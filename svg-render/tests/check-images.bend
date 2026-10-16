import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  +scene = SVG.document(XML.parse("<svg width='16' height='16'><image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==' x='2' y='3' width='4' height='6' preserveAspectRatio='none' fill='none' fill-opacity='0'/></svg>"), 16.0, 16.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(scene, 2, 3, 4)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 5, 8, 4)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 1, 3, 4)))
    IO.print(U32.show(SVG.pixel(scene, 6, 8, 4)))

#|16711680
#|16711680
#|16777215
#|16777215
