# XML: tokens, element tree, entities, attributes and serialization.
import Base
import gralha-text-scan@0.1.0.1/scan.bend as U

# Reverse a scan's accumulator while decoding XML entities: the reversed
# text shows an entity as its ';' first, then its name backwards, then '&';
# a ';' without a short name and '&' behind it is plain text.
def entity.push(+e: String, +out: String) -> String:
  match e:
    case SNil{}: out
    case SCon{c, t}: SCon{c, entity.push(t, out)}

def entity.of(+name: String) -> String:
  U.choose(String, U.string.equal(name, "amp"), "&", U.choose(String, U.string.equal(name, "lt"), "<",
    U.choose(String, U.string.equal(name, "gt"), ">", U.choose(String, U.string.equal(name, "quot"), "\"",
      U.choose(String, U.string.equal(name, "apos"), "'", U.choose(String, U.prefix(name, "#x"), SCon{Chr{U.hex(U.drop(name, "#x"), 0)}, ""},
        U.choose(String, U.prefix(name, "#"), SCon{Chr{F32.to_u32(U.scalar(U.drop(name, "#"), 65533.0))}, ""}, "&" ++ name ++ ";")))))))

# One step of the decoding reversal: kind 0 a plain character, 1 an entity
# (its name collected backwards up to the '&'), 2 a ';' that began no
# entity (the collected text stays as it was), 3 the end.
type Step is Data:
  Step{kind: U32, ch: U32, name: String, rest: String}

@unsafe
def entity.take(s: String, +name: String, +n: U32) -> Step:
  match s:
    case SNil{}: Step{2, 0, name, ""}
    case SCon{Chr{c}, t}:
      +ch = c
      +tail = t
      U.branch(Step, U32.is_eq(ch, 38), _ => Step{1, 0, name, tail},
        _ => U.branch(Step, U32.is_lt(n, 12) && (U.digit(ch) || (U32.is_ge(ch, 65) && U32.is_le(ch, 90)) || (U32.is_ge(ch, 97) && U32.is_le(ch, 122)) || U32.is_eq(ch, 35)),
          _ => entity.take(tail, SCon{Chr{ch}, name}, (n + 1 : U32)), _ => Step{2, 0, name, SCon{Chr{ch}, tail}}))

def rev.next.at(semi: Bool, +ch: U32, t: String) -> Step:
  match semi:
    case True{}: entity.take(t, "", 0)
    case False{}: Step{0, ch, "", t}

def rev.next(s: String) -> Step:
  match s:
    case SNil{}: Step{3, 0, "", ""}
    case SCon{Chr{c}, t}:
      +ch = c
      rev.next.at(U32.is_eq(ch, 59), ch, t)

@unsafe
def rev.decode.go(st: Step, +out: String) -> String:
  match st:
    case Step{kind, ch, name, rest}:
      match kind:
        case 0: rev.decode.go(rev.next(rest), SCon{Chr{ch}, out})
        case 1: rev.decode.go(rev.next(rest), entity.push(entity.of(name), out))
        case 2: rev.decode.go(rev.next(rest), entity.push(name, SCon{Chr{59}, out}))
        case _: out

def rev.decode(s: String, +out: String) -> String:
  rev.decode.go(rev.next(s), out)

# Like until, with entities decoded in the reversal.
@unsafe
def until.decoded.go(hit: Bool, +c: U32, t: String, +end: U32, acc: String) -> U.Scan:
  match hit:
    case True{}: U.Scan{rev.decode(acc, ""), t}
    case False{}:
      match t:
        case SNil{}: U.Scan{rev.decode(SCon{Chr{c}, acc}, ""), ""}
        case SCon{Chr{c2}, t2}:
          +cc = c2
          until.decoded.go(U32.is_eq(cc, end), cc, t2, end, SCon{Chr{c}, acc})

def until.decoded(s: String, +end: U32, acc: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{rev.decode(acc, ""), ""}
    case SCon{Chr{c}, t}:
      +cc = c
      until.decoded.go(U32.is_eq(cc, end), cc, t, end, acc)

def name.stop(+c: U32) -> Bool:
  U.space(c) || U32.is_eq(c, 61) || U32.is_eq(c, 47) || U32.is_eq(c, 62)

# Each step is decided one character ahead (`stop` says whether `c` ends
# the name) so the text after the name is held once, never shared.
@unsafe
def name.go(stop: Bool, +c: U32, t: String, acc: String) -> U.Scan:
  match stop:
    case True{}: U.Scan{U.rev(acc, ""), SCon{Chr{c}, t}}
    case False{}:
      match t:
        case SNil{}: U.Scan{U.rev(SCon{Chr{c}, acc}, ""), ""}
        case SCon{Chr{c2}, t2}:
          +cc = c2
          name.go(name.stop(cc), cc, t2, SCon{Chr{c}, acc})

def xml.name(s: String, acc: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{U.rev(acc, ""), ""}
    case SCon{Chr{c}, t}:
      +cc = c
      name.go(name.stop(cc), cc, t, acc)

def value.go(quoted: Bool, +ch: U32, rest: String) -> U.Scan:
  match quoted:
    case True{}: until.decoded(rest, ch, "")
    case False{}: xml.name(SCon{Chr{ch}, rest}, "")

def value(s: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{"", ""}
    case SCon{Chr{c}, t}:
      +ch = c
      value.go(U32.is_eq(ch, 34) || U32.is_eq(ch, 39), ch, t)

def equals(s: String) -> U.Scan:
  match s:
    case SNil{}: U.Scan{"", ""}
    case SCon{Chr{c}, t}:
      U.branch(U.Scan, U32.is_eq(c, 61), _ => value(U.trim(t)), _ => U.Scan{"", ""})

type Attr is Data:
  Attr{key: String, val: String}

type Tag is Data:
  Tag{attrs: List<&2, Attr>, tail: String, closed: Bool}

# The parse position after an attribute: the kind of the next character
# (see attr.kind; 4 at the end of the text) with the attributes so far.
# What a character starts inside a tag: 0 space, 1 the end of the tag,
# 2 a self-closing slash, 3 an attribute.
def attr.kind(+c: U32) -> U32:
  U.choose(U32, U.space(c), 0, U.choose(U32, U32.is_eq(c, 62), 1, U.choose(U32, U32.is_eq(c, 47), 2, 3)))

type Next is Data:
  Next{kind: U32, ch: U32, attrs: List<&2, Attr>, tail: String}

def next.of(attrs: List<&2, Attr>, tail: String) -> Next:
  match tail:
    case SNil{}: Next{4, 0, attrs, ""}
    case SCon{Chr{c}, t}:
      +cc = c
      Next{attr.kind(cc), cc, attrs, t}

def attr.append(k: String, b: U.Scan, attrs: List<&2, Attr>) -> Next:
  U.Scan{v, t} = b
  next.of(Con{Attr{k, v}, attrs}, t)

def attr.read.scan(a: U.Scan, attrs: List<&2, Attr>) -> Next:
  U.Scan{k, t} = a
  attr.append(k, equals(U.trim(t)), attrs)

def attr.read(s: String, attrs: List<&2, Attr>) -> Next:
  attr.read.scan(xml.name(s, ""), attrs)

def attributes.close(scan: U.Scan, attrs: List<&2, Attr>) -> Tag:
  U.Scan{h, t} = scan
  Tag{attrs, t, True{}}

@unsafe
def attributes.go(step: Next) -> Tag:
  match step:
    case Next{kind, ch, as, tail}:
      match kind:
        case 0: attributes.go(next.of(as, tail))
        case 1: Tag{as, tail, False{}}
        case 2: attributes.close(U.until(tail, 62, ""), as)
        case 3: attributes.go(attr.read(SCon{Chr{ch}, tail}, as))
        case _: Tag{as, "", False{}}

def attributes(s: String, attrs: List<&2, Attr>) -> Tag:
  attributes.go(next.of(attrs, s))

type Token is Data:
  Open{name: String, attrs: List<&2, Attr>, closed: Bool}
  Shut{name: String}
  Chars{content: String}

type Lexeme is Data:
  Lexeme{token: Token, tail: String}

def lex.open(n: String, tag: Tag) -> Lexeme:
  Tag{attrs, tail, closed} = tag
  Lexeme{Open{n, attrs, closed}, tail}

def lex.named(scan: U.Scan) -> Lexeme:
  U.Scan{n, t} = scan
  lex.open(n, attributes(t, Nil{}))

def lex.shut(scan: U.Scan) -> Lexeme:
  U.Scan{n, t} = scan
  Lexeme{Shut{n}, t}

def xml.raw(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{c}, t}:
      +ch = c
      U.choose(String, U32.is_eq(ch, 38), "&amp;", SCon{Chr{ch}, ""}) ++ xml.raw(t)

def lex.cdata(scan: U.Scan) -> Lexeme:
  U.Scan{h, t} = scan
  Lexeme{Chars{xml.raw(h)}, t}

def lex.tag(+s: String) -> Lexeme:
  U.branch(Lexeme, U.prefix(s, "![CDATA["), _ => lex.cdata(U.until.sequence(U.drop(s, "![CDATA["), "]]>", "")),
    _ => U.branch(Lexeme, U.prefix(s, "!--"), _ => Lexeme{Chars{""}, U.through(s, "-->")},
    _ => U.branch(Lexeme, U.prefix(s, "?"), _ => Lexeme{Chars{""}, U.through(s, "?>")},
      _ => U.branch(Lexeme, U.prefix(s, "!"), _ => Lexeme{Chars{""}, U.through(s, ">")},
        _ => U.branch(Lexeme, U.prefix(s, "/"), _ => lex.shut(U.until(U.drop(s, "/"), 62, "")),
          _ => lex.named(xml.name(s, "")))))))

def lex.more(item: Lexeme, next: String -> List<&2, Token>) -> List<&2, Token>:
  Lexeme{tok, t} = item
  Con{tok, next(t)}

def lex.after(s: String, next: String -> List<&2, Token>) -> List<&2, Token>:
  match s:
    case SNil{}: Nil{}
    case SCon{c, t}: lex.more(lex.tag(SCon{c, t}), next)

def lex.text(scan: U.Scan, next: String -> List<&2, Token>) -> List<&2, Token>:
  U.Scan{h, t} = scan
  Con{Chars{h}, lex.after(t, next)}

@unsafe
def tokenize(s: String) -> List<&2, Token>:
  match s:
    case SNil{}: Nil{}
    case SCon{c, t}:
      lex.text(U.until(SCon{c, t}, 60, ""), next => tokenize(next))

type Element is Data:
  Element{name: String, attrs: List<&2, Attr>, children: List<&2, Element>, text: String}

def elements.rev(xs: List<&2, Element>, acc: List<&2, Element>) -> List<&2, Element>:
  match xs:
    case Nil{}: acc
    case Con{h, t}: elements.rev(t, Con{h, acc})

def element.finish(e: Element) -> Element:
  Element{n, a, kids, txt} = e
  Element{n, a, elements.rev(kids, Nil{}), txt}

def stack.add(s: List<&2, Element>, node: Element) -> List<&2, Element>:
  match s:
    case Nil{}: Con{Element{"#document", Nil{}, Con{node, Nil{}}, ""}, Nil{}}
    case Con{Element{n, a, kids, txt}, rest}:
      Con{Element{n, a, Con{node, kids}, txt}, rest}

def stack.text(+s: List<&2, Element>, +text: String) -> List<&2, Element>:
  U.branch(List<&2, Element>, U.string.equal(text, ""), _ => s,
    _ => stack.add(s, Element{"#text", Nil{}, Nil{}, text}))

def stack.close(s: List<&2, Element>) -> List<&2, Element>:
  match s:
    case Nil{}: Nil{}
    case Con{node, rest}: stack.add(rest, element.finish(node))

def tree.step(tok: Token, +s: List<&2, Element>) -> List<&2, Element>:
  match tok:
    case Chars{txt}: stack.text(s, txt)
    case Shut{n}: stack.close(s)
    case Open{n, a, closed}:
      +node = {Element{n, a, Nil{}, ""} : Element}
      U.choose(List<&2, Element>, closed, stack.add(s, node), Con{node, s})

def tree(tokens: List<&2, Token>, s: List<&2, Element>) -> List<&2, Element>:
  match tokens:
    case Nil{}: s
    case Con{tok, rest}: tree(rest, tree.step(tok, s))

def tree.root(s: List<&2, Element>) -> Element:
  match s:
    case Nil{}: Element{"#document", Nil{}, Nil{}, ""}
    case Con{node, rest}: element.finish(node)

def annotate(xs: List<&2, Token>, +i: U32) -> List<&2, Token>:
  match xs:
    case Nil{}: Nil{}
    case Con{Open{n, as, closed}, rest}:
      Con{Open{n, Con{Attr{"#editor-id", U32.show(i)}, as}, closed}, annotate(rest, U32.inc(i))}
    case Con{tok, rest}: Con{tok, annotate(rest, i)}

def attr.pick(hit: Bool, +v: String, rest: Maybe<&2, String>) -> Maybe<&2, String>:
  match hit:
    case True{}: Some{v}
    case False{}: rest

# The attribute's value when present. Attribute lists are short, so the whole
# list is walked without a lambda per entry.
# The first attribute with the key, decided one entry ahead so the walk
# stops at the hit instead of comparing every key.
@unsafe
def attr.find.go(hit: Bool, v: String, t: List<&2, Attr>, +key: String) -> Maybe<&2, String>:
  match hit:
    case True{}: Some{v}
    case False{}:
      match t:
        case Nil{}: None{}
        case Con{Attr{k2, v2}, t2}: attr.find.go(U.string.equal(k2, key), v2, t2, key)

def attr.find(attrs: List<&2, Attr>, +key: String) -> Maybe<&2, String>:
  match attrs:
    case Nil{}: None{}
    case Con{Attr{k, v}, t}: attr.find.go(U.string.equal(k, key), v, t, key)

def attr.or(found: Maybe<&2, String>, +fallback: String) -> String:
  match found:
    case None{}: fallback
    case Some{v}: v

def attr.get(attrs: List<&2, Attr>, +key: String, +fallback: String) -> String:
  attr.or(attr.find(attrs, key), fallback)

def attrs.append(xs: List<&2, Attr>, ys: List<&2, Attr>) -> List<&2, Attr>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, attrs.append(t, ys)}

def element.prefer(a: Maybe<&2, Element>, b: Maybe<&2, Element>) -> Maybe<&2, Element>:
  match a:
    case Some{e}: Some{e}
    case None{}: b

def element.find(+xs: List<&2, Element>, +id: String) -> Maybe<&2, Element>:
  match xs:
    case Nil{}: None{}
    case Con{Element{n, as, kids, txt}, rest}:
      U.branch(Maybe<&2, Element>, U.string.equal(attr.get(as, "id", ""), id),
        _ => Some{Element{n, as, kids, txt}},
        _ => element.prefer(U.branch(Maybe<&2, Element>, U.string.equal(n, "#svg-image"), _ => None{}, _ => element.find(kids, id)), element.find(rest, id)))

# Decode XML entities before interpreting attributes or exposing source editing.
def entity(+s: String) -> String:
  U.branch(String, U.string.equal(s, "amp"), _ => "&",
    _ => U.branch(String, U.string.equal(s, "lt"), _ => "<",
      _ => U.branch(String, U.string.equal(s, "gt"), _ => ">",
        _ => U.branch(String, U.string.equal(s, "quot"), _ => "\"",
          _ => U.branch(String, U.string.equal(s, "apos"), _ => "'",
            _ => U.branch(String, U.prefix(s, "#x"), _ => SCon{Chr{U.hex(U.drop(s, "#x"), 0)}, ""},
              _ => U.branch(String, U.prefix(s, "#"), _ => SCon{Chr{F32.to_u32(U.scalar(U.drop(s, "#"), 65533.0))}, ""},
                _ => "&" ++ s ++ ";")))))))

def entities.more(scan: U.Scan, acc: String, next: String -> String -> String) -> String:
  U.Scan{h, t} = scan
  next(t)(U.rev(entity(h), acc))

@unsafe
def entities.loop(s: String, +acc: String) -> String:
  match s:
    case SNil{}: U.rev(acc, "")
    case SCon{Chr{c}, t}:
      +ch = c
      +tail = t
      U.branch(String, U32.is_eq(ch, 38),
        _ => entities.more(U.until(tail, 59, ""), acc, rest => text => entities.loop(rest, text)),
        _ => entities.loop(tail, SCon{Chr{ch}, acc}))

def entities(s: String) -> String:
  entities.loop(s, "")

def decode.attrs(as: List<&2, Attr>) -> List<&2, Attr>:
  match as:
    case Nil{}: Nil{}
    case Con{Attr{k, v}, rest}: Con{Attr{k, entities(v)}, decode.attrs(rest)}

# Attribute values were decoded as they were read; text still is here.
def decode.nodes(xs: List<&2, Element>) -> List<&2, Element>:
  match xs:
    case Nil{}: Nil{}
    case Con{Element{n, as, kids, txt}, rest}:
      Con{Element{n, as, decode.nodes(kids), entities(txt)}, decode.nodes(rest)}

def parse(s: String) -> Element:
  tree.root(decode.nodes(tree(annotate(tokenize(s), 1), Con{Element{"#document", Nil{}, Nil{}, ""}, Nil{}})))

# Editor support: identifiers are private metadata and never serialized.
def attrs.remove(+as: List<&2, Attr>, +key: String) -> List<&2, Attr>:
  match as:
    case Nil{}: Nil{}
    case Con{Attr{k, v}, rest}:
      +kk = k
      U.branch(List<&2, Attr>, U.string.equal(kk, key), _ => attrs.remove(rest, key),
        _ => Con{Attr{kk, v}, attrs.remove(rest, key)})

def attrs.set(as: List<&2, Attr>, +key: String, value: String) -> List<&2, Attr>:
  Con{Attr{key, value}, attrs.remove(as, key)}

# One attribute's value taken out of the list, so its text has a single
# owner; "" and the untouched list when absent.
type Taken is Data:
  Taken{value: String, rest: List<&2, Attr>}

def taken.push(t: Taken, a: Attr) -> Taken:
  Taken{v, rest} = t
  Taken{v, Con{a, rest}}

@unsafe
def attrs.take.go(hit: Bool, kk: String, v: String, rest: List<&2, Attr>, +key: String) -> Taken:
  match hit:
    case True{}: Taken{v, rest}
    case False{}:
      match rest:
        case Nil{}: Taken{"", Con{Attr{kk, v}, Nil{}}}
        case Con{Attr{k2, v2}, r2}:
          +kk2 = k2
          taken.push(attrs.take.go(U.string.equal(kk2, key), kk2, v2, r2, key), Attr{kk, v})

def attrs.take(as: List<&2, Attr>, +key: String) -> Taken:
  match as:
    case Nil{}: Taken{"", Nil{}}
    case Con{Attr{k, v}, rest}:
      +kk = k
      attrs.take.go(U.string.equal(kk, key), kk, v, rest, key)

# Build escaped XML in reverse, so large data URIs do not grow the host stack.
def escape.rev(s: String, acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{Chr{c}, t}:
      +ch = c
      escape.rev(t, U.rev(U.choose(String, U32.is_eq(ch, 38), "&amp;",
        U.choose(String, U32.is_eq(ch, 60), "&lt;",
          U.choose(String, U32.is_eq(ch, 62), "&gt;",
            U.choose(String, U32.is_eq(ch, 34), "&quot;", SCon{Chr{ch}, ""})))), acc))

def escape(s: String) -> String:
  U.rev(escape.rev(s, ""), "")

def serialize.attrs.rev(as: List<&2, Attr>, +acc: String) -> String:
  match as:
    case Nil{}: acc
    case Con{Attr{k, v}, rest}:
      +key = k
      serialize.attrs.rev(rest, U.branch(String, U.prefix(key, "#"), _ => acc,
        _ => SCon{Chr{34}, escape.rev(v, SCon{Chr{34}, SCon{Chr{61}, U.rev(key, SCon{Chr{32}, acc})}})}))

def serialize.attrs(as: List<&2, Attr>) -> String:
  U.rev(serialize.attrs.rev(as, ""), "")

def serialize.element(+n: String, as: List<&2, Attr>, kids: List<&2, Element>, txt: String, +acc: String,
  children: List<&2, Element> -> String -> String) -> String:
  +isDocument = U.string.equal(n, "#document")
  +isText = U.string.equal(n, "#text")
  +open = U.branch(String, isDocument || isText, _ => acc,
    _ => SCon{Chr{62}, serialize.attrs.rev(as, U.rev(n, SCon{Chr{60}, acc}))})
  +body = children(U.choose(List<&2, Element>, isText, Nil{}, kids))(U.choose(String, isDocument, open, escape.rev(txt, open)))
  U.branch(String, isDocument || isText, _ => body, _ => SCon{Chr{62}, U.rev(n, SCon{Chr{47}, SCon{Chr{60}, body}})})

@unsafe
def serialize.nodes.rev(xs: List<&2, Element>, acc: String) -> String:
  match xs:
    case Nil{}: acc
    case Con{Element{n, as, kids, txt}, rest}:
      serialize.nodes.rev(rest, serialize.element(n, as, kids, txt, acc, nodes => tail => serialize.nodes.rev(nodes, tail)))

def serialize.nodes(xs: List<&2, Element>) -> String:
  U.rev(serialize.nodes.rev(xs, ""), "")

def serialize(root: Element) -> String:
  serialize.nodes(Con{root, Nil{}})

# The number of elements in a forest, the roots included.
# Which of four element names the tree holds, as bits: 1 image, 2 use, 4 text, 8 style.
def elements.kinds(xs: List<&2, Element>, +acc: U32) -> U32:
  match xs:
    case Nil{}: acc
    case Con{Element{name, attrs, kids, text}, rest}:
      +n = name
      elements.kinds(rest, elements.kinds(kids, U32.or(acc, U.choose(U32, U.string.equal(n, "image"), 1,
        U.choose(U32, U.string.equal(n, "use"), 2, U.choose(U32, U.string.equal(n, "text"), 4, U.choose(U32, U.string.equal(n, "style"), 8, 0)))))))

def elements.count(xs: List<&2, Element>) -> U32:
  match xs:
    case Nil{}: 0
    case Con{Element{name, attrs, kids, text}, rest}: (1 + elements.count(kids) + elements.count(rest) : U32)
