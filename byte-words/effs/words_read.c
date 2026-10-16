// Words
// =====
// the whole file packed four bytes to a word, little-endian, in a
// buf block of 2^d u32 lanes with at least three spare words of zeros,
// and its byte count
Term words_read_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* path = io_cstr(e, f[0], &n);
  FILE* fp = io_nul(path, n) ? NULL : fopen(path, "rb");
  if (fp == NULL) {
    free(path);
    return io_fail(e, errno != 0 ? (u32)errno : ENOENT, NULL);
  }
  free(path);
  uint64_t cap = 1 << 20;
  uint64_t len = 0;
  uint8_t* buf = io_mem(malloc(cap));
  for (;;) {
    if (len + 65536 > cap) {
      cap *= 2;
      buf = io_mem(realloc(buf, cap));
    }
    size_t got = fread(buf + len, 1, cap - len, fp);
    if (got == 0) {
      break;
    }
    len += got;
  }
  fclose(fp);
  uint64_t words = (len >> 2) + 3;
  u64 d = 0;
  while ((1ull << d) < words) {
    d += 1;
  }
  Term arr = blk_new(e, 0, d, 0, 0, NULL);
  u64 loc = blk_loc(e.mem, arr);
  uint64_t full = len >> 2;
  for (uint64_t i = 0; i < full; i += 1) {
    uint32_t word;
    memcpy(&word, buf + i * 4, sizeof(word));
    blk_write(e.mem, 0, loc, (u32)i, word);
  }
  if ((len & 3) != 0) {
    uint32_t word = 0;
    memcpy(&word, buf + full * 4, len & 3);
    blk_write(e.mem, 0, loc, (u32)full, word);
  }
  free(buf);
  return io_done(e, io_tup(e, arr, (Term)len));
}

static void __attribute__((constructor)) words_read_use(void) {
  io_eff(CID(read_raw), words_read_run);
}
