# Withdrawing packages in Wolfi

Sometimes a package needs to be withdrawn from Wolfi because it has been
determined to be defective. Also obsolete packages should be withdrawn after
renames and stream-splits. This is to avoid somebody from accidentally depending
on it. If you are fixing the defective version, and in the process are bumping
the epoch, most likely you do not need to withdraw the package as the newer
version will be preferred by version selection process. Any other package fix
that will create a more preferred version will also mean that you are not likely
to need to withdraw packages.

To do so:

1. Put the APK file names to withdraw (e.g. `foo-1.2.3-r0.apk`), one per
   line, in `withdrawn-packages.txt`.
2. Raise a PR, get it reviewed and merged.

Once the PR merges, the
[apk-withdraw-restore reconciler](https://github.com/chainguard-dev/mono/tree/main/bots/apk-withdraw-restore)
withdraws the packages, usually within a few minutes. There is no workflow
to run by hand.

## Technical details

`withdrawn-packages.txt` is a command log, not a record of everything ever
withdrawn. Each merged commit that changes it is applied once, as a batch
of the file's whole content at that commit: the packages are removed from
the registry index and the legacy static index for both architectures, and
their SBOMs are deleted. It is fine to replace the file's content with just
the new batch, and fine to leave older entries in place: withdrawing an
already-withdrawn package is a no-op.

An entry that is also listed in `restored-packages.txt` at the same commit
is ambiguous, so neither action is applied to it.

The reconciler's design is in
[docs/guarded-os/apk-withdraw-restore.md](https://github.com/chainguard-dev/mono/blob/main/docs/guarded-os/apk-withdraw-restore.md)
in mono.

