# gralha-crc32

The IEEE CRC-32 used by gzip, zip and PNG, over bytes packed as
`gralha-byte-words` lays them out (four to a `U32`, little-endian).

```python
import gralha-crc32@0.1.0.0/crc32.bend as Crc32
```

- `update_raw(a, start, n, prior)`: a foreign effect, using the ARM CRC
  instructions where the C target has them and a table elsewhere. It answers
  the array and a `Result`. `update(what, a, start, n, prior)` exits with
  `what` on a failure.
- `pure(a, start, n, prior)`: the same function in plain Bend, a bit at a time.
  It is slow but needs no IO.

`prior` is the finished CRC of the bytes before `start` (0 for none), so a long
input can be checked in pieces.

Depends on: Base only. Tests: `bend tests/check.bend` checks both against the
`"123456789"` check value, 0xCBF43926.
