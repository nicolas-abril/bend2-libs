# HTTP/1.1 messages: requests parsed from text, responses serialized to it.
# Pure: no IO, no foreign code. A server reads the text from a socket
# (gralha-http-server); a header name compares without case.
import Base

# Utilities
# =========

# One of two computations, run on c; only the chosen one runs.
def when(-A: Type, c: Bool, yes: Unit -> A, no: Unit -> A) -> A:
  match c:
    case True{}:
      yes(Unit{})
    case False{}:
      no(Unit{})

# The text before the first sep and the text after it, or None without sep.
def cut.go(s: String, +sep: String, +acc: String) -> Maybe<&1, String & String>:
  match s:
    case SNil{}:
      None{}
    case SCon{+h, +t}:
      when(Maybe<&1, String & String>, String.starts_with(SCon{h, t}, sep),
        _ => Some{(String.reverse(acc), String.drop(SCon{h, t}, String.length(sep)))},
        _ => cut.go(t, sep, SCon{h, acc}))

def cut(s: String, +sep: String) -> Maybe<&1, String & String>:
  cut.go(s, sep, "")

def before.cut(c: Maybe<&1, String & String>, whole: String) -> String:
  match c:
    case None{}:
      whole
    case Some{(a, b)}:
      a

# The text before sep, or all of it without sep.
def before(+s: String, +sep: String) -> String:
  before.cut(cut(s, sep), s)

def after.cut(c: Maybe<&1, String & String>) -> String:
  match c:
    case None{}:
      ""
    case Some{(a, b)}:
      b

# The text after sep, or "" without sep.
def after(s: String, +sep: String) -> String:
  after.cut(cut(s, sep))

# UTF-8
# =====

def utf8.width(+c: U32) -> U32:
  when(U32, U32.is_lt(c, 128), _ => 1, _ => when(U32, U32.is_lt(c, 2048), _ => 2,
    _ => when(U32, U32.is_lt(c, 65536), _ => 3, _ => 4)))

def utf8.count(s: String, acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{Chr{c}, t}:
      utf8.count(t, (acc + utf8.width(c) : U32))

# The bytes a text takes in UTF-8, as Content-Length counts them.
def utf8.length(s: String) -> U32:
  utf8.count(s, 0)

# A character's UTF-8 bytes, prepended to acc in reverse.
def utf8.push(+c: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  +cont = ((c .&. 63) .|. 128 : U32)
  when(List<&2, U32>, U32.is_lt(c, 128), _ => c <> acc,
    _ => when(List<&2, U32>, U32.is_lt(c, 2048),
      _ => cont <> ((c >> 6n) .|. 192 : U32) <> acc,
      _ => when(List<&2, U32>, U32.is_lt(c, 65536),
        _ => cont <> (((c >> 6n) .&. 63) .|. 128 : U32) <> ((c >> 12n) .|. 224 : U32) <> acc,
        _ => cont <> (((c >> 6n) .&. 63) .|. 128 : U32) <> (((c >> 12n) .&. 63) .|. 128 : U32)
          <> ((c >> 18n) .|. 240 : U32) <> acc)))

# Decoding reads a byte at a time: need is the continuation bytes still
# owed and code the bits so far. A byte out of place is U+FFFD.
def utf8.need(+b: U32, +need: U32) -> U32:
  when(U32, U32.is_eq(need, 0),
    _ => when(U32, U32.is_ge(b, 240), _ => 3, _ => when(U32, U32.is_ge(b, 224), _ => 2,
      _ => when(U32, U32.is_ge(b, 192), _ => 1, _ => 0))),
    _ => when(U32, U32.is_eq((b .&. 192 : U32), 128), _ => (need - 1 : U32), _ => 0))

def utf8.code(+b: U32, +need: U32, +code: U32) -> U32:
  when(U32, U32.is_eq(need, 0),
    _ => when(U32, U32.is_ge(b, 240), _ => (b .&. 7 : U32), _ => when(U32, U32.is_ge(b, 224),
      _ => (b .&. 15 : U32), _ => (b .&. 31 : U32))),
    _ => ((code << 6n) .|. (b .&. 63) : U32))

def utf8.emit(+b: U32, +need: U32, +code: U32, +acc: String) -> String:
  when(String, U32.is_eq(need, 0),
    _ => when(String, U32.is_lt(b, 128), _ => SCon{Chr{b}, acc},
      _ => when(String, U32.is_ge(b, 192), _ => acc, _ => SCon{Chr{65533}, acc})),
    _ => when(String, U32.is_eq((b .&. 192 : U32), 128),
      _ => when(String, U32.is_eq(need, 1), _ => SCon{Chr{utf8.code(b, need, code)}, acc}, _ => acc),
      _ => SCon{Chr{65533}, acc}))

def utf8.decode.go(bytes: List<&2, U32>, +need: U32, +code: U32, acc: String) -> String:
  match bytes:
    case Nil{}:
      String.reverse(acc)
    case Con{+b, t}:
      utf8.decode.go(t, utf8.need(b, need), utf8.code(b, need, code), utf8.emit(b, need, code, acc))

def utf8.decode(bytes: List<&2, U32>) -> String:
  utf8.decode.go(bytes, 0, 0, "")

# Urls
# ====

def hex.digit(+c: U32) -> U32:
  when(U32, U32.is_le(c, 57), _ => (c - 48 : U32),
    _ => when(U32, U32.is_le(c, 70), _ => (c - 55 : U32), _ => (c - 87 : U32)))

def hex.is_digit(+c: U32) -> Bool:
  (U32.is_ge(c, 48) && U32.is_le(c, 57)) || (U32.is_ge(c, 65) && U32.is_le(c, 70))
    || (U32.is_ge(c, 97) && U32.is_le(c, 102))

def url.bytes(s: String, +acc: List<&2, U32>) -> List<&2, U32>:
  match s:
    case SNil{}:
      List.reverse(&2, U32, acc)
    case SCon{Chr{+c}, SCon{Chr{+x}, SCon{Chr{+y}, +t}}}:
      when(List<&2, U32>, U32.is_eq(c, 37) && hex.is_digit(x) && hex.is_digit(y),
        _ => url.bytes(t, (hex.digit(x) * 16 + hex.digit(y) : U32) <> acc),
        _ => url.bytes(SCon{Chr{x}, SCon{Chr{y}, t}},
          utf8.push(when(U32, U32.is_eq(c, 43), _ => 32, _ => c), acc)))
    case SCon{Chr{+c}, t}:
      url.bytes(t, utf8.push(when(U32, U32.is_eq(c, 43), _ => 32, _ => c), acc))

# A url component with %XX escapes and + (a space, as forms send it)
# decoded; the bytes read as UTF-8.
def url.decode(s: String) -> String:
  utf8.decode(url.bytes(s, Nil{}))

# A target's path: the part before ?.
def target.path(+target: String) -> String:
  before(target, "?")

# A target's query: the part after ?, or "".
def target.query(target: String) -> String:
  after(target, "?")

def query.find(pairs: List<&2, String>, +name: String) -> Maybe<&2, String>:
  match pairs:
    case Nil{}:
      None{}
    case Con{+p, t}:
      when(Maybe<&2, String>, String.eq(url.decode(before(p, "=")), name),
        _ => Some{url.decode(after(p, "="))}, _ => query.find(t, name))

# The first value of a query parameter, decoded, e.g. query.get("a=1&b=x%20y", "b").
def query.get(query: String, +name: String) -> Maybe<&2, String>:
  query.find(String.split(query, '&'), name)

# Headers
# =======

type Header is Data:
  Header{name: String, value: String}

# The value of the first header named name, any case.
def header.find(headers: List<&2, Header>, +name: String) -> Maybe<&2, String>:
  match headers:
    case Nil{}:
      None{}
    case Con{Header{n, v}, t}:
      when(Maybe<&2, String>, String.eq(String.to_lower(n), name),
        _ => Some{v}, _ => header.find(t, name))

def header.get(headers: List<&2, Header>, name: String) -> Maybe<&2, String>:
  header.find(headers, String.to_lower(name))

def header.has(headers: List<&2, Header>, name: String) -> Bool:
  Maybe.is_some(&2, String, header.get(headers, name))

def header.line(c: Maybe<&1, String & String>, rest: List<&2, Header>) -> List<&2, Header>:
  match c:
    case None{}:
      rest
    case Some{(n, v)}:
      Header{String.trim(n), String.trim(v)} <> rest

# Header lines, "Name: value" each; a line with no colon is skipped.
def header.parse(lines: List<&2, String>) -> List<&2, Header>:
  match lines:
    case Nil{}:
      Nil{}
    case Con{l, t}:
      header.line(cut(l, ":"), header.parse(t))

def header.text(headers: List<&2, Header>) -> String:
  match headers:
    case Nil{}:
      ""
    case Con{Header{n, v}, t}:
      n ++ ": " ++ v ++ "\r\n" ++ header.text(t)

def digits(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+c}, t}:
      U32.is_ge(c, 48) && U32.is_le(c, 57) && digits(t)

# A decimal number made of digits only, as Content-Length is.
def number(+s: String) -> Maybe<&2, U32>:
  when(Maybe<&2, U32>, digits(s), _ => U32.read(s), _ => None{})

def number.or_zero(m: Maybe<&2, String>) -> U32:
  match m:
    case None{}:
      0
    case Some{s}:
      Maybe.default(&2, U32, number(s), 0)

# The Content-Length a header list declares, or 0.
def content.length(headers: List<&2, Header>) -> U32:
  number.or_zero(header.get(headers, "content-length"))

# Requests
# ========

type Request is Data:
  Request{method: String, target: String, version: String, headers: List<&2, Header>, body: String}

def request.line(parts: List<&2, String>, headers: List<&2, Header>, body: String) -> Maybe<&2, Request>:
  match parts:
    case Con{m, Con{t, Con{v, Nil{}}}}:
      Some{Request{m, t, v, headers, body}}
    case _:
      None{}

def request.head(lines: List<&2, String>, body: String) -> Maybe<&2, Request>:
  match lines:
    case Nil{}:
      None{}
    case Con{first, rest}:
      request.line(String.split(String.trim(first), ' '), header.parse(rest), body)

def request.cut(c: Maybe<&1, String & String>) -> Maybe<&2, Request>:
  match c:
    case None{}:
      None{}
    case Some{(head, body)}:
      request.head(String.split(head, '\n'), body)

# A request: "METHOD target HTTP/x.y", header lines, a blank line, the body
# (all that follows it). None when the head is unfinished or malformed.
def request.parse(text: String) -> Maybe<&2, Request>:
  request.cut(cut(text, "\r\n\r\n"))

def request.complete.cut(c: Maybe<&1, String & String>) -> Bool:
  match c:
    case None{}:
      False{}
    case Some{(head, body)}:
      U32.is_ge(utf8.length(body), content.length(header.parse(String.split(head, '\n'))))

# Whether text holds a whole request: its head ended, and as many body bytes
# as its Content-Length (none without one).
def request.complete(text: String) -> Bool:
  request.complete.cut(cut(text, "\r\n\r\n"))

def request.method(r: Request) -> String:
  match r:
    case Request{m, t, v, h, b}:
      m

def request.target(r: Request) -> String:
  match r:
    case Request{m, t, v, h, b}:
      t

def request.path(r: Request) -> String:
  match r:
    case Request{m, t, v, h, b}:
      target.path(t)

def request.body(r: Request) -> String:
  match r:
    case Request{m, t, v, h, b}:
      b

# A header of the request, any case.
def request.header(r: Request, name: String) -> Maybe<&2, String>:
  match r:
    case Request{m, t, v, h, b}:
      header.get(h, name)

# A query parameter of the request's target, decoded.
def request.query(r: Request, +name: String) -> Maybe<&2, String>:
  match r:
    case Request{m, t, v, h, b}:
      query.get(target.query(t), name)

# Whether the request is method on path, e.g. request.is(r, "GET", "/").
def request.is(+r: Request, method: String, path: String) -> Bool:
  String.eq(request.method(r), method) && String.eq(request.path(r), path)

# Responses
# =========

type Response is Data:
  Response{status: U32, headers: List<&2, Header>, body: String}

# The reason phrase of a status code, or "" for one not listed.
def reason(+code: U32) -> String:
  match code:
    case 200: "OK"
    case 201: "Created"
    case 202: "Accepted"
    case 204: "No Content"
    case 206: "Partial Content"
    case 100: "Continue"
    case 101: "Switching Protocols"
    case 301: "Moved Permanently"
    case 302: "Found"
    case 303: "See Other"
    case 304: "Not Modified"
    case 307: "Temporary Redirect"
    case 308: "Permanent Redirect"
    case 400: "Bad Request"
    case 401: "Unauthorized"
    case 403: "Forbidden"
    case 404: "Not Found"
    case 405: "Method Not Allowed"
    case 406: "Not Acceptable"
    case 408: "Request Timeout"
    case 409: "Conflict"
    case 410: "Gone"
    case 411: "Length Required"
    case 413: "Content Too Large"
    case 414: "URI Too Long"
    case 415: "Unsupported Media Type"
    case 416: "Range Not Satisfiable"
    case 422: "Unprocessable Content"
    case 429: "Too Many Requests"
    case 500: "Internal Server Error"
    case 501: "Not Implemented"
    case 502: "Bad Gateway"
    case 503: "Service Unavailable"
    case 504: "Gateway Timeout"
    case _: ""

# A response with a status, a Content-Type and a body.
def response(+status: U32, content_type: String, body: String) -> Response:
  Response{status, [Header{"Content-Type", content_type}], body}

# A 200 response with a Content-Type and a body.
def ok(content_type: String, body: String) -> Response:
  response(200, content_type, body)

# A plain-text response with the status's reason phrase as its body.
def status(+code: U32) -> Response:
  response(code, "text/plain; charset=utf-8", reason(code))

# The response with one more header, after the ones it has.
def response.with(r: Response, name: String, value: String) -> Response:
  match r:
    case Response{s, h, b}:
      Response{s, List.append(&2, Header, h, [Header{name, value}]), b}

def response.status(r: Response) -> U32:
  match r:
    case Response{s, h, b}:
      s

# The status line and the header lines, up to the blank line: what a server
# sends before a body it writes itself.
def head(+status: U32, headers: List<&2, Header>) -> String:
  "HTTP/1.1 " ++ U32.show(status) ++ " " ++ reason(status) ++ "\r\n" ++ header.text(headers) ++ "\r\n"

def length.with(+headers: List<&2, Header>, +body: String) -> List<&2, Header>:
  when(List<&2, Header>, header.has(headers, "content-length"), _ => headers,
    _ => List.append(&2, Header, headers, [Header{"Content-Length", U32.show(utf8.length(body))}]))

# The response as sent: its head, with a Content-Length counted in UTF-8
# bytes after its own headers (unless it has one), then its body.
def response.text(r: Response) -> String:
  match r:
    case Response{+s, h, +b}:
      head(s, length.with(h, b)) ++ b

# Laws
# ====

law ok_is_200:
  for t: String
  for b: String
  {response.status(ok(t, b)) == 200 : U32}

def ok_is_200(t, b):
  {==}

law with_keeps_status:
  for r: Response
  for n: String
  for v: String
  {response.status(response.with(r, n, v)) == response.status(r) : U32}

def with_keeps_status(r, n, v):
  match r:
    case Response{s, h, b}:
      {==}
