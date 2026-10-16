# gralha-ustar: POSIX ustar archives over gralha-byte-words. header builds
# a member's 512-byte header; create_stream writes an archive member by
# member; manifest and fill produce the archive into bounded Sink batches
# (for a compressor); walk lists or extracts an archive held in memory,
# and list_file lists one from an open file, reading only its headers.
# Regular files only: mode 0644, uid and gid 0, mtime 0.
import Base
import gralha-byte-words@0.1.0.0/words.bend as Words


# Bytes and strings
# -----------------

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def pick(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

def slen(s: String, +acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      slen(t, (acc + 1 : U32))

# reverse onto acc
def srev(s: String, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      srev(t, SCon{h, acc})

def sdrop(n: Nat, s: String) -> String:
  match n, s:
    case 0n, rest:
      rest
    case 1n+p, SNil{}:
      SNil{}
    case 1n+p, SCon{h, t}:
      sdrop(p, t)

# the first n bytes, reversed onto acc
def stake_rev(n: Nat, s: String, acc: String) -> String:
  match n, s:
    case 0n, rest:
      acc
    case 1n+p, SNil{}:
      acc
    case 1n+p, SCon{h, t}:
      stake_rev(p, t, SCon{h, acc})

def stake(n: Nat, s: String) -> String:
  srev(stake_rev(n, s, ""), "")

# the first n bytes and the rest
def split_at(n: Nat, s: String, acc: String) -> String & String:
  match n, s:
    case 0n, rest:
      (srev(acc, ""), rest)
    case 1n+p, SNil{}:
      (srev(acc, ""), "")
    case 1n+p, SCon{h, t}:
      split_at(p, t, SCon{h, acc})

# reverse onto acc, counting
def srev_len(s: String, acc: String, +n: U32) -> String & U32:
  match s:
    case SNil{}:
      (acc, n)
    case SCon{h, t}:
      srev_len(t, SCon{h, acc}, (n + 1 : U32))

# n copies of byte c in front of s
def sfill(n: Nat, +c: U32, s: String) -> String:
  match n:
    case 0n:
      s
    case 1n+p:
      sfill(p, c, SCon{Chr{c}, s})

# s cut or NUL-padded to exactly n bytes
def field(+n: U32, +s: String) -> String:
  +len = slen(s, 0)
  stake(U32.to_nat(n), s) ++ sfill(U32.to_nat((n - pick(U32.is_lt(len, n), len, n) : U32)), 0, "")

# the head byte, 0 on empty
def head(s: String) -> U32:
  match s:
    case SNil{}:
      0
    case SCon{Chr{c}, t}:
      c

def head_is(s: String, +c: U32) -> Bool:
  U32.is_eq(head(s), c)

def head_digit(s: String) -> Bool:
  +c = head(s)
  (c >= 48 : U32) && (c <= 55 : U32)

# the bytes of s up to the first NUL; nul says whether s starts with one
def cstr(s: String, acc: String, nul: Bool) -> String:
  match s, nul:
    case rest, True{}:
      srev(acc, "")
    case SNil{}, False{}:
      srev(acc, "")
    case SCon{h, t}, False{}:
      +t2 = t
      cstr(t2, SCon{h, acc}, head_is(t2, 0))

# the byte at position i, 0 past the end
def sat(s: String, i: Nat) -> U32:
  match s, i:
    case SNil{}, k:
      0
    case SCon{Chr{c}, t}, 0n:
      c
    case SCon{h, t}, 1n+p:
      sat(t, p)

# n digits of v in octal, least significant first, in front of tail
def octal(n: Nat, +v: U32, tail: String) -> String:
  match n:
    case 0n:
      tail
    case 1n+p:
      octal(p, (v / 8 : U32), SCon{Chr{(48 + v % 8 : U32)}, tail})

# an octal field read while digits last; digit says whether s starts with one
def unoctal(s: String, +acc: U32, digit: Bool) -> U32:
  match s, digit:
    case rest, False{}:
      acc
    case SNil{}, True{}:
      acc
    case SCon{Chr{c}, t}, True{}:
      +t2 = t
      unoctal(t2, (acc * 8 + (c - 48) : U32), head_digit(t2))

def ssum(s: String, +acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{Chr{c}, t}:
      ssum(t, (acc + c : U32))

def all_zero(s: String, ok: Bool) -> Bool:
  match s:
    case SNil{}:
      ok
    case SCon{Chr{c}, t}:
      all_zero(t, ok && U32.is_eq(c, 0))

def le32(+v: U32) -> String:
  SCon{Chr{(v .&. 255 : U32)}, SCon{Chr{((v >> 8n) .&. 255 : U32)}, SCon{Chr{((v >> 16n) .&. 255 : U32)}, SCon{Chr{(v >> 24n : U32)}, ""}}}}

def say(verbose: Bool, line: String) -> IO(Unit):
  match verbose:
    case True{}:
      IO.print_err(line)
    case False{}:
      IO.pure(Unit, Unit{})

# Tar
# ---
# ustar: a 512-byte header, the data, NUL padding to 512, and two zero
# blocks at the end. Regular files only: mode 0644, uid and gid 0, mtime 0.
# Every entry starts at a multiple of 512, so a member's words go into
# the archive aligned.

def padding(+n: U32) -> U32:
  ((512 - n % 512) % 512 : U32)

def header(name: String, +size: U32) -> String:
  +h = field(100, name) ++ "0000644" ++ "\0" ++ "0000000" ++ "\0" ++ "0000000" ++ "\0"
    ++ octal(11n, size, "\0") ++ octal(11n, 0, "\0") ++ "        " ++ "0" ++ field(100, "")
    ++ "ustar" ++ "\0" ++ "00" ++ field(32, "") ++ field(32, "") ++ "0000000" ++ "\0" ++ "0000000" ++ "\0"
    ++ field(155, "") ++ field(12, "")
  stake(148n, h) ++ octal(6n, ssum(h, 0), "\0 ") ++ sdrop(156n, h)

# Create
# ------

# The bounded gzip source. Metadata is collected once, then the logical tar
# stream is produced into fixed batches without constructing a whole archive.
type Tm is Type:
  Tm{name: String, size: U32}

def manifest(names: List<&2, String>, +verbose: Bool) -> IO(List<&1, Tm>):
  match names:
    case Nil{}:
      IO.pure(List<&1, Tm>, [])
    case Con{h, t}:
      +name = h
      do IO<List<&1, Tm>>:
        size : U32 <- Words.file_size(name)
        Unit <- say(verbose, "a " ++ name)
        rest : List<&1, Tm> <- manifest(t, verbose)
        return Tm{name, size} <> rest

type Gsrc is Type:
  GFiles{members: List<&1, Tm>}
  GData{name: String, size: U32, at: U32, rest: List<&1, Tm>}
  GPad{rest: List<&1, Tm>, left: U32}
  GZero{left: U32}
  GDone{}

type Bt is Type:
  Bt{src: Gsrc, ob: Words.Sink, done: Bool}

def gs_data_next(+name: String, +size: U32, +at: U32, rest: List<&1, Tm>, done: Bool) -> Gsrc:
  match done:
    case True{}:
      GPad{rest, padding(size)}
    case False{}:
      GData{name, size, at, rest}

def gs_pad_next(rest: List<&1, Tm>, +left: U32, done: Bool) -> Gsrc:
  match done:
    case True{}:
      GFiles{rest}
    case False{}:
      GPad{rest, left}

def gs_zero_next(+left: U32, done: Bool) -> Gsrc:
  match done:
    case True{}:
      GDone{}
    case False{}:
      GZero{left}

# At most 4096 command-line words enter the parser. A batch can therefore cross
# every member header, body, and padding run without an artificial early flush.
def fill(fuel: Nat, more: Bool, src: Gsrc, ob: Words.Sink, +limit: U32) -> IO(Bt):
  match fuel, more, src, ob:
    case f, m, GDone{}, out:
      IO.pure(Bt, Bt{GDone{}, out, True{}})
    case f, False{}, s, out:
      IO.pure(Bt, Bt{s, out, False{}})
    case 0n, True{}, s, out:
      IO.pure(Bt, Bt{s, out, False{}})
    case 1n+p, True{}, GFiles{Nil{}}, out:
      fill(p, True{}, GZero{1024}, out, limit)
    case 1n+p, True{}, GFiles{Con{Tm{name, size}, rest}}, Words.Sink{a, cap, pos}:
      +nm = name
      +sz = size
      +pp = pos
      +next = (pp + 512 : U32)
      fill(p, U32.is_lt(next, limit), GData{nm, sz, 0, rest}, Words.put_str(header(nm, sz), Words.Sink{a, cap, pp}), limit)
    case 1n+p, True{}, GData{name, size, at, rest}, Words.Sink{a, cap, pos}:
      +nm = name
      +sz = size
      +aa = at
      +pp = pos
      +take = pick(U32.is_lt((sz - aa : U32), (limit - pp : U32)), (sz - aa : U32), (limit - pp : U32))
      +next_at = (aa + take : U32)
      +next_pos = (pp + take : U32)
      do IO<Bt>:
        a2 : Array<U32> <- Words.fill_at(nm, aa, a, pp, take)
        fill(p, U32.is_lt(next_pos, limit), gs_data_next(nm, sz, next_at, rest, U32.is_eq(next_at, sz)), Words.Sink{a2, cap, next_pos}, limit)
    case 1n+p, True{}, GPad{rest, left}, Words.Sink{a, cap, pos}:
      +ll = left
      +pp = pos
      +take = pick(U32.is_lt(ll, (limit - pp : U32)), ll, (limit - pp : U32))
      +next_left = (ll - take : U32)
      +next_pos = (pp + take : U32)
      fill(p, U32.is_lt(next_pos, limit), gs_pad_next(rest, next_left, U32.is_eq(next_left, 0)), Words.Sink{a, cap, next_pos}, limit)
    case 1n+p, True{}, GZero{left}, Words.Sink{a, cap, pos}:
      +ll = left
      +pp = pos
      +take = pick(U32.is_lt(ll, (limit - pp : U32)), ll, (limit - pp : U32))
      +next_left = (ll - take : U32)
      +next_pos = (pp + take : U32)
      fill(p, U32.is_lt(next_pos, limit), gs_zero_next(next_left, U32.is_eq(next_left, 0)), Words.Sink{a, cap, next_pos}, limit)

# The plain create path writes one member at a time. Headers stay in Bend;
# the effect only transfers their packed words and copies the file into the
# ordered sink, so member contents never enter the growing archive Array.
def stream_ob(+out: String, +input: String, +pad: U32, first: Bool, st: Words.Sink) -> IO(Unit):
  match st:
    case Words.Sink{a, cap, pos}:
      Words.append(out, a, pos, input, pad, first)

def stream_member(+out: String, +name: String, +size: U32, first: Bool) -> IO(Unit):
  stream_ob(out, name, padding(size), first, Words.put_str(header(name, size), Words.sink_new()))

def stream_end(+out: String, first: Bool) -> IO(Unit):
  stream_ob(out, "", 0, first, Words.put_zeros(Words.sink_new(), 1024))

def create_stream(names: List<&2, String>, +verbose: Bool, +out: String, first: Bool) -> IO(Unit):
  match names:
    case Nil{}:
      stream_end(out, first)
    case Con{h, t}:
      +name = h
      do IO<Unit>:
        size : U32 <- Words.file_size(name)
        Unit <- say(verbose, "a " ++ name)
        Unit <- stream_member(out, name, size, first)
        create_stream(t, verbose, out, False{})

# List and extract
# ----------------
# the header at off: name, size, type, and whether the archive has
# ended (a zero block, or nothing left)

type Hdr is Type:
  Hdr{a: Array<U32>, name: String, size: U32, kind: U32, off: U32, end: Bool}

# the bytes [off, off+n) as a string, reversed onto acc
type Hs2 is Type:
  Hs2{a: Array<U32>, s: String}

def hs_cons(r: Array<U32> & U32, acc: String) -> Hs2:
  (a, b) = r
  Hs2{a, SCon{Chr{b}, acc}}

def hs_loop(n: Nat, st: Hs2, +j: U32) -> Hs2:
  match n, st:
    case 0n, r:
      r
    case 1n+p, Hs2{a, acc}:
      hs_loop(p, hs_cons(Words.byte_at(a, j), acc), (j + 1 : U32))

def hs_of(st: Hs2) -> Array<U32> & String:
  match st:
    case Hs2{a, s}:
      (a, srev(s, ""))

def bytes_str(a: Array<U32>, +off: U32, +n: U32) -> Array<U32> & String:
  hs_of(hs_loop(U32.to_nat(n), Hs2{a, ""}, off))

# whether the 128 words at off are zero
type Hz is Type:
  Hz{a: Array<U32>, zero: Bool}

def hz_at(r: Array<U32> & U32, zero: Bool) -> Hz:
  (a, w) = r
  Hz{a, zero && U32.is_eq(w, 0)}

def hz_loop(n: Nat, st: Hz, +q: U32) -> Hz:
  match n, st:
    case 0n, r:
      r
    case 1n+p, Hz{a, zero}:
      hz_loop(p, hz_at(Array.get(U32, a, q), zero), (q + 1 : U32))

def hz_of(st: Hz) -> Array<U32> & Bool:
  match st:
    case Hz{a, zero}:
      (a, zero)

def hdr_kind(r: Array<U32> & U32, name: String, +size: U32, +off: U32) -> Hdr:
  (a, kind) = r
  Hdr{a, name, size, kind, off, False{}}

def hdr_size(r: Array<U32> & String, name: String, +off: U32) -> Hdr:
  (a, digits) = r
  +d = digits
  hdr_kind(Words.byte_at(a, (off + 156 : U32)), name, unoctal(d, 0, head_digit(d)), off)

def hdr_name(r: Array<U32> & String, +off: U32) -> Hdr:
  (a, raw) = r
  +s = raw
  hdr_size(bytes_str(a, (off + 124 : U32), 12), cstr(s, "", head_is(s, 0)), off)

def hdr_live(r: Array<U32> & Bool, +off: U32) -> Hdr:
  (a, zero) = r
  match zero:
    case True{}:
      Hdr{a, "", 0, 0, off, True{}}
    case False{}:
      hdr_name(bytes_str(a, off, 100), off)

def hdr_go(a: Array<U32>, +off: U32, past: Bool) -> Hdr:
  match past:
    case True{}:
      Hdr{a, "", 0, 0, off, True{}}
    case False{}:
      hdr_live(hz_of(hz_loop(128n, Hz{a, True{}}, (off >> 2n : U32))), off)

def header_at(a: Array<U32>, +off: U32, +n: U32) -> Hdr:
  hdr_go(a, off, U32.is_ge((off + 512 : U32), (n + 1 : U32)))

def tar_write(a: Array<U32>, +name: String, +off: U32, +size: U32, verbose: Bool, dir: Bool) -> IO(Array<U32>):
  match dir:
    case True{}:
      do IO<Array<U32>>:
        Unit <- IO.print_err("tar: skipping directory " ++ name ++ " (no mkdir)")
        return a
    case False{}:
      do IO<Array<U32>>:
        Unit <- say(verbose, "x " ++ name)
        Words.write(name, a, (off + 512 : U32), size)

def tar_emit(a: Array<U32>, +name: String, +off: U32, +size: U32, kind: U32, extract: Bool, verbose: Bool) -> IO(Array<U32>):
  match extract:
    case False{}:
      do IO<Array<U32>>:
        Unit <- IO.print(name)
        return a
    case True{}:
      tar_write(a, name, off, size, verbose, U32.is_eq(kind, 53))

# walks the entries; fuel bounds the loop by the archive's block count
def walk_loop(fuel: Nat, h: Hdr, +n: U32, +extract: Bool, +verbose: Bool) -> IO(Unit):
  match fuel, h:
    case 0n, k:
      IO.pure(Unit, Unit{})
    case 1n+p, Hdr{a, name, size, kind, off, end}:
      match end:
        case True{}:
          Words.drop(a)
        case False{}:
          +sz = size
          +o = off
          do IO<Unit>:
            a2 : Array<U32> <- tar_emit(a, name, o, sz, kind, extract, verbose)
            walk_loop(p, header_at(a2, (o + 512 + sz + padding(sz) : U32), n), n, extract, verbose)

def walk(r: Array<U32> & U32, extract: Bool, verbose: Bool) -> IO(Unit):
  (a, n) = r
  +nn = n
  walk_loop(U32.to_nat((nn / 512 + 1 : U32)), header_at(a, 0, nn), nn, extract, verbose)

# Plain archives are listed one header at a time. Payload ranges are skipped by
# advancing the pread offset, so a one-file 64 MiB archive reads 512 bytes rather
# than materializing all 64 MiB. Gzip still uses the decoder above.
type Ls is Type:
  LRead{file: File, a: Array<U32>, n: U32, off: U32}
  LHdr{file: File, h: Hdr, off: U32}

def ls_read(r: Words.Chunk, +off: U32) -> Ls:
  match r:
    case Words.Chunk{file, a, n}:
      LRead{file, a, n, off}

def list_stream_close(st: Ls) -> IO(Unit):
  match st:
    case LRead{file, a, n, off}:
      do IO<Unit>:
        Unit <- Words.drop(a)
        File.close(file)
    case LHdr{file, Hdr{a, name, size, kind, hoff, end}, off}:
      do IO<Unit>:
        Unit <- Words.drop(a)
        File.close(file)

def list_stream_loop(fuel: Nat, st: Ls, +path: String, +n: U32) -> IO(Unit):
  match fuel, st:
    case 0n, r:
      list_stream_close(r)
    case 1n+p, LRead{file, a, got, off}:
      +nn = got
      list_stream_loop(p, LHdr{file, header_at(a, 0, nn), off}, path, n)
    case 1n+p, LHdr{file, Hdr{a, name, size, kind, hoff, end}, off}:
      match end:
        case True{}:
          do IO<Unit>:
            Unit <- Words.drop(a)
            File.close(file)
        case False{}:
          +sz = size
          +next = (off + 512 + sz + padding(sz) : U32)
          do IO<Unit>:
            Unit <- IO.print(name)
            Unit <- Words.drop(a)
            raw : File & Result<&1, &1, U32 & String, Array<U32> & U32> <- Words.file_read_at_raw(file, next, 512)
            chunk : Words.Chunk <- Words.file_read_got(path, raw)
            list_stream_loop(p, ls_read(chunk, next), path, n)

# lists the archive in file (n bytes) to stdout, given its first chunk:
# a, read at offset 0, got bytes long; only the headers are read
def list_file(file: File, a: Array<U32>, +got: U32, +path: String, +n: U32) -> IO(Unit):
  list_stream_loop(U32.to_nat((n / 256 + 4 : U32)), LHdr{file, header_at(a, 0, got), 0}, path, n)
