import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.1/scan.bend as U
import gralha-xml-doc@0.1.0.1/xml.bend as XML

def many(n: Nat, +word: String, acc: String) -> String:
  match n:
    case Zero{}: acc
    case Succ{d}: many(d, word, word ++ acc)

def yes(b: Bool) -> IO(Unit):
  IO.print(U.choose(String, b, "True", "False"))

def main() -> IO(Unit):
  +data = many(1024n, "0123456789abcdef0123456789abcdef", "")
  +node = {XML.Element{"svg", Con{XML.Attr{"data", data}, Con{XML.Attr{"tag", "&<>\"😀"}, Nil{}}}, Con{XML.Element{"#text", Nil{}, Nil{}, data}, Nil{}}, ""} : XML.Element}
  +saved = XML.serialize(node)
  +suffix = U.drop(U.drop(saved, "<svg data=\""), data)
  do IO<Unit>:
    Unit <- IO.print(U32.show(SVG.length(saved)))
    Unit <- yes(U.prefix(saved, "<svg data=\"0123456789abcdef"))
    Unit <- yes(U.prefix(suffix, "\" tag=\"&amp;&lt;&gt;&quot;😀\">"))
    Unit <- yes(U.string.equal(saved, saved))
    Unit <- yes(Bool.not(U.string.equal(data, U.rev(U.rev(data, ""), "!"))))
    yes(String.eq(U.drop(U.drop(suffix, "\" tag=\"&amp;&lt;&gt;&quot;😀\">"), data), "</svg>"))

#|65582
#|True
#|True
#|True
#|True
#|True
