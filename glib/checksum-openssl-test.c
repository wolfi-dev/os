/* Exercises the OpenSSL GChecksum/GHmac backend.
 *
 * Usage: checksum-openssl-test MODE
 *   default      no FIPS config: every algorithm works, fips.so not loaded
 *   restricted   config whose providers offer nothing: every constructor
 *                returns NULL (proves glib never falls back to built-in code)
 *   fips         fipshardened config: SHA/HMAC from fips.so, MD5 allowed
 *   fips-strict  fipshardened, CHAINGUARD_LEGACY_ALLOWED=0: MD5 rejected
 *
 * -DNO_LIBCRYPTO drops the error-queue check, for builds without libcrypto
 * (the static libglib keeps GLib's built-in code).
 */
#include <glib.h>
#ifndef NO_LIBCRYPTO
#include <openssl/err.h>
#endif
#include <string.h>

#define SHA1_ABC   "a9993e364706816aba3e25717850c26c9cd0d89d"
#define SHA256_ABC "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
#define SHA384_ABC "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"
#define SHA512_ABC "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
#define MD5_ABC    "900150983cd24fb0d6963f7d28e17f72"
/* RFC 4231 test case 1 and a divergent continuation of it */
#define HMAC256_HI "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"
#define HMAC256_HI_MORE "fffb8e86c905e669d49de41b4e1d22976e40950d16a3be9284b99615f7fba6c8"
#define HMAC512_HI "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854"
#define HMAC256_EMPTY "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad"

static guint warnings;

static void
count_warning (const gchar *domain, GLogLevelFlags level,
               const gchar *message, gpointer data)
{
  g_printerr ("captured: %s\n", message);
  warnings++;
}

static gboolean
fips_provider_loaded (void)
{
  gchar *maps = NULL;
  gboolean found;

  g_assert_true (g_file_get_contents ("/proc/self/maps", &maps, NULL, NULL));
  found = strstr (maps, "/fips.so") != NULL;
  g_free (maps);

  return found;
}

static gpointer
hash_in_thread (gpointer data)
{
  for (int i = 0; i < 200; i++)
    {
      gchar *s = g_compute_checksum_for_string (G_CHECKSUM_SHA256, "abc", -1);
      g_assert_cmpstr (s, ==, SHA256_ABC);
      g_free (s);
    }
  return NULL;
}

/* The first checksum in the process loads libcrypto; race it. */
static void
check_concurrent_first_use (void)
{
  GThread *threads[8];

  for (guint i = 0; i < G_N_ELEMENTS (threads); i++)
    threads[i] = g_thread_new ("hash", hash_in_thread, NULL);
  for (guint i = 0; i < G_N_ELEMENTS (threads); i++)
    g_thread_join (threads[i]);
}

static void
check_digest (GChecksumType type, const gchar *expected)
{
  gchar *s = g_compute_checksum_for_string (type, "abc", -1);
  g_assert_cmpstr (s, ==, expected);
  g_free (s);
}

static void
check_checksum_semantics (void)
{
  guint8 d1[32], d2[32];
  gsize l1 = sizeof (d1), l2 = sizeof (d2);
  GChecksum *a, *b;
  guint before;

  /* get_string and get_digest after closing agree and are repeatable */
  a = g_checksum_new (G_CHECKSUM_SHA256);
  g_checksum_update (a, (const guchar *) "abc", -1);
  g_assert_cmpstr (g_checksum_get_string (a), ==, SHA256_ABC);
  g_assert_cmpstr (g_checksum_get_string (a), ==, SHA256_ABC);
  g_checksum_get_digest (a, d1, &l1);
  g_assert_cmpuint (l1, ==, 32);

  /* updating a closed checksum warns and leaves it unchanged */
  before = warnings;
  g_checksum_update (a, (const guchar *) "x", 1);
  g_assert_cmpuint (warnings, ==, before + 1);
  g_assert_cmpstr (g_checksum_get_string (a), ==, SHA256_ABC);

  /* a copy of a closed checksum is closed with the same digest, and
   * can be reset and reused */
  b = g_checksum_copy (a);
  g_assert_cmpstr (g_checksum_get_string (b), ==, SHA256_ABC);
  g_checksum_get_digest (b, d2, &l2);
  g_assert_cmpmem (d1, l1, d2, l2);
  g_checksum_reset (b);
  g_checksum_update (b, (const guchar *) "ab", 2);
  g_checksum_update (b, (const guchar *) "c", 1);
  g_assert_cmpstr (g_checksum_get_string (b), ==, SHA256_ABC);
  g_checksum_free (a);
  g_checksum_free (b);

  /* empty input, and a copy of an open checksum diverging */
  check_digest (G_CHECKSUM_SHA256, SHA256_ABC);
  a = g_checksum_new (G_CHECKSUM_SHA256);
  g_assert_cmpstr (g_checksum_get_string (a),
                   ==, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
  g_checksum_free (a);
}

static void
check_hmac_semantics (void)
{
  guchar key[20];
  guint8 digest[32];
  gsize len = sizeof (digest);
  GHmac *a, *b;
  gchar *s;

  memset (key, 0x0b, sizeof (key));

  s = g_compute_hmac_for_string (G_CHECKSUM_SHA256, key, sizeof (key), "Hi There", -1);
  g_assert_cmpstr (s, ==, HMAC256_HI);
  g_free (s);
  s = g_compute_hmac_for_string (G_CHECKSUM_SHA512, key, sizeof (key), "Hi There", -1);
  g_assert_cmpstr (s, ==, HMAC512_HI);
  g_free (s);

  /* copy mid-stream, then diverge */
  a = g_hmac_new (G_CHECKSUM_SHA256, key, sizeof (key));
  g_assert_nonnull (a);
  g_hmac_update (a, (const guchar *) "Hi ", -1);
  b = g_hmac_copy (a);
  g_hmac_update (a, (const guchar *) "There", -1);
  g_hmac_update (b, (const guchar *) "There, more", -1);
  g_assert_cmpstr (g_hmac_get_string (a), ==, HMAC256_HI);
  g_assert_cmpstr (g_hmac_get_string (b), ==, HMAC256_HI_MORE);

  /* get_digest after get_string returns the same bytes */
  g_hmac_get_digest (a, digest, &len);
  s = g_strdup (g_hmac_get_string (a));
  g_assert_cmpuint (len, ==, 32);
  g_assert_cmpint (strncmp (s, "b0344c61", 8), ==, 0);
  g_assert_cmpuint (digest[0], ==, 0xb0);
  g_assert_cmpuint (digest[31], ==, 0xf7);
  g_free (s);
  g_hmac_unref (a);
  g_hmac_unref (b);
}

static void
check_error_queue_clean (void)
{
#ifndef NO_LIBCRYPTO
  g_assert_cmpuint (ERR_peek_error (), ==, 0);
#endif
}

int
main (int argc, char **argv)
{
  const gchar *mode;
  gboolean fips;

  g_assert_cmpint (argc, ==, 2);
  mode = argv[1];
  fips = g_str_has_prefix (mode, "fips");

  g_log_set_handler ("GLib", G_LOG_LEVEL_WARNING, count_warning, NULL);

  if (g_str_equal (mode, "restricted"))
    {
      guchar key[20] = { 0 };

      g_assert_null (g_checksum_new (G_CHECKSUM_SHA256));
      g_assert_null (g_checksum_new (G_CHECKSUM_MD5));
      g_assert_null (g_compute_checksum_for_string (G_CHECKSUM_SHA1, "abc", -1));
      g_assert_null (g_hmac_new (G_CHECKSUM_SHA256, key, sizeof (key)));
      g_assert_cmpuint (warnings, ==, 4);
      check_error_queue_clean ();
      g_assert_false (fips_provider_loaded ());
      g_print ("ok: %s\n", mode);
      return 0;
    }

  check_concurrent_first_use ();
  check_digest (G_CHECKSUM_SHA1, SHA1_ABC);
  check_digest (G_CHECKSUM_SHA256, SHA256_ABC);
  check_digest (G_CHECKSUM_SHA384, SHA384_ABC);
  check_digest (G_CHECKSUM_SHA512, SHA512_ABC);
  check_checksum_semantics ();
  check_hmac_semantics ();

  /* fips.so computes the HMAC and has no MD5; legacy-allowed only adds
   * the MD5 digest, so HMAC-MD5 is refused in both FIPS modes */
  if (fips)
    {
      guchar key[20] = { 0 };
      guint before = warnings;

      g_assert_null (g_hmac_new (G_CHECKSUM_MD5, key, sizeof (key)));
      g_assert_cmpuint (warnings, ==, before + 1);
      check_error_queue_clean ();
    }

  if (g_str_equal (mode, "fips-strict"))
    {
      guint before = warnings;

      g_assert_null (g_checksum_new (G_CHECKSUM_MD5));
      g_assert_cmpuint (warnings, ==, before + 1);
      check_error_queue_clean ();
    }
  else
    {
      check_digest (G_CHECKSUM_MD5, MD5_ABC);
    }

  if (!fips)
    {
      gchar *s = g_compute_hmac_for_string (G_CHECKSUM_SHA256,
                                            (const guchar *) "", 0, "", 0);
      g_assert_cmpstr (s, ==, HMAC256_EMPTY);
      g_free (s);
    }

  g_assert_true (fips_provider_loaded () == fips);
  check_error_queue_clean ();

  g_print ("ok: %s\n", mode);

  return 0;
}
