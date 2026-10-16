# CSS: stylesheets, selectors, specificity, media queries and the cascade onto an XML tree.
import Base
import gralha-text-scan@0.1.0.0/scan.bend as U
import gralha-xml-doc@0.1.0.0/xml.bend as XML

def css.lower(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      +ch = c
      SCon{Chr{U.choose(U32, U32.is_ge(ch, 65) && U32.is_le(ch, 90), (ch + 32 : U32), ch)}, css.lower(t)}

def css.pair(s: U.Scan, attrs: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  U.Scan{k, v} = s
  Con{XML.Attr{U.trim.both(k), U.trim.both(v)}, attrs}

def css.more(s: U.Scan, attrs: List<&2, XML.Attr>, next: String -> List<&2, XML.Attr> -> List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  U.Scan{h, t} = s
  next(t)(css.pair(U.until(h, 58, ""), attrs))

@unsafe
def css(s: String, attrs: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match s:
    case SNil{}: attrs
    case SCon{c, t}: css.more(U.until(SCon{c, t}, 59, ""), attrs, rest => as => css(rest, as))

def properties(+attrs: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  U.branch(List<&2, XML.Attr>, U.string.equal(XML.attr.get(attrs, "#css-ready", ""), "1"), _ => attrs, _ => css(XML.attr.get(attrs, "style", ""), attrs))

# Stylesheets are applied to a rendering copy; authored XML stays unchanged.
def css.stop(+ch: U32, +mode: U32) -> Bool:
  U.choose(Bool, U32.is_eq(mode, 0), U.space(ch) || U32.is_eq(ch, 62) || U32.is_eq(ch, 43) || U32.is_eq(ch, 126), U.choose(Bool, U32.is_eq(mode, 1), U32.is_eq(ch, 123) || U32.is_eq(ch, 59), U32.is_eq(ch, mode)))

# Delimiters within strings, brackets or functions do not split CSS tokens.
@unsafe
def css.cut(+s: String, +end: U32, +depth: U32, +quote: U32, +escaped: Bool, +acc: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{U.rev(acc, ""), ""}
    case SCon{Chr{ch}, tail}:
      +c = ch
      +t = tail
      +quoted = Bool.not(U32.is_eq(quote, 0))
      +opening = U32.is_eq(c, 40) || U32.is_eq(c, 91) || U32.is_eq(c, 123)
      +closing = U32.is_eq(c, 41) || U32.is_eq(c, 93) || U32.is_eq(c, 125)
      U.branch(U.Scan, Bool.not(escaped) && Bool.not(quoted) && U32.is_eq(depth, 0) && css.stop(c, end),
        _ => U.Scan{U.rev(acc, ""), s},
        _ => U.branch(U.Scan, Bool.not(escaped) && Bool.not(quoted) && U.prefix(s, "/*"),
          _ => css.cut(U.through(t, "*/"), end, depth, quote, False{}, acc),
          _ => css.cut(t, end,
            U.choose(U32, quoted || escaped, depth, U.choose(U32, opening, U32.inc(depth), U.choose(U32, closing && U32.is_gt(depth, 0), (depth - 1 : U32), depth))),
            U.choose(U32, escaped, quote, U.choose(U32, quoted, U.choose(U32, U32.is_eq(c, quote), 0, quote), U.choose(U32, U32.is_eq(c, 34) || U32.is_eq(c, 39), c, 0))),
            Bool.not(escaped) && U32.is_eq(c, 92), SCon{Chr{c}, acc})))

def css.scan(s: String, end: U32) -> U.Scan:
  css.cut(s, end, 0, 0, False{}, "")

@unsafe
def css.skip(+s: String) -> String:
  U.branch(String, U.prefix(U.trim(s), "/*"), _ => css.skip(U.through(U.trim(s), "*/")), _ => U.trim(s))

def css.ident.char(+c: U32) -> Bool:
  U.digit(c) || (U32.is_ge(c, 65) && U32.is_le(c, 90)) || (U32.is_ge(c, 97) && U32.is_le(c, 122))
    || U32.is_eq(c, 45) || U32.is_eq(c, 95) || U32.is_ge(c, 128)

def css.ident(+s: String, +acc: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{U.rev(acc, ""), ""}
    case SCon{Chr{c}, t}:
      U.branch(U.Scan, css.ident.char(c), _ => css.ident(t, SCon{Chr{c}, acc}), _ => U.Scan{U.rev(acc, ""), s})

def css.word(+s: String, +acc: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{U.rev(acc, ""), ""}
    case SCon{Chr{c}, t}: U.branch(U.Scan, U.space(c), _ => U.Scan{U.rev(acc, ""), t}, _ => css.word(t, SCon{Chr{c}, acc}))

def css.word.test(scan: U.Scan, +word: String, next: String -> Bool) -> Bool:
  U.Scan{h, t} = scan
  U.string.equal(h, word) || next(t)

@unsafe
def css.words(s: String, +word: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{c, t}: css.word.test(css.word(U.trim(SCon{c, t}), ""), word, rest => css.words(rest, word))

type CSSContext is Data:
  CSSContext{node: XML.Element, parents: List<&2, CSSContext>, previous: List<&2, CSSContext>, index: U32, count: U32}

type CSSStep is Data:
  CSSStep{compound: String, relation: U32}

def css.parts.scan(scan: U.Scan, rel: U32, acc: List<&2, CSSStep>, next: String -> List<&2, CSSStep> -> List<&2, CSSStep>) -> List<&2, CSSStep>:
  U.Scan{h, t} = scan
  next(t)(Con{CSSStep{h, rel}, acc})

@unsafe
def css.parts(+s: String, +rel: U32, +acc: List<&2, CSSStep>) -> List<&2, CSSStep>:
  match s:
    case SNil{}: acc
    case SCon{Chr{c}, t}:
      U.branch(List<&2, CSSStep>, U.space(c), _ => css.parts(U.trim(t), rel, acc),
        _ => U.branch(List<&2, CSSStep>, U32.is_eq(c, 62) || U32.is_eq(c, 43) || U32.is_eq(c, 126),
          _ => css.parts(U.trim(t), U.choose(U32, U32.is_eq(c, 62), 2, U.choose(U32, U32.is_eq(c, 43), 3, 4)), acc),
          _ => css.parts.scan(css.scan(s, 0), rel, acc, rest => steps => css.parts(rest, 1, steps))))

def css.attr.value(+actual: String, +expected: String, +op: String) -> Bool:
  U.branch(Bool, U.string.equal(op, "="), _ => U.string.equal(actual, expected),
    _ => U.branch(Bool, U.string.equal(expected, ""), _ => False{},
      _ => U.choose(Bool, U.string.equal(op, "~="), css.words(U.trim(actual), expected),
        U.choose(Bool, U.string.equal(op, "|="), U.string.equal(actual, expected) || U.prefix(actual, expected ++ "-"),
          U.choose(Bool, U.string.equal(op, "^="), U.prefix(actual, expected),
            U.choose(Bool, U.string.equal(op, "$="), U.prefix(U.rev(actual, ""), U.rev(expected, "")),
              Bool.not(U.string.equal(U.through(actual, expected), "")) || U.prefix(U.rev(actual, ""), U.rev(expected, ""))))))))

def css.attr.compare(scan: U.Scan, +actual: String, +op: String) -> Bool:
  U.Scan{expected, tail} = scan
  +ignoreCase = U.string.equal(css.lower(U.trim.both(tail)), "i")
  +text = expected
  css.attr.value(U.choose(String, ignoreCase, css.lower(actual), actual), U.choose(String, ignoreCase, css.lower(text), text), op)

def css.attr.test(scan: U.Scan, +as: List<&2, XML.Attr>) -> Bool:
  U.Scan{k, tail} = scan
  +key = k
  +rest = U.trim(tail)
  +op = U.choose(String, U.prefix(rest, "="), "=", U.choose(String, U.prefix(rest, "~="), "~=", U.choose(String, U.prefix(rest, "|="), "|=", U.choose(String, U.prefix(rest, "^="), "^=", U.choose(String, U.prefix(rest, "$="), "$=", "*=")))))
  +v = U.trim(U.drop(rest, op))
  +actual = XML.attr.get(as, key, "#missing-css-attribute#")
  U.branch(Bool, U.string.equal(rest, ""), _ => Bool.not(U.string.equal(actual, "#missing-css-attribute#")),
    _ => Bool.not(U.string.equal(actual, "#missing-css-attribute#")) && css.attr.compare(XML.value(v), actual, op))

def css.empty(xs: List<&2, XML.Element>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      U.string.equal(n, "#text") && U.string.equal(txt, "") && css.empty(rest)

def css.compact(+s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      +tail = t
      U.branch(String, U.space(c), _ => css.compact(tail), _ => SCon{Chr{c}, css.compact(tail)})

def css.nth.formula(scan: U.Scan, +index: U32) -> Bool:
  U.Scan{h, t} = scan
  +head = h
  +tail = t
  +a = U.choose(F32, U.string.equal(head, "") || U.string.equal(head, "+"), 1.0, U.choose(F32, U.string.equal(head, "-"), F32.neg(1.0), U.scalar(head, 0.0)))
  +b = U.scalar(U.drop(tail, "n"), 0.0)
  +difference = (U32.to_f32(index) - b : F32)
  +n = (difference / a : F32)
  U.branch(Bool, U.string.equal(tail, ""), _ => F32.is_eq(U32.to_f32(index), U.scalar(head, F32.neg(1.0))),
    _ => U.choose(Bool, F32.is_eq(a, 0.0), F32.is_eq(difference, 0.0), F32.is_ge(n, 0.0) && F32.is_eq(n, F32.floor(n))))

def css.nth(+s: String, +index: U32) -> Bool:
  +value = css.lower(css.compact(s))
  U.choose(Bool, U.string.equal(value, "odd"), U32.is_eq(U32.mod(index, 2), 1),
    U.choose(Bool, U.string.equal(value, "even"), U32.is_eq(U32.mod(index, 2), 0), css.nth.formula(css.scan(value, 110), index)))

def css.is.root(parents: List<&2, CSSContext>) -> Bool:
  match parents:
    case Nil{}: True{}
    case Con{h, t}: False{}

def css.pseudo(+key: String, +arg: String, +context: CSSContext) -> Bool:
  CSSContext{XML.Element{n, as, kids, txt}, parents, previous, index, count} = context
  U.choose(Bool, U.string.equal(key, "root"), css.is.root(parents),
    U.choose(Bool, U.string.equal(key, "first-child"), U32.is_eq(index, 1),
      U.choose(Bool, U.string.equal(key, "last-child"), U32.is_eq(index, count),
        U.choose(Bool, U.string.equal(key, "only-child"), U32.is_eq(count, 1),
          U.choose(Bool, U.string.equal(key, "nth-child"), css.nth(arg, index),
            U.choose(Bool, U.string.equal(key, "nth-last-child"), css.nth(arg, (count + 1 - index : U32)),
              U.string.equal(key, "empty") && css.empty(kids)))))))

# Simple selectors compose by conjunction; unsupported pseudo-classes do not match.
def css.simple.scan(scan: U.Scan, +context: CSSContext, +kind: U32, next: String -> Bool) -> Bool:
  U.Scan{h, t} = scan
  CSSContext{XML.Element{n, as, kids, txt}, parents, previous, index, count} = context
  +name = h
  Bool.not(U.string.equal(name, "")) && U.choose(Bool, U32.is_eq(kind, 35), U.string.equal(XML.attr.get(as, "id", ""), name),
    U.choose(Bool, U32.is_eq(kind, 46), css.words(U.trim(XML.attr.get(as, "class", "")), name), U.string.equal(n, name))) && next(t)

def css.simple.attr(+scan: U.Scan, +context: CSSContext, next: String -> Bool) -> Bool:
  U.Scan{h, t} = scan
  CSSContext{XML.Element{n, as, kids, txt}, parents, previous, index, count} = context
  U.prefix(t, "]") && css.attr.test(css.ident(U.trim(h), ""), as) && next(U.drop(t, "]"))

def css.simple.pseudo.arg(+scan: U.Scan, +key: String, +context: CSSContext, next: String -> Bool,
  nested: String -> Bool) -> Bool:
  U.Scan{h, t} = scan
  U.prefix(t, ")") && U.branch(Bool, U.string.equal(key, "not"), _ => Bool.not(nested(h)), _ => css.pseudo(key, h, context)) && next(U.drop(t, ")"))

def css.simple.pseudo(scan: U.Scan, +context: CSSContext, next: String -> Bool, nested: String -> Bool) -> Bool:
  U.Scan{h, t} = scan
  +key = css.lower(h)
  +tail = t
  css.simple.pseudo.arg(U.choose(U.Scan, U.prefix(tail, "("), css.scan(U.drop(tail, "("), 41), U.Scan{"", ")" ++ tail}), key, context, next, nested)

@unsafe
def css.simple(+fuel: Nat, +s: String, +context: CSSContext) -> Bool:
  match fuel s:
    case 0n _: False{}
    case 1n+d SNil{}: True{}
    case 1n+d SCon{Chr{c}, t}:
      U.branch(Bool, U32.is_eq(c, 42), _ => css.simple(d, t, context),
        _ => U.branch(Bool, U32.is_eq(c, 35) || U32.is_eq(c, 46),
          _ => css.simple.scan(css.ident(t, ""), context, c, rest => css.simple(d, rest, context)),
          _ => U.branch(Bool, U32.is_eq(c, 91),
            _ => css.simple.attr(css.scan(t, 93), context, rest => css.simple(d, rest, context)),
            _ => U.branch(Bool, U32.is_eq(c, 58),
              _ => css.simple.pseudo(css.ident(t, ""), context, rest => css.simple(d, rest, context), arg => css.simple(d, arg, context)),
              _ => css.simple.scan(css.ident(s, ""), context, 0, rest => css.simple(d, rest, context))))))

@unsafe
def css.match(+steps: List<&2, CSSStep>, +contexts: List<&2, CSSContext>, +one: Bool) -> Bool:
  match steps contexts:
    case Nil{} _: True{}
    case Con{step, rest} Nil{}: False{}
    case Con{CSSStep{compound, relation}, rest} Con{CSSContext{node, parents, previous, index, count}, others}:
      +rel = relation
      (css.simple(128n, compound, CSSContext{node, parents, previous, index, count}) &&
        U.branch(Bool, U32.is_eq(rel, 0), _ => True{},
          _ => css.match(rest, U.choose(List<&2, CSSContext>, U32.is_le(rel, 2), parents, previous), U32.is_eq(rel, 2) || U32.is_eq(rel, 3))))
        || U.branch(Bool, one, _ => False{}, _ => css.match(steps, others, False{}))

def css.score.scan(scan: U.Scan, weight: U32, next: String -> U32) -> U32:
  U.Scan{h, t} = scan
  (weight + next(t) : U32)

def css.score.arg(scan: U.Scan, negation: Bool, next: String -> U32, nested: String -> U32) -> U32:
  U.Scan{h, t} = scan
  (U.choose(U32, negation, nested(h), 1000) + next(U.drop(t, ")")) : U32)

def css.score.pseudo(scan: U.Scan, next: String -> U32, nested: String -> U32) -> U32:
  U.Scan{h, t} = scan
  +tail = t
  css.score.arg(U.choose(U.Scan, U.prefix(tail, "("), css.scan(U.drop(tail, "("), 41), U.Scan{"", ")" ++ tail}), U.string.equal(h, "not"), next, nested)

@unsafe
def css.score(+fuel: Nat, +s: String) -> U32:
  match fuel s:
    case 0n _: 0
    case 1n+d SNil{}: 0
    case 1n+d SCon{Chr{c}, t}:
      U.branch(U32, U32.is_eq(c, 42), _ => css.score(d, t),
        _ => U.branch(U32, U32.is_eq(c, 35) || U32.is_eq(c, 46),
          _ => css.score.scan(css.ident(t, ""), U.choose(U32, U32.is_eq(c, 35), 1000000, 1000), rest => css.score(d, rest)),
          _ => U.branch(U32, U32.is_eq(c, 91),
            _ => css.score.scan(css.scan(t, 93), 1000, rest => css.score(d, U.drop(rest, "]"))),
            _ => U.branch(U32, U32.is_eq(c, 58),
              _ => css.score.pseudo(css.ident(t, ""), rest => css.score(d, rest), arg => css.score(d, arg)),
              _ => css.score.scan(css.ident(s, ""), 1, rest => css.score(d, rest))))))

def css.specificity(steps: List<&2, CSSStep>) -> U32:
  match steps:
    case Nil{}: 0
    case Con{CSSStep{s, relation}, rest}: (css.score(128n, s) + css.specificity(rest) : U32)

type CSSMatch is Data:
  CSSMatch{matched: Bool, specificity: U32}

def css.select.scan(scan: U.Scan, +context: CSSContext, +best: CSSMatch, next: String -> CSSMatch -> CSSMatch) -> CSSMatch:
  U.Scan{h, t} = scan
  CSSMatch{found, score} = best
  +sel = U.trim.both(h)
  +parts = css.parts(sel, 0, Nil{})
  +hit = Bool.not(U.string.equal(sel, "")) && css.match(parts, Con{context, Nil{}}, True{})
  +weight = css.specificity(parts)
  next(U.drop(t, ","))(CSSMatch{found || hit, U.choose(U32, hit && U32.is_gt(weight, score), weight, score)})

@unsafe
def css.select(s: String, +context: CSSContext, best: CSSMatch) -> CSSMatch:
  match s:
    case SNil{}: best
    case SCon{c, t}: css.select.scan(css.scan(SCon{c, t}, 44), context, best, rest => result => css.select(rest, context, result))

type CSSRule is Data:
  CSSRule{selector: String, declarations: List<&2, XML.Attr>}

def css.declaration.pair(scan: U.Scan) -> XML.Attr:
  U.Scan{k, t} = scan
  XML.Attr{css.lower(U.trim.both(k)), U.trim.both(U.drop(t, ":"))}

def css.declaration.expand(a: XML.Attr, rest: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  XML.Attr{k, v} = a
  +key = k
  +val = v
  +tail = rest
  U.choose(List<&2, XML.Attr>, U.string.equal(key, "marker"), Con{XML.Attr{"marker-start", val}, Con{XML.Attr{"marker-mid", val}, Con{XML.Attr{"marker-end", val}, tail}}}, Con{XML.Attr{key, val}, tail})

def css.declarations.scan(scan: U.Scan, next: String -> List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  U.Scan{h, t} = scan
  css.declaration.expand(css.declaration.pair(css.scan(h, 58)), next(U.drop(t, ";")))

@unsafe
def css.declarations(s: String) -> List<&2, XML.Attr>:
  match s:
    case SNil{}: Nil{}
    case SCon{c, t}: css.declarations.scan(css.scan(SCon{c, t}, 59), rest => css.declarations(rest))

def css.media.feature(scan: U.Scan, +w: F32, +h: F32) -> Bool:
  U.Scan{k, v} = scan
  +key = U.trim.both(k)
  +value = css.lower(U.trim.both(v))
  +x = U.unit(U.number(value), w)
  U.choose(Bool, U.string.equal(key, "min-width"), F32.is_ge(w, x),
    U.choose(Bool, U.string.equal(key, "max-width"), F32.is_le(w, x),
      U.choose(Bool, U.string.equal(key, "width"), F32.is_eq(w, x),
        U.choose(Bool, U.string.equal(key, "min-height"), F32.is_ge(h, x),
          U.choose(Bool, U.string.equal(key, "max-height"), F32.is_le(h, x),
            U.choose(Bool, U.string.equal(key, "height"), F32.is_eq(h, x),
              U.string.equal(key, "orientation") && U.choose(Bool, U.string.equal(value, "portrait"), F32.is_ge(h, w), U.string.equal(value, "landscape") && F32.is_gt(w, h))))))))

def css.media.parens(scan: U.Scan, w: F32, h: F32, next: String -> Bool) -> Bool:
  U.Scan{body, tail} = scan
  css.media.feature(U.until(body, 58, ""), w, h) && next(U.drop(tail, ")"))

def css.media.result(+word: String, +result: Bool) -> Bool:
  U.choose(Bool, U.string.equal(word, "not"), Bool.not(result),
    (U.string.equal(word, "screen") || U.string.equal(word, "all") || U.string.equal(word, "and") || U.string.equal(word, "only")) && result)

def css.media.word(scan: U.Scan, next: String -> Bool) -> Bool:
  U.Scan{head, tail} = scan
  +word = head
  U.branch(Bool, U.string.equal(word, ""), _ => False{}, _ => css.media.result(word, next(tail)))

@unsafe
def css.media.query(+s: String, +w: F32, +h: F32) -> Bool:
  match s:
    case SNil{}: True{}
    case SCon{Chr{c}, t}:
      U.branch(Bool, U.space(c), _ => css.media.query(t, w, h),
        _ => U.branch(Bool, U32.is_eq(c, 40), _ => css.media.parens(css.scan(t, 41), w, h, rest => css.media.query(rest, w, h)),
          _ => css.media.word(css.ident(s, ""), rest => css.media.query(rest, w, h))))

def css.media.list(scan: U.Scan, w: F32, h: F32, next: String -> Bool) -> Bool:
  U.Scan{head, tail} = scan
  css.media.query(css.lower(U.trim.both(head)), w, h) || next(U.drop(tail, ","))

@unsafe
def css.media.more(s: String, +w: F32, +h: F32) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{c, t}: css.media.list(css.scan(SCon{c, t}, 44), w, h, rest => css.media.more(rest, w, h))

def css.media(+s: String, w: F32, h: F32) -> Bool:
  U.string.equal(U.trim(s), "") || css.media.more(s, w, h)

def css.rules.append(xs: List<&2, CSSRule>, ys: List<&2, CSSRule>) -> List<&2, CSSRule>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, css.rules.append(t, ys)}

def css.rules.body(selector: String, scan: U.Scan, w: F32, h: F32,
  next: String -> List<&2, CSSRule>, nested: String -> List<&2, CSSRule>) -> List<&2, CSSRule>:
  U.Scan{body, tail} = scan
  +sel = U.trim.both(selector)
  +content = body
  +following = next(U.drop(tail, "}"))
  U.branch(List<&2, CSSRule>, U.prefix(sel, "@"),
    _ => U.branch(List<&2, CSSRule>, U.prefix(css.lower(sel), "@media") && css.media(U.drop(sel, "@media"), w, h),
      _ => css.rules.append(nested(content), following), _ => following),
    _ => Con{CSSRule{sel, css.declarations(content)}, following})

def css.rules.head(scan: U.Scan, w: F32, h: F32,
  next: String -> List<&2, CSSRule>, nested: String -> List<&2, CSSRule>) -> List<&2, CSSRule>:
  U.Scan{head, tail} = scan
  +rest = tail
  css.rules.body(head, U.choose(U.Scan, U.prefix(rest, ";"), U.Scan{"", "}" ++ U.drop(rest, ";")}, css.scan(U.drop(rest, "{"), 125)), w, h, next, nested)

@unsafe
def css.rules(s: String, +w: F32, +h: F32) -> List<&2, CSSRule>:
  match s:
    case SNil{}: Nil{}
    case SCon{c, t}: css.rules.head(css.scan(SCon{c, t}, 1), w, h, rest => css.rules(rest, w, h), body => css.rules(body, w, h))

def css.text(xs: List<&2, XML.Element>) -> String:
  match xs:
    case Nil{}: ""
    case Con{XML.Element{n, as, kids, txt}, rest}: txt ++ css.text(kids) ++ css.text(rest)

def css.sheets(+xs: List<&2, XML.Element>, +w: F32, +h: F32) -> String:
  match xs:
    case Nil{}: ""
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +nodes = kids
      U.branch(String, U.string.equal(n, "style"),
        _ => U.choose(String, U.string.equal(css.lower(XML.attr.get(as, "type", "text/css")), "text/css") && css.media(XML.attr.get(as, "media", ""), w, h), css.text(nodes), ""),
        _ => css.sheets(nodes, w, h)) ++ "\n" ++ css.sheets(rest, w, h)

type CSSChoice is Data:
  CSSChoice{key: String, value: String, important: Bool, specificity: U32}

def css.choice.scan(+k: String, value: U.Scan, score: U32) -> CSSChoice:
  U.Scan{h, t} = value
  +strong = U.string.equal(css.lower(U.trim.both(U.drop(t, "!"))), "important")
  CSSChoice{k, U.trim.both(h), strong, score}

def css.wins(a: CSSChoice, b: CSSChoice) -> Bool:
  CSSChoice{ak, av, ai, aw} = a
  CSSChoice{bk, bv, bi, bw} = b
  +astrong = ai
  +bstrong = bi
  (astrong && Bool.not(bstrong)) || (((astrong && bstrong) || (Bool.not(astrong) && Bool.not(bstrong))) && U32.is_ge(aw, bw))

def css.insert(+value: CSSChoice, +xs: List<&2, CSSChoice>) -> List<&2, CSSChoice>:
  CSSChoice{nk, nv, ni, nw} = value
  match xs:
    case Nil{}: Con{value, Nil{}}
    case Con{CSSChoice{k, v, imp, weight}, rest}:
      +old = {CSSChoice{k, v, imp, weight} : CSSChoice}
      U.branch(List<&2, CSSChoice>, U.string.equal(nk, k), _ => Con{U.choose(CSSChoice, css.wins(value, old), value, old), rest},
        _ => Con{old, css.insert(value, rest)})

def css.cascade(ds: List<&2, XML.Attr>, +score: U32, +choices: List<&2, CSSChoice>) -> List<&2, CSSChoice>:
  match ds:
    case Nil{}: choices
    case Con{XML.Attr{k, v}, rest}:
      +value = v
      +key = k
      css.cascade(rest, score, U.branch(List<&2, CSSChoice>, U.string.equal(key, "") || U.string.equal(value, ""), _ => choices,
        _ => css.insert(css.choice.scan(key, css.scan(value, 33), score), choices)))

def css.rule.matched(result: CSSMatch, ds: List<&2, XML.Attr>, +choices: List<&2, CSSChoice>) -> List<&2, CSSChoice>:
  CSSMatch{matched, score} = result
  U.branch(List<&2, CSSChoice>, matched, _ => css.cascade(ds, score, choices), _ => choices)

def css.apply.rules(rs: List<&2, CSSRule>, +context: CSSContext, choices: List<&2, CSSChoice>) -> List<&2, CSSChoice>:
  match rs:
    case Nil{}: choices
    case Con{CSSRule{sel, ds}, rest}:
      css.apply.rules(rest, context, css.rule.matched(css.select(sel, context, CSSMatch{False{}, 0}), ds, choices))

def css.chosen(xs: List<&2, CSSChoice>, attrs: List<&2, XML.Attr>) -> List<&2, XML.Attr>:
  match xs:
    case Nil{}: attrs
    case Con{CSSChoice{k, v, important, weight}, rest}: Con{XML.Attr{k, v}, css.chosen(rest, attrs)}

def css.styled(+context: CSSContext, rules: List<&2, CSSRule>) -> List<&2, XML.Attr>:
  CSSContext{XML.Element{n, as, kids, txt}, parents, previous, index, count} = context
  +attrs = as
  Con{XML.Attr{"#css-ready", "1"}, Con{XML.Attr{"style", ""}, css.chosen(css.cascade(css.declarations(XML.attr.get(attrs, "style", "")), 1000000000,
    css.apply.rules(rules, context, Nil{})), attrs)}}

def css.element.count(xs: List<&2, XML.Element>) -> U32:
  match xs:
    case Nil{}: 0
    case Con{XML.Element{n, as, kids, txt}, rest}: (U.choose(U32, U.string.equal(n, "#text"), 0, 1) + css.element.count(rest) : U32)

@unsafe
def css.tree(+xs: List<&2, XML.Element>, +rules: List<&2, CSSRule>, +parents: List<&2, CSSContext>, +previous: List<&2, CSSContext>, +index: U32, +count: U32) -> List<&2, XML.Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{XML.Element{n, as, kids, txt}, rest}:
      +tagname = n
      +children = kids
      +node = {XML.Element{tagname, as, children, txt} : XML.Element}
      +context = {CSSContext{node, parents, previous, index, count} : CSSContext}
      U.branch(List<&2, XML.Element>, U.string.equal(tagname, "#text"),
        _ => Con{node, css.tree(rest, rules, parents, previous, index, count)},
        _ => Con{XML.Element{tagname, css.styled(context, rules), css.tree(children, rules, Con{context, parents}, Nil{}, 1, css.element.count(children)), txt},
          css.tree(rest, rules, parents, Con{context, previous}, U32.inc(index), count)})
