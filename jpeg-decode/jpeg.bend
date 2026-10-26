# JPEG decoder: baseline and progressive Huffman, subsampling, color transforms.
import Base
import gralha-text-scan@0.1.0.1/scan.bend as U
import gralha-bytes@0.1.0.1/bytes.bend as Bin
import gralha-image@0.1.0.1/image.bend as Img

# JPEG entropy bytes are MSB-first and escape FF as FF 00.
type JPEGSpectral is Data:
  JPEGSpectral{start: U32, end: U32, high: U32, low: U32, eob: U32}

def jpeg.spectral.default() -> JPEGSpectral:
  JPEGSpectral{0, 63, 0, 0, 0}

def jpeg.spectral.eob(scan: JPEGSpectral, eob: U32) -> JPEGSpectral:
  JPEGSpectral{start, end, high, low, previous} = scan
  JPEGSpectral{start, end, high, low, eob}

type JPEGStream is Data:
  JPEGStream{data: Bin.Bytes, position: U32, word: U32, count: U32, scan: JPEGSpectral, valid: Bool}

type JPEGRead is Data:
  JPEGRead{value: U32, stream: JPEGStream}

def jpeg.stream.valid(stream: JPEGStream) -> Bool:
  JPEGStream{data, position, word, count, scan, valid} = stream
  valid

def jpeg.stream.invalid(stream: JPEGStream) -> JPEGStream:
  JPEGStream{data, position, word, count, scan, valid} = stream
  JPEGStream{data, position, word, count, scan, False{}}

def jpeg.stream.position(stream: JPEGStream) -> U32:
  JPEGStream{data, position, word, count, scan, valid} = stream
  position

def jpeg.stream.fill(+stream: JPEGStream) -> JPEGStream:
  JPEGStream{data, position, word, count, scan, valid} = stream
  +v = Bin.bytes.get(data, position)
  +escaped = U32.is_eq(v, 255)
  +next = (position + U.choose(U32, escaped, 2, 1) : U32)
  U.branch(JPEGStream, U32.is_gt(count, 0), _ => stream,
    _ => JPEGStream{data, next, v, 8, scan, valid && U32.is_le(next, Bin.bytes.size(data)) && (Bool.not(escaped) || U32.is_eq(Bin.bytes.get(data, U32.inc(position)), 0))})

def jpeg.stream.take(+stream: JPEGStream) -> JPEGRead:
  JPEGStream{data, position, word, count, scan, valid} = stream
  U.branch(JPEGRead, valid && U32.is_gt(count, 0),
    _ => JPEGRead{U32.and(U32.shrn(word, U32.to_nat((count - 1 : U32))), 1), JPEGStream{data, position, word, (count - 1 : U32), scan, valid}},
    _ => JPEGRead{0, jpeg.stream.invalid(stream)})

def jpeg.bits.next(read: JPEGRead, acc: U32, next: JPEGStream -> U32 -> JPEGRead) -> JPEGRead:
  JPEGRead{bit, stream} = read
  next(stream)((acc * 2 + bit : U32))

@unsafe
def jpeg.bits.loop(n: Nat, stream: JPEGStream, acc: U32) -> JPEGRead:
  match n:
    case 0n: JPEGRead{acc, stream}
    case 1n+d: jpeg.bits.next(jpeg.stream.take(jpeg.stream.fill(stream)), acc, input => decoded => jpeg.bits.loop(d, input, decoded))

def jpeg.bits(stream: JPEGStream, count: U32) -> JPEGRead:
  jpeg.bits.loop(U32.to_nat(count), stream, 0)

def jpeg.huff.next(read: JPEGRead, zero: Bin.Huffman, one: Bin.Huffman, next: Bin.Huffman -> JPEGStream -> JPEGRead) -> JPEGRead:
  JPEGRead{bit, stream} = read
  next(U.choose(Bin.Huffman, U32.is_eq(bit, 0), zero, one))(stream)

@unsafe
def jpeg.huff.read(node: Bin.Huffman, stream: JPEGStream) -> JPEGRead:
  match node:
    case Bin.HuffEmpty{}: JPEGRead{0, jpeg.stream.invalid(stream)}
    case Bin.HuffBad{}: JPEGRead{0, jpeg.stream.invalid(stream)}
    case Bin.HuffLeaf{symbol}: JPEGRead{symbol, stream}
    case Bin.HuffNode{zero, one}: jpeg.huff.next(jpeg.bits(stream, 1), zero, one, node => input => jpeg.huff.read(node, input))

# Quantized coefficients use two's-complement U32 storage, with explicit
# signed conversion before floating-point reconstruction.
def jpeg.signed(+value: U32) -> F32:
  U.branch(F32, U32.is_ge(value, 2147483648), _ => F32.neg(U32.to_f32((0 - value : U32))), _ => U32.to_f32(value))

def jpeg.extend(+value: U32, +count: U32) -> U32:
  +base = U32.shln(1, U32.to_nat(count))
  U.choose(U32, U32.is_gt(count, 0) && U32.is_lt(value, (base / 2 : U32)), (value + 1 - base : U32), value)

type JPEGMarker is Data:
  JPEGMarker{code: U32, position: U32, valid: Bool}

@unsafe
def jpeg.marker.byte(+src: Bin.Bytes, +at: U32) -> JPEGMarker:
  +v = Bin.bytes.get(src, at)
  U.branch(JPEGMarker, U32.is_ge(at, Bin.bytes.size(src)), _ => JPEGMarker{0, at, False{}},
    _ => U.branch(JPEGMarker, U32.is_eq(v, 255), _ => jpeg.marker.byte(src, U32.inc(at)), _ => JPEGMarker{v, U32.inc(at), Bool.not(U32.is_eq(v, 0))}))

def jpeg.marker(+src: Bin.Bytes, +at: U32) -> JPEGMarker:
  U.branch(JPEGMarker, U32.is_lt(at, Bin.bytes.size(src)) && U32.is_eq(Bin.bytes.get(src, at), 255), _ => jpeg.marker.byte(src, U32.inc(at)), _ => JPEGMarker{0, at, False{}})

def jpeg.zigzag(index: U32) -> U32:
  U.uints.nth(Con{0, Con{1, Con{8, Con{16, Con{9, Con{2, Con{3, Con{10, Con{17, Con{24, Con{32, Con{25, Con{18, Con{11, Con{4, Con{5, Con{12, Con{19, Con{26, Con{33, Con{40, Con{48, Con{41, Con{34, Con{27, Con{20, Con{13, Con{6, Con{7, Con{14, Con{21, Con{28, Con{35, Con{42, Con{49, Con{56, Con{57, Con{50, Con{43, Con{36, Con{29, Con{22, Con{15, Con{23, Con{30, Con{37, Con{44, Con{51, Con{58, Con{59, Con{52, Con{45, Con{38, Con{31, Con{39, Con{46, Con{53, Con{60, Con{61, Con{54, Con{47, Con{55, Con{62, Con{63, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}, U32.to_nat(index), 0)

def jpeg.stream.eob(stream: JPEGStream, eob: U32) -> JPEGStream:
  JPEGStream{data, position, word, count, scan, valid} = stream
  JPEGStream{data, position, word, count, jpeg.spectral.eob(scan, eob), valid}

type JPEGQuant is Data:
  JPEGQuant{id: U32, values: Bin.Bytes}

type JPEGHuff is Data:
  JPEGHuff{id: U32, ac: Bool, node: Bin.Huffman}

type JPEGComponent is Data:
  JPEGComponent{id: U32, h: U32, v: U32, quant: U32, dc: U32, ac: U32, predictor: U32, bw: U32, bh: U32, coefficients: Bin.Bytes, samples: Bin.Bytes}

type JPEGFrame is Data:
  JPEGFrame{w: U32, h: U32, hm: U32, vm: U32, progressive: Bool, components: List<&2, JPEGComponent>, quants: List<&2, JPEGQuant>, huffs: List<&2, JPEGHuff>, restart: U32, adobe: U32, valid: Bool}

def jpeg.frame.empty() -> JPEGFrame:
  JPEGFrame{0, 0, 1, 1, False{}, Nil{}, Nil{}, Nil{}, 0, 255, True{}}

def jpeg.frame.invalid(frame: JPEGFrame) -> JPEGFrame:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, False{}}

def jpeg.frame.valid(frame: JPEGFrame) -> Bool:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  valid

def jpeg.quant.find(xs: List<&2, JPEGQuant>, +id: U32) -> Bin.Bytes:
  match xs:
    case Nil{}: Bin.bytes.empty()
    case Con{JPEGQuant{key, values}, rest}: U.branch(Bin.Bytes, U32.is_eq(key, id), _ => values, _ => jpeg.quant.find(rest, id))

def jpeg.huff.find(xs: List<&2, JPEGHuff>, +id: U32, +ac: Bool) -> Bin.Huffman:
  match xs:
    case Nil{}: Bin.HuffEmpty{}
    case Con{JPEGHuff{key, kind, node}, rest}: U.branch(Bin.Huffman, U32.is_eq(key, id) && U.choose(Bool, kind, ac, Bool.not(ac)), _ => node, _ => jpeg.huff.find(rest, id, ac))

def jpeg.quant.read(n: Nat, +src: Bin.Bytes, +at: U32, +stride: U32, +index: U32, out: Bin.Bytes) -> Bin.Bytes:
  match n:
    case 0n: out
    case 1n+d: jpeg.quant.read(d, src, (at + stride : U32), stride, U32.inc(index), Bin.bytes.set(out, jpeg.zigzag(index), Bin.bytes.be(src, at, U32.to_nat(stride), 0)))

@unsafe
def jpeg.quant.segment(+src: Bin.Bytes, +at: U32, +end: U32, +frame: JPEGFrame) -> JPEGFrame:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +pq = Bin.bytes.get(src, at)
  +stride = U32.inc((pq / 16 : U32))
  +next = (at + 1 + 64 * stride : U32)
  U.branch(JPEGFrame, U32.is_eq(at, end), _ => frame,
    _ => U.branch(JPEGFrame, U32.is_gt(at, end) || U32.is_gt(pq, 19) || U32.is_gt((pq % 16 : U32), 3) || U32.is_gt(next, end), _ => jpeg.frame.invalid(frame),
      _ => jpeg.quant.segment(src, next, end, JPEGFrame{w, h, hm, vm, progressive, components, Con{JPEGQuant{(pq % 16 : U32), jpeg.quant.read(64n, src, U32.inc(at), stride, 0, Bin.bytes.zero(64))}, quants}, huffs, restart, adobe, valid})))

type JPEGCoding is Data:
  JPEGCoding{node: Bin.Huffman, code: U32, at: U32, valid: Bool}

def jpeg.huff.symbols(n: Nat, +src: Bin.Bytes, +bits: U32, +coding: JPEGCoding) -> JPEGCoding:
  match n:
    case 0n: coding
    case 1n+d:
      JPEGCoding{node, cw0, at, valid} = coding
      +cw = cw0
      jpeg.huff.symbols(d, src, bits, JPEGCoding{Bin.huff.insert(node, U32.to_nat(bits), cw, Bin.bytes.get(src, at)), U32.inc(cw), U32.inc(at), valid && U32.is_lt(cw, (U32.shln(1, U32.to_nat(bits)) - 1 : U32))})

def jpeg.huff.shift(coding: JPEGCoding) -> JPEGCoding:
  JPEGCoding{node, cw0, at, valid} = coding
  JPEGCoding{node, (cw0 * 2 : U32), at, valid}

def jpeg.huff.lengths(n: Nat, +src: Bin.Bytes, +counts: U32, +bits: U32, +coding: JPEGCoding) -> JPEGCoding:
  match n:
    case 0n: coding
    case 1n+d: jpeg.huff.lengths(d, src, U32.inc(counts), U32.inc(bits), jpeg.huff.shift(jpeg.huff.symbols(U32.to_nat(Bin.bytes.get(src, counts)), src, bits, coding)))

def jpeg.huff.install(coding: JPEGCoding, +frame: JPEGFrame, spec: U32, end: U32, next: U32 -> JPEGFrame -> JPEGFrame) -> JPEGFrame:
  JPEGCoding{node, cw0, at, ok} = coding
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +position = at
  +tag = spec
  next(position)(JPEGFrame{w, h, hm, vm, progressive, components, quants, Con{JPEGHuff{(tag % 16 : U32), U32.is_ge(tag, 16), node}, huffs}, restart, adobe, valid && ok && U32.is_le(position, end)})

@unsafe
def jpeg.huff.segment(+src: Bin.Bytes, +at: U32, +end: U32, +frame: JPEGFrame) -> JPEGFrame:
  +spec = Bin.bytes.get(src, at)
  U.branch(JPEGFrame, U32.is_eq(at, end), _ => frame,
    _ => U.branch(JPEGFrame, Bool.not(jpeg.frame.valid(frame)) || U32.is_gt((at + 17 : U32), end) || U32.is_gt(spec, 19) || U32.is_gt((spec % 16 : U32), 3), _ => jpeg.frame.invalid(frame),
      _ => jpeg.huff.install(jpeg.huff.lengths(16n, src, U32.inc(at), 1, JPEGCoding{Bin.HuffEmpty{}, 0, (at + 17 : U32), True{}}), frame, spec, end, pos => updated => jpeg.huff.segment(src, pos, end, updated))))

def jpeg.ceil(+n: U32, +d: U32) -> U32:
  ((n + d - 1) / d : U32)

def jpeg.components.read(n: Nat, +src: Bin.Bytes, +at: U32) -> List<&2, JPEGComponent>:
  match n:
    case 0n: Nil{}
    case 1n+d:
      +hv = Bin.bytes.get(src, U32.inc(at))
      Con{JPEGComponent{Bin.bytes.get(src, at), (hv / 16 : U32), (hv % 16 : U32), Bin.bytes.get(src, (at + 2 : U32)), 0, 0, 0, 0, 0, Bin.bytes.empty(), Bin.bytes.empty()}, jpeg.components.read(d, src, (at + 3 : U32))}

def jpeg.components.max(xs: List<&2, JPEGComponent>, +vertical: Bool, +acc: U32) -> U32:
  match xs:
    case Nil{}: acc
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      +val = U.choose(U32, vertical, v, h)
      jpeg.components.max(rest, vertical, U.choose(U32, U32.is_gt(val, acc), val, acc))

def jpeg.components.has(xs: List<&2, JPEGComponent>, +key: U32) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{JPEGComponent{id, _, _, _, _, _, _, _, _, _, _}, rest}: U32.is_eq(id, key) || jpeg.components.has(rest, key)

def jpeg.components.units(xs: List<&2, JPEGComponent>) -> U32:
  match xs:
    case Nil{}: 0
    case Con{JPEGComponent{_, h, v, _, _, _, _, _, _, _, _}, rest}: (h * v + jpeg.components.units(rest) : U32)

def jpeg.components.valid(+xs: List<&2, JPEGComponent>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      +hh = h
      +vv = v
      U32.is_ge(hh, 1) && U32.is_le(hh, 4) && U32.is_ge(vv, 1) && U32.is_le(vv, 4) && U32.is_le(quant, 3) && Bool.not(jpeg.components.has(rest, id)) && jpeg.components.valid(rest)

def jpeg.components.allocate(xs: List<&2, JPEGComponent>, +cols: U32, +rows: U32) -> List<&2, JPEGComponent>:
  match xs:
    case Nil{}: Nil{}
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      +hh = h
      +vv = v
      Con{JPEGComponent{id, hh, vv, quant, dc, ac, predictor, (cols * hh : U32), (rows * vv : U32), Bin.bytes.zero((cols * hh * rows * vv * 64 : U32)), Bin.bytes.zero(64)}, jpeg.components.allocate(rest, cols, rows)}

def jpeg.frame.start(+src: Bin.Bytes, +at: U32, +end: U32, +frame: JPEGFrame, +kind: U32) -> JPEGFrame:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +ww = Bin.bytes.be(src, (at + 3 : U32), 2n, 0)
  +hh = Bin.bytes.be(src, U32.inc(at), 2n, 0)
  +count = Bin.bytes.get(src, (at + 5 : U32))
  +cs = jpeg.components.read(U32.to_nat(U.choose(U32, U32.is_le(count, 4), count, 0)), src, (at + 6 : U32))
  +mh = jpeg.components.max(cs, False{}, 1)
  +mv = jpeg.components.max(cs, True{}, 1)
  +ok = valid && U32.is_eq(w, 0) && U32.is_eq(Bin.bytes.get(src, at), 8) && U32.is_gt(ww, 0) && U32.is_le(ww, 2048) && U32.is_gt(hh, 0) && U32.is_le(hh, 2048) && (U32.is_eq(count, 1) || U32.is_eq(count, 3) || U32.is_eq(count, 4)) && U32.is_eq((at + 6 + count * 3 : U32), end) && jpeg.components.valid(cs) && U32.is_le(jpeg.components.units(cs), 10)
  U.branch(JPEGFrame, ok, _ => JPEGFrame{ww, hh, mh, mv, U32.is_eq(kind, 194), jpeg.components.allocate(cs, jpeg.ceil(ww, (8 * mh : U32)), jpeg.ceil(hh, (8 * mv : U32))), quants, huffs, restart, adobe, ok}, _ => jpeg.frame.invalid(frame))

def jpeg.quant.valid(n: Nat, +index: U32, +quant: Bin.Bytes) -> Bool:
  match n:
    case 0n: U32.is_eq(Bin.bytes.size(quant), 64)
    case 1n+d: U32.is_gt(Bin.bytes.get(quant, index), 0) && jpeg.quant.valid(d, U32.inc(index), quant)

type JPEGBlock is Data:
  JPEGBlock{stream: JPEGStream, coefficients: Bin.Bytes, predictor: U32}

def jpeg.block.invalid(block: JPEGBlock) -> JPEGBlock:
  JPEGBlock{stream, coefficients, predictor} = block
  JPEGBlock{jpeg.stream.invalid(stream), coefficients, predictor}

def jpeg.progressive.dc.bits(read: JPEGRead, count: U32, coefficients: Bin.Bytes, predictor: U32, offset: U32, low: U32) -> JPEGBlock:
  JPEGRead{word, stream} = read
  +dc = (predictor + jpeg.extend(word, count) : U32)
  JPEGBlock{stream, Bin.bytes.set(coefficients, offset, U32.shln(dc, U32.to_nat(low))), dc}

def jpeg.progressive.dc.first(+read: JPEGRead, coefficients: Bin.Bytes, predictor: U32, offset: U32, low: U32) -> JPEGBlock:
  JPEGRead{count, stream} = read
  +n = count
  +ok = U32.is_le(n, 11)
  jpeg.progressive.dc.bits(jpeg.bits(U.choose(JPEGStream, ok, stream, jpeg.stream.invalid(stream)), U.choose(U32, ok, n, 0)), n, coefficients, predictor, offset, low)

def jpeg.progressive.dc.refine(read: JPEGRead, +coefficients: Bin.Bytes, predictor: U32, +offset: U32, low: U32) -> JPEGBlock:
  JPEGRead{bit, stream} = read
  JPEGBlock{stream, Bin.bytes.set(coefficients, offset, U32.or(Bin.bytes.get(coefficients, offset), U32.shln(bit, U32.to_nat(low)))), predictor}

def jpeg.progressive.ac.bits(read: JPEGRead, count: U32, coefficients: Bin.Bytes, predictor: U32, offset: U32, index: U32, low: U32) -> JPEGBlock:
  JPEGRead{word, stream} = read
  JPEGBlock{stream, Bin.bytes.set(coefficients, (offset + jpeg.zigzag(index) : U32), U32.shln(jpeg.extend(word, count), U32.to_nat(low))), predictor}

def jpeg.progressive.eob(read: JPEGRead, run: U32, coefficients: Bin.Bytes, predictor: U32, decrement: U32) -> JPEGBlock:
  JPEGRead{word, stream} = read
  JPEGBlock{jpeg.stream.eob(stream, (U32.shln(1, U32.to_nat(run)) + word - decrement : U32)), coefficients, predictor}

type JPEGRefined is Data:
  JPEGRefined{index: U32, block: JPEGBlock}

def jpeg.progressive.first.symbol(read: JPEGRead, +index: U32, +end: U32, +offset: U32, +low: U32, +coefficients: Bin.Bytes, +predictor: U32) -> JPEGRefined:
  JPEGRead{symbol, stream} = read
  +rs = symbol
  +input = stream
  +run = (rs / 16 : U32)
  +count = (rs % 16 : U32)
  +eob = U32.is_eq(count, 0) && U32.is_lt(run, 15)
  +zero = U32.is_eq(rs, 240)
  +pos = (index + run : U32)
  +ok = jpeg.stream.valid(input) && (eob || (zero && U32.is_le(pos, end)) || (U32.is_gt(count, 0) && U32.is_le(count, 10) && U32.is_le(pos, end)))
  JPEGRefined{U.choose(U32, eob || Bool.not(ok), U32.inc(end), U32.inc(pos)),
    U.branch(JPEGBlock, Bool.not(ok), _ => JPEGBlock{jpeg.stream.invalid(input), coefficients, predictor},
      _ => U.branch(JPEGBlock, eob, _ => jpeg.progressive.eob(jpeg.bits(input, run), run, coefficients, predictor, 1),
        _ => U.branch(JPEGBlock, zero, _ => JPEGBlock{input, coefficients, predictor}, _ => jpeg.progressive.ac.bits(jpeg.bits(input, count), count, coefficients, predictor, offset, pos, low))))}

def jpeg.refined.next(refined: JPEGRefined, next: U32 -> JPEGBlock -> JPEGBlock) -> JPEGBlock:
  JPEGRefined{index, block} = refined
  next(index)(block)

@unsafe
def jpeg.progressive.first(+index: U32, +end: U32, +offset: U32, +low: U32, +table: Bin.Huffman, +block: JPEGBlock) -> JPEGBlock:
  JPEGBlock{stream, coefficients, predictor} = block
  U.branch(JPEGBlock, U32.is_gt(index, end) || Bool.not(jpeg.stream.valid(stream)), _ => block,
    _ => jpeg.refined.next(jpeg.progressive.first.symbol(jpeg.huff.read(table, stream), index, end, offset, low, coefficients, predictor), pos => decoded => jpeg.progressive.first(pos, end, offset, low, table, decoded)))

def jpeg.progressive.refine.bit(read: JPEGRead, +coefficients: Bin.Bytes, predictor: U32, +at: U32, +p1: U32) -> JPEGBlock:
  JPEGRead{bit, stream} = read
  +old = Bin.bytes.get(coefficients, at)
  +negative = U32.is_ge(old, 2147483648)
  +magnitude = U.choose(U32, negative, (0 - old : U32), old)
  +adjust = U32.is_eq(bit, 1) && U32.is_eq(U32.and(magnitude, p1), 0)
  JPEGBlock{stream, Bin.bytes.set(coefficients, at, U.choose(U32, adjust, (old + U.choose(U32, negative, (0 - p1 : U32), p1) : U32), old)), predictor}

# Walk over zero positions while refining the previously nonzero coefficients.
# A new coefficient is inserted only after the requested zero run is consumed.
@unsafe
def jpeg.progressive.walk(+index: U32, +end: U32, +run: U32, +fresh: U32, +offset: U32, +p1: U32, +block: JPEGBlock) -> JPEGRefined:
  JPEGBlock{stream, coefficients, predictor} = block
  +at = (offset + jpeg.zigzag(index) : U32)
  +nonzero = Bool.not(U32.is_eq(Bin.bytes.get(coefficients, at), 0))
  +done = U32.is_gt(index, end) || (U32.is_eq(run, 0) && U32.is_eq(fresh, 0)) || Bool.not(jpeg.stream.valid(stream))
  U.branch(JPEGRefined, done, _ => JPEGRefined{index, U.choose(JPEGBlock, U32.is_gt(index, end) && Bool.not(U32.is_eq(fresh, 0)), jpeg.block.invalid(block), block)},
    _ => U.branch(JPEGRefined, nonzero,
      _ => jpeg.progressive.walk(U32.inc(index), end, run, fresh, offset, p1, jpeg.progressive.refine.bit(jpeg.bits(stream, 1), coefficients, predictor, at, p1)),
      _ => U.branch(JPEGRefined, U32.is_gt(run, 0), _ => jpeg.progressive.walk(U32.inc(index), end, (run - 1 : U32), fresh, offset, p1, block),
        _ => JPEGRefined{U32.inc(index), JPEGBlock{stream, Bin.bytes.set(coefficients, at, fresh), predictor}})))

def jpeg.progressive.refine.fresh(read: JPEGRead, index: U32, end: U32, run: U32, offset: U32, +p1: U32, coefficients: Bin.Bytes, predictor: U32) -> JPEGRefined:
  JPEGRead{bit, stream} = read
  jpeg.progressive.walk(index, end, run, U.choose(U32, U32.is_eq(bit, 1), p1, (0 - p1 : U32)), offset, p1, JPEGBlock{stream, coefficients, predictor})

def jpeg.progressive.refine.eob(block: JPEGBlock, index: U32, end: U32, offset: U32, p1: U32) -> JPEGRefined:
  jpeg.progressive.walk(index, end, 64, 0, offset, p1, block)

def jpeg.progressive.refine.symbol(read: JPEGRead, +index: U32, +end: U32, +offset: U32, +p1: U32, +coefficients: Bin.Bytes, +predictor: U32) -> JPEGRefined:
  JPEGRead{symbol, stream} = read
  +rs = symbol
  +input = stream
  +run = (rs / 16 : U32)
  +count = (rs % 16 : U32)
  +ok = jpeg.stream.valid(input) && U32.is_le(count, 1)
  U.branch(JPEGRefined, Bool.not(ok), _ => JPEGRefined{U32.inc(end), JPEGBlock{jpeg.stream.invalid(input), coefficients, predictor}},
    _ => U.branch(JPEGRefined, U32.is_eq(count, 1), _ => jpeg.progressive.refine.fresh(jpeg.bits(input, 1), index, end, run, offset, p1, coefficients, predictor),
      _ => U.branch(JPEGRefined, U32.is_eq(run, 15), _ => jpeg.progressive.walk(index, end, 16, 0, offset, p1, JPEGBlock{input, coefficients, predictor}),
        _ => jpeg.progressive.refine.eob(jpeg.progressive.eob(jpeg.bits(input, run), run, coefficients, predictor, 1), index, end, offset, p1))))

@unsafe
def jpeg.progressive.refine(+index: U32, +end: U32, +offset: U32, +p1: U32, +table: Bin.Huffman, +block: JPEGBlock) -> JPEGBlock:
  JPEGBlock{stream, coefficients, predictor} = block
  U.branch(JPEGBlock, U32.is_gt(index, end) || Bool.not(jpeg.stream.valid(stream)), _ => block,
    _ => jpeg.refined.next(jpeg.progressive.refine.symbol(jpeg.huff.read(table, stream), index, end, offset, p1, coefficients, predictor), pos => decoded => jpeg.progressive.refine(pos, end, offset, p1, table, decoded)))

def jpeg.refined.block(refined: JPEGRefined) -> JPEGBlock:
  JPEGRefined{index, block} = refined
  block

def jpeg.progressive.decode(+component: JPEGComponent, +tables: List<&2, JPEGHuff>, +offset: U32, +stream: JPEGStream) -> JPEGBlock:
  JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
  JPEGStream{data, position, word, count, JPEGSpectral{start, end, high, low, eob}, valid} = stream
  +p1 = U32.shln(1, U32.to_nat(low))
  U.branch(JPEGBlock, U32.is_eq(start, 0),
    _ => U.branch(JPEGBlock, U32.is_eq(high, 0), _ => jpeg.progressive.dc.first(jpeg.huff.read(jpeg.huff.find(tables, dc, False{}), stream), coefficients, predictor, offset, low), _ => jpeg.progressive.dc.refine(jpeg.bits(stream, 1), coefficients, predictor, offset, low)),
    _ => U.branch(JPEGBlock, U32.is_gt(eob, 0),
      _ => U.branch(JPEGBlock, U32.is_eq(high, 0), _ => JPEGBlock{jpeg.stream.eob(stream, (eob - 1 : U32)), coefficients, predictor},
        _ => jpeg.refined.block(jpeg.progressive.walk(start, end, 64, 0, offset, p1, JPEGBlock{jpeg.stream.eob(stream, (eob - 1 : U32)), coefficients, predictor}))),
      _ => U.branch(JPEGBlock, U32.is_eq(high, 0), _ => jpeg.progressive.first(start, end, offset, low, jpeg.huff.find(tables, ac, True{}), JPEGBlock{stream, coefficients, predictor}),
        _ => jpeg.progressive.refine(start, end, offset, p1, jpeg.huff.find(tables, ac, True{}), JPEGBlock{stream, coefficients, predictor}))))

def jpeg.block.dc.bits(read: JPEGRead, +count: U32, coefficients: Bin.Bytes, predictor: U32, +offset: U32) -> JPEGBlock:
  JPEGRead{word, stream} = read
  +dc = (predictor + jpeg.extend(word, count) : U32)
  JPEGBlock{stream, Bin.bytes.set(coefficients, offset, dc), dc}

def jpeg.block.dc(+read: JPEGRead, coefficients: Bin.Bytes, predictor: U32, offset: U32) -> JPEGBlock:
  JPEGRead{count, stream} = read
  +n = count
  +ok = U32.is_le(n, 11)
  jpeg.block.dc.bits(jpeg.bits(U.choose(JPEGStream, ok, stream, jpeg.stream.invalid(stream)), U.choose(U32, ok, n, 0)), n, coefficients, predictor, offset)

def jpeg.block.ac.bits(read: JPEGRead, count: U32, coefficients: Bin.Bytes, predictor: U32, offset: U32, +index: U32, next: U32 -> JPEGBlock -> JPEGBlock) -> JPEGBlock:
  JPEGRead{word, stream} = read
  next(U32.inc(index))(JPEGBlock{stream, Bin.bytes.set(coefficients, (offset + jpeg.zigzag(index) : U32), jpeg.extend(word, count)), predictor})

def jpeg.block.ac.symbol(read: JPEGRead, +coefficients: Bin.Bytes, +predictor: U32, +offset: U32, +index: U32, next: U32 -> JPEGBlock -> JPEGBlock) -> JPEGBlock:
  JPEGRead{symbol, stream} = read
  +rs = symbol
  +input = stream
  +count = (rs % 16 : U32)
  +pos = (index + rs / 16 : U32)
  +end = U32.is_eq(rs, 0)
  +zero = U32.is_eq(rs, 240)
  +ok = jpeg.stream.valid(input) && (end || (zero && U32.is_le((index + 16 : U32), 64)) || (U32.is_gt(count, 0) && U32.is_le(count, 10) && U32.is_lt(pos, 64)))
  +skip = end || Bool.not(ok)
  +result = U.branch(JPEGBlock, skip || zero, _ => JPEGBlock{U.choose(JPEGStream, ok, input, jpeg.stream.invalid(input)), coefficients, predictor},
    _ => jpeg.block.ac.bits(jpeg.bits(input, count), count, coefficients, predictor, offset, pos, _ => block => block))
  next(U.choose(U32, skip, 64, U.choose(U32, zero, (index + 16 : U32), U32.inc(pos))))(result)

@unsafe
def jpeg.block.ac(+index: U32, +table: Bin.Huffman, +offset: U32, +block: JPEGBlock) -> JPEGBlock:
  JPEGBlock{stream, coefficients, predictor} = block
  U.branch(JPEGBlock, U32.is_ge(index, 64) || Bool.not(jpeg.stream.valid(stream)), _ => block,
    _ => jpeg.block.ac.symbol(jpeg.huff.read(table, stream), coefficients, predictor, offset, index, pos => decoded => jpeg.block.ac(pos, table, offset, decoded)))

def jpeg.block.decode(+component: JPEGComponent, +tables: List<&2, JPEGHuff>, offset: U32, +stream: JPEGStream) -> JPEGBlock:
  JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
  JPEGStream{data, position, word, count, JPEGSpectral{start, end, high, low, eob}, valid} = stream
  +base = offset
  U.branch(JPEGBlock, U32.is_eq(start, 0) && U32.is_eq(end, 63),
    _ => jpeg.block.ac(1, jpeg.huff.find(tables, ac, True{}), base, jpeg.block.dc(jpeg.huff.read(jpeg.huff.find(tables, dc, False{}), stream), coefficients, predictor, base)),
    _ => jpeg.progressive.decode(component, tables, base, stream))

type JPEGPart is Data:
  JPEGPart{component: JPEGComponent, stream: JPEGStream}

def jpeg.component.block(block: JPEGBlock, component: JPEGComponent) -> JPEGPart:
  JPEGBlock{stream, coefficients, predictor} = block
  JPEGComponent{id, h, v, quant, dc, ac, old, bw, bh, previous, samples} = component
  JPEGPart{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, stream}

def jpeg.part.next(part: JPEGPart, next: JPEGComponent -> JPEGStream -> JPEGPart) -> JPEGPart:
  JPEGPart{component, stream} = part
  next(component)(stream)

@unsafe
def jpeg.component.blocks(n: Nat, +index: U32, +cols: U32, +x: U32, +y: U32, +tables: List<&2, JPEGHuff>, +component: JPEGComponent, stream: JPEGStream) -> JPEGPart:
  match n:
    case 0n: JPEGPart{component, stream}
    case 1n+d:
      JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
      +offset = (((y + index / cols) * bw + x + index % cols) * 64 : U32)
      jpeg.part.next(jpeg.component.block(jpeg.block.decode(component, tables, offset, stream), component), item => input => jpeg.component.blocks(d, U32.inc(index), cols, x, y, tables, item, input))

type JPEGScan is Data:
  JPEGScan{components: List<&2, JPEGComponent>, stream: JPEGStream}

def jpeg.scan.prepend(scan: JPEGScan, component: JPEGComponent) -> JPEGScan:
  JPEGScan{components, stream} = scan
  JPEGScan{Con{component, components}, stream}

def jpeg.scan.part(part: JPEGPart, next: JPEGStream -> JPEGScan) -> JPEGScan:
  JPEGPart{component, stream} = part
  jpeg.scan.prepend(next(stream), component)

@unsafe
def jpeg.mcu(+xs: List<&2, JPEGComponent>, +tables: List<&2, JPEGHuff>, +single: Bool, +x: U32, +y: U32, stream: JPEGStream) -> JPEGScan:
  match xs:
    case Nil{}: JPEGScan{Nil{}, stream}
    case Con{component, rest}:
      JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
      +c = {component : JPEGComponent}
      +hh = U.choose(U32, single, 1, h)
      +vv = U.choose(U32, single, 1, v)
      jpeg.scan.part(jpeg.component.blocks(U32.to_nat((hh * vv : U32)), 0, hh, (x * hh : U32), (y * vv : U32), tables, c, stream), input => jpeg.mcu(rest, tables, single, x, y, input))

def jpeg.components.reset(xs: List<&2, JPEGComponent>) -> List<&2, JPEGComponent>:
  match xs:
    case Nil{}: Nil{}
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      Con{JPEGComponent{id, h, v, quant, dc, ac, 0, bw, bh, coefficients, samples}, jpeg.components.reset(rest)}

def jpeg.restart.marker(marker: JPEGMarker, scan: JPEGScan, expected: U32) -> JPEGScan:
  JPEGMarker{tag, at, ok} = marker
  JPEGScan{components, JPEGStream{data, position, word, count, spectral, valid}} = scan
  JPEGScan{jpeg.components.reset(components), JPEGStream{data, at, 0, 0, jpeg.spectral.eob(spectral, 0), valid && ok && U32.is_eq(tag, expected)}}

def jpeg.restart(+scan: JPEGScan, expected: U32) -> JPEGScan:
  JPEGScan{components, JPEGStream{data, position, word, count, spectral, valid}} = scan
  jpeg.restart.marker(jpeg.marker(data, position), scan, expected)

def jpeg.scan.next(scan: JPEGScan, next: List<&2, JPEGComponent> -> JPEGStream -> JPEGScan) -> JPEGScan:
  JPEGScan{components, stream} = scan
  next(components)(stream)

def jpeg.scan.active(+scan: JPEGScan, next: List<&2, JPEGComponent> -> JPEGStream -> JPEGScan) -> JPEGScan:
  JPEGScan{components, stream} = scan
  U.branch(JPEGScan, jpeg.stream.valid(stream), _ => next(components)(stream), _ => scan)

@unsafe
def jpeg.mcus(n: Nat, +index: U32, +cols: U32, +single: Bool, +tables: List<&2, JPEGHuff>, +interval: U32, +scan: JPEGScan) -> JPEGScan:
  match n:
    case 0n: scan
    case 1n+d:
      +reset = U32.is_gt(interval, 0) && U32.is_gt(index, 0) && U32.is_eq((index % interval : U32), 0)
      +ready = U.branch(JPEGScan, reset, _ => jpeg.restart(scan, (208 + (index / interval - 1) % 8 : U32)), _ => scan)
      jpeg.scan.active(ready, cs => input => jpeg.scan.next(jpeg.mcu(cs, tables, single, (index % cols : U32), (index / cols : U32), input), parts => decoded => jpeg.mcus(d, U32.inc(index), cols, single, tables, interval, JPEGScan{parts, decoded})))

def jpeg.component.find(+xs: List<&2, JPEGComponent>, +id: U32) -> Maybe<&2, JPEGComponent>:
  match xs:
    case Nil{}: None{}
    case Con{component, rest}:
      JPEGComponent{key, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
      +c = {component : JPEGComponent}
      U.branch(Maybe<&2, JPEGComponent>, U32.is_eq(key, id), _ => Some{c}, _ => jpeg.component.find(rest, id))

def jpeg.component.tables(found: Maybe<&2, JPEGComponent>, spec: U32) -> JPEGComponent:
  match found:
    case None{}: JPEGComponent{255, 1, 1, 0, 4, 4, 0, 0, 0, Bin.bytes.empty(), Bin.bytes.empty()}
    case Some{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}}:
      +tag = spec
      JPEGComponent{id, h, v, quant, (tag / 16 : U32), (tag % 16 : U32), 0, bw, bh, coefficients, samples}

def jpeg.scan.select(n: Nat, +src: Bin.Bytes, +at: U32, +xs: List<&2, JPEGComponent>) -> List<&2, JPEGComponent>:
  match n:
    case 0n: Nil{}
    case 1n+d: Con{jpeg.component.tables(jpeg.component.find(xs, Bin.bytes.get(src, at)), Bin.bytes.get(src, U32.inc(at))), jpeg.scan.select(d, src, (at + 2 : U32), xs)}

def jpeg.component.or(found: Maybe<&2, JPEGComponent>, fallback: JPEGComponent) -> JPEGComponent:
  match found:
    case None{}: fallback
    case Some{component}: component

def jpeg.components.merge(+xs: List<&2, JPEGComponent>, +updated: List<&2, JPEGComponent>) -> List<&2, JPEGComponent>:
  match xs:
    case Nil{}: Nil{}
    case Con{component, rest}:
      JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
      +c = {component : JPEGComponent}
      Con{jpeg.component.or(jpeg.component.find(updated, id), c), jpeg.components.merge(rest, updated)}

def jpeg.scan.extent(xs: List<&2, JPEGComponent>, w: U32, h: U32, hm: U32, vm: U32, +vertical: Bool) -> U32:
  match xs:
    case Nil{}: 0
    case Con{JPEGComponent{id, hh, vv, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      jpeg.ceil((U.choose(U32, vertical, h, w) * U.choose(U32, vertical, vv, hh) : U32), (U.choose(U32, vertical, vm, hm) * 8 : U32))

type JPEGDecoded is Data:
  JPEGDecoded{frame: JPEGFrame, at: U32}

def jpeg.scan.complete(stream: JPEGStream) -> Bool:
  JPEGStream{data, position, word, count, JPEGSpectral{start, end, high, low, eob}, valid} = stream
  valid && U32.is_eq(eob, 0)

def jpeg.scan.finish(scan: JPEGScan, frame: JPEGFrame) -> JPEGDecoded:
  JPEGScan{updated, stream} = scan
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +input = stream
  JPEGDecoded{JPEGFrame{w, h, hm, vm, progressive, jpeg.components.merge(components, updated), quants, huffs, restart, adobe, valid && jpeg.scan.complete(input)}, jpeg.stream.position(input)}

# The sample buffer holds approximation history until IDCT replaces it.
# Zero means unseen; low+1 records the last transmitted coefficient bit.
def jpeg.history.valid(n: Nat, +index: U32, +history: Bin.Bytes, +high: U32) -> Bool:
  match n:
    case 0n: True{}
    case 1n+d: U32.is_eq(Bin.bytes.get(history, index), U.choose(U32, U32.is_eq(high, 0), 0, U32.inc(high))) && jpeg.history.valid(d, U32.inc(index), history, high)

def jpeg.history.set(n: Nat, +index: U32, +low: U32, history: Bin.Bytes) -> Bin.Bytes:
  match n:
    case 0n: history
    case 1n+d: jpeg.history.set(d, U32.inc(index), low, Bin.bytes.set(history, index, U32.inc(low)))

def jpeg.scan.ready(+xs: List<&2, JPEGComponent>, +start: U32, +end: U32, +high: U32, +quants: List<&2, JPEGQuant>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      U32.is_gt(bw, 0) && (U32.is_eq(start, 0) || U32.is_gt(Bin.bytes.get(samples, 0), 0)) && U32.is_le(dc, 3) && U32.is_le(ac, 3) && Bool.not(jpeg.components.has(rest, id)) && jpeg.quant.valid(64n, 0, jpeg.quant.find(quants, quant)) && jpeg.history.valid(U32.to_nat((end - start + 1 : U32)), start, samples, high) && jpeg.scan.ready(rest, start, end, high, quants)

def jpeg.scan.histories(xs: List<&2, JPEGComponent>, +start: U32, +end: U32, +low: U32) -> List<&2, JPEGComponent>:
  match xs:
    case Nil{}: Nil{}
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, jpeg.history.set(U32.to_nat((end - start + 1 : U32)), start, low, samples)}, jpeg.scan.histories(rest, start, end, low)}

def jpeg.scan.decode(+src: Bin.Bytes, +at: U32, +end: U32, +frame: JPEGFrame) -> JPEGDecoded:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +count = Bin.bytes.get(src, at)
  +cs = jpeg.scan.select(U32.to_nat(U.choose(U32, U32.is_le(count, 4), count, 0)), src, U32.inc(at), components)
  +single = U32.is_eq(count, 1)
  +cols = U.choose(U32, single, jpeg.scan.extent(cs, w, h, hm, vm, False{}), jpeg.ceil(w, (hm * 8 : U32)))
  +rows = U.choose(U32, single, jpeg.scan.extent(cs, w, h, hm, vm, True{}), jpeg.ceil(h, (vm * 8 : U32)))
  +ss = Bin.bytes.get(src, (end - 3 : U32))
  +se = Bin.bytes.get(src, (end - 2 : U32))
  +approx = Bin.bytes.get(src, (end - 1 : U32))
  +ah = (approx / 16 : U32)
  +al = (approx % 16 : U32)
  +sequential = U32.is_eq(ss, 0) && U32.is_eq(se, 63) && U32.is_eq(approx, 0)
  +spectral = U32.is_le(ss, se) && U32.is_le(se, 63) && U.choose(Bool, U32.is_eq(ss, 0), U32.is_eq(se, 0), single) && U32.is_le(al, 13) && (U32.is_eq(ah, 0) || U32.is_eq(ah, U32.inc(al)))
  +ok = valid && U.choose(Bool, progressive, spectral, sequential) && U32.is_gt(w, 0) && U32.is_gt(count, 0) && U32.is_le(count, 4) && U32.is_eq((at + 1 + count * 2 + 3 : U32), end)
  U.branch(JPEGDecoded, ok, _ => U.branch(JPEGDecoded, jpeg.scan.ready(cs, ss, se, ah, quants), _ => jpeg.scan.finish(jpeg.mcus(U32.to_nat((cols * rows : U32)), 0, cols, single, huffs, restart, JPEGScan{jpeg.scan.histories(cs, ss, se, al), JPEGStream{src, end, 0, 0, JPEGSpectral{ss, se, ah, al, 0}, True{}}}), frame), _ => JPEGDecoded{jpeg.frame.invalid(frame), end}), _ => JPEGDecoded{jpeg.frame.invalid(frame), end})

def jpeg.frame.misc(+frame: JPEGFrame, +src: Bin.Bytes, +at: U32, +end: U32, +tag: U32) -> JPEGFrame:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +dri = U32.is_eq(tag, 221)
  +app14 = U32.is_eq(tag, 238) && U32.is_ge((end - at : U32), 12) && U32.is_eq(Bin.bytes.be(src, at, 4n, 0), 1097101154) && U32.is_eq(Bin.bytes.get(src, (at + 4 : U32)), 101)
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, U.choose(U32, dri, Bin.bytes.be(src, at, 2n, 0), restart), U.choose(U32, app14, Bin.bytes.get(src, (at + 11 : U32)), adobe), valid && (Bool.not(dri) || U32.is_eq(end, (at + 2 : U32)))}

def jpeg.file.segment(+src: Bin.Bytes, +at: U32, +end: U32, +tag: U32, +frame: JPEGFrame) -> JPEGDecoded:
  U.branch(JPEGDecoded, U32.is_eq(tag, 218), _ => jpeg.scan.decode(src, at, end, frame),
    _ => JPEGDecoded{U.branch(JPEGFrame, U32.is_eq(tag, 219), _ => jpeg.quant.segment(src, at, end, frame),
      _ => U.branch(JPEGFrame, U32.is_eq(tag, 196), _ => jpeg.huff.segment(src, at, end, frame),
        _ => U.branch(JPEGFrame, U32.is_eq(tag, 192) || U32.is_eq(tag, 193) || U32.is_eq(tag, 194), _ => jpeg.frame.start(src, at, end, frame, tag),
          _ => U.branch(JPEGFrame, (U32.is_ge(tag, 192) && U32.is_le(tag, 207)) || U32.is_eq(tag, 220), _ => jpeg.frame.invalid(frame), _ => jpeg.frame.misc(frame, src, at, end, tag))))), end})

def jpeg.file.next(decoded: JPEGDecoded, next: U32 -> JPEGFrame -> JPEGFrame) -> JPEGFrame:
  JPEGDecoded{frame, at} = decoded
  next(at)(frame)

def jpeg.file.continue(+decoded: JPEGDecoded, stop: Bool, seen: Bool, next: U32 -> JPEGFrame -> Bool -> JPEGFrame) -> JPEGFrame:
  JPEGDecoded{frame, at} = decoded
  U.branch(JPEGFrame, stop, _ => frame, _ => next(at)(frame)(seen))

def jpeg.file.marker(marker: JPEGMarker, +src: Bin.Bytes, +frame: JPEGFrame, +seen: Bool, next: U32 -> JPEGFrame -> Bool -> JPEGFrame) -> JPEGFrame:
  JPEGMarker{tag, at, valid} = marker
  +kind = tag
  +pos = at
  +ok = valid
  +size = Bin.bytes.be(src, pos, 2n, 0)
  +end = (pos + size : U32)
  +done = U32.is_eq(kind, 217)
  +invalid = Bool.not(ok) || Bool.not(jpeg.frame.valid(frame)) || U32.is_lt(kind, 192) || (U32.is_ge(kind, 208) && U32.is_le(kind, 216)) || (Bool.not(done) && (U32.is_lt(size, 2) || U32.is_gt(end, Bin.bytes.size(src))))
  +stop = done || invalid
  +result = U.branch(JPEGDecoded, stop, _ => JPEGDecoded{U.choose(JPEGFrame, done && seen && Bool.not(invalid), frame, jpeg.frame.invalid(frame)), pos}, _ => jpeg.file.segment(src, (pos + 2 : U32), end, kind, frame))
  jpeg.file.continue(result, stop, seen || U32.is_eq(kind, 218), next)

@unsafe
def jpeg.file(+src: Bin.Bytes, +at: U32, frame: JPEGFrame, seen: Bool) -> JPEGFrame:
  jpeg.file.marker(jpeg.marker(src, at), src, frame, seen, pos => parsed => scanned => jpeg.file(src, pos, parsed, scanned))

def jpeg.info(+src: Bin.Bytes) -> JPEGFrame:
  U.branch(JPEGFrame, U32.is_eq(Bin.bytes.be(src, 0, 2n, 0), 65496), _ => jpeg.file(src, 2, jpeg.frame.empty(), False{}), _ => jpeg.frame.invalid(jpeg.frame.empty()))

# Separable, normalized 8x8 inverse DCT. Coefficients remain quantized until
# every sequential scan has been decoded; each component has a padded plane.
def jpeg.idct.basis(+x: U32, +u: U32) -> F32:
  +k = ((2 * x + 1) * u % 32 : U32)
  +fold = U.choose(U32, U32.is_gt(k, 16), (32 - k : U32), k)
  +negative = U32.is_gt(fold, 8)
  +i = U.choose(U32, negative, (16 - fold : U32), fold)
  +cosine = U.nth(Con{1.0, Con{0.9807852804032304, Con{0.9238795325112867, Con{0.8314696123025452, Con{0.7071067811865476, Con{0.5555702330196023, Con{0.3826834323650898, Con{0.1950903220161283, Con{0.0, Nil{}}}}}}}}}}, U32.to_nat(i), 0.0)
  (0.5 * U.choose(F32, U32.is_eq(u, 0), 0.7071067811865476, 1.0) * U.choose(F32, negative, F32.neg(cosine), cosine) : F32)

def jpeg.idct.horizontal(n: Nat, +u: U32, +x: U32, +row: U32, +offset: U32, +coefficients: Bin.Bytes, +quant: Bin.Bytes, acc: F32) -> F32:
  match n:
    case 0n: acc
    case 1n+d:
      +i = (row * 8 + u : U32)
      jpeg.idct.horizontal(d, U32.inc(u), x, row, offset, coefficients, quant, (acc + jpeg.signed(Bin.bytes.get(coefficients, (offset + i : U32))) * U32.to_f32(Bin.bytes.get(quant, i)) * jpeg.idct.basis(x, u) : F32))

def jpeg.idct.rows(n: Nat, +index: U32, +offset: U32, +coefficients: Bin.Bytes, +quant: Bin.Bytes) -> List<&2, F32>:
  match n:
    case 0n: Nil{}
    case 1n+d: Con{jpeg.idct.horizontal(8n, 0, (index % 8 : U32), (index / 8 : U32), offset, coefficients, quant, 0.0), jpeg.idct.rows(d, U32.inc(index), offset, coefficients, quant)}

def jpeg.idct.vertical(n: Nat, +v: U32, +x: U32, +y: U32, +rows: List<&2, F32>, acc: F32) -> F32:
  match n:
    case 0n: acc
    case 1n+d: jpeg.idct.vertical(d, U32.inc(v), x, y, rows, (acc + U.nth(rows, U32.to_nat((v * 8 + x : U32)), 0.0) * jpeg.idct.basis(y, v) : F32))

def jpeg.idct.pixels(n: Nat, +index: U32, +x: U32, +y: U32, +stride: U32, +rows: List<&2, F32>, out: Bin.Bytes) -> Bin.Bytes:
  match n:
    case 0n: out
    case 1n+d:
      +xx = (index % 8 : U32)
      +yy = (index / 8 : U32)
      jpeg.idct.pixels(d, U32.inc(index), x, y, stride, rows, Bin.bytes.set(out, ((y + yy) * stride + x + xx : U32), F32.to_u32(U.clamp(F32.floor((jpeg.idct.vertical(8n, 0, xx, yy, rows, 0.0) + 128.5 : F32)), 0.0, 255.0))))

def jpeg.idct.blocks(n: Nat, +index: U32, +cols: U32, +coefficients: Bin.Bytes, +quant: Bin.Bytes, out: Bin.Bytes) -> Bin.Bytes:
  match n:
    case 0n: out
    case 1n+d: jpeg.idct.blocks(d, U32.inc(index), cols, coefficients, quant, jpeg.idct.pixels(64n, 0, (index % cols * 8 : U32), (index / cols * 8 : U32), (cols * 8 : U32), jpeg.idct.rows(64n, 0, (index * 64 : U32), coefficients, quant), out))

def jpeg.idct.components(xs: List<&2, JPEGComponent>, +quants: List<&2, JPEGQuant>) -> List<&2, JPEGComponent>:
  match xs:
    case Nil{}: Nil{}
    case Con{JPEGComponent{id, h, v, quant, dc, ac, predictor, bw, bh, coefficients, samples}, rest}:
      +cs = coefficients
      +qq = quant
      +ww = bw
      +hh = bh
      Con{JPEGComponent{id, h, v, qq, dc, ac, predictor, ww, hh, cs, jpeg.idct.blocks(U32.to_nat((ww * hh : U32)), 0, ww, cs, jpeg.quant.find(quants, qq), Bin.bytes.zero((ww * hh * 64 : U32)))}, jpeg.idct.components(rest, quants)}

def jpeg.sample.byte(+samples: Bin.Bytes, +stride: U32, +x: U32, +y: U32) -> F32:
  U32.to_f32(Bin.bytes.get(samples, (y * stride + x : U32)))

def jpeg.sample(component: JPEGComponent, +w: U32, +h: U32, +hm: U32, +vm: U32, +x: U32, +y: U32) -> F32:
  JPEGComponent{id, ch, cv, quant, dc, ac, predictor, bw, bh, coefficients, samples} = component
  +hh = ch
  +vv = cv
  +data = samples
  +stride = (bw * 8 : U32)
  +width = jpeg.ceil((w * hh : U32), hm)
  +height = jpeg.ceil((h * vv : U32), vm)
  # libjpeg's horizontally doubled narrow planes use box reconstruction.
  +box = U32.is_eq((hh * 2 : U32), hm) && U32.is_le(width, 2) && (U32.is_eq(vv, vm) || U32.is_eq((vv * 2 : U32), vm))
  +px = U.choose(F32, box, U32.to_f32((x * hh / hm : U32)), U.clamp(((U32.to_f32(x) + 0.5) * U32.to_f32(hh) / U32.to_f32(hm) - 0.5 : F32), 0.0, U32.to_f32((width - 1 : U32))))
  +py = U.choose(F32, box, U32.to_f32((y * vv / vm : U32)), U.clamp(((U32.to_f32(y) + 0.5) * U32.to_f32(vv) / U32.to_f32(vm) - 0.5 : F32), 0.0, U32.to_f32((height - 1 : U32))))
  +x0 = F32.to_u32(F32.floor(px))
  +y0 = F32.to_u32(F32.floor(py))
  +x1 = U.choose(U32, U32.is_lt(U32.inc(x0), width), U32.inc(x0), x0)
  +y1 = U.choose(U32, U32.is_lt(U32.inc(y0), height), U32.inc(y0), y0)
  +fx = (px - U32.to_f32(x0) : F32)
  +fy = (py - U32.to_f32(y0) : F32)
  (jpeg.sample.byte(data, stride, x0, y0) * (1.0 - fx) * (1.0 - fy) + jpeg.sample.byte(data, stride, x1, y0) * fx * (1.0 - fy) + jpeg.sample.byte(data, stride, x0, y1) * (1.0 - fx) * fy + jpeg.sample.byte(data, stride, x1, y1) * fx * fy : F32)

def jpeg.sample.channels(xs: List<&2, JPEGComponent>, +w: U32, +h: U32, +hm: U32, +vm: U32, +x: U32, +y: U32) -> List<&2, F32>:
  match xs:
    case Nil{}: Nil{}
    case Con{c, rest}: Con{jpeg.sample(c, w, h, hm, vm, x, y), jpeg.sample.channels(rest, w, h, hm, vm, x, y)}

def jpeg.channel(x: F32) -> F32:
  (U.clamp(F32.floor((x + 0.5 : F32)), 0.0, 255.0) / 255.0 : F32)

def jpeg.ycbcr(+y: F32, +cb: F32, +cr: F32) -> Img.Color:
  Img.Color{jpeg.channel((y + 1.402 * (cr - 128.0) : F32)), jpeg.channel((y - 0.344136 * (cb - 128.0) - 0.714136 * (cr - 128.0) : F32)), jpeg.channel((y + 1.772 * (cb - 128.0) : F32)), 1.0}

def jpeg.ycck(c: Img.Color, +k: F32) -> Img.Color:
  Img.Color{r, g, b, a} = c
  Img.Color{jpeg.channel(((1.0 - r) * k : F32)), jpeg.channel(((1.0 - g) * k : F32)), jpeg.channel(((1.0 - b) * k : F32)), 1.0}

def jpeg.rgb.ids(xs: List<&2, JPEGComponent>) -> Bool:
  match xs:
    case Con{JPEGComponent{a, _, _, _, _, _, _, _, _, _, _}, Con{JPEGComponent{b, _, _, _, _, _, _, _, _, _, _}, Con{JPEGComponent{c, _, _, _, _, _, _, _, _, _, _}, Nil{}}}}: U32.is_eq(a, 82) && U32.is_eq(b, 71) && U32.is_eq(c, 66)
    case _: False{}

def jpeg.color(xs: List<&2, F32>, +adobe: U32) -> Img.Color:
  match xs:
    case Con{gray, Nil{}}:
      +v = jpeg.channel(gray)
      Img.Color{v, v, v, 1.0}
    case Con{a, Con{b, Con{c, Nil{}}}}:
      +aa = a
      +bb = b
      +cc = c
      U.choose(Img.Color, U32.is_eq(adobe, 0), Img.Color{jpeg.channel(aa), jpeg.channel(bb), jpeg.channel(cc), 1.0}, jpeg.ycbcr(aa, bb, cc))
    case Con{a, Con{b, Con{c, Con{k, Nil{}}}}}:
      +aa = a
      +bb = b
      +cc = c
      +kk = k
      U.branch(Img.Color, U32.is_eq(adobe, 2), _ => jpeg.ycck(jpeg.ycbcr(aa, bb, cc), kk),
        _ => Img.Color{jpeg.channel((aa * kk / 255.0 : F32)), jpeg.channel((bb * kk / 255.0 : F32)), jpeg.channel((cc * kk / 255.0 : F32)), 1.0})
    case _: Img.clear()

def jpeg.paint(n: Nat, +index: U32, +w: U32, +h: U32, +hm: U32, +vm: U32, +components: List<&2, JPEGComponent>, +adobe: U32, +depth: Nat, out: Img.Pixels) -> Img.Pixels:
  match n:
    case 0n: out
    case 1n+d:
      +x = (index % w : U32)
      +y = (index / w : U32)
      jpeg.paint(d, U32.inc(index), w, h, hm, vm, components, adobe, depth, Img.pixels.set(out, depth, x, y, jpeg.color(jpeg.sample.channels(components, w, h, hm, vm, x, y), adobe)))

def jpeg.components.complete(xs: List<&2, JPEGComponent>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{JPEGComponent{_, _, _, _, _, _, _, _, _, _, samples}, rest}: U32.is_gt(Bin.bytes.get(samples, 0), 0) && jpeg.components.complete(rest)

def jpeg.decode.frame(+frame: JPEGFrame) -> Img.Picture:
  JPEGFrame{w, h, hm, vm, progressive, components, quants, huffs, restart, adobe, valid} = frame
  +depth = Img.picture.depth(U.choose(U32, U32.is_gt(w, h), w, h), 1, 0n)
  U.branch(Img.Picture, valid && U32.is_gt(w, 0) && U32.is_gt(h, 0) && jpeg.components.complete(components),
    _ => Img.Picture{w, h, depth, jpeg.paint(U32.to_nat((w * h : U32)), 0, w, h, hm, vm, jpeg.idct.components(components, quants), U.choose(U32, U32.is_eq(adobe, 255) && jpeg.rgb.ids(components), 0, adobe), depth, Img.Flat{Img.clear()})}, _ => Img.picture.blank())

def jpeg.decode(src: Bin.Bytes) -> Img.Picture:
  jpeg.decode.frame(jpeg.info(src))
