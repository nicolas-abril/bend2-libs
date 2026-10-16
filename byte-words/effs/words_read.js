// Words
// =====

// The whole file packed four bytes to a word, little-endian, in an array
// of 2^d words with at least three spare words of zeros, and its byte count.
function words_read(path) {
  const fs = require("fs");
  let buf;
  try {
    buf = fs.readFileSync(path);
  } catch (e) {
    return io_fail(Math.abs(e.errno ?? 2));
  }
  const words = (buf.length >> 2) + 3;
  let n = 1;
  while (n < words) {
    n *= 2;
  }
  const a = new Array(n).fill(0);
  for (let i = 0; i < buf.length; i += 4) {
    a[i >> 2] = ((buf[i] | 0) | ((buf[i + 1] | 0) << 8) | ((buf[i + 2] | 0) << 16) | ((buf[i + 3] | 0) << 24)) >>> 0;
  }
  return io_done(io_tup(a, buf.length));
}

io_eff(CID(read_raw), words_read);
