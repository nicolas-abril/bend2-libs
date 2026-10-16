# gralha-ustar

POSIX ustar archives over `gralha-byte-words`. Members are regular files only:
mode 0644, uid and gid 0, mtime 0.

```python
import gralha-ustar@0.1.0.0/ustar.bend as Ustar
```

- `header(name, size)`: a member's 512-byte header, checksum included.
- `create_stream(names, verbose, out, first)`: writes an archive of the named
  files to `out` one member at a time. File contents never pass through Bend.
- `manifest(names, verbose)` and `fill(...)`: produce the archive stream into
  bounded `Sink` batches, for a compressor to consume (see the gralha tar).
- `walk((a, n), extract, verbose)`: lists or extracts an archive held in
  memory.
- `list_file(file, a, got, path, n)`: lists an archive from an open file,
  reading only its headers.
- `header_at(a, off, n)`: the parsed header at an offset.

Depends on: `gralha-byte-words`. Tests: `bend tests/check.bend` archives two
files and lists them both ways.
