# Restoring newer packages in Wolfi

In the unlikely event that a withdrawn package needs to be restored to Wolfi:

1. Add the package names that need to be restored to `restored-packages.txt`.
2. Raise a PR and then get it reviewed and merged at which point the
["Restore packages"](https://github.com/wolfi-dev/os/actions/workflows/restore-packages.yaml)
workflow on GitHub will run to perform the restore.

This will restore a package via `apk.cgr.dev` and works for packages in more recent
history.

# Restoring really old packages in Wolfi

`apk.cgr.dev` is not a full history of Wolfi; in the event that the restore packages
workflow detailed above does not restore the package (any packages that are not found
during restoration are listed in the response from the `apk.cgr.dev` API call), use the
backfill workflow instead:

1. Add the package names that need to be restored to `backfill-packages.txt`.
2. Raise a PR and then get it reviewed and merged at which point the
["Backfill packages"](https://github.com/wolfi-dev/os/actions/workflows/backfill.yaml)
workflow on GitHub will run to perform the restore.

This will restore the package using the original APK from a GCS bucket.

# Ensure the packages are no longer listed in withdrawn-packages.txt

To ensure that a subsequent withdrawal operation does not withdraw the packages just
restored remove them from withdrawn-packages.txt.

## Technical details

The "Restore packages" workflow exists in `.github/workflows/restore-packages.yaml`.
The "Backfill packaged" workflow exists in `.github/workflows/backfill.yaml`.

