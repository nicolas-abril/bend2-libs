// Copy packed bytes between two Arrays.
function words_copy_range(src, srcAt, dst, dstAt, n) {
  for (let i = 0; i < n; i += 4) {
    dst[(dstAt + i) >> 2] = src[(srcAt + i) >> 2];
  }
  return io_tup(src, dst);
}

io_eff(CID(copy_range), words_copy_range);
