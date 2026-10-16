import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def id(p: SVG.Pick) -> String:
  SVG.Pick{found, name, inv} = p
  name

def main() -> IO(Unit):
  +doc = SVG.document(XML.parse("<svg><defs><clipPath id='c'><rect width='16' height='16'/></clipPath><linearGradient id='g'><stop stop-color='red'/><stop offset='1' stop-color='blue'/></linearGradient></defs><rect x='0' y='0' width='32' height='32' fill='url(#g)' clip-path='url(#c)'/></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(doc, 0, 0, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(doc, 20, 5, 1)))
    Unit <- IO.print(id(SVG.pick(doc, SVG.Point{5.0, 5.0})))
    IO.print("outside=" ++ id(SVG.pick(doc, SVG.Point{20.0, 5.0})))

#|16449540
#|16777215
#|8
#|outside=
