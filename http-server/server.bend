# An HTTP/1.1 server over Base's TCP: one request per connection, answered
# and closed, one connection at a time. The app's state threads through
# the handler, a template (~), so it runs inline and may run every time.
import Base
import gralha-http-core@0.1.0.0/http.bend as Http

# Reading
# =======

def read.chunk(socket: Socket, +text: String, +max: U32, next: Socket -> String -> IO(Socket & String)) ->
  IO(Socket & String):
  Http.when(Socket -> IO(Socket & String), Http.request.complete(text) || U32.is_gt(Http.utf8.length(text), max),
    _ => s => IO.pure(Socket & String, (s, text)), _ => s => next(s)(text))(socket)

def read.got(got: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>, acc: String, +max: U32,
  next: Socket -> String -> IO(Socket & String)) -> IO(Socket & String):
  (socket, result) = got
  match result:
    case Fail{err}:
      IO.pure(Socket & String, (socket, ""))
    case Done{None{}}:
      IO.pure(Socket & String, (socket, acc))
    case Done{Some{data}}:
      read.chunk(socket, acc ++ data, max, next)

def read.go?(socket: Socket, +max: U32, acc: String) -> IO(Socket & String):
  do IO<Socket & String>:
    got : Socket & Result<&1, &1, U32 & String, Maybe<&1, String>> <- TCP.recv(socket, 65536)
    read.got(got, acc, max, s => text => read.go(s, max, text))

# The request's text: received until it is whole (Http.request.complete),
# the peer stops sending, or more than max bytes arrived; "" on an error.
def read.text(socket: Socket, +max: U32) -> IO(Socket & String):
  read.go(socket, max, "")

def read.parse(got: Socket & String) -> IO(Socket & Maybe<&2, Http.Request>):
  (socket, text) = got
  IO.pure(Socket & Maybe<&2, Http.Request>, (socket, Http.request.parse(text)))

# The request read and parsed, or None if it never became one.
def read(socket: Socket, +max: U32) -> IO(Socket & Maybe<&2, Http.Request>):
  do IO<Socket & Maybe<&2, Http.Request>>:
    got : Socket & String <- read.text(socket, max)
    read.parse(got)

# Sending
# =======

# A failed send also hands back the unsent rest, which a closing reply drops.
def send.done(got: Socket & Result<&1, &1, (U32 & String) & String, Unit>) -> IO(Unit):
  (socket, result) = got
  Socket.close(socket)

# Sends text as it is and closes the socket.
def send.text(socket: Socket, text: String) -> IO(Unit):
  do IO<Unit>:
    sent : Socket & Result<&1, &1, (U32 & String) & String, Unit> <- TCP.send(socket, text)
    send.done(sent)

# The response with Connection: close, unless it names a Connection.
def closing(r: Http.Response) -> Http.Response:
  match r:
    case Http.Response{+s, +h, +b}:
      Http.when(Http.Response, Http.header.has(h, "connection"), _ => Http.Response{s, h, b},
        _ => Http.response.with(Http.Response{s, h, b}, "Connection", "close"))

# Sends a response (Http.response.text, with Connection: close) and closes
# the socket.
def send(socket: Socket, r: Http.Response) -> IO(Unit):
  send.text(socket, Http.response.text(closing(r)))

# Serving
# =======

def answer.sent(-S: Type, socket: Socket, out: S & Http.Response) -> IO(S):
  (state, r) = out
  do IO<S>:
    Unit <- send(socket, r)
    return state

def answer(~S: Type, ~handle: Http.Request -> S -> IO(S & Http.Response),
  got: Socket & Maybe<&2, Http.Request>, state: S) -> IO(S):
  (socket, request) = got
  match request:
    case None{}:
      do IO<S>:
        Unit <- send(socket, Http.status(400))
        return state
    case Some{r}:
      do IO<S>:
        out : S & Http.Response <- handle(r)(state)
        answer.sent(S, socket, out)

def answer.socket(~S: Type, ~reply: Socket -> Http.Request -> S -> IO(S),
  got: Socket & Maybe<&2, Http.Request>, state: S) -> IO(S):
  (socket, request) = got
  match request:
    case None{}:
      do IO<S>:
        Unit <- send(socket, Http.status(400))
        return state
    case Some{r}:
      reply(socket)(r)(state)

def accepted(~S: Type, ~handle: Http.Request -> S -> IO(S & Http.Response),
  got: Listener & Result<&1, &1, U32 & String, Socket>, state: S, +max: U32) -> IO(Listener & S):
  (listener, result) = got
  match result:
    case Fail{err}:
      IO.pure(Listener & S, (listener, state))
    case Done{socket}:
      do IO<Listener & S>:
        request : Socket & Maybe<&2, Http.Request> <- read(socket, max)
        next : S <- answer(~S, ~handle, request, state)
        return (listener, next)

def accepted.socket(~S: Type, ~reply: Socket -> Http.Request -> S -> IO(S),
  got: Listener & Result<&1, &1, U32 & String, Socket>, state: S, +max: U32) -> IO(Listener & S):
  (listener, result) = got
  match result:
    case Fail{err}:
      IO.pure(Listener & S, (listener, state))
    case Done{socket}:
      do IO<Listener & S>:
        request : Socket & Maybe<&2, Http.Request> <- read(socket, max)
        next : S <- answer.socket(~S, ~reply, request, state)
        return (listener, next)

# Accepts one connection, reads its request (up to max bytes), answers it
# with handle(request)(state) and closes it; a request that never parses
# gets a 400. A failed accept leaves the state as it was.
def step(~S: Type, ~handle: Http.Request -> S -> IO(S & Http.Response),
  listener: Listener, state: S, +max: U32) -> IO(Listener & S):
  do IO<Listener & S>:
    got : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(listener)
    accepted(~S, ~handle, got, state, max)

# As step, but reply(socket)(request)(state) answers on the socket itself
# and must close it: for bodies the app streams through its own effect.
def step.socket(~S: Type, ~reply: Socket -> Http.Request -> S -> IO(S),
  listener: Listener, state: S, +max: U32) -> IO(Listener & S):
  do IO<Listener & S>:
    got : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(listener)
    accepted.socket(~S, ~reply, got, state, max)

def loop.next(-S: Type, got: Listener & S, next: Listener -> S -> IO(Listener & S)) -> IO(Listener & S):
  (listener, state) = got
  next(listener)(state)

# Serves n connections, then hands back the listener and the state.
def serve.for(~S: Type, ~handle: Http.Request -> S -> IO(S & Http.Response),
  n: Nat, listener: Listener, state: S, +max: U32) -> IO(Listener & S):
  match n:
    case 0n:
      IO.pure(Listener & S, (listener, state))
    case 1n+p:
      do IO<Listener & S>:
        got : Listener & S <- step(~S, ~handle, listener, state, max)
        loop.next(S, got, l => s => serve.for(~S, ~handle, p, l, s, max))

def serve.socket.for(~S: Type, ~reply: Socket -> Http.Request -> S -> IO(S),
  n: Nat, listener: Listener, state: S, +max: U32) -> IO(Listener & S):
  match n:
    case 0n:
      IO.pure(Listener & S, (listener, state))
    case 1n+p:
      do IO<Listener & S>:
        got : Listener & S <- step.socket(~S, ~reply, listener, state, max)
        loop.next(S, got, l => s => serve.socket.for(~S, ~reply, p, l, s, max))

# Serves connections forever, one at a time (unsafe: it never ends).
def serve?(~S: Type, ~handle: Http.Request -> S -> IO(S & Http.Response),
  listener: Listener, state: S, +max: U32) -> IO(Listener & S):
  do IO<Listener & S>:
    got : Listener & S <- step(~S, ~handle, listener, state, max)
    loop.next(S, got, l => s => serve(~S, ~handle, l, s, max))

def serve.socket?(~S: Type, ~reply: Socket -> Http.Request -> S -> IO(S),
  listener: Listener, state: S, +max: U32) -> IO(Listener & S):
  do IO<Listener & S>:
    got : Listener & S <- step.socket(~S, ~reply, listener, state, max)
    loop.next(S, got, l => s => serve.socket(~S, ~reply, l, s, max))
