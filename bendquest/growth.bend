# Maximum-health growth, including the exact saturated word representation.
import Base
import ./game.bend as G
import ./health.bend as H

def Growth.maximum(+level: Nat, +vitality: Nat, bonus: U32, ceiling: U32) -> U32:
  H.Health.maximum_word(G.Bq.max_hp(level, vitality), bonus, ceiling)

law Growth.le_add_prefix:
  for +prefix: Nat
  for +value: Nat
  {G.Bq.Nat.le(value, G.Bq.Nat.add(prefix, value)) == True{} : Bool}

def Growth.le_add_prefix(prefix, value):
  match prefix:
    case Zero{}:
      H.Health.le_refl(value)
    case Succ{p}:
      G.Bq.le_succ_r(value, G.Bq.Nat.add(p, value), Growth.le_add_prefix(p, value))

law Growth.add_left:
  for +a: Nat
  for +b: Nat
  for +extra: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.add(a, extra), G.Bq.Nat.add(b, extra)) == True{} : Bool}

def Growth.add_left(a, b, extra, grow):
  match a:
    case Zero{}:
      Growth.le_add_prefix(b, extra)
    case Succ{p}:
      match b:
        case Zero{}:
          Empty.absurd({G.Bq.Nat.le(Succ{G.Bq.Nat.add(p, extra)}, extra) == True{} : Bool}, G.Bq.Bool.false_ne_true(grow))
        case Succ{q}:
          Growth.add_left(p, q, extra, grow)

law Growth.add_right:
  for +prefix: Nat
  for +a: Nat
  for +b: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.add(prefix, a), G.Bq.Nat.add(prefix, b)) == True{} : Bool}

def Growth.add_right(prefix, a, b, grow):
  match prefix:
    case Zero{}:
      grow
    case Succ{p}:
      Growth.add_right(p, a, b, grow)

law Growth.add_both:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for +d: Nat
  for +ab: {G.Bq.Nat.le(a, b) == True{} : Bool}
  for +cd: {G.Bq.Nat.le(c, d) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.add(a, c), G.Bq.Nat.add(b, d)) == True{} : Bool}

def Growth.add_both(a, b, c, d, ab, cd):
  H.Health.le_trans(G.Bq.Nat.add(a, c), G.Bq.Nat.add(b, c), G.Bq.Nat.add(b, d), Growth.add_left(a, b, c, ab), Growth.add_right(b, c, d, cd))

law Growth.mul:
  for +scale: Nat
  for +a: Nat
  for +b: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.mul(scale, a), G.Bq.Nat.mul(scale, b)) == True{} : Bool}

def Growth.mul(scale, a, b, grow):
  match scale:
    case Zero{}:
      {==}
    case Succ{p}:
      Growth.add_both(a, b, G.Bq.Nat.mul(p, a), G.Bq.Nat.mul(p, b), grow, Growth.mul(p, a, b, grow))

law Growth.double:
  for +a: Nat
  for +b: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.dbl(a), G.Bq.Nat.dbl(b)) == True{} : Bool}

def Growth.double(a, b, grow):
  match a:
    case Zero{}:
      {==}
    case Succ{p}:
      match b:
        case Zero{}:
          Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(grow))
        case Succ{q}:
          Growth.double(p, q, grow)

law Growth.pred:
  for +a: Nat
  for +b: Nat
  for +grow: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.pred(a), G.Bq.Nat.pred(b)) == True{} : Bool}

def Growth.pred(a, b, grow):
  match a:
    case Zero{}:
      {==}
    case Succ{p}:
      match b:
        case Zero{}:
          Empty.absurd({G.Bq.Nat.le(p, 0n) == True{} : Bool}, G.Bq.Bool.false_ne_true(grow))
        case Succ{q}:
          grow

law Growth.raw_maximum:
  for +level0: Nat
  for +level1: Nat
  for +vit0: Nat
  for +vit1: Nat
  for +levels: {G.Bq.Nat.le(level0, level1) == True{} : Bool}
  for +vitalities: {G.Bq.Nat.le(vit0, vit1) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.max_hp(level0, vit0), G.Bq.max_hp(level1, vit1)) == True{} : Bool}

def Growth.raw_maximum(level0, level1, vit0, vit1, levels, vitalities):
  Growth.add_right(20n, G.Bq.Nat.add(G.Bq.Nat.mul(5n, vit0), G.Bq.Nat.dbl(G.Bq.Nat.pred(level0))), G.Bq.Nat.add(G.Bq.Nat.mul(5n, vit1), G.Bq.Nat.dbl(G.Bq.Nat.pred(level1))), Growth.add_both(G.Bq.Nat.mul(5n, vit0), G.Bq.Nat.mul(5n, vit1), G.Bq.Nat.dbl(G.Bq.Nat.pred(level0)), G.Bq.Nat.dbl(G.Bq.Nat.pred(level1)), Growth.mul(5n, vit0, vit1, vitalities), Growth.double(G.Bq.Nat.pred(level0), G.Bq.Nat.pred(level1), Growth.pred(level0, level1, levels))))

law Growth.maximum_monotone:
  for +level0: Nat
  for +level1: Nat
  for +vit0: Nat
  for +vit1: Nat
  for +bonus: U32
  for +ceiling: U32
  for +levels: {G.Bq.Nat.le(level0, level1) == True{} : Bool}
  for +vitalities: {G.Bq.Nat.le(vit0, vit1) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(Growth.maximum(level0, vit0, bonus, ceiling)), U32.to_nat(Growth.maximum(level1, vit1, bonus, ceiling))) == True{} : Bool}

def Growth.maximum_monotone(level0, level1, vit0, vit1, bonus, ceiling, levels, vitalities):
  H.Health.maximum_word_monotone(G.Bq.max_hp(level0, vit0), G.Bq.max_hp(level1, vit1), bonus, ceiling, Growth.raw_maximum(level0, level1, vit0, vit1, levels, vitalities))

law Growth.health_preserved:
  for +hp: U32
  for +level0: Nat
  for +level1: Nat
  for +vit0: Nat
  for +vit1: Nat
  for +bonus: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Growth.maximum(level0, vit0, bonus, ceiling))) == True{} : Bool}
  for +levels: {G.Bq.Nat.le(level0, level1) == True{} : Bool}
  for +vitalities: {G.Bq.Nat.le(vit0, vit1) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Growth.maximum(level1, vit1, bonus, ceiling))) == True{} : Bool}

def Growth.health_preserved(hp, level0, level1, vit0, vit1, bonus, ceiling, valid, levels, vitalities):
  H.Health.le_trans(U32.to_nat(hp), U32.to_nat(Growth.maximum(level0, vit0, bonus, ceiling)), U32.to_nat(Growth.maximum(level1, vit1, bonus, ceiling)), valid, Growth.maximum_monotone(level0, level1, vit0, vit1, bonus, ceiling, levels, vitalities))

law Growth.level_up_preserves_health:
  for +hp: U32
  for +level: Nat
  for +vitality: Nat
  for +bonus: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Growth.maximum(level, vitality, bonus, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Growth.maximum(Succ{level}, vitality, bonus, ceiling))) == True{} : Bool}

def Growth.level_up_preserves_health(hp, level, vitality, bonus, ceiling, valid):
  Growth.health_preserved(hp, level, Succ{level}, vitality, vitality, bonus, ceiling, valid, G.Bq.le_succ_r(level, level, H.Health.le_refl(level)), H.Health.le_refl(vitality))

law Growth.vitality_up_preserves_health:
  for +hp: U32
  for +level: Nat
  for +vitality: Nat
  for +bonus: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Growth.maximum(level, vitality, bonus, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Growth.maximum(level, Succ{vitality}, bonus, ceiling))) == True{} : Bool}

def Growth.vitality_up_preserves_health(hp, level, vitality, bonus, ceiling, valid):
  Growth.health_preserved(hp, level, level, vitality, Succ{vitality}, bonus, ceiling, valid, H.Health.le_refl(level), G.Bq.le_succ_r(vitality, vitality, H.Health.le_refl(vitality)))
