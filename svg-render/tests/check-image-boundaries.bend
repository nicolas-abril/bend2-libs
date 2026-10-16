import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  +scene = SVG.document(XML.parse("<svg width='64' height='64'><rect width='64' height='64' fill='#eee'/><image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAYAAAD+Bd/7AAAASElEQVR4nFWMuQ0AMAjEGIchGI7JmIQ6axAIj0hhXWHr4BCyYw2SsmMNbBnxlhHvgOthZD6IS3GZaygacO0LRlYwsgNbfDLiCw2ecv3NuOvhAAAAAElFTkSuQmCC' x='23' y='2' width='18' height='22' image-rendering='pixelated'/><image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAYAAAD+Bd/7AAAASElEQVR4nFWMuQ0AMAjEGIchGI7JmIQ6axAIj0hhXWHr4BCyYw2SsmMNbBnxlhHvgOthZD6IS3GZaygacO0LRlYwsgNbfDLiCw2ecv3NuOvhAAAAAElFTkSuQmCC' x='44' y='2' width='18' height='22' preserveAspectRatio='xMaxYMax meet' image-rendering='pixelated'/></svg>"), 64.0, 64.0)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.pixel(scene, 23, 8, 8)))
    Unit <- IO.print(U32.show(SVG.pixel(scene, 36, 11, 8)))
    IO.print(U32.show(SVG.pixel(scene, 44, 19, 8)))

#|15373707
#|2637020
#|15121960
