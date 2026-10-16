import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  +drawing = XML.parse("<svg><style><![CDATA[@import url('unused.css'); rect{fill:red}@media screen and (min-width:60px){rect{fill:blue}}@media print{rect{fill:lime}}]]></style><rect width='64' height='64'/></svg>")
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(SVG.document(drawing, 64.0, 64.0), 2, 2, 1)))
    IO.print(U32.show(SVG.pixel(SVG.document(drawing, 32.0, 32.0), 2, 2, 1)))

#|255
#|16711680
