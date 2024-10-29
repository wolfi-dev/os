#!/bin/sh
set -x
# Recreate vmlinux.h header from AL2023 kernel debug headers for both x86_64
# and aarch64. This is needed to build the eBPF programs that are used by the
# AWS Network Policy Agent.
# Theoretically, this should be done on the same architecture as the kernel, but
# with RE-CO stuff the ebpf does it should still work. But might as well use
# the correct architecture.
# These are then used in the melange build file to use the correct vmlinux.h  
#
# See Upstream Docker file `make vmlinuxh` step
# This is generated data from AL2023 kernel

mkdir -p pkg/ebpf/c/

for arch in x86_64 aarch64; do
  docker run --platform linux/$arch -i -w /root --entrypoint sh public.ecr.aws/amazonlinux/amazonlinux:2023 <<EOF
    set -x
    dnf update -y
    dnf install -y bpftool
    bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
EOF

docker cp $(docker ps -alq):/root/vmlinux.h pkg/ebpf/c/vmlinux.h-$arch

done


