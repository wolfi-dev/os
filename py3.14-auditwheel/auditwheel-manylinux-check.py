#!/usr/bin/python3
"""Check ELF files against a manylinux policy using auditwheel.

auditwheel only audits wheels. Each ELF file is wrapped in a throwaway
wheel, then handed to `auditwheel repair --plat <tag>`, which exits
non-zero when the wheel cannot carry the requested tag. Shared libraries
listed alongside the checked files are excluded from the audit, the same
way auditwheel treats libraries that live inside the wheel itself.

Exit status: 0 when every ELF file passes, 1 on any failure or when there
was nothing to check, 2 on a usage error.
"""

import argparse
import fnmatch
import json
import os
import platform
import re
import subprocess
import sys
import tempfile
import zipfile

TAG = "manylinux"
TAG_RE = re.compile(r"^manylinux_(\d+)_(\d+)(?:_[A-Za-z0-9_]+)?$")
SHARED_LIB_RE = re.compile(r"\.so(\.|$)")
ELF_MAGIC = b"\x7fELF"


def info(*args):
    print(f"INFO[{TAG}]:", *args)


def passed(*args):
    print(f"PASS[{TAG}]:", *args)


def failed(*args):
    print(f"FAIL[{TAG}]:", *args)


def warn(*args):
    print(f"WARN[{TAG}]:", *args)


def error(*args):
    print(f"ERROR[{TAG}]:", *args, file=sys.stderr)


def parse_tag(tag):
    """Return the (major, minor) glibc version a manylinux tag names."""
    match = TAG_RE.match(tag)
    if match is None:
        return None
    return int(match.group(1)), int(match.group(2))


def sibling_pattern(name):
    """Return a glob pattern that matches every soname of one shipped library file."""
    return name[: name.index(".so") + len(".so")] + "*"


def is_elf(path):
    if os.path.islink(path) or not os.path.isfile(path):
        return False
    try:
        with open(path, "rb") as f:
            return f.read(len(ELF_MAGIC)) == ELF_MAGIC
    except OSError:
        return False


def make_wheel(elf_path, arch, tmpdir):
    """Wrap one ELF file in a minimal platform wheel.

    auditwheel reads the file list from RECORD, refuses shared libraries
    under a "purelib" directory, and ignores files ending in ".py". The
    layout below avoids all three.
    """
    name = "auditcheck"
    wheel = os.path.join(tmpdir, f"{name}-0-py3-none-linux_{arch}.whl")
    payload = f"{name}/{os.path.basename(elf_path)}"
    if payload.endswith(".py"):
        payload += ".elf"
    dist_info = f"{name}-0.dist-info"
    metadata = f"Metadata-Version: 2.1\nName: {name}\nVersion: 0\n"
    wheel_meta = (
        "Wheel-Version: 1.0\nGenerator: auditwheel-manylinux-check\n"
        f"Root-Is-Purelib: false\nTag: py3-none-linux_{arch}\n"
    )
    entries = [payload, f"{dist_info}/METADATA", f"{dist_info}/WHEEL"]
    record = "".join(f"{entry},,\n" for entry in entries + [f"{dist_info}/RECORD"])
    with zipfile.ZipFile(wheel, "w", zipfile.ZIP_STORED) as zf:
        zf.write(elf_path, payload)
        zf.writestr(f"{dist_info}/METADATA", metadata)
        zf.writestr(f"{dist_info}/WHEEL", wheel_meta)
        zf.writestr(f"{dist_info}/RECORD", record)
    return wheel


def run_auditwheel(*args):
    return subprocess.run(
        ["auditwheel", *args], capture_output=True, text=True, check=False
    )


def audit(elf_path, arch, policy_name, excludes, isa_args):
    """Audit one ELF file. Returns (verdict, detail).

    verdict is "pass", "fail", "skip", "usage" or "error". For "fail",
    detail is a list of diagnostic lines. For the others, detail is the
    reason auditwheel gave. "skip" means auditwheel found no platform ELF
    for this architecture in the file; "error" means it produced no JSON
    at all, such as a traceback.
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        wheel = make_wheel(elf_path, arch, tmpdir)
        # `show` is the only subcommand that reports the file's platform
        # findings as JSON, so it supplies the skip decision and diagnostics.
        shown = run_auditwheel("show", "--json", *isa_args, wheel)
        try:
            result = json.loads(shown.stdout)
        except json.JSONDecodeError:
            result = None
        if result is None:
            return "error", (shown.stdout + shown.stderr).strip()
        if "error" in result:
            return "skip", result["error"].strip()

        # `repair` is the subcommand that honors --exclude and answers a
        # yes/no question about one requested tag.
        exclude_args = [f"--exclude={e}" for e in excludes]
        repaired = run_auditwheel(
            "repair", "--only-plat", f"--plat={policy_name}", "-w",
            os.path.join(tmpdir, "out"), *exclude_args, *isa_args, wheel,
        )
    if repaired.returncode == 0:
        return "pass", None

    reason = [l for l in repaired.stderr.splitlines() if "error" in l.lower()]
    reason = reason[-1].split("error: ", 1)[-1] if reason else repaired.stderr.strip()
    # auditwheel defines a separate set of policies for each architecture.
    # For example, manylinux_2_17 is the oldest policy on aarch64.
    if "argument --plat: invalid choice" in reason:
        return "usage", f"{policy_name} is not a policy auditwheel recognizes for {arch}"
    # Drop the throwaway wheel's path from auditwheel's message.
    reason = re.sub(r'^cannot repair "[^"]*" to "([^"]*)" ABI because',
                    r"cannot carry \1 because", reason)
    detail = [reason]
    # policy_upgrades names the libraries that stand between the file and
    # the requested tag, judged by that tag's own whitelist.
    upgrade = result["policy_upgrades"].get(policy_name, {})
    external = {
        lib: result["external_libs"].get(lib)
        for lib in upgrade.get("libs_to_eliminate", [])
        if not any(fnmatch.fnmatch(lib, e) for e in excludes)
    }
    if external:
        detail.append(f"libraries auditwheel would graft into the wheel for {policy_name}:")
        detail += [f"  {lib} -> {path}" for lib, path in sorted(external.items())]
    detail.append(
        "versioned symbols needed by the file and by the libraries auditwheel "
        f"would graft into it: {result['sym_tag']}"
    )
    # `show` has no --exclude flag, so this block counts excluded libraries too.
    # Only the verdict computed above applies the exclude list.
    if excludes:
        detail.append("  (unfiltered: includes libraries excluded from the verdict)")
    detail += [
        f"  {lib}: {', '.join(versions)}"
        for lib, versions in sorted(result["versioned_symbols"].items())
    ]
    if result["unsupported_isa"]:
        detail.append("requires ISA extensions above the architecture baseline")
    return "fail", detail


def main():
    parser = argparse.ArgumentParser(
        prog="auditwheel-manylinux-check",
        description="Check that ELF files satisfy a manylinux platform tag, "
        "using auditwheel's policy table.",
    )
    parser.add_argument(
        "tag",
        help="manylinux tag to check against, e.g. manylinux_2_28. "
        "An architecture suffix is ignored.",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="ELF files to check. If omitted, read newline-separated paths from stdin. "
        "Non-ELF files, directories, and symlinks are skipped. Shared libraries among "
        "the listed paths are excluded from every file's audit by name stem: "
        "libfoo.so.1.2 excludes libfoo.so*.",
    )
    parser.add_argument(
        "--arch",
        default=platform.machine(),
        help="architecture the files are built for (default: %(default)s)",
    )
    parser.add_argument(
        "--disable-isa-ext-check",
        action="store_true",
        help="do not fail files that need instruction set architecture (ISA) "
        "extensions above the baseline, e.g. x86-64-v2. Passed through to auditwheel.",
    )
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        metavar="SONAME",
        help="library to leave out of the audit, e.g. libssl.so.3. Wildcards allowed. "
        "Repeatable. Passed through to auditwheel.",
    )
    args = parser.parse_args()
    isa_args = ["--disable-isa-ext-check"] if args.disable_isa_ext_check else []

    required = parse_tag(args.tag)
    if required is None:
        error(f"'{args.tag}' is not a manylinux_X_Y tag (legacy aliases such as "
              "manylinux2014 are not accepted)")
        return 2
    policy_name = f"manylinux_{required[0]}_{required[1]}_{args.arch}"

    paths = args.files if args.files else sys.stdin.read().splitlines()
    paths = ["/" + p.strip().lstrip("/") for p in paths if p.strip()]
    # Match a shipped library by its soname (libfoo.so.4), not its exact filename.
    # The soname may not appear in the file list, so exclude everything sharing its stem.
    siblings = sorted({
        sibling_pattern(os.path.basename(p))
        for p in paths if SHARED_LIB_RE.search(os.path.basename(p))
    })
    excludes = args.exclude + siblings
    if siblings:
        info(f"excluding shared libraries shipped alongside the checked files: "
             f"{', '.join(siblings)}")

    counts = {"pass": 0, "fail": 0, "skip": 0}
    for path in paths:
        if not is_elf(path):
            continue
        verdict, detail = audit(path, args.arch, policy_name, excludes, isa_args)
        if verdict == "usage":
            error(detail)
            return 2
        if verdict == "error":
            error(f"{path}: auditwheel produced no JSON:\n{detail}")
            return 1
        counts[verdict] += 1
        if verdict == "pass":
            passed(f"{path}: satisfies {policy_name}")
        elif verdict == "skip":
            warn(f"{path}: skipped, {detail}")
        else:
            failed(f"{path}: {detail[0]}")
            for line in detail[1:]:
                print(f"  {line}")

    checked = sum(counts.values())
    if checked == 0:
        error("no ELF files found to check")
        return 1
    info(f"checked {checked} ELF files against {policy_name}: "
         f"{counts['pass']} passed, {counts['fail']} failed, {counts['skip']} skipped")
    return 1 if counts["fail"] else 0


if __name__ == "__main__":
    sys.exit(main())
