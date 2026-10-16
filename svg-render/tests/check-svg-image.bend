import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def main() -> IO(Unit):
  IO.print(U32.show(SVG.pixel(SVG.prepare.scenes(SVG.document(XML.parse("<svg width='16' height='16'><image width='16' height='16' href='data:image/svg+xml,%3Csvg%20width=%2216%22%20height=%2216%22%3E%3Crect%20width=%2216%22%20height=%2216%22%20fill=%22red%22/%3E%3C/svg%3E'/></svg>"), 16.0, 16.0), SVG.identity(), 1), 8, 8, 1)))

#|16711680
