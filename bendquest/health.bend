# Health rules used by the world simulation. Arithmetic is natural-number
# arithmetic; the machine-word boundary is kept separate below.
import Base
import ./game.bend as G
import ./numeric.bend as N

def Health.spec_clamp(+hp: Nat, +maximum: Nat) -> Nat:
  G.Bq.nmin(hp, maximum)

def Health.spec_heal(+hp: Nat, +amount: Nat, +maximum: Nat) -> Nat:
  Health.spec_clamp(G.Bq.Nat.add(hp, amount), maximum)

def Health.spec_hurt(+hp: Nat, +damage: Nat) -> Nat:
  G.Bq.Nat.sub(hp, damage)

law Health.le_refl:
  for +n: Nat
  {G.Bq.Nat.le(n, n) == True{} : Bool}

def Health.le_refl(n):
  match n:
    case Zero{}:
      {==}
    case Succ{p}:
      Health.le_refl(p)

law Health.le_trans:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for +ab: {G.Bq.Nat.le(a, b) == True{} : Bool}
  for +bc: {G.Bq.Nat.le(b, c) == True{} : Bool}
  {G.Bq.Nat.le(a, c) == True{} : Bool}

def Health.le_trans(a, b, c, ab, bc):
  match a:
    case Zero{}:
      {==}
    case Succ{ap}:
      match b:
        case Zero{}:
          Empty.absurd({G.Bq.Nat.le(Succ{ap}, c) == True{} : Bool}, G.Bq.Bool.false_ne_true(ab))
        case Succ{bp}:
          match c:
            case Zero{}:
              Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(bc))
            case Succ{cp}:
              Health.le_trans(ap, bp, cp, ab, bc)

law Health.spec_clamp_bounded:
  for +hp: Nat
  for +maximum: Nat
  {G.Bq.Nat.le(Health.spec_clamp(hp, maximum), maximum) == True{} : Bool}

def Health.spec_clamp_bounded(hp, maximum):
  G.Bq.nmin_le_r(hp, maximum)

law Health.spec_clamp_unchanged:
  for +hp: Nat
  for +maximum: Nat
  for +valid: {G.Bq.Nat.le(hp, maximum) == True{} : Bool}
  {Health.spec_clamp(hp, maximum) == hp : Nat}

def Health.spec_clamp_unchanged(hp, maximum, valid):
  match hp:
    case Zero{}:
      {==}
    case Succ{p}:
      match maximum:
        case Zero{}:
          Empty.absurd({0n == Succ{p} : Nat}, G.Bq.Bool.false_ne_true(valid))
        case Succ{m}:
          %Health.spec_clamp_unchanged(p, m, valid) : {Succ{Health.spec_clamp(p, m)} == Succ{_} : Nat}
          {==}

law Health.spec_hurt_decreases:
  for +hp: Nat
  for +damage: Nat
  {G.Bq.Nat.le(Health.spec_hurt(hp, damage), hp) == True{} : Bool}

def Health.spec_hurt_decreases(hp, damage):
  match hp:
    case Zero{}:
      {==}
    case Succ{p}:
      match damage:
        case Zero{}:
          Health.le_refl(p)
        case Succ{d}:
          G.Bq.le_succ_r(Health.spec_hurt(p, d), p, Health.spec_hurt_decreases(p, d))

law Health.spec_hurt_preserves_bound:
  for +hp: Nat
  for +damage: Nat
  for +maximum: Nat
  for +valid: {G.Bq.Nat.le(hp, maximum) == True{} : Bool}
  {G.Bq.Nat.le(Health.spec_hurt(hp, damage), maximum) == True{} : Bool}

def Health.spec_hurt_preserves_bound(hp, damage, maximum, valid):
  Health.le_trans(Health.spec_hurt(hp, damage), hp, maximum, Health.spec_hurt_decreases(hp, damage), valid)

law Health.spec_heal_bounded:
  for +hp: Nat
  for +amount: Nat
  for +maximum: Nat
  {G.Bq.Nat.le(Health.spec_heal(hp, amount, maximum), maximum) == True{} : Bool}

def Health.spec_heal_bounded(hp, amount, maximum):
  Health.spec_clamp_bounded(G.Bq.Nat.add(hp, amount), maximum)

law Health.le_add:
  for +hp: Nat
  for +amount: Nat
  {G.Bq.Nat.le(hp, G.Bq.Nat.add(hp, amount)) == True{} : Bool}

def Health.le_add(hp, amount):
  match hp:
    case Zero{}:
      {==}
    case Succ{p}:
      Health.le_add(p, amount)

law Health.le_min:
  for +hp: Nat
  for +a: Nat
  for +b: Nat
  for +ha: {G.Bq.Nat.le(hp, a) == True{} : Bool}
  for +hb: {G.Bq.Nat.le(hp, b) == True{} : Bool}
  {G.Bq.Nat.le(hp, G.Bq.nmin(a, b)) == True{} : Bool}

def Health.le_min(hp, a, b, ha, hb):
  match hp:
    case Zero{}:
      {==}
    case Succ{p}:
      match a:
        case Zero{}:
          Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(ha))
        case Succ{ap}:
          match b:
            case Zero{}:
              Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(hb))
            case Succ{bp}:
              Health.le_min(p, ap, bp, ha, hb)

law Health.spec_heal_never_harms:
  for +hp: Nat
  for +amount: Nat
  for +maximum: Nat
  for +valid: {G.Bq.Nat.le(hp, maximum) == True{} : Bool}
  {G.Bq.Nat.le(hp, Health.spec_heal(hp, amount, maximum)) == True{} : Bool}

def Health.spec_heal_never_harms(hp, amount, maximum, valid):
  Health.le_min(hp, G.Bq.Nat.add(hp, amount), maximum, Health.le_add(hp, amount), valid)

law Health.spec_hurt_survives:
  for +hp: Nat
  for +damage: Nat
  for +below: {G.Bq.Nat.lt(damage, hp) == True{} : Bool}
  {G.Bq.Nat.le(1n, Health.spec_hurt(hp, damage)) == True{} : Bool}

def Health.spec_hurt_survives(hp, damage, below):
  match hp:
    case Zero{}:
      Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(below))
    case Succ{p}:
      match damage:
        case Zero{}:
          {==}
        case Succ{d}:
          Health.spec_hurt_survives(p, d, below)

# These implementations use Base arithmetic, which the native compiler
# implements with big integers. The refinement proofs below tie the fast
# implementations to the inductive specification above.
def Health.pick(+order: Cmp, +a: Nat, +b: Nat) -> Nat:
  match order:
    case LT{}:
      a
    case EQ{}:
      a
    case GT{}:
      b

def Health.clamp(+hp: Nat, +maximum: Nat) -> Nat:
  Health.pick(Nat.cmp(hp, maximum), hp, maximum)

def Health.heal(+hp: Nat, +amount: Nat, +maximum: Nat) -> Nat:
  Health.clamp(Nat.add(hp, amount), maximum)

def Health.hurt(hp: Nat, damage: Nat) -> Nat:
  Nat.sub(hp, damage)

law Health.pick_succ:
  for +order: Cmp
  for +a: Nat
  for +b: Nat
  {Health.pick(order, Succ{a}, Succ{b}) == Succ{Health.pick(order, a, b)} : Nat}

def Health.pick_succ(order, a, b):
  match order:
    case LT{}:
      {==}
    case EQ{}:
      {==}
    case GT{}:
      {==}

law Health.clamp_agrees:
  for +hp: Nat
  for +maximum: Nat
  {Health.clamp(hp, maximum) == Health.spec_clamp(hp, maximum) : Nat}

def Health.clamp_agrees(hp, maximum):
  match hp:
    case Zero{}:
      match maximum:
        case Zero{}:
          {==}
        case Succ{m}:
          {==}
    case Succ{p}:
      match maximum:
        case Zero{}:
          {==}
        case Succ{m}:
          %Health.clamp_agrees(p, m) : {Health.clamp(Succ{p}, Succ{m}) == Succ{_} : Nat}
          Health.pick_succ(Nat.cmp(p, m), p, m)

law Health.add_agrees:
  for +a: Nat
  for +b: Nat
  {Nat.add(a, b) == G.Bq.Nat.add(a, b) : Nat}

def Health.add_agrees(a, b):
  match a:
    case Zero{}:
      {==}
    case Succ{p}:
      %Health.add_agrees(p, b) : {Succ{Nat.add(p, b)} == Succ{_} : Nat}
      {==}

law Health.hurt_agrees:
  for +hp: Nat
  for +damage: Nat
  {Health.hurt(hp, damage) == Health.spec_hurt(hp, damage) : Nat}

def Health.hurt_agrees(hp, damage):
  match hp:
    case Zero{}:
      match damage:
        case Zero{}:
          {==}
        case Succ{d}:
          {==}
    case Succ{p}:
      match damage:
        case Zero{}:
          {==}
        case Succ{d}:
          Health.hurt_agrees(p, d)

law Health.heal_agrees:
  for +hp: Nat
  for +amount: Nat
  for +maximum: Nat
  {Health.heal(hp, amount, maximum) == Health.spec_heal(hp, amount, maximum) : Nat}

def Health.heal_agrees(hp, amount, maximum):
  %Health.add_agrees(hp, amount) : {Health.heal(hp, amount, maximum) == Health.spec_clamp(_, maximum) : Nat}
  Health.clamp_agrees(Nat.add(hp, amount), maximum)

law Health.heal_bounded:
  for +hp: Nat
  for +amount: Nat
  for +maximum: Nat
  {G.Bq.Nat.le(Health.heal(hp, amount, maximum), maximum) == True{} : Bool}

def Health.heal_bounded(hp, amount, maximum):
  %Equal.sym(Nat, Health.heal(hp, amount, maximum), Health.spec_heal(hp, amount, maximum), Health.heal_agrees(hp, amount, maximum)) : {G.Bq.Nat.le(_, maximum) == True{} : Bool}
  Health.spec_heal_bounded(hp, amount, maximum)

law Health.heal_never_harms:
  for +hp: Nat
  for +amount: Nat
  for +maximum: Nat
  for +valid: {G.Bq.Nat.le(hp, maximum) == True{} : Bool}
  {G.Bq.Nat.le(hp, Health.heal(hp, amount, maximum)) == True{} : Bool}

def Health.heal_never_harms(hp, amount, maximum, valid):
  %Equal.sym(Nat, Health.heal(hp, amount, maximum), Health.spec_heal(hp, amount, maximum), Health.heal_agrees(hp, amount, maximum)) : {G.Bq.Nat.le(hp, _) == True{} : Bool}
  Health.spec_heal_never_harms(hp, amount, maximum, valid)

law Health.hurt_preserves_bound:
  for +hp: Nat
  for +damage: Nat
  for +maximum: Nat
  for +valid: {G.Bq.Nat.le(hp, maximum) == True{} : Bool}
  {G.Bq.Nat.le(Health.hurt(hp, damage), maximum) == True{} : Bool}

def Health.hurt_preserves_bound(hp, damage, maximum, valid):
  %Equal.sym(Nat, Health.hurt(hp, damage), Health.spec_hurt(hp, damage), Health.hurt_agrees(hp, damage)) : {G.Bq.Nat.le(_, maximum) == True{} : Bool}
  Health.spec_hurt_preserves_bound(hp, damage, maximum, valid)

law Health.hurt_survives:
  for +hp: Nat
  for +damage: Nat
  for +below: {G.Bq.Nat.lt(damage, hp) == True{} : Bool}
  {G.Bq.Nat.le(1n, Health.hurt(hp, damage)) == True{} : Bool}

def Health.hurt_survives(hp, damage, below):
  %Equal.sym(Nat, Health.hurt(hp, damage), Health.spec_hurt(hp, damage), Health.hurt_agrees(hp, damage)) : {G.Bq.Nat.le(1n, _) == True{} : Bool}
  Health.spec_hurt_survives(hp, damage, below)

# Existing U32 records enter the rules here. The refinement and preservation
# theorems below prove these exact word wrappers cannot wrap their results.
def Health.clamp_word(hp: U32, maximum: U32) -> U32:
  U32.from_nat(Health.clamp(U32.to_nat(hp), U32.to_nat(maximum)))

def Health.heal_word(hp: U32, amount: U32, maximum: U32) -> U32:
  U32.from_nat(Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)))

def Health.hurt_word(hp: U32, damage: U32) -> U32:
  U32.from_nat(Health.hurt(U32.to_nat(hp), U32.to_nat(damage)))

law Health.clamp_bounded:
  for +hp: Nat
  for +maximum: Nat
  {G.Bq.Nat.le(Health.clamp(hp, maximum), maximum) == True{} : Bool}

def Health.clamp_bounded(hp, maximum):
  %Equal.sym(Nat, Health.clamp(hp, maximum), Health.spec_clamp(hp, maximum), Health.clamp_agrees(hp, maximum)) : {G.Bq.Nat.le(_, maximum) == True{} : Bool}
  Health.spec_clamp_bounded(hp, maximum)

law Health.hurt_decreases:
  for +hp: Nat
  for +damage: Nat
  {G.Bq.Nat.le(Health.hurt(hp, damage), hp) == True{} : Bool}

def Health.hurt_decreases(hp, damage):
  %Equal.sym(Nat, Health.hurt(hp, damage), Health.spec_hurt(hp, damage), Health.hurt_agrees(hp, damage)) : {G.Bq.Nat.le(_, hp) == True{} : Bool}
  Health.spec_hurt_decreases(hp, damage)

law Health.clamp_word_exact:
  for +hp: U32
  for +maximum: U32
  {U32.to_nat(Health.clamp_word(hp, maximum)) == Health.clamp(U32.to_nat(hp), U32.to_nat(maximum)) : Nat}

def Health.clamp_word_exact(hp, maximum):
  N.Numeric.u32_nat_roundtrip(Health.clamp(U32.to_nat(hp), U32.to_nat(maximum)), N.Numeric.fits_downward(32n, Health.clamp(U32.to_nat(hp), U32.to_nat(maximum)), U32.to_nat(maximum), N.Numeric.u32_value_fits(maximum), Health.clamp_bounded(U32.to_nat(hp), U32.to_nat(maximum))))

law Health.heal_word_exact:
  for +hp: U32
  for +amount: U32
  for +maximum: U32
  {U32.to_nat(Health.heal_word(hp, amount, maximum)) == Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)) : Nat}

def Health.heal_word_exact(hp, amount, maximum):
  N.Numeric.u32_nat_roundtrip(Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), N.Numeric.fits_downward(32n, Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), U32.to_nat(maximum), N.Numeric.u32_value_fits(maximum), Health.heal_bounded(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum))))

law Health.hurt_word_exact:
  for +hp: U32
  for +damage: U32
  {U32.to_nat(Health.hurt_word(hp, damage)) == Health.hurt(U32.to_nat(hp), U32.to_nat(damage)) : Nat}

def Health.hurt_word_exact(hp, damage):
  N.Numeric.u32_nat_roundtrip(Health.hurt(U32.to_nat(hp), U32.to_nat(damage)), N.Numeric.fits_downward(32n, Health.hurt(U32.to_nat(hp), U32.to_nat(damage)), U32.to_nat(hp), N.Numeric.u32_value_fits(hp), Health.hurt_decreases(U32.to_nat(hp), U32.to_nat(damage))))

law Health.clamp_word_bounded:
  for +hp: U32
  for +maximum: U32
  {G.Bq.Nat.le(U32.to_nat(Health.clamp_word(hp, maximum)), U32.to_nat(maximum)) == True{} : Bool}

def Health.clamp_word_bounded(hp, maximum):
  %Equal.sym(Nat, U32.to_nat(Health.clamp_word(hp, maximum)), Health.clamp(U32.to_nat(hp), U32.to_nat(maximum)), Health.clamp_word_exact(hp, maximum)) : {G.Bq.Nat.le(_, U32.to_nat(maximum)) == True{} : Bool}
  Health.clamp_bounded(U32.to_nat(hp), U32.to_nat(maximum))

law Health.heal_word_bounded:
  for +hp: U32
  for +amount: U32
  for +maximum: U32
  {G.Bq.Nat.le(U32.to_nat(Health.heal_word(hp, amount, maximum)), U32.to_nat(maximum)) == True{} : Bool}

def Health.heal_word_bounded(hp, amount, maximum):
  %Equal.sym(Nat, U32.to_nat(Health.heal_word(hp, amount, maximum)), Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), Health.heal_word_exact(hp, amount, maximum)) : {G.Bq.Nat.le(_, U32.to_nat(maximum)) == True{} : Bool}
  Health.heal_bounded(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum))

law Health.heal_word_never_harms:
  for +hp: U32
  for +amount: U32
  for +maximum: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(maximum)) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Health.heal_word(hp, amount, maximum))) == True{} : Bool}

def Health.heal_word_never_harms(hp, amount, maximum, valid):
  %Equal.sym(Nat, U32.to_nat(Health.heal_word(hp, amount, maximum)), Health.heal(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum)), Health.heal_word_exact(hp, amount, maximum)) : {G.Bq.Nat.le(U32.to_nat(hp), _) == True{} : Bool}
  Health.heal_never_harms(U32.to_nat(hp), U32.to_nat(amount), U32.to_nat(maximum), valid)

law Health.hurt_word_preserves_bound:
  for +hp: U32
  for +damage: U32
  for +maximum: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(maximum)) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(Health.hurt_word(hp, damage)), U32.to_nat(maximum)) == True{} : Bool}

def Health.hurt_word_preserves_bound(hp, damage, maximum, valid):
  %Equal.sym(Nat, U32.to_nat(Health.hurt_word(hp, damage)), Health.hurt(U32.to_nat(hp), U32.to_nat(damage)), Health.hurt_word_exact(hp, damage)) : {G.Bq.Nat.le(_, U32.to_nat(maximum)) == True{} : Bool}
  Health.hurt_preserves_bound(U32.to_nat(hp), U32.to_nat(damage), U32.to_nat(maximum), valid)

law Health.hurt_word_survives:
  for +hp: U32
  for +damage: U32
  for +below: {G.Bq.Nat.lt(U32.to_nat(damage), U32.to_nat(hp)) == True{} : Bool}
  {G.Bq.Nat.le(1n, U32.to_nat(Health.hurt_word(hp, damage))) == True{} : Bool}

def Health.hurt_word_survives(hp, damage, below):
  %Equal.sym(Nat, U32.to_nat(Health.hurt_word(hp, damage)), Health.hurt(U32.to_nat(hp), U32.to_nat(damage)), Health.hurt_word_exact(hp, damage)) : {G.Bq.Nat.le(1n, _) == True{} : Bool}
  Health.hurt_survives(U32.to_nat(hp), U32.to_nat(damage), below)

# Natural stat-derived maxima must be clamped before conversion, too.
def Health.cap_nat_word(value: Nat, maximum: U32) -> U32:
  U32.from_nat(Health.clamp(value, U32.to_nat(maximum)))

law Health.cap_nat_word_exact:
  for +value: Nat
  for +maximum: U32
  {U32.to_nat(Health.cap_nat_word(value, maximum)) == Health.clamp(value, U32.to_nat(maximum)) : Nat}

def Health.cap_nat_word_exact(value, maximum):
  N.Numeric.u32_nat_roundtrip(Health.clamp(value, U32.to_nat(maximum)), N.Numeric.fits_downward(32n, Health.clamp(value, U32.to_nat(maximum)), U32.to_nat(maximum), N.Numeric.u32_value_fits(maximum), Health.clamp_bounded(value, U32.to_nat(maximum))))

law Health.spec_clamp_decreases:
  for +a: Nat
  for +b: Nat
  {G.Bq.Nat.le(Health.spec_clamp(a, b), a) == True{} : Bool}

def Health.spec_clamp_decreases(a, b):
  match a:
    case Zero{}:
      {==}
    case Succ{p}:
      match b:
        case Zero{}:
          {==}
        case Succ{q}:
          Health.spec_clamp_decreases(p, q)

law Health.clamp_decreases:
  for +a: Nat
  for +b: Nat
  {G.Bq.Nat.le(Health.clamp(a, b), a) == True{} : Bool}

def Health.clamp_decreases(a, b):
  %Equal.sym(Nat, Health.clamp(a, b), Health.spec_clamp(a, b), Health.clamp_agrees(a, b)) : {G.Bq.Nat.le(_, a) == True{} : Bool}
  Health.spec_clamp_decreases(a, b)

law Health.clamp_monotone:
  for +a: Nat
  for +b: Nat
  for +maximum: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(Health.clamp(a, maximum), Health.clamp(b, maximum)) == True{} : Bool}

def Health.clamp_monotone(a, b, maximum, grow):
  %Equal.sym(Nat, Health.clamp(b, maximum), Health.spec_clamp(b, maximum), Health.clamp_agrees(b, maximum)) : {G.Bq.Nat.le(Health.clamp(a, maximum), _) == True{} : Bool}
  Health.le_min(Health.clamp(a, maximum), b, maximum, Health.le_trans(Health.clamp(a, maximum), a, b, Health.clamp_decreases(a, maximum), grow), Health.clamp_bounded(a, maximum))

law Health.cap_nat_word_monotone:
  for +a: Nat
  for +b: Nat
  for +maximum: U32
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(Health.cap_nat_word(a, maximum)), U32.to_nat(Health.cap_nat_word(b, maximum))) == True{} : Bool}

def Health.cap_nat_word_monotone(a, b, maximum, grow):
  %Equal.sym(Nat, U32.to_nat(Health.cap_nat_word(a, maximum)), Health.clamp(a, U32.to_nat(maximum)), Health.cap_nat_word_exact(a, maximum)) : {G.Bq.Nat.le(_, U32.to_nat(Health.cap_nat_word(b, maximum))) == True{} : Bool}
  %Equal.sym(Nat, U32.to_nat(Health.cap_nat_word(b, maximum)), Health.clamp(b, U32.to_nat(maximum)), Health.cap_nat_word_exact(b, maximum)) : {G.Bq.Nat.le(Health.clamp(a, U32.to_nat(maximum)), _) == True{} : Bool}
  Health.clamp_monotone(a, b, U32.to_nat(maximum), grow)

law Health.add_mono_left:
  for +amount: Nat
  for +a: Nat
  for +b: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(Nat.add(amount, a), Nat.add(amount, b)) == True{} : Bool}

def Health.add_mono_left(amount, a, b, grow):
  match amount:
    case Zero{}:
      grow
    case Succ{p}:
      Health.add_mono_left(p, a, b, grow)

# Add the charm bonus before conversion. The server supplies U32 maximum
# as the ceiling; keeping it explicit makes the theorem apply to any ceiling.
def Health.maximum_word(+raw: Nat, bonus: U32, ceiling: U32) -> U32:
  Health.cap_nat_word(Nat.add(U32.to_nat(bonus), raw), ceiling)

law Health.maximum_word_monotone:
  for +a: Nat
  for +b: Nat
  for +bonus: U32
  for +ceiling: U32
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(Health.maximum_word(a, bonus, ceiling)), U32.to_nat(Health.maximum_word(b, bonus, ceiling))) == True{} : Bool}

def Health.maximum_word_monotone(a, b, bonus, ceiling, grow):
  Health.cap_nat_word_monotone(Nat.add(U32.to_nat(bonus), a), Nat.add(U32.to_nat(bonus), b), ceiling, Health.add_mono_left(U32.to_nat(bonus), a, b, grow))

law Health.cap_nat_word_positive:
  for +value: Nat
  for +maximum: U32
  for +positive: {G.Bq.Nat.le(1n, value) == True{} : Bool}
  for +limit_positive: {G.Bq.Nat.le(1n, U32.to_nat(maximum)) == True{} : Bool}
  {G.Bq.Nat.le(1n, U32.to_nat(Health.cap_nat_word(value, maximum))) == True{} : Bool}

def Health.cap_nat_word_positive(value, maximum, positive, limit_positive):
  %Equal.sym(Nat, U32.to_nat(Health.cap_nat_word(value, maximum)), Health.clamp(value, U32.to_nat(maximum)), Health.cap_nat_word_exact(value, maximum)) : {G.Bq.Nat.le(1n, _) == True{} : Bool}
  %Equal.sym(Nat, Health.clamp(value, U32.to_nat(maximum)), Health.spec_clamp(value, U32.to_nat(maximum)), Health.clamp_agrees(value, U32.to_nat(maximum))) : {G.Bq.Nat.le(1n, _) == True{} : Bool}
  Health.le_min(1n, value, U32.to_nat(maximum), positive, limit_positive)

law Health.spec_hurt_zero:
  for +hp: Nat
  for +damage: Nat
  for +lethal: {G.Bq.Nat.le(hp, damage) == True{} : Bool}
  {Health.spec_hurt(hp, damage) == 0n : Nat}

def Health.spec_hurt_zero(hp, damage, lethal):
  match hp:
    case Zero{}:
      {==}
    case Succ{rest}:
      match damage:
        case Zero{}:
          Empty.absurd({Succ{rest} == 0n : Nat}, G.Bq.Bool.false_ne_true(lethal))
        case Succ{less}:
          Health.spec_hurt_zero(rest, less, lethal)

law Health.hurt_word_zero:
  for +hp: U32
  for +damage: U32
  for +lethal: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(damage)) == True{} : Bool}
  {U32.to_nat(Health.hurt_word(hp, damage)) == 0n : Nat}

def Health.hurt_word_zero(hp, damage, lethal):
  %Equal.sym(Nat, U32.to_nat(Health.hurt_word(hp, damage)), Health.hurt(U32.to_nat(hp), U32.to_nat(damage)), Health.hurt_word_exact(hp, damage)) : {_ == 0n : Nat}
  %Equal.sym(Nat, Health.hurt(U32.to_nat(hp), U32.to_nat(damage)), Health.spec_hurt(U32.to_nat(hp), U32.to_nat(damage)), Health.hurt_agrees(U32.to_nat(hp), U32.to_nat(damage))) : {_ == 0n : Nat}
  Health.spec_hurt_zero(U32.to_nat(hp), U32.to_nat(damage), lethal)
