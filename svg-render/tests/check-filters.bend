import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def check(+filter: String, +extra: String, +x: U32, +y: U32) -> String:
  nodes = SVG.prepare.scenes(SVG.document(XML.parse("<svg width='16' height='16'><defs><filter id='f' filterUnits='userSpaceOnUse' x='0' y='0' width='16' height='16' color-interpolation-filters='sRGB'>" ++ filter ++ "</filter></defs><rect x='2' y='2' width='6' height='6' fill='red' filter='url(#f)' " ++ extra ++ "/></svg>"), 16.0, 16.0), SVG.identity(), 1)
  U32.show(SVG.pixel(nodes, x, y, 1))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(check("<feFlood flood-color='blue'/>", "", 12, 12))
    Unit <- IO.print(check("<feOffset dx='4' dy='2'/>", "", 8, 5))
    Unit <- IO.print(check("<feOffset dx='4' dy='2'/>", "", 3, 3))
    Unit <- IO.print(check("<feColorMatrix values='0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0'/>", "", 3, 3))
    Unit <- IO.print(check("<feFlood flood-color='blue'/><feComposite in2='SourceGraphic' operator='in'/>", "", 3, 3))
    Unit <- IO.print(check("<feFlood flood-color='blue'/><feComposite in2='SourceGraphic' operator='in'/>", "", 12, 12))
    Unit <- IO.print(check("<feComponentTransfer><feFuncR type='linear' slope='0'/><feFuncB type='linear' intercept='1'/></feComponentTransfer>", "", 3, 3))
    Unit <- IO.print(check("<feFlood flood-color='blue'/>", "opacity='0.5'", 12, 12))
    IO.print(check("", "", 3, 3))

#|255
#|16711680
#|16777215
#|65280
#|255
#|16777215
#|255
#|8421631
#|16777215
