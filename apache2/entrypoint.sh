#!/bin/sh
set -e

exec httpd -DFOREGROUND "$@"
