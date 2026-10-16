import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(SVG.image.svg.source(U.Scan{"image/svg+xml;base64", "w6nOu/CfmIM="}))
    Unit <- IO.print(SVG.image.svg.source(U.Scan{"image/svg+xml", "%C3%A9%CE%BB%F0%9F%98%83"}))
    IO.print(SVG.image.svg.source(U.Scan{"image/svg+xml", "éλ😃"}))

#|éλ😃
#|éλ😃
#|éλ😃
