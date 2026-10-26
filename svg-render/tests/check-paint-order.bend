# Translucent fill, stroke and marker overlap must preserve all six orderings.
import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def pixel(order: String) -> U32:
  +source = "<svg><defs><marker id='m' markerUnits='userSpaceOnUse' markerWidth='10' markerHeight='10' overflow='visible'><rect x='-5' y='-5' width='10' height='10' fill='lime' opacity='.5'/></marker></defs><path d='M3 4H23V14Z' fill='red' fill-opacity='.5' stroke='blue' stroke-opacity='.5' stroke-width='6' marker-mid='url(#m)' paint-order='" ++ order ++ "'/></svg>"
  SVG.pixel(SVG.document(XML.parse(source), 32.0, 24.0), 21, 5, 1)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(pixel("normal")))
    Unit <- IO.print(U32.show(pixel("fill markers")))
    Unit <- IO.print(U32.show(pixel("stroke")))
    Unit <- IO.print(U32.show(pixel("stroke markers")))
    Unit <- IO.print(U32.show(pixel("markers")))
    Unit <- IO.print(U32.show(pixel("markers stroke")))
    Unit <- IO.print(U32.show(SVG.paint.order.value("  STROKE\tfill\nmarkers ", 5)))
    Unit <- IO.print(U32.show(SVG.paint.order.value("fill fill", 5)))
    Unit <- IO.print(U32.show(SVG.paint.order.value("normal stroke", 5)))
    IO.print(U32.show(SVG.paint.order.value("unknown", 5)))

#|4235104
#|4219039
#|6332224
#|10444864
#|6307999
#|10436704
#|2
#|5
#|5
#|5
