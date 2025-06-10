#!/bin/sh

set -x

cap_add=""
cap_drop=""

OLDIFS=$IFS
IFS=","
for capadd in $CAP_ADD; do
	cap_add="$cap_add --cap-add $capadd"
done
for capdrop in $CAP_DROP; do
	cap_drop="$cap_drop --cap-drop $capdrop"
done
IFS=$OLDIFS

bwrap \
	--bind /mount / \
	--bind /proc /proc \
	--bind /sys /sys \
	--bind /sys/fs/cgroup /sys/fs/cgroup \
	--tmpfs /tmp \
	--tmpfs /run \
	--dev /dev \
	--bind /dev/pts /dev/pts \
	--uid $(id -u) \
	--gid $(id -g) \
	${cap_add} ${cap_drop} \
	-- ${SHELL} -i
