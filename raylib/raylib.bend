# gralha-raylib: a raylib window for Bend programs, driven by command lists.
# A frame is a List<U32> of draw commands built with the helpers below and
# joined with List.append; input comes back as words. Native (C) only: see
# README.md for the build flags.
import Base

# Effects
# =======

# Opens the window (and the audio device). One window per program.
def open(title: String, w: U32, h: U32) -> IO(Unit):
  import "./effs/raylib.c"

# Runs a command list: draws are presented as one frame, meta commands
# (uploads, queries, close) are applied in order.
def send(cmds: List<U32>) -> IO(Unit):
  import "./effs/raylib.c"

# The pending query replies if there are any, else this frame's input:
# [held, mouse, events..] (see README.md).
def poll() -> IO(List<U32>):
  import "./effs/raylib.c"

# Words
# =====

# A string as its code points.
def words(s: String) -> List<U32>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{Chr{c}, t}:
      Con{c, words(t)}

def sized.step(h: U32, r: U32 & List<U32>) -> U32 & List<U32>:
  match r:
    case Tuple{n, t}:
      ((n + 1 : U32), Con{h, t})

# A list beside its length.
def sized(xs: List<U32>) -> U32 & List<U32>:
  match xs:
    case Nil{}:
      (0, Nil{})
    case Con{h, t}:
      sized.step(h, sized(t))

def counted.of(r: U32 & List<U32>) -> List<U32>:
  match r:
    case Tuple{n, t}:
      Con{n, t}

# The length of `xs`, then `xs`.
def counted(xs: List<U32>) -> List<U32>:
  counted.of(sized(xs))

# The first word of a reply, or 0.
def first(ws: List<U32>) -> U32:
  match ws:
    case Nil{}:
      0
    case Con{w, rest}:
      w

def is_one(+w: U32) -> Bool:
  U32.is_eq(w, 1)

# Draw commands
# =============
# Colors are 0xAARRGGBB; an alpha of 0 is opaque. Coordinates are pixels,
# as two's-complement words.

def clear(color: U32) -> List<U32>:
  [0, color]

def rect(x: U32, y: U32, w: U32, h: U32, color: U32) -> List<U32>:
  [1, x, y, w, h, color]

def rect_lines(x: U32, y: U32, w: U32, h: U32, color: U32) -> List<U32>:
  [2, x, y, w, h, color]

# ASCII text (other code points draw as '?'), in the loaded font if any.
def text(x: U32, y: U32, size: U32, color: U32, s: String) -> List<U32>:
  Con{3, Con{x, Con{y, Con{size, Con{color, counted(words(s))}}}}}

def circle(x: U32, y: U32, r: U32, color: U32) -> List<U32>:
  [4, x, y, r, color]

def line(x1: U32, y1: U32, x2: U32, y2: U32, color: U32) -> List<U32>:
  [5, x1, y1, x2, y2, color]

# Draws the (sx, sy, sw, sh) part of texture `id` at (dx, dy), scaled by
# scale/256, mirrored when flip is 1, multiplied by tint.
def sprite(id: U32, sx: U32, sy: U32, sw: U32, sh: U32, dx: U32, dy: U32, scale: U32, flip: U32, tint: U32) -> List<U32>:
  [6, id, sx, sy, sw, sh, dx, dy, scale, flip, tint]

def play(id: U32) -> List<U32>:
  [7, id]

# Calls
# =====

# Draws one frame.
def frame(cmds: List<U32>) -> IO(Unit):
  send(cmds)

# This frame's input: [held, mouse, events..].
def input() -> IO(List<U32>):
  poll()

# Sends commands whose last one asks for a reply, and answers it.
def query(cmds: List<U32>) -> IO(U32):
  do IO<U32>:
    send(cmds)
    ws : List<U32> <- poll()
    return first(ws)

# Uploads a w*h RGBA texture (four bytes per pixel, one byte per word);
# answers its id, or 0xFFFFFFFF if it does not fit.
def texture(w: U32, h: U32, rgba: List<U32>) -> IO(U32):
  query(Con{20, Con{w, Con{h, counted(rgba)}}})

# Uploads an 8-bit mono 22050 Hz sound (one sample per word); answers its id.
def sound(samples: List<U32>) -> IO(U32):
  query(Con{21, counted(samples)})

# Loads a TrueType font for text; answers whether it loaded.
def font(path: String) -> IO(Bool):
  do IO<Bool>:
    r : U32 <- query(Con{22, counted(words(path))})
    return is_one(r)

def clipboard(s: String) -> IO(Unit):
  send(Con{23, counted(words(s))})

def screenshot(path: String) -> IO(Unit):
  send(Con{24, counted(words(path))})

# Whether the user asked to close the window.
def should_close() -> IO(Bool):
  do IO<Bool>:
    r : U32 <- query([26])
    return is_one(r)

# The width in pixels of `s` drawn at `size`.
def text_width(size: U32, s: String) -> IO(U32):
  query(Con{27, Con{size, counted(words(s))}})

# Closes the window and the audio device.
def close() -> IO(Unit):
  send([25])

# Input
# =====

# The mouse word: x in bits 0-11, y in 12-23, then the buttons.
def mouse_x(+m: U32) -> U32:
  (m .&. 4095 : U32)

def mouse_y(+m: U32) -> U32:
  ((m >> 12n) .&. 4095 : U32)

# Whether bit `b` of a word is set (a held key, a mouse button).
def bit(+w: U32, +b: Nat) -> Bool:
  U32.is_eq(((w >> b) .&. 1 : U32), 1)
