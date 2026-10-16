// Read up to max bytes at offset into a packed Array without moving the file.
function file_words_read_at(file, offset, max) {
  const fs = require("fs");
  const bytes = Buffer.alloc(max);
  try {
    const got = fs.readSync(file, bytes, 0, max, offset);
    const words = (max >>> 2) + 3;
    let cap = 1;
    while (cap < words) cap *= 2;
    const out = new Array(cap).fill(0);
    for (let i = 0; i < got; i += 4) {
      out[i >>> 2] = ((bytes[i] | 0) | ((bytes[i + 1] | 0) << 8) |
        ((bytes[i + 2] | 0) << 16) | ((bytes[i + 3] | 0) << 24)) >>> 0;
    }
    return io_tup(file, io_done(io_tup(out, got)));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}

io_eff(CID(file_read_at_raw), file_words_read_at);
