// Read up to max bytes at offset into a packed Array without moving the
// file position. The open File handle and the packed byte count return.
Term file_words_read_at_run(Env e, Term* f, IoWork* w) {
  int fd = (int)io_hand_v(f[0]);
  uint64_t off = (uint64_t)(u32)f[1];
  uint64_t max = (uint64_t)(u32)f[2];
  uint64_t words = (max >> 2) + 3;
  u64 d = 0;
  while ((1ull << d) < words) d += 1;

  Term arr = blk_new(e, 0, d, 0, 0, NULL);
  uint8_t* data = (uint8_t*)blk_ptr(e.mem, blk_loc(e.mem, arr), 0);
  uint64_t got = 0;
  while (got < max) {
    ssize_t n = pread(fd, data + got, max - got, (off_t)(off + got));
    if (n < 0 && errno == EINTR) continue;
    if (n < 0) {
      return io_tup(e, io_hand(fd), io_fail(e, (u32)errno, NULL));
    }
    if (n == 0) break;
    got += (uint64_t)n;
  }
  return io_tup(e, io_hand(fd), io_done(e, io_tup(e, arr, (Term)got)));
}

static void __attribute__((constructor)) file_words_read_at_use(void) {
  io_eff(CID(file_read_at_raw), file_words_read_at_run);
}
