import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def yes(value: Bool) -> IO(Unit):
  IO.print(U.choose(String, value, "True", "False"))

def valid(text: String) -> IO(Unit):
  yes(SVG.image.svg.wellformed(XML.tokenize(text), Nil{}, False{}))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- yes(SVG.image.svg.reference("data:image/svg+xml;base64,"))
    Unit <- yes(SVG.image.svg.reference("DATA:IMAGE/SVG+XML;BASE64,"))
    Unit <- yes(SVG.image.svg.reference("data:image/svg+xml-wrong,"))
    Unit <- yes(SVG.image.svg.reference("http:image/svg+xml,"))
    Unit <- valid("<svg><g><rect/></g></svg>")
    Unit <- valid("<svg><g><rect/></svg>")
    Unit <- valid("<svg><rect/>")
    Unit <- valid("<svg/><svg/>")
    Unit <- valid("<rect/>")
    Unit <- valid(" <svg/> ")
    Unit <- valid("<svg><![CDATA[hi]]></svg>")
    valid("")

#|True
#|True
#|False
#|False
#|True
#|False
#|False
#|False
#|False
#|True
#|True
#|False
