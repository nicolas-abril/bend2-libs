# compress, written to a file and read back, inflates to the same bytes
# at levels 0, 1, 6 and 9, over two 248 KiB chunks; prints ok per level.
import Base
import gralha-byte-words@0.1.0.0/words.bend as Words
import gralha-crc32@0.1.0.0/crc32.bend as Crc32
import ../deflate.bend as Deflate

def text(n: Nat, +k: U32, acc: String) -> String:
  match n:
    case 0n:
      acc
    case 1n+p:
      text(p, (k + 1 : U32), "gralha " ++ U32.show((k * k % 1000 : U32)) ++ " deflate " ++ acc)

def sink_of(st: Words.Sink) -> Array<U32> & U32:
  match st:
    case Words.Sink{a, cap, pos}:
      (a, pos)

def input() -> Array<U32> & U32:
  sink_of(Words.put_str(text(16000n, 0, ""), Words.sink_new()))

def path() -> String:
  "deflate-test.bin"

def report(ok: Bool, msg: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("ok " ++ msg)
    case False{}:
      IO.print("FAIL " ++ msg)

def check_crc(r: Array<U32> & U32, +n: U32, +want: U32, +crc: U32, +level: U32) -> IO(Unit):
  (b, c) = r
  report(U32.is_eq(n, want) && U32.is_eq(c, crc), "level " ++ U32.show(level) ++ ", " ++ U32.show(n) ++ " bytes")

def check(r: Array<U32> & U32, +want: U32, +crc: U32, +level: U32) -> IO(Unit):
  (a, n) = r
  +nn = n
  check_crc(Crc32.pure(a, 0, nn, 0), nn, want, crc, level)

def back(r: Array<U32> & U32, +want: U32, +crc: U32, +level: U32) -> IO(Unit):
  (a, got) = r
  +g = got
  check(Deflate.inflate(a, 0, g, want), want, crc, level)

def compressed(r: Array<U32> & U32, +n: U32, +level: U32) -> IO(Unit):
  (a, crc) = r
  +c = crc
  do IO<Unit>:
    file : File <- Words.open_out(path())
    done : File <- Deflate.write(Deflate.compress(a, 0, n, level, True{}), path(), file)
    Unit <- File.close(done)
    got : Array<U32> & U32 <- Words.read(path())
    back(got, n, c, level)

def round(r: Array<U32> & U32, +level: U32) -> IO(Unit):
  (a, n) = r
  +nn = n
  compressed(Crc32.pure(a, 0, nn, 0), nn, level)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- round(input(), 0)
    Unit <- round(input(), 1)
    Unit <- round(input(), 6)
    round(input(), 9)
