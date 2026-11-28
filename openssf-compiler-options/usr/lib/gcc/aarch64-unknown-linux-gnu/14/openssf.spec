*self_spec:
+ %{!O*:-O2} \
  -fhardened \
  -Wno-error=hardened \
  -Wno-hardened \
  %{!mbranch-protection=*:-mbranch-protection=standard} \
  %{!fdelete-null-pointer-checks:-fno-delete-null-pointer-checks} \
  -fno-strict-overflow \
  -fno-strict-aliasing \
  %{!fomit-frame-pointer:-fno-omit-frame-pointer} \
  -mno-omit-leaf-frame-pointer

*link:
+ --as-needed \
  -O1 \
  --sort-common \
  -z noexecstack \
  -z relro \
  -z now

%include_noerr </usr/lib/oldglibc/gcc.spec>
%include_noerr </home/build/.melange.gcc.spec>
%include_noerr </home/rebuilder/.libraries.gcc.spec>
