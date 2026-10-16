import Base
import gralha-text-scan@0.1.0.0/scan.bend as U
import ../cover.bend as Cov

def square(+x0: F32, +y0: F32, +x1: F32, +y1: F32) -> List<&2, Cov.CovLine>:
  Con{Cov.CovLine{x0, y0, x1, y0}, Con{Cov.CovLine{x1, y0, x1, y1}, Con{Cov.CovLine{x1, y1, x0, y1}, Con{Cov.CovLine{x0, y1, x0, y0}, Nil{}}}}}

def at(+m: Cov.CovMask, +x: U32, +y: U32) -> String:
  U32.show(F32.to_u32((Cov.mask.at(m, (U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32)) * 1000.0 + 0.5 : F32)))

def row(+m: Cov.CovMask, n: Nat, +x: U32, +y: U32) -> String:
  match n:
    case 0n: ""
    case 1n+d: U.choose(String, U32.is_eq(x, 0), "", " ") ++ at(m, x, y) ++ row(m, d, (x + 1 : U32), y)

def total(+m: Cov.CovMask, n: Nat, +i: U32, +w: U32, +acc: F32) -> F32:
  match n:
    case 0n: acc
    case 1n+d: total(m, d, (i + 1 : U32), w, (acc + Cov.mask.at(m, (U32.to_f32(U32.mod(i, w)) + 0.5 : F32), (U32.to_f32(U32.div(i, w)) + 0.5 : F32)) : F32))

def main() -> IO(Unit):
  +half = Cov.mask(square(2.5, 2.5, 6.5, 6.5), False{}, 10, 10, 8, True{})
  +tri = Cov.mask(Con{Cov.CovLine{1.0, 1.0, 9.0, 1.0}, Con{Cov.CovLine{9.0, 1.0, 1.0, 7.0}, Con{Cov.CovLine{1.0, 7.0, 1.0, 1.0}, Nil{}}}}, False{}, 10, 10, 8, True{})
  +overlap = Cov.mask(Cov.lines.append(square(1.0, 1.0, 5.0, 5.0), square(3.0, 3.0, 7.0, 7.0)), True{}, 8, 8, 8, True{})
  +reversed = Cov.mask(square(6.5, 6.5, 2.5, 2.5), False{}, 10, 10, 8, True{})
  +outside = Cov.mask(square(F32.neg(3.0), F32.neg(3.0), 4.5, 4.5), False{}, 8, 8, 8, True{})
  +double = Cov.mask(Cov.lines.append(square(1.5, 1.5, 5.5, 5.5), square(1.5, 1.5, 5.5, 5.5)), False{}, 8, 8, 8, True{})
  do IO<Unit>:
    Unit <- IO.print(row(half, 10n, 0, 2))
    Unit <- IO.print(row(half, 10n, 0, 4))
    Unit <- IO.print(row(half, 10n, 0, 6))
    Unit <- IO.print(U32.show(F32.to_u32((total(half, 100n, 0, 10, 0.0) * 100.0 + 0.5 : F32))))
    Unit <- IO.print(U32.show(F32.to_u32((total(tri, 100n, 0, 10, 0.0) * 100.0 + 0.5 : F32))))
    Unit <- IO.print(row(overlap, 8n, 0, 4))
    Unit <- IO.print(row(reversed, 10n, 0, 4))
    Unit <- IO.print(row(outside, 8n, 0, 2))
    IO.print(row(double, 8n, 0, 3))

#|0 0 250 500 500 500 250 0 0 0
#|0 0 500 1000 1000 1000 500 0 0 0
#|0 0 250 500 500 500 250 0 0 0
#|1600
#|2400
#|0 1000 1000 0 0 1000 1000 0
#|0 0 500 1000 1000 1000 500 0 0 0
#|1000 1000 1000 1000 500 0 0 0
#|0 500 1000 1000 1000 500 0 0
