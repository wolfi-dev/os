# Withdrawing packages in Wolfi

Sometimes a package needs to be withdrawn from Wolfi because it has been
determined to be defective.

To do so:

1. Add the package names that need to be withdrawn to `withdrawn-packages.txt`.
2. Run the "Withdraw packages" workflow on GitHub.

## Technical details

The "Withdraw packages" workflow exists in `.github/workflows/withdraw-packages.yaml`.

