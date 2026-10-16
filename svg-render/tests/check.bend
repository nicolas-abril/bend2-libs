import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def names(xs: List<&2, XML.Element>) -> String:
  match xs:
    case Nil{}: ""
    case Con{XML.Element{n, a, kids, txt}, rest}:
      "[" ++ n ++ ":" ++ XML.attr.get(a, "id", "") ++ names(kids) ++ "]" ++ names(rest)

def root(e: XML.Element) -> String:
  XML.Element{n, a, kids, txt} = e
  names(kids)

def nums(xs: List<&2, F32>) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, t}: F32.show(h) ++ "," ++ nums(t)

def point(p: SVG.Point) -> String:
  SVG.Point{x, y} = p
  F32.show(x) ++ "," ++ F32.show(y)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(root(XML.parse("<?xml version='1.0'?><svg id='root'><g id=\"a\"><rect id='b'/><!-- hi > --><circle /></g></svg>")))
    Unit <- IO.print(nums(U.numbers("1 -2.5,3e2 4e-2 +.5")))
    IO.print(point(SVG.matrix.point(SVG.transform("translate(10,20) scale(2) rotate(90)", SVG.identity()), SVG.Point{1.0, 0.0})))

#|[svg:root[g:a[rect:b][circle:]]]
#|1,-2.5,300,0.04,0.5,
#|10,22
