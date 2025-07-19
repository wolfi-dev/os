#!/bin/bash
# This script was based on the upstream script available at https://github.com/SonarSource/docker-sonarqube/blob/3c29d8645e40acfb61cf241a0dfc51bd7175b96b/10/community/entrypoint.sh
# If paths for the jarfiles ever change, this must be updated too.
DEFAULT_CMD=('/usr/bin/java' '-jar' '/opt/sonarqube/lib/sonarqube.jar' '-Dsonar.log.console=true')

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- "${DEFAULT_CMD[@]}" "$@"
fi

exec "$@"
