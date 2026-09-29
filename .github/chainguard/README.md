# Wolfi publication trust

Production export and publication use repository-restricted organization policies
in `chainguard-dev/.github` and `wolfi-dev/.github`, with separate Google service
accounts. This directory no longer grants access to stereo's export Actions job.

For [OS-2867](https://linear.app/chainguard/issue/OS-2867), merge this retirement in
wolfi-staging only after the old workflow is disabled, queued/active runs are
drained, its removal is merged, and new runtime policies are installed. Capture
the resulting staging head for the reviewed signed-history transition. Do not
make an independent retirement commit in public Wolfi: exact-commit publication
must carry this deletion into public history before schedule activation.

Follow the [production cutover runbook](https://github.com/chainguard-dev/mono/blob/main/env/enforce.dev/iac/400-export-wolfi/README.md).
