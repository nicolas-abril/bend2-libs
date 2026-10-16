# PNG decoder: chunks, filters, interlacing, palettes and bit depths.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-bytes@0.1.0.0/bytes.bend as Bin
import gralha-image@0.1.0.0/image.bend as Img

type PNGInfo is Data:
  PNGInfo{width: U32, height: U32, depth: U32, kind: U32, interlace: U32, palette: Bin.Bytes, alpha: Bin.Bytes, compressed: Bin.Bytes, valid: Bool}

def png.empty() -> PNGInfo:
  PNGInfo{0, 0, 0, 0, 0, Bin.bytes.empty(), Bin.bytes.empty(), Bin.bytes.empty(), False{}}

def png.invalid(info: PNGInfo) -> PNGInfo:
  PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
  PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, False{}}

def png.header(+src: Bin.Bytes, +at: U32) -> PNGInfo:
  PNGInfo{Bin.bytes.be(src, at, 4n, 0), Bin.bytes.be(src, (at + 4 : U32), 4n, 0), Bin.bytes.get(src, (at + 8 : U32)), Bin.bytes.get(src, (at + 9 : U32)), Bin.bytes.get(src, (at + 12 : U32)), Bin.bytes.empty(), Bin.bytes.empty(), Bin.bytes.empty(), U32.is_eq(Bin.bytes.get(src, (at + 10 : U32)), 0) && U32.is_eq(Bin.bytes.get(src, (at + 11 : U32)), 0)}

def png.chunk(info: PNGInfo, +name: U32, +src: Bin.Bytes, +at: U32, +count: U32) -> PNGInfo:
  PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
  +pal = palette
  +trans = alpha
  +data = compressed
  PNGInfo{w, h, depth, kind, interlace,
    U.branch(Bin.Bytes, U32.is_eq(name, 1347179589), _ => Bin.bytes.slice(U32.to_nat(count), src, at, Bin.bytes.empty()), _ => pal),
    U.branch(Bin.Bytes, U32.is_eq(name, 1951551059), _ => Bin.bytes.slice(U32.to_nat(count), src, at, Bin.bytes.empty()), _ => trans),
    U.branch(Bin.Bytes, U32.is_eq(name, 1229209940), _ => Bin.bytes.slice(U32.to_nat(count), src, at, data), _ => data),
    valid && Bool.not(U32.is_eq(name, 1229472850)) && (U32.is_eq(name, 1347179589) || U32.is_eq(name, 1229209940) || U32.is_eq(U32.and(U32.shrn(name, 24n), 32), 32))}

@unsafe
def png.chunks(+src: Bin.Bytes, +at: U32, +info: PNGInfo, +table: Bin.Bytes) -> PNGInfo:
  +size = Bin.bytes.size(src)
  +count = Bin.bytes.be(src, at, 4n, 0)
  +name = Bin.bytes.be(src, (at + 4 : U32), 4n, 0)
  +next = (at + count + 12 : U32)
  U.branch(PNGInfo, U32.is_le(at, size) && U32.is_ge((size - at : U32), 12) && U32.is_le(count, (size - at - 12 : U32)),
    _ => U.branch(PNGInfo, U32.is_eq(Bin.checksum.crc.loop(U32.to_nat((count + 4 : U32)), src, (at + 4 : U32), table, 4294967295), Bin.bytes.be(src, (at + count + 8 : U32), 4n, 0)),
      _ => U.branch(PNGInfo, U32.is_eq(name, 1229278788), _ => U.choose(PNGInfo, U32.is_eq(count, 0) && U32.is_eq(next, size), info, png.invalid(info)),
        _ => png.chunks(src, next, png.chunk(info, name, src, (at + 8 : U32), count), table)), _ => png.invalid(info)), _ => png.invalid(info))

def png.info(+src: Bin.Bytes) -> PNGInfo:
  +table = Bin.checksum.crc.table(256n, 0, Bin.bytes.empty())
  U.branch(PNGInfo, U32.is_ge(Bin.bytes.size(src), 33) && U32.is_eq(Bin.bytes.be(src, 0, 4n, 0), 2303741511) && U32.is_eq(Bin.bytes.be(src, 4, 4n, 0), 218765834) && U32.is_eq(Bin.bytes.be(src, 8, 4n, 0), 13) && U32.is_eq(Bin.bytes.be(src, 12, 4n, 0), 1229472850) && U32.is_eq(Bin.checksum.crc.loop(17n, src, 12, table, 4294967295), Bin.bytes.be(src, 29, 4n, 0)),
    _ => png.chunks(src, 33, png.header(src, 16), table), _ => png.empty())

def png.channels(+kind: U32) -> U32:
  U.choose(U32, U32.is_eq(kind, 2), 3, U.choose(U32, U32.is_eq(kind, 4), 2, U.choose(U32, U32.is_eq(kind, 6), 4, 1)))

def png.depth.valid(+kind: U32, +depth: U32) -> Bool:
  +small = U32.is_eq(depth, 1) || U32.is_eq(depth, 2) || U32.is_eq(depth, 4) || U32.is_eq(depth, 8)
  U.choose(Bool, U32.is_eq(kind, 0), small || U32.is_eq(depth, 16), U.choose(Bool, U32.is_eq(kind, 3), small, (U32.is_eq(kind, 2) || U32.is_eq(kind, 4) || U32.is_eq(kind, 6)) && (U32.is_eq(depth, 8) || U32.is_eq(depth, 16))))

def png.valid(+info: PNGInfo) -> Bool:
  PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
  valid && U32.is_gt(w, 0) && U32.is_gt(h, 0) && U32.is_le(w, 2048) && U32.is_le(h, 2048) && png.depth.valid(kind, depth) && U32.is_le(interlace, 1) && (Bool.not(U32.is_eq(kind, 3)) || (U32.is_gt(Bin.bytes.size(palette), 0) && U32.is_eq(U32.mod(Bin.bytes.size(palette), 3), 0) && U32.is_le(Bin.bytes.size(palette), 768)))

def png.paeth(+a: U32, +b: U32, +c: U32) -> U32:
  +aa = U32.to_f32(a)
  +bb = U32.to_f32(b)
  +cc = U32.to_f32(c)
  +pa = F32.abs((bb - cc : F32))
  +pb = F32.abs((aa - cc : F32))
  +pc = F32.abs((aa + bb - 2.0 * cc : F32))
  U.choose(U32, F32.is_le(pa, pb) && F32.is_le(pa, pc), a, U.choose(U32, F32.is_le(pb, pc), b, c))

def png.predict(+kind: U32, +a: U32, +b: U32, +c: U32) -> U32:
  U.choose(U32, U32.is_eq(kind, 1), a, U.choose(U32, U32.is_eq(kind, 2), b, U.choose(U32, U32.is_eq(kind, 3), ((a + b) / 2 : U32), U.choose(U32, U32.is_eq(kind, 4), png.paeth(a, b, c), 0))))

def png.unfilter.row(n: Nat, +raw: Bin.Bytes, +at: U32, +x: U32, +stride: U32, +bpp: U32, +kind: U32, +out: Bin.Bytes) -> Bin.Bytes:
  match n:
    case 0n: out
    case 1n+d:
      +pos = Bin.bytes.size(out)
      +a = U.choose(U32, U32.is_ge(x, bpp), Bin.bytes.get(out, (pos - bpp : U32)), 0)
      +b = U.choose(U32, U32.is_ge(pos, stride), Bin.bytes.get(out, (pos - stride : U32)), 0)
      +c = U.choose(U32, U32.is_ge(x, bpp) && U32.is_ge(pos, stride), Bin.bytes.get(out, (pos - stride - bpp : U32)), 0)
      png.unfilter.row(d, raw, U32.inc(at), U32.inc(x), stride, bpp, kind, Bin.bytes.push(out, ((Bin.bytes.get(raw, at) + png.predict(kind, a, b, c)) % 256 : U32)))

def png.unfilter(n: Nat, +raw: Bin.Bytes, +at: U32, +stride: U32, +bpp: U32, +out: Bin.Bytes) -> Maybe<&2, Bin.Bytes>:
  match n:
    case 0n: Some{out}
    case 1n+d:
      +kind = Bin.bytes.get(raw, at)
      U.branch(Maybe<&2, Bin.Bytes>, U32.is_le(kind, 4), _ => png.unfilter(d, raw, (at + stride + 1 : U32), stride, bpp, png.unfilter.row(U32.to_nat(stride), raw, U32.inc(at), 0, stride, bpp, kind, out)), _ => None{})

def png.sample(+raw: Bin.Bytes, +row: U32, +index: U32, +depth: U32) -> U32:
  +bit = (index * depth : U32)
  +at = (row + bit / 8 : U32)
  U.branch(U32, U32.is_eq(depth, 16), _ => Bin.bytes.be(raw, at, 2n, 0), _ => U32.and(U32.shrn(Bin.bytes.get(raw, at), U32.to_nat((8 - depth - bit % 8 : U32))), (U32.shln(1, U32.to_nat(depth)) - 1 : U32)))

def png.palette(+palette: Bin.Bytes, +alpha: Bin.Bytes, +index: U32) -> Img.Color:
  +at = (index * 3 : U32)
  U.branch(Img.Color, U32.is_lt((at + 2 : U32), Bin.bytes.size(palette)),
    _ => Img.rgba((U32.to_f32(Bin.bytes.get(palette, at)) / 255.0 : F32), (U32.to_f32(Bin.bytes.get(palette, U32.inc(at))) / 255.0 : F32), (U32.to_f32(Bin.bytes.get(palette, (at + 2 : U32))) / 255.0 : F32), (U32.to_f32(U.choose(U32, U32.is_lt(index, Bin.bytes.size(alpha)), Bin.bytes.get(alpha, index), 255)) / 255.0 : F32)), _ => Img.clear())

def png.pixel(info: PNGInfo, +raw: Bin.Bytes, stride: U32, x: U32, y: U32) -> Img.Color:
  PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
  +bits = depth
  +mode = kind
  +trans = alpha
  +row = (y * stride : U32)
  +index = (x * png.channels(mode) : U32)
  +top = U32.to_f32((U32.shln(1, U32.to_nat(bits)) - 1 : U32))
  +r = png.sample(raw, row, index, bits)
  +g = png.sample(raw, row, U32.inc(index), bits)
  +b = png.sample(raw, row, (index + 2 : U32), bits)
  +a = png.sample(raw, row, (index + 3 : U32), bits)
  +gray = U32.is_eq(mode, 0) || U32.is_eq(mode, 4)
  +transparent = U.choose(Bool, gray, U32.is_eq(Bin.bytes.size(trans), 2) && U32.is_eq(r, Bin.bytes.be(trans, 0, 2n, 0)), U32.is_eq(Bin.bytes.size(trans), 6) && U32.is_eq(r, Bin.bytes.be(trans, 0, 2n, 0)) && U32.is_eq(g, Bin.bytes.be(trans, 2, 2n, 0)) && U32.is_eq(b, Bin.bytes.be(trans, 4, 2n, 0)))
  U.branch(Img.Color, U32.is_eq(mode, 3), _ => png.palette(palette, trans, r),
    _ => Img.rgba((U32.to_f32(r) / top : F32), (U32.to_f32(U.choose(U32, gray, r, g)) / top : F32), (U32.to_f32(U.choose(U32, gray, r, b)) / top : F32),
      U.choose(F32, U32.is_eq(mode, 4), (U32.to_f32(g) / top : F32), U.choose(F32, U32.is_eq(mode, 6), (U32.to_f32(a) / top : F32), U.choose(F32, transparent, 0.0, 1.0)))))

type PNGPass is Data:
  PNGPass{width: U32, height: U32, x: U32, y: U32, dx: U32, dy: U32, stride: U32, offset: U32}

def png.pass.size(+full: U32, +start: U32, +step: U32) -> U32:
  U.choose(U32, U32.is_le(full, start), 0, ((full - start + step - 1) / step : U32))

def png.pass(+w: U32, +h: U32, bits: U32, channels: U32, +index: U32, +interlaced: Bool, offset: U32) -> PNGPass:
  +x = U.choose(U32, interlaced, U.uints.nth(Con{0, Con{4, Con{0, Con{2, Con{0, Con{1, Con{0, Nil{}}}}}}}}, U32.to_nat(index), 0), 0)
  +y = U.choose(U32, interlaced, U.uints.nth(Con{0, Con{0, Con{4, Con{0, Con{2, Con{0, Con{1, Nil{}}}}}}}}, U32.to_nat(index), 0), 0)
  +dx = U.choose(U32, interlaced, U.uints.nth(Con{8, Con{8, Con{4, Con{4, Con{2, Con{2, Con{1, Nil{}}}}}}}}, U32.to_nat(index), 1), 1)
  +dy = U.choose(U32, interlaced, U.uints.nth(Con{8, Con{8, Con{8, Con{4, Con{4, Con{2, Con{2, Nil{}}}}}}}}, U32.to_nat(index), 1), 1)
  +width = png.pass.size(w, x, dx)
  PNGPass{width, png.pass.size(h, y, dy), x, y, dx, dy, ((width * channels * bits + 7) / 8 : U32), offset}

def png.pass.bytes(+pass: PNGPass) -> U32:
  PNGPass{w, h, x, y, dx, dy, stride, offset} = pass
  U.choose(U32, U32.is_eq(w, 0), 0, ((stride + 1) * h : U32))

def png.passes(n: Nat, +info: PNGInfo, +index: U32, +offset: U32) -> List<&2, PNGPass>:
  match n:
    case 0n: Nil{}
    case 1n+d:
      PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
      +pass = png.pass(w, h, depth, png.channels(kind), index, U32.is_eq(interlace, 1), offset)
      Con{pass, png.passes(d, info, U32.inc(index), (offset + png.pass.bytes(pass) : U32))}

def png.passes.bytes(xs: List<&2, PNGPass>, total: U32) -> U32:
  match xs:
    case Nil{}: total
    case Con{h, t}: png.passes.bytes(t, (total + png.pass.bytes(h) : U32))

def png.paint.row(n: Nat, +index: U32, +row: U32, +info: PNGInfo, +raw: Bin.Bytes, +pass: PNGPass, +depth: Nat, pixels: Img.Pixels) -> Img.Pixels:
  match n:
    case 0n: pixels
    case 1n+d:
      PNGPass{w, h, x, y, dx, dy, stride, offset} = pass
      png.paint.row(d, U32.inc(index), row, info, raw, pass, depth, Img.pixels.set(pixels, depth, (x + index * dx : U32), (y + row * dy : U32), png.pixel(info, raw, stride, index, row)))

def png.paint.rows(n: Nat, +row: U32, +info: PNGInfo, +raw: Bin.Bytes, +pass: PNGPass, +depth: Nat, pixels: Img.Pixels) -> Img.Pixels:
  match n:
    case 0n: pixels
    case 1n+d:
      PNGPass{w, h, x, y, dx, dy, stride, offset} = pass
      png.paint.rows(d, U32.inc(row), info, raw, pass, depth, png.paint.row(U32.to_nat(w), 0, row, info, raw, pass, depth, pixels))

def png.paint(result: Maybe<&2, Bin.Bytes>, info: PNGInfo, +pass: PNGPass, depth: Nat, pixels: Img.Pixels, next: Img.Pixels -> Maybe<&2, Img.Pixels>) -> Maybe<&2, Img.Pixels>:
  match result:
    case None{}: None{}
    case Some{raw}:
      PNGPass{w, h, x, y, dx, dy, stride, offset} = pass
      next(png.paint.rows(U32.to_nat(h), 0, info, raw, pass, depth, pixels))

@unsafe
def png.decode.passes(+xs: List<&2, PNGPass>, +info: PNGInfo, +raw: Bin.Bytes, +bpp: U32, +depth: Nat, +pixels: Img.Pixels) -> Maybe<&2, Img.Pixels>:
  match xs:
    case Nil{}: Some{pixels}
    case Con{PNGPass{w, h, x, y, dx, dy, stride, offset}, rest}:
      +pass = {PNGPass{w, h, x, y, dx, dy, stride, offset} : PNGPass}
      U.branch(Maybe<&2, Img.Pixels>, U32.is_eq(w, 0) || U32.is_eq(h, 0), _ => png.decode.passes(rest, info, raw, bpp, depth, pixels),
        _ => png.paint(png.unfilter(U32.to_nat(h), raw, offset, stride, bpp, Bin.bytes.empty()), info, pass, depth, pixels, image => png.decode.passes(rest, info, raw, bpp, depth, image)))

def png.raster(result: Maybe<&2, Img.Pixels>, w: U32, h: U32, depth: Nat) -> Img.Picture:
  match result:
    case None{}: Img.Picture{0, 0, 0n, Img.Flat{Img.clear()}}
    case Some{pixels}: Img.Picture{w, h, depth, pixels}

def png.inflate(result: Maybe<&2, Bin.Bytes>, +info: PNGInfo, passes: List<&2, PNGPass>) -> Img.Picture:
  match result:
    case None{}: Img.Picture{0, 0, 0n, Img.Flat{Img.clear()}}
    case Some{raw}:
      PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
      +dd = Img.picture.depth(U.choose(U32, U32.is_gt(w, h), w, h), 1, 0n)
      png.raster(png.decode.passes(passes, info, raw, U.choose(U32, U32.is_lt(depth, 8), 1, (png.channels(kind) * depth / 8 : U32)), dd, Img.Flat{Img.clear()}), w, h, dd)

def png.decode.info(+info: PNGInfo) -> Img.Picture:
  PNGInfo{w, h, depth, kind, interlace, palette, alpha, compressed, valid} = info
  +passes = png.passes(U.choose(Nat, U32.is_eq(interlace, 1), 7n, 1n), info, 0, 0)
  U.branch(Img.Picture, png.valid(info), _ => png.inflate(Bin.zlib(compressed, png.passes.bytes(passes, 0)), info, passes), _ => Img.Picture{0, 0, 0n, Img.Flat{Img.clear()}})

def png.decode(src: Bin.Bytes) -> Img.Picture:
  png.decode.info(png.info(src))
