// Words
// =====

// n bytes of the packed words from byte start into the file; the words
// come back outside the Result.
function words_write(path, a, start, n) {
  const fs = require("fs");
  const bytes = new Uint8Array(n);
  for (let j = 0; j < n; j++) {
    const at = start + j;
    bytes[j] = (a[at >> 2] >>> (8 * (at & 3))) & 255;
  }
  try {
    const fd = fs.openSync(path, "w");
    fs.writeSync(fd, bytes, 0, n, null);
    fs.closeSync(fd);
  } catch (e) {
    return io_tup(a, io_fail(Math.abs(e.errno ?? 5)));
  }
  return io_tup(a, io_done({ $: CID(Unit) }));
}

io_eff(CID(write_raw), words_write);
