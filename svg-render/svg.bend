# SVG parsing, geometry, painting and rasterization. No foreign code.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML
import gralha-css-style@0.1.0.0/css.bend as CSS
import gralha-bytes@0.1.0.0/bytes.bend as Bin
import gralha-image@0.1.0.0/image.bend as Img
import gralha-png-decode@0.1.0.0/png.bend as PNG
import gralha-jpeg-decode@0.1.0.0/jpeg.bend as JPEG
import gralha-coverage@0.1.0.0/cover.bend as Cov
import gralha-truetype@0.1.0.0/font.bend as Font

def length.go(s: String, acc: U32) -> U32:
  match s:
    case SNil{}: acc
    case SCon{c, t}: length.go(t, U32.inc(acc))

def length(s: String) -> U32:
  length.go(s, 0)

# Affine transforms, composed in SVG's column - vector order.
type Matrix is Data:
  Matrix{a: F32, b: F32, c: F32, d: F32, e: F32, f: F32}

def identity() -> Matrix:
  Matrix{1.0, 0.0, 0.0, 1.0, 0.0, 0.0}

def matrix.mul(+m: Matrix, +n: Matrix) -> Matrix:
  Matrix{a, b, c, d, e, f} = m
  Matrix{g, h, i, j, k, l} = n
  Matrix{(a * g + c * h : F32), (b * g + d * h : F32), (a * i + c * j : F32),
    (b * i + d * j : F32), (a * k + c * l + e : F32), (b * k + d * l + f : F32)}

def matrix.inverse.values(+m: Matrix, +det: F32) -> Matrix:
  Matrix{a, b, c, d, e, f} = m
  Matrix{(d / det : F32), (0.0 - b / det : F32), (0.0 - c / det : F32),
    (a / det : F32), ((c * f - d * e) / det : F32), ((b * e - a * f) / det : F32)}

def matrix.inverse(+m: Matrix) -> Matrix:
  Matrix{a, b, c, d, e, f} = m
  matrix.inverse.values(m, (a * d - b * c : F32))

type Point is Data:
  Point{x: F32, y: F32}

def matrix.point(+m: Matrix, +p: Point) -> Point:
  Matrix{a, b, c, d, e, f} = m
  Point{x, y} = p
  Point{(a * x + c * y + e : F32), (b * x + d * y + f : F32)}

def translate(x: F32, y: F32) -> Matrix:
  Matrix{1.0, 0.0, 0.0, 1.0, x, y}

def scale(x: F32, y: F32) -> Matrix:
  Matrix{x, 0.0, 0.0, y, 0.0, 0.0}

def rotate(+angle: F32) -> Matrix:
  +r = (angle * 0.017453292519943295 : F32)
  Matrix{F32.cos(r), F32.sin(r), F32.neg(F32.sin(r)), F32.cos(r), 0.0, 0.0}

def transform.one(+name: String, +v: List<&2, F32>) -> Matrix:
  +x = U.nth(v, 0n, 0.0)
  +y = U.nth(v, 1n, 0.0)
  +z = U.nth(v, 2n, 0.0)
  U.branch(Matrix, U.string.equal(name, "translate"), _ => translate(x, y),
    _ => U.branch(Matrix, U.string.equal(name, "scale"), _ => scale(x, U.nth(v, 1n, x)),
      _ => U.branch(Matrix, U.string.equal(name, "rotate"),
        _ => matrix.mul(translate(y, z), matrix.mul(rotate(x), translate(F32.neg(y), F32.neg(z)))),
        _ => U.branch(Matrix, U.string.equal(name, "matrix"),
          _ => Matrix{x, y, z, U.nth(v, 3n, 1.0), U.nth(v, 4n, 0.0), U.nth(v, 5n, 0.0)},
          _ => U.branch(Matrix, U.string.equal(name, "skewX"),
            _ => Matrix{1.0, 0.0, F32.tan((x * 0.017453292519943295 : F32)), 1.0, 0.0, 0.0},
            _ => U.branch(Matrix, U.string.equal(name, "skewY"),
              _ => Matrix{1.0, F32.tan((x * 0.017453292519943295 : F32)), 0.0, 1.0, 0.0, 0.0},
              _ => identity()))))))

def transform.args(n: String, s: U.Scan, m: Matrix, next: String -> Matrix -> Matrix) -> Matrix:
  U.Scan{h, t} = s
  next(t)(matrix.mul(m, transform.one(n, U.numbers(h))))

def transform.name(s: U.Scan, m: Matrix, next: String -> Matrix -> Matrix) -> Matrix:
  U.Scan{h, t} = s
  transform.args(h, U.until(t, 41, ""), m, next)

@unsafe
def transform(+s: String, +m: Matrix) -> Matrix:
  U.branch(Matrix, U.string.equal(U.trim(s), ""), _ => m,
    _ => transform.name(U.until(U.separators(s), 40, ""), m, t => n => transform(t, n)))

# Paths are flattened in user coordinates. The fill-only closing edge of an
# open subpath is kept separate from its stroked edges.
# An edge is one heap node: its endpoints are stored as four numbers, so
# building, walking and freeing edge lists touch half the nodes a pair of
# points would.
type Edge is Data:
  Edge{x0: F32, y0: F32, x1: F32, y1: F32, stroke: Bool, closed: Bool}

def edge.of(a: Point, b: Point, stroke: Bool, closed: Bool) -> Edge:
  Point{x0, y0} = a
  Point{x1, y1} = b
  Edge{x0, y0, x1, y1, stroke, closed}

# ---- analytic coverage ----
# A cover is a pixel-space coverage mask (see cover.bend) together with the raster
# grid it was built for, so device points map straight to its cells.
type Cover is Data:
  Cover{mask: Cov.CovMask, origin: Point, step: F32}

def cover.none() -> Cover:
  Cover{Cov.mask.none(), Point{0.0, 0.0}, 1.0}

def cover.present(+c: Cover) -> Bool:
  Cover{mask, origin, step} = c
  Cov.mask.present(mask)

def cover.at(+c: Cover, +p: Point) -> F32:
  Cover{mask, Point{ox, oy}, step} = c
  Point{x, y} = p
  Cov.mask.at(mask, ((x - ox) / step : F32), ((y - oy) / step : F32))

def point.add(p: Point, q: Point) -> Point:
  Point{x, y} = p
  Point{u, v} = q
  Point{(x + u : F32), (y + v : F32)}

def point.sub(p: Point, q: Point) -> Point:
  Point{x, y} = p
  Point{u, v} = q
  Point{(x - u : F32), (y - v : F32)}

def point.scale(p: Point, +s: F32) -> Point:
  Point{x, y} = p
  Point{(x * s : F32), (y * s : F32)}

def point.dot(p: Point, q: Point) -> F32:
  Point{x, y} = p
  Point{u, v} = q
  (x * u + y * v : F32)

def point.mid(p: Point, q: Point) -> Point:
  point.scale(point.add(p, q), 0.5)

def point.distance(+p: Point, +q: Point) -> F32:
  +d = point.sub(p, q)
  F32.sqrt(point.dot(d, d))

# Curves are flattened to a tolerance measured in device pixels (converted to
# local units through the element's matrix by the caller), so a curve gets as
# many segments as the output size needs and no more.
def flat.tolerance() -> F32:
  0.03

# The largest scale the matrix applies to any direction, bounded by its
# Frobenius norm; local tolerance = pixel tolerance / scale.
def matrix.norm(+m: Matrix) -> F32:
  Matrix{a, b, c, d, e, f} = m
  U.max(0.000001, F32.sqrt((a * a + b * b + c * c + d * d : F32)))

# scale is the device pixels per unit of the frame m maps into (1 when m
# maps to the device, the tile's density for pattern content).
def local.tolerance(+m: Matrix, +scale: F32) -> F32:
  (flat.tolerance() / (scale * matrix.norm(m)) : F32)

def chord.cross(p: Point, q: Point) -> F32:
  Point{x, y} = p
  Point{u, v} = q
  (x * v - y * u : F32)

# Whether x lies within tol of the chord pq: at most tol from its line and
# not beyond either end by more than tol.
def chord.near(+p: Point, +q: Point, +x: Point, +tol: F32) -> Bool:
  +d = point.sub(q, p)
  +len = F32.sqrt(point.dot(d, d))
  +off = point.sub(x, p)
  U.branch(Bool, F32.is_lt(len, 0.000001), _ => F32.is_le(point.distance(p, x), tol),
    _ => F32.is_le(F32.abs(chord.cross(d, off)), (tol * len : F32))
      && F32.is_ge(point.dot(d, off), (F32.neg(tol) * len : F32))
      && F32.is_le(point.dot(d, off), ((len + tol) * len : F32)))

# A cubic's distance from its chord is 3t(1-t) times a mix of its control
# points' distances, at most three quarters of the larger, so the curve is
# within tol when both control points are within 4/3 tol.
def cubic.flat(+p: Point, +a: Point, +b: Point, +q: Point, +tol: F32) -> Bool:
  +reach = (tol * 1.3333334 : F32)
  chord.near(p, q, a, reach) && chord.near(p, q, b, reach)

# Wang's bound: a cubic cut into n equal parameter steps stays within e of
# its chords when n >= sqrt(3/4 * L / e), L the larger second difference of
# the control points. The bound assumes the curvature all sits in one place,
# so the tolerance is doubled to land near the adaptive count; the count is
# fixed up front and each point costs one evaluation and no flatness test.
def cubic.count(+p: Point, +a: Point, +b: Point, +q: Point, +tol: F32) -> U32:
  +l = U.max(point.distance(point.add(p, b), point.scale(a, 2.0)), point.distance(point.add(a, q), point.scale(b, 2.0)))
  F32.to_u32(U.clamp(F32.ceil(F32.sqrt((0.375 * l / U.max(tol, 0.000001) : F32))), 1.0, 1024.0))

def cubic.at(+p: Point, +a: Point, +b: Point, +q: Point, +t: F32) -> Point:
  +u = (1.0 - t : F32)
  point.add(point.add(point.scale(p, (u * u * u : F32)), point.scale(a, (3.0 * u * u * t : F32))),
    point.add(point.scale(b, (3.0 * u * t * t : F32)), point.scale(q, (t * t * t : F32))))

@unsafe
def cubic.go(+n: Nat, +i: F32, +step: F32, +p: Point, +a: Point, +b: Point, +q: Point, +prev: Point, +edges: List<&2, Edge>) -> List<&2, Edge>:
  match n:
    case 0n: edges
    case 1n+d:
      +next = U.choose(Point, U32.is_zero(U32.from_nat(d)), q, cubic.at(p, a, b, q, (i * step : F32)))
      cubic.go(d, (i + 1.0 : F32), step, p, a, b, q, next, Con{edge.of(prev, next, True{}, False{}), edges})

def cubic(+p: Point, +a: Point, +b: Point, +q: Point, +edges: List<&2, Edge>, +tol: F32) -> List<&2, Edge>:
  +n = cubic.count(p, a, b, q, tol)
  cubic.go(U32.to_nat(n), 1.0, (1.0 / U32.to_f32(n) : F32), p, a, b, q, p, edges)

# What follows a command's numbers, scanned one step ahead: `kind` is 0 at
# the end of the data, 1 at a letter, 2 at a number repeating the pending
# command, 3 at anything else.
type PathNext is Data:
  PathNext{kind: U32, ch: U32, rest: String}

type Params is Data:
  Params{valid: Bool, values: List<&2, F32>, next: PathNext}

def path.letter(+ch: U32) -> Bool:
  (U32.is_ge(ch, 65) && U32.is_le(ch, 90)) || (U32.is_ge(ch, 97) && U32.is_le(ch, 122))

def path.next(s: String, +cmd: U32) -> PathNext:
  match s:
    case SNil{}: PathNext{0, 0, ""}
    case SCon{Chr{c}, t}:
      +cc = c
      PathNext{U.choose(U32, path.letter(cc), 1, U.choose(U32, U32.is_ne(cmd, 0), 2, 3)), cc, t}

def floats.rev(xs: List<&2, F32>, acc: List<&2, F32>) -> List<&2, F32>:
  match xs:
    case Nil{}: acc
    case Con{h, t}: floats.rev(t, Con{h, acc})

def arc.flag(+s: String) -> U.Number:
  match s:
    case SNil{}: U.Number{0.0, "", False{}}
    case SCon{Chr{c}, t}: U.Number{U.choose(F32, U32.is_eq(c, 49), 1.0, 0.0), t, U32.is_eq(c, 48) || U32.is_eq(c, 49)}

def args.number.pick(flag: Bool, s: String) -> U.Number:
  match flag:
    case True{}: arc.flag(U.separators(s))
    case False{}: U.number(s)

# The arguments are counted down; an arc's flags are the 4th and 3rd from its end.
def args.number(+n: Nat, s: String, +arc: Bool) -> U.Number:
  args.number.pick(arc && (U32.is_eq(U32.from_nat(n), 4) || U32.is_eq(U32.from_nat(n), 3)), s)

# The numbers of one command, gathered in a loop; `n` counts those still to
# read after `num`. An invalid number ends the whole parse.
@unsafe
def path.args(num: U.Number, +n: Nat, acc: List<&2, F32>, +arc: Bool, +cmd: U32) -> Params:
  match num:
    case U.Number{x, t, valid}:
      match valid:
        case False{}: Params{False{}, Nil{}, PathNext{0, 0, t}}
        case True{}:
          match n:
            case 0n: Params{True{}, floats.rev(Con{x, acc}, Nil{}), path.next(U.separators(t), cmd)}
            case 1n+d: path.args(args.number(1n+d, t, arc), d, Con{x, acc}, arc, cmd)

def path.arguments(+n: Nat, s: String, +arc: Bool, +cmd: U32) -> Params:
  match n:
    case 0n: Params{True{}, Nil{}, path.next(U.separators(s), cmd)}
    case 1n+d: path.args(args.number(1n+d, s, arc), d, Nil{}, arc, cmd)

# Preserve source segment endpoints and analytic tangents only when requested.
type MarkerSegment is Data:
  MarkerSegment{p: Point, q: Point, outgoing: Point, incoming: Point, kind: U32}

def marker.segment(trace: Maybe<&2, List<&2, MarkerSegment>>, segment: MarkerSegment) -> Maybe<&2, List<&2, MarkerSegment>>:
  match trace:
    case None{}: None{}
    case Some{segments}: Some{Con{segment, segments}}

def marker.nonzero(+v: Point) -> Bool:
  F32.is_gt(point.dot(v, v), 0.000000000001)

def marker.vector(+a: Point, b: Point) -> Point:
  U.choose(Point, marker.nonzero(a), a, b)

def marker.cubic(+p: Point, +a: Point, +b: Point, +q: Point) -> MarkerSegment:
  MarkerSegment{p, q, marker.vector(point.sub(a, p), marker.vector(point.sub(b, p), point.sub(q, p))),
    marker.vector(point.sub(q, b), marker.vector(point.sub(q, a), point.sub(q, p))), 0}

def marker.line(+p: Point, +q: Point, kind: U32) -> MarkerSegment:
  MarkerSegment{p, q, point.sub(q, p), point.sub(q, p), kind}

def marker.arc.tangent(+rx: F32, +ry: F32, +phi: F32, +theta: F32, +delta: F32) -> Point:
  +direction = U.choose(F32, F32.is_lt(delta, 0.0), F32.neg(1.0), 1.0)
  Point{((F32.neg(rx) * F32.cos(phi) * F32.sin(theta) - ry * F32.sin(phi) * F32.cos(theta)) * direction : F32),
    ((F32.neg(rx) * F32.sin(phi) * F32.sin(theta) + ry * F32.cos(phi) * F32.cos(theta)) * direction : F32)}

type Path is Data:
  Path{current: Point, start: Point, control: Point, command: U32, previous: U32, edges: List<&2, Edge>, trace: Maybe<&2, List<&2, MarkerSegment>>, tolerance: F32}

def upper(+c: U32) -> U32:
  U.choose(U32, U32.is_ge(c, 97) && U32.is_le(c, 122), (c - 32 : U32), c)

def relative(+cmd: U32, +current: Point, p: Point) -> Point:
  point.add(U.choose(Point, U32.is_ge(cmd, 97), current, Point{0.0, 0.0}), p)

def path.move(+p: Path, +q: Point, cmd: U32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  Path{q, q, q, U.choose(U32, U32.is_ge(cmd, 97), 108, 76), 77,
    U.choose(List<&2, Edge>, U32.is_eq(prev, 0), es, Con{edge.of(cur, start, False{}, False{}), es}), marker.segment(trace, marker.line(q, q, 1)), tol}

def path.line(+p: Path, +q: Point, +cmd: U32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  Path{q, start, q, cmd, upper(cmd), Con{edge.of(cur, q, True{}, False{}), es}, marker.segment(trace, marker.line(cur, q, 0)), tol}

def path.cubic(+p: Path, +a: Point, +b: Point, +q: Point, +cmd: U32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  +tt = tol
  Path{q, start, b, cmd, upper(cmd), cubic(cur, a, b, q, es, tt), marker.segment(trace, marker.cubic(cur, a, b, q)), tt}

def path.quad(+p: Path, +a: Point, +q: Point, +cmd: U32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  ca = point.add(cur, point.scale(point.sub(a, cur), 0.6666666666666666))
  cb = point.add(q, point.scale(point.sub(a, q), 0.6666666666666666))
  +tt = tol
  Path{q, start, a, cmd, upper(cmd), cubic(cur, ca, cb, q, es, tt), marker.segment(trace, marker.cubic(cur, a, a, q)), tt}

def path.close(+p: Path) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  Path{start, start, start, 0, 90, Con{edge.of(cur, start, True{}, True{}), es}, marker.segment(trace, marker.line(cur, start, 2)), tol}

def path.h(+cur: Point, +v: F32, cmd: U32) -> Point:
  Point{x, y} = cur
  Point{U.choose(F32, U32.is_ge(cmd, 97), (x + v : F32), v), y}

def path.v(+cur: Point, +v: F32, cmd: U32) -> Point:
  Point{x, y} = cur
  Point{x, U.choose(F32, U32.is_ge(cmd, 97), (y + v : F32), v)}

# Endpoint-to-center conversion from SVG's elliptical arc implementation notes.
def arc.point(+center: Point, +rx: F32, +ry: F32, +phi: F32, +t: F32) -> Point:
  point.add(center, Point{(rx * F32.cos(phi) * F32.cos(t) - ry * F32.sin(phi) * F32.sin(t) : F32),
    (rx * F32.sin(phi) * F32.cos(t) + ry * F32.cos(phi) * F32.sin(t) : F32)})

def arc.edges(+n: Nat, +i: F32, +step: F32, +theta: F32, +center: Point,
  +rx: F32, +ry: F32, +phi: F32, +endpoint: Point, p: Point, edges: List<&2, Edge>) -> List<&2, Edge>:
  match n:
    case 0n: edges
    case 1n+d:
      +q = U.choose(Point, U32.is_zero(U32.from_nat(d)), endpoint, arc.point(center, rx, ry, phi, (theta + i * step : F32)))
      arc.edges(d, (i + 1.0 : F32), step, theta, center, rx, ry, phi, endpoint, q, Con{edge.of(p, q, True{}, False{}), edges})

def arc.draw(+p: Path, +q: Point, +cmd: U32, +rx: F32, +ry: F32, +phi: F32,
  +center: Point, +theta: F32, +delta: F32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  # A chord of angle step on the larger radius stays within the tolerance:
  # step = 2 acos(1 - tol / r), approximated by 2 sqrt(2 tol / r).
  +tt = tol
  +step = U.max(0.001, (2.0 * F32.sqrt((2.0 * U.max(tt, 0.000001) / U.max(rx, ry) : F32)) : F32))
  +count = U.max(1.0, F32.ceil((F32.abs(delta) / step : F32)))
  Path{q, start, q, cmd, 65, arc.edges(U32.to_nat(F32.to_u32(U.min(4096.0, count))),
    1.0, (delta / U.min(4096.0, count) : F32), theta, center, rx, ry, phi, q, cur, es), marker.segment(trace, MarkerSegment{cur, q, marker.arc.tangent(rx, ry, phi, theta, delta), marker.arc.tangent(rx, ry, phi, (theta + delta : F32), delta), 0}), tt}

def arc.angles(+p: Path, +q: Point, +cmd: U32, +rx: F32, +ry: F32, +phi: F32,
  +xp: F32, +yp: F32, +cx: F32, +cy: F32, +center: Point, sweep: F32) -> Path:
  +ux = ((xp - cx) / rx : F32)
  +uy = ((yp - cy) / ry : F32)
  +vx = ((0.0 - xp - cx) / rx : F32)
  +vy = ((0.0 - yp - cy) / ry : F32)
  +delta = F32.atan2((ux * vy - uy * vx : F32), (ux * vx + uy * vy : F32))
  +sw = F32.is_gt(sweep, 0.0)
  arc.draw(p, q, cmd, rx, ry, phi, center, F32.atan2(uy, ux),
    U.choose(F32, sw && F32.is_lt(delta, 0.0), (delta + 6.283185307179586 : F32),
      U.choose(F32, Bool.not(sw) && F32.is_gt(delta, 0.0), (delta - 6.283185307179586 : F32), delta)))

def arc.center(+p: Path, +q: Point, +cmd: U32, +rx: F32, +ry: F32, +phi: F32,
  +xp: F32, +yp: F32, +coef: F32, sweep: F32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  +cx = (coef * rx * yp / ry : F32)
  +cy = (0.0 - coef * ry * xp / rx : F32)
  center = point.add(point.mid(cur, q), Point{(F32.cos(phi) * cx - F32.sin(phi) * cy : F32),
    (F32.sin(phi) * cx + F32.cos(phi) * cy : F32)})
  arc.angles(p, q, cmd, rx, ry, phi, xp, yp, cx, cy, center, sweep)

def arc.radii(+p: Path, +q: Point, +cmd: U32, +rx: F32, +ry: F32, +phi: F32,
  +xp: F32, +yp: F32, +large: F32, +sweep: F32) -> Path:
  +ratio = U.max(1.0, F32.sqrt((xp * xp / (rx * rx) + yp * yp / (ry * ry) : F32)))
  +r = (rx * ratio : F32)
  +s = (ry * ratio : F32)
  +den = (r * r * yp * yp + s * s * xp * xp : F32)
  +factor = F32.sqrt(U.max(0.0, ((r * r * s * s - den) / den : F32)))
  arc.center(p, q, cmd, r, s, phi, xp, yp,
    U.choose(F32, F32.is_eq(large, sweep), F32.neg(factor), factor), sweep)

def arc.prepare(+p: Path, +q: Point, cmd: U32, rx: F32, ry: F32, +phi: F32,
  large: F32, sweep: F32, delta: Point) -> Path:
  Point{x, y} = delta
  +dx = x
  +dy = y
  arc.radii(p, q, cmd, rx, ry, phi, (F32.cos(phi) * dx + F32.sin(phi) * dy : F32),
    (0.0 - F32.sin(phi) * dx + F32.cos(phi) * dy : F32), large, sweep)

def path.arc(+p: Path, +q: Point, +cmd: U32, +rx: F32, +ry: F32, phi: F32,
  large: F32, sweep: F32) -> Path:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  U.branch(Path, F32.is_lt(point.distance(cur, q), 0.000001), _ => Path{q, start, q, cmd, 65, es, trace, tol},
    _ => U.branch(Path, F32.is_eq(rx, 0.0) || F32.is_eq(ry, 0.0), _ => path.line(p, q, cmd),
      _ => arc.prepare(p, q, cmd, F32.abs(rx), F32.abs(ry), (phi * 0.017453292519943295 : F32),
        large, sweep, point.scale(point.sub(cur, q), 0.5))))

# The command's numbers are read by pattern, exactly as many as it takes;
# the parser has already counted them.
def path.cursor(p: Path) -> Point:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  cur

# The reflected control point of a smooth curve after a curve of the same
# kind (commands a or b), else the current point.
def path.smooth(p: Path, +a: U32, +b: U32) -> Point:
  Path{cur, start, ctrl, old, prev, es, trace, tol} = p
  +c = cur
  +pv = prev
  U.choose(Point, U32.is_eq(pv, a) || U32.is_eq(pv, b), point.sub(point.scale(c, 2.0), ctrl), c)

def path.apply(+p: Path, +cmd: U32, c: U32, vs: List<&2, F32>) -> Path:
  match c:
    case 77:
      match vs:
        case Con{x, Con{y, r}}:
          path.move(p, relative(cmd, path.cursor(p), Point{x, y}), cmd)
        case _: p
    case 76:
      match vs:
        case Con{x, Con{y, r}}:
          path.line(p, relative(cmd, path.cursor(p), Point{x, y}), cmd)
        case _: p
    case 72:
      match vs:
        case Con{x, r}:
          path.line(p, path.h(path.cursor(p), x, cmd), cmd)
        case _: p
    case 86:
      match vs:
        case Con{y, r}:
          path.line(p, path.v(path.cursor(p), y, cmd), cmd)
        case _: p
    case 67:
      match vs:
        case Con{x1, Con{y1, Con{x2, Con{y2, Con{x, Con{y, r}}}}}}:
          path.cubic(p, relative(cmd, path.cursor(p), Point{x1, y1}), relative(cmd, path.cursor(p), Point{x2, y2}), relative(cmd, path.cursor(p), Point{x, y}), cmd)
        case _: p
    case 83:
      match vs:
        case Con{x2, Con{y2, Con{x, Con{y, r}}}}:
          path.cubic(p, path.smooth(p, 67, 83), relative(cmd, path.cursor(p), Point{x2, y2}), relative(cmd, path.cursor(p), Point{x, y}), cmd)
        case _: p
    case 81:
      match vs:
        case Con{x1, Con{y1, Con{x, Con{y, r}}}}:
          path.quad(p, relative(cmd, path.cursor(p), Point{x1, y1}), relative(cmd, path.cursor(p), Point{x, y}), cmd)
        case _: p
    case 84:
      match vs:
        case Con{x, Con{y, r}}:
          path.quad(p, path.smooth(p, 81, 84), relative(cmd, path.cursor(p), Point{x, y}), cmd)
        case _: p
    case 65:
      match vs:
        case Con{rx, Con{ry, Con{rot, Con{large, Con{sweep, Con{x, Con{y, r}}}}}}}:
          path.arc(p, relative(cmd, path.cursor(p), Point{x, y}), cmd, rx, ry, rot, large, sweep)
        case _: p
    case _: p

def path.arity(+c: U32) -> Nat:
  U.choose(Nat, U32.is_eq(c, 90), 0n, U.choose(Nat, U32.is_eq(c, 72) || U32.is_eq(c, 86), 1n,
    U.choose(Nat, U32.is_eq(c, 67), 6n,
      U.choose(Nat, U32.is_eq(c, 83) || U32.is_eq(c, 81), 4n,
        U.choose(Nat, U32.is_eq(c, 65), 7n, 2n)))))

# A command applied to the path: 0 nothing (before the first command),
# 1 a close, 2 a drawing command with its numbers.
def path.step(kind: U32, p: Path, +cmd: U32, vs: List<&2, F32>) -> Path:
  match kind:
    case 0: p
    case 1: path.close(p)
    case _: path.apply(p, cmd, upper(cmd), vs)

# The command a bare number after `cmd` repeats: a move continues as a
# line, a close as nothing (the parse ends), any other command as itself.
def path.follow(+cmd: U32) -> U32:
  U.choose(U32, U32.is_eq(cmd, 77), 76, U.choose(U32, U32.is_eq(cmd, 109), 108, U.choose(U32, U32.is_eq(upper(cmd), 90), 0, cmd)))

def path.step.kind(+cmd: U32) -> U32:
  U.choose(U32, U32.is_eq(cmd, 0), 0, U.choose(U32, U32.is_eq(upper(cmd), 90), 1, 2))

# The commands in turn: each step applies the pending command with the
# numbers just read, then reads the next command's numbers. A non-letter
# repeats the pending command (SVG's implicit repetition); with none pending
# it ends the parse.
@unsafe
def path.run(ps: Params, +cmd: U32, p: Path) -> Path:
  match ps:
    case Params{valid, vs, nx}:
      match valid:
        case False{}: p
        case True{}:
          match nx:
            case PathNext{kind, ch, rest}:
              match kind:
                case 1:
                  +c2 = ch
                  path.run(path.arguments(path.arity(upper(c2)), rest, U32.is_eq(upper(c2), 65), path.follow(c2)), c2, path.step(path.step.kind(cmd), p, cmd, vs))
                case 2:
                  +pending = path.follow(cmd)
                  path.run(path.arguments(path.arity(upper(pending)), SCon{Chr{ch}, rest}, U32.is_eq(upper(pending), 65), path.follow(pending)), pending, path.step(path.step.kind(cmd), p, cmd, vs))
                case _: path.step(path.step.kind(cmd), p, cmd, vs)

def path.loop(s: String, p: Path) -> Path:
  path.run(path.arguments(0n, s, False{}, 0), 0, p)

def path.finish(+p: Path) -> List<&2, Edge>:
  Path{cur, start, ctrl, cmd, prev, es, trace, tol} = p
  U.choose(List<&2, Edge>, U32.is_eq(prev, 0), Nil{}, Con{edge.of(cur, start, False{}, False{}), es})

def path(s: String, +tol: F32) -> List<&2, Edge>:
  path.finish(path.loop(s, Path{Point{0.0, 0.0}, Point{0.0, 0.0}, Point{0.0, 0.0}, 0, 0, Nil{}, None{}, tol}))

# Geometry queries use half-open crossings, supporting both SVG fill rules.
def edge.cross(+edge: Edge, +p: Point) -> F32:
  Edge{x1, y1, x2, y2, stroked, closed} = edge
  Point{x, y} = p
  U.branch(F32, (F32.is_le(y1, y) && F32.is_gt(y2, y)) || (F32.is_le(y2, y) && F32.is_gt(y1, y)),
    _ => U.choose(F32, F32.is_gt((x1 + (y - y1) * (x2 - x1) / (y2 - y1) : F32), x),
      U.choose(F32, F32.is_gt(y2, y1), 1.0, F32.neg(1.0)), 0.0), _ => 0.0)

def winding(edges: List<&2, Edge>, +p: Point) -> F32:
  match edges:
    case Nil{}: 0.0
    case Con{h, t}: (edge.cross(h, p) + winding(t, p) : F32)

def fill.inside(edges: List<&2, Edge>, p: Point, even: Bool) -> Bool:
  +w = winding(edges, p)
  F32.is_gt(F32.abs(U.choose(F32, even, (w % 2.0 : F32), w)), 0.5)

def edge.distance(+e: Edge, +p: Point) -> F32:
  Edge{ax, ay, bx, by, stroked, closed} = e
  +a = {Point{ax, ay} : Point}
  +ab = point.sub(Point{bx, by}, a)
  +den = point.dot(ab, ab)
  +t = U.clamp((point.dot(point.sub(p, a), ab) / U.max(0.000000000001, den) : F32), 0.0, 1.0)
  U.choose(F32, stroked, point.distance(p, point.add(a, point.scale(ab, t))), 100000000000000000000.0)

def stroke.inside(edges: List<&2, Edge>, +p: Point, +radius: F32) -> Bool:
  match edges:
    case Nil{}: False{}
    case Con{h, t}:
      U.branch(Bool, F32.is_le(edge.distance(h, p), radius), _ => True{},
        _ => stroke.inside(t, p, radius))

type Bounds is Data:
  Bounds{x0: F32, y0: F32, x1: F32, y1: F32}

def bounds.point(+b: Bounds, +p: Point) -> Bounds:
  Bounds{x0, y0, x1, y1} = b
  Point{x, y} = p
  Bounds{U.min(x0, x), U.min(y0, y), U.max(x1, x), U.max(y1, y)}

def bounds.at(+b: Bounds, +x: F32, +y: F32) -> Bounds:
  Bounds{x0, y0, x1, y1} = b
  Bounds{U.min(x0, x), U.min(y0, y), U.max(x1, x), U.max(y1, y)}

def bounds(edges: List<&2, Edge>, box: Bounds) -> Bounds:
  match edges:
    case Nil{}: box
    case Con{Edge{ax, ay, bx, by, stroked, closed}, t}: bounds(t, bounds.at(bounds.at(box, ax, ay), bx, by))

def bounds.inside(b: Bounds, +p: Point, +margin: F32) -> Bool:
  Bounds{x0, y0, x1, y1} = b
  Point{x, y} = p
  F32.is_ge(x, (x0 - margin : F32)) && F32.is_ge(y, (y0 - margin : F32))
    && F32.is_le(x, (x1 + margin : F32)) && F32.is_le(y, (y1 + margin : F32))

def inflate(+data: Bin.Bytes, limit: U32) -> Bin.Inflate:
  Bin.inflate.blocks(Bin.BitStream{data, 0, (Bin.bytes.size(data) * 8 : U32), True{}}, Bin.bytes.empty(), limit)

def color.fade(c: Img.Color, +opacity: F32) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{(r * opacity : F32), (g * opacity : F32), (b * opacity : F32), (a * opacity : F32)}

def color.over(+front: Img.Color, back: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = front
  Img.Color{x, y, z, w} = back
  Img.Color{(r + x * (1.0 - a) : F32), (g + y * (1.0 - a) : F32),
    (b + z * (1.0 - a) : F32), (a + w * (1.0 - a) : F32)}

def color.add(c: Img.Color, d: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{x, y, z, w} = d
  Img.Color{(r + x : F32), (g + y : F32), (b + z : F32), (a + w : F32)}

def byte(+x: U32, n: U32) -> F32:
  (U32.to_f32(U32.mod(U32.div(x, n), 256)) / 255.0 : F32)

type Raster is Data:
  Raster{origin: Point, step: F32, width: U32, height: U32, depth: Nat, linear: Bool, pixels: Img.Pixels}

def color.rgb(+x: U32) -> Img.Color:
  Img.rgba(byte(x, 65536), byte(x, 256), byte(x, 1), 1.0)

def nibble(+x: U32, n: U32) -> F32:
  (U32.to_f32(U32.mod(U32.div(x, n), 16)) / 15.0 : F32)

def color.hex.short(+x: U32, len: U32) -> Img.Color:
  U.choose(Img.Color, U32.is_eq(len, 4), Img.rgba(nibble(x, 4096), nibble(x, 256), nibble(x, 16), nibble(x, 1)),
    Img.rgba(nibble(x, 256), nibble(x, 16), nibble(x, 1), 1.0))

def color.hex(+x: U32, +len: U32) -> Img.Color:
  U.branch(Img.Color, U32.is_eq(len, 3) || U32.is_eq(len, 4),
    _ => color.hex.short(x, len),
    _ => U.choose(Img.Color, U32.is_eq(len, 8), Img.rgba(byte(x, 16777216), byte(x, 65536), byte(x, 256), byte(x, 1)), color.rgb(x)))

def color.named.a(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "aliceblue"), _ => 15792383, _ => U.branch(U32, U.string.equal(s, "antiquewhite"), _ => 16444375, _ => U.branch(U32, U.string.equal(s, "aqua"), _ => 65535, _ => U.branch(U32, U.string.equal(s, "aquamarine"), _ => 8388564, _ => U.branch(U32, U.string.equal(s, "azure"), _ => 15794175, _ => 16777216)))))

def color.named.b(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "beige"), _ => 16119260, _ => U.branch(U32, U.string.equal(s, "bisque"), _ => 16770244, _ => U.branch(U32, U.string.equal(s, "black"), _ => 0, _ => U.branch(U32, U.string.equal(s, "blanchedalmond"), _ => 16772045, _ => U.branch(U32, U.string.equal(s, "blue"), _ => 255, _ => U.branch(U32, U.string.equal(s, "blueviolet"), _ => 9055202, _ => U.branch(U32, U.string.equal(s, "brown"), _ => 10824234, _ => U.branch(U32, U.string.equal(s, "burlywood"), _ => 14596231, _ => 16777216))))))))

def color.named.c(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "cadetblue"), _ => 6266528, _ => U.branch(U32, U.string.equal(s, "chartreuse"), _ => 8388352, _ => U.branch(U32, U.string.equal(s, "chocolate"), _ => 13789470, _ => U.branch(U32, U.string.equal(s, "coral"), _ => 16744272, _ => U.branch(U32, U.string.equal(s, "cornflowerblue"), _ => 6591981, _ => U.branch(U32, U.string.equal(s, "cornsilk"), _ => 16775388, _ => U.branch(U32, U.string.equal(s, "crimson"), _ => 14423100, _ => U.branch(U32, U.string.equal(s, "cyan"), _ => 65535, _ => 16777216))))))))

def color.named.d(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "darkblue"), _ => 139, _ => U.branch(U32, U.string.equal(s, "darkcyan"), _ => 35723, _ => U.branch(U32, U.string.equal(s, "darkgoldenrod"), _ => 12092939, _ => U.branch(U32, U.string.equal(s, "darkgray"), _ => 11119017, _ => U.branch(U32, U.string.equal(s, "darkgreen"), _ => 25600, _ => U.branch(U32, U.string.equal(s, "darkgrey"), _ => 11119017, _ => U.branch(U32, U.string.equal(s, "darkkhaki"), _ => 12433259, _ => U.branch(U32, U.string.equal(s, "darkmagenta"), _ => 9109643, _ => U.branch(U32, U.string.equal(s, "darkolivegreen"), _ => 5597999, _ => U.branch(U32, U.string.equal(s, "darkorange"), _ => 16747520, _ => U.branch(U32, U.string.equal(s, "darkorchid"), _ => 10040012, _ => U.branch(U32, U.string.equal(s, "darkred"), _ => 9109504, _ => U.branch(U32, U.string.equal(s, "darksalmon"), _ => 15308410, _ => U.branch(U32, U.string.equal(s, "darkseagreen"), _ => 9419919, _ => U.branch(U32, U.string.equal(s, "darkslateblue"), _ => 4734347, _ => U.branch(U32, U.string.equal(s, "darkslategray"), _ => 3100495, _ => U.branch(U32, U.string.equal(s, "darkslategrey"), _ => 3100495, _ => U.branch(U32, U.string.equal(s, "darkturquoise"), _ => 52945, _ => U.branch(U32, U.string.equal(s, "darkviolet"), _ => 9699539, _ => U.branch(U32, U.string.equal(s, "deeppink"), _ => 16716947, _ => U.branch(U32, U.string.equal(s, "deepskyblue"), _ => 49151, _ => U.branch(U32, U.string.equal(s, "dimgray"), _ => 6908265, _ => U.branch(U32, U.string.equal(s, "dimgrey"), _ => 6908265, _ => U.branch(U32, U.string.equal(s, "dodgerblue"), _ => 2003199, _ => 16777216))))))))))))))))))))))))

def color.named.f(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "firebrick"), _ => 11674146, _ => U.branch(U32, U.string.equal(s, "floralwhite"), _ => 16775920, _ => U.branch(U32, U.string.equal(s, "forestgreen"), _ => 2263842, _ => U.branch(U32, U.string.equal(s, "fuchsia"), _ => 16711935, _ => 16777216))))

def color.named.g(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "gainsboro"), _ => 14474460, _ => U.branch(U32, U.string.equal(s, "ghostwhite"), _ => 16316671, _ => U.branch(U32, U.string.equal(s, "gold"), _ => 16766720, _ => U.branch(U32, U.string.equal(s, "goldenrod"), _ => 14329120, _ => U.branch(U32, U.string.equal(s, "gray"), _ => 8421504, _ => U.branch(U32, U.string.equal(s, "green"), _ => 32768, _ => U.branch(U32, U.string.equal(s, "greenyellow"), _ => 11403055, _ => U.branch(U32, U.string.equal(s, "grey"), _ => 8421504, _ => 16777216))))))))

def color.named.h(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "honeydew"), _ => 15794160, _ => U.branch(U32, U.string.equal(s, "hotpink"), _ => 16738740, _ => 16777216))

def color.named.i(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "indianred"), _ => 13458524, _ => U.branch(U32, U.string.equal(s, "indigo"), _ => 4915330, _ => U.branch(U32, U.string.equal(s, "ivory"), _ => 16777200, _ => 16777216)))

def color.named.k(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "khaki"), _ => 15787660, _ => 16777216)

def color.named.l(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "lavender"), _ => 15132410, _ => U.branch(U32, U.string.equal(s, "lavenderblush"), _ => 16773365, _ => U.branch(U32, U.string.equal(s, "lawngreen"), _ => 8190976, _ => U.branch(U32, U.string.equal(s, "lemonchiffon"), _ => 16775885, _ => U.branch(U32, U.string.equal(s, "lightblue"), _ => 11393254, _ => U.branch(U32, U.string.equal(s, "lightcoral"), _ => 15761536, _ => U.branch(U32, U.string.equal(s, "lightcyan"), _ => 14745599, _ => U.branch(U32, U.string.equal(s, "lightgoldenrodyellow"), _ => 16448210, _ => U.branch(U32, U.string.equal(s, "lightgray"), _ => 13882323, _ => U.branch(U32, U.string.equal(s, "lightgreen"), _ => 9498256, _ => U.branch(U32, U.string.equal(s, "lightgrey"), _ => 13882323, _ => U.branch(U32, U.string.equal(s, "lightpink"), _ => 16758465, _ => U.branch(U32, U.string.equal(s, "lightsalmon"), _ => 16752762, _ => U.branch(U32, U.string.equal(s, "lightseagreen"), _ => 2142890, _ => U.branch(U32, U.string.equal(s, "lightskyblue"), _ => 8900346, _ => U.branch(U32, U.string.equal(s, "lightslategray"), _ => 7833753, _ => U.branch(U32, U.string.equal(s, "lightslategrey"), _ => 7833753, _ => U.branch(U32, U.string.equal(s, "lightsteelblue"), _ => 11584734, _ => U.branch(U32, U.string.equal(s, "lightyellow"), _ => 16777184, _ => U.branch(U32, U.string.equal(s, "lime"), _ => 65280, _ => U.branch(U32, U.string.equal(s, "limegreen"), _ => 3329330, _ => U.branch(U32, U.string.equal(s, "linen"), _ => 16445670, _ => 16777216))))))))))))))))))))))

def color.named.m(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "magenta"), _ => 16711935, _ => U.branch(U32, U.string.equal(s, "maroon"), _ => 8388608, _ => U.branch(U32, U.string.equal(s, "mediumaquamarine"), _ => 6737322, _ => U.branch(U32, U.string.equal(s, "mediumblue"), _ => 205, _ => U.branch(U32, U.string.equal(s, "mediumorchid"), _ => 12211667, _ => U.branch(U32, U.string.equal(s, "mediumpurple"), _ => 9662683, _ => U.branch(U32, U.string.equal(s, "mediumseagreen"), _ => 3978097, _ => U.branch(U32, U.string.equal(s, "mediumslateblue"), _ => 8087790, _ => U.branch(U32, U.string.equal(s, "mediumspringgreen"), _ => 64154, _ => U.branch(U32, U.string.equal(s, "mediumturquoise"), _ => 4772300, _ => U.branch(U32, U.string.equal(s, "mediumvioletred"), _ => 13047173, _ => U.branch(U32, U.string.equal(s, "midnightblue"), _ => 1644912, _ => U.branch(U32, U.string.equal(s, "mintcream"), _ => 16121850, _ => U.branch(U32, U.string.equal(s, "mistyrose"), _ => 16770273, _ => U.branch(U32, U.string.equal(s, "moccasin"), _ => 16770229, _ => 16777216)))))))))))))))

def color.named.n(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "navajowhite"), _ => 16768685, _ => U.branch(U32, U.string.equal(s, "navy"), _ => 128, _ => 16777216))

def color.named.o(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "oldlace"), _ => 16643558, _ => U.branch(U32, U.string.equal(s, "olive"), _ => 8421376, _ => U.branch(U32, U.string.equal(s, "olivedrab"), _ => 7048739, _ => U.branch(U32, U.string.equal(s, "orange"), _ => 16753920, _ => U.branch(U32, U.string.equal(s, "orangered"), _ => 16729344, _ => U.branch(U32, U.string.equal(s, "orchid"), _ => 14315734, _ => 16777216))))))

def color.named.p(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "palegoldenrod"), _ => 15657130, _ => U.branch(U32, U.string.equal(s, "palegreen"), _ => 10025880, _ => U.branch(U32, U.string.equal(s, "paleturquoise"), _ => 11529966, _ => U.branch(U32, U.string.equal(s, "palevioletred"), _ => 14381203, _ => U.branch(U32, U.string.equal(s, "papayawhip"), _ => 16773077, _ => U.branch(U32, U.string.equal(s, "peachpuff"), _ => 16767673, _ => U.branch(U32, U.string.equal(s, "peru"), _ => 13468991, _ => U.branch(U32, U.string.equal(s, "pink"), _ => 16761035, _ => U.branch(U32, U.string.equal(s, "plum"), _ => 14524637, _ => U.branch(U32, U.string.equal(s, "powderblue"), _ => 11591910, _ => U.branch(U32, U.string.equal(s, "purple"), _ => 8388736, _ => 16777216)))))))))))

def color.named.r(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "rebeccapurple"), _ => 6697881, _ => U.branch(U32, U.string.equal(s, "red"), _ => 16711680, _ => U.branch(U32, U.string.equal(s, "rosybrown"), _ => 12357519, _ => U.branch(U32, U.string.equal(s, "royalblue"), _ => 4286945, _ => 16777216))))

def color.named.s(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "saddlebrown"), _ => 9127187, _ => U.branch(U32, U.string.equal(s, "salmon"), _ => 16416882, _ => U.branch(U32, U.string.equal(s, "sandybrown"), _ => 16032864, _ => U.branch(U32, U.string.equal(s, "seagreen"), _ => 3050327, _ => U.branch(U32, U.string.equal(s, "seashell"), _ => 16774638, _ => U.branch(U32, U.string.equal(s, "sienna"), _ => 10506797, _ => U.branch(U32, U.string.equal(s, "silver"), _ => 12632256, _ => U.branch(U32, U.string.equal(s, "skyblue"), _ => 8900331, _ => U.branch(U32, U.string.equal(s, "slateblue"), _ => 6970061, _ => U.branch(U32, U.string.equal(s, "slategray"), _ => 7372944, _ => U.branch(U32, U.string.equal(s, "slategrey"), _ => 7372944, _ => U.branch(U32, U.string.equal(s, "snow"), _ => 16775930, _ => U.branch(U32, U.string.equal(s, "springgreen"), _ => 65407, _ => U.branch(U32, U.string.equal(s, "steelblue"), _ => 4620980, _ => 16777216))))))))))))))

def color.named.t(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "tan"), _ => 13808780, _ => U.branch(U32, U.string.equal(s, "teal"), _ => 32896, _ => U.branch(U32, U.string.equal(s, "thistle"), _ => 14204888, _ => U.branch(U32, U.string.equal(s, "tomato"), _ => 16737095, _ => U.branch(U32, U.string.equal(s, "turquoise"), _ => 4251856, _ => 16777216)))))

def color.named.v(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "violet"), _ => 15631086, _ => 16777216)

def color.named.w(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "wheat"), _ => 16113331, _ => U.branch(U32, U.string.equal(s, "white"), _ => 16777215, _ => U.branch(U32, U.string.equal(s, "whitesmoke"), _ => 16119285, _ => 16777216)))

def color.named.y(+s: String) -> U32:
  U.branch(U32, U.string.equal(s, "yellow"), _ => 16776960, _ => U.branch(U32, U.string.equal(s, "yellowgreen"), _ => 10145074, _ => 16777216))

def color.named.code(+s: String) -> U32:
  U.branch(U32, U.prefix(s, "a"), _ => color.named.a(s), _ => U.branch(U32, U.prefix(s, "b"), _ => color.named.b(s), _ => U.branch(U32, U.prefix(s, "c"), _ => color.named.c(s), _ => U.branch(U32, U.prefix(s, "d"), _ => color.named.d(s), _ => U.branch(U32, U.prefix(s, "f"), _ => color.named.f(s), _ => U.branch(U32, U.prefix(s, "g"), _ => color.named.g(s), _ => U.branch(U32, U.prefix(s, "h"), _ => color.named.h(s), _ => U.branch(U32, U.prefix(s, "i"), _ => color.named.i(s), _ => U.branch(U32, U.prefix(s, "k"), _ => color.named.k(s), _ => U.branch(U32, U.prefix(s, "l"), _ => color.named.l(s), _ => U.branch(U32, U.prefix(s, "m"), _ => color.named.m(s), _ => U.branch(U32, U.prefix(s, "n"), _ => color.named.n(s), _ => U.branch(U32, U.prefix(s, "o"), _ => color.named.o(s), _ => U.branch(U32, U.prefix(s, "p"), _ => color.named.p(s), _ => U.branch(U32, U.prefix(s, "r"), _ => color.named.r(s), _ => U.branch(U32, U.prefix(s, "s"), _ => color.named.s(s), _ => U.branch(U32, U.prefix(s, "t"), _ => color.named.t(s), _ => U.branch(U32, U.prefix(s, "v"), _ => color.named.v(s), _ => U.branch(U32, U.prefix(s, "w"), _ => color.named.w(s), _ => U.branch(U32, U.prefix(s, "y"), _ => color.named.y(s), _ => 16777216))))))))))))))))))))

def color.named(s: String) -> Img.Color:
  +code = color.named.code(s)
  color.rgb(U.choose(U32, U32.is_lt(code, 16777216), code, 0))

# Img.Color arguments retain separators and units; unlike SVG coordinates, these
# functions do not permit adjacent numbers or mixed comma/slash syntax.
type ColorToken is Data:
  ColorToken{value: F32, kind: U32, separator: U32}

def color.word(+s: String, +acc: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{U.rev(acc, ""), ""}
    case SCon{Chr{c}, tail}:
      U.branch(U.Scan, U.space(c) || U32.is_eq(c, 44) || U32.is_eq(c, 47) || U32.is_eq(c, 41),
        _ => U.Scan{U.rev(acc, ""), s}, _ => color.word(tail, SCon{Chr{c}, acc}))

def color.token.number(num: U.Number, sep: U32) -> ColorToken:
  U.Number{x, unitName, ok} = num
  +u = unitName
  ColorToken{x, U.choose(U32, Bool.not(ok), 7, U.choose(U32, U.string.equal(u, ""), 0, U.choose(U32, U.string.equal(u, "%"), 1,
    U.choose(U32, U.string.equal(u, "deg"), 2, U.choose(U32, U.string.equal(u, "rad"), 3, U.choose(U32, U.string.equal(u, "grad"), 4,
      U.choose(U32, U.string.equal(u, "turn"), 5, 7))))))), sep}

def color.token(+word: String, +sep: U32) -> ColorToken:
  U.branch(ColorToken, U.string.equal(word, "none"), _ => ColorToken{0.0, 6, sep}, _ => color.token.number(U.number(word), sep))

def color.tokens.word(+scan: U.Scan, next: String -> List<&2, ColorToken>) -> List<&2, ColorToken>:
  U.Scan{word, rest} = scan
  +s = U.trim(rest)
  +token = word
  +comma = U.prefix(s, ",")
  +slash = U.prefix(s, "/")
  +end = U.prefix(s, ")") && U.string.equal(U.trim(U.drop(s, ")")), "")
  +spaced = Bool.not(U.string.equal(rest, s))
  +sep = U.choose(U32, end, 0, U.choose(U32, comma, 2, U.choose(U32, slash, 3, U.choose(U32, spaced, 1, 9))))
  +tail = U.choose(String, comma, U.drop(s, ","), U.choose(String, slash, U.drop(s, "/"), s))
  Con{color.token(token, sep), U.choose(Unit -> List<&2, ColorToken>, end || U32.is_eq(sep, 9), _ => Nil{}, _ => next(tail))(Unit{})}

def color.tokens(fuel: Nat, s: String) -> List<&2, ColorToken>:
  match fuel:
    case 0n: Con{ColorToken{0.0, 7, 9}, Nil{}}
    case 1n+n: color.tokens.word(color.word(U.trim(s), ""), rest => color.tokens(n, rest))

def color.component(+kind: U32) -> Bool:
  U32.is_eq(kind, 0) || U32.is_eq(kind, 1) || U32.is_eq(kind, 6)

def color.hue(+x: F32, +kind: U32) -> F32:
  +degrees = U.choose(F32, U32.is_eq(kind, 3), (x * 57.29577951308232 : F32), U.choose(F32, U32.is_eq(kind, 4), (x * 0.9 : F32), U.choose(F32, U32.is_eq(kind, 5), (x * 360.0 : F32), x)))
  (degrees - 360.0 * F32.floor((degrees / 360.0 : F32)) : F32)

def color.hsl.channel(+h: F32, +s: F32, +l: F32, n: F32) -> F32:
  +turn = (n + h / 30.0 : F32)
  +k = (turn - 12.0 * F32.floor((turn / 12.0 : F32)) : F32)
  (l - s * U.min(l, (1.0 - l : F32)) * U.max(F32.neg(1.0), U.min(U.min((k - 3.0 : F32), (9.0 - k : F32)), 1.0)) : F32)

def color.hsl(+h: F32, +s: F32, +l: F32, a: F32) -> Img.Color:
  +sat = U.clamp(s, 0.0, 1.0)
  +light = U.clamp(l, 0.0, 1.0)
  Img.rgba(color.hsl.channel(h, sat, light, 0.0), color.hsl.channel(h, sat, light, 8.0), color.hsl.channel(h, sat, light, 4.0), a)

def color.hwb.mix(c: Img.Color, +white: F32, +black: F32, alpha: F32) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +remaining = (1.0 - white - black : F32)
  Img.rgba((r * remaining + white : F32), (g * remaining + white : F32), (b * remaining + white : F32), alpha)

def color.hwb(h: F32, +w: F32, +b: F32, +a: F32) -> Img.Color:
  +white = U.clamp(w, 0.0, 1.0)
  +black = U.clamp(b, 0.0, 1.0)
  +sum = (white + black : F32)
  +gray = (white / U.max(sum, 0.000001) : F32)
  U.branch(Img.Color, F32.is_ge(sum, 1.0), _ => Img.rgba(gray, gray, gray, a), _ => color.hwb.mix(color.hsl(h, 1.0, 0.5, 1.0), white, black, a))

def color.function.channels(+r: ColorToken, +g: ColorToken, +b: ColorToken, +a: ColorToken, +mode: U32, +alpha: Bool) -> Img.Color:
  ColorToken{rr, kr, sr} = r
  ColorToken{gg, kg, sg} = g
  ColorToken{bb, kb, sb} = b
  ColorToken{aa, ka, sa} = a
  +legacy = U32.is_eq(sr, 2) && U32.is_eq(sg, 2) && U32.is_eq(sb, U.choose(U32, alpha, 2, 0)) && U32.is_eq(sa, 0)
  +modern = U32.is_eq(sr, 1) && U32.is_eq(sg, 1) && U32.is_eq(sb, U.choose(U32, alpha, 3, 0)) && U32.is_eq(sa, 0)
  +rgb = U32.is_eq(mode, 0)
  +hue = U32.is_lt(kr, 7) && Bool.not(U32.is_eq(kr, 1))
  +kinds = color.component(kg) && color.component(kb) && color.component(ka) && U.choose(Bool, rgb, color.component(kr), hue)
  +oldKinds = U32.is_lt(ka, 6) && U.choose(Bool, rgb, U32.is_lt(kr, 2) && U32.is_eq(kr, kg) && U32.is_eq(kr, kb), U32.is_lt(kr, 6) && U32.is_eq(kg, 1) && U32.is_eq(kb, 1))
  +valid = kinds && (modern || (legacy && oldKinds && Bool.not(U32.is_eq(mode, 2))))
  +opacity = U.clamp(U.choose(F32, U32.is_eq(ka, 1), (aa / 100.0 : F32), aa), 0.0, 1.0)
  U.branch(Img.Color, valid,
    _ => U.branch(Img.Color, rgb, _ => Img.rgba(U.clamp((rr / U.choose(F32, U32.is_eq(kr, 1), 100.0, 255.0) : F32), 0.0, 1.0),
      U.clamp((gg / U.choose(F32, U32.is_eq(kg, 1), 100.0, 255.0) : F32), 0.0, 1.0), U.clamp((bb / U.choose(F32, U32.is_eq(kb, 1), 100.0, 255.0) : F32), 0.0, 1.0), opacity),
      _ => U.branch(Img.Color, U32.is_eq(mode, 1), _ => color.hsl(color.hue(rr, kr), (gg / 100.0 : F32), (bb / 100.0 : F32), opacity),
        _ => color.hwb(color.hue(rr, kr), (gg / 100.0 : F32), (bb / 100.0 : F32), opacity))), _ => color.rgb(0))

def color.function.args(xs: List<&2, ColorToken>, mode: U32) -> Img.Color:
  match xs:
    case Con{r, Con{g, Con{b, Nil{}}}}: color.function.channels(r, g, b, ColorToken{1.0, 0, 0}, mode, False{})
    case Con{r, Con{g, Con{b, Con{a, Nil{}}}}}: color.function.channels(r, g, b, a, mode, True{})
    case _: color.rgb(0)

def color.hex.valid(s: String) -> Bool:
  match s:
    case SNil{}: True{}
    case SCon{Chr{c}, rest}:
      +ch = c
      (U.digit(ch) || (U32.is_ge(ch, 97) && U32.is_le(ch, 102))) && color.hex.valid(rest)

def color.hex.string(+s: String) -> Img.Color:
  +n = length(s)
  U.branch(Img.Color, (U32.is_eq(n, 3) || U32.is_eq(n, 4) || U32.is_eq(n, 6) || U32.is_eq(n, 8)) && color.hex.valid(s),
    _ => color.hex(U.hex(s, 0), n), _ => color.rgb(0))

def color.parse(+s: String) -> Img.Color:
  U.branch(Img.Color, U.prefix(s, "#"), _ => color.hex.string(U.drop(s, "#")),
    _ => U.branch(Img.Color, U.prefix(s, "rgb(") || U.prefix(s, "rgba("), _ => color.function.args(color.tokens(4n, U.drop(s, U.choose(String, U.prefix(s, "rgba("), "rgba(", "rgb("))), 0),
    _ => U.branch(Img.Color, U.prefix(s, "hsl(") || U.prefix(s, "hsla("), _ => color.function.args(color.tokens(4n, U.drop(s, U.choose(String, U.prefix(s, "hsla("), "hsla(", "hsl("))), 1),
    _ => U.branch(Img.Color, U.prefix(s, "hwb("), _ => color.function.args(color.tokens(4n, U.drop(s, "hwb(")), 2),
    _ => U.branch(Img.Color, U.string.equal(s, "none") || U.string.equal(s, "transparent"), _ => Img.clear(), _ => color.named(s))))))

# Hex digits after a '#', read in one pass: the value and count when the
# rest is only whitespace, else a count of 0 so the general parser decides.
def color.hex.digit(+ch: U32) -> Bool:
  U.digit(ch) || (U32.is_ge(U32.or(ch, 32), 97) && U32.is_le(U32.or(ch, 32), 102))

# One character at a time, decided one step ahead: `hexed` says whether `ch`
# is a hex digit; the rest is scanned only while digits continue.
@unsafe
def color.hex.scan(hexed: Bool, +ch: U32, t: String, +acc: U32, +n: U32) -> U32 & U32:
  match hexed:
    case True{}:
      match t:
        case SNil{}: ((acc * 16 + U.hex.digit(ch) : U32), (n + 1 : U32))
        case SCon{Chr{c}, t2}:
          +c2 = c
          color.hex.scan(color.hex.digit(c2), c2, t2, (acc * 16 + U.hex.digit(ch) : U32), (n + 1 : U32))
    case False{}: U.choose(U32 & U32, U.space(ch) && U.string.equal(U.trim(t), ""), (acc, n), (0, 0))

def color.hex.start(rest: String) -> U32 & U32:
  match rest:
    case SNil{}: (0, 0)
    case SCon{Chr{c}, t}:
      +c2 = c
      color.hex.scan(color.hex.digit(c2), c2, t, 0, 0)

def color.hex.fast(scanned: U32 & U32, s: String) -> Img.Color:
  (x, n) = scanned
  +len = n
  U.branch(Img.Color, U32.is_eq(len, 3) || U32.is_eq(len, 4) || U32.is_eq(len, 6) || U32.is_eq(len, 8),
    _ => color.hex(x, len), _ => color.parse(CSS.css.lower(U.trim.both(s))))

def color.head(+s: String) -> Img.Color:
  match s:
    case SNil{}: color.parse("")
    case SCon{Chr{c}, t}:
      +ch = c
      +rest = t
      U.branch(Img.Color, U32.is_eq(ch, 35), _ => color.hex.fast(color.hex.start(rest), s),
        _ => color.parse(CSS.css.lower(U.trim.both(s))))

def color(s: String) -> Img.Color:
  color.head(U.trim(s))

def color.opacity.number(num: U.Number, fallback: F32) -> F32:
  U.Number{x, tail, ok} = num
  +u = U.trim.both(tail)
  U.clamp(U.choose(F32, ok && (U.string.equal(u, "") || U.string.equal(u, "%")), (x / U.choose(F32, U.string.equal(u, "%"), 100.0, 1.0) : F32), fallback), 0.0, 1.0)

def color.opacity(s: String, fallback: F32) -> F32:
  color.opacity.number(U.number(s), fallback)

def dimension(attrs: List<&2, XML.Attr>, key: String, ref: F32, fallback: String) -> F32:
  U.unit(U.number(XML.attr.get(attrs, key, fallback)), ref)

def xy(x: F32, y: F32) -> String:
  F32.show(x) ++ "," ++ F32.show(y) ++ " "

def shape.rect.path(+x: F32, +y: F32, +w: F32, +h: F32, +rx: F32, +ry: F32) -> String:
  +a = xy(rx, ry) ++ "0 0 1 "
  "M" ++ xy((x + rx : F32), y) ++ "H" ++ F32.show((x + w - rx : F32))
    ++ "A" ++ a ++ xy((x + w : F32), (y + ry : F32)) ++ "V" ++ F32.show((y + h - ry : F32))
    ++ "A" ++ a ++ xy((x + w - rx : F32), (y + h : F32)) ++ "H" ++ F32.show((x + rx : F32))
    ++ "A" ++ a ++ xy(x, (y + h - ry : F32)) ++ "V" ++ F32.show((y + ry : F32))
    ++ "A" ++ a ++ xy((x + rx : F32), y) ++ "Z"

def shape.rect(+as: List<&2, XML.Attr>, +vw: F32, +vh: F32) -> String:
  +w = dimension(as, "width", vw, "0")
  +h = dimension(as, "height", vh, "0")
  +rx = U.min((w / 2.0 : F32), U.max(0.0, dimension(as, "rx", vw, XML.attr.get(as, "ry", "0"))))
  +ry = U.min((h / 2.0 : F32), U.max(0.0, dimension(as, "ry", vh, XML.attr.get(as, "rx", "0"))))
  U.branch(String, F32.is_gt(w, 0.0) && F32.is_gt(h, 0.0),
    _ => shape.rect.path(dimension(as, "x", vw, "0"), dimension(as, "y", vh, "0"), w, h, rx, ry), _ => "")

def shape.ellipse.path(+x: F32, +y: F32, +rx: F32, +ry: F32) -> String:
  U.branch(String, F32.is_gt(rx, 0.0) && F32.is_gt(ry, 0.0),
    _ => "M" ++ xy((x + rx : F32), y) ++ "A" ++ xy(rx, ry) ++ "0 1 1 " ++ xy((x - rx : F32), y)
      ++ "A" ++ xy(rx, ry) ++ "0 1 1 " ++ xy((x + rx : F32), y) ++ "Z", _ => "")

def edges.transform(es: List<&2, Edge>, +m: Matrix) -> List<&2, Edge>:
  match es:
    case Nil{}: Nil{}
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}:
      Con{edge.of(matrix.point(m, Point{ax, ay}), matrix.point(m, Point{bx, by}), stroked, closed), edges.transform(rest, m)}

# The path data of a shape; a path's own `d` arrives separately (taken out
# of its attributes) so the parser owns that text outright.
def shape.data(+name: String, +as: List<&2, XML.Attr>, +vw: F32, +vh: F32, data: String) -> String:
  U.branch(String, U.string.equal(name, "path"), _ => data,
    _ => U.branch(String, U.string.equal(name, "rect") || U.string.equal(name, "image") || U.string.equal(name, "#svg-image"), _ => shape.rect(as, vw, vh),
      _ => U.branch(String, U.string.equal(name, "circle"),
        _ => shape.ellipse.path(dimension(as, "cx", vw, "0"), dimension(as, "cy", vh, "0"),
          dimension(as, "r", F32.sqrt(((vw * vw + vh * vh) / 2.0 : F32)), "0"),
          dimension(as, "r", F32.sqrt(((vw * vw + vh * vh) / 2.0 : F32)), "0")),
        _ => U.branch(String, U.string.equal(name, "ellipse"),
          _ => shape.ellipse.path(dimension(as, "cx", vw, "0"), dimension(as, "cy", vh, "0"),
            dimension(as, "rx", vw, "0"), dimension(as, "ry", vh, "0")),
          _ => U.branch(String, U.string.equal(name, "line"),
            _ => "M" ++ xy(dimension(as, "x1", vw, "0"), dimension(as, "y1", vh, "0"))
              ++ "L" ++ xy(dimension(as, "x2", vw, "0"), dimension(as, "y2", vh, "0")),
            _ => U.branch(String, U.string.equal(name, "polygon") || U.string.equal(name, "polyline"),
              _ => "M" ++ XML.attr.get(as, "points", "") ++ U.choose(String, U.string.equal(name, "polygon"), "Z", ""),
              _ => ""))))))

def glyph.path(+d: String, +gm: Matrix, +tol: F32) -> List<&2, Edge>:
  edges.transform(path(d, (tol / matrix.norm(gm) : F32)), gm)

def shape.of(glyph: Bool, data: String, +name: String, +as: List<&2, XML.Attr>, +vw: F32, +vh: F32, +tol: F32) -> List<&2, Edge>:
  match glyph:
    case True{}: glyph.path(data, transform(XML.attr.get(as, "#glyph-transform", ""), identity()), tol)
    case False{}: path(shape.data(name, as, vw, vh, data), tol)

def shape(+name: String, +as: List<&2, XML.Attr>, +vw: F32, +vh: F32, +tol: F32, data: String) -> List<&2, Edge>:
  shape.of(U.string.equal(name, "#glyph"), data, name, as, vw, vh, tol)

# Paint adjacent glyphs with one shared style as one geometry. This keeps all
# fills together and all strokes together, including overlapping glyphs.
def glyph.edges.append(xs: List<&2, Edge>, ys: List<&2, Edge>) -> List<&2, Edge>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, glyph.edges.append(t, ys)}

def glyph.edges(xs: List<&2, XML.Element>, +tol: F32) -> List<&2, Edge>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +attrs = as
      glyph.edges.append(glyph.path(XML.attr.get(attrs, "d", ""), transform(XML.attr.get(attrs, "#glyph-transform", ""), identity()), tol), glyph.edges(rest, tol))

# The element's edges in local units, flattened for the local-to-device matrix m.
def shape.children(+name: String, as: List<&2, XML.Attr>, kids: List<&2, XML.Element>, vw: F32, vh: F32, +tol: F32, data: String) -> List<&2, Edge>:
  U.branch(List<&2, Edge>, U.string.equal(name, "#glyph-run"), _ => glyph.edges(kids, tol), _ => shape(name, as, vw, vh, tol, data))

type MarkerSubpath is Data:
  MarkerSubpath{start: Point, segments: List<&2, MarkerSegment>, closed: Bool}

def marker.segments.reverse(xs: List<&2, MarkerSegment>, acc: List<&2, MarkerSegment>) -> List<&2, MarkerSegment>:
  match xs:
    case Nil{}: acc
    case Con{h, t}: marker.segments.reverse(t, Con{h, acc})

def marker.subpaths.reverse(xs: List<&2, MarkerSubpath>, acc: List<&2, MarkerSubpath>) -> List<&2, MarkerSubpath>:
  match xs:
    case Nil{}: acc
    case Con{h, t}: marker.subpaths.reverse(t, Con{h, acc})

def marker.subpaths(+xs: List<&2, MarkerSegment>, +start: Point, +acc: List<&2, MarkerSegment>, +have: Bool, +done: List<&2, MarkerSubpath>) -> List<&2, MarkerSubpath>:
  match xs:
    case Nil{}: marker.subpaths.reverse(U.choose(List<&2, MarkerSubpath>, have, Con{MarkerSubpath{start, marker.segments.reverse(acc, Nil{}), False{}}, done}, done), Nil{})
    case Con{segment, rest}:
      MarkerSegment{p, q, outgoing, incoming, kind} = segment
      +seg = {MarkerSegment{p, q, outgoing, incoming, kind} : MarkerSegment}
      U.branch(List<&2, MarkerSubpath>, U32.is_eq(kind, 1),
        _ => marker.subpaths(rest, q, Nil{}, True{}, U.choose(List<&2, MarkerSubpath>, have, Con{MarkerSubpath{start, marker.segments.reverse(acc, Nil{}), False{}}, done}, done)),
        _ => U.branch(List<&2, MarkerSubpath>, U32.is_eq(kind, 2),
          _ => marker.subpaths(rest, q, Nil{}, False{}, Con{MarkerSubpath{U.choose(Point, have, start, p), marker.segments.reverse(Con{seg, acc}, Nil{}), True{}}, done}),
          _ => marker.subpaths(rest, U.choose(Point, have, start, p), Con{seg, acc}, True{}, done)))

def marker.first(xs: List<&2, MarkerSegment>, fallback: Point) -> Point:
  match xs:
    case Nil{}: fallback
    case Con{MarkerSegment{p, q, outgoing, incoming, kind}, rest}:
      +v = outgoing
      U.branch(Point, marker.nonzero(v), _ => v, _ => marker.first(rest, fallback))

def marker.last(xs: List<&2, MarkerSegment>, fallback: Point) -> Point:
  match xs:
    case Nil{}: fallback
    case Con{MarkerSegment{p, q, outgoing, incoming, kind}, rest}:
      marker.last(rest, marker.vector(incoming, fallback))

def marker.angle.vector(v: Point) -> F32:
  Point{x, y} = v
  (F32.atan2(y, x) * 57.29577951308232 : F32)

def marker.angle.mean(+a: F32, +b: F32) -> F32:
  +wrap = F32.is_gt(F32.abs((a - b : F32)), 180.0)
  ((a + U.choose(F32, wrap && F32.is_lt(a, b), 360.0, 0.0) + b + U.choose(F32, wrap && F32.is_lt(b, a), 360.0, 0.0)) / 2.0 : F32)

def marker.direction(+incoming: Point, +outgoing: Point) -> F32:
  marker.angle.mean(marker.angle.vector(marker.vector(incoming, outgoing)), marker.angle.vector(marker.vector(outgoing, incoming)))

type MarkerVertex is Data:
  MarkerVertex{point: Point, angle: F32}

@unsafe
def marker.vertices.tail(xs: List<&2, MarkerSegment>, previous: Point, +first: Point, +endAngle: F32) -> List<&2, MarkerVertex>:
  match xs:
    case Nil{}: Nil{}
    case Con{MarkerSegment{p, q, outgoing, incoming, kind}, Nil{}}: Con{MarkerVertex{q, endAngle}, Nil{}}
    case Con{MarkerSegment{p, q, outgoing, incoming, kind}, Con{head, tail}}:
      +before = marker.vector(incoming, previous)
      +remaining = {Con{head, tail} : List<&2, MarkerSegment>}
      Con{MarkerVertex{q, marker.direction(before, marker.first(remaining, first))}, marker.vertices.tail(remaining, before, first, endAngle)}

def marker.vertices.one(+subpath: MarkerSubpath) -> List<&2, MarkerVertex>:
  MarkerSubpath{start, segments, closed} = subpath
  +zero = {Point{0.0, 0.0} : Point}
  +outgoing = marker.first(segments, zero)
  +incoming = marker.last(segments, zero)
  +joined = marker.direction(incoming, outgoing)
  +startAngle = U.choose(F32, closed, joined, marker.angle.vector(outgoing))
  +endAngle = U.choose(F32, closed, joined, marker.angle.vector(incoming))
  Con{MarkerVertex{start, startAngle}, marker.vertices.tail(segments, U.choose(Point, closed, incoming, zero), U.choose(Point, closed, outgoing, zero), endAngle)}

def marker.vertices.append(xs: List<&2, MarkerVertex>, ys: List<&2, MarkerVertex>) -> List<&2, MarkerVertex>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, marker.vertices.append(t, ys)}

def marker.vertices(xs: List<&2, MarkerSubpath>) -> List<&2, MarkerVertex>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, t}: marker.vertices.append(marker.vertices.one(h), marker.vertices(t))

def marker.trace.result(trace: Maybe<&2, List<&2, MarkerSegment>>) -> List<&2, MarkerVertex>:
  match trace:
    case None{}: Nil{}
    case Some{segments}: marker.vertices(marker.subpaths(marker.segments.reverse(segments, Nil{}), Point{0.0, 0.0}, Nil{}, False{}, Nil{}))

def marker.trace.path(p: Path) -> List<&2, MarkerVertex>:
  Path{cur, start, ctrl, cmd, prev, es, trace, tol} = p
  marker.trace.result(trace)

def marker.trace(s: String) -> List<&2, MarkerVertex>:
  marker.trace.path(path.loop(s, Path{Point{0.0, 0.0}, Point{0.0, 0.0}, Point{0.0, 0.0}, 0, 0, Nil{}, Some{Nil{}}, 1.0}))

# Stroke geometry is compiled once. Overlapping parts form a union, so alpha
# is applied once even at joins, caps and self intersections.
type StrokeSettings is Data:
  StrokeSettings{cap: String, join: String, limit: F32, dash: String, offset: String, vector: String}

def stroke.settings() -> StrokeSettings:
  StrokeSettings{"butt", "miter", 4.0, "none", "0", "none"}

# A property from an element's attributes: absent means the inherited value
# (or the initial one for non-inherited properties) with no string work at
# all; present, the CSS-wide keywords are honoured.
# The CSS-wide keywords of a value: 1 inherit, 2 initial, 3 unset, 0 none.
# Decided from the first letter on, case-insensitively, with blanks around
# allowed, without lowercasing or trimming a copy of every value.
def keyword.blank(s: String) -> Bool:
  match s:
    case SNil{}: True{}
    case SCon{Chr{c}, t}: U.space(c) && keyword.blank(t)

def keyword.rest(p: String, s: String) -> Bool:
  match p:
    case SNil{}: keyword.blank(s)
    case SCon{Chr{pc}, pt}:
      match s:
        case SNil{}: False{}
        case SCon{Chr{c}, t}: U32.is_eq(U32.or(c, 32), pc) && keyword.rest(pt, t)

def keyword.pick(+s: String) -> U32:
  U.choose(U32, keyword.rest("inherit", s), 1, U.choose(U32, keyword.rest("initial", s), 2, U.choose(U32, keyword.rest("unset", s), 3, 0)))

def keyword.head(s: String) -> U32:
  match s:
    case SNil{}: 0
    case SCon{Chr{c}, t}:
      +ch = c
      U.choose(U32, U32.is_eq(U32.or(ch, 32), 105) || U32.is_eq(U32.or(ch, 32), 117), keyword.pick(SCon{Chr{ch}, t}), 0)

def style.keyword(s: String) -> U32:
  keyword.head(U.trim(s))

def style.present(found: Maybe<&2, String>, +fallback: String, +initial: String, +inherited: Bool) -> String:
  match found:
    case None{}: U.choose(String, inherited, fallback, initial)
    case Some{v}:
      +vv = v
      +k = style.keyword(vv)
      U.choose(String, U32.is_eq(k, 1) || (inherited && U32.is_eq(k, 3)), fallback,
        U.choose(String, U32.is_eq(k, 2) || U32.is_eq(k, 3), initial, vv))

def style.value(+as: List<&2, XML.Attr>, key: String, +fallback: String, +initial: String, +inherited: Bool) -> String:
  style.present(XML.attr.find(as, key), fallback, initial, inherited)

# A numeric inherited property: the parent's number stays a number when the
# attribute is absent instead of being printed and parsed again.
def style.number.present(found: Maybe<&2, String>, +parent: F32, +initial: F32, parse: String -> F32) -> F32:
  match found:
    case None{}: parent
    case Some{v}:
      +vv = v
      +k = style.keyword(vv)
      U.choose(F32, U32.is_eq(k, 1) || U32.is_eq(k, 3), parent,
        U.choose(F32, U32.is_eq(k, 2), initial, parse(vv)))

def style.number(+as: List<&2, XML.Attr>, key: String, +parent: F32, +initial: F32, parse: String -> F32) -> F32:
  style.number.present(XML.attr.find(as, key), parent, initial, parse)

# The style properties an element's own attributes may set, picked up in
# one pass over the attribute list (the first occurrence of a key counts,
# as a lookup by name would find it), so inheritance reads them without a
# walk per property.
type Picked is Data:
  Picked{fill: Maybe<&2, String>, stroke: Maybe<&2, String>, color: Maybe<&2, String>, fo: Maybe<&2, String>, so: Maybe<&2, String>,
    width: Maybe<&2, String>, rule: Maybe<&2, String>, vis: Maybe<&2, String>, render: Maybe<&2, String>, order: Maybe<&2, String>,
    cap: Maybe<&2, String>, join: Maybe<&2, String>, limit: Maybe<&2, String>, dash: Maybe<&2, String>, offset: Maybe<&2, String>,
    vector: Maybe<&2, String>, ms: Maybe<&2, String>, mm: Maybe<&2, String>, me: Maybe<&2, String>}

def pick.none() -> Picked:
  Picked{None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}}

def pick.first(old: Maybe<&2, String>, v: String) -> Maybe<&2, String>:
  match old:
    case None{}: Some{v}
    case Some{x}: Some{x}

# Which property a key names, 0 for none, by its first letter then the name.
def pick.slot.f(+k: String) -> U32:
  U.choose(U32, U.string.equal(k, "fill"), 1, U.choose(U32, U.string.equal(k, "fill-opacity"), 4, U.choose(U32, U.string.equal(k, "fill-rule"), 7, 0)))

def pick.slot.s(+k: String) -> U32:
  U.choose(U32, U.string.equal(k, "stroke"), 2, U.choose(U32, U.string.equal(k, "stroke-opacity"), 5, U.choose(U32, U.string.equal(k, "stroke-width"), 6,
    U.choose(U32, U.string.equal(k, "stroke-linecap"), 11, U.choose(U32, U.string.equal(k, "stroke-linejoin"), 12, U.choose(U32, U.string.equal(k, "stroke-miterlimit"), 13,
      U.choose(U32, U.string.equal(k, "stroke-dasharray"), 14, U.choose(U32, U.string.equal(k, "stroke-dashoffset"), 15, 0))))))))

def pick.slot.m(+k: String) -> U32:
  U.choose(U32, U.string.equal(k, "marker-start"), 17, U.choose(U32, U.string.equal(k, "marker-mid"), 18, U.choose(U32, U.string.equal(k, "marker-end"), 19, 0)))

def pick.slot.other(+k: String, +c: U32) -> U32:
  U.choose(U32, U32.is_eq(c, 99) && U.string.equal(k, "color"), 3,
    U.choose(U32, U32.is_eq(c, 118) && U.string.equal(k, "visibility"), 8, U.choose(U32, U32.is_eq(c, 118) && U.string.equal(k, "vector-effect"), 16,
      U.choose(U32, U32.is_eq(c, 105) && U.string.equal(k, "image-rendering"), 9, U.choose(U32, U32.is_eq(c, 112) && U.string.equal(k, "paint-order"), 10, 0)))))

def pick.slot(k: String) -> U32:
  match k:
    case SNil{}: 0
    case SCon{Chr{c}, t}:
      +ch = c
      +key = {SCon{Chr{ch}, t} : String}
      U.choose(U32, U32.is_eq(ch, 102), pick.slot.f(key), U.choose(U32, U32.is_eq(ch, 115), pick.slot.s(key), U.choose(U32, U32.is_eq(ch, 109), pick.slot.m(key), pick.slot.other(key, ch))))

def pick.put(p: Picked, +slot: U32, v: String) -> Picked:
  Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19} = p
  match slot:
    case 1: Picked{pick.first(q1, v), q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 2: Picked{q1, pick.first(q2, v), q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 3: Picked{q1, q2, pick.first(q3, v), q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 4: Picked{q1, q2, q3, pick.first(q4, v), q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 5: Picked{q1, q2, q3, q4, pick.first(q5, v), q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 6: Picked{q1, q2, q3, q4, q5, pick.first(q6, v), q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 7: Picked{q1, q2, q3, q4, q5, q6, pick.first(q7, v), q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 8: Picked{q1, q2, q3, q4, q5, q6, q7, pick.first(q8, v), q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 9: Picked{q1, q2, q3, q4, q5, q6, q7, q8, pick.first(q9, v), q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 10: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, pick.first(q10, v), q11, q12, q13, q14, q15, q16, q17, q18, q19}
    case 11: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, pick.first(q11, v), q12, q13, q14, q15, q16, q17, q18, q19}
    case 12: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, pick.first(q12, v), q13, q14, q15, q16, q17, q18, q19}
    case 13: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, pick.first(q13, v), q14, q15, q16, q17, q18, q19}
    case 14: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, pick.first(q14, v), q15, q16, q17, q18, q19}
    case 15: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, pick.first(q15, v), q16, q17, q18, q19}
    case 16: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, pick.first(q16, v), q17, q18, q19}
    case 17: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, pick.first(q17, v), q18, q19}
    case 18: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, pick.first(q18, v), q19}
    case 19: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, pick.first(q19, v)}
    case _: Picked{q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19}

def style.pick(as: List<&2, XML.Attr>, p: Picked) -> Picked:
  match as:
    case Nil{}: p
    case Con{XML.Attr{k, v}, rest}: style.pick(rest, pick.put(p, pick.slot(k), v))

def stroke.inherit(s: StrokeSettings, cap: Maybe<&2, String>, join: Maybe<&2, String>, lim: Maybe<&2, String>, dash: Maybe<&2, String>, offset: Maybe<&2, String>, vector: Maybe<&2, String>) -> StrokeSettings:
  StrokeSettings{cap0, join0, limit, dash0, offset0, vector0} = s
  +lim0 = limit
  StrokeSettings{style.present(cap, cap0, "butt", True{}), style.present(join, join0, "miter", True{}),
    U.max(0.0, style.number.present(lim, lim0, 4.0, v => U.scalar(v, lim0))),
    style.present(dash, dash0, "none", True{}), style.present(offset, offset0, "0", True{}),
    style.present(vector, vector0, "none", False{})}

def point.cross(p: Point, q: Point) -> F32:
  Point{x, y} = p
  Point{u, v} = q
  (x * v - y * u : F32)

def point.normal(p: Point) -> Point:
  Point{x, y} = p
  Point{F32.neg(y), x}

def point.unit(+p: Point) -> Point:
  point.scale(p, (1.0 / U.max(0.0000001, F32.sqrt(point.dot(p, p))) : F32))

type Subpath is Data:
  Subpath{points: List<&2, Point>, closed: Bool}

def points.rev(xs: List<&2, Point>, acc: List<&2, Point>) -> List<&2, Point>:
  match xs:
    case Nil{}: acc
    case Con{h, t}: points.rev(t, Con{h, acc})

# Repeated points dropped, each decided a step ahead: `near` says whether
# h coincides with the point kept before it.
@unsafe
def points.clean.go(near: Bool, +h: Point, t: List<&2, Point>, +previous: Point) -> List<&2, Point>:
  match near:
    case True{}:
      match t:
        case Nil{}: Nil{}
        case Con{h2, t2}:
          +hh = h2
          points.clean.go(F32.is_lt(point.distance(hh, previous), 0.0000001), hh, t2, previous)
    case False{}:
      match t:
        case Nil{}: Con{h, Nil{}}
        case Con{h2, t2}:
          +hh = h2
          Con{h, points.clean.go(F32.is_lt(point.distance(hh, h), 0.0000001), hh, t2, h)}

def points.clean(xs: List<&2, Point>, +previous: Point) -> List<&2, Point>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, t}:
      +hh = h
      points.clean.go(F32.is_lt(point.distance(hh, previous), 0.0000001), hh, t, previous)

def subpath.finish(points: List<&2, Point>, closed: Bool, paths: List<&2, Subpath>) -> List<&2, Subpath>:
  match points:
    case Nil{}: paths
    case Con{h, t}:
      +p = h
      Con{Subpath{points.rev(Con{p, points.clean(t, p)}, Nil{}), closed}, paths}

def edges.rev(es: List<&2, Edge>, acc: List<&2, Edge>) -> List<&2, Edge>:
  match es:
    case Nil{}: acc
    case Con{h, t}: edges.rev(t, Con{h, acc})

def points.add(points: List<&2, Point>, a: Point, b: Point) -> List<&2, Point>:
  match points:
    case Nil{}: Con{b, Con{a, Nil{}}}
    case Con{h, t}: Con{b, Con{h, t}}

# The polylines under construction: the current one's points (reversed)
# and the finished subpaths.
type Sub is Data:
  Sub{points: List<&2, Point>, paths: List<&2, Subpath>}

# 0 a fill-only edge (ends the current subpath, open), 1 a stroked edge
# (extends it), 2 a closing edge (ends it, closed).
def edge.kind(+stroked: Bool, +closed: Bool) -> U32:
  U.choose(U32, stroked, U.choose(U32, closed, 2, 1), 0)

def subpaths.add(kind: U32, +ax: F32, +ay: F32, +bx: F32, +by: F32, st: Sub) -> Sub:
  match kind:
    case 0:
      Sub{points, paths} = st
      Sub{Nil{}, subpath.finish(points, False{}, paths)}
    case 1:
      Sub{points, paths} = st
      Sub{points.add(points, Point{ax, ay}, Point{bx, by}), paths}
    case _:
      Sub{points, paths} = st
      Sub{Nil{}, subpath.finish(points.add(points, Point{ax, ay}, Point{bx, by}), True{}, paths)}

def subpaths.finish(st: Sub) -> List<&2, Subpath>:
  Sub{points, paths} = st
  subpath.finish(points, False{}, paths)

@unsafe
def subpaths.go(kind: U32, +ax: F32, +ay: F32, +bx: F32, +by: F32, rest: List<&2, Edge>, st: Sub) -> List<&2, Subpath>:
  match rest:
    case Nil{}: subpaths.finish(subpaths.add(kind, ax, ay, bx, by, st))
    case Con{Edge{x0, y0, x1, y1, s2, c2}, r2}: subpaths.go(edge.kind(s2, c2), x0, y0, x1, y1, r2, subpaths.add(kind, ax, ay, bx, by, st))

def subpaths(es: List<&2, Edge>) -> List<&2, Subpath>:
  match es:
    case Nil{}: Nil{}
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}: subpaths.go(edge.kind(stroked, closed), ax, ay, bx, by, rest, Sub{Nil{}, Nil{}})

type Segment is Data:
  Segment{px: F32, py: F32, qx: F32, qy: F32, ux: F32, uy: F32, length: F32, distance: F32}

def segment.of(p: Point, q: Point, u: Point, +length: F32, +distance: F32) -> Segment:
  Point{px, py} = p
  Point{qx, qy} = q
  Point{ux, uy} = u
  Segment{px, py, qx, qy, ux, uy, length, distance}

def segments(+points: List<&2, Point>, +distance: F32) -> List<&2, Segment>:
  match points:
    case Nil{}: Nil{}
    case Con{p, Nil{}}: Nil{}
    case Con{p, Con{q, rest}}:
      +len = point.distance(p, q)
      Con{segment.of(p, q, point.unit(point.sub(q, p)), len, distance), segments(Con{q, rest}, (distance + len : F32))}

def segments.length(xs: List<&2, Segment>) -> F32:
  match xs:
    case Nil{}: 0.0
    case Con{Segment{px, py, qx, qy, ux, uy, len, distance}, rest}: (len + segments.length(rest) : F32)

# Dash intervals are measured along each flattened subpath. A dash crossing a
# vertex gets a join; a dash ending there gets a cap instead.
type DashPattern is Data:
  DashPattern{values: List<&2, F32>, period: F32, offset: F32}

type DashCursor is Data:
  DashCursor{remaining: F32, rest: List<&2, F32>, painted: Bool}

type DashRun is Data:
  DashRun{start: F32, end: F32}

def floats.append(xs: List<&2, F32>, ys: List<&2, F32>) -> List<&2, F32>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, floats.append(t, ys)}

def floats.count(xs: List<&2, F32>) -> U32:
  match xs:
    case Nil{}: 0
    case Con{h, t}: U32.inc(floats.count(t))

def floats.sum(xs: List<&2, F32>) -> F32:
  match xs:
    case Nil{}: 0.0
    case Con{h, t}: (h + floats.sum(t) : F32)

def floats.negative(xs: List<&2, F32>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h, t}: F32.is_lt(h, 0.0) || floats.negative(t)

def dash.skip.units(+s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      U.branch(String, (U32.is_ge(c, 65) && U32.is_le(c, 90)) || (U32.is_ge(c, 97) && U32.is_le(c, 122)) || U32.is_eq(c, 37),
        _ => dash.skip.units(t), _ => s)

def dash.value(+n: U.Number, ref: F32, next: String -> List<&2, F32>) -> List<&2, F32>:
  U.Number{x, t, valid} = n
  U.choose(Unit -> List<&2, F32>, valid, _ => Con{U.unit(n, ref), next(dash.skip.units(t))}, _ => Nil{})(Unit{})

@unsafe
def dash.values(s: String, +ref: F32) -> List<&2, F32>:
  dash.value(U.number(s), ref, t => dash.values(t, ref))

def dash.pattern.values(+values: List<&2, F32>, offset: F32) -> DashPattern:
  +vs = U.choose(List<&2, F32>, U32.is_eq((floats.count(values) % 2 : U32), 1), floats.append(values, values), values)
  DashPattern{vs, U.choose(F32, floats.negative(vs), 0.0, floats.sum(vs)), offset}

def floats.scale(xs: List<&2, F32>, +factor: F32) -> List<&2, F32>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, t}: Con{(h * factor : F32), floats.scale(t, factor)}

def dash.pattern(settings: StrokeSettings, +ref: F32, +factor: F32) -> DashPattern:
  StrokeSettings{cap, join, limit, dash, offset, vector} = settings
  dash.pattern.values(floats.scale(dash.values(dash, ref), factor), (U.unit(U.number(offset), ref) * factor : F32))

# Whether the pattern dashes at all.
def dash.some(pattern: DashPattern) -> Bool:
  DashPattern{values, period, offset} = pattern
  F32.is_gt(period, 0.0000001)

def dash.seek(xs: List<&2, F32>, +offset: F32, +painted: Bool) -> DashCursor:
  match xs:
    case Nil{}: DashCursor{0.0, Nil{}, painted}
    case Con{h, t}:
      +len = h
      +tail = t
      U.branch(DashCursor, F32.is_le(offset, len), _ => DashCursor{(len - offset : F32), tail, painted},
        _ => dash.seek(tail, (offset - len : F32), Bool.not(painted)))

def dash.next(xs: List<&2, F32>, all: List<&2, F32>, painted: Bool) -> DashCursor:
  match xs:
    case Nil{}: dash.seek(all, 0.0, painted)
    case Con{h, t}: DashCursor{h, t, painted}

@unsafe
def dash.walk(+cursor: DashCursor, +all: List<&2, F32>, +position: F32, +total: F32) -> List<&2, DashRun>:
  DashCursor{remaining, rest, painted} = cursor
  +end = U.min(total, (position + remaining : F32))
  +tail = U.branch(List<&2, DashRun>, F32.is_ge(end, total), _ => Nil{},
    _ => dash.walk(dash.next(rest, all, Bool.not(painted)), all, end, total))
  U.choose(List<&2, DashRun>, painted, Con{DashRun{position, end}, tail}, tail)

def dash.runs(+pattern: DashPattern, +total: F32) -> List<&2, DashRun>:
  DashPattern{values, period, offset} = pattern
  U.branch(List<&2, DashRun>, F32.is_le(period, 0.0000001), _ => Con{DashRun{0.0, total}, Nil{}},
    _ => dash.walk(dash.seek(values, (offset - period * F32.floor((offset / period : F32)) : F32), True{}), values, 0.0, total))

def dash.crosses(xs: List<&2, DashRun>, +t: F32) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{DashRun{a, b}, rest}:
      (F32.is_lt(a, t) && F32.is_gt(b, t)) || dash.crosses(rest, t)

def dash.start(xs: List<&2, DashRun>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{DashRun{a, b}, rest}:
      (F32.is_le(a, 0.0) && F32.is_gt(b, 0.0)) || dash.start(rest)

def dash.end(xs: List<&2, DashRun>, +total: F32) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{DashRun{a, b}, rest}:
      (F32.is_lt(a, total) && F32.is_ge(b, total)) || dash.end(rest, total)

def segment.dir(s: Segment) -> Point:
  Segment{px, py, qx, qy, ux, uy, len, distance} = s
  Point{ux, uy}

def segment.start(s: Segment) -> Point:
  Segment{px, py, qx, qy, ux, uy, len, distance} = s
  Point{px, py}

def segment.end(s: Segment) -> Point:
  Segment{px, py, qx, qy, ux, uy, len, distance} = s
  Point{qx, qy}

# ---- outline stroker ----
# A stroke is filled as an outline with nonzero winding: for an open subpath
# one polygon (the left offsets forward, the end cap, the right offsets
# backward, the start cap), for a closed one two (the left and the right
# offsets, each closed, running opposite ways so the band between them has
# winding one). Joins are built on the outer side of a vertex only; on the
# inner side the two offsets cross, and the small loop that makes still
# fills under nonzero winding. Round parts are flattened to the device
# tolerance through `scale`, the device pixels per local unit.

# The join and cap of a stroke as codes, decided once per stroke instead of
# by name at every vertex: cap 0 butt, 1 round, 2 square; join 0 miter,
# 1 round, 2 bevel, 3 miter-clip.
type Joins is Data:
  Joins{cap: U32, join: U32, limit: F32}

def cap.code(+s: String) -> U32:
  U.choose(U32, U.string.equal(s, "round"), 1, U.choose(U32, U.string.equal(s, "square"), 2, 0))

def join.code(+s: String) -> U32:
  U.choose(U32, U.string.equal(s, "round"), 1, U.choose(U32, U.string.equal(s, "bevel"), 2, U.choose(U32, U.string.equal(s, "miter-clip"), 3, 0)))

def joins.of(settings: StrokeSettings) -> Joins:
  StrokeSettings{cap, join, limit, dash, offset, vector} = settings
  Joins{cap.code(cap), join.code(join), limit}

def outline.tolerance(+scale: F32) -> F32:
  (flat.tolerance() / U.max(scale, 0.000001) : F32)

# Steps for an arc of `sweep` radians at radius r within the tolerance.
def outline.steps(+sweep: F32, +r: F32, +scale: F32) -> U32:
  +tol = outline.tolerance(scale)
  +step = U.max(0.001, (2.0 * F32.sqrt((2.0 * U.max(tol, 0.000001) / U.max(r, 0.000001) : F32)) : F32))
  F32.to_u32(U.min(4096.0, U.max(1.0, F32.ceil((F32.abs(sweep) / step : F32)))))

def point.angle(+p: Point) -> F32:
  Point{x, y} = p
  F32.atan2(y, x)

# n points from `angle` on, `step` apart, prepended in order.
def outline.arc(n: Nat, +c: Point, +r: F32, +angle: F32, +step: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match n:
    case 0n: acc
    case 1n+d: outline.arc(d, c, r, (angle + step : F32), step, Con{point.add(c, Point{(r * F32.cos(angle) : F32), (r * F32.sin(angle) : F32)}), acc})

# The points strictly between the start and end of an arc around c from the
# direction `from` sweeping `sweep` radians (signed).
def outline.sweep(+c: Point, +r: F32, +from: Point, +sweep: F32, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  +n = outline.steps(sweep, r, scale)
  +step = (sweep / U32.to_f32(n) : F32)
  outline.arc(U32.to_nat((n - 1 : U32)), c, r, (point.angle(from) + step : F32), step, acc)

# The signed angle from u to v, both unit vectors.
def point.turn(+u: Point, +v: Point) -> F32:
  F32.atan2(point.cross(u, v), point.dot(u, v))

# The join on the left side at vertex p, from the incoming direction u to the
# outgoing v, when that side is the outer one (the path turns right). Both
# offset endpoints a = p + r n(u) and b = p + r n(v) are pushed by the
# segments; only what lies between them is added here.
def outline.miter.pick(fits: Bool, clip: Bool, +m: Point, +a: Point, +b: Point, +da: F32, +db: F32, +distance: F32, +reach: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match fits:
    case True{}: Con{m, acc}
    case False{}:
      match clip:
        case True{}:
          Con{point.add(b, point.scale(point.sub(m, b), U.clamp(((reach - db) / (distance - db) : F32), 0.0, 1.0))),
            Con{point.add(a, point.scale(point.sub(m, a), U.clamp(((reach - da) / (distance - da) : F32), 0.0, 1.0))), acc}}
        case False{}: acc

def outline.miter(+p: Point, +a: Point, +b: Point, +u: Point, +v: Point, +r: F32, +limit: F32, +join: U32, acc: List<&2, Point>) -> List<&2, Point>:
  +m = point.add(a, point.scale(u, (point.cross(point.sub(b, a), v) / point.cross(u, v) : F32)))
  +distance = point.distance(p, m)
  +n = point.unit(point.sub(m, p))
  +reach = (limit * r : F32)
  outline.miter.pick(F32.is_le(distance, reach), U32.is_eq(join, 3), m, a, b, point.dot(point.sub(a, p), n), point.dot(point.sub(b, p), n), distance, reach, acc)

def outline.join.kind(+join: U32, +p: Point, +u: Point, +v: Point, +nu: Point, +r: F32, +limit: F32, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match join:
    case 1: outline.sweep(p, r, nu, point.turn(u, v), scale, acc)
    case 2: acc
    case _: outline.miter(p, point.add(p, point.scale(nu, r)), point.add(p, point.scale(point.normal(v), r)), u, v, r, limit, join, acc)

def outline.join.outer(+p: Point, +u: Point, +v: Point, +r: F32, js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  Joins{cap, join, limit} = js
  outline.join.kind(join, p, u, v, point.normal(u), r, limit, scale, acc)

# A reversal (v = -u) gets the half circle through p + r u when joins are round.
def outline.join.back.kind(join: U32, +p: Point, +u: Point, +r: F32, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match join:
    case 1: outline.sweep(p, r, point.normal(u), F32.neg(3.141592653589793), scale, acc)
    case _: acc

def outline.join.back(+p: Point, +u: Point, +r: F32, js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  Joins{cap, join, limit} = js
  outline.join.back.kind(join, p, u, r, scale, acc)

# The previous segment along a side: its direction, the end of its offset
# (not yet emitted, since an inner join replaces it) and its length.
type Prev is Data:
  Prev{dir: Point, end: Point, len: F32}

def prev.of(seg: Segment, +r: F32) -> Prev:
  Segment{px, py, qx, qy, ux, uy, len, distance} = seg
  +u = {Point{ux, uy} : Point}
  Prev{u, point.add(Point{qx, qy}, point.scale(point.normal(u), r)), len}

# On the inner side the two offset lines cross; when they cross within both
# segments that point replaces both offset ends, so the outline has no loop
# there. Otherwise (a segment shorter than the offset) the ends stay and the
# loop they make still fills under nonzero winding.
def outline.inner(+p: Point, +u: Point, +a1: Point, +lenPrev: F32, +v: Point, +b0: Point, +lenNext: F32, +acc: List<&2, Point>) -> List<&2, Point>:
  +den = point.cross(u, v)
  +t = (point.cross(point.sub(b0, a1), v) / den : F32)
  +s = (point.cross(point.sub(b0, a1), u) / den : F32)
  U.choose(List<&2, Point>, F32.is_le(t, 0.0) && F32.is_ge(t, F32.neg(lenPrev)) && F32.is_ge(s, 0.0) && F32.is_le(s, lenNext),
    Con{point.add(a1, point.scale(u, t)), acc}, Con{b0, Con{a1, acc}})

def outline.back.if(reversal: Bool, +p: Point, +u: Point, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match reversal:
    case True{}: outline.join.back(p, u, r, js, scale, acc)
    case False{}: acc

# The points at vertex p between the previous segment (direction u, offset
# end a1) and the next (direction v, offset start b0).
def outline.vertex.pick(straight: Bool, outer: Bool, +p: Point, +u: Point, +a1: Point, +lenPrev: F32, +v: Point, +b0: Point, +lenNext: F32, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match straight:
    case True{}: Con{b0, outline.back.if(F32.is_lt(point.dot(u, v), 0.0), p, u, r, js, scale, Con{a1, acc})}
    case False{}:
      match outer:
        case True{}: Con{b0, outline.join.outer(p, u, v, r, js, scale, Con{a1, acc})}
        case False{}: outline.inner(p, u, a1, lenPrev, v, b0, lenNext, acc)

def outline.vertex.join(+p: Point, +u: Point, +a1: Point, +lenPrev: F32, +v: Point, +b0: Point, +lenNext: F32, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  +turn = point.cross(u, v)
  outline.vertex.pick(F32.is_lt(F32.abs(turn), 0.000001), F32.is_lt(turn, 0.0), p, u, a1, lenPrev, v, b0, lenNext, r, js, scale, acc)

def outline.vertex(previous: Maybe<&2, Prev>, +p: Point, +v: Point, +lenNext: F32, +b0: Point, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match previous:
    case None{}: Con{b0, acc}
    case Some{Prev{u, a1, lenPrev}}: outline.vertex.join(p, u, a1, lenPrev, v, b0, lenNext, r, js, scale, acc)

# At the end of an open side the last offset end is emitted; a closed loop
# emitted it through its first vertex.
def outline.side.end(previous: Maybe<&2, Prev>, closed: Bool, acc: List<&2, Point>) -> List<&2, Point>:
  match previous:
    case None{}: acc
    case Some{Prev{u, e, l}}:
      match closed:
        case True{}: acc
        case False{}: Con{e, acc}

# The left side of a polyline: each segment's offset endpoints with the
# joins between segments. `previous` carries the segment arriving at the
# first vertex (the last one, for a closed subpath).
def outline.side(xs: List<&2, Segment>, previous: Maybe<&2, Prev>, +closed: Bool, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match xs:
    case Nil{}: outline.side.end(previous, closed, acc)
    case Con{Segment{px, py, qx, qy, ux, uy, len, distance}, rest}:
      +u = {Point{ux, uy} : Point}
      +pp = {Point{px, py} : Point}
      +ln = len
      +n = point.scale(point.normal(u), r)
      outline.side(rest, Some{Prev{u, point.add(Point{qx, qy}, n), ln}}, closed, r, js, scale, outline.vertex(previous, pp, u, ln, point.add(pp, n), r, js, scale, acc))

# The cap at point p leaving in direction u, between the offsets p + r n and
# p - r n (which the sides push): nothing for butt.
def outline.cap(cap: U32, +p: Point, +u: Point, +r: F32, +scale: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match cap:
    case 1: outline.sweep(p, r, point.normal(u), F32.neg(3.141592653589793), scale, acc)
    case 2:
      +n = point.scale(point.normal(u), r)
      +ahead = point.add(p, point.scale(u, r))
      Con{point.sub(ahead, n), Con{point.add(ahead, n), acc}}
    case _: acc

def outline.edges.go(+first: Point, pts: List<&2, Point>, +prev: Point, acc: List<&2, Edge>) -> List<&2, Edge>:
  match pts:
    case Nil{}: Con{edge.of(prev, first, True{}, True{}), acc}
    case Con{p, rest}:
      +pp = p
      outline.edges.go(first, rest, pp, Con{edge.of(prev, pp, True{}, False{}), acc})

# The closed polygon through the points, as edges.
def outline.edges(pts: List<&2, Point>, acc: List<&2, Edge>) -> List<&2, Edge>:
  match pts:
    case Nil{}: acc
    case Con{p, rest}:
      +pp = p
      outline.edges.go(pp, rest, pp, acc)

def segments.last(xs: List<&2, Segment>, fallback: Segment) -> Segment:
  match xs:
    case Nil{}: fallback
    case Con{h, t}: segments.last(t, h)

# The outline of an open polyline: the left side, the end cap, the right side
# (the left side of the reversed points) and the start cap.
def joins.cap(+s: Joins) -> U32:
  Joins{cap, join, limit} = s
  cap

def outline.open.go(forward: List<&2, Segment>, back: List<&2, Segment>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match forward:
    case Nil{}: acc
    case Con{h, t}:
      +first = h
      +tt = t
      +last = segments.last(tt, first)
      +cap = joins.cap(js)
      outline.edges(outline.cap(cap, segment.start(first), point.scale(segment.dir(first), F32.neg(1.0)), r, scale,
        outline.side(back, None{}, False{}, r, js, scale,
          outline.cap(cap, segment.end(last), segment.dir(last), r, scale,
            outline.side(Con{first, tt}, None{}, False{}, r, js, scale, Nil{})))), acc)

# The segments backwards, each turned around, for the right side.
def segments.flip(xs: List<&2, Segment>, acc: List<&2, Segment>) -> List<&2, Segment>:
  match xs:
    case Nil{}: acc
    case Con{Segment{px, py, qx, qy, ux, uy, len, distance}, rest}: segments.flip(rest, Con{Segment{qx, qy, px, py, F32.neg(ux), F32.neg(uy), len, distance}, acc})

def outline.open.segs(+forward: List<&2, Segment>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  outline.open.go(forward, segments.flip(forward, Nil{}), r, js, scale, acc)

def outline.open(pts: List<&2, Point>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  outline.open.segs(segments(pts, 0.0), r, js, scale, acc)

# A closed subpath: one closed loop per side, each joined at the start vertex.
def outline.loop(+xs: List<&2, Segment>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match xs:
    case Nil{}: acc
    case Con{h, t}:
      +first = h
      outline.edges(outline.side(Con{h, t}, Some{prev.of(segments.last(t, first), r)}, True{}, r, js, scale, Nil{}), acc)

def outline.closed.segs(+forward: List<&2, Segment>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  outline.loop(segments.flip(forward, Nil{}), r, js, scale, outline.loop(forward, r, js, scale, acc))

def outline.closed(pts: List<&2, Point>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  outline.closed.segs(segments(pts, 0.0), r, js, scale, acc)

# A zero-length piece: a dot for round caps, a square for square caps.
def outline.dot.cap(+cap: U32, +p: Point, +u: Point, +r: F32, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match cap:
    case 0: acc
    case _:
      +n = point.scale(point.normal(u), r)
      outline.edges(outline.cap(cap, p, point.scale(u, F32.neg(1.0)), r, scale, Con{point.sub(p, n), outline.cap(cap, p, u, r, scale, Con{point.add(p, n), Nil{}})}), acc)

def outline.dot(+p: Point, +u: Point, +r: F32, js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  outline.dot.cap(joins.cap(js), p, u, r, scale, acc)

# ---- dashes as polylines ----
# The point at distance d along the segments, and the direction there.
def segment.at(s: Segment, +d: F32) -> Point:
  Segment{px, py, qx, qy, ux, uy, len, distance} = s
  point.add(Point{px, py}, point.scale(Point{ux, uy}, U.clamp((d - distance : F32), 0.0, len)))

def segment.reaches(s: Segment, +d: F32) -> Bool:
  Segment{px, py, qx, qy, ux, uy, len, distance} = s
  F32.is_le(d, (distance + len : F32))

@unsafe
def segments.at(xs: List<&2, Segment>, +d: F32, +fallback: Point) -> Point:
  match xs:
    case Nil{}: fallback
    case Con{h, Nil{}}: segment.at(h, d)
    case Con{h, Con{g, t}}:
      +hh = h
      U.branch(Point, segment.reaches(hh, d), _ => segment.at(hh, d), _ => segments.at(Con{g, t}, d, fallback))

@unsafe
def segments.dir.at(xs: List<&2, Segment>, +d: F32, +fallback: Point) -> Point:
  match xs:
    case Nil{}: fallback
    case Con{h, Nil{}}: segment.dir(h)
    case Con{h, Con{g, t}}:
      +hh = h
      U.branch(Point, segment.reaches(hh, d), _ => segment.dir(hh), _ => segments.dir.at(Con{g, t}, d, fallback))

def points.push.if(hit: Bool, +p: Point, tail: List<&2, Point>) -> List<&2, Point>:
  match hit:
    case True{}: Con{p, tail}
    case False{}: tail

# The vertices strictly inside (s, e), in order, prepended before `acc`.
def segments.between(xs: List<&2, Segment>, +s: F32, +e: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match xs:
    case Nil{}: acc
    case Con{Segment{px, py, qx, qy, ux, uy, len, distance}, rest}:
      +at = (distance + len : F32)
      points.push.if(F32.is_gt(at, s) && F32.is_lt(at, e), Point{qx, qy}, segments.between(rest, s, e, acc))

# The polyline of the run [s, e] along the segments.
def dash.points(+xs: List<&2, Segment>, +s: F32, +e: F32) -> List<&2, Point>:
  Con{segments.at(xs, s, Point{0.0, 0.0}), segments.between(xs, s, e, Con{segments.at(xs, e, Point{0.0, 0.0}), Nil{}})}

def outline.run(+xs: List<&2, Segment>, +s: F32, +e: F32, +r: F32, +js: Joins, +scale: F32, +acc: List<&2, Edge>) -> List<&2, Edge>:
  U.branch(List<&2, Edge>, F32.is_le((e - s : F32), 0.000001),
    _ => outline.dot(segments.at(xs, s, Point{0.0, 0.0}), segments.dir.at(xs, s, Point{1.0, 0.0}), r, js, scale, acc),
    _ => outline.open(dash.points(xs, s, e), r, js, scale, acc))

# The runs of an open subpath, or of a closed one whose dashes do not meet at
# the seam. A closed subpath painted along its whole length is a closed loop.
def outline.runs(runs: List<&2, DashRun>, +xs: List<&2, Segment>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match runs:
    case Nil{}: acc
    case Con{DashRun{s, e}, rest}: outline.runs(rest, xs, r, js, scale, outline.run(xs, s, e, r, js, scale, acc))

def dash.first.end(xs: List<&2, DashRun>) -> F32:
  match xs:
    case Nil{}: 0.0
    case Con{DashRun{s, e}, rest}: e

def dash.last.start(xs: List<&2, DashRun>, +fallback: F32) -> F32:
  match xs:
    case Nil{}: fallback
    case Con{DashRun{s, e}, rest}: dash.last.start(rest, s)

def dash.drop.first(xs: List<&2, DashRun>) -> List<&2, DashRun>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, t}: t

def dash.drop.last(xs: List<&2, DashRun>) -> List<&2, DashRun>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, Nil{}}: Nil{}
    case Con{h, Con{g, t}}: Con{h, dash.drop.last(Con{g, t})}

def dash.whole(xs: List<&2, DashRun>, +total: F32) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{DashRun{s, e}, Nil{}}: F32.is_le(s, 0.0) && F32.is_ge(e, total)
    case Con{DashRun{s, e}, Con{g, t}}: False{}

def dash.points.tail(+xs: List<&2, Segment>, +s: F32, +e: F32) -> List<&2, Point>:
  segments.between(xs, s, e, Con{segments.at(xs, e, Point{0.0, 0.0}), Nil{}})

def points.append(xs: List<&2, Point>, ys: List<&2, Point>) -> List<&2, Point>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, points.append(t, ys)}

# The dashes of a closed subpath crossing the seam merge into one polyline:
# the last run's points followed by the first run's, minus the shared point.
def outline.seam(+xs: List<&2, Segment>, +runs: List<&2, DashRun>, +total: F32, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  +s = dash.last.start(runs, 0.0)
  +e = dash.first.end(runs)
  outline.runs(dash.drop.last(dash.drop.first(runs)), xs, r, js, scale,
    outline.open(points.append(dash.points(xs, s, total), dash.points.tail(xs, 0.0, e)), r, js, scale, acc))

def outline.dashed.runs(+pts: List<&2, Point>, +closed: Bool, +r: F32, +js: Joins, +pattern: DashPattern, +scale: F32, +acc: List<&2, Edge>) -> List<&2, Edge>:
  +xs = segments(pts, 0.0)
  +total = segments.length(xs)
  +runs = dash.runs(pattern, total)
  U.branch(List<&2, Edge>, closed && dash.whole(runs, total), _ => outline.closed(pts, r, js, scale, acc),
    _ => U.branch(List<&2, Edge>, closed && dash.start(runs) && dash.end(runs, total) && Bool.not(dash.whole(runs, total)),
      _ => outline.seam(xs, runs, total, r, js, scale, acc),
      _ => outline.runs(runs, xs, r, js, scale, acc)))

# An undashed subpath is outlined whole; only a dash pattern measures it.
def outline.plain(closed: Bool, pts: List<&2, Point>, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match closed:
    case True{}: outline.closed(pts, r, js, scale, acc)
    case False{}: outline.open(pts, r, js, scale, acc)

def outline.dashed(dashed: Bool, pts: List<&2, Point>, +closed: Bool, +r: F32, +js: Joins, pattern: DashPattern, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match dashed:
    case True{}: outline.dashed.runs(pts, closed, r, js, pattern, scale, acc)
    case False{}: outline.plain(closed, pts, r, js, scale, acc)

def dash.any(xs: List<&2, DashRun>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h, t}: True{}

def outline.dot.if(paint: Bool, +p: Point, +r: F32, +js: Joins, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match paint:
    case True{}: outline.dot(p, Point{1.0, 0.0}, r, js, scale, acc)
    case False{}: acc

# A subpath of one point: caps only, as a dot in the x direction, when the
# dash pattern paints at its start.
def outline.subpath(+pts: List<&2, Point>, +closed: Bool, +r: F32, +js: Joins, +pattern: DashPattern, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match pts:
    case Nil{}: acc
    case Con{p, Nil{}}: outline.dot.if(dash.any(dash.runs(pattern, 0.0)), p, r, js, scale, acc)
    case Con{p, Con{q, rest}}: outline.dashed(dash.some(pattern), Con{p, Con{q, rest}}, closed, r, js, pattern, scale, acc)

def outline.subpaths(paths: List<&2, Subpath>, +r: F32, +js: Joins, +pattern: DashPattern, +scale: F32, acc: List<&2, Edge>) -> List<&2, Edge>:
  match paths:
    case Nil{}: acc
    case Con{Subpath{points, closed}, rest}: outline.subpaths(rest, r, js, pattern, scale, outline.subpath(points, closed, r, js, pattern, scale, acc))

def subpaths.length(paths: List<&2, Subpath>) -> F32:
  match paths:
    case Nil{}: 0.0
    case Con{Subpath{points, closed}, rest}: (segments.length(segments(points, 0.0)) + subpaths.length(rest) : F32)

def stroke.compile.pick(measured: Bool, paths: List<&2, Subpath>, r: F32, +settings: StrokeSettings, ref: F32, +declared: F32, +scale: F32) -> List<&2, Edge>:
  match measured:
    case True{}:
      +ps = paths
      outline.subpaths(ps, r, joins.of(settings), dash.pattern(settings, ref, (subpaths.length(ps) / declared : F32)), scale, Nil{})
    case False{}: outline.subpaths(paths, r, joins.of(settings), dash.pattern(settings, ref, 1.0), scale, Nil{})

def stroke.compile.paths(paths: List<&2, Subpath>, r: F32, +settings: StrokeSettings, ref: F32, +declared: F32, +scale: F32) -> List<&2, Edge>:
  stroke.compile.pick(F32.is_gt(declared, 0.0), paths, r, settings, ref, declared, scale)

# The stroke outline edges of a shape's edges, in the same units.
def stroke.compile(es: List<&2, Edge>, r: F32, settings: StrokeSettings, ref: F32, declared: F32, +scale: F32) -> List<&2, Edge>:
  stroke.compile.paths(subpaths(edges.rev(es, Nil{})), r, settings, ref, declared, scale)

def bounds.empty() -> Bounds:
  Bounds{1000000000.0, 1000000000.0, F32.neg(1000000000.0), F32.neg(1000000000.0)}

def bounds.merge(a: Bounds, b: Bounds) -> Bounds:
  Bounds{x0, y0, x1, y1} = a
  Bounds{u0, v0, u1, v1} = b
  Bounds{U.min(x0, u0), U.min(y0, v0), U.max(x1, u1), U.max(y1, v1)}

# A shape's edges with their bounds. Point queries walk the list; rasters
# read the list back directly, so no per-edge tree is ever built.
type EdgeTree is Data:
  EdgeFlat{box: Bounds, edges: List<&2, Edge>}

def edge.tree.bounds(t: EdgeTree) -> Bounds:
  match t:
    case EdgeFlat{box, edges}: box

def edge.tree(+es: List<&2, Edge>) -> EdgeTree:
  EdgeFlat{bounds(es, bounds.empty()), es}

def edge.tree.empty() -> EdgeTree:
  EdgeFlat{bounds.empty(), Nil{}}

def bounds.ray(b: Bounds, p: Point) -> Bool:
  Bounds{x0, y0, x1, y1} = b
  Point{x, y} = p
  +py = y
  F32.is_ge(py, y0) && F32.is_lt(py, y1) && F32.is_le(x, x1)

def edges.winding(es: List<&2, Edge>, +p: Point, +acc: F32) -> F32:
  match es:
    case Nil{}: acc
    case Con{e, rest}: edges.winding(rest, p, (acc + edge.cross(e, p) : F32))

def edge.tree.winding(t: EdgeTree, +p: Point) -> F32:
  match t:
    case EdgeFlat{box, edges}: U.branch(F32, bounds.ray(box, p), _ => edges.winding(edges, p, 0.0), _ => 0.0)

def edge.tree.inside(t: EdgeTree, p: Point, even: Bool) -> Bool:
  +w = edge.tree.winding(t, p)
  F32.is_gt(F32.abs(U.choose(F32, even, (w % 2.0 : F32), w)), 0.5)

# A fill keeps its bounds for the scene box and, once built for a raster,
# the cover that gives each pixel its exact coverage. The edges stay with
# the scene alone, so building the cover consumes them as their owner (the
# covered scene keeps none); a point query without a cover, picking on the
# compiled scene, walks them from there.
type Fill is Data:
  Fill{box: Bounds, cover: Cover}

def fill.new(es: List<&2, Edge>) -> Fill:
  Fill{bounds(es, bounds.empty()), cover.none()}

def fill.bounds(f: Fill) -> Bounds:
  Fill{box, cover} = f
  box

def fill.coverage(f: Fill, es: List<&2, Edge>, +q: Point, +p: Point, +even: Bool) -> F32:
  Fill{box, cover} = f
  +cov = cover
  U.branch(F32, cover.present(cov), _ => cover.at(cov, p), _ => U.choose(F32, fill.inside(es, q, even), 1.0, 0.0))

def bounds.disk(p: Point, +r: F32) -> Bounds:
  Point{x, y} = p
  +px = x
  +py = y
  Bounds{(px - r : F32), (py - r : F32), (px + r : F32), (py + r : F32)}

# The stroke outline as an edge tree in local units, with its inverse matrix
# (device to local) and, after the cover pass, its coverage.
type StrokeMesh is Data:
  StrokeMesh{tree: EdgeTree, inverse: Matrix, cover: Cover}

def stroke.mesh(+edges: List<&2, Edge>, inverse: Matrix) -> StrokeMesh:
  StrokeMesh{edge.tree(edges), inverse, cover.none()}

def stroke.mesh.inside(mesh: StrokeMesh, p: Point) -> Bool:
  StrokeMesh{tree, inv, cover} = mesh
  edge.tree.inside(tree, matrix.point(inv, p), False{})

def stroke.coverage(mesh: StrokeMesh, +p: Point) -> F32:
  StrokeMesh{stree, inv, cover} = mesh
  +cov = cover
  U.branch(F32, cover.present(cov), _ => cover.at(cov, p), _ => U.choose(F32, edge.tree.inside(stree, matrix.point(inv, p), False{}), 1.0, 0.0))

type MarkerStyle is Data:
  MarkerStyle{start: String, middle: String, end: String}

def marker.style(ms: MarkerStyle, s: Maybe<&2, String>, m: Maybe<&2, String>, e: Maybe<&2, String>) -> MarkerStyle:
  MarkerStyle{start, middle, end} = ms
  MarkerStyle{style.present(s, start, "none", True{}), style.present(m, middle, "none", True{}), style.present(e, end, "none", True{})}

# Normalize the small CSS paint-order vocabulary; omitted operations follow in
# default fill/stroke/markers order. Invalid values retain the inherited order.
def paint.order.normalize(s: String, +out: String, +gap: Bool) -> String:
  match s:
    case SNil{}: out
    case SCon{Chr{c}, rest}:
      +ch = c
      +tail = rest
      U.branch(String, U.space(ch), _ => paint.order.normalize(tail, out, Bool.not(U.string.equal(out, ""))),
        _ => paint.order.normalize(tail, out ++ U.choose(String, gap, " ", "") ++ SCon{Chr{ch}, SNil{}}, False{}))

def paint.order.name(+order: U32) -> String:
  U.choose(String, U32.is_eq(order, 1), "fill markers stroke", U.choose(String, U32.is_eq(order, 2), "stroke fill markers",
    U.choose(String, U32.is_eq(order, 3), "stroke markers fill", U.choose(String, U32.is_eq(order, 4), "markers fill stroke",
      U.choose(String, U32.is_eq(order, 5), "markers stroke fill", "normal")))))

def paint.order.value(+s: String, fallback: U32) -> U32:
  +v = paint.order.normalize(CSS.css.lower(U.trim.both(s)), "", False{})
  U.choose(U32, U.string.equal(v, "normal") || U.string.equal(v, "fill") || U.string.equal(v, "fill stroke") || U.string.equal(v, "fill stroke markers"), 0,
    U.choose(U32, U.string.equal(v, "fill markers") || U.string.equal(v, "fill markers stroke"), 1,
      U.choose(U32, U.string.equal(v, "stroke") || U.string.equal(v, "stroke fill") || U.string.equal(v, "stroke fill markers"), 2,
        U.choose(U32, U.string.equal(v, "stroke markers") || U.string.equal(v, "stroke markers fill"), 3,
          U.choose(U32, U.string.equal(v, "markers") || U.string.equal(v, "markers fill") || U.string.equal(v, "markers fill stroke"), 4,
            U.choose(U32, U.string.equal(v, "markers stroke") || U.string.equal(v, "markers stroke fill"), 5, fallback))))))

# The order from an element's own attribute, else the inherited one as it is.
def paint.order.pick(found: Maybe<&2, String>, +inherited: U32) -> U32:
  match found:
    case None{}: inherited
    case Some{v}:
      +vv = v
      +k = style.keyword(vv)
      U.choose(U32, U32.is_eq(k, 1) || U32.is_eq(k, 3), inherited, U.choose(U32, U32.is_eq(k, 2), 0, paint.order.value(vv, inherited)))

# Compilation resolves geometry and inherited presentation once per edit.
type Style is Data:
  Style{fill: String, stroke: String, color: String, fillOpacity: F32,
    strokeOpacity: F32, width: F32, even: Bool, visible: Bool, strokeSettings: StrokeSettings, markers: MarkerStyle, imageRendering: String, paintOrder: U32}

def style.default() -> Style:
  Style{"black", "none", "black", 1.0, 1.0, 1.0, False{}, True{}, stroke.settings(), MarkerStyle{"none", "none", "none"}, "auto", 0}

def style.inherit.picked(+s: Style, p: Picked, +ref: F32) -> Style:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  Picked{pfill, pstroke, pcolor, pfo, pso, pwidth, prule, pvis, prender, porder, pcap, pjoin, plimit, pdash, poffset, pvector, pms, pmm, pme} = p
  +po = order
  Style{style.present(pfill, fill, "black", True{}), style.present(pstroke, stroke, "none", True{}), style.present(pcolor, col, "black", True{}),
    style.number.present(pfo, fo, 1.0, v => color.opacity(v, fo)),
    style.number.present(pso, so, 1.0, v => color.opacity(v, so)),
    U.max(0.0, style.number.present(pwidth, width, 1.0, v => U.unit(U.number(v), ref))),
    U.string.equal(style.present(prule, U.choose(String, even, "evenodd", "nonzero"), "nonzero", True{}), "evenodd"),
    U.string.equal(style.present(pvis, U.choose(String, visible, "visible", "hidden"), "visible", True{}), "visible"), stroke.inherit(ss, pcap, pjoin, plimit, pdash, poffset, pvector), marker.style(ms, pms, pmm, pme), style.present(prender, rendering, "auto", True{}), paint.order.pick(porder, po)}

def style.inherit(+s: Style, as: List<&2, XML.Attr>, +ref: F32) -> Style:
  style.inherit.picked(s, style.pick(as, pick.none()), ref)

# The properties a resource may inherit, in the order every resolved list
# carries them; a resolved parent list starts with the same keys in the same
# order, so a parent's value is read positionally and only the element's own
# attributes are searched by name.
type Prop is Data:
  Prop{key: String, initial: String, inherited: Bool}

def props.spec() -> List<&2, Prop>:
  Con{Prop{"color", "black", True{}}, Con{Prop{"color-interpolation", "sRGB", True{}}, Con{Prop{"stop-color", "black", False{}}, Con{Prop{"stop-opacity", "1", False{}},
    Con{Prop{"fill", "black", True{}}, Con{Prop{"stroke", "none", True{}}, Con{Prop{"stroke-width", "1", True{}}, Con{Prop{"fill-opacity", "1", True{}},
    Con{Prop{"stroke-opacity", "1", True{}}, Con{Prop{"fill-rule", "nonzero", True{}}, Con{Prop{"clip-rule", "nonzero", True{}}, Con{Prop{"stroke-linecap", "butt", True{}},
    Con{Prop{"stroke-linejoin", "miter", True{}}, Con{Prop{"stroke-miterlimit", "4", True{}}, Con{Prop{"stroke-dasharray", "none", True{}}, Con{Prop{"stroke-dashoffset", "0", True{}},
    Con{Prop{"visibility", "visible", True{}}, Con{Prop{"opacity", "1", False{}}, Con{Prop{"image-rendering", "auto", True{}}, Con{Prop{"color-interpolation-filters", "linearRGB", True{}},
    Con{Prop{"flood-color", "black", False{}}, Con{Prop{"flood-opacity", "1", False{}}, Con{Prop{"marker-start", "none", True{}}, Con{Prop{"marker-mid", "none", True{}},
    Con{Prop{"marker-end", "none", True{}}, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}

def props.head.pick(hit: Bool, +v: String, whole: List<&2, XML.Attr>, +key: String, +initial: String) -> String:
  match hit:
    case True{}: v
    case False{}: XML.attr.get(whole, key, initial)

# The parent's value for key: the head when the parent list is resolved, else by name.
def props.head.value(parent: List<&2, XML.Attr>, +key: String, +initial: String) -> String:
  match parent:
    case Nil{}: initial
    case Con{XML.Attr{k, v}, t}:
      +kk = k
      +vv = v
      props.head.pick(U.string.equal(kk, key), vv, Con{XML.Attr{kk, vv}, t}, key, initial)

def props.advance.pick(hit: Bool, whole: List<&2, XML.Attr>, rest: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match hit:
    case True{}: rest
    case False{}: whole

def props.advance(parent: List<&2, XML.Attr>, +key: String) -> List<&2, XML.Attr>:
  match parent:
    case Nil{}: Nil{}
    case Con{XML.Attr{k, v}, t}:
      +kk = k
      +tt = t
      props.advance.pick(U.string.equal(kk, key), Con{XML.Attr{kk, v}, tt}, tt)

def props.fold(spec: List<&2, Prop>, +parent: List<&2, XML.Attr>, +as: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match spec:
    case Nil{}: as
    case Con{Prop{key, initial, inherited}, rest}:
      +k = key
      +ini = initial
      Con{XML.Attr{k, style.value(as, k, props.head.value(parent, k, ini), ini, inherited)}, props.fold(rest, props.advance(parent, k), as)}

# Referenced elements (gradients, patterns, markers, clip paths, masks,
# filters) get their inherited properties on demand: the raw tree is kept
# under a root element whose attributes are the root svg's, and a lookup
# by id resolves the properties down the ancestor chain of the element it
# finds. Nothing is resolved for the elements a document never references.
def resources(xs: List<&2, XML.Element>, +root: List<&2, XML.Attr>) -> List<&2, XML.Element>:
  Con{XML.Element{"#root", root, xs, ""}, Nil{}}

# The subtree of a found element gets its properties resolved too, since its
# content (stops, primitives, pattern or marker content) inherits from it.
def resources.tree(xs: List<&2, XML.Element>, +parent: List<&2, XML.Attr>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, attrs, kids, txt}, rest}:
      +props = props.fold(props.spec(), parent, CSS.properties(attrs))
      Con{XML.Element{n, props, resources.tree(kids, props), txt}, resources.tree(rest, parent)}

# The properties of an element below a chain of raw ancestor attribute
# lists, outermost last.
def resource.resolve(chain: List<&2, List<&2, XML.Attr>>, own: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match chain:
    case Nil{}: own
    case Con{as, rest}: props.fold(props.spec(), resource.resolve(rest, as), own)

def resource.found(+n: String, +props: List<&2, XML.Attr>, kids: List<&2, XML.Element>, +txt: String) -> Maybe<&2, XML.Element>:
  Some{XML.Element{n, props, resources.tree(kids, props), txt}}

# A lookup runs rarely, so it branches through lambdas over copies.
def resource.search(xs: List<&2, XML.Element>, +id: String, +chain: List<&2, List<&2, XML.Attr>>) -> Maybe<&2, XML.Element>:
  match xs:
    case Nil{}: None{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +nn = n
      +attrs = as
      +kk = kids
      +tt = txt
      U.branch(Maybe<&2, XML.Element>, U.string.equal(XML.attr.get(attrs, "id", ""), id),
        _ => resource.found(nn, resource.resolve(chain, CSS.properties(attrs)), kk, tt),
        _ => XML.element.prefer(U.branch(Maybe<&2, XML.Element>, U.string.equal(nn, "#svg-image"), _ => None{}, _ => resource.search(kk, id, Con{attrs, chain})),
          resource.search(rest, id, chain)))

def resource.find(+all: List<&2, XML.Element>, +id: String) -> Maybe<&2, XML.Element>:
  resource.search(all, id, Nil{})

# Gradient resources are compiled into paint functions before rasterization.
type Stop is Data:
  Stop{offset: F32, color: Img.Color}

type Clip is Data:
  ClipAll{}
  ClipShape{edges: EdgeTree, inverse: Matrix, even: Bool, cover: Cover}
  ClipUnion{left: Clip, right: Clip}
  ClipIntersect{left: Clip, right: Clip}

type Paint<-B: Data> is Data:
  Paint{fill: B, stroke: B}

type FilterEffect is Data:
  NoFilter{}
  FilterSpec{region: Bounds, units: Matrix, viewport: Point, attrs: List<&2, XML.Attr>, primitives: List<&2, XML.Element>}
  FilterImage{raster: Raster}

type Scene<-B: Data> is Data:
  Scene{edges: List<&2, Edge>, bounds: Bounds, inverse: Matrix, style: Style,
    opacity: F32, children: List<&2, Scene<B>>, id: String, paint: Paint<B>, clip: Clip, outline: StrokeMesh, fill: Fill, maskNodes: List<&2, Scene<B>>, maskMode: U32, markerNodes: List<&2, Scene<B>>, coverage: Bounds, effect: FilterEffect}

type Brush is Data:
  Bitmap{raster: Raster, inverse: Matrix, nearest: Bool}
  Solid{value: Img.Color, source: Img.Color}
  PendingContext{stroke: Bool, opacity: F32}
  ContextPaint{source: Brush, matrix: Matrix, opacity: F32}
  Pattern{inverse: Matrix, width: F32, height: F32, opacity: F32, nodes: List<&2, Scene<Brush>>}
  Tile{raster: Raster, inverse: Matrix, width: F32, height: F32, opacity: F32, u: Point, v: Point, grid: U32}
  Gradient{inverse: Matrix, radial: Bool, start: Point, end: Point, radius: F32,
    focalRadius: F32, stops: List<&2, Stop>, spread: U32, opacity: F32, linear: Bool}

def gradient.has.stops(xs: List<&2, XML.Element>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{XML.Element{n, as, kids, txt}, rest}: U.string.equal(n, "stop") || gradient.has.stops(rest)

def gradient.merge(local: XML.Element, template: XML.Element) -> XML.Element:
  XML.Element{n, as, kids, txt} = local
  XML.Element{tn, tas, tkids, ttxt} = template
  +children = kids
  XML.Element{n, XML.attrs.append(as, tas), U.choose(List<&2, XML.Element>, gradient.has.stops(children), children, tkids), txt}

def gradient.reference(+node: XML.Element, result: Maybe<&2, XML.Element>, next: XML.Element -> XML.Element) -> XML.Element:
  match result:
    case None{}: node
    case Some{e}: gradient.merge(node, next(e))

def gradient.resolve(depth: Nat, +node: XML.Element, +all: List<&2, XML.Element>) -> XML.Element:
  match depth:
    case 0n: node
    case 1n+d:
      XML.Element{n, as, kids, txt} = node
      +href = XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", ""))
      U.branch(XML.Element, U.prefix(href, "#"),
        _ => gradient.reference(node, resource.find(all, U.drop(href, "#")), e => gradient.resolve(d, e, all)), _ => node)

def srgb.linear(+v: F32) -> F32:
  U.branch(F32, F32.is_le(v, 0.04045), _ => (v / 12.92 : F32), _ => F32.pow(((v + 0.055) / 1.055 : F32), 2.4))

def linear.srgb(+v: F32) -> F32:
  U.branch(F32, F32.is_le(v, 0.0031308), _ => (v * 12.92 : F32),
    _ => (1.055 * F32.pow(v, 0.4166666666666667) - 0.055 : F32))

def stop.color(c: Img.Color, opacity: F32, +linear: Bool) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +alpha = a
  +rr = (r / U.max(0.0000001, alpha) : F32)
  +gg = (g / U.max(0.0000001, alpha) : F32)
  +bb = (b / U.max(0.0000001, alpha) : F32)
  Img.Color{U.choose(F32, linear, srgb.linear(rr), rr), U.choose(F32, linear, srgb.linear(gg), gg),
    U.choose(F32, linear, srgb.linear(bb), bb), (alpha * opacity : F32)}

def property.value(+as: List<&2, XML.Attr>, +parent: List<&2, XML.Attr>, +key: String, +initial: String, inherited: Bool) -> String:
  style.value(as, key, XML.attr.get(parent, key, initial), initial, inherited)

def gradient.stops(xs: List<&2, XML.Element>, +as: List<&2, XML.Attr>, +previous: F32, +linear: Bool) -> List<&2, Stop>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, attrs, kids, txt}, rest}:
      +props = CSS.properties(attrs)
      +offset = U.max(previous, U.clamp(U.unit(U.number(XML.attr.get(props, "offset", "0")), 1.0), 0.0, 1.0))
      +col = XML.attr.get(props, "stop-color", "black")
      +tail = rest
      U.branch(List<&2, Stop>, U.string.equal(n, "stop"),
        _ => Con{Stop{offset, stop.color(color(U.choose(String, U.string.equal(CSS.css.lower(U.trim.both(col)), "currentcolor"),
          XML.attr.get(props, "color", XML.attr.get(as, "color", "black")), col)), U.clamp(U.unit(U.number(XML.attr.get(props, "stop-opacity", "1")), 1.0), 0.0, 1.0), linear)},
          gradient.stops(tail, as, offset, linear)}, _ => gradient.stops(tail, as, previous, linear))

def gradient.mix(+a: Img.Color, +b: Img.Color, +t: F32) -> Img.Color:
  color.add(color.fade(a, (1.0 - t : F32)), color.fade(b, t))

def gradient.interval(xs: List<&2, Stop>, +previous: Stop, +t: F32) -> Img.Color:
  match xs:
    case Nil{}:
      Stop{o, c} = previous
      c
    case Con{Stop{o, c}, rest}:
      Stop{po, pc} = previous
      +offset = o
      +ink = c
      U.branch(Img.Color, F32.is_lt(t, offset),
        _ => gradient.mix(pc, ink, U.clamp(((t - po) / U.max(0.0000001, (offset - po : F32)) : F32), 0.0, 1.0)),
        _ => gradient.interval(rest, Stop{offset, ink}, t))

def gradient.color(xs: List<&2, Stop>, +t: F32) -> Img.Color:
  match xs:
    case Nil{}: Img.clear()
    case Con{Stop{o, c}, rest}:
      +ink = c
      +offset = o
      U.branch(Img.Color, F32.is_lt(t, offset), _ => ink,
        _ => gradient.interval(rest, Stop{offset, ink}, t))

def gradient.spread(+t: F32, +mode: U32) -> F32:
  +repeat = (t - F32.floor(t) : F32)
  +period = (t - 2.0 * F32.floor((t / 2.0 : F32)) : F32)
  U.choose(F32, U32.is_eq(mode, 1), repeat,
    U.choose(F32, U32.is_eq(mode, 2), (1.0 - F32.abs((period - 1.0 : F32)) : F32), U.clamp(t, 0.0, 1.0)))

def gradient.finish(c: Img.Color, opacity: F32, +linear: Bool) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +rr = r
  +gg = g
  +bb = b
  Img.rgba(U.choose(F32, linear, linear.srgb(rr), rr), U.choose(F32, linear, linear.srgb(gg), gg),
    U.choose(F32, linear, linear.srgb(bb), bb), (a * opacity : F32))

type Parameter is Data:
  Parameter{value: F32, valid: Bool}

def radial.roots(+a: F32, +b: F32, +c: F32, +fr: F32, +dr: F32) -> Parameter:
  +disc = (b * b - 4.0 * a * c : F32)
  +root = F32.sqrt(U.max(0.0, disc))
  +t0 = ((0.0 - b - root) / (2.0 * a) : F32)
  +t1 = ((0.0 - b + root) / (2.0 * a) : F32)
  +t = U.max(t0, t1)
  Parameter{t, F32.is_ge(disc, 0.0) && F32.is_ge((fr + t * dr : F32), 0.0)}

def radial.parameter(+p: Point, +start: Point, +end: Point, +r: F32, +fr: F32) -> Parameter:
  +q = point.sub(p, start)
  +d = point.sub(end, start)
  +dr = (r - fr : F32)
  +a = (point.dot(d, d) - dr * dr : F32)
  +b = (0.0 - 2.0 * (point.dot(q, d) + fr * dr) : F32)
  +c = (point.dot(q, q) - fr * fr : F32)
  U.branch(Parameter, F32.is_lt(r, 0.0000001), _ => Parameter{1.0, True{}},
    _ => U.branch(Parameter, F32.is_lt(F32.abs(a), 0.0000001),
      _ => Parameter{(0.0 - c / b : F32), F32.is_gt(F32.abs(b), 0.0000001)},
      _ => radial.roots(a, b, c, fr, dr)))

def linear.parameter(+p: Point, +start: Point, +end: Point) -> Parameter:
  +d = point.sub(end, start)
  +den = point.dot(d, d)
  Parameter{U.choose(F32, F32.is_lt(den, 0.0000000001), 1.0,
    (point.dot(point.sub(p, start), d) / den : F32)), True{}}

def gradient.at(param: Parameter, stops: List<&2, Stop>, spread: U32, opacity: F32, linear: Bool) -> Img.Color:
  Parameter{t, valid} = param
  U.branch(Img.Color, valid, _ => gradient.finish(gradient.color(stops, gradient.spread(t, spread)), opacity, linear), _ => Img.clear())

# Wrap coverage and paint coordinates by the same tile, including negative tiles.
def pattern.at(p: Point, +paintPoint: Point, +w: F32, +h: F32, opacity: F32,
  nodes: List<&2, Scene<Brush>>, paint: List<&2, Scene<Brush>> -> Point -> Point -> Img.Color) -> Img.Color:
  Point{x, y} = p
  +px = x
  +py = y
  +shift = {Point{(F32.floor((px / w : F32)) * w : F32), (F32.floor((py / h : F32)) * h : F32)} : Point}
  color.fade(paint(nodes)(point.sub(Point{px, py}, shift))(point.sub(paintPoint, shift)), opacity)

def brush.solid(+c: Img.Color, opacity: F32) -> Brush:
  Solid{color.fade(c, opacity), c}

def color.space(+c: Img.Color, linear: Bool) -> Img.Color:
  Img.Color{r, g, b, a} = c
  U.branch(Img.Color, linear,
    _ => Img.Color{(srgb.linear((r / U.max(a, 0.0000001) : F32)) * a : F32),
      (srgb.linear((g / U.max(a, 0.0000001) : F32)) * a : F32),
      (srgb.linear((b / U.max(a, 0.0000001) : F32)) * a : F32), a}, _ => c)

def raster.pixel(+r: Raster, +x: F32, +y: F32) -> Img.Color:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = r
  U.branch(Img.Color, F32.is_ge(x, 0.0) && F32.is_ge(y, 0.0) && F32.is_lt(x, U32.to_f32(width)) && F32.is_lt(y, U32.to_f32(height)),
    _ => Img.pixels.get(pixels, U32.shln(1, depth), F32.to_u32(x), F32.to_u32(y)), _ => Img.clear())

def color.mix(a: Img.Color, b: Img.Color, +t: F32) -> Img.Color:
  color.add(color.fade(a, (1.0 - t : F32)), color.fade(b, t))

def raster.horizontal(+r: Raster, +x: F32, +y: F32, +dx: F32) -> Img.Color:
  U.branch(Img.Color, F32.is_eq(dx, 0.0), _ => raster.pixel(r, x, y),
    _ => color.mix(raster.pixel(r, x, y), raster.pixel(r, (x + 1.0 : F32), y), dx))

def raster.sample(+r: Raster, p: Point) -> Img.Color:
  Raster{Point{ox, oy}, step, width, height, depth, pixelsLinear, pixels} = r
  Point{x, y} = p
  +fx = ((x - ox) / step - 0.5 : F32)
  +fy = ((y - oy) / step - 0.5 : F32)
  +ix = F32.floor(fx)
  +iy = F32.floor(fy)
  +dx = (fx - ix : F32)
  +dy = (fy - iy : F32)
  U.branch(Img.Color, F32.is_eq(dy, 0.0), _ => raster.horizontal(r, ix, iy, dx),
    _ => color.mix(raster.horizontal(r, ix, iy, dx), raster.horizontal(r, ix, (iy + 1.0 : F32), dx), dy))

def color.from.linear(+c: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{(linear.srgb((r / U.max(a, 0.0000001) : F32)) * a : F32), (linear.srgb((g / U.max(a, 0.0000001) : F32)) * a : F32), (linear.srgb((b / U.max(a, 0.0000001) : F32)) * a : F32), a}

def raster.color(+r: Raster, p: Point, +linear: Bool) -> Img.Color:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = r
  +c = raster.sample(r, p)
  U.branch(Img.Color, U.choose(Bool, pixelsLinear, linear, Bool.not(linear)), _ => c,
    _ => U.branch(Img.Color, pixelsLinear, _ => color.from.linear(c), _ => color.space(c, True{})))

def raster.image(image: Img.Picture) -> Raster:
  Img.Picture{w, h, depth, pixels} = image
  Raster{Point{0.0, 0.0}, 1.0, w, h, depth, False{}, pixels}

def bitmap.bytes(+mime: String, +data: String) -> Bin.Bytes:
  U.branch(Bin.Bytes, U.string.contains(mime, ";base64"), _ => Bin.base64(data), _ => Bin.uri.bytes(data, Bin.bytes.empty()))

def bitmap.empty() -> Raster:
  Raster{Point{0.0, 0.0}, 1.0, 0, 0, 0n, False{}, Img.Flat{Img.clear()}}

def bitmap.uri(scan: U.Scan) -> Raster:
  U.Scan{header, content} = scan
  +mime = CSS.css.lower(header)
  +data = content
  U.branch(Raster, U.prefix(mime, "image/png") || U.prefix(mime, "image/apng"),
    _ => raster.image(PNG.png.decode(bitmap.bytes(mime, data))), _ => U.branch(Raster, U.prefix(mime, "image/jpeg") || U.prefix(mime, "image/jpg"), _ => raster.image(JPEG.jpeg.decode(bitmap.bytes(mime, data))), _ => bitmap.empty()))

def bitmap.decode(+href: String) -> Raster:
  U.branch(Raster, U.prefix(href, "data:"), _ => bitmap.uri(U.until(U.drop(href, "data:"), 44, "")), _ => bitmap.empty())

# Inverse F32 transforms can place an exact texel boundary a few ulps above
# its integer value. Snap only that rounding neighborhood before tie-breaking.
def bitmap.nearest(+q: F32) -> F32:
  +integer = F32.floor((q + 0.5 : F32))
  +close = F32.is_le(F32.abs((q - integer : F32)), (U.max(1.0, F32.abs(q)) * 0.000000476837158203125 : F32))
  F32.ceil((U.choose(F32, close, integer, q) - 1.0 : F32))

def bitmap.sample(+raster: Raster, +p: Point, +center: Point, nearest: Bool) -> Img.Color:
  Raster{origin, step, width, height, depth, linear, pixels} = raster
  Point{x, y} = p
  Point{cx, cy} = center
  +w = U32.to_f32(width)
  +h = U32.to_f32(height)
  U.branch(Img.Color, nearest, _ => raster.pixel(raster, U.clamp(bitmap.nearest(cx), 0.0, (w - 1.0 : F32)), U.clamp(bitmap.nearest(cy), 0.0, (h - 1.0 : F32))),
    _ => raster.sample(raster, Point{U.clamp(cx, 0.5, (w - 0.5 : F32)), U.clamp(cy, 0.5, (h - 0.5 : F32))}))

# Pattern tiles (see cover.brush): wrap into the tile and read its raster
# bilinearly, wrapping at the seams so neighbouring tiles join without a border.
def tile.wrap(+q: F32, +size: F32) -> F32:
  (q - F32.floor((q / size : F32)) * size : F32)

def tile.index(+i: F32, +n: U32) -> U32:
  U32.mod(F32.to_u32((i + U32.to_f32(n) : F32)), n)

def tile.corner(+pixels: Img.Pixels, +side: U32, +x: U32, +y: U32, +weight: F32) -> Img.Color:
  color.fade(Img.pixels.get(pixels, side, x, y), weight)

def tile.blend(+pixels: Img.Pixels, +side: U32, +width: U32, +height: U32, +fx: F32, +fy: F32) -> Img.Color:
  +ix = F32.floor(fx)
  +iy = F32.floor(fy)
  +dx = (fx - ix : F32)
  +dy = (fy - iy : F32)
  +x0 = tile.index(ix, width)
  +x1 = tile.index((ix + 1.0 : F32), width)
  +y0 = tile.index(iy, height)
  +y1 = tile.index((iy + 1.0 : F32), height)
  color.add(color.add(tile.corner(pixels, side, x0, y0, ((1.0 - dx) * (1.0 - dy) : F32)), tile.corner(pixels, side, x1, y0, (dx * (1.0 - dy) : F32))),
    color.add(tile.corner(pixels, side, x0, y1, ((1.0 - dx) * dy : F32)), tile.corner(pixels, side, x1, y1, (dx * dy : F32))))

def tile.cell(+x: F32, +w: F32, +n: U32) -> U32:
  U32.mod(F32.to_u32(F32.floor((tile.wrap(x, w) * U32.to_f32(n) / w : F32))), n)

# Nearest tile pixel under a pattern-space point.
def tile.read(+pixels: Img.Pixels, +side: U32, +wd: U32, +ht: U32, +w: F32, +h: F32, q: Point) -> Img.Color:
  Point{x, y} = q
  Img.pixels.get(pixels, side, tile.cell(x, w, wd), tile.cell(y, h, ht))

# Sum of grid by grid nearest reads spread over the pixel footprint (u, v).
@unsafe
def tile.grid(+pixels: Img.Pixels, +side: U32, +wd: U32, +ht: U32, +w: F32, +h: F32, +q: Point, +u: Point, +v: Point, +grid: U32, n: Nat, +i: U32, acc: Img.Color) -> Img.Color:
  match n:
    case 0n: acc
    case 1n+d:
      +gx = ((U32.to_f32(U32.mod(i, grid)) + 0.5) / U32.to_f32(grid) - 0.5 : F32)
      +gy = ((U32.to_f32(U32.div(i, grid)) + 0.5) / U32.to_f32(grid) - 0.5 : F32)
      tile.grid(pixels, side, wd, ht, w, h, q, u, v, grid, d, (i + 1 : U32), color.add(acc, tile.read(pixels, side, wd, ht, w, h, point.add(q, point.add(point.scale(u, gx), point.scale(v, gy))))))

# A grid of one reads the tile bilinearly at the point (aligned tiles at device
# density); a larger grid averages nearest reads of a denser tile over the
# device pixel's footprint, the pattern-space vectors u and v.
def tile.sample(+r: Raster, +q: Point, +w: F32, +h: F32, +opacity: F32, +u: Point, +v: Point, +grid: U32) -> Img.Color:
  Raster{origin, step, width, height, depth, linear, pixels} = r
  Point{x, y} = q
  +wd = width
  +ht = height
  +px = pixels
  +side = U32.shln(1, depth)
  U.branch(Img.Color, U32.is_eq(wd, 0) || U32.is_eq(ht, 0), _ => Img.clear(),
    _ => color.fade(U.branch(Img.Color, U32.is_le(grid, 1),
      _ => tile.blend(px, side, wd, ht, (tile.wrap(x, w) * U32.to_f32(wd) / w - 0.5 : F32), (tile.wrap(y, h) * U32.to_f32(ht) / h - 0.5 : F32)),
      _ => color.fade(tile.grid(px, side, wd, ht, w, h, Point{x, y}, u, v, grid, U32.to_nat((grid * grid : U32)), 0, Img.clear()), (1.0 / U32.to_f32((grid * grid : U32)) : F32))), opacity))

def brush.sample(brush: Brush, +p: Point, +paintPoint: Point, next: List<&2, Scene<Brush>> -> Point -> Point -> Img.Color) -> Img.Color:
  match brush:
    case Solid{c, source}: c
    case Bitmap{raster, inv, nearest}:
      +mat = inv
      bitmap.sample(raster, matrix.point(mat, p), matrix.point(mat, paintPoint), nearest)
    case PendingContext{stroke, opacity}: Img.clear()
    case ContextPaint{source, matrix, opacity}:
      +mat = matrix
      color.fade(brush.sample(source, matrix.point(mat, p), matrix.point(mat, paintPoint), next), opacity)
    case Pattern{inv, w, h, opacity, nodes}:
      +matrix = inv
      pattern.at(matrix.point(matrix, p), matrix.point(matrix, paintPoint), w, h, opacity, nodes, next)
    case Tile{raster, inv, w, h, opacity, u, v, grid}: tile.sample(raster, matrix.point(inv, p), w, h, opacity, u, v, grid)
    case Gradient{inv, radial, start, end, radius, fr, stops, spread, opacity, linear}:
      +q = matrix.point(inv, paintPoint)
      +a = start
      +b = end
      gradient.at(U.choose(Parameter, radial, radial.parameter(q, a, b, radius, fr), linear.parameter(q, a, b)),
        stops, spread, opacity, linear)

def gradient.box(b: Bounds) -> Matrix:
  Bounds{x0, y0, x1, y1} = b
  +x = x0
  +y = y0
  matrix.mul(translate(x, y), scale((x1 - x : F32), (y1 - y : F32)))

def gradient.build(e: XML.Element, +box: Bounds, +w: F32, +h: F32, opacity: F32) -> Brush:
  XML.Element{n, attrs, kids, txt} = e
  +as = CSS.properties(attrs)
  +user = U.string.equal(XML.attr.get(as, "gradientUnits", "objectBoundingBox"), "userSpaceOnUse")
  +vw = U.choose(F32, user, w, 1.0)
  +vh = U.choose(F32, user, h, 1.0)
  +linear = U.string.equal(XML.attr.get(as, "color-interpolation", "sRGB"), "linearRGB")
  +radial = U.string.equal(n, "radialGradient")
  +cx = dimension(as, "cx", vw, "50%")
  +cy = dimension(as, "cy", vh, "50%")
  +radiusRef = F32.sqrt(((vw * vw + vh * vh) / 2.0 : F32))
  Gradient{matrix.inverse(matrix.mul(U.choose(Matrix, user, identity(), gradient.box(box)),
    transform(XML.attr.get(as, "gradientTransform", ""), identity()))), radial,
    U.choose(Point, radial, Point{dimension(as, "fx", vw, F32.show(cx)), dimension(as, "fy", vh, F32.show(cy))},
      Point{dimension(as, "x1", vw, "0%"), dimension(as, "y1", vh, "0%")}),
    U.choose(Point, radial, Point{cx, cy}, Point{dimension(as, "x2", vw, "100%"), dimension(as, "y2", vh, "0%")}),
    dimension(as, "r", radiusRef, "50%"), dimension(as, "fr", radiusRef, "0%"),
    gradient.stops(kids, as, 0.0, linear),
    U.choose(U32, U.string.equal(XML.attr.get(as, "spreadMethod", "pad"), "repeat"), 1,
      U.choose(U32, U.string.equal(XML.attr.get(as, "spreadMethod", "pad"), "reflect"), 2, 0)), opacity, linear}

def gradient.is.valid(e: XML.Element) -> Bool:
  XML.Element{n, as, kids, txt} = e
  +tag = n
  U.string.equal(tag, "linearGradient") || U.string.equal(tag, "radialGradient")

def brush.resource(result: Maybe<&2, XML.Element>, +all: List<&2, XML.Element>, +box: Bounds, +w: F32, +h: F32,
  +opacity: F32, fallback: String, patterns: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush) -> Brush:
  match result:
    case None{}: brush.solid(color(fallback), opacity)
    case Some{XML.Element{tagname, as, kids, txt}}:
      +tag = tagname
      +node = {XML.Element{tag, as, kids, txt} : XML.Element}
      U.branch(Brush, gradient.is.valid(node), _ => gradient.build(gradient.resolve(32n, node, all), box, w, h, opacity),
        _ => U.branch(Brush, U.string.equal(tag, "pattern"), _ => patterns(node)(box)(w)(h)(opacity),
          _ => brush.solid(color(fallback), opacity)))

def brush.url(+scan: U.Scan, +all: List<&2, XML.Element>, box: Bounds, w: F32, h: F32, opacity: F32, patterns: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush) -> Brush:
  U.Scan{url, fallback} = scan
  brush.resource(resource.find(all, U.drop(U.unquote(U.trim.both(url)), "#")), all, box, w, h, opacity,
    U.choose(String, U.string.equal(U.trim(fallback), ""), "none", U.trim(fallback)), patterns)

# A paint's keyword, decided from its first letter: 1 currentcolor,
# 2 context-fill, 3 context-stroke, 0 a color or none.
def paint.keyword.head(s: String) -> U32:
  match s:
    case SNil{}: 0
    case SCon{Chr{c}, t}:
      +ch = c
      +rest = t
      U.choose(U32, U32.is_eq(U32.or(ch, 32), 99), U.choose(U32, keyword.rest("urrentcolor", rest), 1, U.choose(U32, keyword.rest("ontext-fill", rest), 2, U.choose(U32, keyword.rest("ontext-stroke", rest), 3, 0))), 0)

def paint.keyword(s: String) -> U32:
  paint.keyword.head(U.trim(s))

def brush.keyword(+k: U32, +s: String, current: String, +opacity: F32) -> Brush:
  U.choose(Brush, U32.is_eq(k, 2) || U32.is_eq(k, 3), PendingContext{U32.is_eq(k, 3), opacity},
    brush.solid(color(U.choose(String, U32.is_eq(k, 1), current, s)), opacity))

def brush(+s: String, current: String, +opacity: F32, +all: List<&2, XML.Element>, box: Bounds, w: F32, h: F32, patterns: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush) -> Brush:
  U.branch(Brush, U.prefix(s, "url("), _ => brush.url(U.until(U.drop(s, "url("), 41, ""), all, box, w, h, opacity, patterns),
    _ => brush.keyword(paint.keyword(s), s, current, opacity))

def style.colors(+s: Style, +all: List<&2, XML.Element>, +box: Bounds, +w: F32, +h: F32, fills: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush, strokes: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush) -> Paint<Brush>:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  Paint{brush(fill, col, fo, all, box, w, h, fills), brush(stroke, col, so, all, box, w, h, strokes)}

# Clip paths combine geometry by union; nested clip paths intersect coverage.
def clip.inside(c: Clip, +p: Point) -> Bool:
  match c:
    case ClipAll{}: True{}
    case ClipShape{es, inv, even, cover}: edge.tree.inside(es, matrix.point(inv, p), even)
    case ClipUnion{a, b}: clip.inside(a, p) || clip.inside(b, p)
    case ClipIntersect{a, b}: clip.inside(a, p) && clip.inside(b, p)

# Clip coverage: unions add as independent areas, intersections multiply.
def clip.cover(c: Clip, +p: Point) -> F32:
  match c:
    case ClipAll{}: 1.0
    case ClipShape{es, inv, even, cover}:
      +cov = cover
      U.branch(F32, cover.present(cov), _ => cover.at(cov, p), _ => U.choose(F32, edge.tree.inside(es, matrix.point(inv, p), even), 1.0, 0.0))
    case ClipUnion{a, b}:
      +u = clip.cover(a, p)
      +v = clip.cover(b, p)
      (u + v - u * v : F32)
    case ClipIntersect{a, b}: (clip.cover(a, p) * clip.cover(b, p) : F32)

def clip.fade(+cov: F32, render: Unit -> Img.Color) -> Img.Color:
  U.branch(Img.Color, F32.is_gt(cov, 0.0), _ => color.fade(render(Unit{}), cov), _ => Img.clear())

def clip.empty() -> Clip:
  ClipShape{edge.tree.empty(), identity(), False{}, cover.none()}

def clip.reference(result: Maybe<&2, XML.Element>, +box: Bounds, +m: Matrix,
  build: List<&2, XML.Element> -> Matrix -> Clip) -> Clip:
  match result:
    case None{}: ClipAll{}
    case Some{XML.Element{n, as, kids, txt}}:
      +tag = n
      +attrs = as
      U.branch(Clip, U.string.equal(tag, "clipPath"),
        _ => build(Con{XML.Element{tag, attrs, kids, txt}, Nil{}})(matrix.mul(m,
          U.choose(Matrix, U.string.equal(XML.attr.get(attrs, "clipPathUnits", "userSpaceOnUse"), "objectBoundingBox"),
            gradient.box(box), identity()))), _ => ClipAll{})

def clip.attach(+as: List<&2, XML.Attr>, +all: List<&2, XML.Element>, box: Bounds, m: Matrix,
  build: List<&2, XML.Element> -> Matrix -> Clip) -> Clip:
  +value = XML.attr.get(as, "clip-path", "none")
  U.branch(Clip, U.prefix(value, "url("),
    _ => clip.reference(resource.find(all, U.drop(U.unquote(U.trim.both(U.scan.head(U.until(U.drop(value, "url("), 41, "")))), "#")),
      box, m, build), _ => ClipAll{})

@unsafe
def clip.build(fuel: Nat, +xs: List<&2, XML.Element>, +all: List<&2, XML.Element>, +m: Matrix,
  +w: F32, +h: F32, +even: Bool, +scale: F32) -> Clip:
  match fuel:
    case 0n: clip.empty()
    case 1n+d:
      match xs:
        case Nil{}: clip.empty()
        case Con{XML.Element{n, attrs, kids, txt}, rest}:
          +dd = d
          +as = CSS.properties(attrs)
          +matrix = matrix.mul(matrix.mul(m, transform(XML.attr.get(as, "transform", ""), identity())),
            U.choose(Matrix, U.string.equal(n, "use"), translate(dimension(as, "x", w, "0"), dimension(as, "y", h, "0")), identity()))
          +rule = U.string.equal(XML.attr.get(as, "clip-rule", U.choose(String, even, "evenodd", "nonzero")), "evenodd")
          +es = shape.children(n, as, kids, w, h, local.tolerance(matrix, scale), XML.attr.get(as, "d", ""))
          +box = bounds(es, Bounds{1000000000.0, 1000000000.0, F32.neg(1000000000.0), F32.neg(1000000000.0)})
          U.branch(Clip, U.string.equal(XML.attr.get(as, "display", "inline"), "none"),
            _ => clip.build(1n+dd, rest, all, m, w, h, even, scale),
            _ => ClipUnion{ClipIntersect{
              ClipUnion{ClipShape{edge.tree(es), matrix.inverse(matrix), rule, cover.none()}, clip.build(1n+dd, kids, all, matrix, w, h, rule, scale)},
              clip.attach(as, all, box, matrix, nodes => mat => clip.build(dd, nodes, all, mat, w, h, False{}, scale))},
              clip.build(1n+dd, rest, all, m, w, h, even, scale)})

def clip.compile(as: List<&2, XML.Attr>, +all: List<&2, XML.Element>, box: Bounds, m: Matrix, +w: F32, +h: F32, +scale: F32) -> Clip:
  clip.attach(as, all, box, m, nodes => mat => clip.build(128n, nodes, all, mat, w, h, False{}, scale))

def style.nonScaling(s: Style) -> Bool:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  StrokeSettings{cap, join, limit, dash, offset, vector} = ss
  U.string.equal(vector, "non-scaling-stroke")

def style.outline(+s: Style, +es: List<&2, Edge>, +m: Matrix, ref: F32, declared: F32) -> StrokeMesh:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  +screen = style.nonScaling(s)
  stroke.mesh(U.branch(List<&2, Edge>, U.string.equal(stroke, "none") || F32.is_le(width, 0.0), _ => Nil{},
    _ => stroke.compile(U.choose(List<&2, Edge>, screen, edges.transform(es, m), es), (width / 2.0 : F32), ss, ref, declared, U.choose(F32, screen, 1.0, matrix.norm(m)))),
    U.choose(Matrix, screen, identity(), matrix.inverse(m)))

def bounds.transformed(es: List<&2, Edge>, +m: Matrix, box: Bounds) -> Bounds:
  match es:
    case Nil{}: box
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}:
      bounds.transformed(rest, m, bounds.point(bounds.point(box, matrix.point(m, Point{ax, ay})), matrix.point(m, Point{bx, by})))

# These bounds enclose rendered coverage, including descendant strokes and
# markers. They are distinct from objectBoundingBox paint coordinates.
def bounds.finite(b: Bounds) -> Bool:
  Bounds{x0, y0, x1, y1} = b
  F32.is_lt(F32.abs(x0), 1.0e25) && F32.is_lt(F32.abs(y0), 1.0e25) && F32.is_lt(F32.abs(x1), 1.0e25) && F32.is_lt(F32.abs(y1), 1.0e25)

def bounds.safe(+box: Bounds) -> Bounds:
  U.choose(Bounds, bounds.finite(box), box, Bounds{F32.neg(1.0e30), F32.neg(1.0e30), 1.0e30, 1.0e30})

def bounds.transform(box: Bounds, +mat: Matrix) -> Bounds:
  Bounds{x0, y0, x1, y1} = box
  +left = x0
  +top = y0
  +right = x1
  +bottom = y1
  # Include the local stroke tests' tolerances before transforming the corners.
  +a = (left - 0.0001 : F32)
  +b = (top - 0.0001 : F32)
  +c = (right + 0.0001 : F32)
  +d = (bottom + 0.0001 : F32)
  U.branch(Bounds, F32.is_gt(left, right) || F32.is_gt(top, bottom), _ => bounds.empty(),
    _ => bounds.safe(bounds.point(bounds.point(bounds.point(bounds.point(bounds.empty(), matrix.point(mat, Point{a, b})), matrix.point(mat, Point{c, b})), matrix.point(mat, Point{a, d})), matrix.point(mat, Point{c, d}))))

# A child's box already holds its own children, so the parent's box is the
# union of the children's boxes brought into its space.
def scene.bounds(xs: List<&2, Scene<Brush>>, +parentInverse: Matrix, box: Bounds) -> Bounds:
  match xs:
    case Nil{}: box
    case Con{Scene{es, childbox, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      scene.bounds(rest, parentInverse, bounds.merge(box, bounds.transform(childbox, matrix.mul(parentInverse, matrix.inverse(inv)))))

def bounds.spec(+as: List<&2, XML.Attr>, box: Bounds) -> Bounds:
  +value = XML.attr.get(as, "#paint-box", "")
  +vs = U.numbers(value)
  U.choose(Bounds, U.string.equal(value, ""), box, Bounds{U.nth(vs, 0n, 0.0), U.nth(vs, 1n, 0.0), U.nth(vs, 2n, 0.0), U.nth(vs, 3n, 0.0)})

def filter.dimension(+as: List<&2, XML.Attr>, +key: String, +ref: F32, +fallback: String, user: Bool) -> F32:
  U.branch(F32, user, _ => dimension(as, key, ref, fallback), _ => (dimension(as, key, 1.0, fallback) * ref : F32))

def filter.region(+as: List<&2, XML.Attr>, box: Bounds, +w: F32, +h: F32, +primitiveBox: Bool) -> Bounds:
  Bounds{x0, y0, x1, y1} = box
  +bx = x0
  +by = y0
  +bw = (x1 - bx : F32)
  +bh = (y1 - by : F32)
  +user = U.string.equal(XML.attr.get(as, "filterUnits", "objectBoundingBox"), "userSpaceOnUse")
  +fw = U.choose(F32, user, w, bw)
  +fh = U.choose(F32, user, h, bh)
  +x = (U.choose(F32, user, 0.0, bx) + filter.dimension(as, "x", fw, "-10%", user) : F32)
  +y = (U.choose(F32, user, 0.0, by) + filter.dimension(as, "y", fh, "-10%", user) : F32)
  +width = filter.dimension(as, "width", fw, "120%", user)
  +height = filter.dimension(as, "height", fh, "120%", user)
  U.branch(Bounds, (user || (F32.is_gt(bw, 0.0) && F32.is_gt(bh, 0.0))) && (Bool.not(primitiveBox) || (F32.is_gt(bw, 0.0) && F32.is_gt(bh, 0.0))),
    _ => U.branch(Bounds, primitiveBox, _ => Bounds{((x - bx) / bw : F32), ((y - by) / bh : F32), ((x + width - bx) / bw : F32), ((y + height - by) / bh : F32)},
      _ => Bounds{x, y, (x + width : F32), (y + height : F32)}), _ => bounds.empty())

def filter.resource(result: Maybe<&2, XML.Element>, +box: Bounds, m: Matrix, +w: F32, +h: F32) -> FilterEffect:
  match result:
    case None{}: NoFilter{}
    case Some{XML.Element{name, attrs, kids, txt}}:
      +as = CSS.properties(attrs)
      +object = U.string.equal(XML.attr.get(as, "primitiveUnits", "userSpaceOnUse"), "objectBoundingBox")
      U.branch(FilterEffect, U.string.equal(name, "filter"), _ => FilterSpec{filter.region(as, box, w, h, object), matrix.mul(m, U.choose(Matrix, object, gradient.box(box), identity())), Point{U.choose(F32, object, 1.0, w), U.choose(F32, object, 1.0, h)}, as, kids}, _ => NoFilter{})

def filter.spec(+as: List<&2, XML.Attr>, all: List<&2, XML.Element>, box: Bounds, m: Matrix, w: F32, h: F32) -> FilterEffect:
  +value = U.trim.both(XML.attr.get(as, "filter", "none"))
  +id = U.drop(U.unquote(U.trim.both(U.scan.head(U.until(U.drop(value, "url("), 41, "")))), "#")
  U.branch(FilterEffect, U.prefix(value, "url("), _ => filter.resource(resource.find(all, id), box, m, w, h), _ => NoFilter{})

def scene.make(+es: List<&2, Edge>, +m: Matrix, +s: Style, opacity: F32, +children: List<&2, Scene<Brush>>, id: String,
  +all: List<&2, XML.Element>, +w: F32, +h: F32, +as: List<&2, XML.Attr>, fills: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush, strokes: XML.Element -> Bounds -> F32 -> F32 -> F32 -> Brush, +scale: F32) -> Scene<Brush>:
  +f = fill.new(es)
  +box = bounds.spec(as, scene.bounds(children, matrix.inverse(m), fill.bounds(f)))
  Scene{es, box, matrix.inverse(m), s, opacity, children, id, style.colors(s, all, box, w, h, fills, strokes), clip.compile(as, all, box, m, w, h, scale), style.outline(s, es, m, F32.sqrt(((w * w + h * h) / 2.0 : F32)), U.scalar(XML.attr.get(as, "pathLength", "0"), 0.0)), f, Nil{}, 0, Nil{}, bounds.empty(), filter.spec(as, all, box, m, w, h)}

# SVG viewports establish local units and intersect their children with overflow clips.
def viewbox.matrix(+v: List<&2, F32>, +w: F32, +h: F32, +aspect: String) -> Matrix:
  +x = U.nth(v, 0n, 0.0)
  +y = U.nth(v, 1n, 0.0)
  +vw = U.nth(v, 2n, w)
  +vh = U.nth(v, 3n, h)
  +sx = (w / U.max(0.000001, vw) : F32)
  +sy = (h / U.max(0.000001, vh) : F32)
  +s = U.choose(F32, U.prefix(U.through(aspect, " "), "slice"), U.max(sx, sy), U.min(sx, sy))
  +tx = U.choose(F32, U.prefix(aspect, "xMin"), 0.0, U.choose(F32, U.prefix(aspect, "xMax"), 1.0, 0.5))
  +ty = U.choose(F32, U.prefix(U.drop(aspect, "xxxx"), "YMin"), 0.0,
    U.choose(F32, U.prefix(U.drop(aspect, "xxxx"), "YMax"), 1.0, 0.5))
  U.branch(Matrix, U.string.equal(aspect, "none"), _ => matrix.mul(scale(sx, sy), translate(F32.neg(x), F32.neg(y))),
    _ => matrix.mul(translate(((w - vw * s) * tx : F32), ((h - vh * s) * ty : F32)),
      matrix.mul(scale(s, s), translate(F32.neg(x), F32.neg(y)))))

type EmbeddedImage is Data:
  NoImage{}
  EmbeddedImage{raster: Raster, attrs: List<&2, XML.Attr>, inverse: Matrix, nearest: Bool}

def bitmap.layout(+raster: Raster, +as: List<&2, XML.Attr>, +vw: F32, +vh: F32) -> EmbeddedImage:
  Raster{origin, step, width, height, depth, linear, pixels} = raster
  +iw = U32.to_f32(width)
  +ih = U32.to_f32(height)
  +aw = XML.attr.get(as, "width", "auto")
  +ah = XML.attr.get(as, "height", "auto")
  +autoW = U.string.equal(aw, "auto")
  +autoH = U.string.equal(ah, "auto")
  +rw = dimension(as, "width", vw, "0")
  +rh = dimension(as, "height", vh, "0")
  +w = U.choose(F32, autoW, U.choose(F32, autoH, iw, (rh * iw / U.max(ih, 0.000001) : F32)), rw)
  +h = U.choose(F32, autoH, U.choose(F32, autoW, ih, (rw * ih / U.max(iw, 0.000001) : F32)), rh)
  +attrs = {Con{XML.Attr{"width", F32.show(w)}, Con{XML.Attr{"height", F32.show(h)}, as}} : List<&2, XML.Attr>}
  +inv = matrix.inverse(matrix.mul(translate(dimension(as, "x", vw, "0"), dimension(as, "y", vh, "0")), viewbox.matrix(Con{0.0, Con{0.0, Con{iw, Con{ih, Nil{}}}}}, w, h, U.trim.both(XML.attr.get(as, "preserveAspectRatio", "xMidYMid meet")))))
  +rendering = XML.attr.get(as, "image-rendering", "auto")
  EmbeddedImage{raster, attrs, inv, U.string.equal(rendering, "pixelated") || U.string.equal(rendering, "crisp-edges") || U.string.equal(rendering, "optimizeSpeed")}

def style.image.rendering(s: Style) -> String:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  rendering

def bitmap.element(+name: String, +as: List<&2, XML.Attr>, w: F32, h: F32) -> EmbeddedImage:
  U.branch(EmbeddedImage, U.string.equal(name, "image"), _ => bitmap.layout(bitmap.decode(XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", ""))), as, w, h), _ => NoImage{})

def bitmap.attrs(image: EmbeddedImage, fallback: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match image:
    case NoImage{}: fallback
    case EmbeddedImage{raster, attrs, inv, nearest}: attrs

def style.image(s: Style) -> Style:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  Style{"white", "none", col, 1.0, 1.0, 0.0, False{}, visible, ss, MarkerStyle{"none", "none", "none"}, rendering, order}

def bitmap.style(image: EmbeddedImage, style: Style) -> Style:
  match image:
    case NoImage{}: style
    case EmbeddedImage{raster, attrs, inv, nearest}: style.image(style)

def style.is.visible(s: Style) -> Bool:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  visible

def style.embedded(s: Style) -> Style:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  Style{"none", "none", col, 1.0, 1.0, 0.0, False{}, visible, ss, MarkerStyle{"none", "none", "none"}, rendering, order}

def bitmap.paint(image: EmbeddedImage, ink: Paint<Brush>) -> Paint<Brush>:
  match image:
    case NoImage{}: ink
    case EmbeddedImage{raster, attrs, inv, nearest}: Paint{Bitmap{raster, inv, nearest}, brush.solid(Img.clear(), 1.0)}

def scene.bitmap(scene: Scene<Brush>, image: EmbeddedImage) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, masks, maskMode, markers, coverage, effect} = scene
  Scene{es, box, inv, style, opacity, kids, id, bitmap.paint(image, ink), clip, outline, fillTree, masks, maskMode, markers, coverage, effect}

type Viewport is Data:
  Viewport{matrix: Matrix, width: F32, height: F32, clip: Clip, valid: Bool}

def viewport.clip(+w: F32, +h: F32, m: Matrix) -> Clip:
  ClipShape{edge.tree(path(shape.rect.path(0.0, 0.0, w, h, 0.0, 0.0), 1.0)), matrix.inverse(m), False{}, cover.none()}

def viewport.dimension(+as: List<&2, XML.Attr>, key: String, +ref: F32) -> F32:
  +value = XML.attr.get(as, key, "auto")
  U.branch(F32, U.string.equal(value, "auto"), _ => ref, _ => U.unit(U.number(value), ref))

def image.layout.sized(+as: List<&2, XML.Attr>, +values: List<&2, F32>, +vw: F32, +vh: F32) -> List<&2, XML.Attr>:
  +iw = U.nth(values, 0n, 300.0)
  +ih = U.nth(values, 1n, 150.0)
  +ratio = U.nth(values, 2n, 0.0)
  +aw = U.string.equal(XML.attr.get(as, "width", "auto"), "auto")
  +ah = U.string.equal(XML.attr.get(as, "height", "auto"), "auto")
  +rw = dimension(as, "width", vw, "0")
  +rh = dimension(as, "height", vh, "0")
  +w = U.choose(F32, aw, U.choose(F32, ah, iw, U.choose(F32, F32.is_gt(ratio, 0.0), (rh * ratio : F32), iw)), rw)
  +h = U.choose(F32, ah, U.choose(F32, aw, ih, U.choose(F32, F32.is_gt(ratio, 0.0), (rw / U.max(ratio, 0.000001) : F32), ih)), rh)
  Con{XML.Attr{"width", F32.show(w)}, Con{XML.Attr{"height", F32.show(h)}, as}}

def image.layout.attrs(+as: List<&2, XML.Attr>, +w: F32, +h: F32) -> List<&2, XML.Attr>:
  +size = XML.attr.get(as, "#image-size", "")
  U.branch(List<&2, XML.Attr>, U.string.equal(size, ""), _ => as, _ => image.layout.sized(as, U.numbers(size), w, h))

def element.viewport(+name: String, raw: List<&2, XML.Attr>, +m: Matrix, +w: F32, +h: F32, +root: Bool) -> Viewport:
  +as = image.layout.attrs(raw, w, h)
  +base = matrix.mul(m, transform(XML.attr.get(as, "transform", ""), identity()))
  +svg = U.string.equal(name, "svg")
  +width = U.choose(F32, root, w, viewport.dimension(as, "width", w))
  +height = U.choose(F32, root, h, viewport.dimension(as, "height", h))
  +origin = matrix.mul(base, U.choose(Matrix, root, identity(),
    translate(dimension(as, "x", w, "0"), dimension(as, "y", h, "0"))))
  +view = U.numbers(XML.attr.get(as, "viewBox", ""))
  +vw = U.nth(view, 2n, width)
  +vh = U.nth(view, 3n, height)
  U.branch(Viewport, svg, _ => Viewport{
      matrix.mul(origin, viewbox.matrix(view, width, height, U.trim.both(XML.attr.get(as, "preserveAspectRatio", "xMidYMid meet")))), vw, vh,
      U.branch(Clip, U.string.equal(XML.attr.get(as, "overflow", "hidden"), "visible"), _ => ClipAll{}, _ => viewport.clip(width, height, origin)),
      F32.is_gt(width, 0.0) && F32.is_gt(height, 0.0) && F32.is_gt(vw, 0.0) && F32.is_gt(vh, 0.0)},
    _ => Viewport{U.branch(Matrix, U.string.equal(name, "use"),
      _ => matrix.mul(base, translate(dimension(as, "x", w, "0"), dimension(as, "y", h, "0"))), _ => base), w, h, ClipAll{}, True{}})

def scene.clipped(scene: Scene<Brush>, viewportClip: Clip) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect} = scene
  Scene{es, box, inv, style, opacity, kids, id, ink, ClipIntersect{mask, viewportClip}, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}

def element.hidden(+name: String, as: List<&2, XML.Attr>) -> Bool:
  U.string.equal(name, "#text") || U.string.equal(name, "defs") || U.string.equal(name, "title") || U.string.equal(name, "desc")
    || U.string.equal(name, "metadata") || U.string.equal(name, "clipPath") || U.string.equal(name, "mask")
    || U.string.equal(name, "symbol") || U.string.equal(name, "linearGradient") || U.string.equal(name, "radialGradient")
    || U.string.equal(name, "marker") || U.string.equal(name, "pattern") || U.string.equal(name, "filter") || U.string.equal(name, "style")
    || U.string.equal(XML.attr.get(as, "display", "inline"), "none")

def instance.anonymous(xs: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      Con{XML.Element{n, Con{XML.Attr{"#editor-id", ""}, as}, instance.anonymous(kids), txt}, instance.anonymous(rest)}

def instance.root(result: Maybe<&2, XML.Element>, +useAttrs: List<&2, XML.Attr>) -> List<&2, XML.Element>:
  match result:
    case None{}: Nil{}
    case Some{XML.Element{n, attrs, kids, txt}}:
      +tagname = n
      +as = CSS.properties(attrs)
      +width = XML.attr.get(useAttrs, "width", "auto")
      +height = XML.attr.get(useAttrs, "height", "auto")
      +viewport = U.string.equal(tagname, "svg") || U.string.equal(tagname, "symbol")
      Con{XML.Element{U.choose(String, U.string.equal(tagname, "symbol"), "svg", tagname),
        U.choose(List<&2, XML.Attr>, viewport,
          Con{XML.Attr{"style", ""}, Con{XML.Attr{"width", U.choose(String, U.string.equal(width, "auto"), XML.attr.get(as, "width", "auto"), width)},
            Con{XML.Attr{"height", U.choose(String, U.string.equal(height, "auto"), XML.attr.get(as, "height", "auto"), height)}, as}}}, as), kids, txt}, Nil{}}

def use.children(+as: List<&2, XML.Attr>, all: List<&2, XML.Element>, ancestors: List<&2, String>,
  expand: List<&2, XML.Element> -> List<&2, XML.Element>) -> List<&2, XML.Element>:
  +href = XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", ""))
  +id = U.drop(href, "#")
  U.branch(List<&2, XML.Element>, U.prefix(href, "#") && Bool.not(U.string.equal(id, "")) && Bool.not(U.strings.has(ancestors, id)),
    _ => instance.anonymous(expand(instance.root(XML.element.find(all, id), as))), _ => Nil{})

@unsafe
def use.expand(+fuel: Nat, +xs: List<&2, XML.Element>, +all: List<&2, XML.Element>, +ancestors: List<&2, String>) -> List<&2, XML.Element>:
  match fuel xs:
    case 0n _: Nil{}
    case 1n+d Nil{}: Nil{}
    case 1n+d Con{XML.Element{n, attrs, kids, txt}, rest}:
      +as = attrs
      +tagname = n
      +parents = {Con{XML.attr.get(as, "id", ""), ancestors} : List<&2, String>}
      Con{XML.Element{tagname, as, U.branch(List<&2, XML.Element>, U.string.equal(tagname, "use"),
        _ => use.children(CSS.properties(as), all, parents, nodes => use.expand(d, nodes, all, parents)),
        _ => use.expand(fuel, kids, U.choose(List<&2, XML.Element>, U.string.equal(tagname, "#svg-image"), kids, all), U.choose(List<&2, String>, U.string.equal(tagname, "#svg-image"), Nil{}, parents))), txt}, use.expand(fuel, rest, all, ancestors)}

def scenes.append(xs: List<&2, Scene<Brush>>, ys: List<&2, Scene<Brush>>) -> List<&2, Scene<Brush>>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, scenes.append(t, ys)}

# A mask is rendered as a transparent subscene before its alpha/luminance is used.
type MaskData is Data:
  MaskData{nodes: List<&2, Scene<Brush>>, mode: U32}

def mask.scene(scene: Scene<Brush>, data: MaskData) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, oldNodes, oldMode, markerNodes, coverage, effect} = scene
  MaskData{nodes, mode} = data
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, nodes, mode, markerNodes, coverage, effect}

def mask.clip(nodes: List<&2, Scene<Brush>>, +region: Clip) -> List<&2, Scene<Brush>>:
  match nodes:
    case Nil{}: Nil{}
    case Con{h, t}: Con{scene.clipped(h, region), mask.clip(t, region)}

def mask.region(+as: List<&2, XML.Attr>, +box: Bounds, +m: Matrix, +w: F32, +h: F32) -> Clip:
  +user = U.string.equal(XML.attr.get(as, "maskUnits", "objectBoundingBox"), "userSpaceOnUse")
  +vw = U.choose(F32, user, w, 1.0)
  +vh = U.choose(F32, user, h, 1.0)
  +width = dimension(as, "width", vw, "120%")
  +height = dimension(as, "height", vh, "120%")
  U.branch(Clip, F32.is_gt(width, 0.0) && F32.is_gt(height, 0.0),
    _ => ClipShape{edge.tree(path(shape.rect.path(dimension(as, "x", vw, "-10%"), dimension(as, "y", vh, "-10%"), width, height, 0.0, 0.0), 1.0)),
      matrix.inverse(matrix.mul(m, U.choose(Matrix, user, identity(), gradient.box(box)))), False{}, cover.none()}, _ => clip.empty())

def mask.resource(result: Maybe<&2, XML.Element>, +id: String, +mode: String, +box: Bounds, +m: Matrix, +w: F32, +h: F32,
  build: String -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>) -> MaskData:
  match result:
    case None{}: MaskData{Nil{}, 2}
    case Some{XML.Element{n, attrs, kids, txt}}:
      +as = CSS.properties(attrs)
      +bbox = U.string.equal(XML.attr.get(as, "maskContentUnits", "userSpaceOnUse"), "objectBoundingBox")
      +kind = U.choose(String, U.string.equal(mode, "alpha") || U.string.equal(mode, "luminance"), mode, XML.attr.get(as, "mask-type", "luminance"))
      U.branch(MaskData, U.string.equal(n, "mask"),
        _ => MaskData{mask.clip(build(id)(Con{XML.Element{"g", as, kids, txt}, Nil{}})(matrix.mul(m, U.choose(Matrix, bbox, gradient.box(box), identity())))(U.choose(F32, bbox, 1.0, w))(U.choose(F32, bbox, 1.0, h)), mask.region(as, box, m, w, h)),
          U.choose(U32, U.string.equal(kind, "alpha"), 1, U.choose(U32, U.string.equal(XML.attr.get(as, "color-interpolation", "sRGB"), "linearRGB"), 3, 2))},
        _ => MaskData{Nil{}, 2})

def mask.attach(+as: List<&2, XML.Attr>, all: List<&2, XML.Element>, active: List<&2, String>, box: Bounds, m: Matrix, w: F32, h: F32,
  build: String -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>) -> MaskData:
  +value = XML.attr.get(as, "mask-image", XML.attr.get(as, "mask", "none"))
  +id = U.drop(U.unquote(U.trim.both(U.scan.head(U.until(U.drop(value, "url("), 41, "")))), "#")
  U.branch(MaskData, U.prefix(value, "url("),
    _ => U.branch(MaskData, U.strings.has(active, id), _ => MaskData{Nil{}, 2},
      _ => mask.resource(resource.find(all, id), id, XML.attr.get(as, "mask-mode", "match-source"), box, m, w, h, build)),
    _ => MaskData{Nil{}, 0})

def scene.masked(+scene: Scene<Brush>, as: List<&2, XML.Attr>, all: List<&2, XML.Element>, active: List<&2, String>, w: F32, h: F32,
  build: String -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect} = scene
  mask.scene(scene, mask.attach(as, all, active, box, matrix.inverse(inv), w, h, build))

def mask.value(c: Img.Color, mode: U32) -> F32:
  Img.Color{r, g, b, a} = c
  U.choose(F32, U32.is_eq(mode, 1), a, (r * 0.2126 + g * 0.7152 + b * 0.0722 : F32))

def mask.factor(+mode: U32, render: Unit -> Img.Color) -> F32:
  U.branch(F32, U32.is_eq(mode, 0), _ => 1.0, _ => mask.value(render(Unit{}), mode))

# Transparent source pixels cannot contribute, so avoid rendering their masks.
def mask.apply(+c: Img.Color, +opacity: F32, mode: U32, render: Unit -> Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  U.branch(Img.Color, F32.is_gt(a, 0.0) && F32.is_gt(opacity, 0.0),
    _ => color.fade(c, (opacity * mask.factor(mode, render) : F32)), _ => Img.clear())

def style.paint(s: String, +current: String, opacity: F32) -> Img.Color:
  +paint = s
  color.fade(color(U.choose(String, U.string.equal(CSS.css.lower(U.trim.both(paint)), "currentcolor"), current, paint)), opacity)

def filter.sample(effect: FilterEffect, p: Point, linear: Bool, original: Unit -> Img.Color) -> Img.Color:
  match effect:
    case NoFilter{}: original(Unit{})
    case FilterSpec{region, units, viewport, attrs, primitives}: original(Unit{})
    case FilterImage{raster}: raster.color(raster, p, linear)

def paint.order.composite(+order: U32, +fill: Img.Color, +stroke: Img.Color, +markers: Img.Color) -> Img.Color:
  U.choose(Img.Color, U32.is_eq(order, 1), color.over(stroke, color.over(markers, fill)),
    U.choose(Img.Color, U32.is_eq(order, 2), color.over(markers, color.over(fill, stroke)),
      U.choose(Img.Color, U32.is_eq(order, 3), color.over(fill, color.over(markers, stroke)),
        U.choose(Img.Color, U32.is_eq(order, 4), color.over(stroke, color.over(fill, markers)),
          U.choose(Img.Color, U32.is_eq(order, 5), color.over(fill, color.over(stroke, markers)), color.over(markers, color.over(stroke, fill)))))))

# `limit` is the coverage the enclosing clips leave at this pixel; taking the
# minimum with the shape's own coverage keeps an edge that coincides with a clip
# edge (marker and image viewports) at its true coverage instead of squaring it.
def scene.shape(f: Fill, es: List<&2, Edge>, +s: Style, ink: Paint<Brush>, outline: StrokeMesh, +p: Point, +paintPoint: Point, +worldPoint: Point, +linear: Bool, markers: Img.Color, fills: List<&2, Scene<Brush>> -> Point -> Point -> Img.Color, strokes: List<&2, Scene<Brush>> -> Point -> Point -> Img.Color, +limit: F32) -> Img.Color:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  Paint{fc, sc} = ink
  +fillCover = U.choose(F32, visible && Bool.not(U.string.equal(fill, "none")), U.min(fill.coverage(f, es, p, worldPoint, even), limit), 0.0)
  +strokeCover = U.choose(F32, visible && Bool.not(U.string.equal(stroke, "none")) && F32.is_gt(width, 0.0), U.min(stroke.coverage(outline, worldPoint), limit), 0.0)
  paint.order.composite(order,
    U.branch(Img.Color, F32.is_gt(fillCover, 0.0), _ => color.fade(color.space(brush.sample(fc, p, paintPoint, fills), linear), fillCover), _ => Img.clear()),
    U.branch(Img.Color, F32.is_gt(strokeCover, 0.0), _ => color.fade(color.space(brush.sample(sc, p, paintPoint, strokes), linear), strokeCover), _ => Img.clear()), markers)

def style.margin(s: Style) -> F32:
  Style{fill, stroke, col, fo, so, w, even, visible, ss, ms, rendering, order} = s
  StrokeSettings{cap, join, limit, dash, offset, vector} = ss
  (w * U.max(1.41421356237, limit) / 2.0 : F32)

def scene.local(+scene: Scene<Brush>, +p: Point, paintPoint: Point, linear: Bool, +markers: Img.Color, fills: List<&2, Scene<Brush>> -> Point -> Point -> Img.Color, strokes: List<&2, Scene<Brush>> -> Point -> Point -> Img.Color, +limit: F32) -> Img.Color:
  Scene{es, box, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect} = scene
  +q = matrix.point(inv, p)
  U.branch(Img.Color, bounds.inside(box, q, style.margin(style)) || style.nonScaling(style), _ => scene.shape(fillTree, es, style, ink, outline, q, matrix.point(inv, paintPoint), p, linear, markers, fills, strokes, limit), _ => markers)

# A rendered filter carries its clip as a plain factor; otherwise the clip
# coverage travels down as the limit.
def filter.rendered(effect: FilterEffect) -> Bool:
  match effect:
    case NoFilter{}: False{}
    case FilterSpec{region, units, viewport, attrs, primitives}: False{}
    case FilterImage{raster}: True{}

# Pattern scenes are finite compiled subtrees; the callback obscures structural descent.
@unsafe
def sample(+scenes: List<&2, Scene<Brush>>, +p: Point, +paintPoint: Point, +back: Img.Color, +linear: Bool, +limit: F32) -> Img.Color:
  match scenes:
    case Nil{}: back
    case Con{Scene{es, box, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      +cc = clip.cover(mask, p)
      +inner = U.min(limit, cc)
      +gate = U.choose(F32, filter.rendered(effect), cc, U.choose(F32, F32.is_gt(inner, 0.0), 1.0, 0.0))
      sample(rest, p, paintPoint, U.branch(Img.Color, bounds.inside(coverage, p, 0.01), _ => color.over(mask.apply(clip.fade(gate, _ => filter.sample(effect, paintPoint, linear, _ => sample(kids, p, paintPoint,
        scene.local(Scene{es, box, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}, p, paintPoint, linear, sample(markerNodes, p, paintPoint, Img.clear(), linear, inner),
          nodes => q => center => sample(nodes, q, center, Img.clear(), False{}, 1.0),
          nodes => q => center => sample(nodes, q, center, Img.clear(), False{}, 1.0), inner), linear, inner))),
        opacity, maskMode, _ => sample(maskNodes, p, paintPoint, Img.clear(), U32.is_eq(maskMode, 3), 1.0)), back), _ => back), linear, limit)

# Patterns compile their content once and reuse it for every tile sample.
def pattern.has.content(xs: List<&2, XML.Element>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +tagname = n
      Bool.not(U.string.equal(tagname, "title") || U.string.equal(tagname, "desc") || U.string.equal(tagname, "metadata") || U.string.equal(tagname, "#text")) || pattern.has.content(rest)

def pattern.attributes(+xs: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Attr{k, v}, rest}:
      +key = k
      U.branch(List<&2, XML.Attr>, U.string.equal(key, "x") || U.string.equal(key, "y") || U.string.equal(key, "width") || U.string.equal(key, "height")
        || U.string.equal(key, "viewBox") || U.string.equal(key, "preserveAspectRatio") || U.string.equal(key, "patternTransform")
        || U.string.equal(key, "patternUnits") || U.string.equal(key, "patternContentUnits"),
        _ => Con{XML.Attr{key, v}, pattern.attributes(rest)}, _ => pattern.attributes(rest))

def pattern.merge(local: XML.Element, template: XML.Element) -> XML.Element:
  XML.Element{n, as, kids, txt} = local
  XML.Element{tn, tas, tkids, ttxt} = template
  +children = kids
  XML.Element{n, XML.attrs.append(as, pattern.attributes(tas)), U.choose(List<&2, XML.Element>, pattern.has.content(children), children, tkids), txt}

def pattern.reference(+node: XML.Element, result: Maybe<&2, XML.Element>, next: XML.Element -> XML.Element) -> XML.Element:
  match result:
    case None{}: node
    case Some{XML.Element{n, as, kids, txt}}:
      +tagname = n
      U.branch(XML.Element, U.string.equal(tagname, "pattern"), _ => pattern.merge(node, next(XML.Element{tagname, as, kids, txt})), _ => node)

def pattern.resolve(depth: Nat, +node: XML.Element, +all: List<&2, XML.Element>) -> XML.Element:
  match depth:
    case 0n: node
    case 1n+d:
      XML.Element{n, as, kids, txt} = node
      +href = XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", ""))
      U.branch(XML.Element, U.prefix(href, "#"),
        _ => pattern.reference(node, resource.find(all, U.drop(href, "#")), e => pattern.resolve(d, e, all)), _ => node)

def pattern.paint(+nodes: List<&2, Scene<Brush>>, inv: Matrix, width: F32, height: F32, opacity: F32) -> Brush:
  Pattern{inv, width, height, opacity, nodes}

# pixels is the device pixels per user unit of the referencing element; the
# content is compiled for the pattern frame's own device scale.
# Pattern space to the referencing element's user space.
def pattern.frame(+as: List<&2, XML.Attr>, +units: Matrix, +uw: F32, +uh: F32) -> Matrix:
  matrix.mul(transform(XML.attr.get(as, "patternTransform", ""), identity()), matrix.mul(units,
    translate(dimension(as, "x", uw, "0"), dimension(as, "y", uh, "0"))))

def pattern.tile(e: XML.Element, box: Bounds, +w: F32, +h: F32, opacity: F32,
  build: String -> F32 -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>, +pixels: F32) -> Brush:
  XML.Element{n, attrs, kids, txt} = e
  Bounds{x0, y0, x1, y1} = box
  +as = CSS.properties(attrs)
  +bx = x0
  +by = y0
  +bw = (x1 - bx : F32)
  +bh = (y1 - by : F32)
  +user = U.string.equal(XML.attr.get(as, "patternUnits", "objectBoundingBox"), "userSpaceOnUse")
  +contentUser = U.string.equal(XML.attr.get(as, "patternContentUnits", "userSpaceOnUse"), "userSpaceOnUse")
  +uw = U.choose(F32, user, w, 1.0)
  +uh = U.choose(F32, user, h, 1.0)
  +width = dimension(as, "width", uw, "0")
  +height = dimension(as, "height", uh, "0")
  +view = U.numbers(XML.attr.get(as, "viewBox", ""))
  +hasView = Bool.not(U.string.equal(XML.attr.get(as, "viewBox", ""), ""))
  +vw = U.choose(F32, hasView, U.nth(view, 2n, 0.0), U.choose(F32, contentUser, w, 1.0))
  +vh = U.choose(F32, hasView, U.nth(view, 3n, 0.0), U.choose(F32, contentUser, h, 1.0))
  +units = U.choose(Matrix, user, identity(), matrix.mul(translate(bx, by), scale(bw, bh)))
  +content = U.choose(Matrix, hasView,
    viewbox.matrix(view, width, height, XML.attr.get(as, "preserveAspectRatio", "xMidYMid meet")),
    scale((U.choose(F32, contentUser, 1.0, bw) / U.choose(F32, user, 1.0, U.max(bw, 0.0000001)) : F32),
      (U.choose(F32, contentUser, 1.0, bh) / U.choose(F32, user, 1.0, U.max(bh, 0.0000001)) : F32)))
  U.branch(Brush, F32.is_gt(width, 0.0) && F32.is_gt(height, 0.0) && F32.is_gt(vw, 0.0) && F32.is_gt(vh, 0.0)
      && (user || (F32.is_gt(bw, 0.0) && F32.is_gt(bh, 0.0))),
    _ => pattern.paint(build(XML.attr.get(as, "id", ""))((pixels * matrix.norm(pattern.frame(as, units, uw, uh)) : F32))(Con{XML.Element{"g", Con{XML.Attr{"display", "inline"}, as}, kids, txt}, Nil{}})(content)(vw)(vh),
      matrix.inverse(pattern.frame(as, units, uw, uh)), width, height, opacity),
    _ => Solid{Img.clear(), Img.clear()})

def pattern.build(+node: XML.Element, +all: List<&2, XML.Element>, active: List<&2, String>, box: Bounds, w: F32, h: F32, opacity: F32,
  build: String -> F32 -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>, +pixels: F32) -> Brush:
  XML.Element{n, as, kids, txt} = node
  U.branch(Brush, U.strings.has(active, XML.attr.get(as, "id", "")), _ => Solid{Img.clear(), Img.clear()},
    _ => pattern.tile(pattern.resolve(32n, node, all), box, w, h, opacity, build, pixels))

def matrix.show(m: Matrix) -> String:
  Matrix{a, b, c, d, e, f} = m
  # Commas between all six values are required in CSS style declarations.
  "matrix(" ++ F32.show(a) ++ "," ++ F32.show(b) ++ "," ++ F32.show(c)
    ++ "," ++ F32.show(d) ++ "," ++ F32.show(e) ++ "," ++ F32.show(f) ++ ")"

# Marker instances have independent styles and viewports. Their geometry does not
# enlarge the referring shape's object bounding box.
def scene.marked(scene: Scene<Brush>, nodes: List<&2, Scene<Brush>>) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, oldMarkers, coverage, effect} = scene
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, nodes, coverage, effect}

def marker.angle.number(n: U.Number) -> F32:
  U.Number{x, t, ok} = n
  +suffix = U.trim.both(t)
  (x * U.choose(F32, U.string.equal(suffix, "rad"), 57.29577951308232, U.choose(F32, U.string.equal(suffix, "grad"), 0.9, U.choose(F32, U.string.equal(suffix, "turn"), 360.0, 1.0))) : F32)

def marker.orient(+s: String, angle: F32, start: Bool) -> F32:
  +auto = U.string.equal(s, "auto") || U.string.equal(s, "auto-start-reverse")
  U.choose(F32, auto, (angle + U.choose(F32, start && U.string.equal(s, "auto-start-reverse"), 180.0, 0.0) : F32), marker.angle.number(U.number(s)))

def marker.reference.point(p: Point, +width: F32, +height: F32) -> List<&2, XML.Attr>:
  Point{x, y} = p
  Con{XML.Attr{"x", F32.show(F32.neg(x))}, Con{XML.Attr{"y", F32.show(F32.neg(y))}, Con{XML.Attr{"width", F32.show(width)}, Con{XML.Attr{"height", F32.show(height)}, Nil{}}}}}

def marker.resource(+result: Maybe<&2, XML.Element>, id: String, vertex: MarkerVertex, start: Bool, strokeWidth: F32, +w: F32, +h: F32) -> List<&2, XML.Element>:
  match result:
    case None{}: Nil{}
    case Some{XML.Element{n, as, kids, txt}}:
      MarkerVertex{Point{x, y}, angle} = vertex
      +width = dimension(as, "markerWidth", w, "3")
      +height = dimension(as, "markerHeight", h, "3")
      +view = U.numbers(XML.attr.get(as, "viewBox", ""))
      +vw = U.nth(view, 2n, width)
      +vh = U.nth(view, 3n, height)
      +unitScale = U.choose(F32, U.string.equal(XML.attr.get(as, "markerUnits", "strokeWidth"), "userSpaceOnUse"), 1.0, strokeWidth)
      +mat = matrix.mul(translate(x, y), matrix.mul(rotate(marker.orient(XML.attr.get(as, "orient", "0"), angle, start)), scale(unitScale, unitScale)))
      +ref = matrix.point(viewbox.matrix(view, width, height, XML.attr.get(as, "preserveAspectRatio", "xMidYMid meet")), Point{dimension(as, "refX", vw, "0"), dimension(as, "refY", vh, "0")})
      U.branch(List<&2, XML.Element>, U.string.equal(n, "marker") && F32.is_gt(width, 0.0) && F32.is_gt(height, 0.0) && F32.is_gt(vw, 0.0) && F32.is_gt(vh, 0.0) && F32.is_gt(unitScale, 0.0),
        _ => Con{XML.Element{"g", Con{XML.Attr{"transform", matrix.show(mat)}, Nil{}}, Con{XML.Element{"svg", Con{XML.Attr{"#marker-source", id}, Con{XML.Attr{"#editor-id", ""}, Con{XML.Attr{"transform", ""}, XML.attrs.append(marker.reference.point(ref, width, height), as)}}}, instance.anonymous(kids), txt}, Nil{}}, ""}, Nil{}}, _ => Nil{})

def marker.instance(+value: String, vertex: MarkerVertex, start: Bool, +all: List<&2, XML.Element>, active: List<&2, String>, width: F32, w: F32, h: F32) -> List<&2, XML.Element>:
  +id = U.drop(U.unquote(U.trim.both(U.scan.head(U.until(U.drop(value, "url("), 41, "")))), "#")
  U.branch(List<&2, XML.Element>, U.prefix(value, "url(") && Bool.not(U.strings.has(active, id)),
    _ => marker.resource(resource.find(all, id), id, vertex, start, width, w, h), _ => Nil{})

def marker.elements.append(xs: List<&2, XML.Element>, ys: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: ys
    case Con{a, rest}: Con{a, marker.elements.append(rest, ys)}

@unsafe
def marker.instances.loop(xs: List<&2, MarkerVertex>, +first: Bool, +ms: MarkerStyle, +all: List<&2, XML.Element>, +active: List<&2, String>, +width: F32, +w: F32, +h: F32) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{vertex, Nil{}}:
      MarkerStyle{start, middle, end} = ms
      +v = vertex
      marker.elements.append(U.branch(List<&2, XML.Element>, first, _ => marker.instance(start, v, True{}, all, active, width, w, h), _ => Nil{}), marker.instance(end, v, False{}, all, active, width, w, h))
    case Con{vertex, Con{head, tail}}:
      MarkerStyle{start, middle, end} = ms
      marker.elements.append(marker.instance(U.choose(String, first, start, middle), vertex, first, all, active, width, w, h), marker.instances.loop(Con{head, tail}, False{}, ms, all, active, width, w, h))

def marker.enabled(ms: MarkerStyle) -> Bool:
  MarkerStyle{start, middle, end} = ms
  U.prefix(start, "url(") || U.prefix(middle, "url(") || U.prefix(end, "url(")

def marker.shape(+name: String) -> Bool:
  U.string.equal(name, "path") || U.string.equal(name, "line") || U.string.equal(name, "polyline") || U.string.equal(name, "polygon")

def marker.wanted(+name: String, s: Style) -> Bool:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  marker.enabled(ms) && marker.shape(name)

def marker.instances(+name: String, +as: List<&2, XML.Attr>, +s: Style, all: List<&2, XML.Element>, active: List<&2, String>, +w: F32, +h: F32) -> List<&2, XML.Element>:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  U.branch(List<&2, XML.Element>, marker.enabled(ms) && marker.shape(name),
    _ => marker.instances.loop(marker.trace(shape.data(name, as, w, h, XML.attr.get(as, "d", ""))), True{}, ms, all, active, width, w, h), _ => Nil{})

# A shape's edges and its marker instances. Path data is shared with the
# marker trace only when markers are wanted.
def compile.geometry(marked: Bool, data: String, +n: String, +attrs: List<&2, XML.Attr>, glyphs: List<&2, XML.Element>, +vw: F32, +vh: F32, +tol: F32, +style: Style, all: List<&2, XML.Element>, active: List<&2, String>) -> List<&2, Edge> & List<&2, XML.Element>:
  match marked:
    case False{}: (shape.children(n, attrs, glyphs, vw, vh, tol, data), Nil{})
    case True{}:
      +dd = data
      (shape.children(n, attrs, glyphs, vw, vh, tol, dd), marker.instances(n, Con{XML.Attr{"d", dd}, attrs}, style, all, active, vw, vh))

def compile.visible(geo: List<&2, Edge> & List<&2, XML.Element>, +n: String, +matrix: Matrix, +vw: F32, +vh: F32, viewportClip: Clip, +style: Style, embedded: EmbeddedImage, +attrs: List<&2, XML.Attr>, +all: List<&2, XML.Element>, +active: List<&2, String>, +scale: F32,
  masks: String -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>, fills: String -> F32 -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>, strokes: String -> F32 -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>,
  markers: List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>,
  children: Style -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>) -> List<&2, Scene<Brush>>:
  (edges, markerNodes) = geo
  Con{scene.marked(scene.masked(scene.clipped(scene.bitmap(scene.make(edges, matrix, style,
    color.opacity(XML.attr.get(attrs, "opacity", "1"), 1.0), U.branch(List<&2, Scene<Brush>>, U.string.equal(n, "#glyph-run"), _ => Nil{}, _ => children(style)(matrix)(vw)(vh)),
    XML.attr.get(attrs, "#editor-id", ""), all, vw, vh, attrs,
      node => box => pw => ph => alpha => pattern.build(node, all, active, box, pw, ph, alpha, fills, (scale * matrix.norm(matrix) : F32)),
      node => box => pw => ph => alpha => pattern.build(node, all, active, box, pw, ph, alpha, strokes, (scale * matrix.norm(matrix) : F32)), scale), embedded), viewportClip), attrs, all, active, vw, vh, masks), markers(markerNodes)(matrix)(vw)(vh)), Nil{}}

def compile.node(+n: String, +as: List<&2, XML.Attr>, +glyphs: List<&2, XML.Element>, +vp: Viewport, inherited: Style, +all: List<&2, XML.Element>, +active: List<&2, String>, +scale: F32, data: String,
  masks: String -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>, fills: String -> F32 -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>, strokes: String -> F32 -> List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>,
  markers: List<&2, XML.Element> -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>,
  children: Style -> Matrix -> F32 -> F32 -> List<&2, Scene<Brush>>) -> List<&2, Scene<Brush>>:
  Viewport{matrix, vw, vh, viewportClip, valid} = vp
  +baseStyle = style.inherit(inherited, as, F32.sqrt(((vw * vw + vh * vh) / 2.0 : F32)))
  +embedded = bitmap.element(n, Con{XML.Attr{"image-rendering", style.image.rendering(baseStyle)}, as}, vw, vh)
  +attrs = bitmap.attrs(embedded, as)
  +style = U.choose(Style, U.string.equal(n, "#svg-image"), style.embedded(baseStyle), bitmap.style(embedded, baseStyle))
  U.branch(List<&2, Scene<Brush>>, element.hidden(n, as) || Bool.not(valid) || (U.string.equal(n, "#svg-image") && Bool.not(style.is.visible(baseStyle))), _ => Nil{},
    _ => compile.visible(compile.geometry(marker.wanted(n, style), data, n, attrs, glyphs, vw, vh, local.tolerance(matrix, scale), style, all, active),
      n, matrix, vw, vh, viewportClip, style, embedded, attrs, all, active, scale, masks, fills, strokes, markers, children))

# An element's path data is taken out of its attributes before they are
# shared, so the path parser owns that text; the loop carries the element in
# that state as a step of its own.
type Work is Data:
  Pending{xs: List<&2, XML.Element>}
  Prepared{taken: XML.Taken, tagname: String, kids: List<&2, XML.Element>, rest: List<&2, XML.Element>}

@unsafe
def compile.work(+fuel: Nat, work: Work, +inherited: Style, +m: Matrix, +w: F32, +h: F32,
  +all: List<&2, XML.Element>, +root: Bool, +active: List<&2, String>, +scale: F32) -> List<&2, Scene<Brush>>:
  match fuel work:
    case 0n _: Nil{}
    case 1n+d Pending{xs}:
      match xs:
        case Nil{}: Nil{}
        case Con{XML.Element{tagname, attrs, kids, txt}, rest}:
          compile.work(fuel, Prepared{XML.attrs.take(image.layout.attrs(CSS.properties(attrs), w, h), "d"), tagname, kids, rest}, inherited, m, w, h, all, root, active, scale)
    case 1n+d Prepared{XML.Taken{data, as0}, tagname, kids, rest}:
      +as = as0
      +ks = kids
      +n = tagname
      scenes.append(compile.node(n, as, ks, element.viewport(n, as, m, w, h, root), inherited, all, active, scale, data,
        used => nodes => mat => vw => vh => compile.work(d, Pending{nodes}, style.default(), mat, vw, vh, all, False{}, Con{used, active}, scale),
        used => sc => nodes => mat => vw => vh => compile.work(d, Pending{nodes}, style.default(), mat, vw, vh, all, False{}, Con{used, active}, sc),
        used => sc => nodes => mat => vw => vh => compile.work(d, Pending{nodes}, style.default(), mat, vw, vh, all, False{}, Con{used, active}, sc),
        nodes => mat => vw => vh => compile.work(d, Pending{nodes}, style.default(), mat, vw, vh, all, False{}, active, scale),
        style => mat => vw => vh => compile.work(U.choose(Nat, U.string.equal(XML.attr.get(as, "#marker-source", ""), ""), fuel, d), Pending{ks}, U.choose(Style, U.string.equal(n, "#svg-image"), style.default(), style), mat, vw, vh, U.choose(List<&2, XML.Element>, U.string.equal(n, "#svg-image"), resources(ks, Nil{}), all), False{}, U.choose(List<&2, String>, U.string.equal(n, "#svg-image"), Nil{}, U.choose(List<&2, String>, U.string.equal(XML.attr.get(as, "#marker-source", ""), ""), active, Con{XML.attr.get(as, "#marker-source", ""), active})), scale)),
        compile.work(fuel, Pending{rest}, inherited, m, w, h, all, root, active, scale))

def compile(+fuel: Nat, xs: List<&2, XML.Element>, +inherited: Style, +m: Matrix, +w: F32, +h: F32,
  +all: List<&2, XML.Element>, +root: Bool, +active: List<&2, String>, +scale: F32) -> List<&2, Scene<Brush>>:
  compile.work(fuel, Pending{xs}, inherited, m, w, h, all, root, active, scale)

# XML.Text layout produces internal glyph geometry while preserving text/tspan groups.
type TextFont is Data:
  TextFont{size: F32, face: U32, weight: String, slant: String, anchor: String,
    letter: F32, word: F32, shift: F32, baseline: String, kern: Bool, preserve: Bool, book: Font.FontBook}

def text.font.em(font: TextFont) -> F32:
  TextFont{size, face, weight, slant, anchor, letter, word, shift, baseline, kern, preserve, book} = font
  size

def text.font.default(book: Font.FontBook) -> TextFont:
  TextFont{16.0, 0, "normal", "normal", "start", 0.0, 0.0, 0.0, "alphabetic", True{}, False{}, book}

def text.measure(+num: U.Number, ref: F32, +size: F32) -> F32:
  U.Number{x, tail, ok} = num
  +t = tail
  U.choose(F32, U.prefix(t, "em"), (x * size : F32), U.choose(F32, U.prefix(t, "ex"), (x * size * 0.536 : F32),
    U.choose(F32, U.prefix(t, "rem"), (x * 16.0 : F32), U.unit(num, ref))))

def text.font.size(+s: String, +parent: F32) -> F32:
  U.choose(F32, U.string.equal(s, "smaller"), (parent / 1.2 : F32), U.choose(F32, U.string.equal(s, "larger"), (parent * 1.2 : F32),
    U.choose(F32, U.string.equal(s, "medium"), 16.0, U.choose(F32, U.string.equal(s, "small"), 13.0,
      U.choose(F32, U.string.equal(s, "large"), 18.0, U.max(0.0, text.measure(U.number(s), parent, parent)))))))

def text.font.inherit(+font: TextFont, +as: List<&2, XML.Attr>) -> TextFont:
  TextFont{size, face, weight, slant, anchor, letter, word, shift, baseline, kern, preserve, book} = font
  +sz = text.font.size(style.value(as, "font-size", F32.show(size), "16", True{}), size)
  +wt = style.value(as, "font-weight", weight, "normal", True{})
  +it = style.value(as, "font-style", slant, "normal", True{})
  +bold = U.string.equal(wt, "bold") || U.string.equal(wt, "bolder") || F32.is_ge(U.scalar(wt, 400.0), 600.0)
  +italic = U.string.equal(it, "italic") || U.prefix(it, "oblique")
  +selectedFace = (U.choose(U32, bold, 1, 0) + U.choose(U32, italic, 2, 0) : U32)
  +bs = XML.attr.get(as, "baseline-shift", "0")
  +ws = style.value(as, "white-space", U.choose(String, preserve, "pre", "normal"), "normal", True{})
  +xml = XML.attr.get(as, "xml:space", "")
  TextFont{sz, selectedFace, wt, it,
    style.value(as, "text-anchor", anchor, "start", True{}),
    text.measure(U.number(style.value(as, "letter-spacing", F32.show(letter), "0", True{})), sz, sz),
    text.measure(U.number(style.value(as, "word-spacing", F32.show(word), "0", True{})), sz, sz),
    (shift + U.choose(F32, U.string.equal(bs, "super"), (Font.font.metric(book, selectedFace, "superscript", 0.4) * sz : F32), U.choose(F32, U.string.equal(bs, "sub"), (F32.neg(Font.font.metric(book, selectedFace, "subscript", 0.2)) * sz : F32), text.measure(U.number(bs), sz, sz))) : F32),
    style.value(as, "dominant-baseline", baseline, "alphabetic", True{}),
    Bool.not(U.string.equal(style.value(as, "font-kerning", U.choose(String, kern, "auto", "none"), "auto", True{}), "none")),
    U.choose(Bool, U.string.equal(xml, "preserve"), True{}, U.choose(Bool, U.string.equal(xml, "default"), False{}, U.prefix(ws, "pre") || U.string.equal(ws, "break-spaces"))), book}

def text.length.value(+num: U.Number, +ref: F32, +size: F32, next: String -> List<&2, F32>) -> List<&2, F32>:
  U.Number{x, tail, ok} = num
  U.branch(List<&2, F32>, ok, _ => Con{text.measure(num, ref, size), next(dash.skip.units(tail))}, _ => Nil{})

@unsafe
def text.lengths(s: String, +ref: F32, +size: F32) -> List<&2, F32>:
  text.length.value(U.number(s), ref, size, rest => text.lengths(U.separators(rest), ref, size))

type TextFrame is Data:
  TextFrame{start: U32, xs: List<&2, F32>, ys: List<&2, F32>, dxs: List<&2, F32>, dys: List<&2, F32>, angles: List<&2, F32>}

def text.frame(+as: List<&2, XML.Attr>, start: U32, +w: F32, +h: F32, +size: F32) -> TextFrame:
  TextFrame{start, text.lengths(XML.attr.get(as, "x", ""), w, size), text.lengths(XML.attr.get(as, "y", ""), h, size),
    text.lengths(XML.attr.get(as, "dx", ""), w, size), text.lengths(XML.attr.get(as, "dy", ""), h, size), U.numbers(XML.attr.get(as, "rotate", ""))}

type TextValue is Data:
  TextValue{value: F32, set: Bool}

def text.at(xs: List<&2, F32>, +index: U32, +repeat: Bool, previous: TextValue) -> TextValue:
  match xs:
    case Nil{}: U.choose(TextValue, repeat, previous, TextValue{0.0, False{}})
    case Con{head, tail}:
      +h = head
      U.branch(TextValue, U32.is_eq(index, 0), _ => TextValue{h, True{}}, _ => text.at(tail, (index - 1 : U32), repeat, TextValue{h, True{}}))

def text.axis.first(+value: TextValue, fallback: Unit -> TextValue) -> TextValue:
  TextValue{x, set} = value
  U.branch(TextValue, set, _ => value, _ => fallback(Unit{}))

def text.axis(xs: List<&2, TextFrame>, +index: U32, +axis: U32) -> TextValue:
  match xs:
    case Nil{}: TextValue{0.0, False{}}
    case Con{TextFrame{start, xx, yy, dx, dy, angles}, rest}:
      text.axis.first(text.at(U.choose(List<&2, F32>, U32.is_eq(axis, 0), xx, U.choose(List<&2, F32>, U32.is_eq(axis, 1), yy,
        U.choose(List<&2, F32>, U32.is_eq(axis, 2), dx, U.choose(List<&2, F32>, U32.is_eq(axis, 3), dy, angles)))),
        (index - start : U32), U32.is_eq(axis, 4), TextValue{0.0, False{}}), _ => text.axis(rest, index, axis))

type TextPosition is Data:
  TextPosition{x: TextValue, y: TextValue, dx: TextValue, dy: TextValue, angle: TextValue}

def text.position(+frames: List<&2, TextFrame>, +index: U32) -> TextPosition:
  TextPosition{text.axis(frames, index, 0), text.axis(frames, index, 1), text.axis(frames, index, 2), text.axis(frames, index, 3), text.axis(frames, index, 4)}

type TextChunk is Data:
  TextChunk{key: U32, delta: F32}

type TextCursor is Data:
  TextCursor{x: F32, y: F32, index: U32, chunk: U32, start: F32, anchor: String,
    previous: U32, previousClass: U32, previousFace: U32, previousSize: F32,
    seen: Bool, space: Bool, trailing: F32, spacing: F32, chunks: List<&2, TextChunk>}

def text.cursor() -> TextCursor:
  TextCursor{0.0, 0.0, 0, 0, 0.0, "start", 0, 0, 99, 0.0, False{}, True{}, 0.0, 0.0, Nil{}}

def text.chunk(+cursor: TextCursor) -> List<&2, TextChunk>:
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  +width = (x - start - trailing - spacing : F32)
  Con{TextChunk{chunk, U.choose(F32, U.string.equal(anchor, "middle"), (width / 2.0 : F32), U.choose(F32, U.string.equal(anchor, "end"), width, 0.0))}, chunks}

def text.index(cursor: TextCursor) -> U32:
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  index

# XML.Text paths use the same flattened geometry as fills and strokes.
def text.path.target(target: Maybe<&2, XML.Element>, +w: F32, +h: F32) -> List<&2, XML.Attr>:
  match target:
    case None{}: Nil{}
    case Some{XML.Element{n, as, kids, txt}}:
      +attrs = CSS.properties(as)
      Con{XML.Attr{"#text-path-data", shape.data(n, attrs, w, h, XML.attr.get(attrs, "d", ""))}, Con{XML.Attr{"#text-path-transform", XML.attr.get(attrs, "transform", "")}, Con{XML.Attr{"#text-path-length", XML.attr.get(attrs, "pathLength", "0")}, Nil{}}}}

def text.path.attrs(+as: List<&2, XML.Attr>, all: List<&2, XML.Element>, +w: F32, +h: F32) -> List<&2, XML.Attr>:
  +direct = XML.attr.get(as, "path", "")
  +href = XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", ""))
  +found = text.path.target(U.branch(Maybe<&2, XML.Element>, U.prefix(href, "#"), _ => XML.element.find(all, U.drop(href, "#")), _ => None{}), w, h)
  XML.attrs.append(U.choose(List<&2, XML.Attr>, U.string.equal(direct, ""), found, Con{XML.Attr{"#text-path-data", direct}, Nil{}}), as)

def text.path.resolve.node(+n: String, +as: List<&2, XML.Attr>, +kids: List<&2, XML.Element>, txt: String, +all: List<&2, XML.Element>, w: F32, h: F32, vp: Viewport,
  expand: List<&2, XML.Element> -> List<&2, XML.Element> -> F32 -> F32 -> List<&2, XML.Element>) -> XML.Element:
  Viewport{mat, vw, vh, clip, valid} = vp
  XML.Element{n, U.choose(List<&2, XML.Attr>, U.string.equal(n, "textPath"), text.path.attrs(as, all, w, h), as), expand(kids)(U.choose(List<&2, XML.Element>, U.string.equal(n, "#svg-image"), kids, all))(vw)(vh), txt}

@unsafe
def text.path.resolve(xs: List<&2, XML.Element>, +all: List<&2, XML.Element>, +w: F32, +h: F32, +root: Bool) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, attrs, kids, txt}, rest}:
      +as = CSS.properties(attrs)
      +tagname = n
      Con{text.path.resolve.node(tagname, as, kids, txt, all, w, h, element.viewport(tagname, as, identity(), w, h, root), nodes => scope => vw => vh => text.path.resolve(nodes, scope, vw, vh, False{})), text.path.resolve(rest, all, w, h, root)}

def text.path.edges(+xs: List<&2, Edge>, +acc: List<&2, Edge>) -> List<&2, Edge>:
  match xs:
    case Nil{}: acc
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}: text.path.edges(rest, U.choose(List<&2, Edge>, stroked && F32.is_gt(point.distance(Point{ax, ay}, Point{bx, by}), 0.000001), Con{Edge{ax, ay, bx, by, stroked, closed}, acc}, acc))

def text.path.geometry(+as: List<&2, XML.Attr>) -> List<&2, Edge>:
  text.path.edges(edges.transform(path(XML.attr.get(as, "#text-path-data", ""), 0.001), transform(XML.attr.get(as, "#text-path-transform", ""), identity())), Nil{})

def text.path.total(xs: List<&2, Edge>) -> F32:
  match xs:
    case Nil{}: 0.0
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}: (point.distance(Point{ax, ay}, Point{bx, by}) + text.path.total(rest) : F32)

def text.path.at(+xs: List<&2, Edge>, +distance: F32, fallback: Matrix) -> Matrix:
  match xs:
    case Nil{}: fallback
    case Con{Edge{x, y, u, v, stroked, closed}, rest}:
      +dx = (u - x : F32)
      +dy = (v - y : F32)
      +len = F32.sqrt((dx * dx + dy * dy : F32))
      +tx = (dx / len : F32)
      +ty = (dy / len : F32)
      U.branch(Matrix, F32.is_le(distance, len), _ => Matrix{tx, ty, F32.neg(ty), tx, (x + tx * distance : F32), (y + ty * distance : F32)},
        _ => text.path.at(rest, (distance - len : F32), Matrix{tx, ty, F32.neg(ty), tx, u, v}))

def text.path.offset(+num: U.Number, +total: F32, +calibration: F32, em: F32) -> F32:
  U.Number{x, suffix, valid} = num
  (text.measure(num, total, em) * U.choose(F32, U.prefix(suffix, "%") || F32.is_le(calibration, 0.0), 1.0, (total / calibration : F32)) : F32)

def text.path.begin(+cursor: TextCursor) -> TextCursor:
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  TextCursor{0.0, 0.0, index, chunk, 0.0, anchor, 0, 0, 99, 0.0, False{}, blankState, 0.0, 0.0, text.chunk(cursor)}

def text.path.end(+cursor: TextCursor, +matrix: Matrix) -> TextCursor:
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  Matrix{a, b, c, d, e, f} = matrix
  TextCursor{e, f, index, U32.inc(chunk), e, "start", 0, 0, 99, 0.0, True{}, blankState, 0.0, 0.0, text.chunk(cursor)}

def text.path.frames(xs: List<&2, TextFrame>) -> List<&2, TextFrame>:
  match xs:
    case Nil{}: Nil{}
    case Con{TextFrame{start, xx, yy, dx, dy, angles}, rest}: Con{TextFrame{start, xx, Nil{}, dx, dy, angles}, text.path.frames(rest)}

type TextLayout is Data:
  TextLayout{nodes: List<&2, XML.Element>, cursor: TextCursor}

def text.nodes.append(xs: List<&2, XML.Element>, ys: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, text.nodes.append(t, ys)}

def text.layout.combine(left: List<&2, XML.Element>, result: TextLayout) -> TextLayout:
  TextLayout{right, cursor} = result
  TextLayout{text.nodes.append(left, right), cursor}

def text.layout.then(result: TextLayout, next: TextCursor -> TextLayout) -> TextLayout:
  TextLayout{nodes, cursor} = result
  text.layout.combine(nodes, next(cursor))

def text.baseline(+font: TextFont) -> F32:
  TextFont{size, face, weight, slant, anchor, letter, word, shift, baseline, kern, preserve, book} = font
  +base = baseline
  +ascender = Font.font.metric(book, face, "ascender", 1.069)
  +descender = Font.font.metric(book, face, "descender", F32.neg(0.293))
  (U.choose(F32, U.string.equal(base, "middle"), (size * Font.font.metric(book, face, "xheight", 0.536) / 2.0 : F32),
    U.choose(F32, U.string.equal(base, "central"), (size * (ascender + descender) / 2.0 : F32),
      U.choose(F32, U.string.equal(base, "text-before-edge") || U.string.equal(base, "before-edge"), (size * ascender : F32),
        U.choose(F32, U.string.equal(base, "text-after-edge") || U.string.equal(base, "after-edge"), (size * descender : F32), 0.0)))) - shift : F32)

def text.glyph.node(outline: String, advance: F32, width: F32, extra: F32, x: F32, +matrix: Matrix, chunk: U32, index: U32) -> XML.Element:
  XML.Element{"#glyph", Con{XML.Attr{"#length-x", F32.show(x)}, Con{XML.Attr{"#length-width", F32.show(width)}, Con{XML.Attr{"#length-extra", F32.show(extra)}, Con{XML.Attr{"d", outline}, Con{XML.Attr{"#glyph-transform", matrix.show(matrix)}, Con{XML.Attr{"#glyph-advance", F32.show(advance)},
    Con{XML.Attr{"#text-chunk", U32.show(chunk)}, Con{XML.Attr{"#text-index", U32.show(index)}, Nil{}}}}}}}}}, Nil{}, ""}

def text.place(+cursor: TextCursor, +font: TextFont, +glyph: Font.FontGlyph, +pos: TextPosition, +ch: U32) -> TextLayout:
  TextCursor{oldx, oldy, index, oldchunk, start, oldanchor, prev, pc, pf, ps, seen, wasSpace, trailing, spacing, chunks} = cursor
  TextFont{size, face, weight, slant, anchor, letter, word, shift, baseline, kern, preserve, book} = font
  Font.FontGlyph{advance, outline, gid, leftClass, rightClass} = glyph
  TextPosition{TextValue{xx, setx}, TextValue{yy, sety}, TextValue{dx, setdx}, TextValue{dy, setdy}, TextValue{angle, seta}} = pos
  +fresh = setx || sety || Bool.not(seen)
  +factor = (size / 1000.0 : F32)
  +kerning = U.choose(F32, kern && Bool.not(fresh) && U32.is_eq(face, pf) && F32.is_eq(size, ps),
    (Font.font.kern(book, face, prev, pc, gid, rightClass) * factor : F32), 0.0)
  +x = (U.choose(F32, setx, xx, oldx) + dx + kerning : F32)
  +y = (U.choose(F32, sety, yy, oldy) + dy : F32)
  +chunk = U.choose(U32, fresh, U32.inc(oldchunk), oldchunk)
  +blank = U32.is_eq(ch, 32)
  +width = (advance * factor + letter + U.choose(F32, blank, word, 0.0) : F32)
  TextLayout{Con{text.glyph.node(outline, advance, width, (letter + U.choose(F32, blank, word, 0.0) : F32), x, matrix.mul(translate(x, (y + text.baseline(font) : F32)),
    matrix.mul(rotate(angle), scale(factor, F32.neg(factor)))), chunk, index), Nil{}},
    TextCursor{(x + width : F32), y, U32.inc(index), chunk, U.choose(F32, fresh, x, start), U.choose(String, fresh, anchor, oldanchor),
      gid, leftClass, face, size, True{}, blank, U.choose(F32, blank && Bool.not(preserve), width, 0.0), U.choose(F32, blank && Bool.not(preserve), spacing, letter),
      U.choose(List<&2, TextChunk>, fresh, text.chunk(cursor), chunks)}}

def text.character(+cursor: TextCursor, +font: TextFont, frames: List<&2, TextFrame>, +ch: U32) -> TextLayout:
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, previousSpace, trailing, spacing, chunks} = cursor
  TextFont{size, face, weight, slant, fa, letter, word, shift, baseline, kern, preserve, book} = font
  +blank = U.space(ch)
  +value = U.choose(U32, blank, 32, ch)
  U.branch(TextLayout, blank && previousSpace && Bool.not(preserve), _ => TextLayout{Nil{}, cursor},
    _ => text.place(cursor, font, Font.font.glyph(book, face, value), text.position(frames, index), value))

@unsafe
def text.characters(s: String, +font: TextFont, +frames: List<&2, TextFrame>, cursor: TextCursor) -> TextLayout:
  match s:
    case SNil{}: TextLayout{Nil{}, cursor}
    case SCon{Chr{ch}, rest}: text.layout.then(text.character(cursor, font, frames, ch), next => text.characters(rest, font, frames, next))

# Length fitting is applied inside-out; an explicitly fitted child is one fixed unit.
type TextMeasure is Data:
  TextMeasure{count: U32, lo: F32, hi: F32, extra: F32, fixed: F32}

def text.measure.empty() -> TextMeasure:
  TextMeasure{0, 1000000000.0, F32.neg(1000000000.0), 0.0, 0.0}

def text.measure.add(m: TextMeasure, +x: F32, +width: F32, extra: F32, fixed: Bool) -> TextMeasure:
  TextMeasure{count, lo, hi, oldExtra, oldFixed} = m
  TextMeasure{U32.inc(count), U.min(lo, x), U.max(hi, (x + width : F32)), extra, (oldFixed + U.choose(F32, fixed, width, 0.0) : F32)}

def text.measure.nodes(xs: List<&2, XML.Element>, +skip: String, +acc: TextMeasure) -> TextMeasure:
  match xs:
    case Nil{}: acc
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +attrs = as
      +glyph = U.string.equal(n, "#glyph")
      +fixed = U.string.equal(XML.attr.get(attrs, "#length-fixed", ""), "yes")
      text.measure.nodes(rest, skip, U.branch(TextMeasure, (glyph && Bool.not(U.string.equal(XML.attr.get(attrs, "#text-index", ""), skip))) || fixed,
        _ => text.measure.add(acc, U.scalar(XML.attr.get(attrs, "#length-x", "0"), 0.0), U.scalar(XML.attr.get(attrs, "#length-width", "0"), 0.0), U.scalar(XML.attr.get(attrs, "#length-extra", "0"), 0.0), fixed),
        _ => text.measure.nodes(kids, skip, acc)))

def text.length.matrix(m: Matrix, +ratio: F32, delta: F32) -> Matrix:
  Matrix{a, b, c, d, e, f} = m
  Matrix{(a * ratio : F32), (b * ratio : F32), c, d, (e + delta : F32), f}

def text.length.attrs(+as: List<&2, XML.Attr>, +ratio: F32, +delta: F32) -> List<&2, XML.Attr>:
  Con{XML.Attr{"#glyph-transform", matrix.show(text.length.matrix(transform(XML.attr.get(as, "#glyph-transform", ""), identity()), ratio, delta))},
    Con{XML.Attr{"#length-x", F32.show((U.scalar(XML.attr.get(as, "#length-x", "0"), 0.0) + delta : F32))},
      Con{XML.Attr{"#length-width", F32.show((U.scalar(XML.attr.get(as, "#length-width", "0"), 0.0) * ratio : F32))},
        Con{XML.Attr{"#length-extra", F32.show((U.scalar(XML.attr.get(as, "#length-extra", "0"), 0.0) * ratio : F32))}, as}}}}

def text.length.translate(xs: List<&2, XML.Element>, +delta: F32) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +attrs = as
      +tagname = n
      Con{XML.Element{tagname, U.choose(List<&2, XML.Attr>, U.string.equal(tagname, "#glyph") || U.string.equal(XML.attr.get(attrs, "#length-fixed", ""), "yes"), text.length.attrs(attrs, 1.0, delta), attrs),
        text.length.translate(kids, delta), txt}, text.length.translate(rest, delta)}

type TextFit is Data:
  TextFit{nodes: List<&2, XML.Element>, count: U32, fixed: F32}

def text.fit.append(nodes: List<&2, XML.Element>, result: TextFit) -> TextFit:
  TextFit{rest, endCount, endFixed} = result
  TextFit{text.nodes.append(nodes, rest), endCount, endFixed}

def text.fit.then(result: TextFit, next: U32 -> F32 -> TextFit) -> TextFit:
  TextFit{nodes, count, fixed} = result
  text.fit.append(nodes, next(count)(fixed))

def text.fit.group(n: String, as: List<&2, XML.Attr>, txt: String, result: TextFit) -> TextFit:
  TextFit{nodes, count, fixed} = result
  TextFit{Con{XML.Element{n, as, nodes, txt}, Nil{}}, count, fixed}

@unsafe
def text.fit.nodes(+xs: List<&2, XML.Element>, +origin: F32, +ratio: F32, +step: F32, +skip: String, +count: U32, +fixed: F32) -> TextFit:
  match xs:
    case Nil{}: TextFit{Nil{}, count, fixed}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +attrs = as
      +tagname = n
      +locked = U.string.equal(XML.attr.get(attrs, "#length-fixed", ""), "yes")
      +glyph = U.string.equal(tagname, "#glyph")
      +x = U.scalar(XML.attr.get(attrs, "#length-x", "0"), 0.0)
      +delta = ((x - origin - fixed) * (ratio - 1.0) + U32.to_f32(count) * step : F32)
      text.fit.then(U.branch(TextFit, locked || (glyph && Bool.not(U.string.equal(XML.attr.get(attrs, "#text-index", ""), skip))),
        _ => TextFit{Con{XML.Element{tagname, text.length.attrs(attrs, U.choose(F32, locked, 1.0, ratio), delta),
          text.length.translate(kids, delta), txt}, Nil{}}, U32.inc(count), (fixed + U.choose(F32, locked, U.scalar(XML.attr.get(attrs, "#length-width", "0"), 0.0), 0.0) : F32)},
        _ => text.fit.group(tagname, attrs, txt, text.fit.nodes(kids, origin, ratio, step, skip, count, fixed))),
        nextCount => nextFixed => text.fit.nodes(rest, origin, ratio, step, skip, nextCount, nextFixed))

def text.length.finish(fit: TextFit, cursor: TextCursor, delta: F32) -> TextLayout:
  TextFit{nodes, count, fixed} = fit
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  TextLayout{nodes, TextCursor{(x + delta : F32), y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks}}

def text.length.fit(+result: TextLayout, +m: TextMeasure, +target: F32, +stretch: Bool, +skip: String) -> TextLayout:
  TextLayout{nodes, cursor} = result
  TextMeasure{count, lo, hi, extra, fixed} = m
  +natural = (hi - lo - extra : F32)
  +free = (natural - fixed : F32)
  +ratio = U.choose(F32, stretch && F32.is_gt(free, 0.0), (U.max(0.0, (target - fixed : F32)) / U.max(free, 0.000001) : F32), 1.0)
  +step = U.choose(F32, Bool.not(stretch) && U32.is_gt(count, 1), ((target - natural) / U.max(1.0, (U32.to_f32(count) - 1.0 : F32)) : F32), 0.0)
  +delta = U.choose(F32, stretch, (free * (ratio - 1.0) - extra : F32), U.choose(F32, U32.is_gt(count, 1), (target - natural - extra : F32), 0.0))
  U.branch(TextLayout, U32.is_gt(count, 0) && F32.is_gt(natural, 0.0),
    _ => text.length.finish(text.fit.nodes(nodes, lo, ratio, step, skip, 0, 0.0), cursor, delta), _ => result)

def text.length.valid(num: U.Number) -> Bool:
  U.Number{x, tail, ok} = num
  ok && F32.is_ge(x, 0.0)

def text.length(+result: TextLayout, +as: List<&2, XML.Attr>, w: F32, size: F32, trimEnd: Bool) -> TextLayout:
  TextLayout{nodes, cursor} = result
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  +target = text.measure(U.number(XML.attr.get(as, "textLength", "-1")), w, size)
  +skip = U.choose(String, trimEnd && F32.is_gt(trailing, 0.0), U32.show((index - 1 : U32)), "#none")
  U.branch(TextLayout, text.length.valid(U.number(XML.attr.get(as, "textLength", "-1"))) && F32.is_ge(target, 0.0),
    _ => text.length.fit(result, text.measure.nodes(nodes, skip, text.measure.empty()), target, U.string.equal(XML.attr.get(as, "lengthAdjust", "spacing"), "spacingAndGlyphs"), skip), _ => result)

def text.length.group.attrs(+as: List<&2, XML.Attr>, +m: TextMeasure) -> List<&2, XML.Attr>:
  TextMeasure{count, lo, hi, extra, fixed} = m
  U.branch(List<&2, XML.Attr>, U32.is_gt(count, 0) && F32.is_ge(U.scalar(XML.attr.get(as, "textLength", "-1"), F32.neg(1.0)), 0.0),
    _ => Con{XML.Attr{"#length-fixed", "yes"}, Con{XML.Attr{"#length-x", F32.show(lo)}, Con{XML.Attr{"#length-width", F32.show((hi - lo - extra : F32))}, as}}}, _ => as)

def text.layout.group(+as: List<&2, XML.Attr>, +result: TextLayout) -> TextLayout:
  TextLayout{nodes, cursor} = result
  TextLayout{Con{XML.Element{"g", text.length.group.attrs(as, text.measure.nodes(nodes, "#none", text.measure.empty())), nodes, ""}, Nil{}}, cursor}

def text.path.layout(+as: List<&2, XML.Attr>, result: TextLayout, em: F32) -> TextLayout:
  TextLayout{nodes, cursor} = result
  +edges = text.path.geometry(as)
  TextLayout{instance.anonymous(Con{XML.Element{"g", Con{XML.Attr{"#text-path", "1"}, Con{XML.Attr{"#text-path-em", F32.show(em)}, as}}, nodes, ""}, Nil{}}), text.path.end(cursor, text.path.at(edges, text.path.total(edges), identity()))}

@unsafe
def text.layout(+xs: List<&2, XML.Element>, +font: TextFont, +frames: List<&2, TextFrame>, +cursor: TextCursor, +w: F32, +h: F32, +onPath: Bool) -> TextLayout:
  match xs:
    case Nil{}: TextLayout{Nil{}, cursor}
    case Con{XML.Element{n, attrs, kids, txt}, rest}:
      +as = CSS.properties(attrs)
      +childFont = text.font.inherit(font, as)
      text.layout.then(U.branch(TextLayout, U.string.equal(n, "#text"), _ => text.characters(txt, font, U.choose(List<&2, TextFrame>, onPath, text.path.frames(frames), frames), cursor),
        _ => U.branch(TextLayout, U.string.equal(n, "textPath") && Bool.not(U.string.equal(XML.attr.get(as, "display", ""), "none")),
          _ => text.path.layout(as, text.length(text.layout(kids, childFont, frames, text.path.begin(cursor), w, h, True{}), as, w, text.font.em(childFont), False{}), text.font.em(childFont)),
        _ => U.branch(TextLayout, (U.string.equal(n, "tspan") || U.string.equal(n, "a")) && Bool.not(U.string.equal(XML.attr.get(as, "display", ""), "none")),
          _ => text.layout.group(as, text.length(text.layout(kids, childFont, Con{text.frame(as, text.index(cursor), w, h, text.font.em(childFont)), frames}, cursor, w, h, onPath), as, w, text.font.em(childFont), False{})),
          _ => TextLayout{Nil{}, cursor}))),
        next => text.layout(rest, font, frames, next, w, h, onPath))

def text.chunk.shift(xs: List<&2, TextChunk>, +key: U32) -> F32:
  match xs:
    case Nil{}: 0.0
    case Con{TextChunk{id, shift}, rest}: U.branch(F32, U32.is_eq(id, key), _ => shift, _ => text.chunk.shift(rest, key))

def text.anchor.nodes(+xs: List<&2, XML.Element>, +chunks: List<&2, TextChunk>, +skip: String) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, attrs, kids, txt}, rest}:
      +tagname = n
      +as = attrs
      +glyph = U.string.equal(tagname, "#glyph")
      +shift = text.chunk.shift(chunks, F32.to_u32(U.scalar(XML.attr.get(as, "#text-chunk", "0"), 0.0)))
      +mat = matrix.mul(translate(F32.neg(shift), 0.0), transform(XML.attr.get(as, "#glyph-transform", ""), identity()))
      U.branch(List<&2, XML.Element>, glyph && U.string.equal(XML.attr.get(as, "#text-index", ""), skip),
        _ => text.anchor.nodes(rest, chunks, skip),
        _ => Con{XML.Element{tagname, U.choose(List<&2, XML.Attr>, glyph, Con{XML.Attr{"#glyph-transform", matrix.show(mat)}, as}, as),
          text.anchor.nodes(kids, chunks, skip), txt}, text.anchor.nodes(rest, chunks, skip)})

def text.path.glyph.matrix(+mat: Matrix, +position: Matrix, +advance: F32) -> Matrix:
  Matrix{a, b, c, d, e, f} = mat
  Matrix{tx, ty, nx, ny, px, py} = position
  +aa = (tx * a + nx * b : F32)
  +bb = (ty * a + ny * b : F32)
  Matrix{aa, bb, (tx * c + nx * d : F32), (ty * c + ny * d : F32), (px + nx * f - aa * advance / 2.0 : F32), (py + ny * f - bb * advance / 2.0 : F32)}

def text.path.glyph(+as: List<&2, XML.Attr>, +edges: List<&2, Edge>, +total: F32, offset: F32, +mat: Matrix) -> List<&2, XML.Element>:
  Matrix{a, b, c, d, e, f} = mat
  +advance = U.scalar(XML.attr.get(as, "#glyph-advance", "0"), 0.0)
  +mid = (e + advance * F32.sqrt((a * a + b * b : F32)) / 2.0 + offset : F32)
  U.branch(List<&2, XML.Element>, F32.is_lt(mid, 0.0) || F32.is_gt(mid, total) || F32.is_le(total, 0.0), _ => Nil{},
    _ => Con{XML.Element{"#glyph", Con{XML.Attr{"#glyph-transform", matrix.show(text.path.glyph.matrix(mat, text.path.at(edges, mid, identity()), advance))}, as}, Nil{}, ""}, Nil{}})

def text.path.map(+xs: List<&2, XML.Element>, +edges: List<&2, Edge>, +total: F32, +offset: F32) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      text.nodes.append(U.branch(List<&2, XML.Element>, U.string.equal(n, "#glyph"), _ => text.path.glyph(as, edges, total, offset, transform(XML.attr.get(as, "#glyph-transform", ""), identity())),
        _ => Con{XML.Element{n, as, text.path.map(kids, edges, total, offset), txt}, Nil{}}), text.path.map(rest, edges, total, offset))

def text.path.mapped(kids: List<&2, XML.Element>, +as: List<&2, XML.Attr>) -> List<&2, XML.Element>:
  +edges = text.path.geometry(as)
  +total = text.path.total(edges)
  text.path.map(kids, edges, total, text.path.offset(U.number(XML.attr.get(as, "startOffset", "0")), total, U.scalar(XML.attr.get(as, "#text-path-length", "0"), 0.0), U.scalar(XML.attr.get(as, "#text-path-em", "16"), 16.0)))

def text.path.finish(+xs: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      Con{XML.Element{n, as, U.branch(List<&2, XML.Element>, U.string.equal(XML.attr.get(as, "#text-path", ""), "1"), _ => text.path.mapped(kids, as), _ => text.path.finish(kids)), txt}, text.path.finish(rest)}

def text.cell(+mat: Matrix, +width: F32, box: Bounds) -> Bounds:
  bounds.point(bounds.point(bounds.point(bounds.point(box, matrix.point(mat, Point{0.0, F32.neg(293.0)})),
    matrix.point(mat, Point{width, F32.neg(293.0)})), matrix.point(mat, Point{width, 1069.0})), matrix.point(mat, Point{0.0, 1069.0}))

def text.bounds(xs: List<&2, XML.Element>, +matrix: Matrix, +box: Bounds) -> Bounds:
  match xs:
    case Nil{}: box
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +attrs = as
      +mat = matrix.mul(matrix, transform(XML.attr.get(attrs, "transform", ""), identity()))
      text.bounds(rest, matrix, text.bounds(kids, mat,
        U.branch(Bounds, U.string.equal(n, "#glyph"), _ => text.cell(matrix.mul(mat, transform(XML.attr.get(attrs, "#glyph-transform", ""), identity())),
          U.scalar(XML.attr.get(attrs, "#glyph-advance", "0"), 0.0), box), _ => box)))

def text.bounds.show(box: Bounds) -> String:
  Bounds{x0, y0, x1, y1} = box
  xy(x0, y0) ++ xy(x1, y1)

def text.paint.bounds(xs: List<&2, XML.Element>, +box: String) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}: Con{XML.Element{n, Con{XML.Attr{"#paint-box", box}, as}, text.paint.bounds(kids, box), txt}, text.paint.bounds(rest, box)}

def text.finished.nodes(+nodes: List<&2, XML.Element>, as: List<&2, XML.Attr>) -> XML.Element:
  +box = text.bounds.show(text.bounds(nodes, identity(), Bounds{1000000000.0, 1000000000.0, F32.neg(1000000000.0), F32.neg(1000000000.0)}))
  XML.Element{"g", Con{XML.Attr{"#paint-box", box}, as}, text.paint.bounds(nodes, box), ""}

def text.finish(+result: TextLayout, as: List<&2, XML.Attr>) -> XML.Element:
  TextLayout{nodes, cursor} = result
  TextCursor{x, y, index, chunk, start, anchor, prev, pc, pf, ps, seen, blankState, trailing, spacing, chunks} = cursor
  text.finished.nodes(text.path.finish(text.anchor.nodes(nodes, text.chunk(cursor), U.choose(String, F32.is_gt(trailing, 0.0), U32.show((index - 1 : U32)), "#none"))), as)

def text.font.reset(font: TextFont) -> TextFont:
  TextFont{size, face, weight, slant, anchor, letter, word, shift, baseline, kern, preserve, book} = font
  text.font.default(book)

def text.expand.node(+n: String, +as: List<&2, XML.Attr>, +kids: List<&2, XML.Element>, txt: String, +font: TextFont, +vp: Viewport,
  expand: List<&2, XML.Element> -> TextFont -> F32 -> F32 -> List<&2, XML.Element>) -> XML.Element:
  Viewport{matrix, w, h, clip, valid} = vp
  +f = U.choose(TextFont, U.string.equal(n, "#svg-image"), text.font.reset(font), text.font.inherit(font, as))
  U.branch(XML.Element, U.string.equal(n, "text"),
    _ => text.finish(text.length(text.layout(kids, f, Con{text.frame(as, 0, w, h, text.font.em(f)), Nil{}}, text.cursor(), w, h, False{}), as, w, text.font.em(f), True{}), as),
    _ => XML.Element{n, as, expand(kids)(f)(w)(h), txt})

@unsafe
def text.expand(xs: List<&2, XML.Element>, +font: TextFont, +w: F32, +h: F32, +root: Bool) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +tagname = n
      +attrs = as
      Con{text.expand.node(tagname, attrs, kids, txt, font, element.viewport(tagname, attrs, identity(), w, h, root),
        nodes => f => vw => vh => text.expand(nodes, f, vw, vh, False{})), text.expand(rest, font, w, h, root)}

type TextPaintRun is Data:
  TextPaintRun{nodes: List<&2, XML.Element>, rest: List<&2, XML.Element>}

def text.paint.reverse(xs: List<&2, XML.Element>, acc: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: acc
    case Con{h, t}: text.paint.reverse(t, Con{h, acc})

@unsafe
def text.paint.take(+xs: List<&2, XML.Element>, +acc: List<&2, XML.Element>) -> TextPaintRun:
  match xs:
    case Nil{}: TextPaintRun{text.paint.reverse(acc, Nil{}), Nil{}}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +name = n
      U.branch(TextPaintRun, U.string.equal(name, "#glyph"),
        _ => text.paint.take(rest, Con{XML.Element{name, as, kids, txt}, acc}), _ => TextPaintRun{text.paint.reverse(acc, Nil{}), xs})

def text.paint.attrs(xs: List<&2, XML.Element>) -> List<&2, XML.Attr>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}: Con{XML.Attr{"fill-rule", "nonzero"}, as}

def text.paint.run(run: TextPaintRun, next: List<&2, XML.Element> -> List<&2, XML.Element>) -> List<&2, XML.Element>:
  TextPaintRun{nodes, rest} = run
  +glyphs = nodes
  Con{XML.Element{"#glyph-run", text.paint.attrs(glyphs), glyphs, ""}, next(rest)}

@unsafe
def text.paint.group(+xs: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +name = n
      U.branch(List<&2, XML.Element>, U.string.equal(name, "#glyph"), _ => text.paint.run(text.paint.take(xs, Nil{}), remaining => text.paint.group(remaining)),
        _ => Con{XML.Element{name, as, text.paint.group(kids), txt}, text.paint.group(rest)})

# Resolve context paints after compiling the finite scene tree. Paint server
# coordinates stay in the referencing shape's space, including bounding boxes.
def context.unfaded(+brush: Brush) -> Brush:
  match brush:
    case Bitmap{raster, inv, nearest}: Bitmap{raster, inv, nearest}
    case Solid{col, source}: Solid{source, source}
    case PendingContext{stroke, opacity}: PendingContext{stroke, 1.0}
    case ContextPaint{source, matrix, opacity}: ContextPaint{source, matrix, 1.0}
    case Pattern{inverse, width, height, opacity, nodes}: Pattern{inverse, width, height, 1.0, nodes}
    case Tile{raster, inverse, width, height, opacity, u, v, grid}: Tile{raster, inverse, width, height, 1.0, u, v, grid}
    case Gradient{inv, radial, start, end, radius, fr, stops, spread, opacity, linear}: Gradient{inv, radial, start, end, radius, fr, stops, spread, 1.0, linear}

def context.select(paint: Paint<Brush>, stroke: Bool) -> Brush:
  Paint{f, s} = paint
  context.unfaded(U.choose(Brush, stroke, s, f))

def context.brush(brush: Brush, paint: Paint<Brush>, matrix: Matrix, patterns: List<&2, Scene<Brush>> -> List<&2, Scene<Brush>>) -> Brush:
  match brush:
    case Bitmap{raster, inv, nearest}: Bitmap{raster, inv, nearest}
    case Solid{col, source}: Solid{col, source}
    case PendingContext{stroke, opacity}: ContextPaint{context.select(paint, stroke), matrix, opacity}
    case ContextPaint{source, matrix, opacity}: ContextPaint{source, matrix, opacity}
    case Pattern{inverse, width, height, opacity, nodes}: Pattern{inverse, width, height, opacity, patterns(nodes)}
    case Tile{raster, inverse, width, height, opacity, u, v, grid}: Tile{raster, inverse, width, height, opacity, u, v, grid}
    case Gradient{inv, radial, start, end, radius, fr, stops, spread, opacity, linear}: Gradient{inv, radial, start, end, radius, fr, stops, spread, opacity, linear}

def context.empty() -> Paint<Brush>:
  Paint{Solid{Img.clear(), Img.clear()}, Solid{Img.clear(), Img.clear()}}

def context.paint(ink: Paint<Brush>, +paint: Paint<Brush>, +matrix: Matrix, fills: List<&2, Scene<Brush>> -> List<&2, Scene<Brush>>, strokes: List<&2, Scene<Brush>> -> List<&2, Scene<Brush>>) -> Paint<Brush>:
  Paint{f, s} = ink
  Paint{context.brush(f, paint, matrix, fills), context.brush(s, paint, matrix, strokes)}

def stroke.mesh.bounds(mesh: StrokeMesh) -> Bounds:
  StrokeMesh{stree, inv, cover} = mesh
  bounds.transform(edge.tree.bounds(stree), matrix.inverse(inv))

def scene.count(xs: List<&2, Scene<Brush>>) -> U32:
  match xs:
    case Nil{}: 0
    case Con{node, rest}: (1 + scene.count(rest) : U32)

def scene.coverage(xs: List<&2, Scene<Brush>>, box: Bounds) -> Bounds:
  match xs:
    case Nil{}: box
    case Con{Scene{es, objectBox, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      scene.coverage(rest, bounds.merge(box, coverage))

def scene.effect.coverage(effect: FilterEffect, cached: Bounds, computed: Bounds) -> Bounds:
  match effect:
    case FilterImage{raster}: cached
    case NoFilter{}: computed
    case FilterSpec{region, units, viewport, attrs, primitives}: computed

def scene.covered(+scene: Scene<Brush>) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect} = scene
  +own = bounds.merge(bounds.transform(fill.bounds(fillTree), matrix.inverse(inv)), stroke.mesh.bounds(outline))
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, markerNodes, scene.effect.coverage(effect, coverage, scene.coverage(markerNodes, scene.coverage(kids, own))), effect}

def context.node(scene: Scene<Brush>, +ink: Paint<Brush>, kids: List<&2, Scene<Brush>>, masks: List<&2, Scene<Brush>>, markers: Paint<Brush> -> List<&2, Scene<Brush>>) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, oldKids, id, oldInk, clip, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect} = scene
  scene.covered(Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, masks, maskMode, markers(ink), bounds.empty(), effect})

@unsafe
def context.scenes(+xs: List<&2, Scene<Brush>>, +paint: Paint<Brush>, +parent: Matrix) -> List<&2, Scene<Brush>>:
  match xs:
    case Nil{}: Nil{}
    case Con{Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      Con{context.node(Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect},
        context.paint(ink, paint, matrix.mul(parent, matrix.inverse(inv)),
          nodes => context.scenes(nodes, context.empty(), identity()), nodes => context.scenes(nodes, context.empty(), identity())),
        context.scenes(kids, paint, parent), context.scenes(maskNodes, context.empty(), identity()),
        source => context.scenes(markerNodes, source, inv)), context.scenes(rest, paint, parent)}

def image.svg.stack.empty(stack: List<&2, String>) -> Bool:
  match stack:
    case Nil{}: True{}
    case Con{head, tail}: False{}

@unsafe
def image.svg.wellformed(+tokens: List<&2, XML.Token>, +stack: List<&2, String>, +seen: Bool) -> Bool:
  match tokens stack:
    case Nil{} Nil{}: seen
    case Nil{} Con{head, tail}: False{}
    case Con{XML.Chars{content}, rest} stack:
      (Bool.not(image.svg.stack.empty(stack)) || U.string.equal(U.trim.both(content), "")) && image.svg.wellformed(rest, stack, seen)
    case Con{XML.Open{name, attrs, closed}, rest} stack:
      +top = image.svg.stack.empty(stack)
      U.branch(Bool, Bool.not(top) || (Bool.not(seen) && U.string.equal(name, "svg")),
        _ => image.svg.wellformed(rest, U.choose(List<&2, String>, closed, stack, Con{name, stack}), seen || top), _ => False{})
    case Con{XML.Shut{name}, rest} Nil{}: False{}
    case Con{XML.Shut{name}, rest} Con{head, tail}:
      U.string.equal(U.trim.both(name), head) && image.svg.wellformed(rest, tail, seen)

def image.svg.read(+text: String) -> XML.Element:
  +source = U.choose(String, U.prefix(text, "﻿"), U.drop(text, "﻿"), text)
  U.branch(XML.Element, image.svg.wellformed(XML.tokenize(source), Nil{}, False{}), _ => XML.parse(source), _ => XML.Element{"#document", Nil{}, Nil{}, ""})

# Expand data-URI SVG images into isolated vector subdocuments.
type ImageCodepoint is Data:
  ImageCodepoint{point: U32, step: U32}

@unsafe
def image.svg.utf8.tail(+data: Bin.Bytes, +at: U32, left: Nat, +acc: U32, +minimum: U32, +step: U32) -> ImageCodepoint:
  match left:
    case Zero{}: U.choose(ImageCodepoint, U32.is_ge(acc, minimum) && U32.is_le(acc, 1114111) && Bool.not(U32.is_ge(acc, 55296) && U32.is_le(acc, 57343)), ImageCodepoint{acc, step}, ImageCodepoint{65533, 1})
    case Succ{rest}:
      +v = Bin.bytes.get(data, at)
      U.branch(ImageCodepoint, U32.is_ge(v, 128) && U32.is_le(v, 191), _ => image.svg.utf8.tail(data, U32.inc(at), rest, (acc * 64 + v % 64 : U32), minimum, step), _ => ImageCodepoint{65533, 1})

def image.svg.utf8(+data: Bin.Bytes, +at: U32) -> ImageCodepoint:
  +v = Bin.bytes.get(data, at)
  U.branch(ImageCodepoint, U32.is_lt(v, 128), _ => ImageCodepoint{v, 1},
    _ => U.branch(ImageCodepoint, U32.is_ge(v, 194) && U32.is_le(v, 223), _ => image.svg.utf8.tail(data, U32.inc(at), 1n, (v % 32 : U32), 128, 2),
      _ => U.branch(ImageCodepoint, U32.is_ge(v, 224) && U32.is_le(v, 239), _ => image.svg.utf8.tail(data, U32.inc(at), 2n, (v % 16 : U32), 2048, 3),
        _ => U.branch(ImageCodepoint, U32.is_ge(v, 240) && U32.is_le(v, 244), _ => image.svg.utf8.tail(data, U32.inc(at), 3n, (v % 8 : U32), 65536, 4), _ => ImageCodepoint{65533, 1}))))

def image.svg.utf8.more(decoded: ImageCodepoint, acc: String, next: U32 -> String -> String) -> String:
  ImageCodepoint{point, step} = decoded
  next(step)(SCon{Chr{point}, acc})

@unsafe
def image.svg.byte.text(+data: Bin.Bytes, +at: U32, +acc: String) -> String:
  U.branch(String, U32.is_ge(at, Bin.bytes.size(data)), _ => U.rev(acc, ""), _ => image.svg.utf8.more(image.svg.utf8(data, at), acc, step => text => image.svg.byte.text(data, (at + step : U32), text)))

def image.svg.utf8.push(+out: Bin.Bytes, +c: U32) -> Bin.Bytes:
  U.branch(Bin.Bytes, U32.is_lt(c, 128), _ => Bin.bytes.push(out, c),
    _ => U.branch(Bin.Bytes, U32.is_lt(c, 2048), _ => Bin.bytes.push(Bin.bytes.push(out, (192 + c / 64 : U32)), (128 + c % 64 : U32)),
      _ => U.branch(Bin.Bytes, U32.is_lt(c, 65536), _ => Bin.bytes.push(Bin.bytes.push(Bin.bytes.push(out, (224 + c / 4096 : U32)), (128 + (c / 64) % 64 : U32)), (128 + c % 64 : U32)),
        _ => Bin.bytes.push(Bin.bytes.push(Bin.bytes.push(Bin.bytes.push(out, (240 + c / 262144 : U32)), (128 + (c / 4096) % 64 : U32)), (128 + (c / 64) % 64 : U32)), (128 + c % 64 : U32)))))

def image.svg.uri.bytes(+s: String, +out: Bin.Bytes) -> Bin.Bytes:
  match s:
    case SNil{}: out
    case SCon{Chr{37}, SCon{Chr{a}, SCon{Chr{b}, rest}}}:
      U.branch(Bin.Bytes, Bin.uri.hex.valid(a) && Bin.uri.hex.valid(b), _ => image.svg.uri.bytes(rest, Bin.bytes.push(out, (U.hex.digit(a) * 16 + U.hex.digit(b) : U32))), _ => Bin.bytes.empty())
    case SCon{Chr{c}, rest}:
      U.branch(Bin.Bytes, Bool.not(U32.is_eq(c, 37)), _ => image.svg.uri.bytes(rest, image.svg.utf8.push(out, c)), _ => Bin.bytes.empty())

def image.svg.source(+scan: U.Scan) -> String:
  U.Scan{mime, data} = scan
  +body = U.branch(Bin.Bytes, U.string.contains(CSS.css.lower(mime), ";base64"), _ => Bin.base64(data), _ => image.svg.uri.bytes(data, Bin.bytes.empty()))
  image.svg.byte.text(body, 0, "")

def image.svg.root(+xs: List<&2, XML.Element>) -> XML.Element:
  match xs:
    case Nil{}: XML.Element{"#empty", Nil{}, Nil{}, ""}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      U.branch(XML.Element, U.string.equal(n, "svg"), _ => XML.Element{n, as, kids, txt}, _ => image.svg.root(rest))

def image.svg.document(root: XML.Element) -> XML.Element:
  XML.Element{n, as, kids, txt} = root
  image.svg.root(kids)

# Intrinsic dimensions come from the root's own width/height attributes; the
# document stylesheet only styles the content once the viewport is known.
def image.svg.attrs(root: XML.Element) -> List<&2, XML.Attr>:
  XML.Element{n, as, kids, txt} = root
  as

def image.svg.absolute(+s: String) -> F32:
  U.branch(F32, U.string.equal(s, "auto") || U.string.contains(s, "%") || Bool.not(text.length.valid(U.number(s))), _ => F32.neg(1.0), _ => U.unit(U.number(s), 0.0))

def image.svg.ratio(+as: List<&2, XML.Attr>) -> F32:
  +w = image.svg.absolute(XML.attr.get(as, "width", "auto"))
  +h = image.svg.absolute(XML.attr.get(as, "height", "auto"))
  +vb = U.numbers(XML.attr.get(as, "viewBox", ""))
  +vw = U.nth(vb, 2n, 0.0)
  +vh = U.nth(vb, 3n, 0.0)
  U.choose(F32, F32.is_ge(w, 0.0) && F32.is_gt(h, 0.0), (w / U.max(h, 0.000001) : F32), U.choose(F32, F32.is_gt(vw, 0.0) && F32.is_gt(vh, 0.0), (vw / U.max(vh, 0.000001) : F32), 0.0))

def image.svg.size(+as: List<&2, XML.Attr>) -> Point:
  +w = image.svg.absolute(XML.attr.get(as, "width", "auto"))
  +h = image.svg.absolute(XML.attr.get(as, "height", "auto"))
  +ratio = image.svg.ratio(as)
  +hasW = F32.is_ge(w, 0.0)
  +hasH = F32.is_ge(h, 0.0)
  +hasRatio = F32.is_gt(ratio, 0.0)
  +dw = U.choose(F32, hasRatio, U.min(300.0, (150.0 * ratio : F32)), 300.0)
  +dh = U.choose(F32, hasRatio, (dw / U.max(ratio, 0.000001) : F32), 150.0)
  Point{U.choose(F32, hasW, w, U.choose(F32, hasH && hasRatio, (h * ratio : F32), dw)), U.choose(F32, hasH, h, U.choose(F32, hasW && hasRatio, (w / U.max(ratio, 0.000001) : F32), dh))}

def image.svg.normalized(root: XML.Element, size: Point) -> XML.Element:
  XML.Element{n, as, kids, txt} = root
  Point{w, h} = size
  XML.Element{n, Con{XML.Attr{"width", F32.show(w)}, Con{XML.Attr{"height", F32.show(h)}, as}}, kids, txt}

def image.svg.place(+as: List<&2, XML.Attr>, +size: Point, +root: XML.Element,
  expand: List<&2, XML.Element> -> F32 -> F32 -> List<&2, XML.Element>) -> XML.Element:
  Point{iw, ih} = size
  +ratio = image.svg.ratio(image.svg.attrs(root))
  +metadata = F32.show(iw) ++ " " ++ F32.show(ih) ++ " " ++ F32.show(ratio)
  +inside = {Con{root, Nil{}} : List<&2, XML.Element>}
  +styled = {Con{image.svg.normalized(image.svg.root(CSS.css.tree(inside, CSS.css.rules(CSS.css.sheets(inside, iw, ih), iw, ih), Nil{}, Nil{}, 1, 1)), size), Nil{}} : List<&2, XML.Element>}
  +frame = {Con{XML.Attr{"#image-size", metadata}, Con{XML.Attr{"x", XML.attr.get(as, "x", "0")}, Con{XML.Attr{"y", XML.attr.get(as, "y", "0")}, Con{XML.Attr{"width", XML.attr.get(as, "width", "auto")}, Con{XML.Attr{"height", XML.attr.get(as, "height", "auto")}, Con{XML.Attr{"viewBox", "0 0 " ++ F32.show(iw) ++ " " ++ F32.show(ih)}, Con{XML.Attr{"preserveAspectRatio", U.choose(String, F32.is_gt(ratio, 0.0), XML.attr.get(as, "preserveAspectRatio", "xMidYMid meet"), "none")}, Con{XML.Attr{"overflow", XML.attr.get(as, "overflow", "hidden")}, Nil{}}}}}}}}} : List<&2, XML.Attr>}
  XML.Element{"#svg-image", Con{XML.Attr{"#image-size", metadata}, as}, Con{XML.Element{"svg", frame, instance.anonymous(expand(styled)(iw)(ih)), ""}, Nil{}}, ""}

def image.svg.sized(as: List<&2, XML.Attr>, +root: XML.Element,
  expand: List<&2, XML.Element> -> F32 -> F32 -> List<&2, XML.Element>) -> XML.Element:
  image.svg.place(as, image.svg.size(image.svg.attrs(root)), root, expand)

def image.svg.node(as: List<&2, XML.Attr>, +root: XML.Element,
  expand: List<&2, XML.Element> -> F32 -> F32 -> List<&2, XML.Element>) -> XML.Element:
  image.svg.sized(as, root, expand)

def image.svg.mime.name(scan: U.Scan) -> Bool:
  U.Scan{name, rest} = scan
  U.string.equal(CSS.css.lower(U.trim.both(name)), "image/svg+xml")

def image.svg.mime(scan: U.Scan) -> Bool:
  U.Scan{name, data} = scan
  image.svg.mime.name(U.until(name, 59, ""))

def image.svg.scheme(scan: U.Scan) -> Bool:
  U.Scan{name, rest} = scan
  U.string.equal(CSS.css.lower(name), "data") && image.svg.mime(U.until(rest, 44, ""))

def image.svg.reference(href: String) -> Bool:
  image.svg.scheme(U.until(href, 58, ""))

@unsafe
def image.svg.expand(+fuel: Nat, +xs: List<&2, XML.Element>, +w: F32, +h: F32) -> List<&2, XML.Element>:
  match fuel xs:
    case Zero{} _: Nil{}
    case Succ{d} Nil{}: Nil{}
    case Succ{d} Con{XML.Element{n, attrs, kids, txt}, rest}:
      +as = CSS.properties(attrs)
      +href = U.trim.both(XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", "")))
      Con{U.branch(XML.Element, U.string.equal(n, "image") && image.svg.reference(href),
        _ => image.svg.node(as, image.svg.document(image.svg.read(image.svg.source(U.until(U.drop(href, "data:"), 44, "")))), nodes => iw => ih => image.svg.expand(d, nodes, iw, ih)),
        _ => XML.Element{n, attrs, image.svg.expand(fuel, kids, w, h), txt}), image.svg.expand(fuel, rest, w, h)}

# Font loading must include text hidden inside an SVG image data URI.
def text.present(+xs: List<&2, XML.Element>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{XML.Element{n, as, kids, txt}, rest}: U.string.equal(n, "text") || (U.string.equal(n, "image") && image.svg.reference(U.trim.both(XML.attr.get(as, "href", XML.attr.get(as, "xlink:href", ""))))) || text.present(kids) || text.present(rest)

# The expansion passes each rebuild the whole tree, so a document without
# images, uses or text skips them; an embedded SVG image may bring any of the
# three, so images imply all passes.
def expand.images(has: Bool, xs: List<&2, XML.Element>, +w: F32, +h: F32) -> List<&2, XML.Element>:
  match has:
    case True{}: image.svg.expand(16n, xs, w, h)
    case False{}: xs

def expand.uses(has: Bool, +xs: List<&2, XML.Element>) -> List<&2, XML.Element>:
  match has:
    case True{}: use.expand(64n, xs, xs, Nil{})
    case False{}: xs

def expand.text(has: Bool, +xs: List<&2, XML.Element>, book: Font.FontBook, +w: F32, +h: F32) -> List<&2, XML.Element>:
  match has:
    case True{}: text.paint.group(text.expand(text.path.resolve(xs, xs, w, h, True{}), text.font.default(book), w, h, True{}))
    case False{}: xs

# Without a stylesheet the CSS pass would only merge style attributes, which
# CSS.properties does on demand, so the tree is used as parsed.
def document.styled(has: Bool, +kids: List<&2, XML.Element>, +w: F32, +h: F32) -> List<&2, XML.Element>:
  match has:
    case True{}: CSS.css.tree(kids, CSS.css.rules(CSS.css.sheets(kids, w, h), w, h), Nil{}, Nil{}, 1, CSS.css.element.count(kids))
    case False{}: kids

def document.camera.fonts(+root: XML.Element, +w: F32, +h: F32, matrix: Matrix, book: Font.FontBook) -> List<&2, Scene<Brush>>:
  XML.Element{n, a, kids, txt} = root
  +kinds = XML.elements.kinds(kids, 0)
  +images = U32.is_gt(U32.and(kinds, 1), 0)
  +styled = document.styled(images || U32.is_gt(U32.and(kinds, 8), 0), kids, w, h)
  +nodes = expand.text(images || U32.is_gt(U32.and(kinds, 4), 0), expand.uses(images || U32.is_gt(U32.and(kinds, 2), 0), expand.images(images, styled, w, h)), book, w, h)
  context.scenes(compile(64n, nodes, style.default(), matrix, w, h, resources(nodes, a), True{}, Nil{}, 1.0), context.empty(), identity())

def document.fonts(root: XML.Element, w: F32, h: F32, book: Font.FontBook) -> List<&2, Scene<Brush>>:
  document.camera.fonts(root, w, h, identity(), book)

# The document viewport and the output matrix have independent dimensions.
def document.size(+root: XML.Element, +w: F32, +h: F32) -> Point:
  XML.Element{n, attrs, kids, txt} = root
  +kinds = XML.elements.kinds(kids, 0)
  +styled = document.styled(U32.is_gt(U32.and(kinds, 9), 0), kids, w, h)
  +as = image.svg.attrs(image.svg.root(styled))
  Point{U.max(0.0, viewport.dimension(as, "width", w)), U.max(0.0, viewport.dimension(as, "height", h))}

def document.fit.matrix(size: Point, +w: F32, +h: F32) -> Matrix:
  Point{width, height} = size
  +vw = width
  +vh = height
  +zoom = U.min((w / U.max(vw, 0.000001) : F32), (h / U.max(vh, 0.000001) : F32))
  Matrix{zoom, 0.0, 0.0, zoom, ((w - vw * zoom) * 0.5 : F32), ((h - vh * zoom) * 0.5 : F32)}

def document.natural.size(root: XML.Element, matrix: Matrix, book: Font.FontBook, size: Point) -> List<&2, Scene<Brush>>:
  Point{vw, vh} = size
  document.camera.fonts(root, vw, vh, matrix, book)

def document.natural.fonts(+root: XML.Element, +w: F32, +h: F32, matrix: Matrix, book: Font.FontBook) -> List<&2, Scene<Brush>>:
  document.natural.size(root, matrix, book, document.size(root, w, h))

def document.fitted.size(root: XML.Element, w: F32, h: F32, book: Font.FontBook, +size: Point) -> List<&2, Scene<Brush>>:
  Point{vw, vh} = size
  document.camera.fonts(root, vw, vh, document.fit.matrix(size, w, h), book)

def document.fitted.fonts(+root: XML.Element, +w: F32, +h: F32, book: Font.FontBook) -> List<&2, Scene<Brush>>:
  document.fitted.size(root, w, h, book, document.size(root, w, h))

def document(root: XML.Element, w: F32, h: F32) -> List<&2, Scene<Brush>>:
  document.fonts(root, w, h, Font.font.empty())

# Every fill, stroke and clip carries its analytic coverage (see cover.scenes), so
# one sample at the pixel center reads exact area coverage; paint is evaluated there.
def pixel.color(+scene: List<&2, Scene<Brush>>, x: U32, y: U32, +aa: U32) -> Img.Color:
  +center = {Point{(U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32)} : Point}
  sample(scene, center, center, Img.clear(), False{}, 1.0)

def channel(x: F32) -> U32:
  F32.to_u32(F32.floor((U.clamp(x, 0.0, 1.0) * 255.0 + 0.5 : F32)))

def color.pack(c: Img.Color) -> U32:
  Img.Color{r, g, b, a} = c
  (channel(r) * 65536 + channel(g) * 256 + channel(b) : U32)

def pixel(+scene: List<&2, Scene<Brush>>, x: U32, y: U32, aa: U32) -> U32:
  color.pack(color.over(pixel.color(scene, x, y, aa), color.rgb(16777215)))

def bounds.nonempty(b: Bounds) -> Bool:
  Bounds{x0, y0, x1, y1} = b
  F32.is_gt(x1, x0) && F32.is_gt(y1, y0)

def bounds.expand(b: Bounds, +margin: F32) -> Bounds:
  Bounds{x0, y0, x1, y1} = b
  Bounds{(x0 - margin : F32), (y0 - margin : F32), (x1 + margin : F32), (y1 + margin : F32)}

def bounds.overlap(a: Bounds, b: Bounds) -> Bool:
  Bounds{x0, y0, x1, y1} = a
  Bounds{u0, v0, u1, v1} = b
  F32.is_le(x0, u1) && F32.is_le(u0, x1) && F32.is_le(y0, v1) && F32.is_le(v0, y1)

@unsafe
def raster.depth(+size: U32, +side: U32, +depth: Nat) -> Nat:
  U.branch(Nat, U32.is_ge(side, size), _ => depth, _ => raster.depth(size, (side * 2 : U32), 1n+depth))

def raster.format(box: Bounds, requested: F32) -> Raster:
  Bounds{x0, y0, x1, y1} = box
  +x = x0
  +y = y0
  +right = x1
  +bottom = y1
  +step = U.max(U.max(requested, 0.000001), (U.max((right - x : F32), (bottom - y : F32)) / 1022.0 : F32))
  +ox = (F32.floor((x / step : F32)) * step : F32)
  +oy = (F32.floor((y / step : F32)) * step : F32)
  +w = F32.to_u32(U.clamp(F32.ceil(((right - ox) / step : F32)), 0.0, 1024.0))
  +h = F32.to_u32(U.clamp(F32.ceil(((bottom - oy) / step : F32)), 0.0, 1024.0))
  Raster{Point{ox, oy}, step, w, h, raster.depth(U.choose(U32, U32.is_gt(w, h), w, h), 1, 0n), False{}, Img.Flat{Img.clear()}}

def raster.empty() -> Raster:
  Raster{Point{0.0, 0.0}, 1.0, 0, 0, 0n, False{}, Img.Flat{Img.clear()}}

def raster.store(format: Raster, pixels: Img.Pixels, linear: Bool) -> Raster:
  Raster{origin, step, width, height, depth, oldLinear, oldPixels} = format
  Raster{origin, step, width, height, depth, linear, pixels}

def raster.position(+format: Raster, x: F32, y: F32) -> Point:
  Raster{Point{ox, oy}, step, width, height, depth, pixelsLinear, pixels} = format
  Point{(ox + x * step : F32), (oy + y * step : F32)}

def raster.scale(format: Raster) -> F32:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = format
  step

def raster.is.linear(format: Raster) -> Bool:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = format
  pixelsLinear

def raster.tile.box(+format: Raster, +x: U32, +y: U32, size: U32) -> Bounds:
  +n = U32.to_f32(size)
  +xx = U32.to_f32(x)
  +yy = U32.to_f32(y)
  bounds.point(bounds.point(bounds.empty(), raster.position(format, xx, yy)), raster.position(format, (xx + n : F32), (yy + n : F32)))

def raster.in.frame(format: Raster, x: U32, y: U32) -> Bool:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = format
  U32.is_lt(x, width) && U32.is_lt(y, height)

def raster.scene.pixel(+format: Raster, +x: U32, +y: U32, nodes: List<&2, Scene<Brush>>, +aa: U32) -> Img.Color:
  +center = raster.position(format, (U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32))
  sample(nodes, center, center, Img.clear(), False{}, 1.0)

def raster.scene.tiles(depth: Nat, +x: U32, +y: U32, +format: Raster, +nodes: List<&2, Scene<Brush>>, +box: Bounds, +aa: U32) -> Img.Pixels:
  match depth:
    case 0n:
      U.branch(Img.Pixels, raster.in.frame(format, x, y) && bounds.overlap(box, raster.tile.box(format, x, y, 1)),
        _ => Img.Flat{raster.scene.pixel(format, x, y, nodes, aa)}, _ => Img.Flat{Img.clear()})
    case 1n+d:
      +dd = d
      +half = U32.shln(1, dd)
      U.branch(Img.Pixels, raster.in.frame(format, x, y) && bounds.overlap(box, raster.tile.box(format, x, y, (half * 2 : U32))),
        _ => Img.pixels.join(raster.scene.tiles(dd, x, y, format, nodes, box, aa), raster.scene.tiles(dd, (x + half : U32), y, format, nodes, box, aa), raster.scene.tiles(dd, x, (y + half : U32), format, nodes, box, aa), raster.scene.tiles(dd, (x + half : U32), (y + half : U32), format, nodes, box, aa)), _ => Img.Flat{Img.clear()})

# ---- coverage pass ----
# Before a raster is painted, every fill, stroke outline and clip shape gets a
# coverage mask on that raster's grid (cover.bend), and every pattern brush is
# rendered once into a tile raster at the grid's resolution; sampling then reads
# one value per pixel instead of testing a grid of sub-samples.

# Sub-scanlines per pixel row: the requested AA level, never below four.
def cover.sub(+aa: U32) -> U32:
  U.choose(U32, U32.is_lt(aa, 4), 4, aa)

def cover.pixel(+frame: Raster, p: Point) -> Point:
  Raster{Point{ox, oy}, step, width, height, depth, linear, pixels} = frame
  Point{x, y} = p
  +stepDup = step
  Point{((x - ox) / stepDup : F32), ((y - oy) / stepDup : F32)}

def cover.line(a: Point, b: Point) -> Cov.CovLine:
  Point{ax, ay} = a
  Point{bx, by} = b
  Cov.CovLine{ax, ay, bx, by}

def cover.lines(es: List<&2, Edge>, +frame: Raster) -> List<&2, Cov.CovLine>:
  match es:
    case Nil{}: Nil{}
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}: Con{cover.line(cover.pixel(frame, Point{ax, ay}), cover.pixel(frame, Point{bx, by})), cover.lines(rest, frame)}

# Local edges through m onto the frame's pixel grid in one pass.
def cover.lines.add(acc: Cov.CovLines, a: Point, b: Point) -> Cov.CovLines:
  Point{ax, ay} = a
  Point{bx, by} = b
  Cov.lines.add(acc, ax, ay, bx, by)

def cover.lines.through(es: List<&2, Edge>, +m: Matrix, +frame: Raster, acc: Cov.CovLines) -> Cov.CovLines:
  match es:
    case Nil{}: acc
    case Con{Edge{ax, ay, bx, by, stroked, closed}, rest}: cover.lines.through(rest, m, frame, cover.lines.add(acc, cover.pixel(frame, matrix.point(m, Point{ax, ay})), cover.pixel(frame, matrix.point(m, Point{bx, by}))))

# With `trees` the mask carries the quadtree that clip and pixel queries
# need; a fill painted directly keeps only its rows of runs.
def cover.build(lines: Cov.CovLines, +even: Bool, +frame: Raster, +sub: U32, +trees: Bool) -> Cover:
  Raster{origin, step, width, height, depth, linear, pixels} = frame
  Cover{Cov.mask.lined(lines, even, width, height, sub, trees), origin, step}

# Local edges through m (local to device) onto the frame's pixel grid.
def cover.edges(es: List<&2, Edge>, +m: Matrix, +even: Bool, +frame: Raster, +sub: U32, +trees: Bool) -> Cover:
  cover.build(cover.lines.through(es, m, frame, Cov.lines.empty()), even, frame, sub, trees)

def cover.tree.edges(t: EdgeTree, acc: List<&2, Edge>) -> List<&2, Edge>:
  match t:
    case EdgeFlat{box, edges}: edges

def cover.reverse(pts: List<&2, Point>, acc: List<&2, Point>) -> List<&2, Point>:
  match pts:
    case Nil{}: acc
    case Con{p, rest}: cover.reverse(rest, Con{p, acc})

def cover.area(pts: List<&2, Point>, +first: Point, +acc: F32) -> F32:
  match pts:
    case Nil{}: acc
    case Con{p, Nil{}}: (acc + point.cross(p, first) : F32)
    case Con{p, Con{q, rest}}:
      +qq = q
      cover.area(Con{qq, rest}, first, (acc + point.cross(p, qq) : F32))

# Every part polygon is oriented the same way so nonzero winding unions them.
def cover.oriented(pts: List<&2, Point>) -> List<&2, Point>:
  match pts:
    case Nil{}: Nil{}
    case Con{p, rest}:
      +pp = p
      +ps = {Con{pp, rest} : List<&2, Point>}
      U.branch(List<&2, Point>, F32.is_lt(cover.area(ps, pp, 0.0), 0.0), _ => cover.reverse(ps, Nil{}), _ => ps)

def cover.close(pts: List<&2, Point>, +first: Point, acc: List<&2, Edge>) -> List<&2, Edge>:
  match pts:
    case Nil{}: acc
    case Con{p, Nil{}}: Con{edge.of(p, first, True{}, True{}), acc}
    case Con{p, Con{q, rest}}:
      +qq = q
      Con{edge.of(p, qq, True{}, True{}), cover.close(Con{qq, rest}, first, acc)}

def cover.polygon(pts: List<&2, Point>, acc: List<&2, Edge>) -> List<&2, Edge>:
  match pts:
    case Nil{}: acc
    case Con{p, rest}:
      +pp = p
      cover.close(Con{pp, rest}, pp, acc)

def cover.arc(n: Nat, +c: Point, +r: F32, +angle: F32, +step: F32, acc: List<&2, Point>) -> List<&2, Point>:
  match n:
    case 0n: cover.reverse(Con{point.add(c, Point{(r * F32.cos(angle) : F32), (r * F32.sin(angle) : F32)}), acc}, Nil{})
    case 1n+d: cover.arc(d, c, r, (angle + step : F32), step, Con{point.add(c, Point{(r * F32.cos(angle) : F32), (r * F32.sin(angle) : F32)}), acc})

def cover.segments(+extent: F32, +radius: F32) -> U32:
  F32.to_u32(U.clamp((F32.ceil((extent * F32.sqrt((radius * 2.5 : F32)) : F32)) + 2.0 : F32), 3.0, 64.0))

def cover.wrap(+a: F32) -> F32:
  (a - 6.283185307179586 * F32.floor((a / 6.283185307179586 : F32)) : F32)

def cover.angle(p: Point) -> F32:
  Point{x, y} = p
  F32.atan2(y, x)

def cover.scale(+m: Matrix, +frame: Raster) -> F32:
  Matrix{a, b, c, d, e, f} = m
  Raster{origin, step, width, height, depth, linear, pixels} = frame
  (F32.sqrt(F32.abs((a * d - b * c : F32))) / step : F32)

# The covered mesh keeps its bounds and cover; its edges are consumed.
def cover.stroke(mesh: StrokeMesh, +frame: Raster, +sub: U32, +trees: Bool) -> StrokeMesh:
  StrokeMesh{stree, inv, old} = mesh
  EdgeFlat{box, edges} = stree
  +iv = inv
  StrokeMesh{EdgeFlat{box, Nil{}}, iv, cover.edges(edges, matrix.inverse(iv), False{}, frame, sub, trees)}

def cover.clip(c: Clip, +frame: Raster, +sub: U32) -> Clip:
  match c:
    case ClipAll{}: ClipAll{}
    case ClipShape{es, inv, even, old}:
      +tree = es
      +iv = inv
      +ev = even
      ClipShape{tree, iv, ev, cover.edges(cover.tree.edges(tree, Nil{}), matrix.inverse(iv), ev, frame, sub, True{})}
    case ClipUnion{a, b}: ClipUnion{cover.clip(a, frame, sub), cover.clip(b, frame, sub)}
    case ClipIntersect{a, b}: ClipIntersect{cover.clip(a, frame, sub), cover.clip(b, frame, sub)}

def cover.fill.if(paints: Bool, f: Fill, es: List<&2, Edge>, +m: Matrix, +even: Bool, +frame: Raster, +sub: U32, +trees: Bool) -> Fill:
  match paints:
    case True{}:
      Fill{box, old} = f
      Fill{box, cover.edges(es, m, even, frame, sub, trees)}
    case False{}: f

def cover.stroke.if(paints: Bool, mesh: StrokeMesh, +frame: Raster, +sub: U32, +trees: Bool) -> StrokeMesh:
  match paints:
    case True{}: cover.stroke(mesh, frame, sub, trees)
    case False{}: mesh

# Whether a style paints its fill or its stroke at all; masks are only built for those.
def style.fills(+s: Style) -> Bool:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  visible && Bool.not(U.string.equal(fill, "none"))

def style.strokes(+s: Style) -> Bool:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  visible && Bool.not(U.string.equal(stroke, "none")) && F32.is_gt(width, 0.0)

def cover.rule(+s: Style) -> Bool:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  even

# ---- pattern tiles ----
# Device pixels per pattern unit along the denser tile axis; m maps pattern space to device.
def cover.density(+m: Matrix, +frame: Raster) -> F32:
  Matrix{a, b, c, d, e, f} = m
  (U.max(F32.sqrt((a * a + b * b : F32)), F32.sqrt((c * c + d * d : F32))) / raster.scale(frame) : F32)

def cover.tile.frame(+w: F32, +h: F32, +density: F32) -> Raster:
  raster.format(Bounds{0.0, 0.0, w, h}, (1.0 / U.max(density, 0.000001) : F32))

def cover.tile.wrapped(p: Point, +w: F32, +h: F32) -> Point:
  Point{x, y} = p
  Point{tile.wrap(x, w), tile.wrap(y, h)}

# Pixel centers wrap into the tile, so a partial last column or row shows the tile's start.
def cover.tile.center(+frame: Raster, +x: U32, +y: U32, +w: F32, +h: F32) -> Point:
  cover.tile.wrapped(raster.position(frame, (U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32)), w, h)

@unsafe
def cover.tile.pixels(depth: Nat, +x: U32, +y: U32, +frame: Raster, +nodes: List<&2, Scene<Brush>>, +box: Bounds, +w: F32, +h: F32) -> Img.Pixels:
  match depth:
    case 0n:
      +center = cover.tile.center(frame, x, y, w, h)
      U.branch(Img.Pixels, raster.in.frame(frame, x, y) && bounds.inside(box, center, 0.01), _ => Img.Flat{sample(nodes, center, center, Img.clear(), False{}, 1.0)}, _ => Img.Flat{Img.clear()})
    case 1n+d:
      +dd = d
      +half = U32.shln(1, dd)
      U.branch(Img.Pixels, raster.in.frame(frame, x, y),
        _ => Img.pixels.join(cover.tile.pixels(dd, x, y, frame, nodes, box, w, h), cover.tile.pixels(dd, (x + half : U32), y, frame, nodes, box, w, h), cover.tile.pixels(dd, x, (y + half : U32), frame, nodes, box, w, h), cover.tile.pixels(dd, (x + half : U32), (y + half : U32), frame, nodes, box, w, h)),
        _ => Img.Flat{Img.clear()})

def cover.tile(+frame: Raster, nodes: List<&2, Scene<Brush>>, +w: F32, +h: F32) -> Raster:
  Raster{origin, step, width, height, depth, linear, pixels} = frame
  +ns = nodes
  raster.store(frame, cover.tile.pixels(depth, 0, 0, frame, ns, scene.coverage(ns, bounds.empty()), w, h), False{})

# ---- bitmap minification ----
# An image drawn smaller than its pixels is box-filtered down to its device
# footprint first (area weights over the source pixels each output pixel
# covers), so a bilinear read at the pixel center approximates area filtering.

# Overlap of [lo, hi) with source pixel i.
def reduce.weight(+lo: F32, +hi: F32, +i: U32) -> F32:
  U.max((U.min(hi, (U32.to_f32(i) + 1.0 : F32)) - U.max(lo, U32.to_f32(i)) : F32), 0.0)

@unsafe
def reduce.cols(+pixels: Img.Pixels, +side: U32, +x: U32, +y: U32, +lo: F32, +hi: F32, +wy: F32, n: Nat, acc: Img.Color) -> Img.Color:
  match n:
    case 0n: acc
    case 1n+d: reduce.cols(pixels, side, (x + 1 : U32), y, lo, hi, wy, d, color.add(acc, color.fade(Img.pixels.get(pixels, side, x, y), (reduce.weight(lo, hi, x) * wy : F32))))

@unsafe
def reduce.rows(+pixels: Img.Pixels, +side: U32, +x: U32, +y: U32, +x0: F32, +x1: F32, +y0: F32, +y1: F32, +nx: Nat, n: Nat, acc: Img.Color) -> Img.Color:
  match n:
    case 0n: acc
    case 1n+d: reduce.rows(pixels, side, x, (y + 1 : U32), x0, x1, y0, y1, nx, d, reduce.cols(pixels, side, x, y, x0, x1, reduce.weight(y0, y1, y), nx, acc))

# Output pixel (x, y) covers source [x fx, (x + 1) fx) by [y fy, (y + 1) fy), clipped to the image.
def reduce.cell(+pixels: Img.Pixels, +side: U32, +x: U32, +y: U32, +w: U32, +h: U32, +fx: F32, +fy: F32) -> Img.Color:
  +x0 = (U32.to_f32(x) * fx : F32)
  +y0 = (U32.to_f32(y) * fy : F32)
  +x1 = U.min((x0 + fx : F32), U32.to_f32(w))
  +y1 = U.min((y0 + fy : F32), U32.to_f32(h))
  +ix = F32.to_u32(F32.floor(x0))
  +iy = F32.to_u32(F32.floor(y0))
  +area = ((x1 - x0) * (y1 - y0) : F32)
  U.branch(Img.Color, F32.is_le(area, 0.0), _ => Img.clear(),
    _ => color.fade(reduce.rows(pixels, side, ix, iy, x0, x1, y0, y1, U32.to_nat((F32.to_u32(F32.ceil(x1)) - ix : U32)), U32.to_nat((F32.to_u32(F32.ceil(y1)) - iy : U32)), Img.clear()), (1.0 / area : F32)))

@unsafe
def reduce.pixels(depth: Nat, +x: U32, +y: U32, +pixels: Img.Pixels, +side: U32, +w: U32, +h: U32, +fx: F32, +fy: F32, +rw: U32, +rh: U32) -> Img.Pixels:
  match depth:
    case 0n: U.branch(Img.Pixels, U32.is_lt(x, rw) && U32.is_lt(y, rh), _ => Img.Flat{reduce.cell(pixels, side, x, y, w, h, fx, fy)}, _ => Img.Flat{Img.clear()})
    case 1n+d:
      +dd = d
      +half = U32.shln(1, dd)
      U.branch(Img.Pixels, U32.is_lt(x, rw) && U32.is_lt(y, rh),
        _ => Img.pixels.join(reduce.pixels(dd, x, y, pixels, side, w, h, fx, fy, rw, rh), reduce.pixels(dd, (x + half : U32), y, pixels, side, w, h, fx, fy, rw, rh), reduce.pixels(dd, x, (y + half : U32), pixels, side, w, h, fx, fy, rw, rh), reduce.pixels(dd, (x + half : U32), (y + half : U32), pixels, side, w, h, fx, fy, rw, rh)),
        _ => Img.Flat{Img.clear()})

# Resample to rw by rh pixels, each covering fx by fy source pixels.
def raster.resample(+r: Raster, +rw: U32, +rh: U32, +fx: F32, +fy: F32) -> Raster:
  Raster{origin, step, width, height, depth, linear, pixels} = r
  +rd = raster.depth(U.choose(U32, U32.is_gt(rw, rh), rw, rh), 1, 0n)
  Raster{origin, step, rw, rh, rd, linear, reduce.pixels(rd, 0, 0, pixels, U32.shln(1, depth), width, height, fx, fy, rw, rh)}

# Reduce a whole image to rw by rh pixels; the caller rescales the brush inverse to match.
def raster.reduce(+r: Raster, +rw: U32, +rh: U32) -> Raster:
  Raster{origin, step, width, height, depth, linear, pixels} = r
  raster.resample(r, rw, rh, (U32.to_f32(width) / U32.to_f32(rw) : F32), (U32.to_f32(height) / U32.to_f32(rh) : F32))

# An axis-aligned tile of at least four device pixels is rendered at device
# density and read bilinearly (nearest-neighbour images stay crisp). A rotated,
# skewed or tiny tile is rendered at `sub` times the density, or at least four
# pixels across, and read with a sub by sub grid of nearest lookups over each
# device pixel's footprint: rotated content keeps supersampled edges and a tile
# smaller than a pixel averages out.
def cover.aligned(+m: Matrix) -> Bool:
  Matrix{a, b, c, d, e, f} = m
  F32.is_le((F32.abs(b) + F32.abs(c) : F32), (0.001 * (F32.abs(a) + F32.abs(d) : F32) : F32))

# The linear part of m applied to (x, y).
def cover.vector(+m: Matrix, +x: F32, +y: F32) -> Point:
  Matrix{a, b, c, d, e, f} = m
  Point{(a * x + c * y : F32), (b * x + d * y : F32)}

# Device pixels per image pixel along each image axis; m maps image pixels to device.
def cover.axes(+m: Matrix, +frame: Raster) -> Point:
  Matrix{a, b, c, d, e, f} = m
  +st = raster.scale(frame)
  Point{(F32.sqrt((a * a + b * b : F32)) / st : F32), (F32.sqrt((c * c + d * d : F32)) / st : F32)}

def cover.reduced(+size: U32, +density: F32) -> U32:
  +n = F32.to_u32(F32.ceil((U32.to_f32(size) * U.min(density, 1.0) : F32)))
  U.choose(U32, U32.is_lt(n, 1), 1, n)

def cover.bitmap.sized(+raster: Raster, +inv: Matrix, +nearest: Bool, +w: U32, +h: U32, +rw: U32, +rh: U32) -> Brush:
  U.branch(Brush, Bool.not(nearest) && (U32.is_lt(rw, w) || U32.is_lt(rh, h)),
    _ => Bitmap{raster.reduce(raster, rw, rh), matrix.mul(scale((U32.to_f32(rw) / U32.to_f32(w) : F32), (U32.to_f32(rh) / U32.to_f32(h) : F32)), inv), nearest},
    _ => Bitmap{raster, inv, nearest})

# A minified image is box-filtered down to its device footprint (see raster.resample).
def cover.bitmap(+raster: Raster, +inv: Matrix, +nearest: Bool, axes: Point) -> Brush:
  Raster{origin, step, width, height, depth, linear, pixels} = raster
  Point{dx, dy} = axes
  cover.bitmap.sized(raster, inv, nearest, width, height, cover.reduced(width, dx), cover.reduced(height, dy))

# A pattern brush becomes a tile raster at the frame's resolution, its content
# covered on that tile grid first; m maps the brush's local space to device space.
def cover.brush(brush: Brush, +m: Matrix, +frame: Raster, +sub: U32, cover: List<&2, Scene<Brush>> -> Raster -> U32 -> List<&2, Scene<Brush>>) -> Brush:
  match brush:
    case Bitmap{raster, inv, nearest}:
      +matrix = inv
      cover.bitmap(raster, matrix, nearest, cover.axes(matrix.mul(m, matrix.inverse(matrix)), frame))
    case Solid{c, source}: Solid{c, source}
    case PendingContext{stroke, opacity}: PendingContext{stroke, opacity}
    case ContextPaint{source, mat, opacity}:
      +matrix = mat
      ContextPaint{cover.brush(source, matrix.mul(m, matrix.inverse(matrix)), frame, sub, cover), matrix, opacity}
    case Pattern{inv, w, h, opacity, nodes}:
      +matrix = inv
      +ww = w
      +hh = h
      +pm = matrix.mul(m, matrix.inverse(matrix))
      +density = cover.density(pm, frame)
      +direct = cover.aligned(pm) && F32.is_ge((U.min(ww, hh) * density : F32), 4.0)
      +tile = cover.tile.frame(ww, hh, U.choose(F32, direct, density, U.max((density * U32.to_f32(sub) : F32), (4.0 / U.max(U.min(ww, hh), 0.000001) : F32))))
      +back = matrix.inverse(pm)
      +st = raster.scale(frame)
      Tile{cover.tile(tile, cover(nodes)(tile)(sub), ww, hh), matrix, ww, hh, opacity, cover.vector(back, st, 0.0), cover.vector(back, 0.0, st), U.choose(U32, direct, 1, sub)}
    case Tile{raster, inv, w, h, opacity, u, v, grid}: Tile{raster, inv, w, h, opacity, u, v, grid}
    case Gradient{inv, radial, start, end, radius, focal, stops, spread, opacity, linear}: Gradient{inv, radial, start, end, radius, focal, stops, spread, opacity, linear}

def cover.paint(ink: Paint<Brush>, +m: Matrix, +frame: Raster, +sub: U32, fills: List<&2, Scene<Brush>> -> Raster -> U32 -> List<&2, Scene<Brush>>, strokes: List<&2, Scene<Brush>> -> Raster -> U32 -> List<&2, Scene<Brush>>) -> Paint<Brush>:
  Paint{fill, stroke} = ink
  Paint{cover.brush(fill, m, frame, sub, fills), cover.brush(stroke, m, frame, sub, strokes)}

def paint.fill(+ink: Paint<Brush>) -> Brush:
  Paint{f, st} = ink
  f

def cover.image.rect(+raster: Raster) -> List<&2, Edge>:
  Raster{origin, step, width, height, depth, linear, pixels} = raster
  path(shape.rect.path(0.0, 0.0, U32.to_f32(width), U32.to_f32(height), 0.0, 0.0), 1.0)

# An image's own rectangle joins the scene clip, so its edges get coverage like
# any shape (the bitmap read clamps to its edge pixels); iv maps device to local.
def cover.image.clip(+brush: Brush, clip: Clip, +iv: Matrix, +frame: Raster, +sub: U32) -> Clip:
  match brush:
    case Bitmap{raster, inv, nearest}:
      +to = matrix.mul(inv, iv)
      +rect = cover.image.rect(raster)
      ClipIntersect{clip, ClipShape{edge.tree(rect), to, False{}, cover.edges(rect, matrix.inverse(to), False{}, frame, sub, True{})}}
    case _: clip

# Half a device pixel in local units, so a scene whose box only reaches into part
# of a pixel is still painted there: the pixel center may lie outside the box.
def cover.reach(+inv: Matrix, +half: F32) -> F32:
  Matrix{a, b, c, d, e, f} = inv
  (half * U.max(F32.sqrt((a * a + b * b : F32)), F32.sqrt((c * c + d * d : F32))) + 0.0001 : F32)

@unsafe
# Scenes painted directly keep rows-only fill masks (trees false); scenes
# sampled per pixel (pattern tiles, filter and mask rasters) need trees.
def cover.scenes(xs: List<&2, Scene<Brush>>, +frame: Raster, +sub: U32, +trees: Bool) -> List<&2, Scene<Brush>>:
  match xs:
    case Nil{}: Nil{}
    case Con{Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fill, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      +iv = inv
      +st = style
      +m = matrix.inverse(iv)
      +half = (raster.scale(frame) * 0.5 + 0.01 : F32)
      +ik = ink
      Con{Scene{Nil{}, bounds.expand(box, cover.reach(iv, half)), iv, st, opacity, cover.scenes(kids, frame, sub, trees), id, cover.paint(ik, m, frame, sub, nodes => f => n => cover.scenes(nodes, f, n, True{}), nodes => f => n => cover.scenes(nodes, f, n, True{})), cover.image.clip(paint.fill(ik), cover.clip(clip, frame, sub), iv, frame, sub), cover.stroke.if(style.strokes(st), outline, frame, sub, trees),
        cover.fill.if(style.fills(st), fill, es, m, cover.rule(st), frame, sub, trees), cover.scenes(maskNodes, frame, sub, trees), maskMode, cover.scenes(markerNodes, frame, sub, trees), bounds.expand(coverage, half), effect}, cover.scenes(rest, frame, sub, trees)}

def raster.scene(+format: Raster, +nodes: List<&2, Scene<Brush>>, +aa: U32) -> Raster:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = format
  +covered = cover.scenes(nodes, format, cover.sub(aa), True{})
  raster.store(format, raster.scene.tiles(depth, 0, 0, format, covered, scene.coverage(covered, bounds.empty()), aa), False{})

# A source alpha input shares its buffer; only the returned RGB channels change.
type FilterInput is Data:
  FilterInput{raster: Raster, region: Bounds, alpha: Bool, standard: Bool}

def color.alpha.only(c: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{0.0, 0.0, 0.0, a}

def filter.input.color(input: FilterInput, p: Point, linear: Bool) -> Img.Color:
  FilterInput{raster, region, alpha, standard} = input
  +c = raster.color(raster, p, linear)
  U.branch(Img.Color, alpha, _ => color.alpha.only(c), _ => c)

def filter.input.raster(input: FilterInput) -> Raster:
  FilterInput{raster, region, alpha, standard} = input
  raster

type ColorRow is Data:
  ColorRow{r: F32, g: F32, b: F32, a: F32, bias: F32}

type ColorMatrix is Data:
  ColorMatrix{r: ColorRow, g: ColorRow, b: ColorRow, a: ColorRow}

def color.straight(c: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +alpha = a
  Img.Color{(r / U.max(alpha, 0.0000001) : F32), (g / U.max(alpha, 0.0000001) : F32), (b / U.max(alpha, 0.0000001) : F32), alpha}

def color.premultiply(c: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +alpha = U.clamp(a, 0.0, 1.0)
  Img.Color{(U.clamp(r, 0.0, 1.0) * alpha : F32), (U.clamp(g, 0.0, 1.0) * alpha : F32), (U.clamp(b, 0.0, 1.0) * alpha : F32), alpha}

def color.premul.clamp(c: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +alpha = U.clamp(a, 0.0, 1.0)
  Img.Color{U.clamp(r, 0.0, alpha), U.clamp(g, 0.0, alpha), U.clamp(b, 0.0, alpha), alpha}

def filter.row(row: ColorRow, c: Img.Color) -> F32:
  ColorRow{rr, rg, rb, ra, bias} = row
  Img.Color{r, g, b, a} = c
  (rr * r + rg * g + rb * b + ra * a + bias : F32)

def filter.matrix(rows: ColorMatrix, c: Img.Color) -> Img.Color:
  ColorMatrix{r, g, b, a} = rows
  +straight = color.straight(c)
  color.premultiply(Img.Color{filter.row(r, straight), filter.row(g, straight), filter.row(b, straight), filter.row(a, straight)})

def filter.matrix.row(+vs: List<&2, F32>, +start: U32, +diagonal: U32) -> ColorRow:
  ColorRow{U.nth(vs, U32.to_nat(start), U.choose(F32, U32.is_eq(diagonal, 0), 1.0, 0.0)), U.nth(vs, U32.to_nat((start + 1 : U32)), U.choose(F32, U32.is_eq(diagonal, 1), 1.0, 0.0)), U.nth(vs, U32.to_nat((start + 2 : U32)), U.choose(F32, U32.is_eq(diagonal, 2), 1.0, 0.0)), U.nth(vs, U32.to_nat((start + 3 : U32)), U.choose(F32, U32.is_eq(diagonal, 3), 1.0, 0.0)), U.nth(vs, U32.to_nat((start + 4 : U32)), 0.0)}

def filter.matrix.identity() -> ColorMatrix:
  ColorMatrix{ColorRow{1.0, 0.0, 0.0, 0.0, 0.0}, ColorRow{0.0, 1.0, 0.0, 0.0, 0.0}, ColorRow{0.0, 0.0, 1.0, 0.0, 0.0}, ColorRow{0.0, 0.0, 0.0, 1.0, 0.0}}

def filter.matrix.saturate(+s: F32) -> ColorMatrix:
  ColorMatrix{ColorRow{(0.213 + 0.787 * s : F32), (0.715 - 0.715 * s : F32), (0.072 - 0.072 * s : F32), 0.0, 0.0}, ColorRow{(0.213 - 0.213 * s : F32), (0.715 + 0.285 * s : F32), (0.072 - 0.072 * s : F32), 0.0, 0.0}, ColorRow{(0.213 - 0.213 * s : F32), (0.715 - 0.715 * s : F32), (0.072 + 0.928 * s : F32), 0.0, 0.0}, ColorRow{0.0, 0.0, 0.0, 1.0, 0.0}}

def filter.matrix.hue(angle: F32) -> ColorMatrix:
  +rad = (angle * 0.017453292519943295 : F32)
  +c = F32.cos(rad)
  +s = F32.sin(rad)
  ColorMatrix{ColorRow{(0.213 + 0.787 * c - 0.213 * s : F32), (0.715 - 0.715 * c - 0.715 * s : F32), (0.072 - 0.072 * c + 0.928 * s : F32), 0.0, 0.0}, ColorRow{(0.213 - 0.213 * c + 0.143 * s : F32), (0.715 + 0.285 * c + 0.140 * s : F32), (0.072 - 0.072 * c - 0.283 * s : F32), 0.0, 0.0}, ColorRow{(0.213 - 0.213 * c - 0.787 * s : F32), (0.715 - 0.715 * c + 0.715 * s : F32), (0.072 + 0.928 * c + 0.072 * s : F32), 0.0, 0.0}, ColorRow{0.0, 0.0, 0.0, 1.0, 0.0}}

def filter.matrix.parse(+as: List<&2, XML.Attr>) -> ColorMatrix:
  +kind = XML.attr.get(as, "type", "matrix")
  +vs = U.numbers(XML.attr.get(as, "values", ""))
  U.branch(ColorMatrix, U.string.equal(kind, "saturate"), _ => filter.matrix.saturate(U.nth(vs, 0n, 1.0)),
    _ => U.branch(ColorMatrix, U.string.equal(kind, "hueRotate"), _ => filter.matrix.hue(U.nth(vs, 0n, 0.0)),
      _ => U.branch(ColorMatrix, U.string.equal(kind, "luminanceToAlpha"), _ => ColorMatrix{ColorRow{0.0, 0.0, 0.0, 0.0, 0.0}, ColorRow{0.0, 0.0, 0.0, 0.0, 0.0}, ColorRow{0.0, 0.0, 0.0, 0.0, 0.0}, ColorRow{0.2125, 0.7154, 0.0721, 0.0, 0.0}},
        _ => U.choose(ColorMatrix, U32.is_eq(floats.count(vs), 20), ColorMatrix{filter.matrix.row(vs, 0, 0), filter.matrix.row(vs, 5, 1), filter.matrix.row(vs, 10, 2), filter.matrix.row(vs, 15, 3)}, filter.matrix.identity()))))

type Transfer is Data:
  Transfer{kind: U32, values: List<&2, F32>, count: U32, a: F32, b: F32, c: F32}

def transfer.identity() -> Transfer:
  Transfer{0, Nil{}, 0, 1.0, 0.0, 0.0}

def transfer.parse(+as: List<&2, XML.Attr>) -> Transfer:
  +kind = XML.attr.get(as, "type", "identity")
  +vs = U.numbers(XML.attr.get(as, "tableValues", ""))
  Transfer{U.choose(U32, U.string.equal(kind, "table"), 1, U.choose(U32, U.string.equal(kind, "discrete"), 2, U.choose(U32, U.string.equal(kind, "linear"), 3, U.choose(U32, U.string.equal(kind, "gamma"), 4, 0)))), vs, floats.count(vs), U.scalar(XML.attr.get(as, U.choose(String, U.string.equal(kind, "gamma"), "amplitude", "slope"), "1"), 1.0), U.scalar(XML.attr.get(as, U.choose(String, U.string.equal(kind, "gamma"), "exponent", "intercept"), U.choose(String, U.string.equal(kind, "gamma"), "1", "0")), 0.0), U.scalar(XML.attr.get(as, "offset", "0"), 0.0)}

def transfer.find(xs: List<&2, XML.Element>, +name: String) -> Transfer:
  match xs:
    case Nil{}: transfer.identity()
    case Con{XML.Element{n, as, kids, txt}, rest}:
      U.branch(Transfer, U.string.equal(n, name), _ => transfer.parse(as), _ => transfer.find(rest, name))

def transfer.apply(+t: Transfer, +x: F32) -> F32:
  Transfer{kind, vs, count, a, b, c} = t
  +last = U.choose(U32, U32.is_eq(count, 0), 0, (count - 1 : U32))
  +position = (U.clamp(x, 0.0, 1.0) * U32.to_f32(last) : F32)
  +index = F32.to_u32(F32.floor(position))
  +left = U.nth(vs, U32.to_nat(index), x)
  U.branch(F32, U32.is_eq(kind, 1) && U32.is_gt(count, 0), _ => (left + (U.nth(vs, U32.to_nat(U32.inc(index)), left) - left) * (position - U32.to_f32(index)) : F32),
    _ => U.branch(F32, U32.is_eq(kind, 2) && U32.is_gt(count, 0), _ => U.nth(vs, U32.to_nat(F32.to_u32(U.min(U32.to_f32(last), F32.floor((U.clamp(x, 0.0, 1.0) * U32.to_f32(count) : F32))))), x),
      _ => U.branch(F32, U32.is_eq(kind, 3), _ => (a * x + b : F32), _ => U.branch(F32, U32.is_eq(kind, 4), _ => (a * F32.pow(U.max(x, 0.0), b) + c : F32), _ => x))))

def filter.transfer(r: Transfer, g: Transfer, b: Transfer, a: Transfer, c: Img.Color) -> Img.Color:
  Img.Color{cr, cg, cb, ca} = c
  +alpha = ca
  color.premultiply(Img.Color{transfer.apply(r, (cr / U.max(alpha, 0.0000001) : F32)), transfer.apply(g, (cg / U.max(alpha, 0.0000001) : F32)), transfer.apply(b, (cb / U.max(alpha, 0.0000001) : F32)), transfer.apply(a, alpha)})

def color.alpha(c: Img.Color) -> F32:
  Img.Color{r, g, b, a} = c
  a

def filter.arithmetic(+a: F32, +b: F32, k1: F32, k2: F32, k3: F32, k4: F32) -> F32:
  (k1 * a * b + k2 * a + k3 * b + k4 : F32)

def filter.composite(+a: Img.Color, +b: Img.Color, +kind: U32, +k1: F32, +k2: F32, +k3: F32, +k4: F32) -> Img.Color:
  Img.Color{ar, ag, ab, aa} = a
  Img.Color{br, bg, bb, ba} = b
  U.branch(Img.Color, U32.is_eq(kind, 5), _ => color.premul.clamp(Img.Color{filter.arithmetic(ar, br, k1, k2, k3, k4), filter.arithmetic(ag, bg, k1, k2, k3, k4), filter.arithmetic(ab, bb, k1, k2, k3, k4), filter.arithmetic(aa, ba, k1, k2, k3, k4)}),
    _ => U.branch(Img.Color, U32.is_eq(kind, 1), _ => color.fade(a, ba),
      _ => U.branch(Img.Color, U32.is_eq(kind, 2), _ => color.fade(a, (1.0 - ba : F32)),
        _ => U.branch(Img.Color, U32.is_eq(kind, 3), _ => color.add(color.fade(a, ba), color.fade(b, (1.0 - aa : F32))),
          _ => U.branch(Img.Color, U32.is_eq(kind, 4), _ => color.add(color.fade(a, (1.0 - ba : F32)), color.fade(b, (1.0 - aa : F32))), _ => color.over(a, b))))))

def filter.blend.hard(+a: F32, +b: F32) -> F32:
  U.choose(F32, F32.is_le(a, 0.5), (2.0 * a * b : F32), (1.0 - 2.0 * (1.0 - a) * (1.0 - b) : F32))

def filter.blend.soft(+a: F32, +b: F32) -> F32:
  +curve = U.choose(F32, F32.is_le(b, 0.25), (((16.0 * b - 12.0) * b + 4.0) * b : F32), F32.sqrt(b))
  U.choose(F32, F32.is_le(a, 0.5), (b - (1.0 - 2.0 * a) * b * (1.0 - b) : F32), (b + (2.0 * a - 1.0) * (curve - b) : F32))

def filter.blend.channel(+a: F32, +b: F32, kind: U32) -> F32:
  match kind:
    case 1: (a * b : F32)
    case 2: (a + b - a * b : F32)
    case 3: U.min(a, b)
    case 4: U.max(a, b)
    case 5: filter.blend.hard(b, a)
    case 6: U.choose(F32, F32.is_le(b, 0.0), 0.0, U.choose(F32, F32.is_ge(a, 1.0), 1.0, U.min(1.0, (b / U.max(0.0000001, (1.0 - a : F32)) : F32))))
    case 7: U.choose(F32, F32.is_ge(b, 1.0), 1.0, U.choose(F32, F32.is_le(a, 0.0), 0.0, (1.0 - U.min(1.0, ((1.0 - b) / U.max(0.0000001, a) : F32)) : F32)))
    case 8: filter.blend.hard(a, b)
    case 9: filter.blend.soft(a, b)
    case 10: F32.abs((a - b : F32))
    case 11: (a + b - 2.0 * a * b : F32)
    case _: a

def filter.blend.lum(c: Img.Color) -> F32:
  Img.Color{r, g, b, a} = c
  (0.3 * r + 0.59 * g + 0.11 * b : F32)

def filter.blend.sat(+c: Img.Color) -> F32:
  Img.Color{r, g, b, a} = c
  (U.max(r, U.max(g, b)) - U.min(r, U.min(g, b)) : F32)

def filter.blend.setsat(+c: Img.Color, +s: F32) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +lo = U.min(r, U.min(g, b))
  +span = (U.max(r, U.max(g, b)) - lo : F32)
  +scale = U.choose(F32, F32.is_gt(span, 0.0), (s / U.max(span, 0.0000001) : F32), 0.0)
  Img.Color{((r - lo) * scale : F32), ((g - lo) * scale : F32), ((b - lo) * scale : F32), 1.0}

def filter.blend.clip.scale(c: Img.Color, +l: F32, +scale: F32) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{(l + (r - l) * scale : F32), (l + (g - l) * scale : F32), (l + (b - l) * scale : F32), 1.0}

def filter.blend.clip(+c: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +l = filter.blend.lum(c)
  +lo = U.min(r, U.min(g, b))
  +hi = U.max(r, U.max(g, b))
  +scaleLow = U.choose(F32, F32.is_lt(lo, 0.0), (l / U.max(0.0000001, (l - lo : F32)) : F32), 1.0)
  +scaleHigh = U.choose(F32, F32.is_gt(hi, 1.0), ((1.0 - l) / U.max(0.0000001, (hi - l : F32)) : F32), 1.0)
  filter.blend.clip.scale(c, l, (scaleLow * scaleHigh : F32))

def filter.blend.setlum(+c: Img.Color, l: F32) -> Img.Color:
  Img.Color{r, g, b, a} = c
  +delta = (l - filter.blend.lum(c) : F32)
  filter.blend.clip(Img.Color{(r + delta : F32), (g + delta : F32), (b + delta : F32), 1.0})

def filter.blend.rgb(+a: Img.Color, +b: Img.Color, +kind: U32) -> Img.Color:
  Img.Color{ar, ag, ab, aa} = a
  Img.Color{br, bg, bb, ba} = b
  U.branch(Img.Color, U32.is_eq(kind, 12), _ => filter.blend.setlum(filter.blend.setsat(a, filter.blend.sat(b)), filter.blend.lum(b)),
    _ => U.branch(Img.Color, U32.is_eq(kind, 13), _ => filter.blend.setlum(filter.blend.setsat(b, filter.blend.sat(a)), filter.blend.lum(b)),
      _ => U.branch(Img.Color, U32.is_eq(kind, 14), _ => filter.blend.setlum(a, filter.blend.lum(b)),
        _ => U.branch(Img.Color, U32.is_eq(kind, 15), _ => filter.blend.setlum(b, filter.blend.lum(a)),
          _ => Img.Color{filter.blend.channel(ar, br, kind), filter.blend.channel(ag, bg, kind), filter.blend.channel(ab, bb, kind), 1.0}))))

def filter.blend(+a: Img.Color, +b: Img.Color, +kind: U32) -> Img.Color:
  Img.Color{ar, ag, ab, aa} = a
  Img.Color{br, bg, bb, ba} = b
  +alpha = (aa * ba : F32)
  color.add(color.add(color.fade(a, (1.0 - ba : F32)), color.fade(b, (1.0 - aa : F32))), color.fade(filter.blend.rgb(Img.Color{(ar / U.max(aa, 0.0000001) : F32), (ag / U.max(aa, 0.0000001) : F32), (ab / U.max(aa, 0.0000001) : F32), 1.0}, Img.Color{(br / U.max(ba, 0.0000001) : F32), (bg / U.max(ba, 0.0000001) : F32), (bb / U.max(ba, 0.0000001) : F32), 1.0}, kind), alpha))

type FilterTap is Data:
  FilterTap{delta: Point, weight: F32}

# Convolution kernels operate on a pixel grid; edge extension precedes interpolation.
type Convolution is Data:
  Convolution{kernel: List<&2, FilterTap>, divisor: F32, bias: F32, preserve: Bool, edge: U32, limits: Bounds}

type FilterOp is Data:
  FilterCopy{}
  FilterFlood{color: Img.Color}
  FilterOffset{delta: Point}
  FilterMatrix{rows: ColorMatrix}
  FilterTransfer{r: Transfer, g: Transfer, b: Transfer, a: Transfer}
  FilterComposite{kind: U32, k1: F32, k2: F32, k3: F32, k4: F32}
  FilterBlend{kind: U32}
  FilterMerge{inputs: List<&2, FilterInput>}
  FilterBlur{kernel: List<&2, FilterTap>}
  FilterMorphology{dilate: Bool, radius: U32, direction: Point}
  FilterConvolution{spec: Convolution}

def filter.merge(xs: List<&2, FilterInput>, +p: Point, +linear: Bool, back: Img.Color) -> Img.Color:
  match xs:
    case Nil{}: back
    case Con{h, t}: filter.merge(t, p, linear, color.over(filter.input.color(h, p, linear), back))

def filter.convolve(xs: List<&2, FilterTap>, +input: FilterInput, +p: Point, +linear: Bool, acc: Img.Color) -> Img.Color:
  match xs:
    case Nil{}: acc
    case Con{FilterTap{delta, weight}, rest}: filter.convolve(rest, input, p, linear, color.add(acc, color.fade(filter.input.color(input, point.add(p, delta), linear), weight)))

# Morphology takes component-wise extrema of premultiplied channels.
def filter.morphology.join(+a: Img.Color, +b: Img.Color, +dilate: Bool) -> Img.Color:
  Img.Color{ar, ag, ab, aa} = a
  Img.Color{br, bg, bb, ba} = b
  Img.Color{U.choose(F32, dilate, U.max(ar, br), U.min(ar, br)), U.choose(F32, dilate, U.max(ag, bg), U.min(ag, bg)), U.choose(F32, dilate, U.max(ab, bb), U.min(ab, bb)), U.choose(F32, dilate, U.max(aa, ba), U.min(aa, ba))}

def filter.morphology.sample(left: Nat, +index: F32, +direction: Point, +dilate: Bool, +input: FilterInput, +p: Point, +linear: Bool, acc: Img.Color) -> Img.Color:
  match left:
    case 0n: acc
    case 1n+rest:
      filter.morphology.sample(rest, (index + 1.0 : F32), direction, dilate, input, p, linear,
        filter.morphology.join(acc, filter.input.color(input, point.add(p, point.scale(direction, index)), linear), dilate))

def filter.convolution.index(+n: F32, +low: F32, +high: F32, edge: U32) -> F32:
  +length = U.max((high - low : F32), 1.0)
  U.choose(F32, U32.is_eq(edge, 1), (low + (n - low) - F32.floor(((n - low) / length : F32)) * length : F32), U.clamp(n, low, (high - 1.0 : F32)))

def filter.convolution.raw(+input: FilterInput, x: F32, y: F32, +linear: Bool) -> Img.Color:
  FilterInput{raster, region, alpha, standard} = input
  +stored = raster.is.linear(raster)
  +c = raster.pixel(raster, x, y)
  +converted = U.branch(Img.Color, U.choose(Bool, stored, linear, Bool.not(linear)), _ => c,
    _ => U.branch(Img.Color, stored, _ => color.from.linear(c), _ => color.space(c, True{})))
  U.choose(Img.Color, alpha, color.alpha.only(converted), converted)

def filter.convolution.pixel(+input: FilterInput, +limits: Bounds, +edge: U32, +x: F32, +y: F32, linear: Bool) -> Img.Color:
  Bounds{x0, y0, x1, y1} = limits
  U.branch(Img.Color, bounds.nonempty(limits) && (Bool.not(U32.is_eq(edge, 2)) || (F32.is_ge(x, x0) && F32.is_lt(x, x1) && F32.is_ge(y, y0) && F32.is_lt(y, y1))),
    _ => filter.convolution.raw(input, filter.convolution.index(x, x0, x1, edge), filter.convolution.index(y, y0, y1, edge), linear), _ => Img.clear())

def filter.convolution.horizontal(+input: FilterInput, +limits: Bounds, +edge: U32, +x: F32, +y: F32, +dx: F32, +linear: Bool) -> Img.Color:
  U.branch(Img.Color, F32.is_eq(dx, 0.0), _ => filter.convolution.pixel(input, limits, edge, x, y, linear),
    _ => color.mix(filter.convolution.pixel(input, limits, edge, x, y, linear), filter.convolution.pixel(input, limits, edge, (x + 1.0 : F32), y, linear), dx))

def filter.convolution.at(+input: FilterInput, +limits: Bounds, +edge: U32, +raster: Raster, p: Point, +linear: Bool) -> Img.Color:
  Raster{Point{ox, oy}, step, width, height, depth, stored, pixels} = raster
  Point{x, y} = p
  +fx = ((x - ox) / step - 0.5 : F32)
  +fy = ((y - oy) / step - 0.5 : F32)
  +ix = F32.floor(fx)
  +iy = F32.floor(fy)
  +dx = (fx - ix : F32)
  +dy = (fy - iy : F32)
  U.branch(Img.Color, F32.is_eq(dy, 0.0), _ => filter.convolution.horizontal(input, limits, edge, ix, iy, dx, linear),
    _ => color.mix(filter.convolution.horizontal(input, limits, edge, ix, iy, dx, linear), filter.convolution.horizontal(input, limits, edge, ix, (iy + 1.0 : F32), dx, linear), dy))

def filter.convolution.color(+input: FilterInput, limits: Bounds, edge: U32, p: Point, linear: Bool) -> Img.Color:
  filter.convolution.at(input, limits, edge, filter.input.raster(input), p, linear)

def filter.convolution.sum(xs: List<&2, FilterTap>, +input: FilterInput, +limits: Bounds, +edge: U32, +preserve: Bool, +p: Point, +linear: Bool, acc: Img.Color) -> Img.Color:
  match xs:
    case Nil{}: acc
    case Con{FilterTap{delta, weight}, rest}:
      +sample = filter.convolution.color(input, limits, edge, point.add(p, delta), linear)
      filter.convolution.sum(rest, input, limits, edge, preserve, p, linear, color.add(acc, color.fade(U.choose(Img.Color, preserve, color.straight(sample), sample), weight)))

def filter.convolution.finish(+c: Img.Color, +divisor: F32, +bias: F32, +preserve: Bool, original: Img.Color) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{rr, gg, bb, aa} = original
  +alpha = U.choose(F32, preserve, aa, (a / divisor + bias : F32))
  U.branch(Img.Color, preserve,
    _ => color.premultiply(Img.Color{(r / divisor + bias : F32), (g / divisor + bias : F32), (b / divisor + bias : F32), alpha}),
    _ => color.premul.clamp(Img.Color{(r / divisor + bias * alpha : F32), (g / divisor + bias * alpha : F32), (b / divisor + bias * alpha : F32), alpha}))

def filter.convolution.sample(+spec: Convolution, +input: FilterInput, +p: Point, +linear: Bool) -> Img.Color:
  Convolution{kernel, divisor, bias, preserve, edge, limits} = spec
  filter.convolution.finish(filter.convolution.sum(kernel, input, limits, edge, preserve, p, linear, Img.clear()), divisor, bias, preserve, filter.input.color(input, p, linear))

def filter.op.sample(op: FilterOp, +a: FilterInput, +b: FilterInput, +p: Point, +linear: Bool) -> Img.Color:
  match op:
    case FilterCopy{}: filter.input.color(a, p, linear)
    case FilterFlood{c}: c
    case FilterOffset{delta}: filter.input.color(a, point.sub(p, delta), linear)
    case FilterMatrix{rows}: filter.matrix(rows, filter.input.color(a, p, linear))
    case FilterTransfer{r, g, b, alpha}: filter.transfer(r, g, b, alpha, filter.input.color(a, p, linear))
    case FilterComposite{kind, k1, k2, k3, k4}: filter.composite(filter.input.color(a, p, linear), filter.input.color(b, p, linear), kind, k1, k2, k3, k4)
    case FilterBlend{kind}: filter.blend(filter.input.color(a, p, linear), filter.input.color(b, p, linear), kind)
    case FilterMerge{inputs}: filter.merge(inputs, p, linear, Img.clear())
    case FilterBlur{kernel}: filter.convolve(kernel, a, p, linear, Img.clear())
    case FilterConvolution{spec}: filter.convolution.sample(spec, a, p, linear)
    case FilterMorphology{dilate, radius, direction}:
      +n = radius
      +expand = dilate
      filter.morphology.sample(U32.to_nat((n * 2 + 1 : U32)), F32.neg(U32.to_f32(n)), direction, expand, a, p, linear, U.choose(Img.Color, expand, Img.clear(), Img.Color{1.0, 1.0, 1.0, 1.0}))

type FilterWindow is Data:
  FilterWindow{region: Bounds, inverse: Matrix, exact: Bool}

def filter.region.inside(b: Bounds, p: Point) -> Bool:
  Bounds{x0, y0, x1, y1} = b
  Point{x, y} = p
  +xx = x
  +yy = y
  F32.is_ge(xx, x0) && F32.is_ge(yy, y0) && F32.is_lt(xx, x1) && F32.is_lt(yy, y1)

def filter.window.contains(region: Bounds, tile: Bounds) -> U32:
  Bounds{x0, y0, x1, y1} = region
  Bounds{a, b, c, d} = tile
  U.choose(U32, F32.is_ge(a, x0) && F32.is_ge(b, y0) && F32.is_le(c, x1) && F32.is_le(d, y1), 1, 2)

def filter.window.span(window: FilterWindow, tile: Bounds) -> U32:
  FilterWindow{region, inverse, exact} = window
  +local = bounds.transform(tile, inverse)
  +box = region
  U.choose(U32, bounds.overlap(box, local), filter.window.contains(box, local), 0)

def filter.window.inside(window: FilterWindow, p: Point) -> Bool:
  FilterWindow{region, inverse, exact} = window
  filter.region.inside(region, matrix.point(inverse, p))

def filter.window.exact(window: FilterWindow) -> Bool:
  FilterWindow{region, inverse, exact} = window
  exact

# An axis-aligned window clips a buffer pixel by its exact overlap with the region.
def filter.window.aligned(window: FilterWindow) -> Bool:
  FilterWindow{region, inverse, exact} = window
  Matrix{a, b, c, d, e, f} = inverse
  F32.is_eq(b, 0.0) && F32.is_eq(c, 0.0)

def filter.window.overlap(region: Bounds, local: Bounds) -> F32:
  Bounds{x0, y0, x1, y1} = region
  Bounds{u0, v0, u1, v1} = local
  +a0 = u0
  +b0 = v0
  +a1 = u1
  +b1 = v1
  +w = U.max(0.0, (U.min(x1, a1) - U.max(x0, a0) : F32))
  +h = U.max(0.0, (U.min(y1, b1) - U.max(y0, b0) : F32))
  (w * h / U.max(((a1 - a0) * (b1 - b0) : F32), 0.000000001) : F32)

def filter.window.area(window: FilterWindow, tile: Bounds) -> F32:
  FilterWindow{region, inverse, exact} = window
  Bounds{x0, y0, x1, y1} = tile
  +m = inverse
  filter.window.overlap(region, bounds.point(bounds.point(bounds.empty(), matrix.point(m, Point{x0, y0})), matrix.point(m, Point{x1, y1})))

def filter.window.samples(n: Nat, +i: U32, +aa: U32, +window: FilterWindow, +point: Point, +step: F32, acc: F32) -> F32:
  match n:
    case 0n: acc
    case 1n+d:
      filter.window.samples(d, U32.inc(i), aa, window, point, step,
        (acc + U.choose(F32, filter.window.inside(window, point.add(point, Point{((U32.to_f32(U32.mod(i, aa)) + 0.5) * step : F32), ((U32.to_f32(U32.div(i, aa)) + 0.5) * step : F32)})), 1.0, 0.0) : F32))

def filter.draw.pixel(+format: Raster, +x: U32, +y: U32, op: FilterOp, a: FilterInput, b: FilterInput, +window: FilterWindow, linear: Bool, +aa: U32, span: U32) -> Img.Pixels:
  +c = filter.op.sample(op, a, b, raster.position(format, (U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32)), linear)
  # Intermediate offscreens include each pixel intersecting the hard clipping
  # region; the final filter region clips by the pixel's covered fraction.
  +covered = U.branch(F32, filter.window.exact(window) && filter.window.aligned(window), _ => filter.window.area(window, raster.tile.box(format, x, y, 1)),
    _ => (filter.window.samples(U32.to_nat((aa * aa : U32)), 0, aa, window, raster.position(format, U32.to_f32(x), U32.to_f32(y)), (raster.scale(format) / U32.to_f32(aa) : F32), 0.0) / U32.to_f32((aa * aa : U32)) : F32))
  Img.Flat{U.branch(Img.Color, U32.is_eq(span, 1), _ => c,
    _ => U.choose(Img.Color, filter.window.exact(window), color.fade(c, covered), U.choose(Img.Color, F32.is_gt(covered, 0.0), c, Img.clear())))}

def filter.draw.tiles(depth: Nat, +x: U32, +y: U32, +format: Raster, +op: FilterOp, +a: FilterInput, +b: FilterInput, +window: FilterWindow, +linear: Bool, +aa: U32) -> Img.Pixels:
  match depth:
    case 0n:
      +span = filter.window.span(window, raster.tile.box(format, x, y, 1))
      U.branch(Img.Pixels, raster.in.frame(format, x, y) && Bool.not(U32.is_eq(span, 0)),
        _ => filter.draw.pixel(format, x, y, op, a, b, window, linear, aa, span), _ => Img.Flat{Img.clear()})
    case 1n+d:
      +dd = d
      +half = U32.shln(1, dd)
      +span = filter.window.span(window, raster.tile.box(format, x, y, (half * 2 : U32)))
      U.branch(Img.Pixels, raster.in.frame(format, x, y) && Bool.not(U32.is_eq(span, 0)),
        _ => Img.pixels.join(filter.draw.tiles(dd, x, y, format, op, a, b, window, linear, aa), filter.draw.tiles(dd, (x + half : U32), y, format, op, a, b, window, linear, aa), filter.draw.tiles(dd, x, (y + half : U32), format, op, a, b, window, linear, aa), filter.draw.tiles(dd, (x + half : U32), (y + half : U32), format, op, a, b, window, linear, aa)), _ => Img.Flat{Img.clear()})

def filter.draw(+format: Raster, op: FilterOp, a: FilterInput, b: FilterInput, window: FilterWindow, +linear: Bool, aa: U32) -> Raster:
  Raster{origin, step, width, height, depth, pixelsLinear, pixels} = format
  raster.store(format, filter.draw.tiles(depth, 0, 0, format, op, a, b, window, linear, aa), linear)

def filter.kernel.raw(n: Nat, +i: F32, +radius: F32, +sigma: F32, +direction: Point) -> List<&2, FilterTap>:
  match n:
    case 0n: Nil{}
    case 1n+d:
      +x = (i - radius : F32)
      Con{FilterTap{point.scale(direction, x), F32.exp((F32.neg(0.5) * x * x / (sigma * sigma) : F32))}, filter.kernel.raw(d, (i + 1.0 : F32), radius, sigma, direction)}

def filter.kernel.sum(xs: List<&2, FilterTap>) -> F32:
  match xs:
    case Nil{}: 0.0
    case Con{FilterTap{delta, weight}, rest}: (weight + filter.kernel.sum(rest) : F32)

def filter.kernel.normalize(xs: List<&2, FilterTap>, +total: F32) -> List<&2, FilterTap>:
  match xs:
    case Nil{}: Nil{}
    case Con{FilterTap{delta, weight}, rest}: Con{FilterTap{delta, (weight / total : F32)}, filter.kernel.normalize(rest, total)}

def filter.kernel(+vector: Point, +step: F32) -> List<&2, FilterTap>:
  +sigma = point.distance(vector, Point{0.0, 0.0})
  +radius = U.min(512.0, F32.ceil((3.0 * sigma / step : F32)))
  +spacing = U.max(step, (3.0 * sigma / U.max(radius, 1.0) : F32))
  +kernel = filter.kernel.raw(U32.to_nat(F32.to_u32((radius * 2.0 + 1.0 : F32))), 0.0, radius, (U.max(sigma, 0.000001) / spacing : F32), point.scale(vector, (spacing / U.max(sigma, 0.000001) : F32)))
  U.branch(List<&2, FilterTap>, F32.is_lt(sigma, 0.000001), _ => Con{FilterTap{Point{0.0, 0.0}, 1.0}, Nil{}}, _ => filter.kernel.normalize(kernel, filter.kernel.sum(kernel)))

# Filter inputs form an ordered graph. Results only see preceding primitives.
type FilterResult is Data:
  FilterResult{name: String, input: FilterInput}

def filter.result(xs: List<&2, FilterResult>, +name: String, +fallback: FilterInput) -> FilterInput:
  match xs:
    case Nil{}: fallback
    case Con{FilterResult{key, input}, rest}:
      U.branch(FilterInput, U.string.equal(key, name), _ => input, _ => filter.result(rest, name, fallback))

def filter.input.alpha(input: FilterInput) -> FilterInput:
  FilterInput{raster, region, alpha, standard} = input
  FilterInput{raster, region, True{}, standard}

def filter.resolve(+name: String, +source: FilterInput, previous: FilterInput, results: List<&2, FilterResult>) -> FilterInput:
  U.branch(FilterInput, U.string.equal(name, "SourceGraphic"), _ => source,
    _ => U.branch(FilterInput, U.string.equal(name, "SourceAlpha"), _ => filter.input.alpha(source), _ => filter.result(results, name, previous)))

def filter.input.region(input: FilterInput) -> Bounds:
  FilterInput{raster, region, alpha, standard} = input
  region

def filter.merge.inputs(+xs: List<&2, XML.Element>, +source: FilterInput, +previous: FilterInput, +results: List<&2, FilterResult>) -> List<&2, FilterInput>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{name, as, kids, txt}, rest}:
      U.branch(List<&2, FilterInput>, U.string.equal(name, "feMergeNode"), _ => Con{filter.resolve(XML.attr.get(as, "in", ""), source, previous, results), filter.merge.inputs(rest, source, previous, results)}, _ => filter.merge.inputs(rest, source, previous, results))

def filter.inputs.region(xs: List<&2, FilterInput>, box: Bounds) -> Bounds:
  match xs:
    case Nil{}: box
    case Con{h, t}: filter.inputs.region(t, bounds.merge(box, filter.input.region(h)))

def bounds.intersection(a: Bounds, b: Bounds) -> Bounds:
  Bounds{x0, y0, x1, y1} = a
  Bounds{u0, v0, u1, v1} = b
  Bounds{U.max(x0, u0), U.max(y0, v0), U.min(x1, u1), U.min(y1, v1)}

def filter.subregion(+as: List<&2, XML.Attr>, box: Bounds, viewport: Point) -> Bounds:
  Bounds{x0, y0, x1, y1} = box
  Point{vw, vh} = viewport
  +w = vw
  +h = vh
  +left = x0
  +top = y0
  +x = U.branch(F32, Bool.not(U.string.equal(XML.attr.get(as, "x", ""), "")), _ => dimension(as, "x", w, "0"), _ => left)
  +y = U.branch(F32, Bool.not(U.string.equal(XML.attr.get(as, "y", ""), "")), _ => dimension(as, "y", h, "0"), _ => top)
  Bounds{x, y, (x + U.branch(F32, Bool.not(U.string.equal(XML.attr.get(as, "width", ""), "")), _ => dimension(as, "width", w, "0"), _ => (x1 - left : F32)) : F32), (y + U.branch(F32, Bool.not(U.string.equal(XML.attr.get(as, "height", ""), "")), _ => dimension(as, "height", h, "0"), _ => (y1 - top : F32)) : F32)}

def matrix.vector(+m: Matrix, p: Point) -> Point:
  point.sub(matrix.point(m, p), matrix.point(m, Point{0.0, 0.0}))

def filter.offset(+as: List<&2, XML.Attr>, viewport: Point) -> Point:
  Point{w, h} = viewport
  Point{dimension(as, "dx", w, "0"), dimension(as, "dy", h, "0")}

def filter.operator(+name: String) -> U32:
  U.choose(U32, U.string.equal(name, "in"), 1, U.choose(U32, U.string.equal(name, "out"), 2, U.choose(U32, U.string.equal(name, "atop"), 3, U.choose(U32, U.string.equal(name, "xor"), 4, U.choose(U32, U.string.equal(name, "arithmetic"), 5, 0)))))

def filter.blend.mode(+name: String) -> U32:
  U.choose(U32, U.string.equal(name, "multiply"), 1, U.choose(U32, U.string.equal(name, "screen"), 2, U.choose(U32, U.string.equal(name, "darken"), 3, U.choose(U32, U.string.equal(name, "lighten"), 4, U.choose(U32, U.string.equal(name, "overlay"), 5, U.choose(U32, U.string.equal(name, "color-dodge"), 6, U.choose(U32, U.string.equal(name, "color-burn"), 7, U.choose(U32, U.string.equal(name, "hard-light"), 8, U.choose(U32, U.string.equal(name, "soft-light"), 9, U.choose(U32, U.string.equal(name, "difference"), 10, U.choose(U32, U.string.equal(name, "exclusion"), 11, U.choose(U32, U.string.equal(name, "hue"), 12, U.choose(U32, U.string.equal(name, "saturation"), 13, U.choose(U32, U.string.equal(name, "color"), 14, U.choose(U32, U.string.equal(name, "luminosity"), 15, 0)))))))))))))))

def filter.flood(+as: List<&2, XML.Attr>) -> Img.Color:
  +ink = XML.attr.get(as, "flood-color", "black")
  color.fade(color(U.choose(String, U.string.equal(CSS.css.lower(ink), "currentcolor"), XML.attr.get(as, "color", "black"), ink)), color.opacity(XML.attr.get(as, "flood-opacity", "1"), 1.0))

def filter.op.parse(+name: String, +as: List<&2, XML.Attr>, +kids: List<&2, XML.Element>, units: Matrix, viewport: Point, merges: List<&2, FilterInput>) -> FilterOp:
  U.branch(FilterOp, U.string.equal(name, "feFlood"), _ => FilterFlood{filter.flood(as)},
    _ => U.branch(FilterOp, U.string.equal(name, "feOffset"), _ => FilterOffset{matrix.vector(units, filter.offset(as, viewport))},
      _ => U.branch(FilterOp, U.string.equal(name, "feColorMatrix"), _ => FilterMatrix{filter.matrix.parse(as)},
        _ => U.branch(FilterOp, U.string.equal(name, "feComponentTransfer"), _ => FilterTransfer{transfer.find(kids, "feFuncR"), transfer.find(kids, "feFuncG"), transfer.find(kids, "feFuncB"), transfer.find(kids, "feFuncA")},
          _ => U.branch(FilterOp, U.string.equal(name, "feComposite"), _ => FilterComposite{filter.operator(XML.attr.get(as, "operator", "over")), U.scalar(XML.attr.get(as, "k1", "0"), 0.0), U.scalar(XML.attr.get(as, "k2", "0"), 0.0), U.scalar(XML.attr.get(as, "k3", "0"), 0.0), U.scalar(XML.attr.get(as, "k4", "0"), 0.0)},
            _ => U.branch(FilterOp, U.string.equal(name, "feBlend"), _ => FilterBlend{filter.blend.mode(XML.attr.get(as, "mode", "normal"))},
              _ => U.branch(FilterOp, U.string.equal(name, "feMerge"), _ => FilterMerge{merges}, _ => FilterCopy{})))))))

def filter.blur(+as: List<&2, XML.Attr>, +format: Raster, +input: FilterInput, +units: Matrix, window: FilterWindow, +linear: Bool, +aa: U32) -> Raster:
  +vs = U.numbers(XML.attr.get(as, "stdDeviation", "0"))
  +sx = U.nth(vs, 0n, 0.0)
  +sy = U.nth(vs, 1n, sx)
  +region = filter.input.region(input)
  +first = {FilterInput{filter.draw(format, FilterBlur{filter.kernel(matrix.vector(units, Point{U.max(sx, 0.0), 0.0}), raster.scale(format))}, input, input, FilterWindow{Bounds{F32.neg(1.0e30), F32.neg(1.0e30), 1.0e30, 1.0e30}, identity(), False{}}, linear, aa), region, False{}, False{}} : FilterInput}
  U.branch(Raster, F32.is_lt(sx, 0.0) || F32.is_lt(sy, 0.0), _ => raster.store(format, Img.Flat{Img.clear()}, linear),
    _ => filter.draw(format, FilterBlur{filter.kernel(matrix.vector(units, Point{0.0, sy}), raster.scale(format))}, first, first, window, linear, aa))

# Rectangular min/max is separable along the transformed primitive axes.
# A radius beyond the finite buffer diagonal only visits transparent samples.
def filter.morphology.axis(+vector: Point, +step: F32, dilate: Bool) -> FilterOp:
  +length = point.distance(vector, Point{0.0, 0.0})
  +radius = F32.to_u32(U.clamp(F32.floor((length / step + 0.5 : F32)), 0.0, 2048.0))
  FilterMorphology{dilate, radius, point.scale(vector, (step / U.max(length, 0.000001) : F32))}

def filter.morphology(+as: List<&2, XML.Attr>, +format: Raster, +input: FilterInput, +units: Matrix, window: FilterWindow, +linear: Bool, +aa: U32) -> Raster:
  +values = U.numbers(XML.attr.get(as, "radius", "0"))
  +rx = U.max(U.nth(values, 0n, 0.0), 0.0)
  +ry = U.max(U.nth(values, 1n, U.nth(values, 0n, 0.0)), 0.0)
  +dilate = U.string.equal(XML.attr.get(as, "operator", "erode"), "dilate")
  +region = filter.input.region(input)
  +first = {FilterInput{filter.draw(format, filter.morphology.axis(matrix.vector(units, Point{rx, 0.0}), raster.scale(format), dilate), input, input, FilterWindow{Bounds{F32.neg(1.0e30), F32.neg(1.0e30), 1.0e30, 1.0e30}, identity(), False{}}, linear, aa), region, False{}, False{}} : FilterInput}
  filter.draw(format, filter.morphology.axis(matrix.vector(units, Point{0.0, ry}), raster.scale(format), dilate), first, first, window, linear, aa)

def filter.shadow(+attrs: List<&2, XML.Attr>, +format: Raster, +input: FilterInput, +units: Matrix, +viewport: Point, +window: FilterWindow, +linear: Bool, +aa: U32) -> Raster:
  +as = {Con{XML.Attr{"stdDeviation", XML.attr.get(attrs, "stdDeviation", "2")}, Con{XML.Attr{"dx", XML.attr.get(attrs, "dx", "2")}, Con{XML.Attr{"dy", XML.attr.get(attrs, "dy", "2")}, attrs}}} : List<&2, XML.Attr>}
  +region = filter.input.region(input)
  +blur = {FilterInput{filter.blur(as, format, filter.input.alpha(input), units, window, linear, aa), region, False{}, False{}} : FilterInput}
  +offset = {FilterInput{filter.draw(format, FilterOffset{matrix.vector(units, filter.offset(as, viewport))}, blur, blur, window, linear, aa), region, False{}, False{}} : FilterInput}
  +flood = {FilterInput{filter.draw(format, FilterFlood{color.space(filter.flood(as), linear)}, input, input, window, linear, aa), region, False{}, False{}} : FilterInput}
  +shade = {FilterInput{filter.draw(format, FilterComposite{1, 0.0, 0.0, 0.0, 0.0}, flood, offset, window, linear, aa), region, False{}, False{}} : FilterInput}
  filter.draw(format, FilterMerge{Con{shade, Con{input, Nil{}}}}, input, input, window, linear, aa)

# The row-major kernel is rotated 180 degrees; target offsets refer to input cells.
def filter.convolution.taps(+xs: List<&2, F32>, +index: U32, +width: U32, +height: U32, +tx: F32, +ty: F32, +dx: Point, +dy: Point) -> List<&2, FilterTap>:
  match xs:
    case Nil{}: Nil{}
    case Con{weight, rest}:
      +x = (U32.to_f32((width - 1 - U32.mod(index, width) : U32)) - tx : F32)
      +y = (U32.to_f32((height - 1 - U32.div(index, width) : U32)) - ty : F32)
      U.branch(List<&2, FilterTap>, F32.is_eq(weight, 0.0), _ => filter.convolution.taps(rest, U32.inc(index), width, height, tx, ty, dx, dy),
        _ => Con{FilterTap{point.add(point.scale(dx, x), point.scale(dy, y)), weight}, filter.convolution.taps(rest, U32.inc(index), width, height, tx, ty, dx, dy)})

def filter.convolution.limits.box(+raster: Raster, box: Bounds) -> Bounds:
  Raster{Point{ox, oy}, step, width, height, depth, stored, pixels} = raster
  Bounds{x0, y0, x1, y1} = box
  Bounds{U.max(0.0, F32.floor(((x0 - ox) / step : F32))), U.max(0.0, F32.floor(((y0 - oy) / step : F32))), U.min(U32.to_f32(width), F32.ceil(((x1 - ox) / step : F32))), U.min(U32.to_f32(height), F32.ceil(((y1 - oy) / step : F32)))}

# Resource domains need exact edges; geometric coverage bounds include a tolerance.
def filter.convolution.bounds(box: Bounds, +units: Matrix) -> Bounds:
  Bounds{x0, y0, x1, y1} = box
  +left = x0
  +top = y0
  +right = x1
  +bottom = y1
  bounds.point(bounds.point(bounds.point(bounds.point(bounds.empty(), matrix.point(units, Point{left, top})), matrix.point(units, Point{right, top})), matrix.point(units, Point{left, bottom})), matrix.point(units, Point{right, bottom}))

def filter.convolution.limits(input: FilterInput, units: Matrix) -> Bounds:
  FilterInput{raster, region, alpha, standard} = input
  filter.convolution.limits.box(raster, filter.convolution.bounds(region, units))

def filter.convolution.parse(+as: List<&2, XML.Attr>, +units: Matrix, +input: FilterInput, +format: Raster) -> FilterOp:
  +order = U.numbers(XML.attr.get(as, "order", "3"))
  +ox = F32.floor(U.nth(order, 0n, 3.0))
  +oy = F32.floor(U.nth(order, 1n, U.nth(order, 0n, 3.0)))
  +width = F32.to_u32(U.clamp(ox, 1.0, 4096.0))
  +height = F32.to_u32(U.clamp(oy, 1.0, 4096.0))
  +tx = F32.floor(U.scalar(XML.attr.get(as, "targetX", ""), F32.floor((ox * 0.5 : F32))))
  +ty = F32.floor(U.scalar(XML.attr.get(as, "targetY", ""), F32.floor((oy * 0.5 : F32))))
  +vs = U.numbers(XML.attr.get(as, "kernelMatrix", ""))
  +sum = floats.sum(vs)
  +defaultDivisor = U.choose(F32, F32.is_eq(sum, 0.0), 1.0, sum)
  +divisor = U.scalar(XML.attr.get(as, "divisor", ""), defaultDivisor)
  +lengths = U.numbers(XML.attr.get(as, "kernelUnitLength", ""))
  +ux = U.nth(lengths, 0n, 0.0)
  +uy = U.nth(lengths, 1n, ux)
  +explicit = F32.is_gt(ux, 0.0) && F32.is_gt(uy, 0.0)
  +step = raster.scale(format)
  +dx = U.choose(Point, explicit, matrix.vector(units, Point{ux, 0.0}), Point{step, 0.0})
  +dy = U.choose(Point, explicit, matrix.vector(units, Point{0.0, uy}), Point{0.0, step})
  +edge = XML.attr.get(as, "edgeMode", "duplicate")
  +valid = F32.is_ge(ox, 1.0) && F32.is_ge(oy, 1.0) && F32.is_le(ox, 4096.0) && F32.is_le(oy, 4096.0) && F32.is_le((ox * oy : F32), 4096.0) && U32.is_eq(floats.count(vs), (width * height : U32)) && F32.is_ge(tx, 0.0) && F32.is_lt(tx, ox) && F32.is_ge(ty, 0.0) && F32.is_lt(ty, oy)
  U.branch(FilterOp, valid, _ => FilterConvolution{Convolution{filter.convolution.taps(vs, 0, width, height, tx, ty, dx, dy), U.choose(F32, F32.is_eq(divisor, 0.0), defaultDivisor, divisor), U.scalar(XML.attr.get(as, "bias", "0"), 0.0), U.string.equal(XML.attr.get(as, "preserveAlpha", "false"), "true"), U.choose(U32, U.string.equal(edge, "wrap"), 1, U.choose(U32, U.string.equal(edge, "none"), 2, 0)), filter.convolution.limits(input, units)}}, _ => FilterCopy{})

def filter.primitive(+name: String, +as: List<&2, XML.Attr>, +kids: List<&2, XML.Element>, +format: Raster, +source: FilterInput, +previous: FilterInput, +results: List<&2, FilterResult>, +region: Bounds, +units: Matrix, +viewport: Point, +aa: U32) -> FilterInput:
  +a = filter.resolve(XML.attr.get(as, "in", ""), source, previous, results)
  +b = filter.resolve(XML.attr.get(as, "in2", ""), source, previous, results)
  +merges = filter.merge.inputs(kids, source, previous, results)
  +two = U.string.equal(name, "feComposite") || U.string.equal(name, "feBlend")
  +defaultBox = U.branch(Bounds, U.string.equal(name, "feFlood"), _ => region,
    _ => U.branch(Bounds, U.string.equal(name, "feMerge"), _ => filter.inputs.region(merges, bounds.empty()), _ => U.choose(Bounds, two, bounds.merge(filter.input.region(a), filter.input.region(b)), filter.input.region(a))))
  +box = bounds.intersection(region, filter.subregion(as, defaultBox, viewport))
  +window = {FilterWindow{box, matrix.inverse(units), False{}} : FilterWindow}
  +linear = U.branch(Bool, U.string.equal(name, "feFlood"), _ => False{}, _ => U.branch(Bool, U.string.equal(name, "feOffset"), _ => raster.is.linear(filter.input.raster(a)), _ => Bool.not(U.string.equal(XML.attr.get(as, "color-interpolation-filters", "linearRGB"), "sRGB"))))
  FilterInput{U.branch(Raster, U.string.equal(name, "feGaussianBlur"), _ => filter.blur(as, format, a, units, window, linear, aa), _ => U.branch(Raster, U.string.equal(name, "feDropShadow"), _ => filter.shadow(as, format, a, units, viewport, window, linear, aa), _ => U.branch(Raster, U.string.equal(name, "feMorphology"), _ => filter.morphology(as, format, a, units, window, linear, aa), _ => filter.draw(format, U.branch(FilterOp, U.string.equal(name, "feConvolveMatrix"), _ => filter.convolution.parse(as, units, a, format), _ => filter.op.parse(name, as, kids, units, viewport, merges)), a, b, window, linear, aa)))), box, False{}, False{}}

@unsafe
def filter.chain(+xs: List<&2, XML.Element>, +format: Raster, +source: FilterInput, +previous: FilterInput, +results: List<&2, FilterResult>, +region: Bounds, +units: Matrix, +viewport: Point, +aa: U32) -> FilterInput:
  match xs:
    case Nil{}: previous
    case Con{XML.Element{name, attrs, kids, txt}, rest}:
      +as = CSS.properties(attrs)
      +next = filter.primitive(name, as, kids, format, source, previous, results, region, units, viewport, aa)
      U.branch(FilterInput, U.prefix(name, "fe"), _ => filter.chain(rest, format, source, next, Con{FilterResult{XML.attr.get(as, "result", ""), next}, results}, region, units, viewport, aa), _ => filter.chain(rest, format, source, previous, results, region, units, viewport, aa))

def filter.padding(+xs: List<&2, XML.Element>, +units: Matrix, +margin: F32) -> F32:
  match xs:
    case Nil{}: margin
    case Con{XML.Element{name, as, kids, txt}, rest}:
      +vs = U.numbers(XML.attr.get(as, "stdDeviation", U.choose(String, U.string.equal(name, "feDropShadow"), "2", "0")))
      +sx = U.nth(vs, 0n, 0.0)
      +sy = U.nth(vs, 1n, sx)
      +pad = (3.0 * (point.distance(matrix.vector(units, Point{sx, 0.0}), Point{0.0, 0.0}) + point.distance(matrix.vector(units, Point{0.0, sy}), Point{0.0, 0.0})) : F32)
      +radii = U.numbers(XML.attr.get(as, "radius", "0"))
      +rx = U.max(U.nth(radii, 0n, 0.0), 0.0)
      +ry = U.max(U.nth(radii, 1n, U.nth(radii, 0n, 0.0)), 0.0)
      +morphPad = (point.distance(matrix.vector(units, Point{rx, 0.0}), Point{0.0, 0.0}) + point.distance(matrix.vector(units, Point{0.0, ry}), Point{0.0, 0.0}) + 2.0 : F32)
      filter.padding(rest, units, U.choose(F32, U.string.equal(name, "feGaussianBlur") || U.string.equal(name, "feDropShadow"), U.max(margin, pad), U.choose(F32, U.string.equal(name, "feMorphology"), U.max(margin, morphPad), margin)))

def filter.present(xs: List<&2, XML.Element>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{XML.Element{name, as, kids, txt}, rest}: U.prefix(name, "fe") || filter.present(rest)

def filter.density(+m: Matrix) -> F32:
  Matrix{a, b, c, d, e, f} = m
  +x = (a * a + b * b : F32)
  +y = (c * c + d * d : F32)
  +dot = (a * c + b * d : F32)
  # Largest singular value keeps transformed pattern buffers at device density.
  F32.sqrt(((x + y + F32.sqrt(((x - y) * (x - y) + 4.0 * dot * dot : F32))) * 0.5 : F32))

def filter.source(scene: Scene<Brush>) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, masks, maskMode, markers, coverage, effect} = scene
  Scene{es, box, inv, style, 1.0, kids, id, ink, ClipAll{}, outline, fillTree, Nil{}, 0, markers, coverage, NoFilter{}}

def filter.render(+scene: Scene<Brush>, +region: Bounds, +units: Matrix, +viewport: Point, +primitives: List<&2, XML.Element>, space: Matrix, +aa: U32) -> Raster:
  +world = bounds.transform(region, units)
  +area = bounds.expand(bounds.merge(world, scene.coverage(Con{scene, Nil{}}, bounds.empty())), filter.padding(primitives, units, 0.0))
  +format = raster.format(area, (1.0 / U.max(filter.density(space), 0.000001) : F32))
  +raw = {FilterInput{raster.scene(format, Con{filter.source(scene), Nil{}}, aa), region, False{}, True{}} : FilterInput}
  +source = {FilterInput{filter.draw(format, FilterCopy{}, raw, raw, FilterWindow{region, matrix.inverse(units), False{}}, False{}, aa), region, False{}, True{}} : FilterInput}
  +result = filter.chain(primitives, format, source, source, Nil{}, region, units, viewport, aa)
  U.branch(Raster, bounds.nonempty(region) && filter.present(primitives),
    _ => filter.draw(format, FilterCopy{}, result, result, FilterWindow{region, matrix.inverse(units), True{}}, raster.is.linear(filter.input.raster(result)), aa), _ => raster.empty())

def filter.cache(scene: Scene<Brush>, raster: Raster, area: Bounds) -> Scene<Brush>:
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, masks, maskMode, markers, coverage, effect} = scene
  Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, masks, maskMode, markers, area, FilterImage{raster}}

def prepare.effect(effect: FilterEffect, +scene: Scene<Brush>, space: Matrix, aa: U32) -> Scene<Brush>:
  match effect:
    case NoFilter{}: scene
    case FilterImage{raster}: scene
    case FilterSpec{region, units, viewport, attrs, primitives}:
      +box = region
      +mat = units
      +buffer = filter.render(scene, box, mat, viewport, primitives, space, aa)
      filter.cache(scene, buffer, bounds.expand(bounds.transform(box, mat), raster.scale(buffer)))

def prepare.brush(brush: Brush, +space: Matrix, next: List<&2, Scene<Brush>> -> Matrix -> List<&2, Scene<Brush>>) -> Brush:
  match brush:
    case Bitmap{raster, inv, nearest}: Bitmap{raster, inv, nearest}
    case Solid{c, source}: Solid{c, source}
    case PendingContext{stroke, opacity}: PendingContext{stroke, opacity}
    case ContextPaint{source, mat, opacity}:
      +matrix = mat
      ContextPaint{prepare.brush(source, matrix.mul(space, matrix.inverse(matrix)), next), matrix, opacity}
    case Pattern{inv, width, height, opacity, nodes}:
      +matrix = inv
      Pattern{matrix, width, height, opacity, next(nodes)(matrix.mul(space, matrix.inverse(matrix)))}
    case Tile{raster, inv, width, height, opacity, u, v, grid}: Tile{raster, inv, width, height, opacity, u, v, grid}
    case Gradient{inv, radial, start, end, radius, focal, stops, spread, opacity, linear}: Gradient{inv, radial, start, end, radius, focal, stops, spread, opacity, linear}

def prepare.paint(ink: Paint<Brush>, +space: Matrix, fills: List<&2, Scene<Brush>> -> Matrix -> List<&2, Scene<Brush>>, strokes: List<&2, Scene<Brush>> -> Matrix -> List<&2, Scene<Brush>>) -> Paint<Brush>:
  Paint{fill, stroke} = ink
  Paint{prepare.brush(fill, space, fills), prepare.brush(stroke, space, strokes)}

@unsafe
def prepare.scenes(+xs: List<&2, Scene<Brush>>, +space: Matrix, +aa: U32) -> List<&2, Scene<Brush>>:
  match xs:
    case Nil{}: Nil{}
    case Con{Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fillTree, masks, maskMode, markers, coverage, effect}, rest}:
      +node = scene.covered(Scene{es, box, inv, style, opacity, prepare.scenes(kids, space, aa), id, prepare.paint(ink, matrix.mul(space, matrix.inverse(inv)), nodes => mat => prepare.scenes(nodes, mat, aa), nodes => mat => prepare.scenes(nodes, mat, aa)), clip, outline, fillTree, prepare.scenes(masks, space, aa), maskMode, prepare.scenes(markers, space, aa), coverage, effect})
      Con{prepare.effect(effect, node, space, aa), prepare.scenes(rest, space, aa)}

# Portable image export for headless rendering and reference comparisons.
def pixel.ppm(c: U32) -> String:
  +rgb = c
  U32.show((rgb / 65536 % 256 : U32)) ++ " " ++ U32.show((rgb / 256 % 256 : U32))
    ++ " " ++ U32.show((rgb % 256 : U32)) ++ "\n"

# ---- painter ----
# Nodes are painted back to front into a flat layer of packed 8-bit
# premultiplied RGBA pixels (one U32 per pixel) straight from their coverage
# masks: a mask leaf that spans a block paints the block with one coverage
# value, so for a solid brush the blended color is computed once per block and
# each pixel is a read, an integer blend and a write, with no constructor or
# closure on the way. Nodes with opacity, a mask or a rendered filter are
# painted into a layer of their own and composited; enclosing clips travel down
# as the coverage limit the per-pixel sampler also uses, so both paths agree up
# to the 8-bit rounding of the layers.

def frame(+w: U32, +h: U32) -> Raster:
  Raster{Point{0.0, 0.0}, 1.0, w, h, raster.depth(U.choose(U32, U32.is_gt(w, h), w, h), 1, 0n), False{}, Img.Flat{Img.clear()}}

# A layer covers the device rectangle at (x, y) of w by h pixels; pixel (px, py)
# lives at index (py - y) * w + (px - x). The frame is the target at the origin;
# a group's layer is only as large as the group's coverage box.
type Target is Data:
  Target{x: U32, y: U32, w: U32, h: U32}

def layer.new(+t: Target) -> Array<U32>:
  Target{x, y, w, h} = t
  Array.new(U32, raster.depth(U.choose(U32, U32.is_eq((w * h : U32), 0), 1, (w * h : U32)), 1, 0n), 0)

def target.index(+t: Target, +px: U32, +py: U32) -> U32:
  Target{x, y, w, h} = t
  ((py - y) * w + px - x : U32)

# The target's rectangle intersected with a device box, as a target.
def target.within(+t: Target, +box: Bounds) -> Target:
  Target{x, y, w, h} = t
  Bounds{bx0, by0, bx1, by1} = box
  +x0 = F32.to_u32(U.clamp(F32.floor(bx0), U32.to_f32(x), U32.to_f32((x + w : U32))))
  +y0 = F32.to_u32(U.clamp(F32.floor(by0), U32.to_f32(y), U32.to_f32((y + h : U32))))
  +x1 = F32.to_u32(U.clamp(F32.ceil(bx1), U32.to_f32(x), U32.to_f32((x + w : U32))))
  +y1 = F32.to_u32(U.clamp(F32.ceil(by1), U32.to_f32(y), U32.to_f32((y + h : U32))))
  Target{x0, y0, U.choose(U32, U32.is_gt(x1, x0), (x1 - x0 : U32), 0), U.choose(U32, U32.is_gt(y1, y0), (y1 - y0 : U32), 0)}

# ---- packed pixels ----

def pixel.lane(+px: U32, +unit: U32) -> U32:
  U32.mod(U32.div(px, unit), 256)

def pixel.make(+r: U32, +g: U32, +b: U32, +a: U32) -> U32:
  (r + g * 256 + b * 65536 + a * 16777216 : U32)

# A premultiplied color scaled by f, rounded to 8 bits.
def pixel.pack(c: Img.Color, +f: F32) -> U32:
  Img.Color{r, g, b, a} = c
  pixel.make(channel((r * f : F32)), channel((g * f : F32)), channel((b * f : F32)), channel((a * f : F32)))

def pixel.round(+v: U32, +f: F32) -> U32:
  F32.to_u32(F32.floor((U32.to_f32(v) * f + 0.5 : F32)))

# A packed pixel scaled by f in every channel.
def pixel.scale(+px: U32, +f: F32) -> U32:
  pixel.make(pixel.round(pixel.lane(px, 1), f), pixel.round(pixel.lane(px, 256), f), pixel.round(pixel.lane(px, 65536), f), pixel.round(pixel.lane(px, 16777216), f))

# front over back, both premultiplied: front + back * (255 - alpha) / 255 per
# channel, written as one expression over the four lanes.
def pixel.over(+front: U32, +back: U32) -> U32:
  +fa = U32.div(front, 16777216)
  +keep = (255 - fa : U32)
  +fb = U32.mod(U32.div(front, 65536), 256)
  +fg = U32.mod(U32.div(front, 256), 256)
  +fr = U32.mod(front, 256)
  +ba = U32.div(back, 16777216)
  +bb = U32.mod(U32.div(back, 65536), 256)
  +bg = U32.mod(U32.div(back, 256), 256)
  +br = U32.mod(back, 256)
  (fr + U32.div((br * keep + 127 : U32), 255) + (fg + U32.div((bg * keep + 127 : U32), 255)) * 256 + (fb + U32.div((bb * keep + 127 : U32), 255)) * 65536 + (fa + U32.div((ba * keep + 127 : U32), 255)) * 16777216 : U32)

# The pixel over white as the packed 0xRRGGBB the outputs use.
def pixel.white(+px: U32) -> U32:
  +a = pixel.lane(px, 16777216)
  ((pixel.lane(px, 1) + 255 - a) * 65536 + (pixel.lane(px, 256) + 255 - a) * 256 + pixel.lane(px, 65536) + 255 - a : U32)

# The mask factor a packed pixel gives: its alpha, or the luminance of its premultiplied color.
def pixel.mask(+px: U32, +mode: U32) -> F32:
  U.choose(F32, U32.is_eq(mode, 1), (U32.to_f32(pixel.lane(px, 16777216)) / 255.0 : F32),
    ((U32.to_f32(pixel.lane(px, 1)) * 0.2126 + U32.to_f32(pixel.lane(px, 256)) * 0.7152 + U32.to_f32(pixel.lane(px, 65536)) * 0.0722) / 255.0 : F32))

def blend.got(got: Array<U32> & U32, +i: U32, +front: U32) -> Array<U32>:
  (a, back) = got
  Array.set(U32, a, i, pixel.over(front, back))

# Composite a packed front over the pixel at index i.
def blend(a: Array<U32>, +i: U32, +front: U32) -> Array<U32>:
  blend.got(Array.get(U32, a, i), i, front)

def paint.with(cond: Bool, a: Array<U32>, yes: Array<U32> -> Array<U32>, no: Array<U32> -> Array<U32>) -> Array<U32>:
  match cond:
    case True{}: yes(a)
    case False{}: no(a)

# ---- clip limits without lambdas ----

def cover.value(present: Bool, +cov: Cover, +es: EdgeTree, +inv: Matrix, +even: Bool, +p: Point) -> F32:
  match present:
    case True{}: cover.at(cov, p)
    case False{}: U.choose(F32, edge.tree.inside(es, matrix.point(inv, p), even), 1.0, 0.0)

# clip.cover, branching through matches since it runs once per clipped pixel.
def clip.limit(c: Clip, +p: Point) -> F32:
  match c:
    case ClipAll{}: 1.0
    case ClipShape{es, inv, even, cover}:
      +cov = cover
      cover.value(cover.present(cov), cov, es, inv, even, p)
    case ClipUnion{a, b}:
      +u = clip.limit(a, p)
      +v = clip.limit(b, p)
      (u + v - u * v : F32)
    case ClipIntersect{a, b}: (clip.limit(a, p) * clip.limit(b, p) : F32)

# The least coverage the enclosing clips leave at p.
def paint.limit(clips: List<&2, Clip>, +p: Point, +acc: F32) -> F32:
  match clips:
    case Nil{}: acc
    case Con{c, rest}: paint.limit(rest, p, U.min(acc, clip.limit(c, p)))

# A clip's coverage over the device pixel block [x0, x1) by [y0, y1) when it is
# uniform there, else -1; the frame grid is the device grid.
def cover.block(+cov: Cover, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  Cover{mask, origin, step} = cov
  Cov.mask.uniform(mask, x0, y0, x1, y1)

def cover.block.if(present: Bool, +cov: Cover, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  match present:
    case True{}: cover.block(cov, x0, y0, x1, y1)
    case False{}: F32.neg(1.0)

def clip.block(c: Clip, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  match c:
    case ClipAll{}: 1.0
    case ClipShape{es, inv, even, cover}:
      +cov = cover
      cover.block.if(cover.present(cov), cov, x0, y0, x1, y1)
    case ClipUnion{a, b}:
      +u = clip.block(a, x0, y0, x1, y1)
      +v = clip.block(b, x0, y0, x1, y1)
      U.choose(F32, F32.is_lt(u, 0.0) || F32.is_lt(v, 0.0), F32.neg(1.0), (u + v - u * v : F32))
    case ClipIntersect{a, b}:
      +u = clip.block(a, x0, y0, x1, y1)
      +v = clip.block(b, x0, y0, x1, y1)
      U.choose(F32, F32.is_lt(u, 0.0) || F32.is_lt(v, 0.0), F32.neg(1.0), (u * v : F32))

# The least clip coverage over a block when every clip is uniform there, else -1.
def paint.limit.block(clips: List<&2, Clip>, +x0: U32, +y0: U32, +x1: U32, +y1: U32, +acc: F32) -> F32:
  match clips:
    case Nil{}: acc
    case Con{c, rest}:
      +u = clip.block(c, x0, y0, x1, y1)
      paint.limit.block(rest, x0, y0, x1, y1, U.choose(F32, F32.is_lt(u, 0.0) || F32.is_lt(acc, 0.0), F32.neg(1.0), U.min(acc, u)))

def paint.clipped(clips: List<&2, Clip>) -> Bool:
  match clips:
    case Nil{}: False{}
    case Con{c, rest}: True{}

# ---- shape pixels ----

# What one shape's pixels need: the brush (a solid color is kept as a premultiplied
# color to scale per block), the device-to-local matrix, the color space and the
# enclosing clips.
type PaintCtx is Data:
  PaintCtx{brush: Brush, inverse: Matrix, linear: Bool, clips: List<&2, Clip>, solid: Bool, tint: Img.Color, clipped: Bool}

def paint.solid(+brush: Brush) -> Bool:
  match brush:
    case Solid{c, source}: True{}
    case _: False{}

def paint.solid.color(+brush: Brush, +linear: Bool) -> Img.Color:
  match brush:
    case Solid{c, source}: color.space(c, linear)
    case _: Img.clear()

def paint.context(+brush: Brush, +inv: Matrix, +linear: Bool, +clips: List<&2, Clip>) -> PaintCtx:
  PaintCtx{brush, inv, linear, clips, paint.solid(brush), paint.solid.color(brush, linear), paint.clipped(clips)}

def paint.sampled(+br: Brush, +inv: Matrix, +linear: Bool, +p: Point) -> Img.Color:
  color.space(brush.sample(br, matrix.point(inv, p), matrix.point(inv, p), nodes => q => center => Img.clear()), linear)

def paint.sampled.ctx(+ctx: PaintCtx, +p: Point) -> Img.Color:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  paint.sampled(br, inv, linear, p)

def paint.tint.ctx(+ctx: PaintCtx) -> Img.Color:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  tint

def paint.color(solid: Bool, +ctx: PaintCtx, +p: Point) -> Img.Color:
  match solid:
    case True{}: paint.tint.ctx(ctx)
    case False{}: paint.sampled.ctx(ctx, p)

def paint.ctx.solid(+ctx: PaintCtx) -> Bool:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  solid

def paint.ctx.direct(+ctx: PaintCtx) -> Bool:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  solid && Bool.not(clipped)

def paint.ctx.tint(+ctx: PaintCtx) -> Img.Color:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  tint

def paint.ctx.clips(+ctx: PaintCtx) -> List<&2, Clip>:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  clips

# The general pixel: brush sampled or solid, coverage limited by the clips; a
# known block limit (0 or more) replaces the per-pixel clip reads.
def paint.pixel(fb: Array<U32>, +x: U32, +y: U32, +v: F32, +known: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  +p = {Point{(U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32)} : Point}
  blend(fb, target.index(t, x, y), pixel.pack(paint.color(paint.ctx.solid(ctx), ctx, p), U.min(v, U.choose(F32, F32.is_lt(known, 0.0), paint.limit(paint.ctx.clips(ctx), p, 1.0), known))))

@unsafe
def paint.row(fb: Array<U32>, n: Nat, +x: U32, +y: U32, +v: F32, +known: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: paint.row(paint.pixel(fb, x, y, v, known, t, ctx), d, (x + 1 : U32), y, v, known, t, ctx)

@unsafe
def paint.rows(fb: Array<U32>, n: Nat, +x0: U32, +y: U32, +cols: Nat, +v: F32, +known: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: paint.rows(paint.row(fb, cols, x0, y, v, known, t, ctx), d, x0, (y + 1 : U32), cols, v, known, t, ctx)

# The fast pixel: a constant packed front blended along the row, its
# channels split once per row.
def pixel.under(+fr: U32, +fg: U32, +fb: U32, +fa: U32, +keep: U32, +back: U32) -> U32:
  (fr + U32.div((U32.mod(back, 256) * keep + 127 : U32), 255) + (fg + U32.div((U32.mod(U32.div(back, 256), 256) * keep + 127 : U32), 255)) * 256
    + (fb + U32.div((U32.mod(U32.div(back, 65536), 256) * keep + 127 : U32), 255)) * 65536 + (fa + U32.div((U32.div(back, 16777216) * keep + 127 : U32), 255)) * 16777216 : U32)

def blend.pre.got(got: Array<U32> & U32, +i: U32, +fr: U32, +fg: U32, +fb: U32, +fa: U32, +keep: U32) -> Array<U32>:
  (a, back) = got
  Array.set(U32, a, i, pixel.under(fr, fg, fb, fa, keep, back))

@unsafe
def fill.row.pre(fb: Array<U32>, n: Nat, +i: U32, +fr: U32, +fg: U32, +fbl: U32, +fa: U32, +keep: U32) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: fill.row.pre(blend.pre.got(Array.get(U32, fb, i), i, fr, fg, fbl, fa, keep), d, (i + 1 : U32), fr, fg, fbl, fa, keep)

def fill.row(fb: Array<U32>, n: Nat, +i: U32, +front: U32) -> Array<U32>:
  +fa = U32.div(front, 16777216)
  fill.row.pre(fb, n, i, U32.mod(front, 256), U32.mod(U32.div(front, 256), 256), U32.mod(U32.div(front, 65536), 256), fa, (255 - fa : U32))

@unsafe
def fill.rows(fb: Array<U32>, n: Nat, +x0: U32, +y: U32, +cols: Nat, +t: Target, +front: U32) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: fill.rows(fill.row(fb, cols, target.index(t, x0, y), front), d, x0, (y + 1 : U32), cols, t, front)

# A block's rows or columns within the target: start and count.
def paint.from(+at: U32, +lo: U32) -> U32:
  U.choose(U32, U32.is_lt(at, lo), lo, at)

def paint.span(+at: U32, +size: U32, +lo: U32, +hi: U32) -> U32:
  +a = paint.from(at, lo)
  +b = U.choose(U32, U32.is_lt((at + size : U32), hi), (at + size : U32), hi)
  U.choose(U32, U32.is_gt(b, a), (b - a : U32), 0)

# An opaque front replaces the pixels outright, no read and no blend.
@unsafe
def set.row(fb: Array<U32>, n: Nat, +i: U32, +front: U32) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: set.row(Array.set(U32, fb, i, front), d, (i + 1 : U32), front)

@unsafe
def set.rows(fb: Array<U32>, n: Nat, +x0: U32, +y: U32, +cols: Nat, +t: Target, +front: U32) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: set.rows(set.row(fb, cols, target.index(t, x0, y), front), d, x0, (y + 1 : U32), cols, t, front)

def fill.rows.mode(opaque: Bool, fb: Array<U32>, n: Nat, +x0: U32, +y: U32, +cols: Nat, +t: Target, +front: U32) -> Array<U32>:
  match opaque:
    case True{}: set.rows(fb, n, x0, y, cols, t, front)
    case False{}: fill.rows(fb, n, x0, y, cols, t, front)

def paint.block.mode(direct: Bool, fb: Array<U32>, +x0: U32, +y0: U32, +rows: Nat, +cols: Nat, +v: F32, +known: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match direct:
    case True{}:
      +front = pixel.pack(paint.ctx.tint(ctx), U.min(v, known))
      fill.rows.mode(U32.is_eq(U32.div(front, 16777216), 255), fb, rows, x0, y0, cols, t, front)
    case False{}: paint.rows(fb, rows, x0, y0, cols, v, known, t, ctx)

# A block whose clips are uniform paints with that limit folded in: nothing
# when it is zero, the constant front when the brush is solid, the general row
# without clip reads otherwise; a block a clip edge crosses reads clips per pixel.
def paint.block.known(fb: Array<U32>, +x0: U32, +y0: U32, +rows: Nat, +cols: Nat, +v: F32, +known: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  paint.block.mode(F32.is_ge(known, 0.0) && paint.ctx.solid(ctx), fb, x0, y0, rows, cols, v, known, t, ctx)

def paint.block.some(skip: Bool, fb: Array<U32>, +x0: U32, +y0: U32, +rows: Nat, +cols: Nat, +v: F32, +known: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match skip:
    case True{}: fb
    case False{}: paint.block.known(fb, x0, y0, rows, cols, v, known, t, ctx)

def paint.block.limit(clipped: Bool, +clips: List<&2, Clip>, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  match clipped:
    case True{}: paint.limit.block(clips, x0, y0, x1, y1, 1.0)
    case False{}: 1.0

def paint.ctx.clipped(+ctx: PaintCtx) -> Bool:
  PaintCtx{br, inv, linear, clips, solid, tint, clipped} = ctx
  clipped

# One uniform block of a mask, clipped to the target. A block a clip edge
# crosses is split in four down to eight pixels, so the per-pixel clip reads
# stay near the edge and the rest of the block still fills at once.
@unsafe
def paint.block(fb: Array<U32>, +x0: U32, +y0: U32, +size: U32, +v: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  Target{tx, ty, tw, th} = t
  +bx = paint.from(x0, tx)
  +by = paint.from(y0, ty)
  +cols = paint.span(x0, size, tx, (tx + tw : U32))
  +rows = paint.span(y0, size, ty, (ty + th : U32))
  +known = paint.block.limit(paint.ctx.clipped(ctx), paint.ctx.clips(ctx), bx, by, (bx + cols : U32), (by + rows : U32))
  +half = U32.div(size, 2)
  paint.with(F32.is_lt(known, 0.0) && U32.is_gt(size, 8) && U32.is_gt(cols, 0) && U32.is_gt(rows, 0), fb,
    fb1 => paint.block(paint.block(paint.block(paint.block(fb1, x0, y0, half, v, t, ctx), (x0 + half : U32), y0, half, v, t, ctx), x0, (y0 + half : U32), half, v, t, ctx), (x0 + half : U32), (y0 + half : U32), half, v, t, ctx),
    fb1 => paint.block.some(U32.is_eq(cols, 0) || U32.is_eq(rows, 0) || F32.is_eq(known, 0.0), fb1, bx, by, U32.to_nat(rows), U32.to_nat(cols), v, known, t, ctx))

def paint.block.if(cond: Bool, fb: Array<U32>, +x0: U32, +y0: U32, +size: U32, +v: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match cond:
    case True{}: paint.block(fb, x0, y0, size, v, t, ctx)
    case False{}: fb

@unsafe
def paint.tree(fb: Array<U32>, t: Cov.CovTree, +x0: U32, +y0: U32, +size: U32, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  match t:
    case Cov.CovFlat{v}:
      +vv = v
      paint.block.if(F32.is_gt(vv, 0.0), fb, x0, y0, size, vv, tg, ctx)
    case Cov.CovQuad{a, b, c, d}:
      +half = U32.div(size, 2)
      paint.tree(paint.tree(paint.tree(paint.tree(fb, a, x0, y0, half, tg, ctx), b, (x0 + half : U32), y0, half, tg, ctx), c, x0, (y0 + half : U32), half, tg, ctx), d, (x0 + half : U32), (y0 + half : U32), half, tg, ctx)

def paint.tree.if(cond: Bool, fb: Array<U32>, t: Cov.CovTree, +x0: U32, +y0: U32, +size: U32, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  match cond:
    case True{}: paint.tree(fb, t, x0, y0, size, tg, ctx)
    case False{}: fb

# One run of a row: the columns within the target, the clip limit over them
# (per pixel when a clip edge crosses the run), then the row painter.
# One run of a row: the columns within the target, the clip limit over
# them (the box's limit when that is uniform, else read per run and per
# pixel when a clip edge crosses the run), then the row painter.
def paint.run(fb: Array<U32>, +x0: U32, +x1: U32, +v: F32, +y: U32, +fixed: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  Target{tx, ty, tw, th} = t
  +bx = paint.from(x0, tx)
  +cols = paint.span(x0, (x1 - x0 : U32), tx, (tx + tw : U32))
  +known = U.choose(F32, F32.is_lt(fixed, 0.0), paint.block.limit(paint.ctx.clipped(ctx), paint.ctx.clips(ctx), bx, y, (bx + cols : U32), (y + 1 : U32)), fixed)
  paint.block.some(U32.is_eq(cols, 0) || F32.is_eq(known, 0.0), fb, bx, y, 1n, U32.to_nat(cols), v, known, t, ctx)

@unsafe
def paint.runs(fb: Array<U32>, runs: List<&2, Cov.Run>, +gx: U32, +y: U32, +fixed: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match runs:
    case Nil{}: fb
    case Con{Cov.Run{x0, x1, v}, rest}: paint.runs(paint.run(fb, (gx + x0 : U32), (gx + x1 : U32), v, y, fixed, t, ctx), rest, gx, y, fixed, t, ctx)

def paint.row.if(inside: Bool, fb: Array<U32>, runs: List<&2, Cov.Run>, +gx: U32, +y: U32, +fixed: F32, +t: Target, +ctx: PaintCtx) -> Array<U32>:
  match inside:
    case True{}: paint.runs(fb, runs, gx, y, fixed, t, ctx)
    case False{}: fb

# Rows of runs painted straight into the target, no tree needed.
@unsafe
def paint.rows.go(fb: Array<U32>, rows: List<&2, List<&2, Cov.Run>>, +gx: U32, +y: U32, +fixed: F32, +tx: U32, +ty: U32, +tw: U32, +th: U32, +ctx: PaintCtx) -> Array<U32>:
  match rows:
    case Nil{}: fb
    case Con{r, rest}:
      paint.rows.go(paint.row.if(U32.is_ge(y, ty) && U32.is_lt(y, (ty + th : U32)), fb, r, gx, y, fixed, Target{tx, ty, tw, th}, ctx), rest, gx, (y + 1 : U32), fixed, tx, ty, tw, th, ctx)

def paint.rows.of(fb: Array<U32>, rows: List<&2, List<&2, Cov.Run>>, +gx: U32, +y: U32, +fixed: F32, t: Target, +ctx: PaintCtx) -> Array<U32>:
  Target{tx, ty, tw, th} = t
  paint.rows.go(fb, rows, gx, y, fixed, tx, ty, tw, th, ctx)

# A solid brush with a uniform clip limit paints runs straight: the front
# for full coverage is packed once per shape, a partial run packs its own,
# and an opaque front is written without a read.
def paint.solid.row.mode(opaque: Bool, fb: Array<U32>, +i: U32, +cols: Nat, +front: U32) -> Array<U32>:
  match opaque:
    case True{}: set.row(fb, cols, i, front)
    case False{}: fill.row(fb, cols, i, front)

# The target rectangle and the tint travel as plain numbers through the run
# loops: a record passed along would be shared and read again at every run.
def paint.solid.run.some(skip: Bool, fb: Array<U32>, +bx: U32, +cols: U32, +v: F32, +y: U32, +tx: U32, +ty: U32, +tw: U32, +full: U32, +tr: F32, +tg: F32, +tb: F32, +ta: F32, +limit: F32) -> Array<U32>:
  match skip:
    case True{}: fb
    case False{}:
      +front = U.choose(U32, F32.is_ge(v, 1.0), full, pixel.pack(Img.Color{tr, tg, tb, ta}, U.min(v, limit)))
      paint.solid.row.mode(U32.is_eq(U32.div(front, 16777216), 255), fb, ((y - ty) * tw + bx - tx : U32), U32.to_nat(cols), front)

def paint.solid.run(fb: Array<U32>, +x0: U32, +x1: U32, +v: F32, +y: U32, +tx: U32, +ty: U32, +tw: U32, +full: U32, +tr: F32, +tg: F32, +tb: F32, +ta: F32, +limit: F32) -> Array<U32>:
  +bx = paint.from(x0, tx)
  +cols = paint.span(x0, (x1 - x0 : U32), tx, (tx + tw : U32))
  paint.solid.run.some(U32.is_eq(cols, 0), fb, bx, cols, v, y, tx, ty, tw, full, tr, tg, tb, ta, limit)

@unsafe
def paint.solid.runs(fb: Array<U32>, runs: List<&2, Cov.Run>, +gx: U32, +y: U32, +tx: U32, +ty: U32, +tw: U32, +full: U32, +tr: F32, +tg: F32, +tb: F32, +ta: F32, +limit: F32) -> Array<U32>:
  match runs:
    case Nil{}: fb
    case Con{Cov.Run{x0, x1, v}, rest}: paint.solid.runs(paint.solid.run(fb, (gx + x0 : U32), (gx + x1 : U32), v, y, tx, ty, tw, full, tr, tg, tb, ta, limit), rest, gx, y, tx, ty, tw, full, tr, tg, tb, ta, limit)

def paint.solid.row.if(inside: Bool, fb: Array<U32>, runs: List<&2, Cov.Run>, +gx: U32, +y: U32, +tx: U32, +ty: U32, +tw: U32, +full: U32, +tr: F32, +tg: F32, +tb: F32, +ta: F32, +limit: F32) -> Array<U32>:
  match inside:
    case True{}: paint.solid.runs(fb, runs, gx, y, tx, ty, tw, full, tr, tg, tb, ta, limit)
    case False{}: fb

@unsafe
def paint.solid.rows.go(fb: Array<U32>, rows: List<&2, List<&2, Cov.Run>>, +gx: U32, +y: U32, +tx: U32, +ty: U32, +tw: U32, +th: U32, +full: U32, +tr: F32, +tg: F32, +tb: F32, +ta: F32, +limit: F32) -> Array<U32>:
  match rows:
    case Nil{}: fb
    case Con{r, rest}:
      paint.solid.rows.go(paint.solid.row.if(U32.is_ge(y, ty) && U32.is_lt(y, (ty + th : U32)), fb, r, gx, y, tx, ty, tw, full, tr, tg, tb, ta, limit), rest, gx, (y + 1 : U32), tx, ty, tw, th, full, tr, tg, tb, ta, limit)

def paint.solid.rows(fb: Array<U32>, rows: List<&2, List<&2, Cov.Run>>, +gx: U32, +y: U32, t: Target, +full: U32, tint: Img.Color, +limit: F32) -> Array<U32>:
  Target{tx, ty, tw, th} = t
  Img.Color{tr, tg, tb, ta} = tint
  paint.solid.rows.go(fb, rows, gx, y, tx, ty, tw, th, full, tr, tg, tb, ta, limit)

def paint.rows.mode(solid: Bool, fb: Array<U32>, rows: List<&2, List<&2, Cov.Run>>, +gx: U32, +gy: U32, +fixed: F32, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  match solid:
    case True{}:
      +tint = paint.ctx.tint(ctx)
      paint.solid.rows(fb, rows, gx, gy, tg, pixel.pack(tint, fixed), tint, fixed)
    case False{}: paint.rows.of(fb, rows, gx, gy, fixed, tg, ctx)

# The clips are read once over the mask's whole box: uniform there (the
# usual case, a shape inside the viewport clip), that limit serves every
# run and nothing reads the clips again; zero there paints nothing.
def paint.data(d: Cov.CovData, fb: Array<U32>, +gx: U32, +gy: U32, +size: U32, +fixed: F32, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  match d:
    case Cov.CovRows{rows}: paint.rows.mode(F32.is_ge(fixed, 0.0) && paint.ctx.solid(ctx), fb, rows, gx, gy, fixed, tg, ctx)
    case Cov.CovTreed{tree}: paint.tree(fb, tree, gx, gy, size, tg, ctx)

def paint.data.known(empty: Bool, +known: F32, d: Cov.CovData, fb: Array<U32>, +gx: U32, +gy: U32, +size: U32, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  match empty:
    case True{}: fb
    case False{}: paint.data(d, fb, gx, gy, size, known, tg, ctx)

def paint.data.if(present: Bool, d: Cov.CovData, fb: Array<U32>, +gx: U32, +gy: U32, +w: U32, +h: U32, +size: U32, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  match present:
    case True{}:
      Target{tx, ty, tw, th} = tg
      +x0 = U.max.u32(gx, tx)
      +y0 = U.max.u32(gy, ty)
      +x1 = U.min.u32((gx + w : U32), (tx + tw : U32))
      +y1 = U.min.u32((gy + h : U32), (ty + th : U32))
      +known = U.choose(F32, U32.is_ge(x0, x1) || U32.is_ge(y0, y1), 0.0, paint.block.limit(paint.ctx.clipped(ctx), paint.ctx.clips(ctx), x0, y0, x1, y1))
      paint.data.known(F32.is_eq(known, 0.0), known, d, fb, gx, gy, size, Target{tx, ty, tw, th}, ctx)
    case False{}: fb

# A shape's coverage mask on the frame grid, painted with its brush.
def paint.cover(fb: Array<U32>, +cov: Cover, +tg: Target, +ctx: PaintCtx) -> Array<U32>:
  Cover{Cov.CovMask{gx, gy, w, h, size, depth, data, present}, origin, step} = cov
  paint.data.if(present, data, fb, gx, gy, w, h, size, tg, ctx)

def paint.fill.if(cond: Bool, fb: Array<U32>, f: Fill, +brush: Brush, +inv: Matrix, +linear: Bool, +clips: List<&2, Clip>, +tg: Target) -> Array<U32>:
  match cond:
    case True{}:
      Fill{box, cover} = f
      paint.cover(fb, cover, tg, paint.context(brush, inv, linear, clips))
    case False{}: fb

def paint.stroke.if(cond: Bool, fb: Array<U32>, mesh: StrokeMesh, +brush: Brush, +inv: Matrix, +linear: Bool, +clips: List<&2, Clip>, +tg: Target) -> Array<U32>:
  match cond:
    case True{}:
      StrokeMesh{tree, meshInverse, cover} = mesh
      paint.cover(fb, cover, tg, paint.context(brush, inv, linear, clips))
    case False{}: fb

# The fill, stroke and markers of a shape in its paint order (see
# paint.order.first): each arm hands the fill's and the stroke's masks to
# exactly one painter, so the masks are never shared and walked as copies.
def paint.pieces(order: U32, fb: Array<U32>, +fills: Bool, +strokes: Bool, ink: Paint<Brush>, +inv: Matrix, outline: StrokeMesh, f: Fill, markers: Array<U32> -> Array<U32>, +linear: Bool, +clips: List<&2, Clip>, +tg: Target) -> Array<U32>:
  match order:
    case 0:
      Paint{fc, sc} = ink
      markers(paint.stroke.if(strokes, paint.fill.if(fills, fb, f, fc, inv, linear, clips, tg), outline, sc, inv, linear, clips, tg))
    case 1:
      Paint{fc, sc} = ink
      paint.stroke.if(strokes, markers(paint.fill.if(fills, fb, f, fc, inv, linear, clips, tg)), outline, sc, inv, linear, clips, tg)
    case 2:
      Paint{fc, sc} = ink
      markers(paint.fill.if(fills, paint.stroke.if(strokes, fb, outline, sc, inv, linear, clips, tg), f, fc, inv, linear, clips, tg))
    case 3:
      Paint{fc, sc} = ink
      paint.fill.if(fills, markers(paint.stroke.if(strokes, fb, outline, sc, inv, linear, clips, tg)), f, fc, inv, linear, clips, tg)
    case 4:
      Paint{fc, sc} = ink
      paint.stroke.if(strokes, paint.fill.if(fills, markers(fb), f, fc, inv, linear, clips, tg), outline, sc, inv, linear, clips, tg)
    case _:
      Paint{fc, sc} = ink
      paint.fill.if(fills, paint.stroke.if(strokes, markers(fb), outline, sc, inv, linear, clips, tg), f, fc, inv, linear, clips, tg)

# paint-order as three steps: the first piece is order / 2, the other two in
# ascending order for an even value and descending for an odd one.
def paint.order.first(+order: U32) -> U32:
  U32.div(order, 2)

def paint.order.second(+order: U32) -> U32:
  +first = U32.div(order, 2)
  +lo = U.choose(U32, U32.is_eq(first, 0), 1, 0)
  +hi = U.choose(U32, U32.is_eq(first, 2), 1, 2)
  U.choose(U32, U32.is_eq(U32.mod(order, 2), 0), lo, hi)

def paint.order.third(+order: U32) -> U32:
  +first = U32.div(order, 2)
  +lo = U.choose(U32, U32.is_eq(first, 0), 1, 0)
  +hi = U.choose(U32, U32.is_eq(first, 2), 1, 2)
  U.choose(U32, U32.is_eq(U32.mod(order, 2), 0), hi, lo)

def paint.order.of(+s: Style) -> U32:
  Style{fill, stroke, col, fo, so, width, even, visible, ss, ms, rendering, order} = s
  order

def paint.markers.at(+which: U32, +nodes: List<&2, Scene<Brush>>) -> List<&2, Scene<Brush>>:
  U.choose(List<&2, Scene<Brush>>, U32.is_eq(which, 2), nodes, Nil{})

def paint.clips(clip: Clip, +clips: List<&2, Clip>) -> List<&2, Clip>:
  match clip:
    case ClipAll{}: clips
    case _: Con{clip, clips}

# ---- layer compositing ----

def comp.factor.got(got: Array<U32> & U32, +mode: U32) -> Array<U32> & F32:
  (a, px) = got
  (a, pixel.mask(px, mode))

# The mask factor at index i: one without a mask, else from the mask layer's pixel.
def comp.factor.if(read: Bool, mask: Array<U32>, +i: U32, +mode: U32) -> Array<U32> & F32:
  match read:
    case True{}: comp.factor.got(Array.get(U32, mask, i), mode)
    case False{}: (mask, 1.0)

def comp.factor(mask: Array<U32>, +i: U32, +mode: U32) -> Array<U32> & F32:
  comp.factor.if(U32.is_ne(mode, 0), mask, i, mode)

def comp.pixel.mask(got: Array<U32> & F32, fb: Array<U32>, layer: Array<U32>, +i: U32, +opacity: F32, +px: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  (mask, f) = got
  (blend(fb, i, pixel.scale(px, (opacity * f : F32))), (layer, mask))

def comp.pixel.layer(got: Array<U32> & U32, fb: Array<U32>, mask: Array<U32>, +i: U32, +opacity: F32, +mode: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  (layer, px) = got
  comp.pixel.mask(comp.factor(mask, i, mode), fb, layer, i, opacity, px)

def comp.pixel.mask.at(got: Array<U32> & F32, fb: Array<U32>, layer: Array<U32>, +i: U32, +opacity: F32, +px: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  (mask, f) = got
  (blend(fb, i, pixel.scale(px, (opacity * f : F32))), (layer, mask))

def comp.pixel.layer.at(got: Array<U32> & U32, fb: Array<U32>, mask: Array<U32>, +i: U32, +j: U32, +opacity: F32, +mode: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  (layer, px) = got
  comp.pixel.mask.at(comp.factor(mask, j, mode), fb, layer, i, opacity, px)

# One pixel: the layer's pixel (index j in the layer and mask) scaled by opacity
# and the mask, over the frame pixel at index i.
def comp.step2(rest: Array<U32> & Array<U32>, fb: Array<U32>, +i: U32, +j: U32, +opacity: F32, +mode: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  (layer, mask) = rest
  comp.pixel.layer.at(Array.get(U32, layer, j), fb, mask, i, j, opacity, mode)

def comp.step(state: Array<U32> & (Array<U32> & Array<U32>), +i: U32, +j: U32, +opacity: F32, +mode: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  (fb, rest) = state
  comp.step2(rest, fb, i, j, opacity, mode)

@unsafe
def comp.row(state: Array<U32> & (Array<U32> & Array<U32>), n: Nat, +i: U32, +j: U32, +opacity: F32, +mode: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  match n:
    case 0n: state
    case 1n+d: comp.row(comp.step(state, i, j, opacity, mode), d, (i + 1 : U32), (j + 1 : U32), opacity, mode)

@unsafe
def comp.rows(state: Array<U32> & (Array<U32> & Array<U32>), n: Nat, +y: U32, +x0: U32, +cols: Nat, +ft: Target, +lt: Target, +opacity: F32, +mode: U32) -> Array<U32> & (Array<U32> & Array<U32>):
  match n:
    case 0n: state
    case 1n+d: comp.rows(comp.row(state, cols, target.index(ft, x0, y), target.index(lt, x0, y), opacity, mode), d, (y + 1 : U32), x0, cols, ft, lt, opacity, mode)

def comp.finish(state: Array<U32> & (Array<U32> & Array<U32>)) -> Array<U32>:
  (fb, rest) = state
  fb

# The pixel range of a device box within the frame: start and count per axis.
def comp.start(+lo: F32, +limit: U32) -> U32:
  F32.to_u32(U.clamp(F32.floor(lo), 0.0, U32.to_f32(limit)))

def comp.count(+lo: F32, +hi: F32, +limit: U32) -> U32:
  +a = comp.start(lo, limit)
  +b = F32.to_u32(U.clamp(F32.ceil(hi), 0.0, U32.to_f32(limit)))
  U.choose(U32, U32.is_gt(b, a), (b - a : U32), 0)

# A finished layer (and its mask layer, both on the layer target), scaled by
# opacity and the mask, over the frame target across the layer's rectangle.
def comp.layer(fb: Array<U32>, layer: Array<U32>, mask: Array<U32>, +ft: Target, +lt: Target, +opacity: F32, +mode: U32) -> Array<U32>:
  Target{x, y, w, h} = lt
  comp.finish(comp.rows((fb, (layer, mask)), U32.to_nat(h), y, x, U32.to_nat(w), ft, lt, opacity, mode))

# A rendered filter raster, faded by the node's clip, opacity and mask, over the frame.
def rcomp.pixel.mask(got: Array<U32> & F32, fb: Array<U32>, +i: U32, +opacity: F32, c: Img.Color, +limit: F32) -> Array<U32> & Array<U32>:
  (mask, f) = got
  (blend(fb, i, pixel.pack(c, (limit * opacity * f : F32))), mask)

def rcomp.step(state: Array<U32> & Array<U32>, +x: U32, +y: U32, +ft: Target, +lt: Target, +raster: Raster, +clip: Clip, +linear: Bool, +opacity: F32, +mode: U32) -> Array<U32> & Array<U32>:
  (fb, mask) = state
  +p = {Point{(U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32)} : Point}
  rcomp.pixel.mask(comp.factor(mask, target.index(lt, x, y), mode), fb, target.index(ft, x, y), opacity, raster.color(raster, p, linear), clip.limit(clip, p))

@unsafe
def rcomp.row(state: Array<U32> & Array<U32>, n: Nat, +x: U32, +y: U32, +ft: Target, +lt: Target, +raster: Raster, +clip: Clip, +linear: Bool, +opacity: F32, +mode: U32) -> Array<U32> & Array<U32>:
  match n:
    case 0n: state
    case 1n+d: rcomp.row(rcomp.step(state, x, y, ft, lt, raster, clip, linear, opacity, mode), d, (x + 1 : U32), y, ft, lt, raster, clip, linear, opacity, mode)

@unsafe
def rcomp.rows(state: Array<U32> & Array<U32>, n: Nat, +y: U32, +x0: U32, +cols: Nat, +ft: Target, +lt: Target, +raster: Raster, +clip: Clip, +linear: Bool, +opacity: F32, +mode: U32) -> Array<U32> & Array<U32>:
  match n:
    case 0n: state
    case 1n+d: rcomp.rows(rcomp.row(state, cols, x0, y, ft, lt, raster, clip, linear, opacity, mode), d, (y + 1 : U32), x0, cols, ft, lt, raster, clip, linear, opacity, mode)

def rcomp.finish(state: Array<U32> & Array<U32>) -> Array<U32>:
  (fb, mask) = state
  fb

# A rendered filter raster over the frame target across the layer target's
# rectangle, faded by the node's clip, opacity and mask (a layer on lt).
def comp.raster(fb: Array<U32>, mask: Array<U32>, +raster: Raster, +clip: Clip, +ft: Target, +lt: Target, +linear: Bool, +opacity: F32, +mode: U32) -> Array<U32>:
  Target{x, y, w, h} = lt
  rcomp.finish(rcomp.rows((fb, mask), U32.to_nat(h), y, x, U32.to_nat(w), ft, lt, raster, clip, linear, opacity, mode))

def filter.raster(effect: FilterEffect) -> Raster:
  match effect:
    case NoFilter{}: raster.empty()
    case FilterSpec{region, units, viewport, attrs, primitives}: raster.empty()
    case FilterImage{raster}: raster

# ---- nodes ----

# Paint a list of scenes onto fb, back to front. A node is direct when it has
# no opacity, mask or rendered filter: fill, stroke and markers in paint order,
# then its children, all limited by the enclosing clips plus its own. Otherwise
# the same content goes into a fresh layer (a copy of the node without those
# three) and the layer, or the filter raster, is composited within the node's
# coverage box; a mask is a layer painted from the mask nodes.
@unsafe
# A scene with an effect, a mask or partial opacity is painted into a layer
# of its own first (the scene without those, over a fresh layer), then
# composited; a filtered scene's raster stands in for the layer.
def paint.layered(rendered: Bool, fb: Array<U32>, es: List<&2, Edge>, box: Bounds, inv: Matrix, style: Style, +opacity: F32, kids: List<&2, Scene<Brush>>, id: String, ink: Paint<Brush>, clip: Clip, outline: StrokeMesh, fill: Fill,
  maskNodes: List<&2, Scene<Brush>>, +maskMode: U32, markerNodes: List<&2, Scene<Brush>>, coverage: Bounds, effect: FilterEffect, +t: Target, +lt: Target, +linear: Bool, +clips: List<&2, Clip>,
  again: List<&2, Scene<Brush>> -> Target -> Bool -> List<&2, Clip> -> Array<U32> -> Array<U32>, more: List<&2, Scene<Brush>> -> Target -> Bool -> List<&2, Clip> -> Array<U32> -> Array<U32>) -> Array<U32>:
  match rendered:
    case True{}: comp.raster(fb, again(paint.markers.at(U.choose(U32, U32.is_ne(maskMode, 0), 2, 0), maskNodes))(lt)(U32.is_eq(maskMode, 3))(Nil{})(layer.new(lt)), filter.raster(effect), clip, t, lt, linear, opacity, maskMode)
    case False{}: comp.layer(fb,
      again(Con{Scene{es, box, inv, style, 1.0, kids, id, ink, clip, outline, fill, Nil{}, 0, markerNodes, coverage, NoFilter{}}, Nil{}})(lt)(linear)(clips)(layer.new(lt)),
      more(paint.markers.at(U.choose(U32, U32.is_ne(maskMode, 0), 2, 0), maskNodes))(lt)(U32.is_eq(maskMode, 3))(Nil{})(layer.new(lt)),
      t, lt, opacity, maskMode)

# A scene painted directly: its pieces in paint order, then its children.
def paint.node(direct: Bool, fb: Array<U32>, es: List<&2, Edge>, box: Bounds, +inv: Matrix, +style: Style, +opacity: F32, kids: List<&2, Scene<Brush>>, id: String, ink: Paint<Brush>, clip: Clip, outline: StrokeMesh, fill: Fill,
  maskNodes: List<&2, Scene<Brush>>, +maskMode: U32, markerNodes: List<&2, Scene<Brush>>, coverage: Bounds, +effect: FilterEffect, +t: Target, +linear: Bool, +clips: List<&2, Clip>, +inner: List<&2, Clip>, +lt: Target,
  again: List<&2, Scene<Brush>> -> Target -> Bool -> List<&2, Clip> -> Array<U32> -> Array<U32>, more: List<&2, Scene<Brush>> -> Target -> Bool -> List<&2, Clip> -> Array<U32> -> Array<U32>) -> Array<U32>:
  match direct:
    case True{}: again(kids)(t)(linear)(inner)(paint.pieces(paint.order.of(style), fb, style.fills(style), style.strokes(style), ink, inv, outline, fill, fbm => more(markerNodes)(t)(linear)(inner)(fbm), linear, inner, t))
    case False{}: paint.layered(filter.rendered(effect), fb, es, box, inv, style, opacity, kids, id, ink, clip, outline, fill, maskNodes, maskMode, markerNodes, coverage, effect, t, lt, linear, clips, again, more)

@unsafe
def paint.scenes(fb: Array<U32>, xs: List<&2, Scene<Brush>>, +t: Target, +linear: Bool, +clips: List<&2, Clip>) -> Array<U32>:
  match xs:
    case Nil{}: fb
    case Con{Scene{es, box, inv, style, opacity, kids, id, ink, clip, outline, fill, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      +cl = clip
      +eff = effect
      +mm = maskMode
      +op = opacity
      +cov = coverage
      paint.scenes(paint.node(F32.is_ge(op, 1.0) && U32.is_eq(mm, 0) && Bool.not(filter.rendered(eff)), fb, es, box, inv, style, op, kids, id, ink, cl, outline, fill, maskNodes, mm, markerNodes, cov, eff, t, linear, clips, paint.clips(cl, clips), target.within(t, cov),
        nodes => tt => lin => cls => fbx => paint.scenes(fbx, nodes, tt, lin, cls), nodes => tt => lin => cls => fbx => paint.scenes(fbx, nodes, tt, lin, cls)), rest, t, linear, clips)

# The whole document at w by h device pixels, packed premultiplied RGBA.
def paint.frame(scene: List<&2, Scene<Brush>>, +w: U32, +h: U32, +aa: U32) -> Array<U32>:
  paint.scenes(layer.new(Target{0, 0, w, h}), cover.scenes(prepare.scenes(scene, identity(), aa), frame(w, h), cover.sub(aa), False{}), Target{0, 0, w, h}, False{}, Nil{})

# ---- packed output ----

def pack.got(got: Array<U32> & U32, +j: U32) -> Array<U32>:
  (fb, px) = got
  Array.set(U32, fb, j, pixel.white(px))

# Every pixel over white, in place, as the 0xRRGGBB the outputs use.
@unsafe
def pack.loop(fb: Array<U32>, n: Nat, +j: U32) -> Array<U32>:
  match n:
    case 0n: fb
    case 1n+d: pack.loop(pack.got(Array.get(U32, fb, j), j), d, (j + 1 : U32))

# The document as packed 0xRRGGBB pixels over white, row-major, w * h entries.
def paint.packed(scene: List<&2, Scene<Brush>>, +w: U32, +h: U32, +aa: U32) -> Array<U32>:
  pack.loop(paint.frame(scene, w, h, aa), U32.to_nat((w * h : U32)), 0)

# Threads an array through a continuation after one read.
def packed.then(-R: Type, got: Array<U32> & U32, next: Array<U32> -> U32 -> R) -> R:
  (a, v) = got
  next(a)(v)

# The window image: a quadtree over a 2^depth square, read from the packed pixels.
@unsafe
def image.of(a: Array<U32>, depth: Nat, +x: U32, +y: U32, +side: U32, next: Array<U32> -> Image -> Image) -> Image:
  match depth:
    case 0n: packed.then(Image, Array.get(U32, a, (y * side + x : U32)), a1 => v => next(a1)(Pix{v}))
    case 1n+d:
      +dd = d
      +half = U32.shln(1, dd)
      image.of(a, dd, x, y, side, a1 => ia => image.of(a1, dd, (x + half : U32), y, side, a2 => ib => image.of(a2, dd, x, (y + half : U32), side,
        a3 => ic => image.of(a3, dd, (x + half : U32), (y + half : U32), side, a4 => id => next(a4)(Qua{ia, ib, ic, id})))))

def image(+depth: Nat, x: U32, y: U32, scene: List<&2, Scene<Brush>>, +aa: U32) -> Image:
  +side = U32.shln(1, depth)
  image.of(paint.packed(scene, side, side, aa), depth, 0, 0, side, a => im => im)

@unsafe
def ppm.cols(a: Array<U32>, n: Nat, +j: U32, next: Array<U32> -> String -> String) -> String:
  match n:
    case 0n: next(a)("")
    case 1n+d: packed.then(String, Array.get(U32, a, j), a1 => v => ppm.cols(a1, d, (j + 1 : U32), a2 => rest => next(a2)(pixel.ppm(v) ++ rest)))

@unsafe
def ppm.rows(a: Array<U32>, n: Nat, +y: U32, +w: U32, next: Array<U32> -> String -> String) -> String:
  match n:
    case 0n: next(a)("")
    case 1n+d: ppm.cols(a, U32.to_nat(w), (y * w : U32), a1 => row => ppm.rows(a1, d, (y + 1 : U32), w, a2 => rest => next(a2)(row ++ rest)))

def ppm(+w: U32, +h: U32, scene: List<&2, Scene<Brush>>, +aa: U32) -> String:
  "P3\n" ++ U32.show(w) ++ " " ++ U32.show(h) ++ "\n255\n" ++ ppm.rows(paint.packed(scene, w, h, aa), U32.to_nat(h), 0, w, a => text => text)

type Pick is Data:
  Pick{found: Bool, id: String, inverse: Matrix}

def pick.prefer(+a: Pick, b: Pick) -> Pick:
  Pick{found, id, inv} = a
  U.choose(Pick, found, a, b)

def pick.alpha(c: Img.Color) -> Bool:
  Img.Color{r, g, b, a} = c
  F32.is_gt(a, 0.0)

def pick.node(c: Img.Color, id: String, inv: Matrix) -> Pick:
  U.choose(Pick, pick.alpha(c), Pick{True{}, id, inv}, Pick{False{}, "", identity()})

def pick.instance(+hit: Pick, id: String, inv: Matrix) -> Pick:
  Pick{found, target, local} = hit
  U.choose(Pick, found && U.string.equal(target, ""), Pick{found, id, inv}, hit)

def pick(+scenes: List<&2, Scene<Brush>>, +p: Point) -> Pick:
  match scenes:
    case Nil{}: Pick{False{}, "", identity()}
    case Con{Scene{es, box, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect}, rest}:
      node = {Scene{es, box, inv, style, opacity, kids, id, ink, mask, outline, fillTree, maskNodes, maskMode, markerNodes, coverage, effect} : Scene<Brush>}
      pick.prefer(pick(rest, p), U.branch(Pick, bounds.inside(coverage, p, 0.01) && clip.inside(mask, p) && F32.is_gt(mask.factor(maskMode, _ => sample(maskNodes, p, p, Img.clear(), U32.is_eq(maskMode, 3), 1.0)), 0.0), _ => pick.prefer(pick.instance(pick(kids, p), id, inv),
        pick.node(scene.local(node, p, p, False{}, sample(markerNodes, p, p, Img.clear(), False{}, 1.0), nodes => q => center => sample(nodes, q, center, Img.clear(), False{}, 1.0), nodes => q => center => sample(nodes, q, center, Img.clear(), False{}, 1.0), 1.0), id, inv)), _ => Pick{False{}, "", identity()}))
