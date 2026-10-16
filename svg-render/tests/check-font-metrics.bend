import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML
import gralha-truetype@0.1.0.0/font.bend as Font

def offset(+book: Font.FontBook, +face: String, +kind: String) -> String:
  F32.show(SVG.text.baseline(SVG.text.font.inherit(SVG.text.font.default(book), Con{XML.Attr{"font-size", "8"}, Con{XML.Attr{"font-weight", face}, Con{XML.Attr{"baseline-shift", kind}, Nil{}}}})))

def main() -> IO(Unit):
  +book = Font.font.parse("m|0:subscript|0.075\nm|0:superscript|0.35\nm|1:subscript|0.15\nm|1:superscript|0.45\nm|1:xheight|0.546\nm|1:ascender|0.9\nm|1:descender|-0.25\n", Font.font.empty())
  do IO<Unit>:
    Unit <- IO.print(offset(book, "normal", "sub"))
    Unit <- IO.print(offset(book, "normal", "super"))
    Unit <- IO.print(offset(book, "bold", "sub"))
    Unit <- IO.print(offset(book, "bold", "super"))
    Unit <- IO.print(offset(Font.font.empty(), "normal", "sub"))
    Unit <- IO.print(offset(Font.font.empty(), "normal", "super"))
    Unit <- IO.print(F32.show(SVG.text.baseline(SVG.text.font.inherit(SVG.text.font.default(book), Con{XML.Attr{"font-size", "10"}, Con{XML.Attr{"font-weight", "bold"}, Con{XML.Attr{"dominant-baseline", "middle"}, Nil{}}}}))))
    IO.print(F32.show(SVG.text.baseline(SVG.text.font.inherit(SVG.text.font.default(book), Con{XML.Attr{"font-size", "10"}, Con{XML.Attr{"font-weight", "bold"}, Con{XML.Attr{"dominant-baseline", "central"}, Nil{}}}}))))

#|0.6
#|-2.8
#|1.2
#|-3.6
#|1.6
#|-3.2
#|2.73
#|3.25
