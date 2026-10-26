import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.1/scan.bend as U

def valid(n: U.Number) -> U32:
  U.Number{x, tail, ok} = n
  U.choose(U32, ok, 1, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(F32.show(U.nth(U.numbers(".6.5-2e-1+3"), 1n, 99.0)))
    Unit <- IO.print(F32.show(U.nth(U.numbers(".6.5-2e-1+3"), 2n, 99.0)))
    Unit <- IO.print(F32.show(U.scalar("2em", 99.0)))
    Unit <- IO.print(U32.show(valid(SVG.arc.flag("2"))))
    IO.print(U32.show(valid(SVG.arc.flag("1"))))

#|0.5
#|-0.2
#|2
#|0
#|1
