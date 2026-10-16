import Base
import ../svg.bend as SVG
import gralha-text-scan@0.1.0.0/scan.bend as U

def close(+a: U32, +b: U32) -> Bool:
  U32.is_le(U.choose(U32, U32.is_ge(a, b), (a - b : U32), (b - a : U32)), 1)

def pixel(+a: U32, +b: U32) -> Bool:
  close((a / 65536 : U32), (b / 65536 : U32)) && close(((a / 256) % 256 : U32), ((b / 256) % 256 : U32)) && close((a % 256 : U32), (b % 256 : U32))

def run(kind: String, src: String, bg: String, expected: U32) -> IO(Unit):
  IO.print(U.choose(String, pixel(SVG.color.pack(SVG.filter.blend(SVG.color(src), SVG.color(bg), SVG.filter.blend.mode(kind))), expected), "True", "False"))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- run("normal", "#cc8844", "#3380b3", 13404228)
    Unit <- run("normal", "#ffffff", "#000000", 16777215)
    Unit <- run("normal", "#000000", "#ffffff", 0)
    Unit <- run("normal", "#808080", "#c06030", 8421504)
    Unit <- run("normal", "#c06030", "#808080", 12607536)
    Unit <- run("normal", "#ff00ff", "#00ff00", 16711935)
    Unit <- run("normal", "#00ffff", "#ff0000", 65535)
    Unit <- run("normal", "#0101fe", "#fefe01", 66046)
    Unit <- run("multiply", "#cc8844", "#3380b3", 2704432)
    Unit <- run("multiply", "#ffffff", "#000000", 0)
    Unit <- run("multiply", "#000000", "#ffffff", 0)
    Unit <- run("multiply", "#808080", "#c06030", 6303768)
    Unit <- run("multiply", "#c06030", "#808080", 6303768)
    Unit <- run("multiply", "#ff00ff", "#00ff00", 0)
    Unit <- run("multiply", "#00ffff", "#ff0000", 0)
    Unit <- run("multiply", "#0101fe", "#fefe01", 65793)
    Unit <- run("screen", "#cc8844", "#3380b3", 14075079)
    Unit <- run("screen", "#ffffff", "#000000", 16777215)
    Unit <- run("screen", "#000000", "#ffffff", 16777215)
    Unit <- run("screen", "#808080", "#c06030", 14725272)
    Unit <- run("screen", "#c06030", "#808080", 14725272)
    Unit <- run("screen", "#ff00ff", "#00ff00", 16777215)
    Unit <- run("screen", "#00ffff", "#ff0000", 16777215)
    Unit <- run("screen", "#0101fe", "#fefe01", 16711422)
    Unit <- run("darken", "#cc8844", "#3380b3", 3375172)
    Unit <- run("darken", "#ffffff", "#000000", 0)
    Unit <- run("darken", "#000000", "#ffffff", 0)
    Unit <- run("darken", "#808080", "#c06030", 8413232)
    Unit <- run("darken", "#c06030", "#808080", 8413232)
    Unit <- run("darken", "#ff00ff", "#00ff00", 0)
    Unit <- run("darken", "#00ffff", "#ff0000", 0)
    Unit <- run("darken", "#0101fe", "#fefe01", 65793)
    Unit <- run("lighten", "#cc8844", "#3380b3", 13404339)
    Unit <- run("lighten", "#ffffff", "#000000", 16777215)
    Unit <- run("lighten", "#000000", "#ffffff", 16777215)
    Unit <- run("lighten", "#808080", "#c06030", 12615808)
    Unit <- run("lighten", "#c06030", "#808080", 12615808)
    Unit <- run("lighten", "#ff00ff", "#00ff00", 16777215)
    Unit <- run("lighten", "#00ffff", "#ff0000", 16777215)
    Unit <- run("lighten", "#0101fe", "#fefe01", 16711422)
    Unit <- run("overlay", "#cc8844", "#3380b3", 5408912)
    Unit <- run("overlay", "#ffffff", "#000000", 0)
    Unit <- run("overlay", "#000000", "#ffffff", 16777215)
    Unit <- run("overlay", "#808080", "#c06030", 12607536)
    Unit <- run("overlay", "#c06030", "#808080", 12607793)
    Unit <- run("overlay", "#ff00ff", "#00ff00", 65280)
    Unit <- run("overlay", "#00ffff", "#ff0000", 16711680)
    Unit <- run("overlay", "#0101fe", "#fefe01", 16645378)
    Unit <- run("color-dodge", "#cc8844", "#3380b3", 16777204)
    Unit <- run("color-dodge", "#ffffff", "#000000", 0)
    Unit <- run("color-dodge", "#000000", "#ffffff", 16777215)
    Unit <- run("color-dodge", "#808080", "#c06030", 16761184)
    Unit <- run("color-dodge", "#c06030", "#808080", 16764318)
    Unit <- run("color-dodge", "#ff00ff", "#00ff00", 65280)
    Unit <- run("color-dodge", "#00ffff", "#ff0000", 16711680)
    Unit <- run("color-dodge", "#0101fe", "#fefe01", 16777215)
    Unit <- run("color-burn", "#cc8844", "#3380b3", 4352)
    Unit <- run("color-burn", "#ffffff", "#000000", 0)
    Unit <- run("color-burn", "#000000", "#ffffff", 16777215)
    Unit <- run("color-burn", "#808080", "#c06030", 8454144)
    Unit <- run("color-burn", "#c06030", "#808080", 5636096)
    Unit <- run("color-burn", "#ff00ff", "#00ff00", 65280)
    Unit <- run("color-burn", "#00ffff", "#ff0000", 16711680)
    Unit <- run("color-burn", "#0101fe", "#fefe01", 0)
    Unit <- run("hard-light", "#cc8844", "#3380b3", 11372639)
    Unit <- run("hard-light", "#ffffff", "#000000", 16777215)
    Unit <- run("hard-light", "#000000", "#ffffff", 0)
    Unit <- run("hard-light", "#808080", "#c06030", 12607793)
    Unit <- run("hard-light", "#c06030", "#808080", 12607536)
    Unit <- run("hard-light", "#ff00ff", "#00ff00", 16711935)
    Unit <- run("hard-light", "#00ffff", "#ff0000", 65535)
    Unit <- run("hard-light", "#0101fe", "#fefe01", 131837)
    Unit <- run("soft-light", "#cc8844", "#3380b3", 5866650)
    Unit <- run("soft-light", "#ffffff", "#000000", 0)
    Unit <- run("soft-light", "#000000", "#ffffff", 16777215)
    Unit <- run("soft-light", "#808080", "#c06030", 12607536)
    Unit <- run("soft-light", "#c06030", "#808080", 10186840)
    Unit <- run("soft-light", "#ff00ff", "#00ff00", 65280)
    Unit <- run("soft-light", "#00ffff", "#ff0000", 16711680)
    Unit <- run("soft-light", "#0101fe", "#fefe01", 16645380)
    Unit <- run("difference", "#cc8844", "#3380b3", 10029167)
    Unit <- run("difference", "#ffffff", "#000000", 16777215)
    Unit <- run("difference", "#000000", "#ffffff", 16777215)
    Unit <- run("difference", "#808080", "#c06030", 4202576)
    Unit <- run("difference", "#c06030", "#808080", 4202576)
    Unit <- run("difference", "#ff00ff", "#00ff00", 16777215)
    Unit <- run("difference", "#00ffff", "#ff0000", 16777215)
    Unit <- run("difference", "#0101fe", "#fefe01", 16645629)
    Unit <- run("exclusion", "#cc8844", "#3380b3", 11370647)
    Unit <- run("exclusion", "#ffffff", "#000000", 16777215)
    Unit <- run("exclusion", "#000000", "#ffffff", 16777215)
    Unit <- run("exclusion", "#808080", "#c06030", 8421504)
    Unit <- run("exclusion", "#c06030", "#808080", 8421504)
    Unit <- run("exclusion", "#ff00ff", "#00ff00", 16777215)
    Unit <- run("exclusion", "#00ffff", "#ff0000", 16777215)
    Unit <- run("exclusion", "#0101fe", "#fefe01", 16645629)
    Unit <- run("hue", "#cc8844", "#3380b3", 10641954)
    Unit <- run("hue", "#ffffff", "#000000", 0)
    Unit <- run("hue", "#000000", "#ffffff", 16777215)
    Unit <- run("hue", "#808080", "#c06030", 7895160)
    Unit <- run("hue", "#c06030", "#808080", 8421504)
    Unit <- run("hue", "#ff00ff", "#00ff00", 16731903)
    Unit <- run("hue", "#00ffff", "#ff0000", 28013)
    Unit <- run("hue", "#0101fe", "#fefe01", 14671871)
    Unit <- run("saturation", "#cc8844", "#3380b3", 3113399)
    Unit <- run("saturation", "#ffffff", "#000000", 0)
    Unit <- run("saturation", "#000000", "#ffffff", 16777215)
    Unit <- run("saturation", "#808080", "#c06030", 7895160)
    Unit <- run("saturation", "#c06030", "#808080", 8421504)
    Unit <- run("saturation", "#ff00ff", "#00ff00", 65280)
    Unit <- run("saturation", "#00ffff", "#ff0000", 16711680)
    Unit <- run("saturation", "#0101fe", "#fefe01", 16711169)
    Unit <- run("color", "#cc8844", "#3380b3", 10904094)
    Unit <- run("color", "#ffffff", "#000000", 0)
    Unit <- run("color", "#000000", "#ffffff", 16777215)
    Unit <- run("color", "#808080", "#c06030", 7895160)
    Unit <- run("color", "#c06030", "#808080", 13133880)
    Unit <- run("color", "#ff00ff", "#00ff00", 16731903)
    Unit <- run("color", "#00ffff", "#ff0000", 28013)
    Unit <- run("color", "#0101fe", "#fefe01", 14671871)
    Unit <- run("luminosity", "#cc8844", "#3380b3", 5875417)
    Unit <- run("luminosity", "#ffffff", "#000000", 16777215)
    Unit <- run("luminosity", "#000000", "#ffffff", 0)
    Unit <- run("luminosity", "#808080", "#c06030", 13133880)
    Unit <- run("luminosity", "#c06030", "#808080", 7895160)
    Unit <- run("luminosity", "#ff00ff", "#00ff00", 45312)
    Unit <- run("luminosity", "#00ffff", "#ff0000", 16749202)
    run("luminosity", "#0101fe", "#fefe01", 2105344)

#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
