import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

# The final filter region clips each pixel by its covered fraction; a primitive
# subregion still includes every pixel it touches.
def check(+region: String, +filter: String, +x: U32, +y: U32) -> String:
  nodes = SVG.prepare.scenes(SVG.document(XML.parse("<svg width='16' height='16'><defs><filter id='f' filterUnits='userSpaceOnUse' " ++ region ++ " color-interpolation-filters='sRGB'>" ++ filter ++ "</filter></defs><rect x='2' y='2' width='6' height='6' fill='red' filter='url(#f)'/></svg>"), 16.0, 16.0), SVG.identity(), 1)
  U32.show(SVG.pixel(nodes, x, y, 1))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(check("x='0' y='4.5' width='16' height='16'", "<feFlood flood-color='blue'/>", 8, 3))
    Unit <- IO.print(check("x='0' y='4.5' width='16' height='16'", "<feFlood flood-color='blue'/>", 8, 4))
    Unit <- IO.print(check("x='0' y='4.5' width='16' height='16'", "<feFlood flood-color='blue'/>", 8, 5))
    Unit <- IO.print(check("x='0.25' y='0' width='16' height='16'", "<feFlood flood-color='blue'/>", 0, 8))
    IO.print(check("x='0' y='0' width='16' height='16'", "<feFlood flood-color='blue' y='4.5' height='8'/>", 8, 4))

#|16777215
#|8421631
#|255
#|4210943
#|255
