# Writes two files, archives them with create_stream, then lists the
# archive in memory (walk) and from its file (list_file). Prints the
# header's length, then each member name twice.
import Base
import gralha-byte-words@0.1.0.0/words.bend as Words
import ../ustar.bend as Ustar

def put(+path: String, s: String) -> IO(Unit):
  do IO<Unit>:
    file : File <- Words.open_out(path)
    done : File <- Words.sink_write(path, file, Words.put_str(s, Words.sink_new()))
    File.close(done)

def chunk(c: Words.Chunk, +path: String, +n: U32) -> IO(Unit):
  match c:
    case Words.Chunk{file, a, got}:
      +g = got
      Ustar.list_file(file, a, g, path, n)

def from_file(+path: String) -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Words.file_size(path)
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    file : File <- Words.open_got(path, opened)
    raw : File & Result<&1, &1, U32 & String, Array<U32> & U32> <- Words.file_read_at_raw(file, 0, 512)
    c : Words.Chunk <- Words.file_read_got(path, raw)
    chunk(c, path, n)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(String.length(Ustar.header("a.txt", 3))))
    Unit <- put("ustar-a.txt", "abc")
    Unit <- put("ustar-b.txt", "a longer second member\n")
    Unit <- Ustar.create_stream(["ustar-a.txt", "ustar-b.txt"], False{}, "ustar-test.tar", True{})
    r : Array<U32> & U32 <- Words.read("ustar-test.tar")
    Unit <- Ustar.walk(r, False{}, False{})
    from_file("ustar-test.tar")
