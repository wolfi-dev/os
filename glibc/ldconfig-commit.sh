#!/bin/sh
# Post-commit apk-tools hook, which is executed after busybox trigger
# has completed installing /bin/sh symlink.
if [ "$1" = "post-commit" ]; then
    /usr/bin/ldconfig
fi
