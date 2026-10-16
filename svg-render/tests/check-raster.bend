import Base
import ../svg.bend as SVG
import gralha-image@0.1.0.0/image.bend as Img

def show(c: Img.Color) -> String:
  Img.Color{r, g, b, a} = c
  F32.show(r) ++ "," ++ F32.show(g) ++ "," ++ F32.show(b) ++ "," ++ F32.show(a)

def main() -> IO(Unit):
  +r = {SVG.Raster{SVG.Point{0.0, 0.0}, 1.0, 2, 2, 1n, False{}, Img.Quad{Img.Flat{SVG.color("red")}, Img.Flat{SVG.color("lime")}, Img.Flat{SVG.color("blue")}, Img.Flat{Img.clear()}}} : SVG.Raster}
  do IO<Unit>:
    Unit <- IO.print(show(SVG.raster.sample(r, SVG.Point{0.5, 0.5})))
    Unit <- IO.print(show(SVG.raster.sample(r, SVG.Point{1.0, 1.0})))
    Unit <- IO.print(show(SVG.raster.sample(r, SVG.Point{0.0, 0.5})))
    IO.print(show(SVG.raster.sample(r, SVG.Point{3.0, 3.0})))

#|1,0,0,1
#|0.25,0.25,0.25,0.75
#|0.5,0,0,0.5
#|0,0,0,0
