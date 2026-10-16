import Base
import ../health.bend as H
import ../growth.bend as Growth

def check_result(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def check(name: String, got: U32, expected: U32) -> IO(Unit):
  check_result(name, U32.is_eq(got, expected))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check("healing near U32 maximum", H.Health.heal_word(4294967294, 30, 4294967295), 4294967295)
    Unit <- check("healing with maximum amount", H.Health.heal_word(35, 4294967295, 100), 100)
    Unit <- check("ordinary capped healing", H.Health.heal_word(30, 20, 35), 35)
    Unit <- check("damage saturates at zero", H.Health.hurt_word(10, 100), 0)
    Unit <- check("nonlethal damage", H.Health.hurt_word(35, 34), 1)
    Unit <- check("clamping invalid health", H.Health.clamp_word(4294967295, 35), 35)
    Unit <- check("maximum above U32 range", H.Health.maximum_word(Nat.add(U32.to_nat(4294967295), 1n), 0, 4294967295), 4294967295)
    Unit <- check("maximum plus charm saturates", H.Health.maximum_word(U32.to_nat(4294967294), 30, 4294967295), 4294967295)
    Unit <- check("ordinary charm maximum", Growth.Growth.maximum(1n, 3n, 30, 4294967295), 65)
    Unit <- check("level-up maximum", Growth.Growth.maximum(2n, 3n, 30, 4294967295), 67)
    Unit <- check("vitality-up maximum", Growth.Growth.maximum(1n, 4n, 30, 4294967295), 70)
    return Unit{}

#| PASS healing near U32 maximum
#| PASS healing with maximum amount
#| PASS ordinary capped healing
#| PASS damage saturates at zero
#| PASS nonlethal damage
#| PASS clamping invalid health

#| PASS maximum above U32 range
#| PASS maximum plus charm saturates
#| PASS ordinary charm maximum
#| PASS level-up maximum
#| PASS vitality-up maximum
