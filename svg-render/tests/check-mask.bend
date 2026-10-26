import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def drawing(kind: String) -> List<&2, SVG.Scene<SVG.Brush>>:
  SVG.document(XML.parse("<svg><defs><mask id='m' mask-type='" ++ kind ++ "'><rect width='16' height='32' fill='white'/><rect x='16' width='16' height='32' fill='black'/></mask></defs><rect width='32' height='32' fill='red' mask='url(#m)'/></svg>"), 64.0, 64.0)

def picked(p: SVG.Pick) -> String:
  SVG.Pick{found, target, inv} = p
  target

def main() -> IO(Unit):
  +lum = drawing("luminance")
  +alpha = drawing("alpha")
  +cycle = SVG.document(XML.parse("<svg><defs><mask id='m'><rect width='64' height='64' fill='white' mask='url(#m)'/></mask></defs><rect width='64' height='64' fill='red' mask='url(#m)'/></svg>"), 64.0, 64.0)
  +linear = SVG.document(XML.parse("<svg><defs><mask id='m' color-interpolation='linearRGB'><rect width='32' height='32' fill='red' opacity='.5'/><rect width='32' height='32' fill='lime' opacity='.5'/></mask></defs><rect width='32' height='32' fill='purple' mask='url(#m)'/></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(lum, 5, 5, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(lum, 25, 5, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(alpha, 25, 5, 1)))
    Unit <- IO.print(picked(SVG.pick(lum, SVG.Point{5.0, 5.0})))
    Unit <- IO.print("outside=" ++ picked(SVG.pick(lum, SVG.Point{25.0, 5.0})))
    Unit <- IO.print(U32.show(SVG.pixel(linear, 5, 5, 1)))
    IO.print(U32.show(SVG.pixel(cycle, 5, 5, 1)))

#|16711680
#|16777215
#|16711680
#|6
#|outside=
#|13342411
#|16777215
