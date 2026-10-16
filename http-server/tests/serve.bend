import Base
import gralha-http-core@0.1.0.0/http.bend as Http
import ../server.bend as Server

# Serves five requests through a handler counting them, then one more
# through a handler that writes its own reply, then prints the count.
def route(+r: Http.Request, +n: U32) -> Http.Response:
  Http.when(Http.Response, Http.request.is(r, "GET", "/"),
    _ => Http.ok("text/plain", "hello " ++ U32.show(n)),
    _ => Http.when(Http.Response, Http.request.is(r, "POST", "/echo"),
      _ => Http.response.with(Http.ok("text/plain; charset=utf-8", Http.request.body(r)), "X-Count", U32.show(n)),
      _ => Http.when(Http.Response, Http.request.is(r, "GET", "/q"),
        _ => Http.ok("text/plain; charset=utf-8", Maybe.default(&2, String, Http.request.query(r, "name"), "?")),
        _ => Http.status(404))))

def handle(r: Http.Request, +n: U32) -> IO(U32 & Http.Response):
  IO.pure(U32 & Http.Response, ((n + 1 : U32), route(r, n)))

def raw(socket: Socket, r: Http.Request, +n: U32) -> IO(U32):
  do IO<U32>:
    Unit <- Server.send.text(socket, "HTTP/1.1 200 OK\r\nContent-Length: 3\r\nConnection: close\r\n\r\nraw")
    return (n + 1 : U32)

def finish(got: Listener & U32) -> IO(Unit):
  (listener, n) = got
  do IO<Unit>:
    Unit <- Listener.close(listener)
    IO.print("served " ++ U32.show(n))

def rest(got: Listener & U32) -> IO(Unit):
  (listener, n) = got
  do IO<Unit>:
    next : Listener & U32 <- Server.serve.socket.for(~U32, ~(s => r => n => raw(s, r, n)), 1n, listener, n, 1024)
    finish(next)

def main() -> IO(Unit):
  do IO<Unit>:
    listener : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 18089))
    got : Listener & U32 <- Server.serve.for(~U32, ~(r => n => handle(r, n)), 5n, listener, 0, 1048576)
    rest(got)
