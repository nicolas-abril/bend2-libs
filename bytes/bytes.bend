# Bytes, bit streams, Huffman codes, DEFLATE/zlib, checksums, base64 and percent decoding.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U

# A Bytes is a persistent byte buffer: a balanced tree over a power-of-two capacity.
# A flat leaf is one value per index (decoders keep whole words in a Bytes, and
# a flat above the leaf level is a uniform run); a word leaf packs four bytes
# little-endian, which is how the file effect builds a tree with a quarter of
# the nodes and two levels fewer to descend. Each leaf carries its own reading.
type ByteTree is Data:
  ByteFlat{value: U32}
  ByteWord{value: U32}
  ByteNode{left: ByteTree, right: ByteTree}

def bytes.lane(+index: U32) -> U32:
  +k = U32.mod(index, 4)
  U.choose(U32, U32.is_eq(k, 0), 1, U.choose(U32, U32.is_eq(k, 1), 256, U.choose(U32, U32.is_eq(k, 2), 65536, 16777216)))

def bytes.word.get(+word: U32, +index: U32) -> U32:
  U32.mod(U32.div(word, bytes.lane(index)), 256)

def bytes.word.put(+word: U32, +index: U32, +v: U32) -> U32:
  +lane = bytes.lane(index)
  (word - U32.mod(U32.div(word, lane), 256) * lane + v * lane : U32)

type Bytes is Data:
  Bytes{bufTree: ByteTree, size: U32, capacity: U32}

def bytes.empty() -> Bytes:
  Bytes{ByteFlat{0}, 0, 1}

@unsafe
def bytes.tree.get(bufTree: ByteTree, +capacity: U32, +index: U32) -> U32:
  match bufTree:
    case ByteFlat{v}: v
    case ByteWord{v}: bytes.word.get(v, index)
    case ByteNode{left, right}:
      +half = (capacity / 2 : U32)
      bytes.tree.get(U.choose(ByteTree, U32.is_lt(index, half), left, right), half, U32.mod(index, half))

@unsafe
def bytes.tree.set(+bufTree: ByteTree, +capacity: U32, +index: U32, +v: U32) -> ByteTree:
  match bufTree:
    case ByteFlat{old}:
      U.branch(ByteTree, U32.is_le(capacity, 1), _ => ByteFlat{v}, _ => bytes.tree.set(ByteNode{ByteFlat{old}, ByteFlat{old}}, capacity, index, v))
    case ByteWord{old}:
      U.branch(ByteTree, U32.is_le(capacity, 4), _ => ByteWord{bytes.word.put(old, index, v)}, _ => bytes.tree.set(ByteNode{ByteWord{old}, ByteWord{old}}, capacity, index, v))
    case ByteNode{left, right}:
      +half = (capacity / 2 : U32)
      U.branch(ByteTree, U32.is_lt(index, half), _ => ByteNode{bytes.tree.set(left, half, index, v), right}, _ => ByteNode{left, bytes.tree.set(right, half, (index - half : U32), v)})

def bytes.get(bytes: Bytes, +index: U32) -> U32:
  Bytes{bufTree, size, capacity} = bytes
  U.branch(U32, U32.is_lt(index, size), _ => bytes.tree.get(bufTree, capacity, index), _ => 0)

def bytes.size(bytes: Bytes) -> U32:
  Bytes{bufTree, size, capacity} = bytes
  size

def bytes.set(+bytes: Bytes, +index: U32, v: U32) -> Bytes:
  Bytes{bufTree, size, capacity} = bytes
  Bytes{bytes.tree.set(bufTree, capacity, index, v), size, capacity}

def bytes.push(bytes: Bytes, +v: U32) -> Bytes:
  Bytes{bufTree, size, capacity} = bytes
  +data = bufTree
  +n = size
  +cap = capacity
  +grow = U32.is_eq(n, cap)
  +newcap = U.choose(U32, grow, (cap * 2 : U32), cap)
  Bytes{bytes.tree.set(U.choose(ByteTree, grow, ByteNode{data, ByteFlat{0}}, data), newcap, n, v), U32.inc(n), newcap}

def bytes.string(s: String, acc: Bytes) -> Bytes:
  match s:
    case SNil{}: acc
    case SCon{Chr{c}, t}: bytes.string(t, bytes.push(acc, c))

def bytes.slice(n: Nat, +source: Bytes, +start: U32, target: Bytes) -> Bytes:
  match n:
    case 0n: target
    case 1n+d: bytes.slice(d, source, U32.inc(start), bytes.push(target, bytes.get(source, start)))

@unsafe
def bytes.be(+bytes: Bytes, +at: U32, count: Nat, acc: U32) -> U32:
  match count:
    case 0n: acc
    case 1n+d: bytes.be(bytes, U32.inc(at), d, (acc * 256 + bytes.get(bytes, at) : U32))

def base64.digit(+c: U32) -> U32:
  U.choose(U32, U32.is_ge(c, 65) && U32.is_le(c, 90), (c - 65 : U32),
    U.choose(U32, U32.is_ge(c, 97) && U32.is_le(c, 122), (c - 71 : U32),
      U.choose(U32, U32.is_ge(c, 48) && U32.is_le(c, 57), (c + 4 : U32), U.choose(U32, U32.is_eq(c, 43), 62, U.choose(U32, U32.is_eq(c, 47), 63, 64)))))

def base64.read(+s: String, +bits: U32, +count: U32, +out: Bytes) -> Bytes:
  match s:
    case SNil{}: out
    case SCon{Chr{c}, t}:
      +v = base64.digit(c)
      +n = (count + 6 : U32)
      +word = (bits * 64 + v : U32)
      U.branch(Bytes, U32.is_eq(c, 61), _ => out,
        _ => U.branch(Bytes, U.space(c), _ => base64.read(t, bits, count, out),
          _ => U.branch(Bytes, U32.is_lt(v, 64), _ => U.branch(Bytes, U32.is_ge(n, 8),
            _ => base64.read(t, U32.mod(word, U32.shln(1, U32.to_nat((n - 8 : U32)))), (n - 8 : U32), bytes.push(out, U32.shrn(word, U32.to_nat((n - 8 : U32))))),
            _ => base64.read(t, word, n, out)), _ => bytes.empty())))

def base64(s: String) -> Bytes:
  base64.read(s, 0, 0, bytes.empty())

type BitStream is Data:
  BitStream{data: Bytes, position: U32, limit: U32, valid: Bool}

type BitRead is Data:
  BitRead{value: U32, stream: BitStream}

def bits.read(stream: BitStream, +count: U32) -> BitRead:
  BitStream{data, position, limit, valid} = stream
  +src = data
  +pos = position
  +end = limit
  +at = (pos / 8 : U32)
  +word = (bytes.get(src, at) + bytes.get(src, U32.inc(at)) * 256 + bytes.get(src, (at + 2 : U32)) * 65536 : U32)
  BitRead{U32.and(U32.shrn(word, U32.to_nat(U32.mod(pos, 8))), (U32.shln(1, U32.to_nat(count)) - 1 : U32)), BitStream{src, (pos + count : U32), end, valid && U32.is_le((pos + count : U32), end)}}

def bits.valid(stream: BitStream) -> Bool:
  BitStream{data, position, limit, valid} = stream
  valid && U32.is_le(position, limit)

def bits.invalid(stream: BitStream) -> BitStream:
  BitStream{data, position, limit, valid} = stream
  BitStream{data, position, limit, False{}}

def bits.align(+stream: BitStream) -> BitStream:
  BitStream{data, position, limit, valid} = stream
  +pos = (((position + 7) / 8) * 8 : U32)
  BitStream{data, pos, limit, valid && U32.is_le(pos, limit)}

type Huffman is Data:
  HuffEmpty{}
  HuffBad{}
  HuffLeaf{symbol: U32}
  HuffNode{zero: Huffman, one: Huffman}

@unsafe
def huff.insert(+node: Huffman, +depth: Nat, +codeword: U32, +symbol: U32) -> Huffman:
  match node:
    case HuffBad{}: HuffBad{}
    case HuffLeaf{old}: HuffBad{}
    case HuffEmpty{}:
      match depth:
        case 0n: HuffLeaf{symbol}
        case 1n+d: huff.insert(HuffNode{HuffEmpty{}, HuffEmpty{}}, 1n+d, codeword, symbol)
    case HuffNode{zero, one}:
      match depth:
        case 0n: HuffBad{}
        case 1n+d:
          +dd = d
          U.branch(Huffman, U32.is_eq(U32.and(codeword, U32.shln(1, dd)), 0), _ => HuffNode{huff.insert(zero, dd, codeword, symbol), one}, _ => HuffNode{zero, huff.insert(one, dd, codeword, symbol)})

def huff.counts(n: Nat, +lengths: Bytes, +index: U32, +counts: Bytes) -> Bytes:
  match n:
    case 0n: counts
    case 1n+d:
      +len = bytes.get(lengths, index)
      huff.counts(d, lengths, U32.inc(index), U.choose(Bytes, U32.is_gt(len, 0) && U32.is_le(len, 15), bytes.set(counts, len, U32.inc(bytes.get(counts, len))), counts))

def huff.codes(n: Nat, +counts: Bytes, +length: U32, codeword: U32, codes: Bytes) -> Bytes:
  match n:
    case 0n: codes
    case 1n+d:
      +next = ((codeword + bytes.get(counts, (length - 1 : U32))) * 2 : U32)
      huff.codes(d, counts, U32.inc(length), next, bytes.push(codes, next))

def huff.build.loop(+n: Nat, +lengths: Bytes, +index: U32, +codes: Bytes, +node: Huffman) -> Huffman:
  match n:
    case 0n: node
    case 1n+d:
      +len = bytes.get(lengths, index)
      +word = bytes.get(codes, len)
      U.branch(Huffman, U32.is_eq(len, 0), _ => huff.build.loop(d, lengths, U32.inc(index), codes, node),
        _ => U.branch(Huffman, U32.is_le(len, 15) && U32.is_lt(word, U32.shln(1, U32.to_nat(len))), _ => huff.build.loop(d, lengths, U32.inc(index), bytes.set(codes, len, U32.inc(word)), huff.insert(node, U32.to_nat(len), word, index)), _ => HuffBad{}))

def huff.build(+lengths: Bytes) -> Huffman:
  +n = U32.to_nat(bytes.size(lengths))
  +counts = huff.counts(n, lengths, 0, Bytes{ByteFlat{0}, 16, 16})
  huff.build.loop(n, lengths, 0, huff.codes(15n, counts, 1, 0, bytes.push(bytes.empty(), 0)), HuffEmpty{})

def huff.read.next(read: BitRead, zero: Huffman, one: Huffman, next: Huffman -> BitStream -> BitRead) -> BitRead:
  BitRead{bit, stream} = read
  next(U.choose(Huffman, U32.is_eq(bit, 0), zero, one))(stream)

@unsafe
def huff.read(node: Huffman, +stream: BitStream) -> BitRead:
  match node:
    case HuffEmpty{}: BitRead{0, bits.invalid(stream)}
    case HuffBad{}: BitRead{0, bits.invalid(stream)}
    case HuffLeaf{symbol}: BitRead{symbol, stream}
    case HuffNode{zero, one}: huff.read.next(bits.read(stream, 1), zero, one, node => input => huff.read(node, input))

def huff.fixed.lengths(n: Nat, +index: U32, out: Bytes) -> Bytes:
  match n:
    case 0n: out
    case 1n+d: huff.fixed.lengths(d, U32.inc(index), bytes.push(out, U.choose(U32, U32.is_lt(index, 144), 8, U.choose(U32, U32.is_lt(index, 256), 9, U.choose(U32, U32.is_lt(index, 280), 7, 8)))))

def bytes.repeat(n: Nat, +v: U32, out: Bytes) -> Bytes:
  match n:
    case 0n: out
    case 1n+d: bytes.repeat(d, v, bytes.push(out, v))

def inflate.length.base(index: U32) -> U32:
  U.uints.nth(Con{3, Con{4, Con{5, Con{6, Con{7, Con{8, Con{9, Con{10, Con{11, Con{13, Con{15, Con{17, Con{19, Con{23, Con{27, Con{31, Con{35, Con{43, Con{51, Con{59, Con{67, Con{83, Con{99, Con{115, Con{131, Con{163, Con{195, Con{227, Con{258, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}, U32.to_nat(index), 0)

def inflate.length.bits(index: U32) -> U32:
  U.uints.nth(Con{0, Con{0, Con{0, Con{0, Con{0, Con{0, Con{0, Con{0, Con{1, Con{1, Con{1, Con{1, Con{2, Con{2, Con{2, Con{2, Con{3, Con{3, Con{3, Con{3, Con{4, Con{4, Con{4, Con{4, Con{5, Con{5, Con{5, Con{5, Con{0, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}, U32.to_nat(index), 0)

def inflate.distance.base(index: U32) -> U32:
  U.uints.nth(Con{1, Con{2, Con{3, Con{4, Con{5, Con{7, Con{9, Con{13, Con{17, Con{25, Con{33, Con{49, Con{65, Con{97, Con{129, Con{193, Con{257, Con{385, Con{513, Con{769, Con{1025, Con{1537, Con{2049, Con{3073, Con{4097, Con{6145, Con{8193, Con{12289, Con{16385, Con{24577, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}, U32.to_nat(index), 0)

def inflate.distance.bits(index: U32) -> U32:
  U.uints.nth(Con{0, Con{0, Con{0, Con{0, Con{1, Con{1, Con{2, Con{2, Con{3, Con{3, Con{4, Con{4, Con{5, Con{5, Con{6, Con{6, Con{7, Con{7, Con{8, Con{8, Con{9, Con{9, Con{10, Con{10, Con{11, Con{11, Con{12, Con{12, Con{13, Con{13, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}, U32.to_nat(index), 0)

def inflate.code.order(index: U32) -> U32:
  U.uints.nth(Con{16, Con{17, Con{18, Con{0, Con{8, Con{7, Con{9, Con{6, Con{10, Con{5, Con{11, Con{4, Con{12, Con{3, Con{13, Con{2, Con{14, Con{1, Con{15, Nil{}}}}}}}}}}}}}}}}}}}}, U32.to_nat(index), 0)

type Inflate is Data:
  Inflate{stream: BitStream, output: Bytes}

def inflate.copy(n: Nat, +distance: U32, +out: Bytes) -> Bytes:
  match n:
    case 0n: out
    case 1n+d: inflate.copy(d, distance, bytes.push(out, bytes.get(out, (bytes.size(out) - distance : U32))))

def inflate.distance.extra(read: BitRead, +length: U32, +base: U32, +out: Bytes, limit: U32) -> Inflate:
  BitRead{extra, stream} = read
  +input = stream
  +distance = (base + extra : U32)
  U.branch(Inflate, bits.valid(input) && U32.is_gt(distance, 0) && U32.is_le(distance, bytes.size(out)) && U32.is_le(length, (limit - bytes.size(out) : U32)),
    _ => Inflate{input, inflate.copy(U32.to_nat(length), distance, out)}, _ => Inflate{bits.invalid(input), out})

def inflate.distance(read: BitRead, length: U32, out: Bytes, limit: U32) -> Inflate:
  BitRead{symbol, stream} = read
  +codeword = symbol
  +input = stream
  inflate.distance.extra(bits.read(U.choose(BitStream, U32.is_lt(codeword, 30), input, bits.invalid(input)), inflate.distance.bits(codeword)), length, inflate.distance.base(codeword), out, limit)

def inflate.length.extra(read: BitRead, base: U32, distance: Huffman, out: Bytes, limit: U32) -> Inflate:
  BitRead{extra, stream} = read
  inflate.distance(huff.read(distance, stream), (base + extra : U32), out, limit)

def inflate.symbol(read: BitRead, distance: Huffman, +out: Bytes, +limit: U32) -> Inflate:
  BitRead{symbol, stream} = read
  +codeword = symbol
  +input = stream
  U.branch(Inflate, Bool.not(bits.valid(input)) || U32.is_gt(codeword, 285), _ => Inflate{bits.invalid(input), out},
    _ => U.branch(Inflate, U32.is_lt(codeword, 256), _ => U.branch(Inflate, U32.is_lt(bytes.size(out), limit), _ => Inflate{input, bytes.push(out, codeword)}, _ => Inflate{bits.invalid(input), out}),
      _ => inflate.length.extra(bits.read(input, inflate.length.bits((codeword - 257 : U32))), inflate.length.base((codeword - 257 : U32)), distance, out, limit)))

def inflate.codes.next(+result: Inflate, next: BitStream -> Bytes -> Inflate) -> Inflate:
  Inflate{stream, output} = result
  U.branch(Inflate, bits.valid(stream), _ => next(stream)(output), _ => result)

def inflate.codes.step(+read: BitRead, distance: Huffman, +out: Bytes, limit: U32, next: BitStream -> Bytes -> Inflate) -> Inflate:
  BitRead{symbol, stream} = read
  U.branch(Inflate, U32.is_eq(symbol, 256), _ => Inflate{stream, out}, _ => inflate.codes.next(inflate.symbol(read, distance, out, limit), next))

@unsafe
def inflate.codes(+literal: Huffman, +distance: Huffman, stream: BitStream, out: Bytes, +limit: U32) -> Inflate:
  inflate.codes.step(huff.read(literal, stream), distance, out, limit, input => output => inflate.codes(literal, distance, input, output, limit))

def inflate.stored.byte(read: BitRead, out: Bytes, next: BitStream -> Bytes -> Inflate) -> Inflate:
  BitRead{v, stream} = read
  next(stream)(bytes.push(out, v))

@unsafe
def inflate.stored.copy(n: Nat, stream: BitStream, out: Bytes) -> Inflate:
  match n:
    case 0n: Inflate{stream, out}
    case 1n+d: inflate.stored.byte(bits.read(stream, 8), out, input => output => inflate.stored.copy(d, input, output))

def inflate.stored.nlen(read: BitRead, +length: U32, +out: Bytes, limit: U32) -> Inflate:
  BitRead{inverse, stream} = read
  +input = stream
  U.branch(Inflate, bits.valid(input) && U32.is_eq(U32.xor(length, inverse), 65535) && U32.is_le(length, (limit - bytes.size(out) : U32)),
    _ => inflate.stored.copy(U32.to_nat(length), input, out), _ => Inflate{bits.invalid(input), out})

def inflate.stored.len(read: BitRead, out: Bytes, limit: U32) -> Inflate:
  BitRead{len, stream} = read
  inflate.stored.nlen(bits.read(stream, 16), len, out, limit)

type DeflateTrees is Data:
  DeflateTrees{literal: Huffman, distance: Huffman, stream: BitStream}

def inflate.cl.byte(read: BitRead, codes: Bytes, index: U32, next: BitStream -> Bytes -> Inflate) -> Inflate:
  BitRead{len, stream} = read
  next(stream)(bytes.set(codes, inflate.code.order(index), len))

@unsafe
def inflate.cl(n: Nat, +index: U32, stream: BitStream, codes: Bytes) -> Inflate:
  match n:
    case 0n: Inflate{stream, codes}
    case 1n+d: inflate.cl.byte(bits.read(stream, 3), codes, index, input => output => inflate.cl(d, U32.inc(index), input, output))

def inflate.length.repeat(read: BitRead, +base: U32, +value: U32, +remaining: U32, +lengths: Bytes) -> Inflate:
  BitRead{extra, stream} = read
  +count = (base + extra : U32)
  +input = stream
  U.branch(Inflate, bits.valid(input) && U32.is_le(count, remaining), _ => Inflate{input, bytes.repeat(U32.to_nat(count), value, lengths)}, _ => Inflate{bits.invalid(input), lengths})

def inflate.length.code(read: BitRead, +remaining: U32, +lengths: Bytes) -> Inflate:
  BitRead{symbol, stream} = read
  +codeword = symbol
  +input = stream
  U.branch(Inflate, Bool.not(bits.valid(input)) || U32.is_gt(codeword, 18), _ => Inflate{bits.invalid(input), lengths},
    _ => U.branch(Inflate, U32.is_lt(codeword, 16), _ => Inflate{input, bytes.push(lengths, codeword)},
      _ => U.branch(Inflate, U32.is_eq(codeword, 16) && U32.is_eq(bytes.size(lengths), 0), _ => Inflate{bits.invalid(input), lengths},
        _ => inflate.length.repeat(bits.read(input, U.choose(U32, U32.is_eq(codeword, 16), 2, U.choose(U32, U32.is_eq(codeword, 17), 3, 7))), U.choose(U32, U32.is_eq(codeword, 18), 11, 3), U.choose(U32, U32.is_eq(codeword, 16), bytes.get(lengths, (bytes.size(lengths) - 1 : U32)), 0), remaining, lengths))))

def inflate.lengths.next(+result: Inflate, remaining: U32, oldSize: U32, next: U32 -> BitStream -> Bytes -> Inflate) -> Inflate:
  Inflate{stream, lengths} = result
  U.branch(Inflate, bits.valid(stream), _ => next((remaining - bytes.size(lengths) + oldSize : U32))(stream)(lengths), _ => result)

@unsafe
def inflate.lengths(+remaining: U32, +codes: Huffman, +stream: BitStream, +lengths: Bytes) -> Inflate:
  U.branch(Inflate, U32.is_eq(remaining, 0), _ => Inflate{stream, lengths},
    _ => inflate.lengths.next(inflate.length.code(huff.read(codes, stream), remaining, lengths), remaining, bytes.size(lengths), n => input => output => inflate.lengths(n, codes, input, output)))

def inflate.trees(result: Inflate, +litCount: U32, distCount: U32) -> DeflateTrees:
  Inflate{stream, lengths} = result
  +ls = lengths
  +input = stream
  DeflateTrees{huff.build(bytes.slice(U32.to_nat(litCount), ls, 0, bytes.empty())), huff.build(bytes.slice(U32.to_nat(distCount), ls, litCount, bytes.empty())), U.choose(BitStream, U32.is_gt(bytes.get(ls, 256), 0), input, bits.invalid(input))}

def inflate.dynamic.codes(result: Inflate, +litCount: U32, +distCount: U32) -> DeflateTrees:
  Inflate{stream, codes} = result
  inflate.trees(inflate.lengths((litCount + distCount : U32), huff.build(codes), stream, bytes.empty()), litCount, distCount)

def inflate.dynamic.header(read: BitRead) -> DeflateTrees:
  BitRead{header, stream} = read
  +word = header
  +litCount = (U32.and(word, 31) + 257 : U32)
  +distCount = (U32.and(U32.shrn(word, 5n), 31) + 1 : U32)
  inflate.dynamic.codes(inflate.cl(U32.to_nat((U32.and(U32.shrn(word, 10n), 15) + 4 : U32)), 0, stream, Bytes{ByteFlat{0}, 19, 32}), litCount, distCount)

def inflate.dynamic(trees: DeflateTrees, out: Bytes, limit: U32) -> Inflate:
  DeflateTrees{literal, distance, stream} = trees
  inflate.codes(literal, distance, stream, out, limit)

def inflate.block(+kind: U32, +stream: BitStream, +out: Bytes, +limit: U32) -> Inflate:
  U.branch(Inflate, U32.is_eq(kind, 0), _ => inflate.stored.len(bits.read(bits.align(stream), 16), out, limit),
    _ => U.branch(Inflate, U32.is_eq(kind, 1), _ => inflate.codes(huff.build(huff.fixed.lengths(288n, 0, bytes.empty())), huff.build(bytes.repeat(32n, 5, bytes.empty())), stream, out, limit),
      _ => U.branch(Inflate, U32.is_eq(kind, 2), _ => inflate.dynamic(inflate.dynamic.header(bits.read(stream, 14)), out, limit), _ => Inflate{bits.invalid(stream), out})))

def inflate.block.done(+result: Inflate, last: Bool, next: BitStream -> Bytes -> Inflate) -> Inflate:
  Inflate{stream, output} = result
  U.branch(Inflate, last || Bool.not(bits.valid(stream)), _ => result, _ => next(stream)(output))

def inflate.header(read: BitRead, out: Bytes, limit: U32, next: BitStream -> Bytes -> Inflate) -> Inflate:
  BitRead{header, stream} = read
  +word = header
  inflate.block.done(inflate.block(U32.shr(word), stream, out, limit), U32.is_eq(U32.and(word, 1), 1), next)

@unsafe
def inflate.blocks(stream: BitStream, out: Bytes, +limit: U32) -> Inflate:
  inflate.header(bits.read(stream, 3), out, limit, input => output => inflate.blocks(input, output, limit))

def checksum.adler.loop(n: Nat, +src: Bytes, +index: U32, +a: U32, b: U32) -> U32:
  match n:
    case 0n: (b * 65536 + a : U32)
    case 1n+d:
      +aa = ((a + bytes.get(src, index)) % 65521 : U32)
      checksum.adler.loop(d, src, U32.inc(index), aa, ((b + aa) % 65521 : U32))

def checksum.adler(+src: Bytes) -> U32:
  checksum.adler.loop(U32.to_nat(bytes.size(src)), src, 0, 1, 0)

def checksum.crc.word(n: Nat, +word: U32) -> U32:
  match n:
    case 0n: word
    case 1n+d: checksum.crc.word(d, U32.xor(U32.shr(word), U.choose(U32, U32.is_eq(U32.and(word, 1), 1), 3988292384, 0)))

def checksum.crc.table(n: Nat, +index: U32, out: Bytes) -> Bytes:
  match n:
    case 0n: out
    case 1n+d: checksum.crc.table(d, U32.inc(index), bytes.push(out, checksum.crc.word(8n, index)))

def checksum.crc.loop(n: Nat, +src: Bytes, +index: U32, +table: Bytes, +crc: U32) -> U32:
  match n:
    case 0n: U32.xor(crc, 4294967295)
    case 1n+d: checksum.crc.loop(d, src, U32.inc(index), table, U32.xor(U32.shrn(crc, 8n), bytes.get(table, U32.and(U32.xor(crc, bytes.get(src, index)), 255))))

def zlib.result(result: Inflate, +expected: U32, checksum: U32) -> Maybe<&2, Bytes>:
  Inflate{stream, output} = result
  +out = output
  U.choose(Maybe<&2, Bytes>, bits.valid(stream) && U32.is_eq(bytes.size(out), expected) && U32.is_eq(checksum.adler(out), checksum), Some{out}, None{})

def zlib(+src: Bytes, +expected: U32) -> Maybe<&2, Bytes>:
  +n = bytes.size(src)
  +cmf = bytes.get(src, 0)
  +flg = bytes.get(src, 1)
  U.branch(Maybe<&2, Bytes>, U32.is_ge(n, 6) && U32.is_eq(U32.and(cmf, 15), 8) && U32.is_le(U32.shrn(cmf, 4n), 7) && U32.is_eq(U32.and(flg, 32), 0) && U32.is_eq(((cmf * 256 + flg) % 31 : U32), 0),
    _ => zlib.result(inflate.blocks(BitStream{src, 16, ((n - 4) * 8 : U32), True{}}, bytes.empty(), expected), expected, bytes.be(src, (n - 4 : U32), 4n, 0)), _ => None{})

def uri.hex.valid(+c: U32) -> Bool:
  U.digit(c) || (U32.is_ge(c, 65) && U32.is_le(c, 70)) || (U32.is_ge(c, 97) && U32.is_le(c, 102))

def uri.bytes(+s: String, +out: Bytes) -> Bytes:
  match s:
    case SNil{}: out
    case SCon{Chr{37}, SCon{Chr{a}, SCon{Chr{b}, rest}}}:
      U.branch(Bytes, uri.hex.valid(a) && uri.hex.valid(b), _ => uri.bytes(rest, bytes.push(out, (U.hex.digit(a) * 16 + U.hex.digit(b) : U32))), _ => bytes.empty())
    case SCon{Chr{c}, rest}:
      U.branch(Bytes, U32.is_lt(c, 128) && Bool.not(U32.is_eq(c, 37)), _ => uri.bytes(rest, bytes.push(out, c)), _ => bytes.empty())

@unsafe
def bytes.depth(+size: U32, +side: U32, +depth: Nat) -> Nat:
  U.branch(Nat, U32.is_ge(side, size), _ => depth, _ => bytes.depth(size, (side * 2 : U32), 1n+depth))

def bytes.zero(+size: U32) -> Bytes:
  Bytes{ByteFlat{0}, size, U32.shln(1, bytes.depth(size, 1, 0n))}

# ---- files ----

# A file's bytes, read straight into a byte tree by the effect (File.read
# decodes UTF-8, and building the tree in Bend from a byte string costs a
# cons cell per byte); Fail carries the errno and its message.
def bytes.read.raw(path: String) -> IO(Result<&1, &1, U32 & String, Bytes>):
  import "./effs/bytes_read.c"
  import "./effs/bytes_read.js"

def bytes.read(path: String) -> IO(Result<&1, &1, U32 & String, Bytes>):
  bytes.read.raw(path)
