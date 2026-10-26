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

# `same` says whether the characters before `a` and `b` matched: deciding
# it one step ahead keeps the loop a tail call on the shrinking `a`.
def string.equal.go(a: String, b: String, same: Bool) -> Bool:
  match a b same:
    case SNil{} SNil{} True{}: True{}
    case SCon{Chr{x}, xs} SCon{Chr{y}, ys} True{}: string.equal.go(xs, ys, U32.is_eq(x, y))
    case _ _ _: False{}

def string.equal(a: String, b: String) -> Bool:
  string.equal.go(a, b, True{})

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
# `c`, the character before `t`, ends the scan), so the rest of the text is
# only ever held once: a shared tail would make every step pay for the
# sharing. The rest comes first, as the argument that shrinks.
def until.go(t: String, hit: Bool, +c: U32, +end: U32, acc: String) -> Scan:
  match t hit:
    case t True{}: Scan{rev(acc, ""), t}
    case SNil{} False{}: Scan{rev(SCon{Chr{c}, acc}, ""), ""}
    case SCon{Chr{c2}, t2} False{}:
      +cc = c2
      until.go(t2, U32.is_eq(cc, end), cc, end, SCon{Chr{c}, acc})

def until(s: String, +end: U32, acc: String) -> Scan:
  match s:
    case SNil{}: Scan{rev(acc, ""), ""}
    case SCon{Chr{c}, t}:
      +cc = c
      until.go(t, U32.is_eq(cc, end), cc, end, acc)

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
def separator(+c: U32) -> Bool:
  space(c) || U32.is_eq(c, 44)

def separators.go(t: String, skip: Bool, +c: U32) -> String:
  match t skip:
    case t False{}: SCon{Chr{c}, t}
    case SNil{} True{}: ""
    case SCon{Chr{c2}, t2} True{}:
      +cc = c2
      separators.go(t2, separator(cc), cc)

def separators(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      +cc = c
      separators.go(t, separator(cc), cc)

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
# scratch string. Each character is classified one step ahead, so the loop
# branches on parameters: class 0 digit, 1 dot, 2 exponent mark, 3 sign,
# 4 anything else; stage 0 start, 1 mantissa, 2 fraction, 3 after the
# mark, 4 exponent digits. An exponent mark that no digit follows is not
# part of the number (as in "1em"), so `mark` keeps what was read from the
# mark on (the mark and any signs, reversed) to give back in that case.
def number.class(+c: U32) -> U32:
  choose(U32, digit(c), 0, choose(U32, U32.is_eq(c, 46), 1,
    choose(U32, U32.is_eq(c, 101) || U32.is_eq(c, 69), 2,
      choose(U32, U32.is_eq(c, 43) || U32.is_eq(c, 45), 3, 4))))

def number.accepts(+k: U32, +stage: U32, +digits: Bool) -> Bool:
  choose(Bool, U32.is_eq(k, 0), True{},
    choose(Bool, U32.is_eq(k, 1), U32.is_lt(stage, 2),
      choose(Bool, U32.is_eq(k, 2), digits && U32.is_lt(stage, 3),
        choose(Bool, U32.is_eq(k, 3), U32.is_eq(stage, 0) || U32.is_eq(stage, 3), False{}))))

def number.stage(+k: U32, +stage: U32) -> U32:
  choose(U32, U32.is_eq(k, 0), choose(U32, U32.is_eq(stage, 0), 1, choose(U32, U32.is_eq(stage, 3), 4, stage)),
    choose(U32, U32.is_eq(k, 1), 2, choose(U32, U32.is_eq(k, 2), 3, stage)))

def number.mark(keep: Bool, +c: U32, mark: String) -> String:
  match keep:
    case True{}: SCon{Chr{c}, mark}
    case False{}: mark

def number.pow10(n: Nat, +acc: F32) -> F32:
  match n:
    case 0n: acc
    case 1n+d: number.pow10(d, (acc * 10.0 : F32))

def number.tail(dangling: Bool, mark: String, rest: String) -> String:
  match dangling:
    case True{}: rev(mark, rest)
    case False{}: rest

# The value from the parts; `rest` is the string from the stop.
def number.finish(rest: String, mark: String, +stage: U32, +sign: F32, +mant: F32, +div: F32, +esign: F32, +ev: U32, +digits: Bool, +edigits: Bool) -> Number:
  +dangling = U32.is_ge(stage, 3) && Bool.not(edigits)
  +scale = number.pow10(U32.to_nat(choose(U32, dangling, 0, ev)), 1.0)
  +v = (sign * mant / choose(F32, F32.is_gt(div, 0.0), div, 1.0) : F32)
  Number{choose(F32, F32.is_lt(esign, 0.0), (v / scale : F32), (v * scale : F32)), number.tail(dangling, mark, rest), digits}

# `c` is the character before `t`; `ok` says whether it was read, and the
# parts are the ones after it. The next character is read when the stage
# accepts it, and otherwise the parts are kept and the number stops there.
def number.go(t: String, ok: Bool, +c: U32, mark: String, +stage: U32, +sign: F32, +mant: F32, +div: F32, +esign: F32, +ev: U32, +digits: Bool, +edigits: Bool) -> Number:
  match t ok:
    case t False{}: number.finish(SCon{Chr{c}, t}, mark, stage, sign, mant, div, esign, ev, digits, edigits)
    case SNil{} True{}: number.finish("", mark, stage, sign, mant, div, esign, ev, digits, edigits)
    case SCon{Chr{c2}, t2} True{}:
      +cc = c2
      +k = number.class(cc)
      +read = number.accepts(k, stage, digits)
      +isDigit = read && U32.is_eq(k, 0)
      +inExp = U32.is_ge(stage, 3)
      +minus = read && U32.is_eq(k, 3) && U32.is_eq(cc, 45)
      +stage2 = choose(U32, read, number.stage(k, stage), stage)
      number.go(t2, read, cc, number.mark(read && U32.is_eq(stage2, 3), cc, mark), stage2,
        choose(F32, minus && U32.is_eq(stage, 0), F32.neg(1.0), sign),
        choose(F32, isDigit && Bool.not(inExp), (mant * 10.0 + U32.to_f32((cc - 48 : U32)) : F32), mant),
        choose(F32, isDigit && U32.is_eq(stage, 2), (div * 10.0 : F32), choose(F32, read && U32.is_eq(k, 1), 1.0, div)),
        choose(F32, minus && U32.is_eq(stage, 3), F32.neg(1.0), esign),
        choose(U32, isDigit && inExp, (ev * 10 + cc - 48 : U32), ev),
        digits || (isDigit && Bool.not(inExp)), edigits || (isDigit && inExp))

# The loop starts as if after a character that was read, with nothing yet.
def number(s: String) -> Number:
  number.go(separators(s), True{}, 0, "", 0, 1.0, 0.0, 0.0, 1.0, 0, False{}, False{})

def number.default(num: Number, fallback: F32) -> F32:
  Number{x, t, valid} = num
  choose(F32, valid, x, fallback)

def scalar(s: String, fallback: F32) -> F32:
  number.default(number(s), fallback)

def numbers.next(num: Number, next: String -> List<&2, F32>) -> List<&2, F32>:
  Number{x, t, valid} = num
  choose(Unit -> List<&2, F32>, valid, _ => Con{x, next(t)}, _ => Nil{})(Unit{})

# Every number read takes at least one character (a digit), so the text's
# length bounds how many there are.
def numbers.go(fuel: Nat, s: String) -> List<&2, F32>:
  match fuel:
    case 0n: Nil{}
    case 1n+f: numbers.next(number(s), t => numbers.go(f, t))

def numbers(+s: String) -> List<&2, F32>:
  numbers.go(String.length(s), s)

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
