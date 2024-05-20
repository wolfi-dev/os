#!/bin/bash

# Use a modified entrypoint script as the official one duplicates env vars and system properties used by the JVM on startup
# This means we avoid errors like: ERROR: setting [discovery.seed_hosts] already set, saw [opensearch-cluster-master-headless] and [opensearch-cluster-master-headless]
# This is based on the upstream script from https://raw.githubusercontent.com/opensearch-project/opensearch-build/2.11.1/docker/release/config/opensearch/opensearch-docker-entrypoint.sh

# Copyright OpenSearch Contributors
# SPDX-License-Identifier: Apache-2.0

# This script specify the entrypoint startup actions for opensearch
# It will start both opensearch and performance analyzer plugin cli
# If either process failed, the entire docker container will be removed
# in favor of a newly started container

# Export OpenSearch Home
export OPENSEARCH_HOME=/usr/share/opensearch
export OPENSEARCH_PATH_CONF=$OPENSEARCH_HOME/config

# The virtual file /proc/self/cgroup should list the current cgroup
# membership. For each hierarchy, you can follow the cgroup path from
# this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
# introspect the statistics for the cgroup for the given
# hierarchy. Alas, Docker breaks this by mounting the container
# statistics at the root while leaving the cgroup paths as the actual
# paths. Therefore, OpenSearch provides a mechanism to override
# reading the cgroup path from /proc/self/cgroup and instead uses the
# cgroup path defined the JVM system property
# opensearch.cgroups.hierarchy.override. Therefore, we set this value here so
# that cgroup statistics are available for the container this process
# will run in.
export OPENSEARCH_JAVA_OPTS="-Dopensearch.cgroups.hierarchy.override=/ $OPENSEARCH_JAVA_OPTS"

# Security Plugin
function setupSecurityPlugin {
    SECURITY_PLUGIN="opensearch-security"

    if [ -d "$OPENSEARCH_HOME/plugins/$SECURITY_PLUGIN" ]; then
        if [ "$DISABLE_INSTALL_DEMO_CONFIG" = "true" ]; then
            echo "Disabling execution of install_demo_configuration.sh for OpenSearch Security Plugin"
        else
            echo "Enabling execution of install_demo_configuration.sh for OpenSearch Security Plugin"
            bash $OPENSEARCH_HOME/plugins/$SECURITY_PLUGIN/tools/install_demo_configuration.sh -y -i -s
        fi

        if [ "$DISABLE_SECURITY_PLUGIN" = "true" ]; then
            echo "Disabling OpenSearch Security Plugin"
            opensearch_opt="-Eplugins.security.disabled=true"
            opensearch_opts+=("${opensearch_opt}")
        else
            echo "Enabling OpenSearch Security Plugin"
        fi
    else
        echo "OpenSearch Security Plugin does not exist, disable by default"
    fi
}

# Performance Analyzer Plugin
function setupPerformanceAnalyzerPlugin {
    PERFORMANCE_ANALYZER_PLUGIN="opensearch-performance-analyzer"
    if [ -d "$OPENSEARCH_HOME/plugins/$PERFORMANCE_ANALYZER_PLUGIN" ]; then
        if [ "$DISABLE_PERFORMANCE_ANALYZER_AGENT_CLI" = "true" ]; then
            echo "Disabling execution of $OPENSEARCH_HOME/bin/$PERFORMANCE_ANALYZER_PLUGIN/performance-analyzer-agent-cli for OpenSearch Performance Analyzer Plugin"
        else
            echo "Enabling execution of OPENSEARCH_HOME/bin/$PERFORMANCE_ANALYZER_PLUGIN/performance-analyzer-agent-cli for OpenSearch Performance Analyzer Plugin"
            $OPENSEARCH_HOME/bin/opensearch-performance-analyzer/performance-analyzer-agent-cli > $OPENSEARCH_HOME/logs/PerformanceAnalyzer.log 2>&1 & disown
        fi
    else
        echo "OpenSearch Performance Analyzer Plugin does not exist, disable by default"
    fi
}

# Start up the opensearch and performance analyzer agent processes.
# When either of them halts, this script exits, or we receive a SIGTERM or SIGINT signal then we want to kill both these processes.
function runOpensearch {
    # Files created by OpenSearch should always be group writable too
    umask 0002

    if [[ "$(id -u)" == "0" ]]; then
        echo "OpenSearch cannot run as root. Please start your container as another user."
        exit 1
    fi

    # Parse Docker env vars to customize OpenSearch
    #
    # e.g. Setting the env var cluster.name=testcluster
    # will cause OpenSearch to be invoked with -Ecluster.name=testcluster
    # DISABLE THIS FOR WOLFI
    opensearch_opts=()
    #while IFS='=' read -r envvar_key envvar_value
    #do
    #    # OpenSearch settings need to have at least two dot separated lowercase
    #    # words, e.g. `cluster.name`, except for `processors` which we handle
    #    # specially
    #    if [[ "$envvar_key" =~ ^[a-z0-9_]+\.[a-z0-9_]+ || "$envvar_key" == "processors" ]]; then
    #        if [[ ! -z $envvar_value ]]; then
    #        opensearch_opt="-E${envvar_key}=${envvar_value}"
    #        opensearch_opts+=("${opensearch_opt}")
    #        fi
    #    fi
    #done < <(env)

    setupSecurityPlugin
    setupPerformanceAnalyzerPlugin

    # Start opensearch
    "$@" "${opensearch_opts[@]}"

}

# Prepend "opensearch" command if no argument was provided or if the first
# argument looks like a flag (i.e. starts with a dash).
if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ]; then
    set -- opensearch "$@"
fi

if [ "$1" = "opensearch" ]; then
    # If the first argument is opensearch, then run the setup script.
    runOpensearch "$@"
else
    # Otherwise, just exec the command.
    exec "$@"
fi