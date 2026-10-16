// Append packed header bytes, a file's bytes, and zero padding to an output.
function stream_append(outPath, a, headN, inPath, padN, first) {
  const fs = require("fs");
  let out;
  let input;
  const stdOut = outPath === "/dev/stdout";
  try {
    out = stdOut ? 1 : fs.openSync(outPath, first ? "w" : "a");
    const head = Buffer.allocUnsafe(headN);
    for (let j = 0; j < headN; j++) {
      head[j] = (a[j >> 2] >>> (8 * (j & 3))) & 255;
    }
    fs.writeSync(out, head);
    if (inPath.length !== 0) {
      input = fs.openSync(inPath, "r");
      const buf = Buffer.allocUnsafe(1 << 20);
      for (;;) {
        const got = fs.readSync(input, buf, 0, buf.length, null);
        if (got === 0) break;
        fs.writeSync(out, buf, 0, got);
      }
      fs.closeSync(input);
      input = undefined;
    }
    const zero = Buffer.alloc(Math.min(padN, 1 << 20));
    while (padN !== 0) {
      const take = Math.min(padN, zero.length);
      fs.writeSync(out, zero, 0, take);
      padN -= take;
    }
    if (!stdOut) fs.closeSync(out);
    return io_tup(a, io_done({ $: CID(Unit) }));
  } catch (e) {
    if (input !== undefined) try { fs.closeSync(input); } catch (_) {}
    if (out !== undefined && !stdOut) try { fs.closeSync(out); } catch (_) {}
    return io_tup(a, io_fail(Math.abs(e.errno ?? 5)));
  }
}

io_eff(CID(append_raw), stream_append);
