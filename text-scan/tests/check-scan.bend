import Base
import ../scan.bend as Scan

# Numbers in the SVG grammar: signs, fractions, exponents, units and lists.
def show.list(xs: List<&2, F32>) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, t}: F32.show(h) ++ " " ++ show.list(t)

def show.scan(s: Scan.Scan) -> String:
  Scan.Scan{h, t} = s
  "[" ++ h ++ "|" ++ t ++ "]"

def bool(b: Bool) -> String:
  match b:
    case True{}: "true"
    case False{}: "false"

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(show.list(Scan.numbers("10,-2.5e1 .5-3 1e")))
    Unit <- IO.print(F32.show(Scan.scalar("  4.25px", 0.0)) ++ " " ++ F32.show(Scan.scalar("x", 7.0)))
    Unit <- IO.print(F32.show(Scan.unit(Scan.number("50%"), 200.0)) ++ " " ++ F32.show(Scan.unit(Scan.number("1in"), 0.0)))
    Unit <- IO.print(U32.show(Scan.hex("ff8", 0)) ++ " " ++ U32.show(Scan.max.u32(3, 9)) ++ " " ++ F32.show(Scan.clamp(5.0, 0.0, 1.0)))
    Unit <- IO.print("[" ++ Scan.trim.both("  a b  ") ++ "] " ++ Scan.unquote("'q'") ++ " " ++ Scan.through("key=value", "="))
    Unit <- IO.print(show.scan(Scan.until("name;rest", 59, "")) ++ " " ++ show.scan(Scan.until.sequence("a-->b", "-->", "")))
    IO.print(bool(Scan.string.contains("stylesheet", "sheet")) ++ " " ++ bool(Scan.string.equal("a", "b")) ++ " " ++ bool(Scan.prefix("#x41", "#x")))

#|10 -25 0.5 -3 1 
#|4.25 7
#|100 96
#|4088 9 1
#|[a b] q value
#|[name|rest] [a|b]
#|true false true
