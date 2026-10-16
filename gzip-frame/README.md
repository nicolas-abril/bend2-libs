# gralha-gzip-frame

The RFC 1952 gzip container around `gralha-deflate`.

```python
import gralha-gzip-frame@0.1.0.0/gzip.bend as Gzip
```

- `is_gzip(a)`: whether a packed array starts with the 1f 8b magic.
- `decode(a, n)`: inflates a whole single-member file of `n` bytes. The extra,
  name, comment and header-CRC fields are skipped, and the output is sized by
  the ISIZE trailer. `decode_if(a, n, gz)` decodes only when `gz` is set.
- `write(path, file, a, n, level)`: compresses `n` packed bytes into one gzip
  member and writes it to an open file.
- `header(sink, level)` and `trailer(sink, crc, size)`: frame a stream that you
  compress and write in pieces, as the gralha tar does.

Depends on: `gralha-byte-words`, `gralha-crc32`, `gralha-deflate`. Tests:
`bend tests/check.bend` writes `gzip-test.gz` and decodes it back;
`gunzip -t gzip-test.gz` confirms it.
