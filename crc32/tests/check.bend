# The effect and the pure fallback agree on the check value of
# "123456789" (0xCBF43926), whole and in two pieces.
import Base
import ../crc32.bend as Crc32

def nine() -> Array<U32>:
  a = [0 : U32*4n]
  a[0] <- 875770417
  a[1] <- 943142453
  a[2] <- 57
  a

def show(+w: U32, +p: U32, +e: U32) -> String:
  U32.show(w) ++ " " ++ U32.show(p) ++ " " ++ U32.show(e) ++ " " ++ Bool.show(U32.is_eq(w, 3421780262) && U32.is_eq(p, w) && U32.is_eq(e, w))

def effect(r: Array<U32> & U32, +w: U32, +p: U32) -> IO(Unit):
  (a, e) = r
  IO.print(show(w, p, e))

def run(r: Array<U32> & U32, +w: U32) -> IO(Unit):
  (a, p) = r
  do IO<Unit>:
    e : Array<U32> & U32 <- Crc32.update("crc", a, 0, 9, 0)
    effect(e, w, p)

def piece(r: Array<U32> & U32, +w: U32) -> IO(Unit):
  (a, h) = r
  +hh = h
  run(Crc32.pure(a, 4, 5, hh), w)

def whole(r: Array<U32> & U32) -> IO(Unit):
  (a, w) = r
  +ww = w
  piece(Crc32.pure(a, 0, 4, 0), ww)

def main() -> IO(Unit):
  whole(Crc32.pure(nine(), 0, 9, 0))
