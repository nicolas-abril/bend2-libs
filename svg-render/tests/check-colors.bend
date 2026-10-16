import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML
import gralha-image@0.1.0.0/image.bend as Img

def show(s: String) -> IO(Unit):
  IO.print(U32.show(SVG.color.pack(SVG.color.over(SVG.color(s), Img.rgba(1.0, 1.0, 1.0, 1.0)))))

def main() -> IO(Unit):
  +scene = SVG.document(XML.parse("<svg color='royalblue'><rect width='8' height='8' fill='CURRENTCOLOR'/><g opacity='50%'><rect x='8' width='8' height='8' fill='red'/></g><rect x='16' width='8' height='8' fill='blue' fill-opacity='25%'/><path d='M24 4H32' stroke='lime' stroke-width='8' stroke-opacity='50%'/><g fill='salmon'><rect x='32' width='8' height='8' fill='INHERIT'/></g></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- show(" ALICEBLUE ")
    Unit <- show("LightGoldenRodYellow")
    Unit <- show("rgb(100%,0%,0%)")
    Unit <- show("rgb(0 100% 255 / 50%)")
    Unit <- show("rgba(0%,100%,0%,25%)")
    Unit <- show("rgb(300 -50 0)")
    Unit <- show("rgb(none 255 none)")
    Unit <- show("rgb(255 0 0 / none)")
    Unit <- show("hsl(-.5turn 100% 50%)")
    Unit <- show("hsl(200grad 100% 50%)")
    Unit <- show("hsl(3.14159265359rad 100% 50%)")
    Unit <- show("hsla(120,100%,50%,50%)")
    Unit <- show("hwb(0 20% 30%)")
    Unit <- show("hwb(180 80% 80% / 50%)")
    Unit <- show("#aBcD")
    Unit <- show("rgb(255, 0 0)")
    Unit <- show("rgb(255 0 0, .5)")
    Unit <- show("#gg0000")
    Unit <- IO.print(U32.show(SVG.pixel(scene, 2, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 10, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 18, 2, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 28, 4, 1)))
    IO.print(U32.show(SVG.pixel(scene, 34, 4, 1)))

#|15792383
#|16448210
#|16711680
#|8454143
#|12582847
#|16711680
#|65280
#|16777215
#|65535
#|65535
#|65535
#|8454016
#|11744051
#|12566463
#|11912403
#|0
#|0
#|0
#|4286945
#|16744576
#|12566527
#|8454016

#|16416882
