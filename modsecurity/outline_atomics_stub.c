/*
 * outline_atomics_stub.c - AArch64 outline atomic stubs for eco-2-28 builds
 *
 * The eco-2-28 cross-toolchain (GCC 9.3.x) generates calls to AArch64
 * "outline atomic" helper functions (__aarch64_cas*, __aarch64_swp*, etc.)
 * for C++ atomic operations.  The oldglibc sysroot's libgcc.a provides
 * these symbols with HIDDEN visibility, which cannot satisfy a DSO's
 * undefined dynamic reference at link time, producing a link error like:
 *
 *   hidden symbol '__aarch64_cas8_acq_rel' in libgcc.a is referenced by DSO
 *
 * This file provides all outline atomic helpers with DEFAULT visibility
 * using inline LL/SC (LDAXR/STLXR) assembly — ARMv8-A base ISA,
 * acquire-release ordering for all variants (stronger than required, always
 * correct).  Linking this object into libmodsecurity.so via the autoconf
 * LIBS variable resolves every outline atomic symbol inside the DSO so none
 * remain as undefined dynamic references.
 *
 * This code is original work written for the Wolfi / Chainguard build system
 * to work around a toolchain limitation in the eco-2-28 build environment.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <stdint.h>

#define A __attribute__((visibility("default"), noinline))

/* CAS (compare-and-swap): (expected, desired, *mem) -> old value */

A uint64_t __aarch64_cas8_relax(uint64_t e, uint64_t d, volatile uint64_t *m)
{
    uint64_t l; uint32_t s;
    __asm__ __volatile__(
        "1: ldaxr  %[l], [%[m]]\n\t"
        "   cmp    %[l], %[e]\n\t"
        "   b.ne   2f\n\t"
        "   stlxr  %w[s], %[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n\t"
        "2:\n"
        : [l]"=&r"(l), [s]"=&r"(s) : [m]"r"(m), [e]"r"(e), [d]"r"(d) : "cc","memory");
    return l;
}
A uint64_t __aarch64_cas8_acq(uint64_t e, uint64_t d, volatile uint64_t *m)     { return __aarch64_cas8_relax(e,d,m); }
A uint64_t __aarch64_cas8_rel(uint64_t e, uint64_t d, volatile uint64_t *m)     { return __aarch64_cas8_relax(e,d,m); }
A uint64_t __aarch64_cas8_acq_rel(uint64_t e, uint64_t d, volatile uint64_t *m) { return __aarch64_cas8_relax(e,d,m); }

A uint32_t __aarch64_cas4_relax(uint32_t e, uint32_t d, volatile uint32_t *m)
{
    uint32_t l, s;
    __asm__ __volatile__(
        "1: ldaxr  %w[l], [%[m]]\n\t"
        "   cmp    %w[l], %w[e]\n\t"
        "   b.ne   2f\n\t"
        "   stlxr  %w[s], %w[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n\t"
        "2:\n"
        : [l]"=&r"(l), [s]"=&r"(s) : [m]"r"(m), [e]"r"(e), [d]"r"(d) : "cc","memory");
    return l;
}
A uint32_t __aarch64_cas4_acq(uint32_t e, uint32_t d, volatile uint32_t *m)     { return __aarch64_cas4_relax(e,d,m); }
A uint32_t __aarch64_cas4_rel(uint32_t e, uint32_t d, volatile uint32_t *m)     { return __aarch64_cas4_relax(e,d,m); }
A uint32_t __aarch64_cas4_acq_rel(uint32_t e, uint32_t d, volatile uint32_t *m) { return __aarch64_cas4_relax(e,d,m); }

A uint16_t __aarch64_cas2_relax(uint16_t e, uint16_t d, volatile uint16_t *m)
{
    uint32_t l, s;
    __asm__ __volatile__(
        "1: ldaxrh %w[l], [%[m]]\n\t"
        "   cmp    %w[l], %w[e]\n\t"
        "   b.ne   2f\n\t"
        "   stlxrh %w[s], %w[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n\t"
        "2:\n"
        : [l]"=&r"(l), [s]"=&r"(s)
        : [m]"r"(m), [e]"r"((uint32_t)e), [d]"r"((uint32_t)d) : "cc","memory");
    return (uint16_t)l;
}
A uint16_t __aarch64_cas2_acq(uint16_t e, uint16_t d, volatile uint16_t *m)     { return __aarch64_cas2_relax(e,d,m); }
A uint16_t __aarch64_cas2_rel(uint16_t e, uint16_t d, volatile uint16_t *m)     { return __aarch64_cas2_relax(e,d,m); }
A uint16_t __aarch64_cas2_acq_rel(uint16_t e, uint16_t d, volatile uint16_t *m) { return __aarch64_cas2_relax(e,d,m); }

A uint8_t __aarch64_cas1_relax(uint8_t e, uint8_t d, volatile uint8_t *m)
{
    uint32_t l, s;
    __asm__ __volatile__(
        "1: ldaxrb %w[l], [%[m]]\n\t"
        "   cmp    %w[l], %w[e]\n\t"
        "   b.ne   2f\n\t"
        "   stlxrb %w[s], %w[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n\t"
        "2:\n"
        : [l]"=&r"(l), [s]"=&r"(s)
        : [m]"r"(m), [e]"r"((uint32_t)e), [d]"r"((uint32_t)d) : "cc","memory");
    return (uint8_t)l;
}
A uint8_t __aarch64_cas1_acq(uint8_t e, uint8_t d, volatile uint8_t *m)     { return __aarch64_cas1_relax(e,d,m); }
A uint8_t __aarch64_cas1_rel(uint8_t e, uint8_t d, volatile uint8_t *m)     { return __aarch64_cas1_relax(e,d,m); }
A uint8_t __aarch64_cas1_acq_rel(uint8_t e, uint8_t d, volatile uint8_t *m) { return __aarch64_cas1_relax(e,d,m); }

/* SWP (exchange): (desired, *mem) -> old value */

A uint64_t __aarch64_swp8_relax(uint64_t d, volatile uint64_t *m)
{
    uint64_t l; uint32_t s;
    __asm__ __volatile__(
        "1: ldaxr  %[l], [%[m]]\n\t"
        "   stlxr  %w[s], %[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint64_t __aarch64_swp8_acq(uint64_t d, volatile uint64_t *m)     { return __aarch64_swp8_relax(d,m); }
A uint64_t __aarch64_swp8_rel(uint64_t d, volatile uint64_t *m)     { return __aarch64_swp8_relax(d,m); }
A uint64_t __aarch64_swp8_acq_rel(uint64_t d, volatile uint64_t *m) { return __aarch64_swp8_relax(d,m); }

A uint32_t __aarch64_swp4_relax(uint32_t d, volatile uint32_t *m)
{
    uint32_t l, s;
    __asm__ __volatile__(
        "1: ldaxr  %w[l], [%[m]]\n\t"
        "   stlxr  %w[s], %w[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint32_t __aarch64_swp4_acq(uint32_t d, volatile uint32_t *m)     { return __aarch64_swp4_relax(d,m); }
A uint32_t __aarch64_swp4_rel(uint32_t d, volatile uint32_t *m)     { return __aarch64_swp4_relax(d,m); }
A uint32_t __aarch64_swp4_acq_rel(uint32_t d, volatile uint32_t *m) { return __aarch64_swp4_relax(d,m); }

A uint16_t __aarch64_swp2_relax(uint16_t d, volatile uint16_t *m)
{
    uint32_t l, s;
    __asm__ __volatile__(
        "1: ldaxrh %w[l], [%[m]]\n\t"
        "   stlxrh %w[s], %w[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint16_t)l;
}
A uint16_t __aarch64_swp2_acq(uint16_t d, volatile uint16_t *m)     { return __aarch64_swp2_relax(d,m); }
A uint16_t __aarch64_swp2_rel(uint16_t d, volatile uint16_t *m)     { return __aarch64_swp2_relax(d,m); }
A uint16_t __aarch64_swp2_acq_rel(uint16_t d, volatile uint16_t *m) { return __aarch64_swp2_relax(d,m); }

A uint8_t __aarch64_swp1_relax(uint8_t d, volatile uint8_t *m)
{
    uint32_t l, s;
    __asm__ __volatile__(
        "1: ldaxrb %w[l], [%[m]]\n\t"
        "   stlxrb %w[s], %w[d], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint8_t)l;
}
A uint8_t __aarch64_swp1_acq(uint8_t d, volatile uint8_t *m)     { return __aarch64_swp1_relax(d,m); }
A uint8_t __aarch64_swp1_rel(uint8_t d, volatile uint8_t *m)     { return __aarch64_swp1_relax(d,m); }
A uint8_t __aarch64_swp1_acq_rel(uint8_t d, volatile uint8_t *m) { return __aarch64_swp1_relax(d,m); }

/* LDADD (fetch-and-add): (val, *mem) -> old value */

A uint64_t __aarch64_ldadd8_relax(uint64_t d, volatile uint64_t *m)
{
    uint64_t l, n; uint32_t s;
    __asm__ __volatile__(
        "1: ldaxr  %[l], [%[m]]\n\t"
        "   add    %[n], %[l], %[d]\n\t"
        "   stlxr  %w[s], %[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint64_t __aarch64_ldadd8_acq(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldadd8_relax(d,m); }
A uint64_t __aarch64_ldadd8_rel(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldadd8_relax(d,m); }
A uint64_t __aarch64_ldadd8_acq_rel(uint64_t d, volatile uint64_t *m) { return __aarch64_ldadd8_relax(d,m); }

A uint32_t __aarch64_ldadd4_relax(uint32_t d, volatile uint32_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxr  %w[l], [%[m]]\n\t"
        "   add    %w[n], %w[l], %w[d]\n\t"
        "   stlxr  %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint32_t __aarch64_ldadd4_acq(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldadd4_relax(d,m); }
A uint32_t __aarch64_ldadd4_rel(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldadd4_relax(d,m); }
A uint32_t __aarch64_ldadd4_acq_rel(uint32_t d, volatile uint32_t *m) { return __aarch64_ldadd4_relax(d,m); }

A uint16_t __aarch64_ldadd2_relax(uint16_t d, volatile uint16_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrh %w[l], [%[m]]\n\t"
        "   add    %w[n], %w[l], %w[d]\n\t"
        "   stlxrh %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint16_t)l;
}
A uint16_t __aarch64_ldadd2_acq(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldadd2_relax(d,m); }
A uint16_t __aarch64_ldadd2_rel(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldadd2_relax(d,m); }
A uint16_t __aarch64_ldadd2_acq_rel(uint16_t d, volatile uint16_t *m) { return __aarch64_ldadd2_relax(d,m); }

A uint8_t __aarch64_ldadd1_relax(uint8_t d, volatile uint8_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrb %w[l], [%[m]]\n\t"
        "   add    %w[n], %w[l], %w[d]\n\t"
        "   stlxrb %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint8_t)l;
}
A uint8_t __aarch64_ldadd1_acq(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldadd1_relax(d,m); }
A uint8_t __aarch64_ldadd1_rel(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldadd1_relax(d,m); }
A uint8_t __aarch64_ldadd1_acq_rel(uint8_t d, volatile uint8_t *m) { return __aarch64_ldadd1_relax(d,m); }

/* LDCLR (fetch-and-clear / BIC): (val, *mem) -> old value */

A uint64_t __aarch64_ldclr8_relax(uint64_t d, volatile uint64_t *m)
{
    uint64_t l, n; uint32_t s;
    __asm__ __volatile__(
        "1: ldaxr  %[l], [%[m]]\n\t"
        "   bic    %[n], %[l], %[d]\n\t"
        "   stlxr  %w[s], %[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint64_t __aarch64_ldclr8_acq(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldclr8_relax(d,m); }
A uint64_t __aarch64_ldclr8_rel(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldclr8_relax(d,m); }
A uint64_t __aarch64_ldclr8_acq_rel(uint64_t d, volatile uint64_t *m) { return __aarch64_ldclr8_relax(d,m); }

A uint32_t __aarch64_ldclr4_relax(uint32_t d, volatile uint32_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxr  %w[l], [%[m]]\n\t"
        "   bic    %w[n], %w[l], %w[d]\n\t"
        "   stlxr  %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint32_t __aarch64_ldclr4_acq(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldclr4_relax(d,m); }
A uint32_t __aarch64_ldclr4_rel(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldclr4_relax(d,m); }
A uint32_t __aarch64_ldclr4_acq_rel(uint32_t d, volatile uint32_t *m) { return __aarch64_ldclr4_relax(d,m); }

A uint16_t __aarch64_ldclr2_relax(uint16_t d, volatile uint16_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrh %w[l], [%[m]]\n\t"
        "   bic    %w[n], %w[l], %w[d]\n\t"
        "   stlxrh %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint16_t)l;
}
A uint16_t __aarch64_ldclr2_acq(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldclr2_relax(d,m); }
A uint16_t __aarch64_ldclr2_rel(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldclr2_relax(d,m); }
A uint16_t __aarch64_ldclr2_acq_rel(uint16_t d, volatile uint16_t *m) { return __aarch64_ldclr2_relax(d,m); }

A uint8_t __aarch64_ldclr1_relax(uint8_t d, volatile uint8_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrb %w[l], [%[m]]\n\t"
        "   bic    %w[n], %w[l], %w[d]\n\t"
        "   stlxrb %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint8_t)l;
}
A uint8_t __aarch64_ldclr1_acq(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldclr1_relax(d,m); }
A uint8_t __aarch64_ldclr1_rel(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldclr1_relax(d,m); }
A uint8_t __aarch64_ldclr1_acq_rel(uint8_t d, volatile uint8_t *m) { return __aarch64_ldclr1_relax(d,m); }

/* LDSET (fetch-and-set / ORR): (val, *mem) -> old value */

A uint64_t __aarch64_ldset8_relax(uint64_t d, volatile uint64_t *m)
{
    uint64_t l, n; uint32_t s;
    __asm__ __volatile__(
        "1: ldaxr  %[l], [%[m]]\n\t"
        "   orr    %[n], %[l], %[d]\n\t"
        "   stlxr  %w[s], %[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint64_t __aarch64_ldset8_acq(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldset8_relax(d,m); }
A uint64_t __aarch64_ldset8_rel(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldset8_relax(d,m); }
A uint64_t __aarch64_ldset8_acq_rel(uint64_t d, volatile uint64_t *m) { return __aarch64_ldset8_relax(d,m); }

A uint32_t __aarch64_ldset4_relax(uint32_t d, volatile uint32_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxr  %w[l], [%[m]]\n\t"
        "   orr    %w[n], %w[l], %w[d]\n\t"
        "   stlxr  %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint32_t __aarch64_ldset4_acq(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldset4_relax(d,m); }
A uint32_t __aarch64_ldset4_rel(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldset4_relax(d,m); }
A uint32_t __aarch64_ldset4_acq_rel(uint32_t d, volatile uint32_t *m) { return __aarch64_ldset4_relax(d,m); }

A uint16_t __aarch64_ldset2_relax(uint16_t d, volatile uint16_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrh %w[l], [%[m]]\n\t"
        "   orr    %w[n], %w[l], %w[d]\n\t"
        "   stlxrh %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint16_t)l;
}
A uint16_t __aarch64_ldset2_acq(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldset2_relax(d,m); }
A uint16_t __aarch64_ldset2_rel(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldset2_relax(d,m); }
A uint16_t __aarch64_ldset2_acq_rel(uint16_t d, volatile uint16_t *m) { return __aarch64_ldset2_relax(d,m); }

A uint8_t __aarch64_ldset1_relax(uint8_t d, volatile uint8_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrb %w[l], [%[m]]\n\t"
        "   orr    %w[n], %w[l], %w[d]\n\t"
        "   stlxrb %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint8_t)l;
}
A uint8_t __aarch64_ldset1_acq(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldset1_relax(d,m); }
A uint8_t __aarch64_ldset1_rel(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldset1_relax(d,m); }
A uint8_t __aarch64_ldset1_acq_rel(uint8_t d, volatile uint8_t *m) { return __aarch64_ldset1_relax(d,m); }

/* LDEOR (fetch-and-xor / EOR): (val, *mem) -> old value */

A uint64_t __aarch64_ldeor8_relax(uint64_t d, volatile uint64_t *m)
{
    uint64_t l, n; uint32_t s;
    __asm__ __volatile__(
        "1: ldaxr  %[l], [%[m]]\n\t"
        "   eor    %[n], %[l], %[d]\n\t"
        "   stlxr  %w[s], %[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint64_t __aarch64_ldeor8_acq(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldeor8_relax(d,m); }
A uint64_t __aarch64_ldeor8_rel(uint64_t d, volatile uint64_t *m)     { return __aarch64_ldeor8_relax(d,m); }
A uint64_t __aarch64_ldeor8_acq_rel(uint64_t d, volatile uint64_t *m) { return __aarch64_ldeor8_relax(d,m); }

A uint32_t __aarch64_ldeor4_relax(uint32_t d, volatile uint32_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxr  %w[l], [%[m]]\n\t"
        "   eor    %w[n], %w[l], %w[d]\n\t"
        "   stlxr  %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"(d) : "memory");
    return l;
}
A uint32_t __aarch64_ldeor4_acq(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldeor4_relax(d,m); }
A uint32_t __aarch64_ldeor4_rel(uint32_t d, volatile uint32_t *m)     { return __aarch64_ldeor4_relax(d,m); }
A uint32_t __aarch64_ldeor4_acq_rel(uint32_t d, volatile uint32_t *m) { return __aarch64_ldeor4_relax(d,m); }

A uint16_t __aarch64_ldeor2_relax(uint16_t d, volatile uint16_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrh %w[l], [%[m]]\n\t"
        "   eor    %w[n], %w[l], %w[d]\n\t"
        "   stlxrh %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint16_t)l;
}
A uint16_t __aarch64_ldeor2_acq(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldeor2_relax(d,m); }
A uint16_t __aarch64_ldeor2_rel(uint16_t d, volatile uint16_t *m)     { return __aarch64_ldeor2_relax(d,m); }
A uint16_t __aarch64_ldeor2_acq_rel(uint16_t d, volatile uint16_t *m) { return __aarch64_ldeor2_relax(d,m); }

A uint8_t __aarch64_ldeor1_relax(uint8_t d, volatile uint8_t *m)
{
    uint32_t l, n, s;
    __asm__ __volatile__(
        "1: ldaxrb %w[l], [%[m]]\n\t"
        "   eor    %w[n], %w[l], %w[d]\n\t"
        "   stlxrb %w[s], %w[n], [%[m]]\n\t"
        "   cbnz   %w[s], 1b\n"
        : [l]"=&r"(l), [n]"=&r"(n), [s]"=&r"(s) : [m]"r"(m), [d]"r"((uint32_t)d) : "memory");
    return (uint8_t)l;
}
A uint8_t __aarch64_ldeor1_acq(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldeor1_relax(d,m); }
A uint8_t __aarch64_ldeor1_rel(uint8_t d, volatile uint8_t *m)     { return __aarch64_ldeor1_relax(d,m); }
A uint8_t __aarch64_ldeor1_acq_rel(uint8_t d, volatile uint8_t *m) { return __aarch64_ldeor1_relax(d,m); }
