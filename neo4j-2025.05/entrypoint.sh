#!/bin/bash -eu

# This script was borrowed from https://github.com/neo4j/docker-neo4j-publish/blob/5e0122d70f6407707b3ae70e6ef91a1fb3fd2f61/5.6.0/community/local-package/docker-entrypoint.sh

cmd="$1"

function running_as_root
{
    test "$(id -u)" = "0"
}

function secure_mode_enabled
{
    test "${SECURE_FILE_PERMISSIONS:=no}" = "yes"
}

function debugging_enabled
{
    test "${NEO4J_DEBUG+yes}" = "yes"
}

function debug_msg
{
    if debugging_enabled; then
        echo "$@"
    fi
}

function containsElement
{
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function is_readable
{
    # this code is fairly ugly but works no matter who this script is running as.
    # It would be nice if the writability tests could use this logic somehow.
    local _file=${1}
    perm=$(stat -c %a "${_file}")

    # everyone permission
    if [[ ${perm:2:1} -ge 4 ]]; then
        return 0
    fi
    # owner permissions
    if [[ ${perm:0:1} -ge 4 ]]; then
        if [[ "$(stat -c %U ${_file})" = "${userid}" ]] || [[ "$(stat -c %u ${_file})" = "${userid}" ]]; then
            return 0
        fi
    fi
    # group permissions
    if [[ ${perm:1:1} -ge 4 ]]; then
        if containsElement "$(stat -c %g ${_file})" "${groups[@]}" || containsElement "$(stat -c %G ${_file})" "${groups[@]}" ; then
            return 0
        fi
    fi
    return 1
}

function is_writable
{
    # It would be nice if this and the is_readable function could combine somehow
    local _file=${1}
    perm=$(stat -c %a "${_file}")

    # everyone permission
    if containsElement ${perm:2:1} 2 3 6 7; then
        return 0
    fi
    # owner permissions
    if containsElement ${perm:0:1} 2 3 6 7; then
        if [[ "$(stat -c %U ${_file})" = "${userid}" ]] || [[ "$(stat -c %u ${_file})" = "${userid}" ]]; then
            return 0
        fi
    fi
    # group permissions
    if containsElement ${perm:1:1} 2 3 6 7; then
        if containsElement "$(stat -c %g ${_file})" "${groups[@]}" || containsElement "$(stat -c %G ${_file})" "${groups[@]}" ; then
            return 0
        fi
    fi
    return 1
}

function print_permissions_advice_and_fail
{
    _directory=${1}
    echo >&2 "
Folder ${_directory} is not accessible for user: ${userid} or group ${groupid} or groups ${groups[@]}, this is commonly a file permissions issue on the mounted folder.

Hints to solve the issue:
1) Make sure the folder exists before mounting it. Docker will create the folder using root permissions before starting the Neo4j container. The root permissions disallow Neo4j from writing to the mounted folder.
2) Pass the folder owner's user ID and group ID to docker run, so that docker runs as that user.
If the folder is owned by the current user, this can be done by adding this flag to your docker run command:
  --user=\$(id -u):\$(id -g)
       "
    exit 1
}

function check_mounted_folder_readable
{
    local _directory=${1}
    debug_msg "checking ${_directory} is readable"
    if ! is_readable "${_directory}"; then
        print_permissions_advice_and_fail "${_directory}"
    fi
}

function check_mounted_folder_writable_with_chown
{
# The /data and /log directory are a bit different because they are very likely to be mounted by the user but not
# necessarily writable.
# This depends on whether a user ID is passed to the container and which folders are mounted.
#
#   No user ID passed to container:
#   1) No folders are mounted.
#      The /data and /log folder are owned by neo4j by default, so should be writable already.
#   2) Both /log and /data are mounted.
#      This means on start up, /data and /logs are owned by an unknown user and we should chown them to neo4j for
#      backwards compatibility.
#
#   User ID passed to container:
#   1) Both /data and /logs are mounted
#      The /data and /logs folders are owned by an unknown user but we *should* have rw permission to them.
#      That should be verified and error (helpfully) if not.
#   2) User mounts /data or /logs *but not both*
#      The  unmounted folder is still owned by neo4j, which should already be writable. The mounted folder should
#      have rw permissions through user id. This should be verified.
#   3) No folders are mounted.
#      The /data and /log folder are owned by neo4j by default, and these are already writable by the user.
#      (This is a very unlikely use case).

    local mountFolder=${1}
    debug_msg "checking ${mountFolder} is writable"
    if running_as_root && ! secure_mode_enabled; then
        # check folder permissions
        if ! is_writable "${mountFolder}" ;  then
            # warn that we're about to chown the folder and then chown it
            echo "Warning: Folder mounted to \"${mountFolder}\" is not writable from inside container. Changing folder owner to ${userid}."
            chown -R "${userid}":"${groupid}" "${mountFolder}"
        # check permissions on files in the folder
        elif [ $(gosu "${userid}":"${groupid}" find "${mountFolder}" -not -writable | wc -l) -gt 0 ]; then
            echo "Warning: Some files inside \"${mountFolder}\" are not writable from inside container. Changing folder owner to ${userid}."
            chown -R "${userid}":"${groupid}" "${mountFolder}"
        fi
    else
        if [[ ! -w "${mountFolder}" ]]  && [[ "$(stat -c %U ${mountFolder})" != "neo4j" ]]; then
            print_permissions_advice_and_fail "${mountFolder}"
        fi
    fi
}

function load_plugin_from_location
{
  # Install a plugin from location at runtime.
  local _plugin_name="${1}"
  local _location="${2}"

  local _plugins_dir="${NEO4J_HOME}/plugins"
  if [ -d /plugins ]; then
    local _plugins_dir="/plugins"
  fi

  local _destination="${_plugins_dir}/${_plugin_name}.jar"

  # Now we install the plugin that is shipped with Neo4j
  for filename in ${_location}; do
    echo "Installing Plugin '${_plugin_name}' from ${_location} to ${_destination}"
    cp --preserve "${filename}" "${_destination}"
  done

  if ! is_readable "${_destination}"; then
    echo >&2 "Plugin at '${_destination}' is not readable"
    exit 1
  fi
}

function load_plugin_from_github
{
  # Load a plugin at runtime. The provided github repository must have a versions.json on the master branch with the
  # correct format.
  local _plugin_name="${1}" #e.g. apoc, graph-algorithms, graph-ql

  local _plugins_dir="${NEO4J_HOME}/plugins"
  if [ -d /plugins ]; then
    local _plugins_dir="/plugins"
  fi
  local _versions_json_url="$(jq --raw-output "with_entries( select(.key==\"${_plugin_name}\") ) | to_entries[] | .value.versions" /startup/neo4j-plugins.json )"
  debug_msg "Will read ${_plugin_name} versions.json from ${_versions_json_url}"
  # Using the same name for the plugin irrespective of version ensures we don't end up with different versions of the same plugin
  local _destination="${_plugins_dir}/${_plugin_name}.jar"
  local _neo4j_version="$(neo4j --version | cut -d' ' -f2)"

  # Now we call out to github to get the versions.json for this plugin and we parse that to find the url for the correct plugin jar for our neo4j version
  echo "Fetching versions.json for Plugin '${_plugin_name}' from ${_versions_json_url}"
  local _versions_json="$(wget -q --timeout 300 --tries 30 -O - "${_versions_json_url}")"
  local _plugin_jar_url="$(echo "${_versions_json}" | jq -L/startup --raw-output "import \"semver\" as lib; [ .[] | select(.neo4j|lib::semver(\"${_neo4j_version}\")) ] | min_by(.neo4j) | .jar")"
  if [[ -z "${_plugin_jar_url}" ]]; then
    echo >&2 "Error: No jar URL found for version '${_neo4j_version}' in versions.json from '${_versions_json_url}'"
    exit 1
  fi
  echo "Installing Plugin '${_plugin_name}' from ${_plugin_jar_url} to ${_destination} "
  wget -q --timeout 300 --tries 30 --output-document="${_destination}" "${_plugin_jar_url}"

  if ! is_readable "${_destination}"; then
    echo >&2 "Plugin at '${_destination}' is not readable"
    exit 1
  fi
}

function apply_plugin_default_configuration
{
    # Set the correct Load a plugin at runtime. The provided github repository must have a versions.json on the master branch with the
    # correct format.
    local _plugin_name="${1}" #e.g. apoc, graph-algorithms, graph-ql
    local _reference_conf="${2}" # used to determine if we can override properties
    local _neo4j_conf="${NEO4J_HOME}/conf/neo4j.conf"

    local _property _value
    echo "Applying default values for plugin ${_plugin_name} to neo4j.conf"
    for _entry in $(jq  --compact-output --raw-output "with_entries( select(.key==\"${_plugin_name}\") ) | to_entries[] | .value.properties | to_entries[]" /startup/neo4j-plugins.json); do
        _property="$(jq --raw-output '.key' <<< "${_entry}")"
        _value="$(jq --raw-output '.value' <<< "${_entry}")"
        debug_msg "${_plugin_name} requires setting ${_property}=${_value}"

        # the first grep strips out comments
        if grep -o "^[^#]*" "${_reference_conf}" | grep -q --fixed-strings "${_property}=" ; then
            # property is already set in the user provided config. In this case we don't override what has been set explicitly by the user.
            echo "Skipping ${_property} for plugin ${_plugin_name} because it is already set."
            echo "You may need to add ${_value} to the ${_property} setting in your configuration file."
        else
            if grep -o "^[^#]*" "${_neo4j_conf}" | grep -q --fixed-strings "${_property}=" ; then
                sed --in-place "s/${_property}=/&${_value},/" "${_neo4j_conf}"
                debug_msg "${_property} was already in the configuration file, so ${_value} was added to it."
            else
                echo "${_property}=${_value}" >> "${_neo4j_conf}"
                debug_msg "${_property}=${_value} has been added to the configuration file."
            fi
        fi
    done
}

function install_neo4j_plugins
{
    # first verify that the requested plugins are valid.
    debug_msg "One or more NEO4J_PLUGINS have been requested."
    local _known_plugins=($(jq --raw-output "keys[]" /startup/neo4j-plugins.json))
    debug_msg "Checking requested plugins are known and can be installed."
    for plugin_name in $(echo "${NEO4J_PLUGINS}" | jq --raw-output '.[]'); do
        if ! containsElement "${plugin_name}" "${_known_plugins[@]}"; then
            printf >&2 "\"%s\" is not a known Neo4j plugin. Options are:\n%s" "${plugin_name}" "$(jq --raw-output "keys[1:][]" /startup/neo4j-plugins.json)"
            exit 1
        fi
    done

    # We store a copy of the config before we modify it for the plugins to allow us to see if there are user-set values in the input config that we shouldn't override
    local _old_config="$(mktemp)"
    if [ -e "${NEO4J_HOME}"/conf/neo4j.conf ]; then
        cp "${NEO4J_HOME}"/conf/neo4j.conf "${_old_config}"
    else
        touch "${NEO4J_HOME}"/conf/neo4j.conf
        touch "${_old_config}"
    fi
    for plugin_name in $(echo "${NEO4J_PLUGINS}" | jq --raw-output '.[]'); do
        debug_msg "Plugin ${plugin_name} has been requested"
        local _location="$(jq --raw-output "with_entries( select(.key==\"${plugin_name}\") ) | to_entries[] | .value.location" /startup/neo4j-plugins.json )"
        if [ "${_location}" != "null" -a -n "$(shopt -s nullglob; echo ${_location})" ]; then
            debug_msg "$plugin_name is already in the container at ${_location}"
            load_plugin_from_location "${plugin_name}" "${_location}"
        else
            debug_msg "$plugin_name must be downloaded."
            load_plugin_from_github "${plugin_name}"
        fi
        debug_msg "Applying plugin specific configurations."
        apply_plugin_default_configuration "${plugin_name}" "${_old_config}"
    done
    rm "${_old_config}"
}

function add_docker_default_to_conf
{
    # docker defaults should NOT overwrite values already in the conf file
    local _setting="${1}"
    local _value="${2}"

    if [ ! -e "${NEO4J_HOME}"/conf/neo4j.conf ] || ! grep -q "^${_setting}=" "${NEO4J_HOME}"/conf/neo4j.conf
    then
        debug_msg "Appended ${_setting}=${_value} to ${NEO4J_HOME}/conf/neo4j.conf"
        echo -e "\n"${_setting}=${_value} >> "${NEO4J_HOME}"/conf/neo4j.conf
    fi
}

function add_env_setting_to_conf
{
    # settings from environment variables should overwrite values already in the conf
    local _setting=${1}
    local _value=${2}
    local _conf_file
    local _append_not_replace_configs=("server.jvm.additional")

    # different settings need to go in different files now.
    case "$(echo ${_setting} | cut -d . -f 1)" in
        apoc)
            _conf_file="${NEO4J_HOME}"/conf/apoc.conf
        ;;
        *)
            _conf_file="${NEO4J_HOME}"/conf/neo4j.conf
        ;;
    esac

    if [ -e "${_conf_file}" ] && grep -q -F "${_setting}=" "${_conf_file}"; then
        if containsElement "${_setting}" "${_append_not_replace_configs[@]}"; then
            debug_msg "${_setting} will be appended to ${_conf_file} without replacing existing settings."
        else
            # Remove any lines containing the setting already
            debug_msg "Removing existing setting for ${_setting} in ${_conf_file}"
            sed --in-place "/^${_setting}=.*/d" "${_conf_file}"
        fi
    fi
    # Then always append setting to file
    debug_msg "Appended ${_setting}=${_value} to ${_conf_file}"
    echo "${_setting}=${_value}" >> "${_conf_file}"
}

function set_initial_password
{
    local _neo4j_auth="${1}"

    # set the neo4j initial password only if you run the database server
    if [ "${cmd}" == "neo4j" ]; then
        if [ "${_neo4j_auth:-}" == "none" ]; then
            debug_msg "Authentication is requested to be unset"
            add_env_setting_to_conf "dbms.security.auth_enabled" "false"
        elif [[ "${_neo4j_auth:-}" =~ ^([^/]+)\/([^/]+)/?([tT][rR][uU][eE])?$ ]]; then
            admin_user="${BASH_REMATCH[1]}"
            password="${BASH_REMATCH[2]}"
            do_reset="${BASH_REMATCH[3]}"
            debug_msg "NEO4J_AUTH has been parsed as user \"${admin_user}\", password \"${password}\", do_reset \"${do_reset}\""

            if [ "${password}" == "neo4j" ]; then
                echo >&2 "Invalid value for password. It cannot be 'neo4j', which is the default."
                exit 1
            fi
            if [ "${#password}" -lt 8 ]; then
                echo >&2 "Invalid value for password. The minimum password length is 8 characters.
If Neo4j fails to start, you can:
1) Use a stronger password.
2) Set configuration dbms.security.auth_minimum_password_length to override the minimum password length requirement.
3) Set environment variable NEO4J_dbms_security_auth__minimum__password__length to override the minimum password length requirement."
            fi
            if [ "${admin_user}" != "neo4j" ]; then
                echo >&2 "Invalid admin username, it must be neo4j."
                exit 1
            fi

            if running_as_root; then
                # running set-initial-password as root will create subfolders to /data as root, causing startup fail when neo4j can't read or write the /data/dbms folder
                # creating the folder first will avoid that
                mkdir -p /data/dbms
                debug_msg "Making sure /data/dbms is owned by ${userid}:${groupid}"
                chown "${userid}":"${groupid}" /data/dbms
            fi

            local extra_args=()
            if [ "${do_reset}" == "true" ]; then
                extra_args+=("--require-password-change")
            fi
            if [ "${EXTENDED_CONF+"yes"}" == "yes" ]; then
                extra_args+=("--expand-commands")
            fi
            if debugging_enabled; then
                extra_args+=("--verbose")
            fi
            debug_msg "Setting initial password"
            debug_msg "${neo4j_admin_cmd} dbms set-initial-password ${password} ${extra_args[*]}"
            ${neo4j_admin_cmd} dbms set-initial-password "${password}" "${extra_args[@]}"

        elif [ -n "${_neo4j_auth:-}" ]; then
            echo "$_neo4j_auth is invalid"
            echo >&2 "Invalid value for NEO4J_AUTH: '${_neo4j_auth}'"
            exit 1
        fi
    fi
}

# ==== CODE STARTS ====
debug_msg "DEBUGGING ENABLED"

# If we're running as root, then run as the neo4j user. Otherwise
# docker is running with --user and we simply use that user.  Note
# that su-exec, despite its name, does not replicate the functionality
# of exec, so we need to use both
if running_as_root; then
  userid="neo4j"
  groupid="neo4j"
  groups=($(id -G neo4j))
  exec_cmd="exec gosu neo4j:neo4j"
  neo4j_admin_cmd="gosu neo4j:neo4j neo4j-admin"
  debug_msg "Running as root user inside neo4j image"
else
  userid="$(id -u)"
  groupid="$(id -g)"
  groups=($(id -G))
  exec_cmd="exec"
  neo4j_admin_cmd="neo4j-admin"
  debug_msg "Running as user ${userid}:${groupid} inside neo4j image"
fi
readonly userid
readonly groupid
readonly groups
readonly exec_cmd
readonly neo4j_admin_cmd


# Need to chown the home directory
if running_as_root; then
    debug_msg "chowning ${NEO4J_HOME} recursively to ${userid}":"${groupid}"
    chown -R "${userid}":"${groupid}" "${NEO4J_HOME}"
    chmod 700 "${NEO4J_HOME}"
    find "${NEO4J_HOME}" -mindepth 1 -maxdepth 1 -type d -exec chmod -R 700 {} \;
    debug_msg "Setting all files in ${NEO4J_HOME}/conf to permissions 600"
    find "${NEO4J_HOME}"/conf -type f -exec chmod -R 600 {} \;
fi

# ==== CHECK LICENSE AGREEMENT ====

# Only prompt for license agreement if command contains "neo4j" in it
if [[ "${cmd}" == *"neo4j"* ]]; then
  if [ "${NEO4J_EDITION}" == "enterprise" ]; then
    : ${NEO4J_ACCEPT_LICENSE_AGREEMENT:="not accepted"}
    if [[ "$NEO4J_ACCEPT_LICENSE_AGREEMENT" != "yes" && "$NEO4J_ACCEPT_LICENSE_AGREEMENT" != "eval" ]]; then
      echo >&2 "
In order to use Neo4j Enterprise Edition you must accept the license agreement.

The license agreement is available at https://neo4j.com/terms/licensing/
If you have a support contract the following terms apply https://neo4j.com/terms/support-terms/

If you do not have a commercial license and want to evaluate the Software
please read the terms of the evaluation agreement before you accept.
https://neo4j.com/terms/enterprise_us/

(c) Neo4j Sweden AB. All Rights Reserved.
Use of this Software without a proper commercial license, or evaluation license
with Neo4j,Inc. or its affiliates is prohibited.
Neo4j has the right to terminate your usage if you are not compliant.

More information is also available at: https://neo4j.com/licensing/
If you have further inquiries about licensing, please contact us via https://neo4j.com/contact-us/

To accept the commercial license agreement set the environment variable
NEO4J_ACCEPT_LICENSE_AGREEMENT=yes

To accept the terms of the evaluation agreement set the environment variable
NEO4J_ACCEPT_LICENSE_AGREEMENT=eval

To do this you can use the following docker argument:

        --env=NEO4J_ACCEPT_LICENSE_AGREEMENT=<yes|eval>
"
      exit 1
    fi
  fi
fi

# NEO4JLABS_PLUGINS has been renamed to NEO4J_PLUGINS, but we want the old name to work for now.
if [ -n "${NEO4JLABS_PLUGINS:-}" ];
then
    echo >&2 "NEO4JLABS_PLUGINS has been renamed to NEO4J_PLUGINS since Neo4j 5.0.0.
The old name will still work, but is likely to be deprecated in future releases."
    : ${NEO4J_PLUGINS:=${NEO4JLABS_PLUGINS:-}}
fi

# ==== CHECK FILE PERMISSIONS ON MOUNTED FOLDERS ====


if [ -d /conf ]; then
    check_mounted_folder_readable "/conf"
    rm -rf "${NEO4J_HOME}"/conf/*
    debug_msg "Copying contents of /conf to ${NEO4J_HOME}/conf/*"
    find /conf -type f -exec cp --preserve=ownership,mode {} "${NEO4J_HOME}"/conf \;
fi

if [ -d /ssl ]; then
    check_mounted_folder_readable "/ssl"
    rm -rf "${NEO4J_HOME}"/certificates
    ln -s /ssl "${NEO4J_HOME}"/certificates
fi

if [ -d /plugins ]; then
    if [[ -n "${NEO4J_PLUGINS:-}" ]]; then
        # We need write permissions to write the required plugins to /plugins
        debug_msg "Extra plugins were requested. Ensuring the mounted /plugins folder has the required write permissions."
        check_mounted_folder_writable_with_chown "/plugins"
    fi
    check_mounted_folder_readable "/plugins"
    : ${NEO4J_server_directories_plugins:="/plugins"}
fi

if [ -d /import ]; then
    check_mounted_folder_readable "/import"
    : ${NEO4J_server_directories_import:="/import"}
fi

if [ -d /metrics ]; then
    # metrics is enterprise only
    if [ "${NEO4J_EDITION}" == "enterprise" ];
    then
        check_mounted_folder_writable_with_chown "/metrics"
        : ${NEO4J_server_directories_metrics:="/metrics"}
    fi
fi

if [ -d /logs ]; then
    check_mounted_folder_writable_with_chown "/logs"
    : ${NEO4J_server_directories_logs:="/logs"}
fi

if [ -d /data ]; then
    check_mounted_folder_writable_with_chown "/data"
    if [ -d /data/databases ]; then
        check_mounted_folder_writable_with_chown "/data/databases"
    fi
    if [ -d /data/dbms ]; then
        check_mounted_folder_writable_with_chown "/data/dbms"
    fi
    if [ -d /data/transactions ]; then
        check_mounted_folder_writable_with_chown "/data/transactions"
    fi
fi

if [ -d /licenses ]; then
    check_mounted_folder_readable "/licenses"
    : ${NEO4J_server_directories_licenses:="/licenses"}
fi


# ==== LOAD PLUGINS ====

if [[ -n "${NEO4J_PLUGINS:-}" ]]; then
  # NEO4J_PLUGINS should be a json array of plugins like '["graph-algorithms", "apoc", "streams", "graphql"]'
  install_neo4j_plugins
fi

# ==== RENAME LEGACY ENVIRONMENT CONF VARIABLES ====

# Env variable naming convention:
# - prefix NEO4J_
# - double underscore char '__' instead of single underscore '_' char in the setting name
# - underscore char '_' instead of dot '.' char in the setting name
# Example:
# NEO4J_server_tx__log_rotation_retention__policy env variable to set
#       server.tx_log.rotation.retention_policy setting

# we only need to override the configurations with a docker specific override.
# The other config renames will be taken care of inside Neo4j.
: ${NEO4J_db_tx__log_rotation_retention__policy:=${NEO4J_dbms_tx__log_rotation_retention__policy:-}}
: ${NEO4J_server_memory_pagecache_size:=${NEO4J_dbms_memory_pagecache_size:-}}
: ${NEO4J_server_default__listen__address:=${NEO4J_dbms_default__listen__address:-}}
if [ "${NEO4J_EDITION}" == "enterprise" ];
  then
   : ${NEO4J_server_discovery_advertised__address:=${NEO4J_causal__clustering_discovery__advertised__address:-}}
   : ${NEO4J_server_cluster_advertised__address:=${NEO4J_causal__clustering_transaction__advertised__address:-}}
   : ${NEO4J_server_cluster_raft_advertised__address:=${NEO4J_causal__clustering_raft__advertised__address:-}}
fi

# ==== SET CONFIGURATIONS ====

## == DOCKER SPECIFIC DEFAULT CONFIGURATIONS ===
## these should not override *any* configurations set by the user

debug_msg "Setting docker specific configuration overrides"
add_docker_default_to_conf "db.tx_log.rotation.retention_policy" "100M size"
add_docker_default_to_conf "server.memory.pagecache.size" "512M"
add_docker_default_to_conf "server.default_listen_address" "0.0.0.0"
# set enterprise only docker defaults
if [ "${NEO4J_EDITION}" == "enterprise" ];
then
    debug_msg "Setting docker specific Enterprise Edition overrides"
    add_docker_default_to_conf "server.discovery.advertised_address" "$(hostname):5000"
    add_docker_default_to_conf "server.cluster.advertised_address" "$(hostname):6000"
    add_docker_default_to_conf "server.cluster.raft.advertised_address" "$(hostname):7000"
fi

## == ENVIRONMENT VARIABLE CONFIGURATIONS ===
## these override BOTH defaults and any existing values in the neo4j.conf file

# these are docker control envs that have the NEO4J_ prefix but we don't want to add to the config.
not_configs=("NEO4J_ACCEPT_LICENSE_AGREEMENT" "NEO4J_AUTH" "NEO4J_DEBUG" "NEO4J_EDITION" \
             "NEO4J_HOME" "NEO4J_PLUGINS" "NEO4J_SHA256" "NEO4J_TARBALL")

debug_msg "Applying configuration settings that have been set using environment variables."
# list env variables with prefix NEO4J_ and create settings from them
for i in $( set | grep ^NEO4J_ | awk -F'=' '{print $1}' | sort -rn ); do
    if containsElement "$i" "${not_configs[@]}"; then
        continue
    fi
    setting=$(echo "${i}" | sed 's|^NEO4J_||' | sed 's|_|.|g' | sed 's|\.\.|_|g')
    value=$(echo "${!i}")
    # Don't allow settings with no value or settings that start with a number (neo4j converts settings to env variables and you cannot have an env variable that starts with a number)
    if [[ -n ${value} ]]; then
        if [[ ! "${setting}" =~ ^[0-9]+.*$ ]]; then
            add_env_setting_to_conf "${setting}" "${value}"
        else
            echo >&2 "WARNING: ${setting} not written to conf file because settings that start with a number are not permitted"
        fi
    fi
done

# ==== SET PASSWORD ====

set_initial_password "${NEO4J_AUTH:-}"

# ==== INVOKE NEO4J STARTUP ====

[ -f "${EXTENSION_SCRIPT:-}" ] && . ${EXTENSION_SCRIPT}

if [ "${cmd}" == "dump-config" ]; then
    if [ ! -d "/conf" ]; then
        echo >&2 "You must mount a folder to /conf so that the configuration file(s) can be dumped to there."
        exit 1
    fi
    check_mounted_folder_writable_with_chown "/conf"
    cp --recursive "${NEO4J_HOME}"/conf/* /conf
    echo "Config Dumped"
    exit 0
fi

# this prints out a command for us to run.
# the command is something like: `java ...[lots of java options]... neo4j.mainClass ...[some neo4j options]...`
# putting debug messages here causes the function to break
function get_neo4j_run_cmd {

    local extra_args=()

    if [ "${EXTENDED_CONF+"yes"}" == "yes" ]; then
        extra_args+=("--expand-commands")
    fi

    if running_as_root; then
        gosu neo4j:neo4j neo4j console --dry-run "${extra_args[@]}"
    else
        neo4j console --dry-run "${extra_args[@]}"
    fi
}

# Use su-exec to drop privileges to neo4j user
# Note that su-exec, despite its name, does not replicate the
# functionality of exec, so we need to use both
if [ "${cmd}" == "neo4j" ]; then
    # separate declaration and use of get_neo4j_run_cmd so that error codes are correctly surfaced
    debug_msg "getting full neo4j run command"
    neo4j_console_cmd="$(get_neo4j_run_cmd)"
    debug_msg "${exec_cmd} ${neo4j_console_cmd}"
    eval ${exec_cmd} ${neo4j_console_cmd?:No Neo4j command was generated}
else
    debug_msg "${exec_cmd}" "$@"
    ${exec_cmd} "$@"
fi
