# gralha-http-server

An HTTP/1.1 server over Base's TCP, on `gralha-http-core`. It takes one
connection at a time, reads one request (until it is whole, the peer stops
sending, or a byte cap), answers it and closes the connection. The app's
state threads through the handler, which is a template (`~`): a closure is
affine and could run only once, a template runs inline every time.

    import gralha-http-server@0.1.0.0/server.bend as Server

```python
def handle(r: Http.Request, +hits: U32) -> IO(U32 & Http.Response):
  IO.pure(U32 & Http.Response, ((hits + 1 : U32), Http.ok("text/plain", "hello")))

def main() -> IO(Unit):
  do IO<Unit>:
    listener : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 8080))
    done : Listener & U32 <- Server.serve(~U32, ~(r => s => handle(r, s)), listener, 0, 1048576)
    ...
```

- `serve(~S, ~handle, listener, state, max)`: forever; `handle(request)(state)`
  answers `IO(S & Http.Response)`, sent with `Connection: close`.
- `serve.socket(~S, ~reply, ...)`: forever; `reply(socket)(request)(state)`
  answers on the socket itself and must close it, for a body the app writes
  through its own effect (the svg demo streams PNG frames this way).
- `serve.for` and `serve.socket.for` take a `Nat` and serve that many
  connections, then hand back the listener and the state.
- `step` and `step.socket` serve one connection.
- `read(socket, max)` and `read.text`, `send(socket, response)` and
  `send.text`, `closing(response)`.

A request that never parses gets a 400; a failed accept is skipped. `serve`
and `serve.socket` never end, so they are `@unsafe` (`def serve?`), as the
loop of a server must be; reading is `@unsafe` too, since a socket can
always send more. `serve.for` itself recurses on its count.

Depends on: `gralha-http-core`. Tests: `tests/run.sh` serves
`tests/serve.bend` on the JS lane and natively and drives it with curl and nc
(`BEND="bun …/bend2/main.ts" ./tests/run.sh`).
