#! /bin/bash -e

# A modified version of the 'jenkins.sh' script which is located upstream:
# - https://github.com/jenkinsci/docker/blob/master/jenkins.sh
#
# The upstream file does not change very often (~2 years), and we can't reliably
# fetch it in melange, due to being located in a different repo, with different
# sha/checksum, and possible race-condition if there is a delay between git tag
# creation in repos.

: "${JENKINS_WAR:="/usr/share/java/jenkins/jenkins.war"}"
: "${JENKINS_HOME:="/var/jenkins_home"}"

if ! [ -r "${JENKINS_HOME}" ] || ! [ -w "${JENKINS_HOME}" ]; then
        echo "INSTALL WARNING: User: ${USER} missing rw permissions on JENKINS_HOME: ${JENKINS_HOME}"
fi

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then

  # shellcheck disable=SC2001
  effective_java_opts=$(sed -e 's/^ $//' <<<"$JAVA_OPTS $JENKINS_JAVA_OPTS")

  # read JAVA_OPTS and JENKINS_OPTS into arrays to avoid need for eval (and associated vulnerabilities)
  java_opts_array=()
  while IFS= read -r -d '' item; do
    java_opts_array+=( "$item" )
  done < <([[ $effective_java_opts ]] && xargs printf '%s\0' <<<"$effective_java_opts")

  readonly agent_port_property='jenkins.model.Jenkins.slaveAgentPort'
  if [ -n "${JENKINS_SLAVE_AGENT_PORT:-}" ] && [[ "${effective_java_opts:-}" != *"${agent_port_property}"* ]]; then
    java_opts_array+=( "-D${agent_port_property}=${JENKINS_SLAVE_AGENT_PORT}" )
  fi

  readonly lifecycle_property='hudson.lifecycle'
  if [[ "${JAVA_OPTS:-}" != *"${lifecycle_property}"* ]]; then
    java_opts_array+=( "-D${lifecycle_property}=hudson.lifecycle.ExitLifecycle" )
  fi

  if [[ "$DEBUG" ]] ; then
    java_opts_array+=( \
      '-Xdebug' \
      '-Xrunjdwp:server=y,transport=dt_socket,address=*:5005,suspend=y' \
    )
  fi

  jenkins_opts_array=( )
  while IFS= read -r -d '' item; do
    jenkins_opts_array+=( "$item" )
  done < <([[ $JENKINS_OPTS ]] && xargs printf '%s\0' <<<"$JENKINS_OPTS")

  exec /usr/bin/java -Duser.home="$JENKINS_HOME" "${java_opts_array[@]}" -jar "${JENKINS_WAR}" "${jenkins_opts_array[@]}" "$@"
fi

exec "$@"