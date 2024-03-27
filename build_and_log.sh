#!/bin/bash

# The first argument is the package name
package=$1

echo "Building package $package"

# Run the command and pipe its output. Use a subshell if necessary.
make MELANGE_EXTRA_OPTS="--create-build-log --cache-dir=.melangecache" REPO="./packages" package/$package -j1 2>&1 | tee /tmp/build.log

# Immediately capture the PIPESTATUS of the make command, we don't want the exit code of the tee command
exit_code=${PIPESTATUS[0]}

# Act on the exit code from the make command
if [ "$exit_code" -ne 0 ]; then
    # Move the build log to the $TMPDIR directory so it can be used in a subsequent step
    mv /tmp/build.log $TMPDIR/$package.error.log
    exit $exit_code
fi
