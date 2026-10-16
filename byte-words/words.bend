# gralha-byte-words: bytes packed four to a U32 word, little-endian, in an
# Array<U32>, the layer the gralha codecs share. byte_at and le32_at read
# a byte or a four-byte window at any offset; Sink is a growing output
# buffer (put_byte, put_str, put_le32, put_zeros, reserve, skip); the
# effects under effs/ move packed words to and from files without a
# byte-per-cell detour (read, write, fill_at, append, copy_range,
# file_read_at, sink_write, open_out, file_size).
import Base

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

# Arrays
# ------

# the smallest depth d with 2^d >= need
def fit(n: Nat, +d: U32, +need: U32, ok: Bool) -> U32:
  match n, ok:
    case k, True{}:
      d
    case 0n, False{}:
      d
    case 1n+p, False{}:
      fit(p, (d + 1 : U32), need, U32.is_ge(U32.shln(1, U32.to_nat((d + 1 : U32))), need))

def depth_for(+need: U32) -> Nat:
  U32.to_nat(fit(31n, 0, need, U32.is_le(need, 1)))

# Output growth
# -------------
# the output doubles when a write would pass its capacity, so the size
# need not be known up front (bsdtar pads a piped archive past its trailer)

type Gr is Type:
  Gr{src: Array<U32>, dst: Array<U32>}

def gr_put(r: Array<U32> & U32, dst: Array<U32>, +i: U32) -> Gr:
  (src, v) = r
  Gr{src, Array.set(U32, dst, i, v)}

def gr_loop(n: Nat, st: Gr, +i: U32) -> Gr:
  match n, st:
    case 0n, r:
      r
    case 1n+p, Gr{src, dst}:
      gr_loop(p, gr_put(Array.get(U32, src, i), dst, i), (i + 1 : U32))

def gr_dst(st: Gr) -> Array<U32>:
  match st:
    case Gr{src, dst}:
      dst

def grow(out: Array<U32>, +cap: U32) -> Array<U32>:
  gr_dst(gr_loop(U32.to_nat(cap), Gr{out, Array.new(U32, depth_for((cap * 2 : U32)), 0)}, 0))

# (out, cap) with cap >= need; ok says it already is
def ensure(n: Nat, out: Array<U32>, +cap: U32, +need: U32, ok: Bool) -> Array<U32> & U32:
  match n, ok:
    case k, True{}:
      (out, cap)
    case 0n, False{}:
      (out, cap)
    case 1n+p, False{}:
      ensure(p, grow(out, cap), (cap * 2 : U32), need, U32.is_ge((cap * 2 : U32), need))

def room(out: Array<U32>, +cap: U32, +need: U32) -> Array<U32> & U32:
  ensure(32n, out, cap, need, U32.is_ge(cap, need))

# Packed input
# ------------
# the input packed four bytes to a word, little-endian: a byte is one
# read and a shift, the window at any byte offset two reads combined.
# The memory is a byte per byte.

def w4_hi(r: Array<U32> & U32, +lo: U32, +sh: U32) -> Array<U32> & U32:
  (a, v) = r
  (a, (lo .|. (U32.shln(v, U32.to_nat((24 - sh : U32))) << 8n) : U32))

def w4_lo(r: Array<U32> & U32, +q: U32, +sh: U32) -> Array<U32> & U32:
  (a, v) = r
  w4_hi(Array.get(U32, a, (q + 1 : U32)), U32.shrn(v, U32.to_nat(sh)), sh)

# the four bytes from j, j lowest
def le32_at(a: Array<U32>, +j: U32) -> Array<U32> & U32:
  w4_lo(Array.get(U32, a, (j >> 2n : U32)), (j >> 2n : U32), ((j .&. 3) << 3n : U32))

def wb_of(r: Array<U32> & U32, +sh: U32) -> Array<U32> & U32:
  (a, v) = r
  (a, (U32.shrn(v, U32.to_nat(sh)) .&. 255 : U32))

# the byte at j
def byte_at(a: Array<U32>, +j: U32) -> Array<U32> & U32:
  wb_of(Array.get(U32, a, (j >> 2n : U32)), ((j .&. 3) << 3n : U32))

# Files
# -----
# a file's bytes come and go as words: four bytes to a word,
# little-endian, zero padded past the end with three spare words, so
# the codec's windows never fall off. The effects are foreign C and JS
# under effs/. A `_raw` effect answers its Result; its plain twin exits
# the program with the error instead.

def read_raw(path: String) -> IO(Result<&1, &1, U32 & String, Array<U32> & U32>):
  import "./effs/words_read.c"
  import "./effs/words_read.js"

def write_raw(path: String, a: Array<U32>, +start: U32, +n: U32) -> IO(Array<U32> & Result<&1, &1, U32 & String, Unit>):
  import "./effs/words_write.c"
  import "./effs/words_write.js"

def fill_at_raw(path: String, +file_off: U32, a: Array<U32>, +start: U32, +n: U32) -> IO(Array<U32> & Result<&1, &1, U32 & String, Unit>):
  import "./effs/words_fill_at.c"
  import "./effs/words_fill_at.js"

def append_raw(path: String, a: Array<U32>, +header_n: U32, input: String, +pad_n: U32, +first: U32) -> IO(Array<U32> & Result<&1, &1, U32 & String, Unit>):
  import "./effs/stream_append.c"
  import "./effs/stream_append.js"

def copy_range(src: Array<U32>, +src_at: U32, dst: Array<U32>, +dst_at: U32, +n: U32) -> IO(Array<U32> & Array<U32>):
  import "./effs/words_copy_range.c"
  import "./effs/words_copy_range.js"

def file_write_raw(file: File, a: Array<U32>, +start: U32, +n: U32) -> IO(File & Array<U32> & Result<&1, &1, U32 & String, Unit>):
  import "./effs/file_words_write.c"
  import "./effs/file_words_write.js"

def file_read_at_raw(file: File, +offset: U32, +max: U32) -> IO(File & Result<&1, &1, U32 & String, Array<U32> & U32>):
  import "./effs/file_words_read_at.c"
  import "./effs/file_words_read_at.js"

def open_out_raw(path: String) -> IO(Result<&1, &1, U32 & String, File>):
  import "./effs/output_open.c"
  import "./effs/output_open.js"

def fail(what: String, e: U32 & String) -> IO(Unit):
  (code, msg) = e
  IO.die(Unit, 1, what ++ ": " ++ msg)

def read_got(what: String, r: Result<&1, &1, U32 & String, Array<U32> & U32>) -> IO(Array<U32> & U32):
  match r:
    case Done{v}:
      IO.pure(Array<U32> & U32, v)
    case Fail{e}:
      do IO<Array<U32> & U32>:
        Unit <- fail(what, e)
        IO.die(Array<U32> & U32, 1, "unreachable")

def read(+path: String) -> IO(Array<U32> & U32):
  do IO<Array<U32> & U32>:
    r : Result<&1, &1, U32 & String, Array<U32> & U32> <- read_raw(path)
    read_got(path, r)

def size_got(what: String, r: Result<&1, &1, U32 & String, U32>) -> IO(U32):
  match r:
    case Done{n}:
      IO.pure(U32, n)
    case Fail{e}:
      do IO<U32>:
        Unit <- fail(what, e)
        IO.die(U32, 1, "unreachable")

def wr_done(what: String, r: Array<U32> & Result<&1, &1, U32 & String, Unit>) -> IO(Array<U32>):
  (a, w) = r
  match w:
    case Done{u}:
      IO.pure(Array<U32>, a)
    case Fail{e}:
      do IO<Array<U32>>:
        Unit <- fail(what, e)
        return a

# n bytes of a from byte start; the words come back
def write(+path: String, a: Array<U32>, +start: U32, +n: U32) -> IO(Array<U32>):
  do IO<Array<U32>>:
    r : Array<U32> & Result<&1, &1, U32 & String, Unit> <- write_raw(path, a, start, n)
    wr_done(path, r)

def fill_at(+path: String, +file_off: U32, a: Array<U32>, +start: U32, +n: U32) -> IO(Array<U32>):
  do IO<Array<U32>>:
    r : Array<U32> & Result<&1, &1, U32 & String, Unit> <- fill_at_raw(path, file_off, a, start, n)
    wr_done(path, r)

def drop(a: Array<U32>) -> IO(Unit):
  IO.pure(Unit, Unit{})

def open_got(what: String, r: Result<&1, &1, U32 & String, File>) -> IO(File):
  match r:
    case Done{file}:
      IO.pure(File, file)
    case Fail{e}:
      do IO<File>:
        Unit <- fail(what, e)
        IO.die(File, 1, "unreachable")

def open_out(+path: String) -> IO(File):
  do IO<File>:
    r : Result<&1, &1, U32 & String, File> <- open_out_raw(path)
    open_got(path, r)

def size_close(what: String, r: File & Result<&1, &1, U32 & String, U32>) -> IO(U32):
  (file, v) = r
  do IO<U32>:
    Unit <- File.close(file)
    size_got(what, v)

# a member's byte count, read off its open handle
def file_size(+path: String) -> IO(U32):
  do IO<U32>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    file : File <- open_got(path, opened)
    r : File & Result<&1, &1, U32 & String, U32> <- File.size(file)
    size_close(path, r)

type Chunk is Type:
  Chunk{file: File, a: Array<U32>, n: U32}

def file_read_got(what: String, r: File & Result<&1, &1, U32 & String, Array<U32> & U32>) -> IO(Chunk):
  (file, v) = r
  match v:
    case Done{(a, n)}:
      IO.pure(Chunk, Chunk{file, a, n})
    case Fail{e}:
      do IO<Chunk>:
        Unit <- File.close(file)
        Unit <- fail(what, e)
        IO.die(Chunk, 1, "unreachable")

def file_write_got(what: String, r: File & Array<U32> & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, a, v) = r
  match v:
    case Done{u}:
      do IO<File>:
        Unit <- drop(a)
        return file
    case Fail{e}:
      do IO<File>:
        Unit <- drop(a)
        Unit <- File.close(file)
        Unit <- fail(what, e)
        IO.die(File, 1, "unreachable")

def append(+path: String, a: Array<U32>, +header_n: U32, +input: String, +pad_n: U32, first: Bool) -> IO(Unit):
  do IO<Unit>:
    r : Array<U32> & Result<&1, &1, U32 & String, Unit> <- append_raw(path, a, header_n, input, pad_n, b2u(first))
    a2 : Array<U32> <- wr_done(path, r)
    drop(a2)

# Output
# ------
# a growing byte sink over packed words: cap counts words, pos bytes.
# A byte lands by read-modify-write of its word; a run of zeros and a
# word-aligned block of words go in whole.

type Sink is Type:
  Sink{a: Array<U32>, cap: U32, pos: U32}

def sink_write(+path: String, file: File, st: Sink) -> IO(File):
  match st:
    case Sink{a, cap, pos}:
      do IO<File>:
        r : File & Array<U32> & Result<&1, &1, U32 & String, Unit> <- file_write_raw(file, a, 0, pos)
        file_write_got(path, r)

def sink_new() -> Sink:
  Sink{Array.new(U32, 16n, 0), 65536, 0}

def ob_fit(r: Array<U32> & U32, +pos: U32) -> Sink:
  (a, cap) = r
  Sink{a, cap, pos}

# room for bytes up to need
def ob_room(a: Array<U32>, +cap: U32, +pos: U32, +need: U32) -> Sink:
  ob_fit(room(a, cap, ((need >> 2n) + 4 : U32)), pos)

def ob_or(r: Array<U32> & U32, +cap: U32, +pos: U32, +b: U32) -> Sink:
  (a, w) = r
  Sink{Array.set(U32, a, (pos >> 2n : U32), (w .|. U32.shln(b, U32.to_nat(((pos .&. 3) << 3n : U32))) : U32)), cap, (pos + 1 : U32)}

def ob_byte_at(st: Sink, +b: U32) -> Sink:
  match st:
    case Sink{a, cap, pos}:
      +p = pos
      ob_or(Array.get(U32, a, (p >> 2n : U32)), cap, p, b)

def put_byte(st: Sink, +b: U32) -> Sink:
  match st:
    case Sink{a, cap, pos}:
      +p = pos
      ob_byte_at(ob_room(a, cap, p, (p + 1 : U32)), b)

def ow_split(a: Array<U32>, +q: U32, +v: U32, +sh: U32, split: Bool) -> Array<U32>:
  match split:
    case True{}:
      Array.set(U32, a, (q + 1 : U32), U32.shrn(v, U32.to_nat((32 - sh : U32))))
    case False{}:
      a

def ob_word_got(r: Array<U32> & U32, +cap: U32, +pos: U32, +q: U32, +sh: U32, +v: U32) -> Sink:
  (a, old) = r
  Sink{ow_split(Array.set(U32, a, q, (old .|. U32.shln(v, U32.to_nat(sh)) : U32)), q, v, sh, U32.is_ne(sh, 0)), cap, (pos + 4 : U32)}

# Four bytes into a previously reserved output range. The destination may be
# unaligned; its already-written low bytes are preserved and the high spill
# becomes the prefix of the next word.
def put_word_at(st: Sink, +v: U32) -> Sink:
  match st:
    case Sink{a, cap, pos}:
      +p = pos
      +q = (p >> 2n : U32)
      +sh = ((p .&. 3) << 3n : U32)
      ob_word_got(Array.get(U32, a, q), cap, p, q, sh, v)

def reserve(st: Sink, +n: U32) -> Sink:
  match st:
    case Sink{a, cap, pos}:
      +p = pos
      ob_room(a, cap, p, (p + n : U32))

# n bytes of a string
def put_str(s: String, st: Sink) -> Sink:
  match s:
    case SNil{}:
      st
    case SCon{Chr{c}, t}:
      put_str(t, put_byte(st, c))

# n zero bytes: the room is zero already
def skip(st: Sink, +n: U32) -> Sink:
  match st:
    case Sink{a, cap, pos}:
      Sink{a, cap, (pos + n : U32)}

def put_zeros(st: Sink, +n: U32) -> Sink:
  match st:
    case Sink{a, cap, pos}:
      +p = pos
      skip(ob_room(a, cap, p, (p + n : U32)), n)

def put_le32(ob: Sink, +v: U32) -> Sink:
  put_byte(put_byte(put_byte(put_byte(ob, (v .&. 255 : U32)), ((v >> 8n) .&. 255 : U32)), ((v >> 16n) .&. 255 : U32)), (v >> 24n : U32))
