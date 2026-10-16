// Append packed header bytes, a file's bytes, and zero padding to an output.
// first truncates a named output. Each call owns its stdio handles, so no
// foreign resource crosses the Bend effect boundary.
Term stream_append_run(Env e, Term* f, IoWork* w) {
  uint64_t out_n = 0;
  char* out_path = io_cstr(e, f[0], &out_n);
  Term arr = f[1];
  uint64_t head_n = (uint64_t)(u32)f[2];
  uint64_t in_n = 0;
  char* in_path = io_cstr(e, f[3], &in_n);
  uint64_t pad_n = (uint64_t)(u32)f[4];
  int first = (u32)f[5] != 0;
  int std_out = !io_nul(out_path, out_n) && strcmp(out_path, "/dev/stdout") == 0;
  FILE* out = std_out ? stdout : (io_nul(out_path, out_n) ? NULL : fopen(out_path, first ? "wb" : "ab"));
  if (out == NULL) {
    int err = errno != 0 ? errno : EIO;
    free(out_path);
    free(in_path);
    return io_tup(e, arr, io_fail(e, (u32)err, NULL));
  }
  free(out_path);

  uint8_t* buf = io_mem(malloc(1 << 20));
  u64 loc = blk_loc(e.mem, arr);
  uint64_t at = 0;
  while (at < head_n) {
    uint64_t take = head_n - at;
    if (take > (1 << 20)) take = 1 << 20;
    for (uint64_t j = 0; j < take; j += 1) {
      uint64_t p = at + j;
      u32 word = (u32)blk_read(e.mem, 0, loc, (u32)(p >> 2));
      buf[j] = (uint8_t)(word >> (8 * (p & 3)));
    }
    if (fwrite(buf, 1, take, out) != take) goto fail;
    at += take;
  }

  if (in_n != 0) {
    FILE* in = fopen(in_path, "rb");
    if (in == NULL) goto fail;
    for (;;) {
      size_t got = fread(buf, 1, 1 << 20, in);
      if (got != 0 && fwrite(buf, 1, got, out) != got) {
        fclose(in);
        goto fail;
      }
      if (got != (1 << 20)) {
        if (ferror(in)) {
          fclose(in);
          goto fail;
        }
        break;
      }
    }
    if (fclose(in) != 0) goto fail;
  }
  free(in_path);

  memset(buf, 0, pad_n < (1 << 20) ? pad_n : (1 << 20));
  while (pad_n != 0) {
    uint64_t take = pad_n > (1 << 20) ? (1 << 20) : pad_n;
    if (fwrite(buf, 1, take, out) != take) goto fail_no_path;
    pad_n -= take;
  }
  free(buf);
  if ((std_out ? fflush(out) : fclose(out)) != 0) {
    return io_tup(e, arr, io_fail(e, (u32)(errno != 0 ? errno : EIO), NULL));
  }
  return io_tup(e, arr, io_done(e, term_pak(CID(Unit), 0)));

fail:
  free(in_path);
fail_no_path: {
    int err = errno != 0 ? errno : EIO;
    free(buf);
    if (!std_out) fclose(out);
    return io_tup(e, arr, io_fail(e, (u32)err, NULL));
  }
}

static void __attribute__((constructor)) stream_append_use(void) {
  io_eff(CID(append_raw), stream_append_run);
}
