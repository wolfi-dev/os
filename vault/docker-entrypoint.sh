#!/usr/bin/dumb-init /bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# Modified by Chainguard 

set -e

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.

# Prevent core dumps
ulimit -c 0

# Allow setting VAULT_REDIRECT_ADDR and VAULT_CLUSTER_ADDR using an interface
# name instead of an IP address. The interface name is specified using
# VAULT_REDIRECT_INTERFACE and VAULT_CLUSTER_INTERFACE environment variables. If
# VAULT_*_ADDR is also set, the resulting URI will combine the protocol and port
# number with the IP of the named interface.
get_addr () {
    local if_name=$1
    local uri_template=$2
    ip addr show dev "$if_name" | awk -v uri="$uri_template" '/\s*inet\s/ { \
      ip=gensub(/(.+)\/.+/, "\\1", "g", $2); \
      print gensub(/^(.+:\/\/).+(:.+)$/, "\\1" ip "\\2", "g", uri); \
      exit}'
}

if [ -n "$VAULT_REDIRECT_INTERFACE" ]; then
    export VAULT_REDIRECT_ADDR=$(get_addr "$VAULT_REDIRECT_INTERFACE" ${VAULT_REDIRECT_ADDR:-"http://0.0.0.0:8200"})
    echo "Using $VAULT_REDIRECT_INTERFACE for VAULT_REDIRECT_ADDR: $VAULT_REDIRECT_ADDR"
fi
if [ -n "$VAULT_CLUSTER_INTERFACE" ]; then
    export VAULT_CLUSTER_ADDR=$(get_addr "$VAULT_CLUSTER_INTERFACE" ${VAULT_CLUSTER_ADDR:-"https://0.0.0.0:8201"})
    echo "Using $VAULT_CLUSTER_INTERFACE for VAULT_CLUSTER_ADDR: $VAULT_CLUSTER_ADDR"
fi


#
# File storage points to `/var/lib/vault` (which is created)
# MUST ADD DOCUMENTATION ON THIS, SO USER CAN MOUNT A VOLUME
#
# Upstream does set various env vars
# https://developer.hashicorp.com/vault/docs/commands#environment-variables 
#
# Note vault loads all files ending in .hcl or .json in the config dir


# Users can add additional config files to this directory as json or hcl. 
# Also note VAULT_LOCAL_CONFIG below
VAULT_CONFIG_DIR=/etc/vault

# Used to store encrypted secrets with filesystem driver. 
VAULT_FILE_DIR=/var/lib/vault 
# logs dir
VAULT_LOGS_DIR=/var/log/vault

# You can also set the VAULT_LOCAL_CONFIG environment variable to pass some
# Vault configuration JSON without having to bind any volumes.
if [ -n "$VAULT_LOCAL_CONFIG" ]; then
    echo "$VAULT_LOCAL_CONFIG" > "$VAULT_CONFIG_DIR/local.json"
fi

# If the user is trying to run Vault directly with some arguments, then
# pass them to Vault.
if [ "${1:0:1}" = '-' ]; then
    set -- vault "$@"
fi

# Look for Vault subcommands.
if [ "$1" = 'server' ]; then
    shift
    set -- vault server \
        -config="$VAULT_CONFIG_DIR" \
        -dev-root-token-id="$VAULT_DEV_ROOT_TOKEN_ID" \
        -dev-listen-address="${VAULT_DEV_LISTEN_ADDRESS:-"0.0.0.0:8200"}" \
        "$@"
elif [ "$1" = 'version' ]; then
    # This needs a special case because there's no help output.
    set -- vault "$@"
elif vault --help "$1" 2>&1 | grep -q "vault $1"; then
    # We can't use the return code to check for the existence of a subcommand, so
    # we have to use grep to look for a pattern in the help output.
    set -- vault "$@"
fi

# If we are running Vault and root, make sure it executes as the proper user.
if [ "$1" = 'vault' ] && [ "$(id -u)" = '0' ]; then
    if [ -z "$SKIP_CHOWN" ]; then
        # If the config dir is bind mounted then chown it
        if [ "$(stat -c %u $VAULT_CONFIG_DIR)" != "$(id -u vault)" ]; then
            chown -R vault:vault $VAULT_CONFIG_DIR || echo "Could not chown $VAULT_CONFIG_DIR (may not have appropriate permissions)"
        fi

        # If the logs dir is bind mounted then chown it
        if [ "$(stat -c %u $VAULT_LOGS_DIR)" != "$(id -u vault)" ]; then
            chown -R vault:vault $VAULT_LOGS_DIR
        fi

        # If the file dir is bind mounted then chown it
        if [ "$(stat -c %u $VAULT_FILE_DIR)" != "$(id -u vault)" ]; then
            chown -R vault:vault $VAULT_FILE_DIR
        fi
    fi

    # In the case vault has been started in a container without IPC_LOCK privileges
    # Note this will probably require running as root and setcap
    if ! vault -version 1>/dev/null 2>/dev/null; then
	>&2 echo "Couldn't start vault with IPC_LOCK. Disabling IPC_LOCK, please use --cap-add IPC_LOCK"
	setcap cap_ipc_lock=-ep "$(readlink -f $(which vault))"
    fi

    set -- su-exec vault "$@"
fi

# Check if we can run (have IPC_LOCK cap)
if [ "$1" = 'vault' ]; then
    if ! vault -version 1>/dev/null 2>/dev/null; then
	>&2 echo "Vault requires the IPC_LOCK capability. Use --cap-add IPC_LOCK or equivalent to run Vault." 
	>&2 echo "If this isn't possible, use --user=root to disable IPC_LOCK."
	exit 1
    fi
fi

exec "$@"
