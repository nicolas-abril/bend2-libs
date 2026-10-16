# gralha-gzip-frame: the RFC 1952 gzip container around gralha-deflate.
# is_gzip checks the magic, decode inflates a whole member (sized by its
# ISIZE trailer), header and trailer frame a stream that is written in
# pieces, and write compresses a whole packed buffer into an open file.
import Base
import gralha-byte-words@0.1.0.0/words.bend as Words
import gralha-crc32@0.1.0.0/crc32.bend as Crc32
import gralha-deflate@0.1.0.0/deflate.bend as Deflate

def pick(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

# past a NUL-terminated field from pos
type Sk is Type:
  Sk{a: Array<U32>, pos: U32, more: Bool}

def sk_at(r: Array<U32> & U32, +pos: U32, +n: U32) -> Sk:
  (a, b) = r
  Sk{a, (pos + 1 : U32), U32.is_ne(b, 0) && U32.is_lt((pos + 1 : U32), n)}

def sk_loop(fuel: Nat, st: Sk, +n: U32) -> Sk:
  match fuel, st:
    case 0n, r:
      r
    case 1n+p, Sk{a, pos, more}:
      match more:
        case False{}:
          Sk{a, pos, False{}}
        case True{}:
          +pp = pos
          sk_loop(p, sk_at(Words.byte_at(a, pp), pp, n), n)

def sk_of(st: Sk) -> Array<U32> & U32:
  match st:
    case Sk{a, pos, more}:
      (a, pos)

def skip_nul_go(a: Array<U32>, +pos: U32, +n: U32, on: Bool) -> Array<U32> & U32:
  match on:
    case True{}:
      sk_of(sk_loop(U32.to_nat(n), Sk{a, pos, U32.is_lt(pos, n)}, n))
    case False{}:
      (a, pos)

def skip_nul(r: Array<U32> & U32, +n: U32, on: Bool) -> Array<U32> & U32:
  (a, pos) = r
  +p = pos
  skip_nul_go(a, p, n, on)

def skip_n(r: Array<U32> & U32, +k: U32, on: Bool) -> Array<U32> & U32:
  (a, pos) = r
  (a, (pos + pick(on, k, 0) : U32))

def skip_xlen(r: Array<U32> & U32, +pos: U32) -> Array<U32> & U32:
  (a, w) = r
  (a, (pos + 2 + (w .&. 65535) : U32))

def skip_extra_go(a: Array<U32>, +pos: U32, on: Bool) -> Array<U32> & U32:
  match on:
    case True{}:
      skip_xlen(Words.le32_at(a, pos), pos)
    case False{}:
      (a, pos)

def skip_extra(r: Array<U32> & U32, on: Bool) -> Array<U32> & U32:
  (a, pos) = r
  +p = pos
  skip_extra_go(a, p, on)

# the deflate stream's offset from the flags byte
def gz_body(r: Array<U32> & U32, +n: U32) -> Array<U32> & U32:
  (a, flg) = r
  +f = flg
  skip_n(skip_nul(skip_nul(skip_extra((a, 10), U32.is_ne((f .&. 4 : U32), 0)), n, U32.is_ne((f .&. 8 : U32), 0)), n, U32.is_ne((f .&. 16 : U32), 0)), 2, U32.is_ne((f .&. 2 : U32), 0))

def gz_start(r: Array<U32> & U32, +n: U32, +out_n: U32) -> Array<U32> & U32:
  (a, pos) = r
  Deflate.inflate(a, pos, n, out_n)

def gz_sized(r: Array<U32> & U32, +n: U32) -> Array<U32> & U32:
  (a, out_n) = r
  gz_start(gz_body(Words.byte_at(a, 3), n), n, out_n)

def decode(a: Array<U32>, +n: U32) -> Array<U32> & U32:
  gz_sized(Words.le32_at(a, (n - 4 : U32)), n)

# the magic 1f 8b
def gz_magic(r: Array<U32> & U32) -> Array<U32> & Bool:
  (a, w) = r
  (a, U32.is_eq((w .&. 65535 : U32), 35615))

def is_gzip(a: Array<U32>) -> Array<U32> & Bool:
  gz_magic(Words.le32_at(a, 0))

def decode_if(a: Array<U32>, +n: U32, gz: Bool) -> Array<U32> & U32:
  match gz:
    case True{}:
      decode(a, n)
    case False{}:
      (a, n)

# XFL says 2 for the slowest level and 4 for the fastest
def header(ob: Words.Sink, +level: U32) -> Words.Sink:
  Words.put_byte(Words.put_byte(Words.put_zeros(Words.put_byte(Words.put_byte(Words.put_byte(ob, 31), 139), 8), 5), pick(U32.is_eq(level, 9), 2, pick(U32.is_eq(level, 1), 4, 0))), 3)

# CRC32 and ISIZE (the size mod 2^32), each little-endian
def trailer(ob: Words.Sink, +crc: U32, +size: U32) -> Words.Sink:
  Words.put_le32(Words.put_le32(ob, crc), size)

def write_crc(r: Array<U32> & U32, +path: String, file: File, +n: U32, +level: U32) -> IO(File):
  (a, crc) = r
  +c = crc
  do IO<File>:
    head : File <- Words.sink_write(path, file, header(Words.sink_new(), level))
    body : File <- Deflate.write(Deflate.compress(a, 0, n, level, True{}), path, head)
    Words.sink_write(path, body, trailer(Words.sink_new(), c, n))

# the n bytes of a, compressed at level (0-9) as one gzip member, written
# to file; a holds three spare zero words past n, as Words.read leaves it
def write(+path: String, file: File, a: Array<U32>, +n: U32, +level: U32) -> IO(File):
  do IO<File>:
    r : Array<U32> & U32 <- Crc32.update(path, a, 0, n, 0)
    write_crc(r, path, file, n, level)
