import Base
import ../bytes.bend as Bin

def show(xs: Bin.Bytes, +at: U32) -> String:
  U32.show(Bin.bytes.get(xs, at))

def bitshow(read: Bin.BitRead) -> String:
  Bin.BitRead{n, stream} = read
  U32.show(n)

def main() -> IO(Unit):
  +s = Bin.base64("AAEC A/7/\n")
  do IO<Unit>:
    Unit <- IO.print(U32.show(Bin.bytes.size(s)))
    Unit <- IO.print(show(s, 0))
    Unit <- IO.print(show(s, 4))
    Unit <- IO.print(show(s, 5))
    Unit <- IO.print(show(Bin.bytes.set(s, 4, 42), 4))
    Unit <- IO.print(show(s, 4))
    IO.print(bitshow(Bin.bits.read(Bin.BitStream{s, 31, 48, True{}}, 9)))

#|6
#|0
#|254
#|255
#|42
#|254
#|508
