# Opens a window, uploads a texture and a sound, loads no font, draws a
# few frames, saves a screenshot, then closes. Build it natively (see
# ../README.md) and run it in a graphical session.
import Base
import ../raylib.bend as RL

# A 2x2 RGBA checker: red, green, blue, white.
def checker() -> List<U32>:
  [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255]

def scene(+t: U32, +tex: U32) -> List<U32>:
  List.append(&1, U32, RL.clear(4280295472),
  List.append(&1, U32, RL.rect((10 + t : U32), 10, 60, 40, 4292886592),
  List.append(&1, U32, RL.rect_lines(80, 10, 60, 40, 4282441792),
  List.append(&1, U32, RL.circle(200, 40, 20, 4282400992),
  List.append(&1, U32, RL.line(10, 100, 300, 100, 4294967295),
  List.append(&1, U32, RL.sprite(tex, 0, 0, 2, 2, 20, 120, 4096, 0, 4294967295),
  RL.text(150, 120, 20, 4294967040, "gralha-raylib")))))))

def frames(+n: Nat, +tex: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        ws : List<U32> <- RL.input()
        RL.frame(scene(U32.from_nat(p), tex))
        frames(p, tex)

def main() -> IO(Unit):
  do IO<Unit>:
    RL.open("gralha-raylib smoke", 320, 200)
    +tex : U32 <- RL.texture(2, 2, checker())
    snd : U32 <- RL.sound([128, 200, 128, 56, 128])
    w : U32 <- RL.text_width(20, "gralha")
    frames(30n, tex)
    RL.screenshot("smoke.png")
    RL.frame(RL.clear(0))
    shut : Bool <- RL.should_close()
    RL.close()
    IO.print("texture " ++ U32.show(tex) ++ ", sound " ++ U32.show(snd) ++ ", text width>0 " ++ Bool.show(U32.is_gt(w, 0)))

#| texture 0, sound 0, text width>0 True
