# Withdrawing packages in Wolfi

Sometimes a package needs to be withdrawn from Wolfi because it has been
determined to be defective. This is to avoid somebody from accidentally
depending on it. If you are fixing the defective version, and in the process are
bumping the epoch, most likely you do not need to withdraw the package as the
newer version will be preferred by version selection process. Any other package
fix that will create a more preferred version will also mean that you are not
likely to need to withdraw packages.

To do so:

1. Add the package names that need to be withdrawn to `withdrawn-packages.txt`.
2. Run the ["Withdraw packages"](https://github.com/wolfi-dev/os/actions/workflows/withdraw-packages.yaml) workflow on GitHub.

## Technical details

The "Withdraw packages" workflow exists in `.github/workflows/withdraw-packages.yaml`.

