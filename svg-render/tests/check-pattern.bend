import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  +tiles = SVG.document(XML.parse("<svg><defs><pattern id='p' patternUnits='userSpaceOnUse' x='2' y='1' width='8' height='8'><rect width='4' height='4' fill='red'/></pattern><pattern id='copy' href='#p' x='3'/><pattern id='zero' width='0' height='1'/></defs><rect width='32' height='16' fill='url(#p)'/><rect y='16' width='32' height='16' fill='url(#copy)'/><rect y='32' width='32' height='16' fill='url(#zero)'/></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(tiles, 2, 1, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(tiles, 6, 1, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(tiles, 10, 9, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(tiles, 3, 17, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(tiles, 2, 17, 1)))
    IO.print(U32.show(SVG.pixel(tiles, 5, 35, 1)))

#|16711680
#|16777215
#|16711680
#|16711680
#|16777215
#|16777215
