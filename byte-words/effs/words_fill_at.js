// Read exactly n bytes at fileOff into a word-aligned packed Array range.
function words_fill_at(path, fileOff, a, start, n) {
  const fs = require("fs");
  let fd;
  try {
    fd = fs.openSync(path, "r");
    const buf = Buffer.allocUnsafe(n);
    let done = 0;
    while (done < n) {
      const got = fs.readSync(fd, buf, done, n - done, fileOff + done);
      if (got <= 0) throw Object.assign(new Error("short read"), { errno: 5 });
      done += got;
    }
    for (let i = 0; i < n; i += 4) {
      a[(start + i) >> 2] = ((buf[i] | 0) | ((buf[i + 1] | 0) << 8) |
        ((buf[i + 2] | 0) << 16) | ((buf[i + 3] | 0) << 24)) >>> 0;
    }
    fs.closeSync(fd);
    return io_tup(a, io_done({ $: CID(Unit) }));
  } catch (e) {
    if (fd !== undefined) try { fs.closeSync(fd); } catch (_) {}
    return io_tup(a, io_fail(Math.abs(e.errno ?? 5)));
  }
}

io_eff(CID(fill_at_raw), words_fill_at);
