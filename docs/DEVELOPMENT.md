# Development

Wolfi's packages are built using [`melange`](https://github.com/chainguard-dev/melange), and development assumes a working knowledge of building packages with `melange`.

## Environment Setup

The most straightforward way to begin building packages is with `docker`.

The Wolfi team keeps up to date SDK images with the core tools used by Wolfi (`melange`, `apko`, `wolfictl`, etc...). The full list is available [here](https://github.com/wolfi-dev/tools).

The example below uses the general [`sdk`](https://github.com/wolfi-dev/tools#sdk) image.

```bash
# create a local development melange signing key
docker run -v $(pwd):/src --entrypoint=melange ghcr.io/wolfi-dev/sdk keygen /src/local-melange.rsa

# build a package
docker run --privileged -v "$PWD":/work --entrypoint=melange --workdir=/work ghcr.io/wolfi-dev/sdk build --keyring-append local-melange.rsa.pub --keyring-append https://packages.wolfi.dev/os/wolfi-signing.rsa.pub --signing-key local-melange.rsa --repository-append https://packages.wolfi.dev/os  --repository-append /work/packages --empty-workspace --arch x86_64 $package
```

> Note that `--privileged` is needed by `melange` to spawn containers that isolate the build process. See the [build-process](https://github.com/chainguard-dev/melange/blob/main/docs/BUILD-PROCESS.md) for more reference.

### Dev Containers

For those in the VSCode ecosystem, a [`devcontainer`](https://code.visualstudio.com/docs/devcontainers/containers) is provided that leverages the same `sdk` image its the base.

The provided `devcontainer` supports:

- developing in a local container
- developing in a remote container (via docker's supported remote protocols)
- developing in a remote [codespace](https://code.visualstudio.com/docs/remote/codespaces)

The `devcontainer` approach is handy for those wanting to jump directly into packaging, without worrying about configuring or tainting their existing environment. Additionally, since some packages take a while to build, it can be helpful for setting up beefy remote development machines quickly.

#### Remote Docker Development

Some packages take a hot second to build, and can be greatly improved by using beefier machines. To aid with that use case, the `devcontainer` setup supports using remote docker runtimes.

##### GCP

The development setup is known to work on GCP's [ContainerOS](https://cloud.google.com/container-optimized-os/docs), which comes preinstalled with `docker`, which we'll use in unison with `ssh` to access the remote runtime.

```bash
# Create a COS compute instance
gcloud compute instances create wolfi-os-dev \
    --image-project cos-cloud --image-family cos-101-lts \
    --zone us-central1-b \
    --machine-type c3-highcpu-176
    
# Get the instance id
INSTANCE_ID=gcloud compute instances list --format "json(id)" --filter "name=packager-relaxing-bat" | jq -er '.[].id'

# Fetch the ssh equivalent of gcloud's IAP ssh helper command
gcloud compute ssh --zone "us-central1-b" "packager-relaxing-bat" --tunnel-through-iap --dry-run

# Use vscodes helper command to translate this into your ssh configuration
# Ensure you only copy the "ssh ..." portion, not the full path to `ssh`
#   >Remote-SSH: Add New SSH Host

# Create and use a new docker context associated with
docker context create remote-wolfi-os-dev --docker "host=ssh://compute.${INSTANCE_ID}"
```

From there, initialize the dev container as you would for a local setup. The connection will respect the current `docker context`, and spawn the container on the remote machine.
