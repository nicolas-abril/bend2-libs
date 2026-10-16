import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  +nodes = SVG.document(XML.parse("<svg><g><path d='M16 12L32 12' fill='none' stroke='red' stroke-width='12' stroke-linecap='round'/></g><g><path d='M16 50L26 30L36 50' fill='none' stroke='blue' stroke-width='6' stroke-linejoin='miter'/></g><g transform='translate(42 40) scale(2 3)'><path d='M0 0L8 0' stroke='lime' stroke-width='6' vector-effect='non-scaling-stroke'/></g></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(nodes, 10, 12, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(nodes, 26, 25, 1)))
    IO.print(U32.show(SVG.pixel(nodes, 50, 38, 1)))

#|16711680
#|255
#|65280
