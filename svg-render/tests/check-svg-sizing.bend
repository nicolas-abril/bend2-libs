import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def show(p: SVG.Point) -> String:
  SVG.Point{x, y} = p
  F32.show(x) ++ ":" ++ F32.show(y)

def size(+w: String, +h: String, vb: String) -> IO(Unit):
  IO.print(show(SVG.image.svg.size(Con{XML.Attr{"width", w}, Con{XML.Attr{"height", h}, Con{XML.Attr{"viewBox", vb}, Nil{}}}})))

def resolved(+w: String, +h: String) -> IO(Unit):
  +as = SVG.image.layout.attrs(Con{XML.Attr{"#image-size", "8 8 1"}, Con{XML.Attr{"width", w}, Con{XML.Attr{"height", h}, Nil{}}}}, 14.0, 12.0)
  IO.print(XML.attr.get(as, "width", "") ++ ":" ++ XML.attr.get(as, "height", ""))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- size("12", "6", "")
    Unit <- size("18", "auto", "0 0 10 5")
    Unit <- size("auto", "10", "0 0 10 5")
    Unit <- size("auto", "auto", "0 0 10 5")
    Unit <- size("100%", "50%", "0 0 10 10")
    Unit <- size("auto", "auto", "")
    Unit <- size("12", "auto", "")
    Unit <- size("0", "8", "0 0 10 5")
    Unit <- resolved("50%", "auto")
    resolved("auto", "50%")

#|12:6
#|18:9
#|20:10
#|300:150
#|150:150
#|300:150
#|12:150
#|0:8
#|7:7
#|6:6
