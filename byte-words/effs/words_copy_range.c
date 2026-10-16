// Copy packed bytes between two Arrays. The gzip pipeline uses this once per
// batch to carry its 32 KiB dictionary without a Bend get/set loop.
Term words_copy_range_run(Env e, Term* f, IoWork* w) {
  Term src = f[0];
  uint64_t src_at = (uint64_t)(u32)f[1];
  Term dst = f[2];
  uint64_t dst_at = (uint64_t)(u32)f[3];
  uint64_t count = (uint64_t)(u32)f[4];
  const uint8_t* from = (const uint8_t*)blk_ptr(e.mem, blk_loc(e.mem, src), 0) + src_at;
  uint8_t* to = (uint8_t*)blk_ptr(e.mem, blk_loc(e.mem, dst), 0) + dst_at;
  memcpy(to, from, count);
  return io_tup(e, src, dst);
}

static void __attribute__((constructor)) words_copy_range_use(void) {
  io_eff(CID(copy_range), words_copy_range_run);
}
