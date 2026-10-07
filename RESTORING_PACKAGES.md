# Restoring newer packages in Wolfi

In the unlikely event that a withdrawn package needs to be restored to Wolfi:

1. Put the APK file names to restore, one per line, in
   `restored-packages.txt`.
2. In the same PR, remove them from `withdrawn-packages.txt` (see below).
3. Raise the PR, get it reviewed and merged. Once it merges, the
[apk-withdraw-restore reconciler](https://github.com/chainguard-dev/mono/tree/main/bots/apk-withdraw-restore)
restores the packages, usually within a few minutes.

This will restore a package via `apk.cgr.dev` and works for packages in more recent
history.

# Restoring really old packages in Wolfi

`apk.cgr.dev` is not a full history of Wolfi; in the event that the restore detailed
above does not restore the package (the reconciler logs, as a warning, any package the
`apk.cgr.dev` restore API reports it could not restore), use the backfill workflow
instead:

1. Add the package names that need to be restored to `backfill-packages.txt`.
2. Raise a PR and then get it reviewed and merged at which point the
["Backfill packages"](https://github.com/wolfi-dev/os/actions/workflows/backfill.yaml)
workflow on GitHub will run to perform the restore.

This will restore the package using the original APK from a GCS bucket.

# Ensure the packages are no longer listed in withdrawn-packages.txt

Remove the packages from `withdrawn-packages.txt` in the same commit that
adds them to `restored-packages.txt`. A package listed in both files at
the same commit is ambiguous, so the reconciler applies neither action to
it and the restore does not happen. Removing it also stops a later
withdrawal batch from withdrawing it again.

## Technical details

`restored-packages.txt` is a command log: each merged commit that changes
it is applied once, as a batch of the file's whole content at that commit.
The reconciler's design is in
[docs/guarded-os/apk-withdraw-restore.md](https://github.com/chainguard-dev/mono/blob/main/docs/guarded-os/apk-withdraw-restore.md)
in mono.

