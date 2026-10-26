# Independent geometric expectations for integer morphology and premultiplied RGBA.
import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.1/scan.bend as U
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def doc(body: String) -> List<&2, SVG.Scene<SVG.Brush>>:
  SVG.document(XML.parse("<svg width='24' height='24'>" ++ body ++ "</svg>"), 24.0, 24.0)

def filtered(op: String, radius: String, source: String, input: String) -> String:
  "<defs><filter id='m' filterUnits='userSpaceOnUse' x='0' y='0' width='24' height='24' color-interpolation-filters='sRGB'><feMorphology operator='" ++ op ++ "' radius='" ++ radius ++ "' in='" ++ input ++ "'/></filter></defs><g filter='url(#m)'>" ++ source ++ "</g>"

def equal(a: String, b: String) -> String:
  U.choose(String, U.string.equal(SVG.ppm(24, 24, doc(a), 2), SVG.ppm(24, 24, doc(b), 2)), "PASS", "FAIL")

def rect() -> String:
  "<rect x='6' y='6' width='8' height='8' fill='red'/>"

def color(op: String, expected: U32) -> String:
  nodes = SVG.prepare.scenes(doc(filtered(op, "1", "<rect x='6' y='6' width='4' height='8' fill='red' fill-opacity='.5'/><rect x='10' y='6' width='4' height='8' fill='blue' fill-opacity='.75'/>", "SourceGraphic")), SVG.identity(), 1)
  +got = SVG.pixel(nodes, 9, 9, 1)
  U.choose(String, U32.is_eq(got, expected), "PASS", U32.show(got))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(equal(filtered("erode", "2", rect(), "SourceGraphic"), "<rect x='8' y='8' width='4' height='4' fill='red'/>"))
    Unit <- IO.print(equal(filtered("dilate", "2", rect(), "SourceGraphic"), "<rect x='4' y='4' width='12' height='12' fill='red'/>"))
    Unit <- IO.print(equal(filtered("dilate", "2 0", rect(), "SourceGraphic"), "<rect x='4' y='6' width='12' height='8' fill='red'/>"))
    Unit <- IO.print(equal(filtered("erode", "0 2", rect(), "SourceGraphic"), "<rect x='6' y='8' width='8' height='4' fill='red'/>"))
    Unit <- IO.print(equal(filtered("dilate", "0", rect(), "SourceGraphic"), rect()))
    Unit <- IO.print(equal(filtered("dilate", "2", rect(), "SourceAlpha"), "<rect x='4' y='4' width='12' height='12' fill='black'/>"))
    Unit <- IO.print(color("dilate", 12534015))
    IO.print(color("erode", 8421504))

#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
