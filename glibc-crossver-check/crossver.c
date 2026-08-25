/*
 * Compiled against an older glibc-<stream>-dev, executed against the newest
 * glibc runtime. Each call below is picked because it carries a symbol
 * version, so the link records a GLIBC_x.y requirement we can inspect.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <gnu/libc-version.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/random.h>

static int worker_ran;

static void *worker(void *arg)
{
	(void)arg;
	worker_ran = 1;
	return NULL;
}

static int cmp_int(const void *a, const void *b, void *ctx)
{
	(void)ctx;
	return *(const int *)a - *(const int *)b;
}

int main(void)
{
	/* pthread_create: moved into libc.so.6 at GLIBC_2.34 */
	pthread_t th;
	int rc = pthread_create(&th, NULL, worker, NULL);
	if (rc != 0) {
		fprintf(stderr, "pthread_create(&th, NULL, worker, NULL) returned %d, expected 0\n", rc);
		return 1;
	}
	pthread_join(th, NULL);
	if (worker_ran != 1) {
		fprintf(stderr, "worker() set worker_ran to %d, expected 1\n", worker_ran);
		return 1;
	}

	/* qsort_r: GLIBC_2.8 */
	int v[] = { 3, 1, 2 };
	qsort_r(v, 3, sizeof v[0], cmp_int, NULL);
	if (v[0] != 1 || v[1] != 2 || v[2] != 3) {
		fprintf(stderr, "qsort_r({3,1,2}, 3, cmp_int) returned {%d,%d,%d}, expected {1,2,3}\n",
			v[0], v[1], v[2]);
		return 1;
	}

	/* strlcpy: GLIBC_2.38, the newest symbol we deliberately depend on */
	char buf[8];
	size_t n = strlcpy(buf, "abc", sizeof buf);
	if (n != 3 || strcmp(buf, "abc") != 0) {
		fprintf(stderr, "strlcpy(buf, \"abc\", 8) returned %zu with buf=\"%s\", expected 3 with buf=\"abc\"\n",
			n, buf);
		return 1;
	}

	/* getrandom: GLIBC_2.25 */
	unsigned char r[4];
	ssize_t got = getrandom(r, sizeof r, 0);
	if (got != (ssize_t)sizeof r) {
		fprintf(stderr, "getrandom(r, 4, 0) returned %zd, expected 4\n", got);
		return 1;
	}

	/* exp/log pull in libm.so.6, so the libm.so linker script is exercised too */
	double x = log(exp(2.0));
	if (fabs(x - 2.0) > 1e-9) {
		fprintf(stderr, "log(exp(2.0)) returned %f, expected 2.000000\n", x);
		return 1;
	}

	/* dlopen: moved into libc.so.6 at GLIBC_2.34 */
	void *h = dlopen("libm.so.6", RTLD_LAZY);
	if (h == NULL) {
		fprintf(stderr, "dlopen(\"libm.so.6\", RTLD_LAZY) returned NULL (%s), expected a handle\n",
			dlerror());
		return 1;
	}
	dlclose(h);

	printf("runtime-glibc: %s\n", gnu_get_libc_version());
	return 0;
}
