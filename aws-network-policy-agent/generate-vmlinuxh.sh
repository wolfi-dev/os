#!/bin/sh
set -x
# Recreate vmlinux.h header from AL2023 kernel debug headers
# See Upstream Docker file `make vmlinuxh` step
# This is generated data from AL2023 kernel

docker run -i -w /root --entrypoint sh public.ecr.aws/amazonlinux/amazonlinux:2023 <<EOF
set -x
dnf update -y
dnf install -y kernel kernel-devel binutils bpftool
/usr/src/kernels/*/scripts/extract-vmlinux /usr/lib/modules/*/vmlinuz > vmlinux
bpftool btf dump file vmlinux format c > vmlinux.h
EOF

mkdir -p pkg/ebpf/c/
docker cp $(docker ps -alq):/root/vmlinux.h pkg/ebpf/c/

