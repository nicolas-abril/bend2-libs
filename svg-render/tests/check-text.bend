import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML
import gralha-truetype@0.1.0.0/font.bend as Font

def main() -> IO(Unit):
  +book = Font.font.parse("g|0:65|600 1 1 0|M0 0H500V700H0Z\ng|0:66|600 2 0 1|M0 0H500V700H0Z\ng|0:32|300 3 0 0|\nk|0:16781314|-100\nk|0:129|-50\n", Font.font.empty())
  +scene = SVG.document.fonts(XML.parse("<svg font-size='10'><text x='10' y='20' fill='red'>AB</text><text x='40' y='20' text-anchor='middle' fill='blue'> AB </text><text x='10' y='40' fill='lime'>A<title>AAA</title><desc>BBB</desc><tspan display='none'>BBB</tspan>B</text><text x='40' y='40' fill='red'>A<tspan dx='4' fill='blue'>B</tspan></text><text x='10 30' y='60' fill='blue'>AB</text></svg>"), 64.0, 64.0, book)
  do IO<Unit>:
    Unit <- IO.print(F32.show(Font.font.kern(book, 0, 1, 1, 2, 1)))
    Unit <- IO.print(F32.show(Font.font.kern(book, 0, 4, 1, 5, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 19, 16, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 20, 16, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 35, 16, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 44, 16, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 19, 36, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 20, 36, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 50, 36, 1)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 16, 56, 1)))
    IO.print(U32.show(SVG.pixel(scene, 31, 56, 1)))

#|-100
#|-50
#|16711680
#|16777215
#|255
#|16777215
#|65280
#|16777215
#|255
#|16777215
#|255
