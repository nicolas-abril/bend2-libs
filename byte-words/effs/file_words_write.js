// Write n bytes of a packed Array to an open File. The File and Array return.
function file_write_words(file, a, start, n) {
  const fs = require("fs");
  const bytes = Buffer.allocUnsafe(n);
  for (let i = 0; i < n; i++) {
    const at = start + i;
    bytes[i] = (a[at >> 2] >>> (8 * (at & 3))) & 255;
  }
  try {
    let at = 0;
    while (at < n) at += fs.writeSync(file, bytes, at, n - at, null);
    return io_tup(file, io_tup(a, io_done({ $: CID(Unit) })));
  } catch (e) {
    return io_tup(file, io_tup(a, io_fail(Math.abs(e.errno ?? 5))));
  }
}

io_eff(CID(file_write_raw), file_write_words);
