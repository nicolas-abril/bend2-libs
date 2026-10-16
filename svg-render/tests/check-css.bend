import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  +scene = SVG.document(XML.parse("<svg><style>rect{fill:red}.a{fill:lime}#b{fill:blue}.force{fill:red!important}g>rect:nth-child(2n){fill:blue}</style><rect width='8' height='8'/><rect class='a' x='8' width='8' height='8'/><rect id='b' class='a' x='16' width='8' height='8'/><rect class='force' style='fill:blue' x='24' width='8' height='8'/><rect class='force' style='fill:lime!important;fill:blue' x='32' width='8' height='8'/><g><rect y='8' width='8' height='8'/><rect x='8' y='8' width='8' height='8'/></g></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(scene, 2, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 10, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 18, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 26, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 34, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 2, 10, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 10, 10, 1)))
    IO.print(XML.serialize(XML.parse("<svg><style><![CDATA[rect[data-x='a&b'] { fill: red; }]]></style></svg>")))

#|16711680
#|65280
#|255
#|16711680
#|65280
#|16711680
#|255
#|<svg><style>rect[data-x='a&amp;b'] { fill: red; }</style></svg>
