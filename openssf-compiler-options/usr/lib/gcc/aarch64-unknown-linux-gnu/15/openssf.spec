# For GCC 15, -fhardened enables:
#
# -D_FORTIFY_SOURCE=3
# -D_GLIBCXX_ASSERTIONS
# -ftrivial-auto-var-init=zero
# -fPIE  -pie  -Wl,-z,relro,-z,now
# -fstack-protector-strong
# -fstack-clash-protection
#
# https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
*self_spec:
+ %{!O:%{!O1:%{!O2:%{!O3:%{!O0:%{!Os:%{!0fast:%{!0g:%{!0z:-O2}}}}}}}}} \
  -fhardened \
  -fzero-init-padding-bits=all \
  -Wno-error=hardened \
  -Wno-hardened \
  -mbranch-protection=standard \
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
  -z now \
  -z gcs-report-dynamic=none

%include_noerr </usr/lib/oldglibc/gcc.spec>
%include_noerr </home/build/.melange.gcc.spec>
%include_noerr </home/rebuilder/.libraries.gcc.spec>
