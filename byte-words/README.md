# gralha-byte-words

Bytes packed four to a `U32` word, little-endian, in an `Array<U32>`: the byte
layer the other gralha codecs (`gralha-deflate`, `gralha-gzip-frame`,
`gralha-ustar`) share. A file read this way costs one word per four bytes, not
a list cell per byte.

```python
import gralha-byte-words@0.1.0.0/words.bend as Words
```

- Reading: `byte_at(a, j)` and `le32_at(a, j)` read a byte or a four-byte
  window at any byte offset; both hand the array back.
- `Sink`: a growing output buffer (`sink_new`, `put_byte`, `put_str`,
  `put_le32`, `put_zeros`, `put_word_at`, `reserve`, `skip`). Its fields are
  the array, its capacity in words and its length in bytes.
- Files (foreign effects, C and JS): `read`, `write`, `fill_at`, `append`,
  `copy_range`, `file_read_at`, `sink_write`, `open_out`, and `file_size`
  (Base's `File.size`). Each `_raw` effect answers its `Result`; its plain twin
  exits the program with the error instead.

A packed array from `read` holds three spare zero words past its bytes, so a
four-byte window never reads past the end.

Depends on: Base only. Tests: `bend tests/check.bend` prints `ok`.
