import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.1/scan.bend as U
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def sample(+body: String, +attrs: String, +x: U32, +y: U32) -> U32:
  SVG.pixel(SVG.prepare.scenes(SVG.document(XML.parse("<svg width='16' height='16'><defs><filter id='f' filterUnits='userSpaceOnUse' x='0' y='0' width='16' height='16' " ++ attrs ++ ">" ++ body ++ "</filter></defs><rect x='2' y='2' width='6' height='6' fill='red' filter='url(#f)'/></svg>"), 16.0, 16.0), SVG.identity(), 1), x, y, 1)

def equal(+a: U32, +b: U32) -> String:
  U.choose(String, U32.is_eq(a, b), "PASS", "FAIL " ++ U32.show(a) ++ " != " ++ U32.show(b))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(equal(sample("<feComponentTransfer><feFuncR type='linear' slope='.5'/></feComponentTransfer>", "", 3, 3), 12320768))
    Unit <- IO.print(equal(sample("<feComponentTransfer><feFuncR type='linear' slope='.5'/></feComponentTransfer>", "color-interpolation-filters='sRGB'", 3, 3), 8388608))
    Unit <- IO.print(equal(sample("<feOffset in='SourceAlpha'/>", "", 3, 3), 0))
    Unit <- IO.print(equal(sample("<feFlood flood-color='blue' result='x'/><feFlood flood-color='lime' result='x'/><feOffset in='x'/>", "", 3, 3), 65280))
    Unit <- IO.print(equal(sample("<feFlood flood-color='blue'/><feOffset in='later'/>", "", 3, 3), 255))
    Unit <- IO.print(equal(sample("<feOffset dx='5' result='shift'/><feMerge><feMergeNode in='shift'/><feMergeNode in='SourceGraphic'/></feMerge>", "", 3, 3), 16711680))
    Unit <- IO.print(equal(sample("<feFlood flood-color='blue' x='4' y='4' width='4' height='4'/>", "", 3, 3), 16777215))
    Unit <- IO.print(equal(sample("<feFlood flood-color='blue' x='4' y='4' width='4' height='4'/>", "", 5, 5), 255))
    Unit <- IO.print(equal(sample("<feGaussianBlur stdDeviation='0'/>", "", 3, 3), 16711680))
    Unit <- IO.print(equal(sample("<feDropShadow dx='6' dy='0' stdDeviation='0' flood-color='blue'/>", "", 9, 3), 255))
    IO.print(equal(sample("<feDropShadow dx='6' dy='0' stdDeviation='0' flood-color='blue'/>", "", 3, 3), 16711680))

#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
