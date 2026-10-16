# Text scanning, number parsing (the SVG/CSS number grammar, units, hex) and
# small helpers over strings, U32 and F32.
import Base

def choose(-A: Type, yes: Bool, a: A, b: A) -> A:
  match yes:
    case True{}: a
    case False{}: b

def max.u32(+a: U32, +b: U32) -> U32:
  choose(U32, U32.is_gt(a, b), a, b)

def min.u32(+a: U32, +b: U32) -> U32:
  choose(U32, U32.is_lt(a, b), a, b)

def min(+a: F32, +b: F32) -> F32:
  choose(F32, F32.is_lt(a, b), a, b)

def max(+a: F32, +b: F32) -> F32:
  choose(F32, F32.is_gt(a, b), a, b)

def clamp(x: F32, lo: F32, hi: F32) -> F32:
  max(lo, min(hi, x))

def code(c: Char) -> U32:
  Chr{x} = c
  x

def space(+c: U32) -> Bool:
  U32.is_eq(c, 32) || U32.is_eq(c, 9) || U32.is_eq(c, 10) || U32.is_eq(c, 13)

def digit(+c: U32) -> Bool:
  U32.is_ge(c, 48) && U32.is_le(c, 57)

def rev(s: String, acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{c, t}: rev(t, SCon{c, acc})

# Consume equality inputs without rebuilding borrowed strings on the host stack.
@unsafe
def string.equal.go(same: Bool, a: String, b: String) -> Bool:
  match same a b:
    case False{} _ _: False{}
    case True{} SNil{} SNil{}: True{}
    case True{} SCon{Chr{x}, xs} SCon{Chr{y}, ys}: string.equal.go(U32.is_eq(x, y), xs, ys)
    case True{} _ _: False{}

def string.equal(a: String, b: String) -> Bool:
  string.equal.go(True{}, a, b)

def branch(-A: Type, yes: Bool, a: Unit -> A, b: Unit -> A) -> A:
  match yes:
    case True{}: a(Unit{})
    case False{}: b(Unit{})

def trim(+s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      branch(String, space(c), _ => trim(t), _ => SCon{Chr{c}, t})

type Scan is Data:
  Scan{head: String, tail: String}

# Scanning loops decide each character one step ahead (`hit` says whether
# `c` ends the scan), so the rest of the text is only ever held once: a
# shared tail would make every step pay for the sharing.
@unsafe
def until.go(hit: Bool, +c: U32, t: String, +end: U32, acc: String) -> Scan:
  match hit:
    case True{}: Scan{rev(acc, ""), t}
    case False{}:
      match t:
        case SNil{}: Scan{rev(SCon{Chr{c}, acc}, ""), ""}
        case SCon{Chr{c2}, t2}:
          +cc = c2
          until.go(U32.is_eq(cc, end), cc, t2, end, SCon{Chr{c}, acc})

def until(s: String, +end: U32, acc: String) -> Scan:
  match s:
    case SNil{}: Scan{rev(acc, ""), ""}
    case SCon{Chr{c}, t}:
      +cc = c
      until.go(U32.is_eq(cc, end), cc, t, end, acc)

def prefix(s: String, p: String) -> Bool:
  match s p:
    case _ SNil{}: True{}
    case SNil{} SCon{pc, pt}: False{}
    case SCon{sc, st} SCon{pc, pt}:
      U32.is_eq(code(sc), code(pc)) && prefix(st, pt)

def drop(s: String, p: String) -> String:
  match s p:
    case s SNil{}: s
    case SNil{} SCon{pc, pt}: ""
    case SCon{sc, st} SCon{pc, pt}: drop(st, pt)

def through(+s: String, +p: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{sc, st}:
      branch(String, prefix(s, p), _ => drop(s, p), _ => through(st, p))

def until.sequence(+s: String, +end: String, +acc: String) -> Scan:
  match s:
    case SNil{}: Scan{rev(acc, ""), ""}
    case SCon{c, t}: branch(Scan, prefix(s, end), _ => Scan{rev(acc, ""), drop(s, end)}, _ => until.sequence(t, end, SCon{c, acc}))

# SVG number grammar, including adjacent signs and scientific notation.
@unsafe
def separators.go(skip: Bool, +c: U32, t: String) -> String:
  match skip:
    case False{}: SCon{Chr{c}, t}
    case True{}:
      match t:
        case SNil{}: ""
        case SCon{Chr{c2}, t2}:
          +cc = c2
          separators.go(space(cc) || U32.is_eq(cc, 44), cc, t2)

def separators(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      +cc = c
      separators.go(space(cc) || U32.is_eq(cc, 44), cc, t)

def number.exponent(+s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{Chr{c}, t}:
      match t:
        case SNil{}: digit(c)
        case SCon{Chr{d}, rest}: digit(c) || ((U32.is_eq(c, 43) || U32.is_eq(c, 45)) && digit(d))

type Number is Data:
  Number{value: F32, tail: String, valid: Bool}

# A number is read straight into a float: digits accumulate the mantissa
# (fraction digits also scale a divisor), an exponent accumulates its own
# digits, and a sign is taken where it may appear. Nothing is copied into a
# scratch string. The head is split off and classified one step ahead so
# the loop branches on parameters: class 0 digit, 1 dot, 2 exponent mark,
# 3 sign, 4 anything else; stage 0 start, 1 mantissa, 2 fraction, 3 after
# the mark, 4 exponent digits. An exponent mark that no digit follows is
# not part of the number (as in "1em"), so the string from the mark is
# kept to be the tail in that case.
def number.class(+c: U32) -> U32:
  choose(U32, digit(c), 0, choose(U32, U32.is_eq(c, 46), 1,
    choose(U32, U32.is_eq(c, 101) || U32.is_eq(c, 69), 2,
      choose(U32, U32.is_eq(c, 43) || U32.is_eq(c, 45), 3, 4))))

def number.accepts(+k: U32, +stage: U32, +digits: Bool) -> Bool:
  choose(Bool, U32.is_eq(k, 0), True{},
    choose(Bool, U32.is_eq(k, 1), U32.is_lt(stage, 2),
      choose(Bool, U32.is_eq(k, 2), digits && U32.is_lt(stage, 3),
        choose(Bool, U32.is_eq(k, 3), U32.is_eq(stage, 0) || U32.is_eq(stage, 3), False{}))))

def number.pow10(n: Nat, +acc: F32) -> F32:
  match n:
    case 0n: acc
    case 1n+d: number.pow10(d, (acc * 10.0 : F32))

# The value from the parts; `rest` is the string from the stop, `mark` the
# string from an exponent mark that turned out not to belong.
def number.finish(rest: String, mark: String, +stage: U32, +sign: F32, +mant: F32, +div: F32, +esign: F32, +ev: U32, +digits: Bool, +edigits: Bool) -> Number:
  +dangling = U32.is_ge(stage, 3) && Bool.not(edigits)
  +scale = number.pow10(U32.to_nat(choose(U32, dangling, 0, ev)), 1.0)
  +v = (sign * mant / choose(F32, F32.is_gt(div, 0.0), div, 1.0) : F32)
  Number{choose(F32, F32.is_lt(esign, 0.0), (v / scale : F32), (v * scale : F32)), choose(String, dangling, mark, rest), digits}

# The next step's head, split off and classified, with the mark to carry
# (the string from the exponent mark when the last step was at one).
type Head is Data:
  Head{end: Bool, ok: Bool, k: U32, c: U32, mark: String, t: String}

def number.split.at(t: String, mark: String, +stage: U32, +digits: Bool) -> Head:
  match t:
    case SNil{}: Head{True{}, False{}, 4, 0, mark, ""}
    case SCon{Chr{c}, t2}:
      +cc = c
      +k = number.class(cc)
      Head{False{}, number.accepts(k, stage, digits), k, cc, mark, t2}

def number.split(atMark: Bool, +c: U32, t: String, mark: String, +stage: U32, +digits: Bool) -> Head:
  match atMark:
    case False{}: number.split.at(t, mark, stage, digits)
    case True{}:
      +tt = t
      number.split.at(tt, SCon{Chr{c}, tt}, stage, digits)

@unsafe
def number.go(h: Head, +stage: U32, +sign: F32, +mant: F32, +div: F32, +esign: F32, +ev: U32, +digits: Bool, +edigits: Bool) -> Number:
  match h:
    case Head{end, ok, k, c, mark, t}:
      match end:
        case True{}: number.finish("", mark, stage, sign, mant, div, esign, ev, digits, edigits)
        case False{}:
          match ok:
            case False{}: number.finish(SCon{Chr{c}, t}, mark, stage, sign, mant, div, esign, ev, digits, edigits)
            case True{}:
              +kk = k
              +cc = c
              +isDigit = U32.is_eq(kk, 0)
              +inExp = U32.is_ge(stage, 3)
              +minus = U32.is_eq(cc, 45)
              +stage2 = choose(U32, isDigit, choose(U32, U32.is_eq(stage, 0), 1, choose(U32, U32.is_eq(stage, 3), 4, stage)),
                choose(U32, U32.is_eq(kk, 1), 2, choose(U32, U32.is_eq(kk, 2), 3, stage)))
              +digits2 = digits || (isDigit && Bool.not(inExp))
              number.go(number.split(U32.is_eq(kk, 2), cc, t, mark, stage2, digits2), stage2,
                choose(F32, U32.is_eq(kk, 3) && U32.is_eq(stage, 0) && minus, F32.neg(1.0), sign),
                choose(F32, isDigit && Bool.not(inExp), (mant * 10.0 + U32.to_f32((cc - 48 : U32)) : F32), mant),
                choose(F32, isDigit && U32.is_eq(stage, 2), (div * 10.0 : F32), choose(F32, U32.is_eq(kk, 1), 1.0, div)),
                choose(F32, U32.is_eq(kk, 3) && U32.is_eq(stage, 3) && minus, F32.neg(1.0), esign),
                choose(U32, isDigit && inExp, (ev * 10 + cc - 48 : U32), ev),
                digits2, edigits || (isDigit && inExp))

def number(s: String) -> Number:
  number.go(number.split.at(separators(s), "", 0, False{}), 0, 1.0, 0.0, 0.0, 1.0, 0, False{}, False{})

def number.default(num: Number, fallback: F32) -> F32:
  Number{x, t, valid} = num
  choose(F32, valid, x, fallback)

def scalar(s: String, fallback: F32) -> F32:
  number.default(number(s), fallback)

def numbers.next(num: Number, next: String -> List<&2, F32>) -> List<&2, F32>:
  Number{x, t, valid} = num
  choose(Unit -> List<&2, F32>, valid, _ => Con{x, next(t)}, _ => Nil{})(Unit{})

@unsafe
def numbers(s: String) -> List<&2, F32>:
  numbers.next(number(s), t => numbers(t))

def nth(xs: List<&2, F32>, i: Nat, fallback: F32) -> F32:
  match xs i:
    case Nil{} _: fallback
    case Con{h, t} 0n: h
    case Con{h, t} 1n+p: nth(t, p, fallback)

def uints.nth(xs: List<&2, U32>, n: Nat, +fallback: U32) -> U32:
  match xs n:
    case Nil{} _: fallback
    case Con{h, t} 0n: h
    case Con{h, t} 1n+d: uints.nth(t, d, fallback)

def hex.digit(+c: U32) -> U32:
  choose(U32, digit(c), (c - 48 : U32),
    choose(U32, U32.is_ge(c, 65) && U32.is_le(c, 70), (c - 55 : U32),
      choose(U32, U32.is_ge(c, 97) && U32.is_le(c, 102), (c - 87 : U32), 0)))

def hex(s: String, acc: U32) -> U32:
  match s:
    case SNil{}: acc
    case SCon{Chr{c}, t}: hex(t, (acc * 16 + hex.digit(c) : U32))

def trim.both(s: String) -> String:
  rev(trim(rev(trim(s), "")), "")

def unit(num: Number, reference: F32) -> F32:
  Number{x, t, ok} = num
  +v = x
  +u = t
  (v * choose(F32, prefix(u, "%"), (reference / 100.0 : F32),
    choose(F32, prefix(u, "in"), 96.0,
      choose(F32, prefix(u, "cm"), 37.7952755906,
        choose(F32, prefix(u, "mm"), 3.77952755906,
          choose(F32, prefix(u, "pt"), 1.333333333333,
            choose(F32, prefix(u, "pc"), 16.0, 1.0)))))) : F32)

def string.contains(+s: String, +part: String) -> Bool:
  match s:
    case SNil{}: string.equal(part, "")
    case SCon{c, rest}: prefix(s, part) || string.contains(rest, part)

def scan.head(s: Scan) -> String:
  Scan{h, t} = s
  h

def unquote(+s: String) -> String:
  branch(String, prefix(s, "'"), _ => scan.head(until(drop(s, "'"), 39, "")),
    _ => branch(String, prefix(s, "\""), _ => scan.head(until(drop(s, "\""), 34, "")), _ => s))

def strings.has(xs: List<&2, String>, +s: String) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h, t}: branch(Bool, string.equal(h, s), _ => True{}, _ => strings.has(t, s))
