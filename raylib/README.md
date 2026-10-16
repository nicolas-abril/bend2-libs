# gralha-raylib

A [raylib](https://www.raylib.com) window for Bend programs: drawing,
textures, sounds, a TrueType font, the clipboard, screenshots and input,
all driven by word-encoded command lists. Extracted from BendQuest's
client.

```python
import gralha-raylib@0.1.0.0/raylib.bend as RL
```

```python
def main() -> IO(Unit):
  do IO<Unit>:
    RL.open("hello", 320, 200)
    RL.frame(List.append(&1, U32, RL.clear(0), RL.text(10, 10, 20, 4294967295, "hi")))
    RL.close()
```

`tests/smoke.bend` is a complete program.

## Build

Native only (there is no JavaScript twin), and raylib must be linked, which
`bend -o <binary>` does not do. Emit C and link it yourself; on macOS with
Homebrew raylib (`brew install raylib`):

```sh
bend app.bend -o app.c
clang -std=c11 -w -O1 app.c -o app \
  -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
  -framework Cocoa -framework IOKit -framework CoreVideo \
  -framework CoreAudio -framework AudioToolbox
```

On Linux, link `-lraylib -lGL -lpthread -lm -ldl -lrt -lX11` instead of the
frameworks. The C side (`effs/raylib.c`) uses Bend's runtime internals, which
carry no ABI promise: it is built and tested against Bend 2.0.37.

## API

Effects: `open(title, w, h)`, `send(cmds)` and `poll()`. Everything else is
built on them:

| call | does |
| --- | --- |
| `frame(cmds)` | draws one frame (`send`) |
| `input()` | this frame's input (`poll`) |
| `texture(w, h, rgba)` | uploads RGBA bytes (one per word); answers the texture id |
| `sound(samples)` | uploads 8-bit mono 22050 Hz samples; answers the sound id |
| `font(path)` | loads a TrueType font for text; answers whether it loaded |
| `text_width(size, s)` | the width in pixels of `s` at `size` |
| `clipboard(s)`, `screenshot(path)` | set the clipboard, save a PNG |
| `should_close()` | whether the user closed the window |
| `close()` | closes the window and the audio device |

Draw commands, each a `List<U32>` to join with `List.append`: `clear(color)`,
`rect(x, y, w, h, color)`, `rect_lines(..)`, `text(x, y, size, color, s)`,
`circle(x, y, r, color)`, `line(x1, y1, x2, y2, color)`,
`sprite(id, sx, sy, sw, sh, dx, dy, scale, flip, tint)` (scale is /256,
flip 1 mirrors) and `play(id)`. Colors are `0xAARRGGBB` words; an alpha of 0
is opaque. Text is ASCII. Up to 64 textures and 32 sounds.

## Input

`input()` answers `[held, mouse, events..]`:

- `held`: bit 0..19 for Left, Right, Up, Down, W, A, S, D, Space, Shift,
  Enter, Escape, Tab, E, Q, I, C, H, X, Backspace held down.
- `mouse`: x in bits 0-11, y in bits 12-23, then left and right button held
  (bits 24, 25) and pressed this frame (26, 27). `mouse_x`, `mouse_y` and
  `bit(w, n)` read it.
- `events`: each key pressed this frame as `0x10000000 | key` (raylib key
  codes) and each character typed as `0x20000000 | code point`.

A query (`texture`, `sound`, `font`, `text_width`, `should_close`, or
`query(cmds)` with your own) answers before the next `input()`.

## Wire format

For `send` and `query`: draw opcodes 0 clear, 1 rect, 2 rect lines, 3 text
(`x y size color n cp*n`), 4 circle, 5 line, 6 sprite, 7 play; meta opcodes
20 texture (`w h n byte*n`), 21 sound (`n byte*n`), 22 font (`n cp*n`),
23 clipboard, 24 screenshot, 25 close, 26 should-close, 27 text width
(`size n cp*n`). A malformed command stops the list.
