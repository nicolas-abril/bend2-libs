// Bytes
// =====

// The whole file as a Bin.Bytes value: a balanced tree of four-byte word
// leaves over the next power of two, zero leaves for the unused tail, byte
// count, capacity.
function bytes_read_tree(buf, lo, cap) {
  if (lo >= buf.length) {
    return { $: CID(ByteFlat), value: 0 };
  }
  if (cap <= 4) {
    let word = 0;
    for (let k = 0; k < cap && lo + k < buf.length; k++) {
      word += buf[lo + k] * 2 ** (8 * k);
    }
    return { $: CID(ByteWord), value: word };
  }
  const half = cap / 2;
  return { $: CID(ByteNode), left: bytes_read_tree(buf, lo, half), right: bytes_read_tree(buf, lo + half, half) };
}

function bytes_read_raw(path) {
  const fs = require("fs");
  let buf;
  try {
    buf = fs.readFileSync(path);
  } catch (e) {
    return io_fail(Math.abs(e.errno ?? 2));
  }
  let size = 1;
  while (size < buf.length) {
    size *= 2;
  }
  return io_done({ $: CID(Bytes), bufTree: bytes_read_tree(buf, 0, size), size: buf.length, capacity: size });
}

io_eff(CID(bytes.read.raw), bytes_read_raw);
