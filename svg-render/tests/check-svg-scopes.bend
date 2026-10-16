import Base
import ../svg.bend as SVG
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def run(source: String) -> IO(Unit):
  IO.print(U32.show(SVG.pixel(SVG.prepare.scenes(SVG.document(XML.parse("<svg width='16' height='16'>" ++ source ++ "</svg>"), 16.0, 16.0), SVG.identity(), 1), 8, 8, 1)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- run("<style>rect{fill:blue}</style><image width=\"16\" height=\"16\"  href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIvPjwvc3ZnPg==\"/>")
    Unit <- run("<style>rect{fill:blue}</style><image width=\"16\" height=\"16\"  href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxzdHlsZT5yZWN0e2ZpbGw6cmVkfTwvc3R5bGU+PHJlY3Qgd2lkdGg9IjE2IiBoZWlnaHQ9IjE2Ii8+PC9zdmc+\"/>")
    Unit <- run("<defs><linearGradient id=\"p\"><stop stop-color=\"red\"/></linearGradient></defs><image width=\"16\" height=\"16\"  href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0idXJsKCNwKSIvPjwvc3ZnPg==\"/>")
    Unit <- run("<image width=\"16\" height=\"16\"  href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxkZWZzPjxsaW5lYXJHcmFkaWVudCBpZD0icCI+PHN0b3Agc3RvcC1jb2xvcj0icmVkIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PC9zdmc+\"/><rect width=\"16\" height=\"16\" fill=\"url(#p)\"/>")
    Unit <- run("<image width=\"16\" height=\"16\" opacity=\".5\" href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/>")
    Unit <- run("<image href=\"data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHN0eWxlPnN2Z3t3aWR0aDo4cHg7aGVpZ2h0OjhweH08L3N0eWxlPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InJlZCIvPjwvc3ZnPg==\"/>")
    run("<image width=\"16\" height=\"16\" visibility=\"hidden\" href=\"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPjxyZWN0IHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0icmVkIi8+PC9zdmc+\"/>")

#|0
#|16711680
#|16777215
#|16777215
#|16744576
#|16711680
#|16777215
