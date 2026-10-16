import Base
import gralha-text-scan@0.1.0.0/scan.bend as U
import ../bytes.bend as Bin

# The size, first big-endian word and fifth byte of a binary fixture read through bytes.read.
def describe(+b: Bin.Bytes) -> String:
  U32.show(Bin.bytes.size(b)) ++ " " ++ U32.show(Bin.bytes.be(b, 0, 4n, 0)) ++ " " ++ U32.show(Bin.bytes.get(b, 4))

def show(got: Result<&1, &1, U32 & String, Bin.Bytes>) -> String:
  match got:
    case Fail{err}: "fail"
    case Done{b}: describe(b)

def main() -> IO(Unit):
  do IO<Unit>:
    got : Result<&1, &1, U32 & String, Bin.Bytes> <- Bin.bytes.read("tests/sample.bin")
    missing : Result<&1, &1, U32 & String, Bin.Bytes> <- Bin.bytes.read("tests/none.bin")
    Unit <- IO.print(show(got))
    IO.print(show(missing))

#|13 65536 42
#|fail
