# gralha-deflate

RFC 1951 DEFLATE, encoder and decoder, over `gralha-byte-words` packed arrays.

```python
import gralha-deflate@0.1.0.0/deflate.bend as Deflate
```

- `inflate(a, pos, n, out_n)`: decodes the raw stream at byte `pos` of the `n`
  bytes of `a` into a new packed array of exactly `out_n` bytes.
- `compress(w, dict, n, level, final)`: compresses the `n` bytes after the
  first `dict` bytes of `w`, which seed the match window, at `level` 0-9.
  - It uses LZ77 with lazy matching on the slow levels, dynamic Huffman
    blocks, and stored blocks when they are smaller.
  - The input is cut into 248 KiB chunks that compress in parallel.
  - The result is a `Parts` tree of `Sink`s that concatenate into one stream.
  - With `final` false, the stream ends byte aligned so that another can
    follow it.
- `write(parts, path, file)`: writes the parts in order. `parts_list` flattens
  them.

At the same level, the output is the same on every thread count and on both the
C and JS targets.

Depends on: `gralha-byte-words`. Tests: `bend tests/check.bend` round-trips
about 300 KB at levels 0, 1, 6 and 9.
