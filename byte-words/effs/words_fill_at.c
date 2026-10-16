// Read exactly n bytes at file_off directly into a word-aligned range of an
// existing packed Array. The Array comes back outside the Result.
Term words_fill_at_run(Env e, Term* f, IoWork* w) {
  uint64_t path_n = 0;
  char* path = io_cstr(e, f[0], &path_n);
  uint64_t file_off = (uint64_t)(u32)f[1];
  Term arr = f[2];
  uint64_t start = (uint64_t)(u32)f[3];
  uint64_t count = (uint64_t)(u32)f[4];
  int fd = io_nul(path, path_n) ? -1 : open(path, O_RDONLY);
  if (fd < 0) {
    int err = errno != 0 ? errno : ENOENT;
    free(path);
    return io_tup(e, arr, io_fail(e, (u32)err, NULL));
  }
  free(path);

  uint8_t* dst = (uint8_t*)blk_ptr(e.mem, blk_loc(e.mem, arr), 0) + start;
  uint64_t done = 0;
  while (done < count) {
    ssize_t got = pread(fd, dst + done, count - done, (off_t)(file_off + done));
    if (got < 0 && errno == EINTR) continue;
    if (got <= 0) {
      int err = got < 0 && errno != 0 ? errno : EIO;
      close(fd);
      return io_tup(e, arr, io_fail(e, (u32)err, NULL));
    }
    done += (uint64_t)got;
  }
  if (close(fd) != 0) {
    return io_tup(e, arr, io_fail(e, (u32)(errno != 0 ? errno : EIO), NULL));
  }
  return io_tup(e, arr, io_done(e, term_pak(CID(Unit), 0)));
}

static void __attribute__((constructor)) words_fill_at_use(void) {
  io_eff(CID(fill_at_raw), words_fill_at_run);
}
