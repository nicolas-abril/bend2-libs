import Base
import gralha-text-scan@0.1.0.1/scan.bend as U
import gralha-bytes@0.1.0.1/bytes.bend as Bin
import ../jpeg.bend as JPEG

def show(read: JPEG.JPEGRead) -> String:
  JPEG.JPEGRead{value, stream} = read
  U32.show(value) ++ ":" ++ U.choose(String, JPEG.jpeg.stream.valid(stream), "ok", "bad")

def main() -> IO(Unit):
  +data = Bin.base64("qv8AAf/Q")
  do IO<Unit>:
    Unit <- IO.print(show(JPEG.jpeg.bits(JPEG.JPEGStream{data, 0, 0, 0, JPEG.jpeg.spectral.default(), True{}}, 16)))
    Unit <- IO.print(show(JPEG.jpeg.bits(JPEG.JPEGStream{data, 3, 0, 0, JPEG.jpeg.spectral.default(), True{}}, 8)))
    Unit <- IO.print(show(JPEG.jpeg.bits(JPEG.JPEGStream{data, 4, 0, 0, JPEG.jpeg.spectral.default(), True{}}, 1)))
    Unit <- IO.print(F32.show(JPEG.jpeg.signed(JPEG.jpeg.extend(2, 3))))
    Unit <- IO.print(F32.show(JPEG.jpeg.signed(JPEG.jpeg.extend(5, 3))))
    IO.print(U32.show(JPEG.jpeg.zigzag(2)))

#|43775:ok
#|1:ok
#|0:bad
#|-5
#|5
#|8
