# OpenSSL 3.6.2 Regression: TLS 1.3 Panic in All go-fips Packages

## Summary

OpenSSL 3.6.2 (released 2026-04-07) introduced strict NULL parameter
validation in `OSSL_PARAM_BLD_push_octet_string()` that breaks TLS 1.3
handshakes in every go-fips package. Any FIPS Go binary that makes an HTTPS
connection panics, including `go mod download` during builds.

## Symptoms

```
panic: failed to add parameter data: OSSL_PARAM_BLD_push_octet_string
    openssl error(s):
    error:078C0102:common libcrypto routines::passed a null parameter
        crypto/param_build.c:369
```

Stack trace through `crypto/tls/internal/tls13.ExpandLabel` ->
`trafficKey` -> `setTrafficSecret` -> `establishHandshakeKeys` during any
TLS 1.3 handshake.

## Root Cause

Two independent issues combine to cause this:

### 1. OpenSSL 3.6.2 added `buf == NULL` rejection (the trigger)

Commit [d5ad0b89b155](https://github.com/openssl/openssl/commit/d5ad0b89b15522ceec93db5c97ac3fed2ccbeaa6)
("Add NULL checks for the arguments in OSSL_PARAM_BLD_push_*() functions"),
merged via [openssl/openssl#30542](https://github.com/openssl/openssl/pull/30542),
added this check to `OSSL_PARAM_BLD_push_octet_string()`:

```c
// crypto/param_build.c (OpenSSL 3.6.2, line 368)
if (bld == NULL || key == NULL || buf == NULL) {   // <-- buf == NULL is new
    ERR_raise(ERR_LIB_CRYPTO, ERR_R_PASSED_NULL_PARAMETER);
    return 0;
}
```

OpenSSL 3.6.1 had **no null check on `buf`** in this function. The new check
rejects `buf == NULL` even when `bsize == 0`, which is a valid and common
way to represent a zero-length octet string in C.

### 2. golang-fips/openssl passes NULL for empty TLS 1.3 context (the latent bug)

In the [golang-fips/openssl](https://github.com/golang-fips/openssl) v2 shim
(vendored by [microsoft/go](https://github.com/microsoft/go) at tag
[v1.25.8-1](https://github.com/microsoft/go/tree/v1.25.8-1)), the
`newTLS13KDFExpandCtx3` function unconditionally passes the `context`
parameter to OpenSSL without a nil guard:

```go
// hkdf.go in golang-fips/openssl (vendored in microsoft/go patch 0001)
func newTLS13KDFExpandCtx3(md ossl.EVP_MD_PTR, label, context, pseudorandomKey []byte) (_ ossl.EVP_KDF_CTX_PTR, err error) {
    // ...
    bld.addOctetString(_OSSL_KDF_PARAM_DATA, context)  // <-- no len() guard
    // ...
}
```

When `context` is nil (a valid case per RFC 8446 Section 7.3 for traffic key
derivation), `addOctetString` calls `pbase(value)` -> `base(value)`:

```go
// hkdf.go, addOctetString
func (b *paramBuilder) addOctetString(name cString, value []byte) {
    // ...
    if len(value) != 0 {
        b.pinner.Pin(&value[0])
    }
    // pbase(nil) returns NULL via base():
    if _, err := ossl.OSSL_PARAM_BLD_push_octet_string(b.bld, name.ptr(), pbase(value), len(value)); err != nil {
        b.err = addParamError{name.str(), err}
    }
}

func base(b []byte) *byte {
    if len(b) == 0 {
        return nil         // <-- returns NULL for empty/nil slices
    }
    return unsafe.SliceData(b)
}
```

This results in calling `OSSL_PARAM_BLD_push_octet_string(bld, key, NULL, 0)`.

Notably, the codebase already has `baseNeverEmpty` / `pbaseNeverEmpty` which
returns a pointer to a static zero byte instead of NULL for empty slices, but
`addOctetString` uses `pbase` (the NULL-returning variant).

Compare with `newHKDFCtx3` (the non-TLS13 path), which has an explicit
`if len(info) > 0` guard and avoids the issue entirely.

### Why empty context is valid

RFC 8446, Section 7.1 defines HKDF-Expand-Label with `context` typed as
`opaque context<0..255>` (zero-length allowed). Section 7.3 explicitly uses
empty context for traffic key derivation:

```
[sender]_write_key = HKDF-Expand-Label(Secret, "key", "", key_length)
[sender]_write_iv  = HKDF-Expand-Label(Secret, "iv", "", iv_length)
```

The stack trace confirms this: `ExpandLabel` is called with context
`{0x0, 0x0, 0x0}` (nil slice) from `trafficKey`.

## Blast Radius

Every package that uses `go-fips` (go-fips-1.25 or go-fips-1.26) is affected.
This includes builds (module download uses HTTPS) and runtime (any TLS 1.3
connection). The `eks-node-monitoring-agent-fips` was already
[downgraded](https://github.com/chainguard-dev/stereo/commit/48f26fe5ca049936a5431ff899daa83c4784cc9d)
from go-fips-1.26 to go-fips-1.25 today in an attempt to fix the same
panic, but the issue is in OpenSSL, not the Go version.

## Fix Applied

Patch applied to OpenSSL 3.6.2 in
[`os/openssl/0001-param-build-allow-NULL-buf-in-push-octet-string-for-zero-length.patch`](os/openssl/0001-param-build-allow-NULL-buf-in-push-octet-string-for-zero-length.patch):

```c
-    if (bld == NULL || key == NULL || buf == NULL) {
+    if (bld == NULL || key == NULL || (buf == NULL && bsize != 0)) {
```

This restores the 3.6.1 behavior: NULL with size 0 is accepted as a valid
empty octet string. Non-zero size with NULL is still rejected.

Commit: `fix(openssl): allow NULL buf for zero-length octet strings in param_build`

## Upstream Fix Needed

The proper long-term fix belongs in
[golang-fips/openssl](https://github.com/golang-fips/openssl). The
`addOctetString` function should use `pbaseNeverEmpty` instead of `pbase`,
or `newTLS13KDFExpandCtx3` should guard the context parameter like
`newHKDFCtx3` does. There is precedent for this pattern:
[golang-fips/openssl#260](https://github.com/golang-fips/openssl/pull/260)
("hkdf: Replace nil salt with a slice of a preallocated all zeros buffer")
already fixed the analogous issue for HKDF salt.

## Related Links

| What | Link |
|------|------|
| OpenSSL 3.6.2 release | https://github.com/openssl/openssl/releases/tag/openssl-3.6.2 |
| OpenSSL commit adding NULL checks | https://github.com/openssl/openssl/commit/d5ad0b89b15522ceec93db5c97ac3fed2ccbeaa6 |
| OpenSSL PR #30542 | https://github.com/openssl/openssl/pull/30542 |
| golang-fips/openssl repo | https://github.com/golang-fips/openssl |
| golang-fips/openssl PR #260 (nil salt fix, precedent) | https://github.com/golang-fips/openssl/pull/260 |
| golang-fips/openssl PR #272 (TLS13-KDF support) | https://github.com/golang-fips/openssl/pull/272 |
| microsoft/go v1.25.8-1 tag | https://github.com/microsoft/go/tree/v1.25.8-1 |
| microsoft/go#1626 (related TLS 1.3 panic, different root cause) | https://github.com/microsoft/go/issues/1626 |
| RFC 8446 Section 7.1 (HKDF-Expand-Label) | https://datatracker.ietf.org/doc/html/rfc8446#section-7.1 |
| RFC 8446 Section 7.3 (traffic key derivation with empty context) | https://datatracker.ietf.org/doc/html/rfc8446#section-7.3 |
