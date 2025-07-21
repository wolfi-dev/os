#!/bin/sh

for f in /etc/chromium/*.conf; do
  [ -f "$f" ] && . "$f"
done

# Append CHROMIUM_USER_FLAGS (from env) on top of system
# default CHROMIUM_FLAGS (from /etc/chromium/chromium.conf).
CHROMIUM_FLAGS="$CHROMIUM_FLAGS ${CHROMIUM_USER_FLAGS:+"$CHROMIUM_USER_FLAGS"}"

if [ $(id -u) -eq 0 ] && [ $(stat -c %u -L ${XDG_CONFIG_HOME:-${HOME}}) -eq 0 ]; then
  # Running as root with HOME owned by root.
  # Pass --user-data-dir to work around upstream failsafe.
  CHROMIUM_FLAGS="--user-data-dir=${XDG_CONFIG_HOME:-"$HOME"/.config}/chromium $CHROMIUM_FLAGS"
fi

exec "/usr/lib/chromium/chrome" ${CHROMIUM_FLAGS} "$@"
