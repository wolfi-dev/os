*self_spec:
+ %{!O:%{!O1:%{!O2:%{!O3:%{!O0:%{!Os:%{!0fast:%{!0g:%{!0z:-O2}}}}}}}}} %{!fdelete-null-pointer-checks:-fno-delete-null-pointer-checks} -fno-strict-overflow -fno-strict-aliasing %{!fomit-frame-pointer:-fno-omit-frame-pointer} -mno-omit-leaf-frame-pointer -Wp,-D_FORTIFY_SOURCE=3 -Wp,-D_GLIBCXX_ASSERTIONS -ftrivial-auto-var-init=zero -fcf-protection=full -fstack-clash-protection -fstack-protector-strong

*link:
+ --as-needed -O1 --sort-common -z noexecstack -z relro -z now
