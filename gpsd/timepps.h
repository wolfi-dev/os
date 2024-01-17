/*
 * timepps.h -- PPS API main header
 *
 * Copyright (C) 2005-2007   Rodolfo Giometti <giometti@linux.it>
 * Copyright (C) 2009-2011   Alexander Gordeev <alex@gordick.net>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 * Source: https://github.com/ago/pps-tools/ - Retreived 2022-09-03
 */

#ifndef _SYS_TIMEPPS_H_
#define _SYS_TIMEPPS_H_

#include <errno.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/pps.h>

#define LINUXPPS	1		/* signal we are using LinuxPPS */

/*
 * New data structures
 */

struct ntp_fp {
	unsigned int integral;
	unsigned int fractional;
};

union pps_timeu {
	struct timespec tspec;
	struct ntp_fp ntpfp;
	unsigned long longpad[3];
};

struct pps_info {
	unsigned long assert_sequence;	/* seq. num. of assert event */
	unsigned long clear_sequence;	/* seq. num. of clear event */
	union pps_timeu assert_tu;	/* time of assert event */
	union pps_timeu clear_tu;	/* time of clear event */
	int current_mode;		/* current mode bits */
};

struct pps_params {
	int api_version;		/* API version # */
	int mode;			/* mode bits */
	union pps_timeu assert_off_tu;	/* offset compensation for assert */
	union pps_timeu clear_off_tu;	/* offset compensation for clear */
};

typedef int pps_handle_t;		/* represents a PPS source */
typedef unsigned long pps_seq_t;	/* sequence number */
typedef struct ntp_fp ntp_fp_t;		/* NTP-compatible time stamp */
typedef union pps_timeu pps_timeu_t;	/* generic data type for time stamps */
typedef struct pps_info pps_info_t;
typedef struct pps_params pps_params_t;

#define assert_timestamp        assert_tu.tspec
#define clear_timestamp         clear_tu.tspec

#define assert_timestamp_ntpfp  assert_tu.ntpfp
#define clear_timestamp_ntpfp   clear_tu.ntpfp

#define assert_offset		assert_off_tu.tspec
#define clear_offset		clear_off_tu.tspec

#define assert_offset_ntpfp     assert_off_tu.ntpfp
#define clear_offset_ntpfp      clear_off_tu.ntpfp

/*
 * The PPS API
 */

static __inline int time_pps_create(int source, pps_handle_t *handle)
{
	int ret;
	struct pps_kparams dummy;

	if (!handle) {
		errno = EINVAL;
		return -1;
	}

	/* First we check if current device is a valid PPS one by
	 * doing a dummy PPS_GETPARAMS...
	 */
	ret = ioctl(source, PPS_GETPARAMS, &dummy);
	if (ret) {
		errno = EOPNOTSUPP;
		return -1;
	}

	/* ... then since in LinuxPPS there are no differences between a
	 * "PPS source" and a "PPS handle", we simply return the same value.
	 */
	*handle = source;

	return 0;
}

static __inline int time_pps_destroy(pps_handle_t handle)
{
	return close(handle);
}

static __inline int time_pps_getparams(pps_handle_t handle,
					pps_params_t *ppsparams)
{
	int ret;
	struct pps_kparams __ppsparams = {};

	ret = ioctl(handle, PPS_GETPARAMS, &__ppsparams);

	ppsparams->api_version = __ppsparams.api_version;
	ppsparams->mode = __ppsparams.mode;
	ppsparams->assert_off_tu.tspec.tv_sec = __ppsparams.assert_off_tu.sec;
	ppsparams->assert_off_tu.tspec.tv_nsec = __ppsparams.assert_off_tu.nsec;
	ppsparams->clear_off_tu.tspec.tv_sec = __ppsparams.clear_off_tu.sec;
	ppsparams->clear_off_tu.tspec.tv_nsec = __ppsparams.clear_off_tu.nsec;

	return ret;
}

static __inline int time_pps_setparams(pps_handle_t handle,
					const pps_params_t *ppsparams)
{
	struct pps_kparams __ppsparams = {};

	__ppsparams.api_version = ppsparams->api_version;
	__ppsparams.mode = ppsparams->mode;
	__ppsparams.assert_off_tu.sec = ppsparams->assert_off_tu.tspec.tv_sec;
	__ppsparams.assert_off_tu.nsec = ppsparams->assert_off_tu.tspec.tv_nsec;
	__ppsparams.clear_off_tu.sec = ppsparams->clear_off_tu.tspec.tv_sec;
	__ppsparams.clear_off_tu.nsec = ppsparams->clear_off_tu.tspec.tv_nsec;

	return ioctl(handle, PPS_SETPARAMS, &__ppsparams);
}

/* Get capabilities for handle */
static __inline int time_pps_getcap(pps_handle_t handle, int *mode)
{
	return ioctl(handle, PPS_GETCAP, mode);
}

static __inline int time_pps_fetch(pps_handle_t handle, const int tsformat,
					pps_info_t *ppsinfobuf,
					const struct timespec *timeout)
{
	struct pps_fdata __fdata = {};
	int ret;

	/* Sanity checks */
	if (tsformat != PPS_TSFMT_TSPEC) {
		errno = EINVAL;
		return -1;
	}

	if (timeout) {
		__fdata.timeout.sec = timeout->tv_sec;
		__fdata.timeout.nsec = timeout->tv_nsec;
	} else
		__fdata.timeout.flags = PPS_TIME_INVALID;

	ret = ioctl(handle, PPS_FETCH, &__fdata);

	ppsinfobuf->assert_sequence = __fdata.info.assert_sequence;
	ppsinfobuf->clear_sequence = __fdata.info.clear_sequence;
	ppsinfobuf->assert_tu.tspec.tv_sec = __fdata.info.assert_tu.sec;
	ppsinfobuf->assert_tu.tspec.tv_nsec = __fdata.info.assert_tu.nsec;
	ppsinfobuf->clear_tu.tspec.tv_sec = __fdata.info.clear_tu.sec;
	ppsinfobuf->clear_tu.tspec.tv_nsec = __fdata.info.clear_tu.nsec;
	ppsinfobuf->current_mode = __fdata.info.current_mode;

	return ret;
}

#ifdef PPS_KC_BIND

static __inline int time_pps_kcbind(pps_handle_t handle,
					const int kernel_consumer,
					const int edge, const int tsformat)
{
	struct pps_bind_args __bind_args = {};

	__bind_args.tsformat = tsformat;
	__bind_args.edge = edge;
	__bind_args.consumer = kernel_consumer;

	return ioctl(handle, PPS_KC_BIND, &__bind_args);
}

#else /* !PPS_KC_BIND */

static __inline int time_pps_kcbind(pps_handle_t handle,
					const int kernel_consumer,
					const int edge, const int tsformat)
{
	/* LinuxPPS doesn't implement kernel consumer feature */
	errno = EOPNOTSUPP;
	return -1;
}

#endif /* PPS_KC_BIND */

#endif /* _SYS_TIMEPPS_H_ */