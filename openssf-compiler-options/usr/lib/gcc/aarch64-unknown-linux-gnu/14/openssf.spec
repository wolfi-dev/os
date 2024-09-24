*self_spec:
+ %{!O:%{!O1:%{!O2:%{!O3:%{!O0:%{!Os:%{!0fast:%{!0g:%{!0z:-O2}}}}}}}}} -fhardened -Wno-error=hardened -mbranch-protection=standard -Wl,--as-needed,-O1,--sort-common,-z,noexecstack,-z,relro,-z,now -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer
