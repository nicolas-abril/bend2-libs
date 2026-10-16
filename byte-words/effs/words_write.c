// Words
// =====
// n bytes of the packed words from byte start into the file; the
// words come back outside the Result
Term words_write_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* path = io_cstr(e, f[0], &n);
  Term arr = f[1];
  uint64_t start = (uint64_t)(uint32_t)f[2];
  uint64_t count = (uint64_t)(uint32_t)f[3];
  FILE* fp = io_nul(path, n) ? NULL : fopen(path, "wb");
  if (fp == NULL) {
    free(path);
    return io_tup(e, arr, io_fail(e, errno != 0 ? (u32)errno : ENOENT, NULL));
  }
  free(path);
  u64 loc = blk_loc(e.mem, arr);
  uint8_t* buf = io_mem(malloc(count + 4));
  uint64_t first = start >> 2;
  uint64_t last = (start + count + 3) >> 2;
  uint64_t at = 0;
  for (uint64_t q = first; q < last; q += 1) {
    uint32_t w = (uint32_t)blk_read(e.mem, 0, loc, (u32)q);
    for (uint64_t k = 0; k < 4; k += 1) {
      uint64_t j = q * 4 + k;
      if (j >= start && j < start + count) {
        buf[at++] = (uint8_t)(w >> (8 * k));
      }
    }
  }
  int bad = count > 0 && fwrite(buf, 1, count, fp) != count;
  free(buf);
  if (fclose(fp) != 0 || bad) {
    return io_tup(e, arr, io_fail(e, errno != 0 ? (u32)errno : EIO, NULL));
  }
  return io_tup(e, arr, io_done(e, term_pak(CID(Unit), 0)));
}

static void __attribute__((constructor)) words_write_use(void) {
  io_eff(CID(write_raw), words_write_run);
}
