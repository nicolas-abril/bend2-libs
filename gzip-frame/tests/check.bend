# Gzip.write, read back, is a gzip member that decodes to the same bytes;
# the file it leaves (gzip-test.gz) is for gunzip to confirm. Prints ok.
import Base
import gralha-byte-words@0.1.0.0/words.bend as Words
import gralha-crc32@0.1.0.0/crc32.bend as Crc32
import ../gzip.bend as Gzip

def text(n: Nat, +k: U32, acc: String) -> String:
  match n:
    case 0n:
      acc
    case 1n+p:
      text(p, (k + 1 : U32), "gralha " ++ U32.show((k * 7 % 100 : U32)) ++ " gzip\n" ++ acc)

def sink_of(st: Words.Sink) -> Array<U32> & U32:
  match st:
    case Words.Sink{a, cap, pos}:
      (a, pos)

def path() -> String:
  "gzip-test.gz"

def report(ok: Bool, msg: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("ok " ++ msg)
    case False{}:
      IO.print("FAIL " ++ msg)

def check_crc(r: Array<U32> & U32, +n: U32, +want: U32, +crc: U32, magic: Bool) -> IO(Unit):
  (b, c) = r
  report(magic && U32.is_eq(n, want) && U32.is_eq(c, crc), U32.show(n) ++ " bytes")

def check(r: Array<U32> & U32, +want: U32, +crc: U32, magic: Bool) -> IO(Unit):
  (a, n) = r
  +nn = n
  check_crc(Crc32.pure(a, 0, nn, 0), nn, want, crc, magic)

def peeked(r: Array<U32> & Bool, +got: U32, +want: U32, +crc: U32) -> IO(Unit):
  (a, magic) = r
  check(Gzip.decode(a, got), want, crc, magic)

def back(r: Array<U32> & U32, +want: U32, +crc: U32) -> IO(Unit):
  (a, got) = r
  +g = got
  peeked(Gzip.is_gzip(a), g, want, crc)

def written(r: Array<U32> & U32, +n: U32) -> IO(Unit):
  (a, crc) = r
  +c = crc
  do IO<Unit>:
    file : File <- Words.open_out(path())
    done : File <- Gzip.write(path(), file, a, n, 6)
    Unit <- File.close(done)
    got : Array<U32> & U32 <- Words.read(path())
    back(got, n, c)

def round(r: Array<U32> & U32) -> IO(Unit):
  (a, n) = r
  +nn = n
  written(Crc32.pure(a, 0, nn, 0), nn)

def main() -> IO(Unit):
  round(sink_of(Words.put_str(text(3000n, 0, ""), Words.sink_new())))
