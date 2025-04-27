*self_spec:
+ %{!O:%{!O1:%{!O2:%{!O3:%{!O0:%{!Os:%{!0fast:%{!0g:%{!0z:-O2}}}}}}}}} -fhardened -Wno-error=hardened -Wno-hardened -mbranch-protection=standard,gcs %{!fdelete-null-pointer-checks:-fno-delete-null-pointer-checks} -fno-strict-overflow -fno-strict-aliasing %{!fomit-frame-pointer:-fno-omit-frame-pointer} -mno-omit-leaf-frame-pointer %{!std=*:-std=gnu23} -Wanalyzer-undefined-behavior-ptrdiff

*link:
+ --as-needed -O1 --sort-common -z noexecstack -z relro -z now

%include_noerr </usr/lib/oldglibc/gcc.spec>
%include_noerr </home/build/.melange.gcc.spec>