import Base
import ../svg.bend as SVG

def vertices(xs: List<&2, SVG.MarkerVertex>) -> String:
  match xs:
    case Nil{}: ""
    case Con{SVG.MarkerVertex{SVG.Point{x, y}, angle}, rest}:
      F32.show(x) ++ "," ++ F32.show(y) ++ ":" ++ F32.show(angle) ++ ";" ++ vertices(rest)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(vertices(SVG.marker.trace("M0 0L10 0L10 10")))
    Unit <- IO.print(vertices(SVG.marker.trace("M0 0L10 0L10 10Z")))
    Unit <- IO.print(vertices(SVG.marker.trace("M0 0L0 0L10 0M20 20L20 30")))
    Unit <- IO.print(vertices(SVG.marker.trace("M0 0C0 10 10 10 10 0")))
    Unit <- IO.print(vertices(SVG.marker.trace("M0 0A4 4 0 0 0 0 0L8 0")))
    IO.print("move-only:" ++ vertices(SVG.marker.trace("M2 3")))

#|0,0:0;10,0:45;10,10:90;
#|0,0:-67.5;10,0:45;10,10:157.5;0,0:-67.5;
#|0,0:0;0,0:0;10,0:0;20,20:90;20,30:90;
#|0,0:90;10,0:-90;
#|0,0:0;8,0:0;
#|move-only:2,3:0;
