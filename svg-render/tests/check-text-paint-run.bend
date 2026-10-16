# Overlapping glyphs are filled once, then stroked together, in paint-order.
import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML
import gralha-truetype@0.1.0.0/font.bend as Font

def same(+order: String) -> Bool:
  +book = Font.font.parse("g|0:65|600 1 1 0|M0 0H500V700H0Z\n", Font.font.empty())
  +paint = " fill='red' fill-opacity='.5' stroke='blue' stroke-opacity='.5' stroke-width='2' paint-order='" ++ order ++ "'"
  +text = SVG.document.fonts(XML.parse("<svg><text x='2' y='12' font-size='10' letter-spacing='-4' fill-rule='evenodd'" ++ paint ++ ">AA</text></svg>"), 32.0, 24.0, book)
  +path = SVG.document(XML.parse("<svg><path d='M2 12H7V5H2Z M4 12H9V5H4Z'" ++ paint ++ "/></svg>"), 32.0, 24.0)
  U.string.equal(SVG.ppm(32, 24, text, 2), SVG.ppm(32, 24, path, 2))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U.choose(String, same("normal"), "True", "False"))
    IO.print(U.choose(String, same("stroke"), "True", "False"))

#|True
#|True
