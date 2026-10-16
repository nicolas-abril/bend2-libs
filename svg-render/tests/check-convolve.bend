# Independent matrix expectations for kernel direction, normalization, alpha and edges.
import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def doc(body: String) -> List<&2, SVG.Scene<SVG.Brush>>:
  SVG.document(XML.parse("<svg width='24' height='24'>" ++ body ++ "</svg>"), 24.0, 24.0)

def rect(x: String, y: String, w: String, color: String, alpha: String) -> String:
  "<rect x='" ++ x ++ "' y='" ++ y ++ "' width='" ++ w ++ "' height='8' fill='" ++ color ++ "' fill-opacity='" ++ alpha ++ "'/>"

def filtered(attrs: String, source: String, region: String) -> String:
  "<defs><filter id='c' filterUnits='userSpaceOnUse' " ++ region ++ " color-interpolation-filters='sRGB'><feConvolveMatrix " ++ attrs ++ "/></filter></defs><g filter='url(#c)'>" ++ source ++ "</g>"

def equal(a: String, b: String) -> String:
  U.choose(String, U.string.equal(SVG.ppm(24, 24, doc(a), 2), SVG.ppm(24, 24, doc(b), 2)), "PASS", "FAIL")

def basic(attrs: String, expected: String) -> String:
  equal(filtered(attrs, rect("6", "6", "8", "red", "1"), "x='0' y='0' width='24' height='24'"), expected)

def alpha(attrs: String, expected: String) -> String:
  equal(filtered(attrs, rect("6", "6", "8", "red", ".5"), "x='0' y='0' width='24' height='24'"), expected)

def edges(mode: String, tail: String) -> String:
  equal(filtered("order='3 1' kernelMatrix='1 0 0' targetX='0' edgeMode='" ++ mode ++ "'", rect("6", "6", "4", "red", "1") ++ rect("10", "6", "4", "blue", "1"), "x='6' y='6' width='8' height='8'"), rect("6", "6", "2", "red", "1") ++ rect("8", "6", "4", "blue", "1") ++ tail)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(basic("order='1' kernelMatrix='1'", rect("6", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='1 0 0'", rect("5", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='1 0 0' targetX='0'", rect("4", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='0 0 1'", rect("7", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='1 3' kernelMatrix='1 0 0'", rect("6", "5", "8", "red", "1")))
    Unit <- IO.print(basic("order='2 2' kernelMatrix='0 0 0 1'", rect("7", "7", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='2 0 0' divisor='0'", rect("5", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='-2 0 0'", rect("5", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='1 0'", rect("6", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='0' kernelMatrix='1'", rect("6", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='1' kernelMatrix='1' targetX='1'", rect("6", "6", "8", "red", "1")))
    Unit <- IO.print(alpha("order='1' kernelMatrix='1' divisor='2'", rect("6", "6", "8", "red", ".25")))
    Unit <- IO.print(alpha("order='1' kernelMatrix='1' divisor='2' preserveAlpha='true'", rect("6", "6", "8", "rgb(50% 0% 0%)", ".5")))
    Unit <- IO.print(alpha("order='1' kernelMatrix='0' bias='.5' preserveAlpha='true'", rect("6", "6", "8", "rgb(50% 50% 50%)", ".5")))
    Unit <- IO.print(equal(filtered("order='1' kernelMatrix='0' bias='.5'", rect("6", "6", "8", "red", ".5"), "x='0' y='0' width='24' height='24'"), "<rect width='24' height='24' fill='rgb(50% 50% 50%)' fill-opacity='.5'/>"))
    Unit <- IO.print(edges("none", ""))
    Unit <- IO.print(edges("duplicate", rect("12", "6", "2", "blue", "1")))
    Unit <- IO.print(edges("wrap", rect("12", "6", "2", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='1 0 0' kernelUnitLength='2'", rect("4", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='3 1' kernelMatrix='1 0 0' kernelUnitLength='0'", rect("5", "6", "8", "red", "1")))
    Unit <- IO.print(basic("order='1' kernelMatrix='1' in='SourceAlpha'", rect("6", "6", "8", "black", "1")))
    Unit <- IO.print(equal("<g transform='scale(2)'>" ++ filtered("order='3 1' kernelMatrix='1 0 0' kernelUnitLength='1'", "<rect x='3' y='3' width='4' height='4' fill='red'/>", "x='0' y='0' width='12' height='12'") ++ "</g>", rect("4", "6", "8", "red", "1")))
    Unit <- IO.print(equal("<g transform='scale(2)'>" ++ filtered("order='3 1' kernelMatrix='1 0 0'", "<rect x='3' y='3' width='4' height='4' fill='red'/>", "x='0' y='0' width='12' height='12'") ++ "</g>", rect("5", "6", "8", "red", "1")))
    Unit <- IO.print(equal(filtered("order='3 1' kernelMatrix='1 0 0' edgeMode='wrap' kernelUnitLength='.5'", rect("6", "6", "4", "red", "1") ++ rect("10", "6", "4", "blue", "1"), "x='6' y='6' width='8' height='8'"), rect("6", "6", "3", "red", "1") ++ rect("9", "6", "1", "rgb(50% 0% 50%)", "1") ++ rect("10", "6", "3", "blue", "1") ++ rect("13", "6", "1", "rgb(50% 0% 50%)", "1")))
    Unit <- IO.print(alpha("order='1' kernelMatrix='1' bias='.75'", "<rect width='24' height='24' fill='rgb(75% 75% 75%)' fill-opacity='.75'/>" ++ rect("6", "6", "8", "rgb(100% 93.75% 93.75%)", "1")))
    IO.print(equal("<g transform='translate(24 0) rotate(90)'>" ++ filtered("order='3 1' kernelMatrix='1 0 0' kernelUnitLength='2'", rect("6", "6", "8", "red", "1"), "x='0' y='0' width='24' height='24'") ++ "</g>", rect("10", "4", "8", "red", "1")))

#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS

#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
#|PASS
