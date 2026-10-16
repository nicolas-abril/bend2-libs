# gralha-bytes

Persistent byte buffers (`Bytes`, a balanced tree of packed words), bit
streams, Huffman codes, DEFLATE/zlib inflate, Adler-32 and CRC-32, base64 and
percent decoding, and `bytes.read`, a foreign effect (C and JS) that reads a
whole file straight into a `Bytes`.

    import gralha-bytes@0.1.0.0/bytes.bend as Bin

Main entry points: `bytes.read`, `bytes.get`, `bytes.set`, `bytes.push`,
`bytes.size`, `bytes.be`, `base64`, `inflate.blocks`, `zlib.result`,
`checksum.adler`.

The C side of `effs/bytes_read.c` uses runtime internals (`io_node`,
`io_seal`, `heap_alloc`), which carry no ABI promise across Bend releases.

Depends on: gralha-text-scan. Tests: `tests/` (run each from this directory).
