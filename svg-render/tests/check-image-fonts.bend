import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def has(s: String) -> Bool:
  SVG.text.present(Con{XML.parse(s), Nil{}})

def yes(b: Bool) -> IO(Unit):
  IO.print(U.choose(String, b, "True", "False"))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- yes(has("<svg><text>Bend</text></svg>"))
    Unit <- yes(has("<svg><image href=\"data:image/svg+xml,%3Csvg/%3E\"/></svg>"))
    Unit <- yes(has("<svg><image href=\" DATA: IMAGE/SVG+XML ;BASE64,PHN2Zy8+ \"/></svg>"))
    Unit <- yes(has("<svg><g><image xlink:href=\"data:image/svg+xml,%3Csvg/%3E\"/></g></svg>"))
    Unit <- yes(has("<svg><image href=\"data:image/png;base64,AA==\"/></svg>"))
    yes(has("<svg><image href=\"data:image/svg+xml-fake;base64,AA==\"/></svg>"))

#|True
#|True
#|True
#|True
#|False
#|False
