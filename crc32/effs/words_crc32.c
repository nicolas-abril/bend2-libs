#if defined(__aarch64__) && (defined(__APPLE__) || defined(__ARM_FEATURE_CRC32))
#define WORDS_HAVE_ARM_CRC 1
#include <arm_acle.h>
#endif

// Incremental IEEE CRC-32 over n bytes of a packed Array, starting at byte
// start. prior is the finalized CRC of preceding bytes. The Array comes back.
#if defined(WORDS_HAVE_ARM_CRC)
__attribute__((target("crc")))
static u32 words_crc32_arm(const u8* p, uint64_t n, u32 prior) {
  u32 crc = prior ^ UINT32_MAX;
  while (n >= 8) {
    uint64_t v;
    memcpy(&v, p, sizeof v);
    crc = __crc32d(crc, v);
    p += 8;
    n -= 8;
  }
  if (n >= 4) {
    u32 v;
    memcpy(&v, p, sizeof v);
    crc = __crc32w(crc, v);
    p += 4;
    n -= 4;
  }
  if (n >= 2) {
    uint16_t v;
    memcpy(&v, p, sizeof v);
    crc = __crc32h(crc, v);
    p += 2;
    n -= 2;
  }
  if (n != 0) crc = __crc32b(crc, *p);
  return crc ^ UINT32_MAX;
}
#endif

static u32 words_crc32_portable(const u8* p, uint64_t n, u32 prior) {
  u32 table[256];
  for (u32 i = 0; i < 256; i += 1) {
    u32 c = i;
    for (u32 k = 0; k < 8; k += 1) {
      c = (c >> 1) ^ ((c & 1) ? 0xedb88320u : 0);
    }
    table[i] = c;
  }
  u32 crc = prior ^ UINT32_MAX;
  for (uint64_t i = 0; i < n; i += 1) {
    crc = table[(crc ^ p[i]) & 255] ^ (crc >> 8);
  }
  return crc ^ UINT32_MAX;
}

Term words_crc32_run(Env e, Term* f, IoWork* w) {
  Term arr = f[0];
  uint64_t start = (uint64_t)(u32)f[1];
  uint64_t count = (uint64_t)(u32)f[2];
  u32 prior = (u32)f[3];
  const u8* p = (const u8*)blk_ptr(e.mem, blk_loc(e.mem, arr), 0) + start;
#if defined(WORDS_HAVE_ARM_CRC)
  u32 crc = words_crc32_arm(p, count, prior);
#else
  u32 crc = words_crc32_portable(p, count, prior);
#endif
  return io_tup(e, arr, io_done(e, (Term)crc));
}

static void __attribute__((constructor)) words_crc32_use(void) {
  io_eff(CID(update_raw), words_crc32_run);
}
