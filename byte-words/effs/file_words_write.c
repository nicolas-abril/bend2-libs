// Write n bytes of a packed Array to an open File without building an
// intermediate whole-output Array. The File and Array both come back.
Term file_words_write_run(Env e, Term* f, IoWork* w) {
  int fd = (int)io_hand_v(f[0]);
  Term arr = f[1];
  uint64_t start = (uint64_t)(u32)f[2];
  uint64_t count = (uint64_t)(u32)f[3];
  const u8* data = (const u8*)blk_ptr(e.mem, blk_loc(e.mem, arr), 0) + start;
  uint64_t at = 0;
  while (at < count) {
    ssize_t wrote = write(fd, data + at, count - at);
    if (wrote < 0 && errno == EINTR) continue;
    if (wrote <= 0) {
      u32 code = (u32)(errno != 0 ? errno : EIO);
      return io_tup(e, io_hand(fd), io_tup(e, arr, io_fail(e, code, NULL)));
    }
    at += (uint64_t)wrote;
  }
  return io_tup(e, io_hand(fd), io_tup(e, arr, io_done(e, term_pak(CID(Unit), 0))));
}

static void __attribute__((constructor)) file_words_write_use(void) {
  io_eff(CID(file_write_raw), file_words_write_run);
}
