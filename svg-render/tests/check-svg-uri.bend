import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def run(source: String) -> IO(Unit):
  IO.print(U32.show(SVG.pixel(SVG.prepare.scenes(SVG.document(XML.parse(source), 16.0, 16.0), SVG.identity(), 1), 8, 8, 1)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/></svg>")
    Unit <- run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" href=\"DATA:IMAGE/SVG+XML;BASE64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/></svg>")
    Unit <- run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" xlink:href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/></svg>")
    Unit <- run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" href=\"data:image/svg+xml-wrong;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/></svg>")
    Unit <- run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+\"/></svg>")
    Unit <- run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" href=\"data:image/svg+xml;base64,!!!\"/></svg>")
    run("<svg width=\"16\" height=\"16\"><image width=\"16\" height=\"16\" href=\"data:image/svg+xml;base64,77u/PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/></svg>")

#|16711680
#|16711680
#|16711680
#|16777215
#|16777215
#|16777215
#|16711680
