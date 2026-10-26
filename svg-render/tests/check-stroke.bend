import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def test(attrs: String, d: String, x: U32, y: U32) -> U32:
  source = {"<svg><path fill='none' stroke='black' stroke-width='6' " ++ attrs ++ " d='" ++ d ++ "'/></svg>" : String}
  SVG.pixel(SVG.document(XML.parse(source), 64.0, 64.0), x, y, 1)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(test("stroke-linecap='butt'", "M10 10H20", 8, 10)))
    Unit <- IO.print(U32.show(test("stroke-linecap='round'", "M10 10H20", 8, 10)))
    Unit <- IO.print(U32.show(test("", "M10 10H30V30H10V10", 8, 8)))
    Unit <- IO.print(U32.show(test("", "M10 10H30V30H10Z", 8, 8)))
    Unit <- IO.print(U32.show(test("stroke-dasharray='4 4'", "M4 10H60", 10, 10)))
    Unit <- IO.print(U32.show(test("stroke-linecap='round' stroke-dasharray='2 4' stroke-dashoffset='3'", "M10 10L10 10", 10, 10)))
    IO.print(U32.show(test("stroke-linecap='round' stroke-dasharray='2 4' stroke-dashoffset='1'", "M10 10L10 10", 10, 10)))

#|16777215
#|0
#|16777215
#|0
#|16777215
#|16777215
#|0
