// Open a named output once, or duplicate stdout for the tar "-" spelling.
Term output_open_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* path = io_cstr(e, f[0], &n);
  int fd = -1;
  if (!io_nul(path, n)) {
    fd = strcmp(path, "/dev/stdout") == 0
      ? dup(STDOUT_FILENO)
      : open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  }
  int err = errno != 0 ? errno : EIO;
  free(path);
  return fd < 0 ? io_fail(e, (u32)err, NULL) : io_done(e, io_hand(fd));
}

static void __attribute__((constructor)) output_open_use(void) {
  io_eff(CID(open_out_raw), output_open_run);
}
