# A Sink written to a file reads back byte for byte; prints ok on success.
import Base
import ../words.bend as Words

def text(n: Nat, acc: String) -> String:
  match n:
    case 0n:
      acc
    case 1n+p:
      text(p, "gralha " ++ acc)

def same(r: Array<U32> & U32, +want: U32, +k: U32) -> Array<U32> & Bool:
  (a, v) = r
  (a, U32.is_eq(v, want) && U32.is_eq(k, 0))

def report(ok: Bool, msg: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("ok")
    case False{}:
      IO.print("FAIL " ++ msg)

def verdict(r: Array<U32> & Bool, +n: U32, +size: U32) -> IO(Unit):
  (a, ok) = r
  report(ok && U32.is_eq(n, 711) && U32.is_eq(size, 711), U32.show(n) ++ " " ++ U32.show(size))

# the 4 bytes at 700 are "gral", and the last 4 are 0xdeadbeef
def tail(r: Array<U32> & U32, +n: U32, +size: U32) -> IO(Unit):
  (a, w) = r
  +ww = w
  verdict(same(Words.le32_at(a, 707), 3735928559, (ww - 1818325607 : U32)), n, size)

def back(r: Array<U32> & U32, +size: U32) -> IO(Unit):
  (a, n) = r
  +nn = n
  tail(Words.le32_at(a, 700), nn, size)

def main() -> IO(Unit):
  do IO<Unit>:
    file : File <- Words.open_out("words-test.bin")
    done : File <- Words.sink_write("words-test.bin", file, Words.put_le32(Words.put_str(text(101n, ""), Words.sink_new()), 3735928559))
    Unit <- File.close(done)
    size : U32 <- Words.file_size("words-test.bin")
    r : Array<U32> & U32 <- Words.read("words-test.bin")
    back(r, size)
