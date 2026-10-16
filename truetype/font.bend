# Font book: glyph outlines, advances, kerning and metrics.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-bytes@0.1.0.0/bytes.bend as Bin

type TTFont is Data:
  TTFont{glyf: U32, loca: U32, long: Bool, hmtx: U32, metrics: U32, glyphs: U32, units: F32}

type TTPairs is Data:
  TTPairs{specific: List<&2, U32>, classes: U32, coverage: U32, class1: U32, class2: U32}

# A TrueType face stays as its bytes plus table offsets; glyphs and kerning
# are read from it on demand (see font.glyph and font.kern at the end).
type TTFace is Data:
  TTFace{bytes: Bin.Bytes, font: TTFont, pairs: TTPairs, cmap: U32}

type FontGlyph is Data:
  FontGlyph{advance: F32, outline: String, glyph: U32, leftClass: U32, rightClass: U32}

# The glyph, kerning and metric maps hold text-format fonts (font.parse) and
# every face's metrics; faces holds the lazily read TrueType faces by number.
type FontBook is Data:
  FontBook{glyphs: Map<&2, FontGlyph>, kerning: Map<&2, F32>, metrics: Map<&2, F32>, faces: Map<&2, TTFace>}

def font.empty() -> FontBook:
  FontBook{MTip{}, MTip{}, MTip{}, MTip{}}

def font.missing() -> FontGlyph:
  FontGlyph{600.0, "M94 0V714H505V0ZM151 57H448V657H151Z", 0, 0, 0}

def font.glyph.result(got: Map<&2, FontGlyph> & FontGlyph) -> FontGlyph:
  (map, glyph) = got
  glyph

def font.number.result(got: Map<&2, F32> & F32) -> F32:
  (map, val) = got
  val

def font.metric(book: FontBook, face: U32, name: String, fallback: F32) -> F32:
  FontBook{glyphs, kerning, faceMetrics, faces} = book
  font.number.result(Map.get(F32, fallback, faceMetrics, U32.show(face) ++ ":" ++ name))

def font.glyph.map(+glyphs: Map<&2, FontGlyph>, +face: U32, ch: U32) -> FontGlyph:
  font.glyph.result(Map.get(FontGlyph, font.glyph.result(Map.get(FontGlyph, font.missing(), glyphs, U32.show(face) ++ ":?")), glyphs, U32.show(face) ++ ":" ++ U32.show(ch)))

def font.kern.value(+specific: F32, fallback: Unit -> F32) -> F32:
  U.branch(F32, F32.is_eq(specific, 1000000.0), _ => fallback(Unit{}), _ => specific)

def font.kern.map(+kerning: Map<&2, F32>, +face: U32, left: U32, leftClass: U32, right: U32, rightClass: U32) -> F32:
  font.kern.value(font.number.result(Map.get(F32, 1000000.0, kerning, U32.show(face) ++ ":" ++ U32.show((16777216 + left * 4096 + right : U32)))),
    _ => font.number.result(Map.get(F32, 0.0, kerning, U32.show(face) ++ ":" ++ U32.show((leftClass * 128 + rightClass : U32)))))

def font.parse.glyph(key: String, scan: U.Scan, book: FontBook) -> FontBook:
  U.Scan{metrics, outline} = scan
  FontBook{glyphs, kerning, faceMetrics, faces} = book
  +vs = U.numbers(metrics)
  FontBook{Map.set(&2, FontGlyph, glyphs, key, FontGlyph{U.nth(vs, 0n, 600.0), outline,
    F32.to_u32(U.nth(vs, 1n, 0.0)), F32.to_u32(U.nth(vs, 2n, 0.0)), F32.to_u32(U.nth(vs, 3n, 0.0))}), kerning, faceMetrics, faces}

def font.parse.record(kind: String, +scan: U.Scan, +book: FontBook) -> FontBook:
  U.Scan{key, body} = scan
  FontBook{glyphs, kerning, faceMetrics, faces} = book
  +tag = kind
  U.branch(FontBook, U.string.equal(tag, "g"), _ => font.parse.glyph(key, U.until(body, 124, ""), book),
    _ => U.branch(FontBook, U.string.equal(tag, "k"), _ => FontBook{glyphs, Map.set(&2, F32, kerning, key, U.scalar(body, 0.0)), faceMetrics, faces}, _ => U.branch(FontBook, U.string.equal(tag, "m"), _ => FontBook{glyphs, kerning, Map.set(&2, F32, faceMetrics, key, U.scalar(body, 0.0)), faces}, _ => book)))

def font.parse.row(scan: U.Scan, book: FontBook) -> FontBook:
  U.Scan{kind, body} = scan
  font.parse.record(kind, U.until(body, 124, ""), book)

def font.parse.line(scan: U.Scan, book: FontBook, next: String -> FontBook -> FontBook) -> FontBook:
  U.Scan{line, tail} = scan
  next(tail)(font.parse.row(U.until(line, 124, ""), book))

@unsafe
def font.parse(s: String, book: FontBook) -> FontBook:
  match s:
    case SNil{}: book
    case SCon{c, t}: font.parse.line(U.until(SCon{c, t}, 10, ""), book, rest => fonts => font.parse(rest, fonts))
# ---- TrueType reader ----
# Reads the table directory, glyf/loca/hmtx, cmap, OS/2 and GPOS of one face:
# outlines as SVG path data in font units (y up), advances, GPOS pair kerning
# (every format 1 subtable and the first format 2 subtable of the first pair
# lookup) and OS/2 metrics normalized by units per em. Glyphs and kerning are
# resolved when asked for, from the face's bytes. CFF outlines, collections,
# WOFF wrappers and the legacy kern table are not read.

def ttf.u8(+b: Bin.Bytes, +at: U32) -> U32:
  Bin.bytes.get(b, at)

def ttf.u16(+b: Bin.Bytes, +at: U32) -> U32:
  Bin.bytes.be(b, at, 2n, 0)

def ttf.u32(+b: Bin.Bytes, +at: U32) -> U32:
  Bin.bytes.be(b, at, 4n, 0)

def ttf.i16(+b: Bin.Bytes, +at: U32) -> F32:
  +v = ttf.u16(b, at)
  U.choose(F32, U32.is_ge(v, 32768), (U32.to_f32(v) - 65536.0 : F32), U32.to_f32(v))

def ttf.i8(+b: Bin.Bytes, +at: U32) -> F32:
  +v = ttf.u8(b, at)
  U.choose(F32, U32.is_ge(v, 128), (U32.to_f32(v) - 256.0 : F32), U32.to_f32(v))

def ttf.f2dot14(+b: Bin.Bytes, +at: U32) -> F32:
  (ttf.i16(b, at) / 16384.0 : F32)

def ttf.bit(+flags: U32, +mask: U32) -> Bool:
  U32.is_ne(U32.and(flags, mask), 0)

def ttf.table.find(+b: Bin.Bytes, n: Nat, +at: U32, +tag: U32) -> U32:
  match n:
    case 0n: 0
    case 1n+d: U.branch(U32, U32.is_eq(ttf.u32(b, at), tag), _ => ttf.u32(b, (at + 8 : U32)), _ => ttf.table.find(b, d, (at + 16 : U32), tag))

# Table offset by tag, read as a big-endian word; 0 when absent.
def ttf.table(+b: Bin.Bytes, +tag: U32) -> U32:
  ttf.table.find(b, U32.to_nat(ttf.u16(b, 4)), 12, tag)

def ttf.font(+b: Bin.Bytes) -> TTFont:
  +head = ttf.table(b, 1751474532)
  +maxp = ttf.table(b, 1835104368)
  +hhea = ttf.table(b, 1751672161)
  TTFont{ttf.table(b, 1735162214), ttf.table(b, 1819239265), U32.is_ne(ttf.u16(b, (head + 50 : U32)), 0), ttf.table(b, 1752003704),
    ttf.u16(b, (hhea + 34 : U32)), ttf.u16(b, (maxp + 4 : U32)), U32.to_f32(ttf.u16(b, (head + 18 : U32)))}

def ttf.valid(+f: TTFont) -> Bool:
  TTFont{glyf, loca, long, hmtx, metrics, glyphs, units} = f
  U32.is_ne(glyf, 0) && U32.is_ne(loca, 0) && U32.is_ne(hmtx, 0) && U32.is_gt(metrics, 0) && F32.is_gt(units, 0.0)

def ttf.units(+f: TTFont) -> F32:
  TTFont{glyf, loca, long, hmtx, metrics, glyphs, units} = f
  units

def ttf.glyf(+f: TTFont) -> U32:
  TTFont{glyf, loca, long, hmtx, metrics, glyphs, units} = f
  glyf

def ttf.advance(+b: Bin.Bytes, +f: TTFont, +gid: U32) -> F32:
  TTFont{glyf, loca, long, hmtx, metrics, glyphs, units} = f
  +m = metrics
  +i = U.choose(U32, U32.is_lt(gid, m), gid, (m - 1 : U32))
  U32.to_f32(ttf.u16(b, (hmtx + i * 4 : U32)))

# Absolute offset of a glyph's data and its byte length (0 for empty or invalid glyphs).
def ttf.location(+b: Bin.Bytes, +f: TTFont, +gid: U32) -> U32 & U32:
  TTFont{glyf, loca, long, hmtx, metrics, glyphs, units} = f
  +lo = loca
  +lg = long
  +a = U.choose(U32, lg, ttf.u32(b, (lo + gid * 4 : U32)), (ttf.u16(b, (lo + gid * 2 : U32)) * 2 : U32))
  +c = U.choose(U32, lg, ttf.u32(b, (lo + gid * 4 + 4 : U32)), (ttf.u16(b, (lo + gid * 2 + 2 : U32)) * 2 : U32))
  ((glyf + a : U32), U.choose(U32, U32.is_lt(gid, glyphs) && U32.is_gt(c, a), (c - a : U32), 0))

type TTPoint is Data:
  TTPoint{x: F32, y: F32, on: Bool}

# Flat point list with the last point index of every contour.
type TTGlyph is Data:
  TTGlyph{points: List<&2, TTPoint>, ends: List<&2, U32>, count: U32}

def ttf.glyph.empty() -> TTGlyph:
  TTGlyph{Nil{}, Nil{}, 0}

def ttf.glyph.points(+g: TTGlyph) -> List<&2, TTPoint>:
  TTGlyph{points, ends, count} = g
  points

def ttf.ends(+b: Bin.Bytes, n: Nat, +at: U32) -> List<&2, U32>:
  match n:
    case 0n: Nil{}
    case 1n+d: Con{ttf.u16(b, at), ttf.ends(b, d, (at + 2 : U32))}

def ttf.last(xs: List<&2, U32>, +fallback: U32) -> U32:
  match xs:
    case Nil{}: fallback
    case Con{h, t}: ttf.last(t, h)

def ttf.after.flag(+f: U32, got: List<&2, U32> & U32) -> List<&2, U32> & U32:
  (rest, next) = got
  (Con{f, rest}, next)

# Point flags with repeat counts expanded; returns the flags and the next byte offset.
def ttf.flags(+b: Bin.Bytes, n: Nat, +at: U32, +pending: U32, +last: U32) -> List<&2, U32> & U32:
  match n:
    case 0n: (Nil{}, at)
    case 1n+d:
      +dd = d
      +f = ttf.u8(b, at)
      U.branch(List<&2, U32> & U32, U32.is_gt(pending, 0),
        _ => ttf.after.flag(last, ttf.flags(b, dd, at, (pending - 1 : U32), last)),
        _ => U.branch(List<&2, U32> & U32, ttf.bit(f, 8),
          _ => ttf.after.flag(f, ttf.flags(b, dd, (at + 2 : U32), ttf.u8(b, (at + 1 : U32)), f)),
          _ => ttf.after.flag(f, ttf.flags(b, dd, (at + 1 : U32), 0, f))))

def ttf.after.coord(+v: F32, got: List<&2, F32> & U32) -> List<&2, F32> & U32:
  (rest, next) = got
  (Con{v, rest}, next)

# One coordinate axis: short bytes with a sign flag, repeated values, or signed word deltas.
def ttf.coords(+b: Bin.Bytes, flags: List<&2, U32>, +at: U32, +prev: F32, +short: U32, +same: U32) -> List<&2, F32> & U32:
  match flags:
    case Nil{}: (Nil{}, at)
    case Con{f, rest}:
      +fl = f
      +isShort = ttf.bit(fl, short)
      +isSame = ttf.bit(fl, same)
      +v = U.branch(F32, isShort, _ => (prev + U.choose(F32, isSame, 1.0, F32.neg(1.0)) * U32.to_f32(ttf.u8(b, at)) : F32),
        _ => U.branch(F32, isSame, _ => prev, _ => (prev + ttf.i16(b, at) : F32)))
      ttf.after.coord(v, ttf.coords(b, rest, (at + U.choose(U32, isShort, 1, U.choose(U32, isSame, 0, 2)) : U32), v, short, same))

def ttf.points(flags: List<&2, U32>, xs: List<&2, F32>, ys: List<&2, F32>) -> List<&2, TTPoint>:
  match flags xs ys:
    case Con{f, fr} Con{x, xr} Con{y, yr}: Con{TTPoint{x, y, ttf.bit(f, 1)}, ttf.points(fr, xr, yr)}
    case _ _ _: Nil{}

def ttf.simple.y(flags: List<&2, U32>, xs: List<&2, F32>, ends: List<&2, U32>, +count: U32, got: List<&2, F32> & U32) -> TTGlyph:
  (ys, next) = got
  TTGlyph{ttf.points(flags, xs, ys), ends, count}

def ttf.simple.x(+b: Bin.Bytes, +flags: List<&2, U32>, ends: List<&2, U32>, +count: U32, got: List<&2, F32> & U32) -> TTGlyph:
  (xs, next) = got
  ttf.simple.y(flags, xs, ends, count, ttf.coords(b, flags, next, 0.0, 4, 32))

def ttf.simple.flags(+b: Bin.Bytes, ends: List<&2, U32>, +count: U32, got: List<&2, U32> & U32) -> TTGlyph:
  (flags, next) = got
  +fl = flags
  ttf.simple.x(b, fl, ends, count, ttf.coords(b, fl, next, 0.0, 2, 16))

# A simple glyph at absolute offset g with the given contour count.
def ttf.simple(+b: Bin.Bytes, +g: U32, +contours: U32) -> TTGlyph:
  +ends = ttf.ends(b, U32.to_nat(contours), (g + 10 : U32))
  +count = U.choose(U32, U32.is_gt(contours, 0), (ttf.last(ends, 0) + 1 : U32), 0)
  +instructions = ttf.u16(b, (g + 10 + contours * 2 : U32))
  ttf.simple.flags(b, ends, count, ttf.flags(b, U32.to_nat(count), (g + 12 + contours * 2 + instructions : U32), 0, 0))

def ttf.point(pts: List<&2, TTPoint>, i: Nat) -> TTPoint:
  match pts i:
    case Nil{} _: TTPoint{0.0, 0.0, True{}}
    case Con{h, t} 0n: h
    case Con{h, t} 1n+p: ttf.point(t, p)

def ttf.transform(pts: List<&2, TTPoint>, +a: F32, +bb: F32, +c: F32, +d: F32, +dx: F32, +dy: F32) -> List<&2, TTPoint>:
  match pts:
    case Nil{}: Nil{}
    case Con{TTPoint{x, y, on}, rest}:
      +px = x
      +py = y
      Con{TTPoint{(a * px + c * py + dx : F32), (bb * px + d * py + dy : F32), on}, ttf.transform(rest, a, bb, c, d, dx, dy)}

def ttf.append.points(xs: List<&2, TTPoint>, ys: List<&2, TTPoint>) -> List<&2, TTPoint>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, ttf.append.points(t, ys)}

def ttf.shift.ends(ys: List<&2, U32>, +offset: U32) -> List<&2, U32>:
  match ys:
    case Nil{}: Nil{}
    case Con{h, t}: Con{(h + offset : U32), ttf.shift.ends(t, offset)}

def ttf.append.ends(xs: List<&2, U32>, ys: List<&2, U32>, +offset: U32) -> List<&2, U32>:
  match xs:
    case Nil{}: ttf.shift.ends(ys, offset)
    case Con{h, t}: Con{h, ttf.append.ends(t, ys, offset)}

def ttf.merge(parent: TTGlyph, child: TTGlyph) -> TTGlyph:
  TTGlyph{ps, pe, pc} = parent
  TTGlyph{cs, ce, cc} = child
  +n = pc
  TTGlyph{ttf.append.points(ps, cs), ttf.append.ends(pe, ce, n), (n + cc : U32)}

def ttf.xy(p: TTPoint) -> F32 & F32:
  TTPoint{x, y, on} = p
  (x, y)

def ttf.matched(pp: F32 & F32, cp: F32 & F32) -> F32 & F32:
  (px, py) = pp
  (cx, cy) = cp
  ((px - cx : F32), (py - cy : F32))

# A component's placement: an affine 2x2 with either an explicit offset or two
# matched point indices (parent point a1 meets child point a2).
type TTPlace is Data:
  TTPlace{xy: Bool, a1: F32, a2: F32, scaledOffset: Bool, a: F32, b: F32, c: F32, d: F32}

def ttf.place.identity() -> TTPlace:
  TTPlace{True{}, 0.0, 0.0, False{}, 1.0, 0.0, 0.0, 1.0}

def ttf.place.offset(+parent: TTGlyph, +child: TTGlyph, +place: TTPlace) -> F32 & F32:
  TTPlace{xy, a1, a2, scaledOffset, a, bb, c, d} = place
  +a2Dup = a2
  +a1Dup = a1
  U.branch(F32 & F32, xy,
    _ => U.choose(F32 & F32, scaledOffset, ((a * a1Dup + c * a2Dup : F32), (bb * a1Dup + d * a2Dup : F32)), (a1Dup, a2Dup)),
    _ => ttf.matched(ttf.xy(ttf.point(ttf.glyph.points(parent), U32.to_nat(F32.to_u32(a1Dup)))), ttf.xy(ttf.point(ttf.glyph.points(child), U32.to_nat(F32.to_u32(a2Dup))))))

def ttf.place.scaled(child: TTGlyph, +place: TTPlace) -> TTGlyph:
  TTGlyph{points, ends, count} = child
  TTPlace{xy, a1, a2, scaledOffset, a, bb, c, d} = place
  TTGlyph{ttf.transform(points, a, bb, c, d, 0.0, 0.0), ends, count}

def ttf.place.shifted(child: TTGlyph, off: F32 & F32) -> TTGlyph:
  TTGlyph{points, ends, count} = child
  (dx, dy) = off
  TTGlyph{ttf.transform(points, 1.0, 0.0, 0.0, 1.0, dx, dy), ends, count}

# Scale the child, then offset it (explicitly or by point matching) and append it to the parent.
def ttf.place(+parent: TTGlyph, +child: TTGlyph, +place: TTPlace) -> TTGlyph:
  +scaled = ttf.place.scaled(child, place)
  ttf.merge(parent, ttf.place.shifted(scaled, ttf.place.offset(parent, scaled, place)))

# A composite being assembled: the next component offset (0 once all are read),
# the points so far and how the finished glyph is placed into its parent.
type TTFrame is Data:
  TTFrame{at: U32, acc: TTGlyph, place: TTPlace}

def ttf.component.place(+b: Bin.Bytes, +at: U32, +flags: U32) -> TTPlace:
  +words = ttf.bit(flags, 1)
  +xy = ttf.bit(flags, 2)
  +a1 = U.choose(F32, words, U.choose(F32, xy, ttf.i16(b, (at + 4 : U32)), U32.to_f32(ttf.u16(b, (at + 4 : U32)))), U.choose(F32, xy, ttf.i8(b, (at + 4 : U32)), U32.to_f32(ttf.u8(b, (at + 4 : U32)))))
  +a2 = U.choose(F32, words, U.choose(F32, xy, ttf.i16(b, (at + 6 : U32)), U32.to_f32(ttf.u16(b, (at + 6 : U32)))), U.choose(F32, xy, ttf.i8(b, (at + 5 : U32)), U32.to_f32(ttf.u8(b, (at + 5 : U32)))))
  +at2 = (at + U.choose(U32, words, 8, 6) : U32)
  +one = ttf.bit(flags, 8)
  +two = ttf.bit(flags, 64)
  +four = ttf.bit(flags, 128)
  +sa = U.choose(F32, one || two || four, ttf.f2dot14(b, at2), 1.0)
  TTPlace{xy, a1, a2, ttf.bit(flags, 2048), sa,
    U.choose(F32, four, ttf.f2dot14(b, (at2 + 2 : U32)), 0.0),
    U.choose(F32, four, ttf.f2dot14(b, (at2 + 4 : U32)), 0.0),
    U.choose(F32, one, sa, U.choose(F32, two, ttf.f2dot14(b, (at2 + 2 : U32)), U.choose(F32, four, ttf.f2dot14(b, (at2 + 6 : U32)), 1.0)))}

# Byte offset of the component after the one at `at`, or 0 when it was the last.
def ttf.component.next(+at: U32, +flags: U32) -> U32:
  +at2 = (at + U.choose(U32, ttf.bit(flags, 1), 8, 6) : U32)
  +at3 = (at2 + U.choose(U32, ttf.bit(flags, 8), 2, U.choose(U32, ttf.bit(flags, 64), 4, U.choose(U32, ttf.bit(flags, 128), 8, 0))) : U32)
  U.choose(U32, ttf.bit(flags, 32), at3, 0)

def ttf.frame.at(+frame: TTFrame) -> U32:
  TTFrame{at, acc, place} = frame
  at

def ttf.frame.acc(+frame: TTFrame) -> TTGlyph:
  TTFrame{at, acc, place} = frame
  acc

# Pop a finished frame into its parent frame.
def ttf.assemble.pop(frame: TTFrame, parents: List<&2, TTFrame>) -> List<&2, TTFrame>:
  TTFrame{at, acc, place} = frame
  match parents:
    case Nil{}: Con{TTFrame{0, acc, place}, Nil{}}
    case Con{TTFrame{pat, pacc, pplace}, rest}: Con{TTFrame{pat, ttf.place(pacc, acc, place), pplace}, rest}

def ttf.assemble.child(+b: Bin.Bytes, +f: TTFont, frame: TTFrame, parents: List<&2, TTFrame>, loc: U32 & U32, +place: TTPlace, +next: U32) -> List<&2, TTFrame>:
  TTFrame{at, acc, fplace} = frame
  (g, len) = loc
  +gg = g
  +ac = acc
  +fp = fplace
  +ps = parents
  +contours = ttf.u16(b, gg)
  U.branch(List<&2, TTFrame>, U32.is_eq(len, 0), _ => Con{TTFrame{next, ac, fp}, ps},
    _ => U.branch(List<&2, TTFrame>, U32.is_ge(contours, 32768),
      _ => Con{TTFrame{(gg + 10 : U32), ttf.glyph.empty(), place}, Con{TTFrame{next, ac, fp}, ps}},
      _ => Con{TTFrame{next, ttf.place(ac, ttf.simple(b, gg, contours), place), fp}, ps}))

# Read the component at the frame's offset: a simple child is placed at once, a
# composite child opens a new frame above the advanced parent.
def ttf.assemble.step(+b: Bin.Bytes, +f: TTFont, frame: TTFrame, parents: List<&2, TTFrame>) -> List<&2, TTFrame>:
  TTFrame{at, acc, place} = frame
  +a = at
  +flags = ttf.u16(b, a)
  ttf.assemble.child(b, f, TTFrame{a, acc, place}, parents, ttf.location(b, f, ttf.u16(b, (a + 2 : U32))), ttf.component.place(b, a, flags), ttf.component.next(a, flags))

def ttf.assemble.next(+b: Bin.Bytes, +f: TTFont, stack: List<&2, TTFrame>) -> List<&2, TTFrame>:
  match stack:
    case Nil{}: Nil{}
    case Con{frame, parents}:
      +parentsDup = parents
      +fr = frame
      U.branch(List<&2, TTFrame>, U32.is_eq(ttf.frame.at(fr), 0), _ => ttf.assemble.pop(fr, parentsDup), _ => ttf.assemble.step(b, f, fr, parentsDup))

def ttf.stack.top(stack: List<&2, TTFrame>) -> TTGlyph:
  match stack:
    case Nil{}: ttf.glyph.empty()
    case Con{frame, parents}: ttf.frame.acc(frame)

def ttf.stack.done(stack: List<&2, TTFrame>) -> Bool:
  match stack:
    case Nil{}: True{}
    case Con{frame, Nil{}}: U32.is_eq(ttf.frame.at(frame), 0)
    case Con{frame, Con{parent, rest}}: False{}

# Iterative composite assembly over an explicit frame stack; fuel bounds the component count.
def ttf.assemble(+b: Bin.Bytes, +f: TTFont, fuel: Nat, +stack: List<&2, TTFrame>) -> TTGlyph:
  match fuel:
    case 0n: ttf.stack.top(stack)
    case 1n+d: U.branch(TTGlyph, ttf.stack.done(stack), _ => ttf.stack.top(stack), _ => ttf.assemble(b, f, d, ttf.assemble.next(b, f, stack)))

def ttf.glyph.at(+b: Bin.Bytes, +f: TTFont, loc: U32 & U32) -> TTGlyph:
  (g, len) = loc
  +gg = g
  +contours = ttf.u16(b, gg)
  U.branch(TTGlyph, U32.is_eq(len, 0), _ => ttf.glyph.empty(),
    _ => U.branch(TTGlyph, U32.is_ge(contours, 32768),
      _ => ttf.assemble(b, f, 256n, Con{TTFrame{(gg + 10 : U32), ttf.glyph.empty(), ttf.place.identity()}, Nil{}}),
      _ => ttf.simple(b, gg, contours)))

def ttf.glyph(+b: Bin.Bytes, +f: TTFont, +gid: U32) -> TTGlyph:
  ttf.glyph.at(b, f, ttf.location(b, f, gid))

# ---- outline emission (M/L/Q/Z in font units, implied on-curve midpoints inserted) ----

def ttf.pair(p: TTPoint) -> String:
  TTPoint{x, y, on} = p
  F32.show(x) ++ " " ++ F32.show(y)

def ttf.mid(a: TTPoint, b: TTPoint) -> TTPoint:
  TTPoint{ax, ay, aon} = a
  TTPoint{bx, by, bon} = b
  TTPoint{((ax + bx) / 2.0 : F32), ((ay + by) / 2.0 : F32), True{}}

def ttf.walk.on(p: TTPoint, pending: Maybe<&2, TTPoint>) -> String:
  match pending:
    case None{}: "L" ++ ttf.pair(p)
    case Some{c}: "Q" ++ ttf.pair(c) ++ " " ++ ttf.pair(p)

def ttf.walk.between(c: TTPoint, p: TTPoint) -> String:
  TTPoint{cx, cy, con} = c
  +x = cx
  +y = cy
  "Q" ++ ttf.pair(TTPoint{x, y, False{}}) ++ " " ++ ttf.pair(ttf.mid(TTPoint{x, y, False{}}, p))

# An off-curve point after another emits the implied on-curve midpoint between them.
def ttf.walk.off(p: TTPoint, pending: Maybe<&2, TTPoint>) -> String:
  match pending:
    case None{}: ""
    case Some{c}: ttf.walk.between(c, p)

def ttf.walk.close(pending: Maybe<&2, TTPoint>, +start: TTPoint) -> String:
  match pending:
    case None{}: "Z"
    case Some{c}: "Q" ++ ttf.pair(c) ++ " " ++ ttf.pair(start) ++ "Z"

def ttf.walk(pts: List<&2, TTPoint>, +pending: Maybe<&2, TTPoint>, +start: TTPoint) -> String:
  match pts:
    case Nil{}: ttf.walk.close(pending, start)
    case Con{TTPoint{x, y, on}, rest}:
      +px = x
      +py = y
      +r = rest
      U.branch(String, on,
        _ => ttf.walk.on(TTPoint{px, py, True{}}, pending) ++ ttf.walk(r, None{}, start),
        _ => ttf.walk.off(TTPoint{px, py, False{}}, pending) ++ ttf.walk(r, Some{TTPoint{px, py, False{}}}, start))

def ttf.init(pts: List<&2, TTPoint>) -> List<&2, TTPoint>:
  match pts:
    case Nil{}: Nil{}
    case Con{h, Nil{}}: Nil{}
    case Con{h, Con{g, t}}: Con{h, ttf.init(Con{g, t})}

def ttf.last.point(pts: List<&2, TTPoint>, fallback: TTPoint) -> TTPoint:
  match pts:
    case Nil{}: fallback
    case Con{h, t}: ttf.last.point(t, h)

def ttf.contour.implied(+start: TTPoint, first: TTPoint, rest: List<&2, TTPoint>) -> String:
  "M" ++ ttf.pair(start) ++ ttf.walk(Con{first, rest}, None{}, start)

# A contour starts at its first on-curve point; when the first point is off-curve,
# the last point starts it if on-curve, else the implied midpoint between last and first.
def ttf.contour.last(+first: TTPoint, +rest: List<&2, TTPoint>, last: TTPoint) -> String:
  TTPoint{lx, ly, lon} = last
  +x = lx
  +y = ly
  U.branch(String, lon,
    _ => "M" ++ ttf.pair(TTPoint{x, y, True{}}) ++ ttf.walk(Con{first, ttf.init(rest)}, None{}, TTPoint{x, y, True{}}),
    _ => ttf.contour.implied(ttf.mid(first, TTPoint{x, y, False{}}), first, rest))

def ttf.contour.off(+first: TTPoint, +rest: List<&2, TTPoint>) -> String:
  ttf.contour.last(first, rest, ttf.last.point(rest, first))

def ttf.contour(pts: List<&2, TTPoint>) -> String:
  match pts:
    case Nil{}: ""
    case Con{TTPoint{x, y, on}, rest}:
      +fx = x
      +fy = y
      +r = rest
      U.branch(String, on,
        _ => "M" ++ ttf.pair(TTPoint{fx, fy, True{}}) ++ ttf.walk(r, None{}, TTPoint{fx, fy, True{}}),
        _ => ttf.contour.off(TTPoint{fx, fy, False{}}, r))

def ttf.take(n: Nat, pts: List<&2, TTPoint>) -> List<&2, TTPoint>:
  match n pts:
    case 0n _: Nil{}
    case 1n+d Nil{}: Nil{}
    case 1n+d Con{h, t}: Con{h, ttf.take(d, t)}

def ttf.drop(n: Nat, pts: List<&2, TTPoint>) -> List<&2, TTPoint>:
  match n pts:
    case 0n _: pts
    case 1n+d Nil{}: Nil{}
    case 1n+d Con{h, t}: ttf.drop(d, t)

@unsafe
def ttf.contours(+pts: List<&2, TTPoint>, ends: List<&2, U32>, +index: U32) -> String:
  match ends:
    case Nil{}: ""
    case Con{e, more}:
      +eDup = e
      +n = U32.to_nat((eDup + 1 - index : U32))
      ttf.contour(ttf.take(n, pts)) ++ ttf.contours(ttf.drop(n, pts), more, (eDup + 1 : U32))

def ttf.outline(g: TTGlyph) -> String:
  TTGlyph{points, ends, count} = g
  ttf.contours(points, ends, 0)

# ---- GPOS pair positioning ----

# Format 1 subtables list specific glyph pairs; the first format 2 subtable supplies classes.
def ttf.pairs.empty() -> TTPairs:
  TTPairs{Nil{}, 0, 0, 0, 0}

def ttf.pairs.add1(+sub: U32, acc: TTPairs) -> TTPairs:
  TTPairs{specific, classes, coverage, class1, class2} = acc
  TTPairs{Con{sub, specific}, classes, coverage, class1, class2}

def ttf.pairs.add2(+b: Bin.Bytes, +sub: U32, acc: TTPairs) -> TTPairs:
  TTPairs{specific, classes, coverage, class1, class2} = acc
  TTPairs{specific, sub, (sub + ttf.u16(b, (sub + 2 : U32)) : U32), (sub + ttf.u16(b, (sub + 8 : U32)) : U32), (sub + ttf.u16(b, (sub + 10 : U32)) : U32)}

def ttf.pairs.unclassed(+acc: TTPairs) -> Bool:
  TTPairs{specific, classes, coverage, class1, class2} = acc
  U32.is_eq(classes, 0)

def ttf.pairs.add(+b: Bin.Bytes, +sub: U32, +acc: TTPairs) -> TTPairs:
  +format = ttf.u16(b, sub)
  U.branch(TTPairs, U32.is_eq(format, 1), _ => ttf.pairs.add1(sub, acc),
    _ => U.branch(TTPairs, U32.is_eq(format, 2) && ttf.pairs.unclassed(acc), _ => ttf.pairs.add2(b, sub, acc), _ => acc))

def ttf.pairs.any.list(specific: List<&2, U32>, +classes: U32) -> Bool:
  match specific:
    case Nil{}: U32.is_ne(classes, 0)
    case Con{h, t}: True{}

def ttf.pairs.any(+p: TTPairs) -> Bool:
  TTPairs{specific, classes, coverage, class1, class2} = p
  ttf.pairs.any.list(specific, classes)

def ttf.pairs.subtables(+b: Bin.Bytes, n: Nat, +lookup: U32, +at: U32, +kind: U32, +acc: TTPairs) -> TTPairs:
  match n:
    case 0n: acc
    case 1n+d:
      +sub = (lookup + ttf.u16(b, at) : U32)
      +extension = U32.is_eq(kind, 9)
      +actual = U.choose(U32, extension, (sub + ttf.u32(b, (sub + 4 : U32)) : U32), sub)
      +subkind = U.choose(U32, extension, ttf.u16(b, (sub + 2 : U32)), kind)
      ttf.pairs.subtables(b, d, lookup, (at + 2 : U32), kind, U.branch(TTPairs, U32.is_eq(subkind, 2), _ => ttf.pairs.add(b, actual, acc), _ => acc))

# The first lookup holding pair subtables supplies both kinds of kerning.
def ttf.pairs.lookups(+b: Bin.Bytes, n: Nat, +list: U32, +at: U32) -> TTPairs:
  match n:
    case 0n: ttf.pairs.empty()
    case 1n+d:
      +lookup = (list + ttf.u16(b, at) : U32)
      +found = ttf.pairs.subtables(b, U32.to_nat(ttf.u16(b, (lookup + 4 : U32))), lookup, (lookup + 6 : U32), ttf.u16(b, lookup), ttf.pairs.empty())
      U.branch(TTPairs, ttf.pairs.any(found), _ => found, _ => ttf.pairs.lookups(b, d, list, (at + 2 : U32)))

def ttf.pairs(+b: Bin.Bytes) -> TTPairs:
  +gpos = ttf.table(b, 1196445523)
  +list = (gpos + ttf.u16(b, (gpos + 8 : U32)) : U32)
  U.branch(TTPairs, U32.is_eq(gpos, 0), _ => ttf.pairs.empty(), _ => ttf.pairs.lookups(b, U32.to_nat(ttf.u16(b, list)), list, (list + 2 : U32)))

# Coverage index plus one (0 when absent), by binary search over sorted glyphs or ranges.
def ttf.coverage.array(+b: Bin.Bytes, fuel: Nat, +base: U32, +lo: U32, +hi: U32, +gid: U32) -> U32:
  match fuel:
    case 0n: 0
    case 1n+d:
      +dd = d
      +mid = U32.div((lo + hi : U32), 2)
      +g = ttf.u16(b, (base + mid * 2 : U32))
      U.branch(U32, U32.is_ge(lo, hi), _ => 0,
        _ => U.branch(U32, U32.is_eq(g, gid), _ => (mid + 1 : U32),
          _ => U.branch(U32, U32.is_lt(g, gid), _ => ttf.coverage.array(b, dd, base, (mid + 1 : U32), hi, gid), _ => ttf.coverage.array(b, dd, base, lo, mid, gid))))

def ttf.coverage.ranges(+b: Bin.Bytes, fuel: Nat, +base: U32, +lo: U32, +hi: U32, +gid: U32) -> U32:
  match fuel:
    case 0n: 0
    case 1n+d:
      +dd = d
      +mid = U32.div((lo + hi : U32), 2)
      +at = (base + mid * 6 : U32)
      +start = ttf.u16(b, at)
      +end = ttf.u16(b, (at + 2 : U32))
      U.branch(U32, U32.is_ge(lo, hi), _ => 0,
        _ => U.branch(U32, U32.is_lt(gid, start), _ => ttf.coverage.ranges(b, dd, base, lo, mid, gid),
          _ => U.branch(U32, U32.is_gt(gid, end), _ => ttf.coverage.ranges(b, dd, base, (mid + 1 : U32), hi, gid),
            _ => (ttf.u16(b, (at + 4 : U32)) + gid - start + 1 : U32))))

def ttf.coverage(+b: Bin.Bytes, +cov: U32, +gid: U32) -> U32:
  +count = ttf.u16(b, (cov + 2 : U32))
  U.branch(U32, U32.is_eq(cov, 0), _ => 0,
    _ => U.branch(U32, U32.is_eq(ttf.u16(b, cov), 1), _ => ttf.coverage.array(b, 20n, (cov + 4 : U32), 0, count, gid), _ => ttf.coverage.ranges(b, 20n, (cov + 4 : U32), 0, count, gid)))

def ttf.coverage.walk(+b: Bin.Bytes, n: Nat, +at: U32, +index: U32) -> U32:
  match n:
    case 0n: 0
    case 1n+d:
      +start = ttf.u16(b, at)
      +end = ttf.u16(b, (at + 2 : U32))
      +first = ttf.u16(b, (at + 4 : U32))
      U.branch(U32, U32.is_ge(index, first) && U32.is_le((index - first : U32), (end - start : U32)), _ => (start + index - first : U32), _ => ttf.coverage.walk(b, d, (at + 6 : U32), index))

# The glyph at a coverage index (format 2 walks its ranges).
def ttf.coverage.glyph(+b: Bin.Bytes, +cov: U32, +index: U32) -> U32:
  U.branch(U32, U32.is_eq(ttf.u16(b, cov), 1), _ => ttf.u16(b, (cov + 4 + index * 2 : U32)),
    _ => ttf.coverage.walk(b, U32.to_nat(ttf.u16(b, (cov + 2 : U32))), (cov + 4 : U32), index))

def ttf.classdef.ranges(+b: Bin.Bytes, fuel: Nat, +base: U32, +lo: U32, +hi: U32, +gid: U32) -> U32:
  match fuel:
    case 0n: 0
    case 1n+d:
      +dd = d
      +mid = U32.div((lo + hi : U32), 2)
      +at = (base + mid * 6 : U32)
      +start = ttf.u16(b, at)
      +end = ttf.u16(b, (at + 2 : U32))
      U.branch(U32, U32.is_ge(lo, hi), _ => 0,
        _ => U.branch(U32, U32.is_lt(gid, start), _ => ttf.classdef.ranges(b, dd, base, lo, mid, gid),
          _ => U.branch(U32, U32.is_gt(gid, end), _ => ttf.classdef.ranges(b, dd, base, (mid + 1 : U32), hi, gid), _ => ttf.u16(b, (at + 4 : U32)))))

def ttf.classdef(+b: Bin.Bytes, +cd: U32, +gid: U32) -> U32:
  +start = ttf.u16(b, (cd + 2 : U32))
  +count = ttf.u16(b, (cd + 4 : U32))
  U.branch(U32, U32.is_eq(cd, 0), _ => 0,
    _ => U.branch(U32, U32.is_eq(ttf.u16(b, cd), 1),
      _ => U.choose(U32, U32.is_ge(gid, start) && U32.is_lt((gid - start : U32), count), ttf.u16(b, (cd + 6 + (gid - start) * 2 : U32)), 0),
      _ => ttf.classdef.ranges(b, 20n, (cd + 4 : U32), 0, ttf.u16(b, (cd + 2 : U32)), gid)))

def ttf.left(+b: Bin.Bytes, +pairs: TTPairs, +gid: U32) -> U32:
  TTPairs{specific, classes, coverage, class1, class2} = pairs
  U.choose(U32, U32.is_gt(ttf.coverage(b, coverage, gid), 0), (ttf.classdef(b, class1, gid) + 1 : U32), 0)

def ttf.right(+b: Bin.Bytes, +pairs: TTPairs, +gid: U32) -> U32:
  TTPairs{specific, classes, coverage, class1, class2} = pairs
  ttf.classdef(b, class2, gid)

# ---- glyph records ----

# ---- cmap ----

def ttf.cmap.score(+platform: U32, +encoding: U32) -> U32:
  U.choose(U32, U32.is_eq(platform, 3) && U32.is_eq(encoding, 10), 6,
    U.choose(U32, U32.is_eq(platform, 0) && U32.is_eq(encoding, 6), 5,
      U.choose(U32, U32.is_eq(platform, 0) && U32.is_eq(encoding, 4), 4,
        U.choose(U32, U32.is_eq(platform, 3) && U32.is_eq(encoding, 1), 3,
          U.choose(U32, U32.is_eq(platform, 0) && U32.is_eq(encoding, 3), 2, U.choose(U32, U32.is_eq(platform, 0), 1, 0))))))

def ttf.cmap.pick(+b: Bin.Bytes, n: Nat, +cmap: U32, +at: U32, +best: U32, +score: U32) -> U32:
  match n:
    case 0n: best
    case 1n+d:
      +dd = d
      +s = ttf.cmap.score(ttf.u16(b, at), ttf.u16(b, (at + 2 : U32)))
      U.branch(U32, U32.is_gt(s, score),
        _ => ttf.cmap.pick(b, dd, cmap, (at + 8 : U32), (cmap + ttf.u32(b, (at + 4 : U32)) : U32), s),
        _ => ttf.cmap.pick(b, dd, cmap, (at + 8 : U32), best, score))

def ttf.cmap4.indexed(+g: U32, +delta: U32) -> U32:
  U.choose(U32, U32.is_eq(g, 0), 0, U32.and((g + delta : U32), 65535))

def ttf.cmap4.glyph(+b: Bin.Bytes, +cp: U32, +start: U32, +delta: U32, +roAt: U32, +ro: U32) -> U32:
  U.branch(U32, U32.is_eq(ro, 0), _ => U32.and((cp + delta : U32), 65535),
    _ => ttf.cmap4.indexed(ttf.u16(b, (roAt + ro + (cp - start) * 2 : U32)), delta))

# Glyph index of a code point through the picked subtable: a binary search over
# format 4 segments (first end code at or above the code point) or format 12 groups.
def ttf.cmap4.find(+b: Bin.Bytes, fuel: Nat, +sub: U32, +lo: U32, +hi: U32, +cp: U32) -> U32:
  match fuel:
    case 0n: lo
    case 1n+d:
      +dd = d
      +mid = U32.div((lo + hi : U32), 2)
      U.branch(U32, U32.is_ge(lo, hi), _ => lo,
        _ => U.branch(U32, U32.is_lt(ttf.u16(b, (sub + 14 + mid * 2 : U32)), cp), _ => ttf.cmap4.find(b, dd, sub, (mid + 1 : U32), hi, cp), _ => ttf.cmap4.find(b, dd, sub, lo, mid, cp)))

def ttf.cmap4.gid(+b: Bin.Bytes, +sub: U32, +cp: U32) -> U32:
  +segX2 = ttf.u16(b, (sub + 6 : U32))
  +count = U32.div(segX2, 2)
  +i = ttf.cmap4.find(b, 20n, sub, 0, count, cp)
  +start = ttf.u16(b, (sub + 16 + segX2 + i * 2 : U32))
  +delta = ttf.u16(b, (sub + 16 + segX2 * 2 + i * 2 : U32))
  +roAt = (sub + 16 + segX2 * 3 + i * 2 : U32)
  U.branch(U32, U32.is_gt(cp, 65534) || U32.is_ge(i, count) || U32.is_lt(cp, start), _ => 0, _ => ttf.cmap4.glyph(b, cp, start, delta, roAt, ttf.u16(b, roAt)))

def ttf.cmap12.find(+b: Bin.Bytes, fuel: Nat, +at: U32, +lo: U32, +hi: U32, +cp: U32) -> U32:
  match fuel:
    case 0n: lo
    case 1n+d:
      +dd = d
      +mid = U32.div((lo + hi : U32), 2)
      U.branch(U32, U32.is_ge(lo, hi), _ => lo,
        _ => U.branch(U32, U32.is_lt(ttf.u32(b, (at + mid * 12 + 4 : U32)), cp), _ => ttf.cmap12.find(b, dd, at, (mid + 1 : U32), hi, cp), _ => ttf.cmap12.find(b, dd, at, lo, mid, cp)))

def ttf.cmap12.gid(+b: Bin.Bytes, +sub: U32, +cp: U32) -> U32:
  +at = (sub + 16 : U32)
  +count = ttf.u32(b, (sub + 12 : U32))
  +i = ttf.cmap12.find(b, 40n, at, 0, count, cp)
  +start = ttf.u32(b, (at + i * 12 : U32))
  U.branch(U32, U32.is_ge(i, count) || U32.is_lt(cp, start), _ => 0, _ => (ttf.u32(b, (at + i * 12 + 8 : U32)) + cp - start : U32))

def ttf.cmap.gid(+b: Bin.Bytes, +sub: U32, +cp: U32) -> U32:
  +format = ttf.u16(b, sub)
  U.branch(U32, U32.is_eq(sub, 0), _ => 0,
    _ => U.branch(U32, U32.is_eq(format, 4), _ => ttf.cmap4.gid(b, sub, cp),
      _ => U.branch(U32, U32.is_eq(format, 12), _ => ttf.cmap12.gid(b, sub, cp), _ => 0)))

# The best Unicode subtable (formats 4 and 12), 0 when the font has none.
def ttf.cmap.subtable(+b: Bin.Bytes) -> U32:
  +cmap = ttf.table(b, 1668112752)
  U.branch(U32, U32.is_eq(cmap, 0), _ => 0, _ => ttf.cmap.pick(b, U32.to_nat(ttf.u16(b, (cmap + 2 : U32))), cmap, (cmap + 4 : U32), 0, 0))

# ---- kerning values ----

def ttf.bits(+v: U32) -> U32:
  (U32.and(v, 1) + U32.and(U32.shrn(v, 1n), 1) + U32.and(U32.shrn(v, 2n), 1) + U32.and(U32.shrn(v, 3n), 1) + U32.and(U32.shrn(v, 4n), 1) + U32.and(U32.shrn(v, 5n), 1) + U32.and(U32.shrn(v, 6n), 1) + U32.and(U32.shrn(v, 7n), 1) : U32)

# A value record holds two bytes per set format bit; XAdvance follows the two placement fields.
def ttf.value.size(+vf: U32) -> U32:
  (ttf.bits(U32.and(vf, 255)) * 2 : U32)

def ttf.xadvance(+b: Bin.Bytes, +at: U32, +vf: U32) -> F32:
  U.choose(F32, ttf.bit(vf, 4), ttf.i16(b, (at + ttf.bits(U32.and(vf, 3)) * 2 : U32)), 0.0)

# A format 1 pair set: the record whose second glyph matches, 1000000 when none.
def ttf.kern.records(+b: Bin.Bytes, n: Nat, +at: U32, +vf1: U32, +vf2: U32, +right: U32) -> F32:
  match n:
    case 0n: 1000000.0
    case 1n+d:
      U.branch(F32, U32.is_eq(ttf.u16(b, at), right), _ => ttf.xadvance(b, (at + 2 : U32), vf1),
        _ => ttf.kern.records(b, d, (at + 2 + ttf.value.size(vf1) + ttf.value.size(vf2) : U32), vf1, vf2, right))

def ttf.kern.subtable(+b: Bin.Bytes, +sub: U32, +left: U32, +right: U32) -> F32:
  +index = ttf.coverage(b, (sub + ttf.u16(b, (sub + 2 : U32)) : U32), left)
  +vf1 = ttf.u16(b, (sub + 4 : U32))
  +vf2 = ttf.u16(b, (sub + 6 : U32))
  +set = (sub + ttf.u16(b, (sub + 10 + (index - 1) * 2 : U32)) : U32)
  U.branch(F32, U32.is_eq(index, 0), _ => 1000000.0, _ => ttf.kern.records(b, U32.to_nat(ttf.u16(b, set)), (set + 2 : U32), vf1, vf2, right))

# Every format 1 subtable in turn; the first pair found wins.
def ttf.kern.specific(+b: Bin.Bytes, subs: List<&2, U32>, +left: U32, +right: U32) -> F32:
  match subs:
    case Nil{}: 1000000.0
    case Con{sub, rest}:
      +v = ttf.kern.subtable(b, sub, left, right)
      U.branch(F32, F32.is_eq(v, 1000000.0), _ => ttf.kern.specific(b, rest, left, right), _ => v)

# The format 2 class grid; leftClass counts from one (0 means uncovered).
def ttf.kern.classes(+b: Bin.Bytes, +sub: U32, +leftClass: U32, +rightClass: U32) -> F32:
  +vf1 = ttf.u16(b, (sub + 4 : U32))
  +vf2 = ttf.u16(b, (sub + 6 : U32))
  +rows = ttf.u16(b, (sub + 12 : U32))
  +columns = ttf.u16(b, (sub + 14 : U32))
  +size = (ttf.value.size(vf1) + ttf.value.size(vf2) : U32)
  U.branch(F32, U32.is_eq(sub, 0) || U32.is_eq(leftClass, 0) || U32.is_gt(leftClass, rows) || U32.is_ge(rightClass, columns), _ => 0.0,
    _ => ttf.xadvance(b, (sub + 16 + ((leftClass - 1) * columns + rightClass) * size : U32), vf1))

def ttf.kern(+fc: TTFace, +left: U32, +leftClass: U32, +right: U32, +rightClass: U32) -> F32:
  TTFace{b, f, pairs, cmap} = fc
  TTPairs{specific, classes, coverage, class1, class2} = pairs
  font.kern.value(ttf.kern.specific(b, specific, left, right), _ => ttf.kern.classes(b, classes, leftClass, rightClass))

# ---- OS/2 metrics ----

def ttf.metric(+face: U32, +name: String, +value: F32, book: FontBook) -> FontBook:
  FontBook{glyphs, kerning, metrics, faces} = book
  FontBook{glyphs, kerning, Map.set(&2, F32, metrics, U32.show(face) ++ ":" ++ name, value), faces}

def ttf.metrics(+b: Bin.Bytes, +face: U32, +os2: U32, +units: F32, book: FontBook) -> FontBook:
  +bookDup = book
  +version = ttf.u16(b, os2)
  U.branch(FontBook, U32.is_eq(os2, 0), _ => bookDup,
    _ => ttf.metric(face, "subscript", (ttf.i16(b, (os2 + 16 : U32)) / units : F32),
      ttf.metric(face, "superscript", (ttf.i16(b, (os2 + 24 : U32)) / units : F32),
        ttf.metric(face, "ascender", (ttf.i16(b, (os2 + 68 : U32)) / units : F32),
          ttf.metric(face, "descender", (ttf.i16(b, (os2 + 70 : U32)) / units : F32),
            U.branch(FontBook, U32.is_ge(version, 2), _ => ttf.metric(face, "xheight", (ttf.i16(b, (os2 + 86 : U32)) / units : F32), bookDup), _ => bookDup))))))

# Adds one face from TrueType bytes: the face record for on-demand glyphs and
# kerning, and its OS/2 metrics. Fonts without glyf/loca/hmtx leave the book unchanged.
def font.ttf(+face: U32, +b: Bin.Bytes, +book: FontBook) -> FontBook:
  FontBook{glyphs, kerning, metrics, faces} = book
  +f = ttf.font(b)
  U.branch(FontBook, ttf.valid(f),
    _ => ttf.metrics(b, face, ttf.table(b, 1330851634), ttf.units(f), FontBook{glyphs, kerning, metrics, Map.set(&2, TTFace, faces, U32.show(face), TTFace{b, f, ttf.pairs(b), ttf.cmap.subtable(b)})}),
    _ => FontBook{glyphs, kerning, metrics, faces})

def font.ttf.base64(+face: U32, +text: String, book: FontBook) -> FontBook:
  font.ttf(face, Bin.base64(text), book)

# ---- lookups ----

def font.face.absent() -> TTFace:
  TTFace{Bin.bytes.empty(), TTFont{0, 0, False{}, 0, 0, 0, 0.0}, TTPairs{Nil{}, 0, 0, 0, 0}, 0}

def font.face.result(got: Map<&2, TTFace> & TTFace) -> TTFace:
  (map, fc) = got
  fc

def font.face(+faces: Map<&2, TTFace>, +face: U32) -> TTFace:
  font.face.result(Map.get(TTFace, font.face.absent(), faces, U32.show(face)))

def font.face.present(+fc: TTFace) -> Bool:
  TTFace{b, f, pairs, cmap} = fc
  ttf.valid(f)

# A glyph read on demand: cmap to glyph index (0, the missing glyph, when
# unmapped), then advance, outline and kerning classes from the tables.
def ttf.lookup(+fc: TTFace, +ch: U32) -> FontGlyph:
  TTFace{b, f, pairs, cmap} = fc
  +gid = ttf.cmap.gid(b, cmap, ch)
  FontGlyph{ttf.advance(b, f, gid), ttf.outline(ttf.glyph(b, f, gid)), gid, ttf.left(b, pairs, gid), ttf.right(b, pairs, gid)}

def font.glyph(+book: FontBook, +face: U32, +ch: U32) -> FontGlyph:
  FontBook{glyphs, kerning, faceMetrics, faces} = book
  +fc = font.face(faces, face)
  U.branch(FontGlyph, font.face.present(fc), _ => ttf.lookup(fc, ch), _ => font.glyph.map(glyphs, face, ch))

def font.kern(+book: FontBook, +face: U32, +left: U32, +leftClass: U32, +right: U32, +rightClass: U32) -> F32:
  FontBook{glyphs, kerning, faceMetrics, faces} = book
  +fc = font.face(faces, face)
  U.branch(F32, font.face.present(fc), _ => ttf.kern(fc, left, leftClass, right, rightClass), _ => font.kern.map(kerning, face, left, leftClass, right, rightClass))
