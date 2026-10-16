# Analytic coverage: line lists in pixel space are scan-converted with a winding
# count on a few sub-scanlines per row (exact span extents in x, so the fill
# rule holds even where contours overlap), and the result is a sparse quadtree
# mask.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U

# A directed line in pixel coordinates of the target grid.
type CovLine is Data:
  CovLine{x0: F32, y0: F32, x1: F32, y1: F32}

# Coverage over a power-of-two square: uniform cells collapse to one leaf.
type CovTree is Data:
  CovFlat{value: F32}
  CovQuad{a: CovTree, b: CovTree, c: CovTree, d: CovTree}

# A run of cells [x0, x1) of one nonzero coverage value in a row.
type Run is Data:
  Run{x0: U32, x1: U32, value: F32}

# A mask's coverage: rows of runs (top first, ascending runs), which a fill is
# painted from directly, or the tree, which clip masks and sampled tiles need
# for block and pixel queries.
type CovData is Data:
  CovRows{rows: List<&2, List<&2, Run>>}
  CovTreed{tree: CovTree}

# A mask placed at pixel (x, y) of its grid, size = 2^depth cells on a side.
# w by h cells of it hold coverage; size = 2^depth is the tree's side.
type CovMask is Data:
  CovMask{x: U32, y: U32, w: U32, h: U32, size: U32, depth: Nat, data: CovData, present: Bool}

def mask.none() -> CovMask:
  CovMask{0, 0, 0, 0, 0, 0n, CovTreed{CovFlat{0.0}}, False{}}

# Coverage of a cell from rows of runs; a slow path for masks built without a tree.
def runs.at(rs: List<&2, Run>, +x: U32) -> F32:
  match rs:
    case Nil{}: 0.0
    case Con{Run{a, b, v}, rest}:
      +aa = a
      +bb = b
      +vv = v
      U.choose(F32, U32.is_ge(x, aa) && U32.is_lt(x, bb), vv, runs.at(rest, x))

def rows.at(rows: List<&2, List<&2, Run>>, +y: U32, +x: U32) -> F32:
  match rows:
    case Nil{}: 0.0
    case Con{r, rest}: U.choose(F32, U32.is_eq(y, 0), runs.at(r, x), rows.at(rest, (y - 1 : U32), x))

def mask.present(+m: CovMask) -> Bool:
  CovMask{x, y, w, h, size, depth, tree, present} = m
  present

@unsafe
def tree.at(t: CovTree, +half: U32, +x: U32, +y: U32) -> F32:
  match t:
    case CovFlat{v}: v
    case CovQuad{a, b, c, d}:
      +left = U32.is_lt(x, half)
      +top = U32.is_lt(y, half)
      +xx = U.choose(U32, left, x, (x - half : U32))
      +yy = U.choose(U32, top, y, (y - half : U32))
      +next = U32.div(half, 2)
      tree.at(U.choose(CovTree, top, U.choose(CovTree, left, a, b), U.choose(CovTree, left, c, d)), next, xx, yy)

def data.at(d: CovData, +half: U32, +x: U32, +y: U32) -> F32:
  match d:
    case CovTreed{t}: tree.at(t, half, x, y)
    case CovRows{rows}: rows.at(rows, y, x)

def mask.at.in(outside: Bool, d: CovData, +half: U32, +x: U32, +y: U32) -> F32:
  match outside:
    case True{}: 0.0
    case False{}: data.at(d, half, x, y)

# Coverage of the pixel containing (px, py), in grid pixel coordinates; the
# reads branch through matches, not lambdas, since they run once per pixel.
def mask.at(+m: CovMask, +px: F32, +py: F32) -> F32:
  CovMask{x, y, w, h, size, depth, data, present} = m
  +sizeDup = size
  +yDup = y
  +xDup = x
  +fx = F32.floor(px)
  +fy = F32.floor(py)
  +ix = (F32.to_u32(U.max(fx, 0.0)) - xDup : U32)
  +iy = (F32.to_u32(U.max(fy, 0.0)) - yDup : U32)
  mask.at.in(F32.is_lt(fx, U32.to_f32(xDup)) || F32.is_lt(fy, U32.to_f32(yDup)) || U32.is_ge(ix, sizeDup) || U32.is_ge(iy, sizeDup), data, U32.div(sizeDup, 2), ix, iy)

# Coverage over the cell rectangle [x0, x1) by [y0, y1) of a node's square at
# (nx, ny) of side size, when every cell in it holds the same value; -1 otherwise.
# acc is 2 before any cell is seen, -1 once cells disagree, else the value so far.
def tree.same.as(+v: F32, +u: F32) -> F32:
  U.choose(F32, F32.is_gt(v, 1.5), u, U.choose(F32, F32.is_lt(v, 0.0) || F32.is_lt(u, 0.0) || Bool.not(F32.is_eq(v, u)), F32.neg(1.0), v))

def tree.overlaps(+nx: U32, +ny: U32, +size: U32, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> Bool:
  U32.is_lt(nx, x1) && U32.is_lt(x0, (nx + size : U32)) && U32.is_lt(ny, y1) && U32.is_lt(y0, (ny + size : U32))

@unsafe
def tree.uniform(t: CovTree, +nx: U32, +ny: U32, +size: U32, +x0: U32, +y0: U32, +x1: U32, +y1: U32, +acc: F32) -> F32:
  match t:
    case CovFlat{v}: U.choose(F32, tree.overlaps(nx, ny, size, x0, y0, x1, y1), tree.same.as(acc, v), acc)
    case CovQuad{a, b, c, d}:
      +half = U32.div(size, 2)
      U.branch(F32, Bool.not(tree.overlaps(nx, ny, size, x0, y0, x1, y1)) || F32.is_lt(acc, F32.neg(0.5)), _ => acc,
        _ => tree.uniform(d, (nx + half : U32), (ny + half : U32), half, x0, y0, x1, y1,
          tree.uniform(c, nx, (ny + half : U32), half, x0, y0, x1, y1,
            tree.uniform(b, (nx + half : U32), ny, half, x0, y0, x1, y1,
              tree.uniform(a, nx, ny, half, x0, y0, x1, y1, acc)))))

# The mask's coverage over the grid rectangle [x0, x1) by [y0, y1) when it is
# uniform (2 means "unvisited", so an empty rectangle reads as uniform 0), else -1.
# The uniform value of runs over the columns [x0, x1): a run covering them
# all gives its value, none touching them gives 0, anything else -1.
def runs.over(rs: List<&2, Run>, +x0: U32, +x1: U32, +acc: F32) -> F32:
  match rs:
    case Nil{}: U.choose(F32, F32.is_gt(acc, 1.5), 0.0, acc)
    case Con{Run{a, b, v}, rest}:
      +aa = a
      +bb = b
      +vv = v
      +overlaps = U32.is_lt(aa, x1) && U32.is_lt(x0, bb)
      +covers = U32.is_le(aa, x0) && U32.is_ge(bb, x1)
      runs.over(rest, x0, x1, U.choose(F32, Bool.not(overlaps), acc, U.choose(F32, covers && F32.is_gt(acc, 1.5), vv, F32.neg(1.0))))

# The uniform value of rows over the cell rectangle [x0, x1) by [y0, y1) in
# grid cells relative to the mask; rows past the list are empty.
@unsafe
def rows.over(rows: List<&2, List<&2, Run>>, +y: U32, +x0: U32, +y0: U32, +x1: U32, +y1: U32, +acc: F32) -> F32:
  match rows:
    case Nil{}: U.choose(F32, U32.is_lt(y, y1), tree.same.as(acc, 0.0), acc)
    case Con{r, rest}:
      U.choose(F32, U32.is_ge(y, y1) || F32.is_lt(acc, F32.neg(0.5)), acc,
        rows.over(rest, (y + 1 : U32), x0, y0, x1, y1, U.choose(F32, U32.is_lt(y, y0), acc, tree.same.as(acc, runs.over(r, x0, x1, 2.0)))))

def data.uniform(d: CovData, +mx: U32, +my: U32, +sz: U32, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  match d:
    case CovTreed{t}: tree.uniform(t, mx, my, sz, x0, y0, x1, y1, 2.0)
    case CovRows{rows}: rows.over(rows, 0, (x0 - mx : U32), (y0 - my : U32), (x1 - mx : U32), (y1 - my : U32), 2.0)

def mask.uniform.in(+m: CovMask, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  CovMask{x, y, w, h, size, depth, data, present} = m
  +mx = x
  +my = y
  +sz = size
  +outside = U32.is_lt(x0, mx) || U32.is_lt(y0, my) || U32.is_gt(x1, (mx + sz : U32)) || U32.is_gt(y1, (my + sz : U32))
  +inside = data.uniform(data, mx, my, sz, U.max.u32(x0, mx), U.max.u32(y0, my), U.min.u32(x1, (mx + sz : U32)), U.min.u32(y1, (my + sz : U32)))
  +v = U.choose(F32, F32.is_gt(inside, 1.5), 0.0, inside)
  U.choose(F32, outside && F32.is_gt(v, 0.0), F32.neg(1.0), v)

def mask.uniform(+m: CovMask, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> F32:
  U.choose(F32, U32.is_ge(x0, x1) || U32.is_ge(y0, y1), 0.0, mask.uniform.in(m, x0, y0, x1, y1))

# ---- clipping to the grid's horizontal extent ----

def line.split(l: CovLine, +at: F32) -> List<&2, CovLine>:
  CovLine{x0, y0, x1, y1} = l
  +ax = x0
  +ay = y0
  +bx = x1
  +by = y1
  +t = ((at - ax) / (bx - ax) : F32)
  +my = (ay + (by - ay) * t : F32)
  U.branch(List<&2, CovLine>, (F32.is_lt(ax, at) && F32.is_gt(bx, at)) || (F32.is_gt(ax, at) && F32.is_lt(bx, at)),
    _ => Con{CovLine{ax, ay, at, my}, Con{CovLine{at, my, bx, by}, Nil{}}},
    _ => Con{CovLine{ax, ay, bx, by}, Nil{}})

def lines.append(xs: List<&2, CovLine>, ys: List<&2, CovLine>) -> List<&2, CovLine>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, lines.append(t, ys)}

def lines.split(xs: List<&2, CovLine>, +at: F32) -> List<&2, CovLine>:
  match xs:
    case Nil{}: Nil{}
    case Con{l, rest}: lines.append(line.split(l, at), lines.split(rest, at))

# Pieces left of 0 or right of w become vertical lines on that boundary, which keeps
# the winding of every cell inside [0, w) intact.
def lines.clamp(xs: List<&2, CovLine>, +w: F32, acc: List<&2, CovLine>, +n: U32) -> List<&2, CovLine> & U32:
  match xs:
    case Nil{}: (acc, n)
    case Con{CovLine{x0, y0, x1, y1}, rest}: lines.clamp(rest, w, Con{CovLine{U.clamp(x0, 0.0, w), y0, U.clamp(x1, 0.0, w), y1}, acc}, (n + 1 : U32))

# The clipped lines, in no particular order, with their count.
def lines.clip(xs: List<&2, CovLine>, +w: F32) -> List<&2, CovLine> & U32:
  lines.clamp(lines.split(lines.split(xs, 0.0), w), w, Nil{}, 0)

# One pass over the lines: shift by the mask's origin, split at the grid's
# left and right edges and clamp the pieces to it, counting them. Pieces
# left of 0 or right of w become vertical lines on that edge, which keeps
# the winding of every cell inside intact.
def line.push(+ax: F32, +ay: F32, +bx: F32, +by: F32, +w: F32, st: List<&2, CovLine> & U32) -> List<&2, CovLine> & U32:
  (acc, n) = st
  (Con{CovLine{U.clamp(ax, 0.0, w), ay, U.clamp(bx, 0.0, w), by}, acc}, (n + 1 : U32))

# Split at x = at when the line crosses it, pushing the piece before the
# crossing; the rest continues.
def line.cut.at(cross: Bool, +ax: F32, +ay: F32, +bx: F32, +by: F32, +at: F32, +w: F32, st: List<&2, CovLine> & U32) -> (List<&2, CovLine> & U32) & (F32 & F32):
  match cross:
    case False{}: (st, (ax, ay))
    case True{}:
      +my = (ay + (by - ay) * ((at - ax) / (bx - ax)) : F32)
      (line.push(ax, ay, at, my, w, st), (at, my))

def line.cut(+ax: F32, +ay: F32, +bx: F32, +by: F32, +at: F32, +w: F32, st: List<&2, CovLine> & U32) -> (List<&2, CovLine> & U32) & (F32 & F32):
  line.cut.at((F32.is_lt(ax, at) && F32.is_gt(bx, at)) || (F32.is_gt(ax, at) && F32.is_lt(bx, at)), ax, ay, bx, by, at, w, st)

def line.prepare.last(got: (List<&2, CovLine> & U32) & (F32 & F32), +bx: F32, +by: F32, +w: F32) -> List<&2, CovLine> & U32:
  (st, (ax, ay)) = got
  line.push(ax, ay, bx, by, w, st)

def line.prepare.right(got: (List<&2, CovLine> & U32) & (F32 & F32), +bx: F32, +by: F32, +w: F32) -> List<&2, CovLine> & U32:
  (st, (ax, ay)) = got
  line.prepare.last(line.cut(ax, ay, bx, by, w, w, st), bx, by, w)

def lines.prepare(xs: List<&2, CovLine>, +dx: F32, +dy: F32, +w: F32, st: List<&2, CovLine> & U32) -> List<&2, CovLine> & U32:
  match xs:
    case Nil{}: st
    case Con{CovLine{x0, y0, x1, y1}, rest}:
      +ax = (x0 - dx : F32)
      +bx = (x1 - dx : F32)
      +by = (y1 - dy : F32)
      lines.prepare(rest, dx, dy, w, line.prepare.right(line.cut(ax, (y0 - dy : F32), bx, by, 0.0, w, st), bx, by, w))

# ---- sub-scanline winding ----
# Each pixel row is sampled on `sub` horizontal scanlines. The lines reaching
# a scanline are kept in a list sorted by their x on it: one pass per
# scanline walks that list with a winding count, emitting the inside spans as
# events, and at the same time places every line that still reaches the next
# scanline into the next list at its x there (lines keep their order almost
# everywhere, so the insertion is a prepend). Lines start when the sorted
# pending list reaches their top and end when the next scanline passes their
# bottom. Coverage is exact in x and quantized to 1/sub in y, overlapping
# contours follow the fill rule exactly, and nothing is sorted from scratch.

def line.top(+l: CovLine) -> F32:
  CovLine{x0, y0, x1, y1} = l
  U.min(y0, y1)

# A line on the scanlines: x at the current one is cur; slope is dx/dy.
type Act is Data:
  Act{cur: F32, x0: F32, y0: F32, slope: F32, bottom: F32, dir: F32}

# Insert into a list descending by cur, after the elements not below it.
type Ins is Data:
  Placed{list: List<&2, Act>}
  Passed{h: Act, t: List<&2, Act>, a: Act}

def act.ins.pick(hit: Bool, a: Act, h: Act, t: List<&2, Act>) -> Ins:
  match hit:
    case True{}: Placed{Con{a, Con{h, t}}}
    case False{}: Passed{h, t, a}

@unsafe
def act.insert.go(i: Ins) -> List<&2, Act>:
  match i:
    case Placed{list}: list
    case Passed{h, t, a}:
      match t:
        case Nil{}: Con{h, Con{a, Nil{}}}
        case Con{Act{c2, x2, y2, s2, b2, d2}, t2}:
          Act{ac, ax, ay, as, ab, ad} = a
          +cc = c2
          +acc = ac
          Con{h, act.insert.go(act.ins.pick(F32.is_ge(acc, cc), Act{acc, ax, ay, as, ab, ad}, Act{cc, x2, y2, s2, b2, d2}, t2))}

def act.insert(a: Act, xs: List<&2, Act>) -> List<&2, Act>:
  Act{ac, ax, ay, as, ab, ad} = a
  match xs:
    case Nil{}: Con{Act{ac, ax, ay, as, ab, ad}, Nil{}}
    case Con{Act{c2, x2, y2, s2, b2, d2}, t2}:
      +cc = c2
      +acc = ac
      act.insert.go(act.ins.pick(F32.is_ge(acc, cc), Act{acc, ax, ay, as, ab, ad}, Act{cc, x2, y2, s2, b2, d2}, t2))

def act.reverse(xs: List<&2, Act>, acc: List<&2, Act>) -> List<&2, Act>:
  match xs:
    case Nil{}: acc
    case Con{a, rest}: act.reverse(rest, Con{a, acc})

# The line as it will stand on scanline sy, placed into the descending list.
def act.keep(keep: Bool, +x0: F32, +y0: F32, +slope: F32, +bottom: F32, +dir: F32, +sy: F32, acc: List<&2, Act>) -> List<&2, Act>:
  match keep:
    case False{}: acc
    case True{}: act.insert(Act{(x0 + (sy - y0) * slope : F32), x0, y0, slope, bottom, dir}, acc)

# A line covers [top, bottom) so a shared vertex counts once; a horizontal line
# never crosses. Lines whose bottom the scanline has passed are dropped.
def act.add(l: CovLine, +sy: F32, acc: List<&2, Act>) -> List<&2, Act>:
  CovLine{x0, y0, x1, y1} = l
  +ax = x0
  +ay = y0
  +bx = x1
  +by = y1
  +up = F32.is_lt(ay, by)
  +bottom = U.max(ay, by)
  act.keep(F32.is_lt(sy, bottom) && Bool.not(F32.is_eq(ay, by)), ax, ay, ((bx - ax) / (by - ay) : F32), bottom, U.choose(F32, up, 1.0, F32.neg(1.0)), sy, acc)

# Lines from the sorted pending list whose top the scanline sy has reached.
type Take is Data:
  Take{done: Bool, pending: List<&2, CovLine>, acc: List<&2, Act>}

def take.pick(hit: Bool, l: CovLine, rest: List<&2, CovLine>, +sy: F32, acc: List<&2, Act>) -> Take:
  match hit:
    case True{}: Take{False{}, rest, act.add(l, sy, acc)}
    case False{}: Take{True{}, Con{l, rest}, acc}

@unsafe
def take.go(t: Take, +sy: F32) -> Take:
  match t:
    case Take{done, pending, acc}:
      match done:
        case True{}: Take{True{}, pending, acc}
        case False{}:
          match pending:
            case Nil{}: Take{True{}, Nil{}, acc}
            case Con{l, rest}:
              +ll = l
              take.go(take.pick(F32.is_le(line.top(ll), sy), ll, rest, sy, acc), sy)

# ---- span events ----
# A span [xa, xb) of weight w touches its two end cells directly (their partial
# overlap) and every cell between them in full. An event carries a direct
# contribution to one cell and a delta that applies to that cell and all cells
# to its right: +w at the first interior cell and -w at the last cell, so a
# span costs three events however wide it is. Events are kept in descending
# cell order (a walk goes left to right and prepends).

type CovEv is Data:
  CovEv{cell: U32, direct: F32, delta: F32}

def ev.push.if(skip: Bool, +cell: U32, +direct: F32, +delta: F32, acc: List<&2, CovEv>) -> List<&2, CovEv>:
  match skip:
    case True{}: acc
    case False{}: Con{CovEv{cell, direct, delta}, acc}

def ev.push(+cell: U32, +direct: F32, +delta: F32, acc: List<&2, CovEv>) -> List<&2, CovEv>:
  ev.push.if(F32.is_eq(direct, 0.0) && F32.is_eq(delta, 0.0), cell, direct, delta, acc)

def span.events.cells(one: Bool, +ia: U32, +ib: U32, +xa: F32, +xb: F32, +w: F32, acc: List<&2, CovEv>) -> List<&2, CovEv>:
  match one:
    case True{}: ev.push(ia, ((xb - xa) * w : F32), 0.0, acc)
    case False{}: ev.push(ib, ((xb - U32.to_f32(ib)) * w : F32), F32.neg(w), ev.push((ia + 1 : U32), 0.0, w, ev.push(ia, ((U32.to_f32(ia) + 1.0 - xa) * w : F32), 0.0, acc)))

# Events of the span [xa, xb) when it is inside; both ends lie within [0, width].
def span.events(inside: Bool, +xa: F32, +xb: F32, +w: F32, acc: List<&2, CovEv>) -> List<&2, CovEv>:
  match inside:
    case False{}: acc
    case True{}:
      +ia = F32.to_u32(F32.floor(xa))
      +ib = F32.to_u32(F32.floor(xb))
      span.events.cells(U32.is_ge(ia, ib), ia, ib, xa, xb, w, acc)

def winding.inside(+wind: F32, +even: Bool) -> Bool:
  U.choose(Bool, even, F32.is_gt(F32.abs((wind - 2.0 * F32.floor((wind / 2.0 : F32)) : F32)), 0.5), F32.is_gt(F32.abs(wind), 0.5))

# One scanline: walk the ascending list, emit the inside spans' events, and
# build the descending list for the next scanline sy2.
type Step is Data:
  Step{events: List<&2, CovEv>, next: List<&2, Act>}

@unsafe
def step(xs: List<&2, Act>, +sy2: F32, +wind: F32, +last: F32, +even: Bool, +weight: F32, evs: List<&2, CovEv>, acc: List<&2, Act>) -> Step:
  match xs:
    case Nil{}: Step{evs, acc}
    case Con{Act{cur, x0, y0, slope, bottom, dir}, rest}:
      +c = cur
      +d = dir
      +b = bottom
      step(rest, sy2, (wind + d : F32), c, even, weight, span.events(winding.inside(wind, even), last, c, weight, evs),
        act.keep(F32.is_lt(sy2, b), x0, y0, slope, b, d, sy2, acc))

# Merge two descending event lists, larger cells first.
type EvOrder is Data:
  EvOrder{first: CovEv, rest: List<&2, CovEv>, other: List<&2, CovEv>}

def ev.cell(+e: CovEv) -> U32:
  CovEv{cell, direct, delta} = e
  cell

def ev.order.pick(hit: Bool, x: CovEv, xt: List<&2, CovEv>, y: CovEv, yt: List<&2, CovEv>) -> EvOrder:
  match hit:
    case True{}: EvOrder{x, xt, Con{y, yt}}
    case False{}: EvOrder{y, yt, Con{x, xt}}

def ev.order(x: CovEv, xt: List<&2, CovEv>, y: CovEv, yt: List<&2, CovEv>) -> EvOrder:
  +xx = x
  +yy = y
  ev.order.pick(U32.is_ge(ev.cell(xx), ev.cell(yy)), xx, xt, yy, yt)

@unsafe
def ev.merge.go(o: EvOrder) -> List<&2, CovEv>:
  match o:
    case EvOrder{first, rest, other}:
      match rest:
        case Nil{}: Con{first, other}
        case Con{x, xt}:
          match other:
            case Nil{}: Con{first, Con{x, xt}}
            case Con{y, yt}: Con{first, ev.merge.go(ev.order(x, xt, y, yt))}

def ev.merge(xs: List<&2, CovEv>, ys: List<&2, CovEv>) -> List<&2, CovEv>:
  match xs:
    case Nil{}: ys
    case Con{x, xt}:
      match ys:
        case Nil{}: Con{x, xt}
        case Con{y, yt}: ev.merge.go(ev.order(x, xt, y, yt))

# ---- rows of runs ----
# A row's events, swept from the right, become runs [x0, x1) of one nonzero
# coverage value in ascending order; cells in no run are zero. Sweeping from
# the right, the coverage of a cell is the negated sum of the deltas to its
# right (all deltas of a row sum to zero) plus its direct contributions.

# Sums of a weight's multiples cancel exactly for power-of-two sub counts and
# to within rounding otherwise; noise below a millionth reads as empty.
def run.snap(+v: F32) -> F32:
  U.choose(F32, F32.is_lt(F32.abs(v), 0.000001), 0.0, v)

def runs.emit.join(join: Bool, +x0: U32, +x1: U32, +v: F32, +b: U32, head: Run, rest: List<&2, Run>) -> List<&2, Run>:
  match join:
    case True{}: Con{Run{x0, b, v}, rest}
    case False{}: Con{Run{x0, x1, v}, Con{head, rest}}

def runs.emit.some(skip: Bool, +x0: U32, +x1: U32, +v: F32, acc: List<&2, Run>) -> List<&2, Run>:
  match skip:
    case True{}: acc
    case False{}:
      match acc:
        case Nil{}: Con{Run{x0, x1, v}, Nil{}}
        case Con{Run{a, b, u}, rest}:
          +aa = a
          +bb = b
          +uu = u
          runs.emit.join(U32.is_eq(aa, x1) && F32.is_eq(uu, v), x0, x1, v, bb, Run{aa, bb, uu}, rest)

# Prepend the run [x0, x1) of value v, extending the head when they meet with one value.
def runs.emit(+x0: U32, +x1: U32, +v: F32, acc: List<&2, Run>) -> List<&2, Run>:
  runs.emit.some(U32.is_ge(x0, x1) || F32.is_eq(v, 0.0), x0, x1, v, acc)

# Sweep state: sum is the total delta at cells >= upper, the runs so far cover
# cells >= upper, and the open group collects the events of cell c.
type Sweep is Data:
  Sweep{sum: F32, upper: U32, c: U32, direct: F32, delta: F32, acc: List<&2, Run>}

# Close the group at c: the gap (c, upper) holds -sum, cell c adds its directs.
def sweep.flush(+sum: F32, +upper: U32, +c: U32, +direct: F32, acc: List<&2, Run>) -> List<&2, Run>:
  runs.emit(c, (c + 1 : U32), run.snap((direct - sum : F32)), runs.emit((c + 1 : U32), upper, run.snap(F32.neg(sum)), acc))

def sweep.step(same: Bool, +cell: U32, +direct: F32, +delta: F32, +sum: F32, +upper: U32, +c: U32, +dsum: F32, +dlsum: F32, acc: List<&2, Run>) -> Sweep:
  match same:
    case True{}: Sweep{sum, upper, c, (dsum + direct : F32), (dlsum + delta : F32), acc}
    case False{}: Sweep{(sum + dlsum : F32), c, cell, direct, delta, sweep.flush(sum, upper, c, dsum, acc)}

@unsafe
def sweep(st: Sweep, evs: List<&2, CovEv>) -> List<&2, Run>:
  Sweep{sum, upper, c, dsum, dlsum, acc} = st
  match evs:
    case Nil{}: sweep.flush(sum, upper, c, dsum, acc)
    case Con{CovEv{cell, direct, delta}, rest}:
      +cc = c
      +ce = cell
      sweep(sweep.step(U32.is_eq(ce, cc), ce, direct, delta, sum, upper, cc, dsum, dlsum, acc), rest)

# The runs of a row of width w from its descending events.
def row.runs(evs: List<&2, CovEv>, +w: U32) -> List<&2, Run>:
  sweep(Sweep{0.0, w, w, 0.0, 0.0, Nil{}}, evs)

# ---- sorting lines by top ----

type LineOrder is Data:
  LineOrder{first: CovLine, rest: List<&2, CovLine>, other: List<&2, CovLine>}

def lines.order.pick(hit: Bool, x: CovLine, xt: List<&2, CovLine>, y: CovLine, yt: List<&2, CovLine>) -> LineOrder:
  match hit:
    case True{}: LineOrder{x, xt, Con{y, yt}}
    case False{}: LineOrder{y, yt, Con{x, xt}}

def lines.order(x: CovLine, xt: List<&2, CovLine>, y: CovLine, yt: List<&2, CovLine>) -> LineOrder:
  +xx = x
  +yy = y
  lines.order.pick(F32.is_le(line.top(xx), line.top(yy)), xx, xt, yy, yt)

@unsafe
def lines.merge.go(o: LineOrder) -> List<&2, CovLine>:
  match o:
    case LineOrder{first, rest, other}:
      match rest:
        case Nil{}: Con{first, other}
        case Con{x, xt}:
          match other:
            case Nil{}: Con{first, Con{x, xt}}
            case Con{y, yt}: Con{first, lines.merge.go(lines.order(x, xt, y, yt))}

def lines.merge(xs: List<&2, CovLine>, ys: List<&2, CovLine>) -> List<&2, CovLine>:
  match xs:
    case Nil{}: ys
    case Con{x, xt}:
      match ys:
        case Nil{}: Con{x, xt}
        case Con{y, yt}: lines.merge.go(lines.order(x, xt, y, yt))

type LineSplit is Data:
  LineSplit{left: List<&2, CovLine>, right: List<&2, CovLine>}

def lines.deal(xs: List<&2, CovLine>, left: List<&2, CovLine>, right: List<&2, CovLine>) -> LineSplit:
  match xs:
    case Nil{}: LineSplit{left, right}
    case Con{x, Nil{}}: LineSplit{Con{x, left}, right}
    case Con{x, Con{y, rest}}: lines.deal(rest, Con{x, left}, Con{y, right})

# Merge sort by top.
@unsafe
def lines.sort.go(s: LineSplit) -> List<&2, CovLine>:
  match s:
    case LineSplit{left, right}:
      match right:
        case Nil{}: left
        case Con{y, yt}: lines.merge(lines.sort.go(lines.deal(left, Nil{}, Nil{})), lines.sort.go(lines.deal(Con{y, yt}, Nil{}, Nil{})))

def lines.sort(xs: List<&2, CovLine>) -> List<&2, CovLine>:
  lines.sort.go(lines.deal(xs, Nil{}, Nil{}))

# ---- the scan ----
# The active list stands at the current scanline; each step walks it, merges
# the scanline's events into the row's, and readies the list for the next
# scanline, taking the lines that start before it. The rows list is built top
# row last (prepended) and reversed at the end.

type Subs is Data:
  Subs{active: List<&2, Act>, pending: List<&2, CovLine>, events: List<&2, CovEv>}

def subs.done(t: Take, events: List<&2, CovEv>) -> Subs:
  Take{done, pending, acc} = t
  Subs{act.reverse(acc, Nil{}), pending, events}

def subs.after(s: Step, pending: List<&2, CovLine>, +sy2: F32, events: List<&2, CovEv>) -> Subs:
  Step{evs, acc} = s
  subs.done(take.go(Take{False{}, pending, acc}, sy2), ev.merge(evs, events))

def subs.step(st: Subs, +sy: F32, +dy: F32, +even: Bool, +weight: F32) -> Subs:
  Subs{active, pending, events} = st
  +sy2 = (sy + dy : F32)
  subs.after(step(active, sy2, 0.0, 0.0, even, weight, Nil{}, Nil{}), pending, sy2, events)

@unsafe
def scan.subs(st: Subs, n: Nat, +sy: F32, +dy: F32, +even: Bool, +weight: F32) -> Subs:
  match n:
    case 0n: st
    case 1n+d: scan.subs(subs.step(st, sy, dy, even, weight), d, (sy + dy : F32), dy, even, weight)

type Scan is Data:
  Scan{rows: List<&2, List<&2, Run>>, active: List<&2, Act>, pending: List<&2, CovLine>}

def scan.row.done(st: Subs, rows: List<&2, List<&2, Run>>, +w: U32) -> Scan:
  Subs{active, pending, events} = st
  Scan{Con{row.runs(events, w), rows}, active, pending}

def scan.row(st: Scan, +y: U32, +sub: U32, +even: Bool, +w: U32) -> Scan:
  Scan{rows, active, pending} = st
  +dy = (1.0 / U32.to_f32(sub) : F32)
  scan.row.done(scan.subs(Subs{active, pending, Nil{}}, U32.to_nat(sub), (U32.to_f32(y) + dy * 0.5 : F32), dy, even, dy), rows, w)

@unsafe
def scan.rows.go(st: Scan, n: Nat, +y: U32, +sub: U32, +even: Bool, +w: U32) -> Scan:
  match n:
    case 0n: st
    case 1n+d: scan.rows.go(scan.row(st, y, sub, even, w), d, (y + 1 : U32), sub, even, w)

def rows.reverse(rows: List<&2, List<&2, Run>>, acc: List<&2, List<&2, Run>>) -> List<&2, List<&2, Run>>:
  match rows:
    case Nil{}: acc
    case Con{r, rest}: rows.reverse(rest, Con{r, acc})

def scan.done(st: Scan) -> List<&2, List<&2, Run>>:
  Scan{rows, active, pending} = st
  rows.reverse(rows, Nil{})

def scan.start(t: Take) -> Scan:
  Take{done, pending, acc} = t
  Scan{Nil{}, act.reverse(acc, Nil{}), pending}

# The rows of runs (top first) of the lines, sorted by top, over a width by height grid.
def scan.rows(+h: U32, +sub: U32, sorted: List<&2, CovLine>, +even: Bool, +w: U32) -> List<&2, List<&2, Run>>:
  scan.done(scan.rows.go(scan.start(take.go(Take{False{}, sorted, Nil{}}, (0.5 / U32.to_f32(sub) : F32))), U32.to_nat(h), 0, sub, even, w))

@unsafe
def depth.for(+size: U32, +side: U32, +depth: Nat) -> Nat:
  U.branch(Nat, U32.is_ge(side, size), _ => depth, _ => depth.for(size, (side * 2 : U32), 1n+depth))

# ---- exact area scan ----
# When a shape's contours never overlap, the winding number is 0 or +-1
# everywhere and a pixel's coverage is the absolute value of the winding
# integrated over it. That integral is a sum over the lines: a line piece
# inside the row contributes, for each cell it passes through, the area to
# its right within that cell (direct) and its height to every cell further
# right (a delta). The contributions of a row go into a row buffer with two
# slots per cell, which costs writes and no allocation; the runs are then
# read off the touched cells only, right to left, and the buffer is cleared
# behind the read. One pass per row, exact in both axes, nothing sampled. A
# row whose integral exceeds one somewhere reveals an overlap, and the shape
# is scanned again with sub-scanlines; even-odd fills always are.

# A line for the exact scan: x = x0 + (y - y0) * slope over [top, bottom).
type Piece is Data:
  Piece{x0: F32, y0: F32, slope: F32, top: F32, bottom: F32, dir: F32}

def piece.of(l: CovLine) -> Piece:
  CovLine{x0, y0, x1, y1} = l
  +ax = x0
  +ay = y0
  +bx = x1
  +by = y1
  Piece{ax, ay, ((bx - ax) / (by - ay) : F32), U.min(ay, by), U.max(ay, by), U.choose(F32, F32.is_lt(ay, by), 1.0, F32.neg(1.0))}

def piece.bottom(+p: Piece) -> F32:
  Piece{x0, y0, slope, top, bottom, dir} = p
  bottom

# The row buffer: slot 2c holds cell c's direct area and slot 2c + 1 its
# delta; a bitmap marks the touched cells so the read skips empty words;
# lo and hi bound the touched cells (lo > hi when none). Arrays cannot sit
# in a constructor, so the buffer is the tuple ((slots, bitmap), (lo, hi)).

def buf.add.got(got: Array<F32> & F32, +i: U32, +v: F32) -> Array<F32>:
  (a, old) = got
  Array.set(F32, a, i, (old + v : F32))

def buf.add(a: Array<F32>, +i: U32, +v: F32) -> Array<F32>:
  buf.add.got(Array.get(F32, a, i), i, v)

def bits.set.got(got: Array<U32> & U32, +i: U32, +bit: U32) -> Array<U32>:
  (bm, word) = got
  Array.set(U32, bm, i, U32.or(word, bit))

def bits.set(bm: Array<U32>, +c: U32) -> Array<U32>:
  bits.set.got(Array.get(U32, bm, U32.div(c, 32)), U32.div(c, 32), U32.shln(1, U32.to_nat(U32.mod(c, 32))))

# A cut's direct area goes to its cell (dropped at or past the width, which
# lies outside the row) and its delta to the next cell, capped at the width
# so every delta still counts in the sum.
def buf.put(b: (Array<F32> & Array<U32>) & (U32 & U32), +cell: U32, +direct: F32, +delta: F32, +w: U32) -> (Array<F32> & Array<U32>) & (U32 & U32):
  ((a, bm), (lo, hi)) = b
  +c = U.min.u32(cell, w)
  +next = U.min.u32((cell + 1 : U32), w)
  ((buf.add(buf.add(a, (c * 2 : U32), U.choose(F32, U32.is_lt(cell, w), direct, 0.0)), (next * 2 + 1 : U32), delta), bits.set(bits.set(bm, c), next)), (U.min.u32(lo, c), U.max.u32(hi, next)))

def buf.put.if(skip: Bool, b: (Array<F32> & Array<U32>) & (U32 & U32), +cell: U32, +direct: F32, +delta: F32, +w: U32) -> (Array<F32> & Array<U32>) & (U32 & U32):
  match skip:
    case True{}: b
    case False{}: buf.put(b, cell, direct, delta, w)

# The piece of a line between heights ya and yb, from xa to xb, cut at the
# cell boundaries it crosses: each cut of height dy within cell i adds the
# area to its right, dy * (i + 1 - mid x), to cell i and dy to the cells
# beyond. `n` bounds the cuts (the cells crossed plus one); `done` holds once
# a cut reached yb.
@unsafe
def piece.cuts(done: Bool, n: Nat, +xa: F32, +ya: F32, +xb: F32, +yb: F32, +dir: F32, +slope: F32, +w: U32, b: (Array<F32> & Array<U32>) & (U32 & U32)) -> (Array<F32> & Array<U32>) & (U32 & U32):
  match done:
    case True{}: b
    case False{}:
      match n:
        case 0n: b
        case 1n+d:
          +ahead = F32.is_le(xa, xb)
          +i = U.choose(F32, ahead, F32.floor(xa), (F32.ceil(xa) - 1.0 : F32))
          +right = (i + 1.0 : F32)
          +bound = U.choose(F32, ahead, right, i)
          +full = U.choose(Bool, ahead, F32.is_le(xb, bound), F32.is_ge(xb, bound))
          +xc = U.choose(F32, full, xb, bound)
          +yc = U.choose(F32, full, yb, U.choose(F32, F32.is_lt(F32.abs(slope), 0.000001), yb, (ya + (xc - xa) / slope : F32)))
          +dy = (yc - ya : F32)
          piece.cuts(full, d, xc, yc, xb, yb, dir, slope, w,
            buf.put.if(F32.is_eq(dy, 0.0), b, F32.to_u32(U.max(i, 0.0)), (dir * dy * (right - (xa + xc) * 0.5) : F32), (dir * dy : F32), w))

# The contributions of a line piece clipped to the row [y, y + 1).
def piece.events(p: Piece, +y: F32, +w: U32, b: (Array<F32> & Array<U32>) & (U32 & U32)) -> (Array<F32> & Array<U32>) & (U32 & U32):
  Piece{x0, y0, slope, top, bottom, dir} = p
  +xx0 = x0
  +yy0 = y0
  +s = slope
  +ya = U.max(top, y)
  +yb = U.min(bottom, (y + 1.0 : F32))
  +xa = (xx0 + (ya - yy0) * s : F32)
  +xb = (xx0 + (yb - yy0) * s : F32)
  +span = F32.to_u32((F32.abs((F32.floor(xb) - F32.floor(xa) : F32)) + 2.0 : F32))
  piece.cuts(F32.is_le(yb, ya), U32.to_nat(span), xa, ya, xb, yb, dir, s, w, b)

# The pieces still reaching below the row, with the row's buffer filled.

def piece.keep(keep: Bool, p: Piece, active: List<&2, Piece>) -> List<&2, Piece>:
  match keep:
    case True{}: Con{p, active}
    case False{}: active

@unsafe
# The row's pieces all go into the buffer and come back as a list (in any
# order); those the next row no longer reaches are retired afterwards.
def pieces.row(xs: List<&2, Piece>, +y: F32, +w: U32, active: List<&2, Piece>, b: (Array<F32> & Array<U32>) & (U32 & U32)) -> List<&2, Piece> & ((Array<F32> & Array<U32>) & (U32 & U32)):
  match xs:
    case Nil{}: (active, b)
    case Con{p, rest}:
      +pp = p
      pieces.row(rest, y, w, Con{pp, active}, piece.events(pp, y, w, b))

def pieces.retire(xs: List<&2, Piece>, +bottom: F32, acc: List<&2, Piece>) -> List<&2, Piece>:
  match xs:
    case Nil{}: acc
    case Con{p, rest}:
      +pp = p
      pieces.retire(rest, bottom, piece.keep(F32.is_gt(piece.bottom(pp), bottom), pp, acc))

# A piece as a line shifted so the row starts at zero, for the sub-scanline
# scan of a row whose exact areas showed an overlap.
def piece.line(+p: Piece, +y: F32) -> CovLine:
  Piece{x0, y0, slope, top, bottom, dir} = p
  +xx0 = x0
  +yy0 = y0
  +s = slope
  +t = top
  +b = bottom
  +xt = (xx0 + (t - yy0) * s : F32)
  +xb = (xx0 + (b - yy0) * s : F32)
  U.choose(CovLine, F32.is_gt(dir, 0.0), CovLine{xt, (t - y : F32), xb, (b - y : F32)}, CovLine{xb, (b - y : F32), xt, (t - y : F32)})

def pieces.lines(xs: List<&2, Piece>, +y: F32, acc: List<&2, CovLine>) -> List<&2, CovLine>:
  match xs:
    case Nil{}: acc
    case Con{p, rest}: pieces.lines(rest, y, Con{piece.line(p, y), acc})

def line.bottom(+l: CovLine) -> F32:
  CovLine{x0, y0, x1, y1} = l
  U.max(y0, y1)

# ---- lines in arrays, ordered by top row ----
# The lines go into one array of four floats each, and an index array orders
# them by the row their top lies in (a counting sort over the rows), so the
# scan takes lines as its rows reach them without a comparison sort and
# without a list per pass. The fallback scans read the lines back in order.

def row.of(+top: F32, +h: U32) -> U32:
  F32.to_u32(U.clamp(F32.floor(top), 0.0, U32.to_f32(h)))

def counts.inc.got(got: Array<U32> & U32, +r: U32) -> Array<U32>:
  (c, v) = got
  Array.set(U32, c, r, (v + 1 : U32))

def counts.inc(c: Array<U32>, +r: U32) -> Array<U32>:
  counts.inc.got(Array.get(U32, c, r), r)

# Store each line at 4i and count its top row.
def soa.store.go(xs: List<&2, CovLine>, a: Array<F32>, counts: Array<U32>, +i: U32, +h: U32) -> Array<F32> & Array<U32>:
  match xs:
    case Nil{}: (a, counts)
    case Con{CovLine{x0, y0, x1, y1}, rest}:
      +ay = y0
      +by = y1
      +base = (i * 4 : U32)
      soa.store.go(rest, Array.set(F32, Array.set(F32, Array.set(F32, Array.set(F32, a, base, x0), (base + 1 : U32), ay), (base + 2 : U32), x1), (base + 3 : U32), by),
        counts.inc(counts, row.of(U.min(ay, by), h)), (i + 1 : U32), h)

# Turn counts into starting positions.
def counts.prefix.got(got: Array<U32> & U32, +i: U32, +acc: U32) -> Array<U32> & U32:
  (c, v) = got
  (Array.set(U32, c, i, acc), (acc + v : U32))

@unsafe
def counts.prefix(st: Array<U32> & U32, n: Nat, +i: U32) -> Array<U32> & U32:
  (c, acc) = st
  match n:
    case 0n: (c, acc)
    case 1n+d: counts.prefix(counts.prefix.got(Array.get(U32, c, i), i, acc), d, (i + 1 : U32))

def counts.done(st: Array<U32> & U32) -> Array<U32>:
  (c, acc) = st
  c

# Place line i at its row's next position.
def soa.place.pos(got: Array<U32> & U32, a: Array<F32>, order: Array<U32>, +i: U32, +r: U32) -> Array<F32> & (Array<U32> & Array<U32>):
  (starts, pos) = got
  +p = pos
  (a, (Array.set(U32, starts, r, (p + 1 : U32)), Array.set(U32, order, p, i)))

def soa.place.y1(got: Array<F32> & F32, starts: Array<U32>, order: Array<U32>, +y0: F32, +i: U32, +h: U32) -> Array<F32> & (Array<U32> & Array<U32>):
  (a, y1) = got
  +r = row.of(U.min(y0, y1), h)
  soa.place.pos(Array.get(U32, starts, r), a, order, i, r)

def soa.place.y0(got: Array<F32> & F32, starts: Array<U32>, order: Array<U32>, +i: U32, +h: U32) -> Array<F32> & (Array<U32> & Array<U32>):
  (a, y0) = got
  soa.place.y1(Array.get(F32, a, (i * 4 + 3 : U32)), starts, order, y0, i, h)

@unsafe
def soa.place(st: Array<F32> & (Array<U32> & Array<U32>), n: Nat, +i: U32, +h: U32) -> Array<F32> & (Array<U32> & Array<U32>):
  (a, (starts, order)) = st
  match n:
    case 0n: (a, (starts, order))
    case 1n+d: soa.place(soa.place.y0(Array.get(F32, a, (i * 4 + 1 : U32)), starts, order, i, h), d, (i + 1 : U32), h)

def soa.placed(st: Array<F32> & (Array<U32> & Array<U32>)) -> Array<F32> & Array<U32>:
  (a, (starts, order)) = st
  (a, order)

def soa.stored(st: Array<F32> & Array<U32>, +n: U32, +h: U32) -> Array<F32> & Array<U32>:
  (a, counts) = st
  soa.placed(soa.place((a, (counts.done(counts.prefix((counts, 0), U32.to_nat((h + 2 : U32)), 0)), Array.new(U32, depth.for((n + 1 : U32), 1, 0n), 0))), U32.to_nat(n), 0, h))

# The lines as (values, order) arrays, ordered by top row.
def soa.build(xs: List<&2, CovLine>, +n: U32, +h: U32) -> Array<F32> & Array<U32>:
  soa.stored(soa.store.go(xs, Array.new(F32, depth.for((n * 4 + 4 : U32), 1, 0n), 0.0), Array.new(U32, depth.for((h + 3 : U32), 1, 0n), 0), 0, h), n, h)

# The lines back as a list in order, for the sub-scanline scans.
def soa.line.x1(got: Array<F32> & F32, +x0: F32, +y0: F32, +y1: F32, acc: List<&2, CovLine>) -> Array<F32> & List<&2, CovLine>:
  (a, x1) = got
  (a, Con{CovLine{x0, y0, x1, y1}, acc})

def soa.line.y1(got: Array<F32> & F32, +x0: F32, +y0: F32, +base: U32, acc: List<&2, CovLine>) -> Array<F32> & List<&2, CovLine>:
  (a, y1) = got
  soa.line.x1(Array.get(F32, a, (base + 2 : U32)), x0, y0, y1, acc)

def soa.line.y0(got: Array<F32> & F32, +x0: F32, +base: U32, acc: List<&2, CovLine>) -> Array<F32> & List<&2, CovLine>:
  (a, y0) = got
  soa.line.y1(Array.get(F32, a, (base + 3 : U32)), x0, y0, base, acc)

def soa.line.x0(got: Array<F32> & F32, +base: U32, acc: List<&2, CovLine>) -> Array<F32> & List<&2, CovLine>:
  (a, x0) = got
  soa.line.y0(Array.get(F32, a, (base + 1 : U32)), x0, base, acc)

def soa.line.pair(got: Array<F32> & List<&2, CovLine>, order: Array<U32>) -> Array<F32> & (Array<U32> & List<&2, CovLine>):
  (a, acc) = got
  (a, (order, acc))

def soa.line.idx(got: Array<U32> & U32, a: Array<F32>, acc: List<&2, CovLine>) -> Array<F32> & (Array<U32> & List<&2, CovLine>):
  (order, i) = got
  +base = (i * 4 : U32)
  soa.line.pair(soa.line.x0(Array.get(F32, a, base), base, acc), order)

@unsafe
def soa.lines.go(st: Array<F32> & (Array<U32> & List<&2, CovLine>), n: Nat, +k: U32) -> Array<F32> & (Array<U32> & List<&2, CovLine>):
  (a, (order, acc)) = st
  match n:
    case 0n: (a, (order, acc))
    case 1n+d: soa.lines.go(soa.line.idx(Array.get(U32, order, k), a, acc), d, (k - 1 : U32))

def soa.lines.done(st: Array<F32> & (Array<U32> & List<&2, CovLine>)) -> List<&2, CovLine>:
  (a, (order, acc)) = st
  acc

def soa.lines(arrays: Array<F32> & Array<U32>, +n: U32) -> List<&2, CovLine>:
  (a, order) = arrays
  soa.lines.done(soa.lines.go((a, (order, {Nil{} : List<&2, CovLine>})), U32.to_nat(n), (n - 1 : U32)))

# Lines whose top the row's bottom has passed become pieces; a horizontal
# one is skipped. The cursor k walks the order array.
type PieceTake is Data:
  PieceTake{done: Bool, k: U32, n: U32, active: List<&2, Piece>}

def piece.take.x1(got: Array<F32> & F32, order: Array<U32>, +x0: F32, +y0: F32, +y1: F32, +k: U32, +n: U32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  (a, x1) = got
  ((a, order), PieceTake{False{}, (k + 1 : U32), n, Con{piece.of(CovLine{x0, y0, x1, y1}), active}})

def piece.take.x0(got: Array<F32> & F32, order: Array<U32>, +y0: F32, +y1: F32, +base: U32, +k: U32, +n: U32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  (a, x0) = got
  piece.take.x1(Array.get(F32, a, (base + 2 : U32)), order, x0, y0, y1, k, n, active)

def piece.take.pick(hit: Bool, flat: Bool, a: Array<F32>, order: Array<U32>, +y0: F32, +y1: F32, +base: U32, +k: U32, +n: U32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  match hit:
    case False{}: ((a, order), PieceTake{True{}, k, n, active})
    case True{}:
      match flat:
        case True{}: ((a, order), PieceTake{False{}, (k + 1 : U32), n, active})
        case False{}: piece.take.x0(Array.get(F32, a, base), order, y0, y1, base, k, n, active)

def piece.take.y1(got: Array<F32> & F32, order: Array<U32>, +y0: F32, +base: U32, +k: U32, +n: U32, +bottom: F32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  (a, y1) = got
  +yy1 = y1
  +top = U.min(y0, yy1)
  piece.take.pick(F32.is_lt(top, bottom), F32.is_le(U.max(y0, yy1), top), a, order, y0, yy1, base, k, n, active)

def piece.take.y0(got: Array<F32> & F32, order: Array<U32>, +base: U32, +k: U32, +n: U32, +bottom: F32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  (a, y0) = got
  piece.take.y1(Array.get(F32, a, (base + 3 : U32)), order, y0, base, k, n, bottom, active)

def piece.take.idx(got: Array<U32> & U32, a: Array<F32>, +k: U32, +n: U32, +bottom: F32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  (order, i) = got
  +base = (i * 4 : U32)
  piece.take.y0(Array.get(F32, a, (base + 1 : U32)), order, base, k, n, bottom, active)

def piece.take.more(arrays: Array<F32> & Array<U32>, more: Bool, +k: U32, +n: U32, +bottom: F32, active: List<&2, Piece>) -> (Array<F32> & Array<U32>) & PieceTake:
  (a, order) = arrays
  match more:
    case True{}: piece.take.idx(Array.get(U32, order, k), a, k, n, bottom, active)
    case False{}: ((a, order), PieceTake{True{}, k, n, active})

@unsafe
def piece.take(st: (Array<F32> & Array<U32>) & PieceTake, +bottom: F32) -> (Array<F32> & Array<U32>) & PieceTake:
  (arrays, t) = st
  match t:
    case PieceTake{done, k, n, active}:
      match done:
        case True{}: (arrays, PieceTake{True{}, k, n, active})
        case False{}:
          +kk = k
          +nn = n
          piece.take(piece.take.more(arrays, U32.is_lt(kk, nn), kk, nn, bottom, active), bottom)

# Reading the runs off the buffer, touched cells only, from hi down to lo: a
# cell's coverage is the magnitude of its direct area minus the deltas to its
# right (a row's deltas cancel), clamped to one, and the untouched cells
# between two touched ones share the magnitude of those deltas. A magnitude
# past one marks an overlap. Every slot and bitmap word read is cleared, so
# the buffer is empty for the next row.
type XState is Data:
  XState{sum: F32, bad: Bool, upper: U32, acc: List<&2, Run>}

def xrun.value(+v: F32) -> F32:
  U.min(1.0, run.snap(F32.abs(v)))

def xrow.delta(got: Array<F32> & F32, bm: Array<U32>, +direct: F32, +c: U32, st: XState) -> (Array<F32> & Array<U32>) & XState:
  (a, delta) = got
  XState{sum, bad, upper, acc} = st
  +ss = sum
  +v = (direct - ss : F32)
  +gap = F32.neg(ss)
  ((Array.set(F32, Array.set(F32, a, (c * 2 : U32), 0.0), (c * 2 + 1 : U32), 0.0), bm),
    XState{(ss + delta : F32), bad || F32.is_gt(F32.abs(v), 1.002) || F32.is_gt(F32.abs(gap), 1.002), c,
      runs.emit(c, (c + 1 : U32), xrun.value(v), runs.emit((c + 1 : U32), upper, xrun.value(gap), acc))})

def xrow.direct(got: Array<F32> & F32, bm: Array<U32>, +c: U32, st: XState) -> (Array<F32> & Array<U32>) & XState:
  (a, direct) = got
  xrow.delta(Array.get(F32, a, (c * 2 + 1 : U32)), bm, direct, c, st)

def xrow.cell(arrays: Array<F32> & Array<U32>, hit: Bool, +c: U32, st: XState) -> (Array<F32> & Array<U32>) & XState:
  (a, bm) = arrays
  match hit:
    case True{}: xrow.direct(Array.get(F32, a, (c * 2 : U32)), bm, c, st)
    case False{}: ((a, bm), st)

# The set bits of a word, from bit 31 down: mask halves at each step.
@unsafe
def xrow.bits(st: (Array<F32> & Array<U32>) & XState, n: Nat, +word: U32, +mask: U32, +cell: U32) -> (Array<F32> & Array<U32>) & XState:
  (arrays, state) = st
  match n:
    case 0n: (arrays, state)
    case 1n+d: xrow.bits(xrow.cell(arrays, U32.is_gt(U32.and(word, mask), 0), cell, state), d, word, U32.div(mask, 2), (cell - 1 : U32))

def xrow.word.if(empty: Bool, a: Array<F32>, bm: Array<U32>, +i: U32, +word: U32, st: XState) -> (Array<F32> & Array<U32>) & XState:
  match empty:
    case True{}: ((a, bm), st)
    case False{}: xrow.bits(((a, Array.set(U32, bm, i, 0)), st), 32n, word, 2147483648, (i * 32 + 31 : U32))

def xrow.word(got: Array<U32> & U32, a: Array<F32>, +i: U32, st: XState) -> (Array<F32> & Array<U32>) & XState:
  (bm, word) = got
  +ww = word
  xrow.word.if(U32.is_eq(ww, 0), a, bm, i, ww, st)

def xrow.word.of(st: (Array<F32> & Array<U32>) & XState, +i: U32) -> (Array<F32> & Array<U32>) & XState:
  ((a, bm), state) = st
  xrow.word(Array.get(U32, bm, i), a, i, state)

# Words from the one holding hi down to the one holding lo.
@unsafe
def xrow.words(st: (Array<F32> & Array<U32>) & XState, n: Nat, +i: U32) -> (Array<F32> & Array<U32>) & XState:
  match n:
    case 0n: st
    case 1n+d: xrow.words(xrow.word.of(st, i), d, (i - 1 : U32))

# A row's result: ((runs, overlap seen), the cleared buffer).
def xrow.done(st: (Array<F32> & Array<U32>) & XState, +w: U32) -> (List<&2, Run> & Bool) & ((Array<F32> & Array<U32>) & (U32 & U32)):
  (arrays, state) = st
  XState{sum, bad, upper, acc} = state
  +ss = sum
  ((runs.emit(0, upper, xrun.value(F32.neg(ss)), acc), bad || F32.is_gt(F32.abs(ss), 1.002)), (arrays, ((w + 1 : U32), 0)))

def xrow.count(+lo: U32, +hi: U32) -> U32:
  U.choose(U32, U32.is_gt(lo, hi), 0, (U32.div(hi, 32) - U32.div(lo, 32) + 1 : U32))

def xrow.from(arrays: Array<F32> & Array<U32>, +lo: U32, +hi: U32, +w: U32) -> (List<&2, Run> & Bool) & ((Array<F32> & Array<U32>) & (U32 & U32)):
  xrow.done(xrow.words((arrays, XState{0.0, False{}, w, {Nil{} : List<&2, Run>}}), U32.to_nat(xrow.count(lo, hi)), U32.div(hi, 32)), w)

# The runs of a row from its buffer, which comes back cleared.
def xrow.runs(b: (Array<F32> & Array<U32>) & (U32 & U32), +w: U32) -> (List<&2, Run> & Bool) & ((Array<F32> & Array<U32>) & (U32 & U32)):
  (arrays, (lo, hi)) = b
  xrow.from(arrays, lo, hi, w)

# The scan state: the row buffer, the line arrays, and the rest as a record.
type XData is Data:
  XData{lo: U32, hi: U32, rows: List<&2, List<&2, Run>>, active: List<&2, Piece>, k: U32, n: U32, sub: U32}

def rows.head(rows: List<&2, List<&2, Run>>) -> List<&2, Run>:
  match rows:
    case Nil{}: Nil{}
    case Con{r, rest}: r

# A row whose exact areas showed an overlap is scanned again with the
# sub-scanlines over its own pieces; other rows keep their runs. Either way
# the pieces the next row no longer reaches are retired.
def xscan.fix(bad: Bool, runs: List<&2, Run>, active: List<&2, Piece>, +y: F32, +sub: U32, +w: U32) -> List<&2, Run> & List<&2, Piece>:
  match bad:
    case False{}: (runs, pieces.retire(active, (y + 1.0 : F32), Nil{}))
    case True{}:
      +act = active
      (rows.head(scan.rows(1, sub, lines.sort(pieces.lines(act, y, Nil{})), False{}, w)), pieces.retire(act, (y + 1.0 : F32), Nil{}))

def xscan.push(fixed: List<&2, Run> & List<&2, Piece>, buf: (Array<F32> & Array<U32>) & (U32 & U32), lines: Array<F32> & Array<U32>, rows: List<&2, List<&2, Run>>, +k: U32, +n: U32, +sub: U32) -> ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData:
  (runs, active) = fixed
  (buf, (lo, hi)) = buf
  ((buf, lines), XData{lo, hi, Con{runs, rows}, active, k, n, sub})

def xscan.swept(r: (List<&2, Run> & Bool) & ((Array<F32> & Array<U32>) & (U32 & U32)), lines: Array<F32> & Array<U32>, rows: List<&2, List<&2, Run>>, active: List<&2, Piece>, +y: F32, +k: U32, +n: U32, +sub: U32, +w: U32) -> ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData:
  ((runs, bad), buf) = r
  xscan.push(xscan.fix(bad, runs, active, y, sub, w), buf, lines, rows, k, n, sub)

def xscan.rowed(s: List<&2, Piece> & ((Array<F32> & Array<U32>) & (U32 & U32)), lines: Array<F32> & Array<U32>, rows: List<&2, List<&2, Run>>, +y: F32, +k: U32, +n: U32, +sub: U32, +w: U32) -> ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData:
  (active, b) = s
  xscan.swept(xrow.runs(b, w), lines, rows, active, y, k, n, sub, w)

def xscan.taken(t: (Array<F32> & Array<U32>) & PieceTake, buf: (Array<F32> & Array<U32>) & (U32 & U32), rows: List<&2, List<&2, Run>>, +y: F32, +sub: U32, +w: U32) -> ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData:
  (lines, take) = t
  PieceTake{done, k, n, active} = take
  xscan.rowed(pieces.row(active, y, w, Nil{}, buf), lines, rows, y, k, n, sub, w)

def xscan.row(st: ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData, +y: U32, +w: U32) -> ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData:
  ((buf, lines), data) = st
  XData{lo, hi, rows, active, k, n, sub} = data
  +yf = U32.to_f32(y)
  xscan.taken(piece.take((lines, PieceTake{False{}, k, n, active}), (yf + 1.0 : F32)), (buf, (lo, hi)), rows, yf, sub, w)

@unsafe
def xscan.rows.go(st: ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData, n: Nat, +y: U32, +w: U32) -> ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData:
  match n:
    case 0n: st
    case 1n+d: xscan.rows.go(xscan.row(st, y, w), d, (y + 1 : U32), w)

def xscan.done(st: ((Array<F32> & Array<U32>) & (Array<F32> & Array<U32>)) & XData) -> List<&2, List<&2, Run>>:
  ((buf, lines), data) = st
  XData{lo, hi, rows, active, k, n, sub} = data
  rows.reverse(rows, Nil{})

# The rows of runs of the lines (in their arrays, n of them) by exact areas,
# rows with an overlap done with `sub` scanlines.
def xscan.rows(+h: U32, lines: Array<F32> & Array<U32>, +n: U32, +sub: U32, +w: U32) -> List<&2, List<&2, Run>>:
  xscan.done(xscan.rows.go((((Array.new(F32, depth.for((w * 2 + 4 : U32), 1, 0n), 0.0), Array.new(U32, depth.for((U32.div(w, 32) + 2 : U32), 1, 0n), 0)), lines),
    XData{(w + 1 : U32), 0, {Nil{} : List<&2, List<&2, Run>>}, {Nil{} : List<&2, Piece>}, 0, n, sub}), U32.to_nat(h), 0, w))

# ---- the tree ----
# A node is built top-down from the rows of runs that lie inside it, clipped
# to its columns. One pass over a node's rows tells whether it is uniform (no
# runs, or in every row one run spanning the node with the same value) and at
# the same time splits the rows into the four quarters, each row's runs cut at
# the middle column, so no list is shared between the node and its children
# and a uniform node's rows are never looked at again.

# A row's runs cut at mid into the left and right halves, with the row's
# uniform value over [x0, x1): 0 for no runs, the value of a single run that
# spans the columns, -1 otherwise.
type Halves is Data:
  Halves{value: F32, left: List<&2, Run>, right: List<&2, Run>}

def halves.place(onLeft: Bool, onRight: Bool, +v: F32, +a: U32, +b: U32, +u: F32, +mid: U32, left: List<&2, Run>, right: List<&2, Run>) -> Halves:
  match onLeft onRight:
    case True{} _: Halves{v, Con{Run{a, b, u}, left}, right}
    case False{} True{}: Halves{v, left, Con{Run{a, b, u}, right}}
    case False{} False{}: Halves{v, Con{Run{a, mid, u}, left}, Con{Run{mid, b, u}, right}}

def halves.push(h: Halves, +a: U32, +b: U32, +u: F32, +mid: U32, +x0: U32, +x1: U32) -> Halves:
  match h:
    case Halves{value, left, right}:
      +vv = value
      +full = F32.is_eq(vv, 0.0) && U32.is_eq(a, x0) && U32.is_eq(b, x1)
      halves.place(U32.is_le(b, mid), U32.is_ge(a, mid), U.choose(F32, full, u, F32.neg(1.0)), a, b, u, mid, left, right)

def runs.halves(rs: List<&2, Run>, +mid: U32, +x0: U32, +x1: U32) -> Halves:
  match rs:
    case Nil{}: Halves{0.0, Nil{}, Nil{}}
    case Con{Run{a, b, u}, rest}: halves.push(runs.halves(rest, mid, x0, x1), a, b, u, mid, x0, x1)

# A node's uniform value (2 before any row, -1 once rows disagree) and its
# quarters' rows; flat holds when the node is uniform (no rows means empty).
type Node is Data:
  Node{flat: Bool, value: F32, tl: List<&2, List<&2, Run>>, tr: List<&2, List<&2, Run>>, bl: List<&2, List<&2, Run>>, br: List<&2, List<&2, Run>>}

def node.push(n: Node, h: Halves, top: Bool) -> Node:
  Node{flat, value, tl, tr, bl, br} = n
  Halves{v, left, right} = h
  match top:
    case True{}: Node{flat, tree.same.as(value, v), Con{left, tl}, Con{right, tr}, bl, br}
    case False{}: Node{flat, tree.same.as(value, v), tl, tr, Con{left, bl}, Con{right, br}}

# Rows past the end of the list are empty; row i of size is a top row when i < half.
def node.rows(rows: List<&2, List<&2, Run>>, +i: U32, +size: U32, +half: U32, +x0: U32) -> Node:
  match rows:
    case Nil{}: Node{False{}, U.choose(F32, U32.is_lt(i, size), 0.0, 2.0), Nil{}, Nil{}, Nil{}, Nil{}}
    case Con{r, rest}: node.push(node.rows(rest, (i + 1 : U32), size, half, x0), runs.halves(r, (x0 + half : U32), x0, (x0 + size : U32)), U32.is_lt(i, half))

def node.mark(n: Node) -> Node:
  Node{flat, value, tl, tr, bl, br} = n
  +vv = value
  Node{Bool.not(F32.is_lt(vv, 0.0)), vv, tl, tr, bl, br}

def node.of(rows: List<&2, List<&2, Run>>, +size: U32, +x0: U32) -> Node:
  node.mark(node.rows(rows, 0, size, U32.div(size, 2), x0))

def node.value(+v: F32) -> F32:
  U.choose(F32, F32.is_gt(v, 1.5), 0.0, v)

@unsafe
def tree.node(n: Node, depth: Nat, +x0: U32, +size: U32) -> CovTree:
  match n:
    case Node{flat, value, tl, tr, bl, br}:
      match flat:
        case True{}: CovFlat{node.value(value)}
        case False{}:
          match depth:
            case 0n: CovFlat{node.value(value)}
            case 1n+d:
              +dd = d
              +half = U32.shln(1, dd)
              +x1 = (x0 + half : U32)
              CovQuad{tree.node(node.of(tl, half, x0), dd, x0, half), tree.node(node.of(tr, half, x1), dd, x1, half),
                tree.node(node.of(bl, half, x0), dd, x0, half), tree.node(node.of(br, half, x1), dd, x1, half)}

# ---- entry ----

type CovBox is Data:
  CovBox{x0: F32, y0: F32, x1: F32, y1: F32}

def lines.bounds(xs: List<&2, CovLine>, +x0: F32, +y0: F32, +x1: F32, +y1: F32) -> CovBox:
  match xs:
    case Nil{}: CovBox{x0, y0, x1, y1}
    case Con{CovLine{ax, ay, bx, by}, rest}:
      +byDup = by
      +bxDup = bx
      +ayDup = ay
      +axDup = ax
      +lx = U.min(axDup, bxDup)
      +ly = U.min(ayDup, byDup)
      +hx = U.max(axDup, bxDup)
      +hy = U.max(ayDup, byDup)
      lines.bounds(rest, U.min(x0, lx), U.min(y0, ly), U.max(x1, hx), U.max(y1, hy))

def lines.shift(xs: List<&2, CovLine>, +dx: F32, +dy: F32) -> List<&2, CovLine>:
  match xs:
    case Nil{}: Nil{}
    case Con{CovLine{ax, ay, bx, by}, rest}: Con{CovLine{(ax - dx : F32), (ay - dy : F32), (bx - dx : F32), (by - dy : F32)}, lines.shift(rest, dx, dy)}

def mask.data(trees: Bool, rows: List<&2, List<&2, Run>>, +size: U32, +depth: Nat) -> CovData:
  match trees:
    case True{}: CovTreed{tree.node(node.of(rows, size, 0), depth, 0, size)}
    case False{}: CovRows{rows}

def mask.arrays(xs: List<&2, CovLine>, +n: U32, +h: U32, +sub: U32, +w: U32) -> List<&2, List<&2, Run>>:
  xscan.rows(h, soa.build(xs, n, h), n, sub, w)

# Even-odd fills rely on the winding parity, which only the sub-scanline scan follows.
def mask.scan(clipped: List<&2, CovLine> & U32, even: Bool, +h: U32, +sub: U32, +w: U32) -> List<&2, List<&2, Run>>:
  (xs, n) = clipped
  match even:
    case True{}: scan.rows(h, sub, lines.sort(xs), True{}, w)
    case False{}: mask.arrays(xs, n, h, sub, w)

def mask.build(xs: List<&2, CovLine>, +gx: U32, +gy: U32, +w: U32, +h: U32, +even: Bool, +sub: U32, +trees: Bool) -> CovMask:
  +side = U.choose(U32, U32.is_gt(w, h), w, h)
  +depth = depth.for(side, 1, 0n)
  +size = U32.shln(1, depth)
  CovMask{gx, gy, w, h, size, depth, mask.data(trees, mask.scan(lines.prepare(xs, U32.to_f32(gx), U32.to_f32(gy), U32.to_f32(w), ({Nil{} : List<&2, CovLine>}, 0)), even, h, sub, w), size, depth), True{}}

def mask.box(+xs: List<&2, CovLine>, +even: Bool, +width: U32, +height: U32, +sub: U32, box: CovBox, +trees: Bool) -> CovMask:
  CovBox{x0, y0, x1, y1} = box
  +gx = F32.to_u32(U.clamp(F32.floor(x0), 0.0, U32.to_f32(width)))
  +gy = F32.to_u32(U.clamp(F32.floor(y0), 0.0, U32.to_f32(height)))
  +ex = F32.to_u32(U.clamp(F32.ceil(x1), 0.0, U32.to_f32(width)))
  +ey = F32.to_u32(U.clamp(F32.ceil(y1), 0.0, U32.to_f32(height)))
  U.branch(CovMask, U32.is_ge(gx, ex) || U32.is_ge(gy, ey), _ => CovMask{0, 0, 0, 0, 0, 0n, CovTreed{CovFlat{0.0}}, True{}},
    _ => mask.build(xs, gx, gy, (ex - gx : U32), (ey - gy : U32), even, sub, trees))

# A closed rectangle on whole pixels: four axis-aligned lines on the box edges
# with integer coordinates (the usual viewport clip and the common rect), whose
# mask is a tree of full and empty leaves with no scan at all.
def line.on.box(+ax: F32, +ay: F32, +bx: F32, +by: F32, +x0: F32, +y0: F32, +x1: F32, +y1: F32) -> Bool:
  (F32.is_eq(ax, bx) && (F32.is_eq(ax, x0) || F32.is_eq(ax, x1))) || (F32.is_eq(ay, by) && (F32.is_eq(ay, y0) || F32.is_eq(ay, y1)))

# Zero-length lines (a path's move and close) are ignored; the four real ones must lie on the box.
def lines.on.box(xs: List<&2, CovLine>, +x0: F32, +y0: F32, +x1: F32, +y1: F32, +count: U32) -> Bool:
  match xs:
    case Nil{}: U32.is_eq(count, 4)
    case Con{CovLine{ax, ay, bx, by}, rest}:
      +axx = ax
      +ayy = ay
      +bxx = bx
      +byy = by
      +empty = F32.is_eq(axx, bxx) && F32.is_eq(ayy, byy)
      (empty || line.on.box(axx, ayy, bxx, byy, x0, y0, x1, y1)) && lines.on.box(rest, x0, y0, x1, y1, U.choose(U32, empty, count, (count + 1 : U32)))

def whole(+v: F32) -> Bool:
  F32.is_eq(v, F32.floor(v))

def rect.aligned(+xs: List<&2, CovLine>, +box: CovBox) -> Bool:
  CovBox{x0, y0, x1, y1} = box
  whole(x0) && whole(y0) && whole(x1) && whole(y1) && F32.is_lt(x0, x1) && F32.is_lt(y0, y1) && lines.on.box(xs, x0, y0, x1, y1, 0)

@unsafe
def tree.rect(depth: Nat, +x: U32, +y: U32, +w: U32, +h: U32) -> CovTree:
  match depth:
    case 0n: CovFlat{U.choose(F32, U32.is_lt(x, w) && U32.is_lt(y, h), 1.0, 0.0)}
    case 1n+d:
      +dd = d
      +half = U32.shln(1, dd)
      +size = (half * 2 : U32)
      U.branch(CovTree, U32.is_ge(x, w) || U32.is_ge(y, h), _ => CovFlat{0.0},
        _ => U.branch(CovTree, U32.is_le((x + size : U32), w) && U32.is_le((y + size : U32), h), _ => CovFlat{1.0},
          _ => CovQuad{tree.rect(dd, x, y, w, h), tree.rect(dd, (x + half : U32), y, w, h), tree.rect(dd, x, (y + half : U32), w, h), tree.rect(dd, (x + half : U32), (y + half : U32), w, h)}))

# A full rectangle as rows: one run per row.
def rect.rows(n: Nat, +w: U32, acc: List<&2, List<&2, Run>>) -> List<&2, List<&2, Run>>:
  match n:
    case 0n: acc
    case 1n+d: rect.rows(d, w, Con{Con{Run{0, w, 1.0}, Nil{}}, acc})

def rect.data(trees: Bool, +depth: Nat, +w: U32, +h: U32) -> CovData:
  match trees:
    case True{}: CovTreed{tree.rect(depth, 0, 0, w, h)}
    case False{}: CovRows{rect.rows(U32.to_nat(h), w, Nil{})}

def mask.rect(+width: U32, +height: U32, +box: CovBox, +trees: Bool) -> CovMask:
  CovBox{x0, y0, x1, y1} = box
  +gx = F32.to_u32(U.clamp(x0, 0.0, U32.to_f32(width)))
  +gy = F32.to_u32(U.clamp(y0, 0.0, U32.to_f32(height)))
  +ex = F32.to_u32(U.clamp(x1, 0.0, U32.to_f32(width)))
  +ey = F32.to_u32(U.clamp(y1, 0.0, U32.to_f32(height)))
  +w = (ex - gx : U32)
  +h = (ey - gy : U32)
  +depth = depth.for(U.choose(U32, U32.is_gt(w, h), w, h), 1, 0n)
  U.branch(CovMask, U32.is_ge(gx, ex) || U32.is_ge(gy, ey), _ => CovMask{0, 0, 0, 0, 0, 0n, CovTreed{CovFlat{0.0}}, True{}},
    _ => CovMask{gx, gy, w, h, U32.shln(1, depth), depth, rect.data(trees, depth, w, h), True{}})

def mask.shape(aligned: Bool, +xs: List<&2, CovLine>, +even: Bool, +width: U32, +height: U32, +sub: U32, +box: CovBox, +trees: Bool) -> CovMask:
  match aligned:
    case True{}: mask.rect(width, height, box, trees)
    case False{}: mask.box(xs, even, width, height, sub, box, trees)

# Rasterize closed contours given as directed lines in pixel coordinates of a
# width by height grid, with `sub` scanlines per pixel row; nonzero winding, or
# even-odd when `even` holds.
# even-odd when `even` holds; with `trees` the mask carries the quadtree that
# block and pixel queries need, else only its rows of runs.
def mask(+xs: List<&2, CovLine>, +even: Bool, +width: U32, +height: U32, +sub: U32, +trees: Bool) -> CovMask:
  +box = lines.bounds(xs, 1000000000.0, 1000000000.0, F32.neg(1000000000.0), F32.neg(1000000000.0))
  mask.shape(rect.aligned(xs, box), xs, even, width, height, sub, box, trees)

# Lines gathered with their bounds and count as they are made, so the mask
# needs no pass of its own over them; only a handful of lines can be a
# rectangle, so the others skip that test too.
type CovLines is Data:
  CovLines{lines: List<&2, CovLine>, x0: F32, y0: F32, x1: F32, y1: F32, count: U32}

def lines.empty() -> CovLines:
  CovLines{Nil{}, 1000000000.0, 1000000000.0, F32.neg(1000000000.0), F32.neg(1000000000.0), 0}

def lines.add(l: CovLines, +ax: F32, +ay: F32, +bx: F32, +by: F32) -> CovLines:
  CovLines{xs, x0, y0, x1, y1, n} = l
  CovLines{Con{CovLine{ax, ay, bx, by}, xs}, U.min(x0, U.min(ax, bx)), U.min(y0, U.min(ay, by)), U.max(x1, U.max(ax, bx)), U.max(y1, U.max(ay, by)), (n + 1 : U32)}

def mask.lined.pick(few: Bool, xs: List<&2, CovLine>, box: CovBox, +even: Bool, +width: U32, +height: U32, +sub: U32, +trees: Bool) -> CovMask:
  match few:
    case True{}:
      +ls = xs
      +b = box
      mask.shape(rect.aligned(ls, b), ls, even, width, height, sub, b, trees)
    case False{}: mask.box(xs, even, width, height, sub, box, trees)

def mask.lined(l: CovLines, +even: Bool, +width: U32, +height: U32, +sub: U32, +trees: Bool) -> CovMask:
  CovLines{xs, x0, y0, x1, y1, n} = l
  mask.lined.pick(U32.is_le(n, 5), xs, CovBox{x0, y0, x1, y1}, even, width, height, sub, trees)

def mask.scanned(+xs: List<&2, CovLine>, +even: Bool, +width: U32, +height: U32, +sub: U32, +trees: Bool) -> CovMask:
  mask.box(xs, even, width, height, sub, lines.bounds(xs, 1000000000.0, 1000000000.0, F32.neg(1000000000.0), F32.neg(1000000000.0)), trees)
