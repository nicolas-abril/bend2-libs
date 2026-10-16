import Base
import ../http.bend as Http

def bool(b: Bool) -> String:
  match b:
    case True{}: "true"
    case False{}: "false"

def opt(m: Maybe<&2, String>) -> String:
  match m:
    case None{}: "-"
    case Some{s}: "[" ++ s ++ "]"

def show.headers(hs: List<&2, Http.Header>) -> String:
  match hs:
    case Nil{}: ""
    case Con{Http.Header{n, v}, t}: n ++ "=" ++ v ++ ";" ++ show.headers(t)

def show.request(m: Maybe<&2, Http.Request>) -> String:
  match m:
    case None{}: "none"
    case Some{Http.Request{me, ta, ve, hs, bo}}:
      me ++ " " ++ ta ++ " " ++ ve ++ " {" ++ show.headers(hs) ++ "} " ++ bo

def visible.go(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{Chr{+c}, +t}:
      Http.when(String, U32.is_eq(c, 13), _ => "\\r" ++ visible.go(t),
        _ => Http.when(String, U32.is_eq(c, 10), _ => "\\n" ++ visible.go(t), _ => SCon{Chr{c}, visible.go(t)}))

def req() -> String:
  "POST /event?x=1&name=caf%C3%A9+au+lait HTTP/1.1\r\nHost: localhost\r\ncontent-LENGTH: 5\r\nX-Note:  é  \r\n\r\nhello"

def parts(m: Maybe<&2, Http.Request>) -> String:
  match m:
    case None{}: "unparsed"
    case Some{q}:
      +rq = q
      Http.request.method(rq) ++ " " ++ Http.request.path(rq) ++ " " ++ opt(Http.request.header(rq, "x-note")) ++ " "
        ++ opt(Http.request.query(rq, "x")) ++ " " ++ bool(Http.request.is(rq, "POST", "/event")) ++ " " ++ bool(Http.request.is(rq, "GET", "/event"))
        ++ " " ++ Http.request.body(rq)

def main() -> IO(Unit):
  +r = req()
  +parsed = Http.request.parse(r)
  do IO<Unit>:
    Unit <- IO.print(show.request(parsed))
    Unit <- IO.print(bool(Http.request.complete(r)) ++ " " ++ bool(Http.request.complete("POST / HTTP/1.1\r\nContent-Length: 6\r\n\r\nhello"))
      ++ " " ++ bool(Http.request.complete("GET / HTTP/1.1\r\nHost: x\r\n")) ++ " " ++ bool(Http.request.complete("GET / HTTP/1.1\r\n\r\n")))
    Unit <- IO.print(bool(Http.request.complete("POST / HTTP/1.1\r\nContent-Length: 2\r\n\r\né")))
    Unit <- IO.print(show.request(Http.request.parse("garbage\r\n\r\n")) ++ " " ++ show.request(Http.request.parse("GET / HTTP/1.1\r\n")))
    Unit <- IO.print(Http.target.path("/a/b?c=d") ++ " " ++ Http.target.query("/a/b?c=d") ++ " " ++ Http.target.path("/plain") ++ " [" ++ Http.target.query("/plain") ++ "]")
    Unit <- IO.print(opt(Http.query.get("x=1&name=caf%C3%A9+au+lait", "name")) ++ " " ++ opt(Http.query.get("x=1", "y")) ++ " " ++ opt(Http.query.get("flag&x=2", "flag")))
    Unit <- IO.print(Http.url.decode("%41%62c%2") ++ " " ++ Http.url.decode("%E2%82%AC%zz") ++ " " ++ U32.show(Http.utf8.length("aé€😀")))
    Unit <- IO.print(visible.go(Http.response.text(Http.ok("text/plain", "hé"))))
    Unit <- IO.print(visible.go(Http.response.text(Http.response.with(Http.response(404, "text/html", ""), "Connection", "close"))))
    Unit <- IO.print(visible.go(Http.response.text(Http.response.with(Http.status(204), "Content-Length", "0"))))
    Unit <- IO.print(visible.go(Http.head(299, [Http.Header{"X-A", "1"}])))
    IO.print(parts(parsed))

#|POST /event?x=1&name=caf%C3%A9+au+lait HTTP/1.1 {Host=localhost;content-LENGTH=5;X-Note=é;} hello
#|true false false true
#|true
#|none none
#|/a/b c=d /plain []
#|[café au lait] - []
#|Abc%2 €%zz 10
#|HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 3\r\n\r\nhé
#|HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: 0\r\n\r\n
#|HTTP/1.1 204 No Content\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 0\r\n\r\nNo Content
#|HTTP/1.1 299 \r\nX-A: 1\r\n\r\n
#|POST /event [é] [1] true false hello
