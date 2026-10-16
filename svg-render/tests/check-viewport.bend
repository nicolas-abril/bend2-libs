import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def picked(p: SVG.Pick) -> String:
  SVG.Pick{found, target, inv} = p
  target

def main() -> IO(Unit):
  +scene = SVG.document(XML.parse("<svg><svg x='10' y='10' width='20' height='10' viewBox='0 0 20 10'><rect x='-10' y='-10' width='50' height='50' fill='red'/></svg><svg x='40' y='40' width='0' height='10'><rect width='50' height='50' fill='blue'/></svg></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(scene, 5, 15, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 15, 15, 1)))
    Unit <- IO.print("outside=" ++ picked(SVG.pick(scene, SVG.Point{5.0, 15.0})))
    Unit <- IO.print(picked(SVG.pick(scene, SVG.Point{15.0, 15.0})))
    IO.print(U32.show(SVG.pixel(scene, 45, 45, 1)))

#|16777215
#|16711680
#|outside=
#|3
#|16777215
