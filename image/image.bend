# Premultiplied colors and quadtree pixel buffers shared by the decoders and the renderer.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U

type Color is Data:
  Color{r: F32, g: F32, b: F32, a: F32}

def clear() -> Color:
  Color{0.0, 0.0, 0.0, 0.0}

def rgba(r: F32, g: F32, b: F32, +a: F32) -> Color:
  Color{(r * a : F32), (g * a : F32), (b * a : F32), a}

# Filter and embedded-image buffers retain premultiplied floating-point channels.
# Uniform tiles share a single color instead of allocating one value per pixel.
type Pixels is Data:
  Flat{color: Color}
  Quad{tl: Pixels, tr: Pixels, bl: Pixels, br: Pixels}

def color.same(a: Color, b: Color) -> Bool:
  Color{ar, ag, ab, aa} = a
  Color{br, bg, bb, ba} = b
  F32.is_eq(ar, br) && F32.is_eq(ag, bg) && F32.is_eq(ab, bb) && F32.is_eq(aa, ba)

def pixels.join(+a: Pixels, +b: Pixels, +c: Pixels, +d: Pixels) -> Pixels:
  match a b c d:
    case Flat{aa} Flat{bb} Flat{cc} Flat{dd}:
      U.choose(Pixels, color.same(aa, bb) && color.same(aa, cc) && color.same(aa, dd), Flat{aa}, Quad{a, b, c, d})
    case _ _ _ _: Quad{a, b, c, d}

# A decoded image: a square quadtree of premultiplied colors covering width by height.
type Picture is Data:
  Picture{width: U32, height: U32, depth: Nat, pixels: Pixels}

def picture.blank() -> Picture:
  Picture{0, 0, 0n, Flat{clear()}}

@unsafe
def pixels.get(xs: Pixels, +size: U32, +x: U32, +y: U32) -> Color:
  match xs:
    case Flat{c}: c
    case Quad{a, b, c, d}:
      +half = (size / 2 : U32)
      pixels.get(U.choose(Pixels, U32.is_lt(y, half), U.choose(Pixels, U32.is_lt(x, half), a, b), U.choose(Pixels, U32.is_lt(x, half), c, d)), half, U32.mod(x, half), U32.mod(y, half))

@unsafe
def picture.depth(+size: U32, +side: U32, +depth: Nat) -> Nat:
  U.branch(Nat, U32.is_ge(side, size), _ => depth, _ => picture.depth(size, (side * 2 : U32), 1n+depth))

@unsafe
def pixels.set(+pixels: Pixels, +depth: Nat, +x: U32, +y: U32, +col: Color) -> Pixels:
  match pixels:
    case Flat{c}:
      match depth:
        case 0n: Flat{col}
        case 1n+d: pixels.set(Quad{Flat{c}, Flat{c}, Flat{c}, Flat{c}}, 1n+d, x, y, col)
    case Quad{a, b, c, e}:
      match depth:
        case 0n: Flat{col}
        case 1n+d:
          +dd = d
          +half = U32.shln(1, dd)
          U.branch(Pixels, U32.is_lt(y, half),
            _ => U.branch(Pixels, U32.is_lt(x, half), _ => pixels.join(pixels.set(a, dd, x, y, col), b, c, e), _ => pixels.join(a, pixels.set(b, dd, (x - half : U32), y, col), c, e)),
            _ => U.branch(Pixels, U32.is_lt(x, half), _ => pixels.join(a, b, pixels.set(c, dd, x, (y - half : U32), col), e), _ => pixels.join(a, b, c, pixels.set(e, dd, (x - half : U32), (y - half : U32), col))))
