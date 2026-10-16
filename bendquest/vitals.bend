# Player vital state and its authoritative death/respawn transitions.
import Base
import ./game.bend as G
import ./health.bend as H
import ./rewards.bend as R

type Vitals.State is Data:
  Vitals.State{hp: U32, xp: U32, dead: U32, respawn: U32, attack: U32, spin: U32}

def Vitals.hp(state: Vitals.State) -> U32:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      hp

def Vitals.dead(state: Vitals.State) -> U32:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      dead

type Vitals.Life<-hp: U32, -dead: U32> is Data:
  Vitals.Alive{flag: {dead == 0 : U32}, positive: {G.Bq.Nat.le(1n, U32.to_nat(hp)) == True{} : Bool}}
  Vitals.Dead{flag: {dead == 1 : U32}, zero: {hp == 0 : U32}}

type Vitals.OK<-state: Vitals.State, -maximum: U32> is Data:
  Vitals.OK{bound: {G.Bq.Nat.le(U32.to_nat(Vitals.hp(state)), U32.to_nat(maximum)) == True{} : Bool}, life: Vitals.Life<Vitals.hp(state), Vitals.dead(state)>}

def Vitals.fall(state: Vitals.State, timer: U32) -> Vitals.State:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.State{0, xp, 1, timer, attack, spin}

def Vitals.revive(state: Vitals.State, maximum: U32) -> Vitals.State:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.State{maximum, xp, 0, 0, 0, 0}

law Vitals.fall_ok:
  for +state: Vitals.State
  for +timer: U32
  for +maximum: U32
  Vitals.OK<Vitals.fall(state, timer), maximum>

def Vitals.fall_ok(state, timer, maximum):
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.OK{{==}, Vitals.Dead{{==}, {==}}}

law Vitals.revive_ok:
  for +state: Vitals.State
  for +maximum: U32
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(maximum)) == True{} : Bool}
  Vitals.OK<Vitals.revive(state, maximum), maximum>

def Vitals.revive_ok(state, maximum, positive):
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.OK{H.Health.le_refl(U32.to_nat(maximum)), Vitals.Alive{{==}, positive}}

type Vitals.Hit is Data:
  Vitals.Hit{state: Vitals.State, fell: Bool}

def Vitals.hit_state(hit: Vitals.Hit) -> Vitals.State:
  match hit:
    case Vitals.Hit{state, fell}:
      state

def Vitals.finish_hit(remaining: Nat, word: U32, state: Vitals.State, timer: U32) -> Vitals.Hit:
  match remaining:
    case Zero{}:
      Vitals.Hit{Vitals.fall(state, timer), True{}}
    case Succ{positive}:
      match state:
        case Vitals.State{hp, xp, dead, respawn, attack, spin}:
          Vitals.Hit{Vitals.State{word, xp, 0, respawn, attack, spin}, False{}}

def Vitals.hit_gate(is_dead: Bool, +state: Vitals.State, damage: U32, timer: U32) -> Vitals.Hit:
  match is_dead:
    case True{}:
      Vitals.Hit{state, False{}}
    case False{}:
      +remaining = H.Health.hurt_word(Vitals.hp(state), damage)
      Vitals.finish_hit(U32.to_nat(remaining), remaining, state, timer)

def Vitals.hit(+state: Vitals.State, damage: U32, timer: U32) -> Vitals.Hit:
  Vitals.hit_gate(U32.is_eq(Vitals.dead(state), 1), state, damage, timer)

law Vitals.finish_hit_ok:
  for +remaining: Nat
  for +word: U32
  for +state: Vitals.State
  for +timer: U32
  for +maximum: U32
  for +exact: {U32.to_nat(word) == remaining : Nat}
  for +bound: {G.Bq.Nat.le(U32.to_nat(word), U32.to_nat(maximum)) == True{} : Bool}
  Vitals.OK<Vitals.hit_state(Vitals.finish_hit(remaining, word, state, timer)), maximum>

def Vitals.finish_hit_ok(remaining, word, state, timer, maximum, exact, bound):
  match remaining:
    case Zero{}:
      Vitals.fall_ok(state, timer, maximum)
    case Succ{positive}:
      match state:
        case Vitals.State{hp, xp, dead, respawn, attack, spin}:
          Vitals.OK{bound, Vitals.Alive{{==}, (%Equal.sym(Nat, U32.to_nat(word), Succ{positive}, exact) : {G.Bq.Nat.le(1n, _) == True{} : Bool}; {==})}}

law Vitals.hit_gate_ok:
  for +is_dead: Bool
  for +state: Vitals.State
  for +damage: U32
  for +timer: U32
  for +maximum: U32
  for +valid: Vitals.OK<state, maximum>
  Vitals.OK<Vitals.hit_state(Vitals.hit_gate(is_dead, state, damage, timer)), maximum>

def Vitals.hit_gate_ok(is_dead, state, damage, timer, maximum, valid):
  match is_dead:
    case True{}:
      valid
    case False{}:
      match valid:
        case Vitals.OK{bound, life}:
          Vitals.finish_hit_ok(U32.to_nat(H.Health.hurt_word(Vitals.hp(state), damage)), H.Health.hurt_word(Vitals.hp(state), damage), state, timer, maximum, {==}, H.Health.hurt_word_preserves_bound(Vitals.hp(state), damage, maximum, bound))

law Vitals.hit_ok:
  for +state: Vitals.State
  for +damage: U32
  for +timer: U32
  for +maximum: U32
  for +valid: Vitals.OK<state, maximum>
  Vitals.OK<Vitals.hit_state(Vitals.hit(state, damage, timer)), maximum>

def Vitals.hit_ok(state, damage, timer, maximum, valid):
  Vitals.hit_gate_ok(U32.is_eq(Vitals.dead(state), 1), state, damage, timer, maximum, valid)

def Vitals.dec(word: U32) -> U32:
  H.Health.hurt_word(word, 1)

def Vitals.wait(state: Vitals.State) -> Vitals.State:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.State{hp, xp, dead, Vitals.dec(respawn), attack, spin}

def Vitals.live_tick(state: Vitals.State, amount: U32, maximum: U32) -> Vitals.State:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.State{H.Health.heal_word(hp, amount, maximum), xp, 0, 0, Vitals.dec(attack), Vitals.dec(spin)}

type Vitals.Upkeep is Data:
  Vitals.Upkeep{state: Vitals.State, revived: Bool, walk: Bool}

def Vitals.upkeep_state(upkeep: Vitals.Upkeep) -> Vitals.State:
  match upkeep:
    case Vitals.Upkeep{state, revived, walk}:
      state

def Vitals.dead_tick(ready: Bool, state: Vitals.State, maximum: U32) -> Vitals.Upkeep:
  match ready:
    case True{}:
      Vitals.Upkeep{Vitals.revive(state, maximum), True{}, False{}}
    case False{}:
      Vitals.Upkeep{Vitals.wait(state), False{}, False{}}

def Vitals.upkeep_gate(is_dead: Bool, ready: Bool, state: Vitals.State, amount: U32, maximum: U32) -> Vitals.Upkeep:
  match is_dead:
    case True{}:
      Vitals.dead_tick(ready, state, maximum)
    case False{}:
      Vitals.Upkeep{Vitals.live_tick(state, amount, maximum), False{}, True{}}

def Vitals.upkeep(+state: Vitals.State, amount: U32, maximum: U32) -> Vitals.Upkeep:
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.upkeep_gate(U32.is_eq(dead, 1), U32.is_le(respawn, 1), Vitals.State{hp, xp, dead, respawn, attack, spin}, amount, maximum)

law Vitals.wait_ok:
  for +state: Vitals.State
  for +maximum: U32
  for +valid: Vitals.OK<state, maximum>
  Vitals.OK<Vitals.wait(state), maximum>

def Vitals.wait_ok(state, maximum, valid):
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      match valid:
        case Vitals.OK{bound, life}:
          Vitals.OK{bound, life}

law Vitals.live_tick_ok:
  for +state: Vitals.State
  for +amount: U32
  for +maximum: U32
  for +bound: {G.Bq.Nat.le(U32.to_nat(Vitals.hp(state)), U32.to_nat(maximum)) == True{} : Bool}
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(Vitals.hp(state))) == True{} : Bool}
  Vitals.OK<Vitals.live_tick(state, amount, maximum), maximum>

def Vitals.live_tick_ok(state, amount, maximum, bound, positive):
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      Vitals.OK{H.Health.heal_word_bounded(hp, amount, maximum), Vitals.Alive{{==}, H.Health.le_trans(1n, U32.to_nat(hp), U32.to_nat(H.Health.heal_word(hp, amount, maximum)), positive, H.Health.heal_word_never_harms(hp, amount, maximum, bound))}}

law Vitals.dead_tick_ok:
  for +ready: Bool
  for +state: Vitals.State
  for +maximum: U32
  for +valid: Vitals.OK<state, maximum>
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(maximum)) == True{} : Bool}
  Vitals.OK<Vitals.upkeep_state(Vitals.dead_tick(ready, state, maximum)), maximum>

def Vitals.dead_tick_ok(ready, state, maximum, valid, positive):
  match ready:
    case True{}:
      Vitals.revive_ok(state, maximum, positive)
    case False{}:
      Vitals.wait_ok(state, maximum, valid)

law Vitals.upkeep_ok:
  for +state: Vitals.State
  for +amount: U32
  for +maximum: U32
  for +valid: Vitals.OK<state, maximum>
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(maximum)) == True{} : Bool}
  Vitals.OK<Vitals.upkeep_state(Vitals.upkeep(state, amount, maximum)), maximum>

def Vitals.upkeep_ok(state, amount, maximum, valid, positive):
  match state:
    case Vitals.State{hp, xp, dead, respawn, attack, spin}:
      match valid:
        case Vitals.OK{bound, life}:
          match life:
            case Vitals.Alive{flag, live}:
              %Equal.sym(U32, dead, 0, flag) : Vitals.OK<Vitals.upkeep_state(Vitals.upkeep(Vitals.State{hp, xp, _, respawn, attack, spin}, amount, maximum)), maximum>
              Vitals.live_tick_ok(Vitals.State{hp, xp, 0, respawn, attack, spin}, amount, maximum, bound, live)
            case Vitals.Dead{flag, zero}:
              %Equal.sym(U32, dead, 1, flag) : Vitals.OK<Vitals.upkeep_state(Vitals.upkeep(Vitals.State{hp, xp, _, respawn, attack, spin}, amount, maximum)), maximum>
              Vitals.dead_tick_ok(U32.is_le(respawn, 1), Vitals.State{hp, xp, 1, respawn, attack, spin}, maximum, Vitals.OK{bound, Vitals.Dead{{==}, zero}}, positive)

law Vitals.dead_hit_noop:
  for +state: Vitals.State
  for +damage: U32
  for +timer: U32
  for +dead: {Vitals.dead(state) == 1 : U32}
  {Vitals.hit(state, damage, timer) == Vitals.Hit{state, False{}} : Vitals.Hit}

def Vitals.dead_hit_noop(state, damage, timer, dead):
  %Equal.sym(U32, Vitals.dead(state), 1, dead) : {Vitals.hit_gate(U32.is_eq(_, 1), state, damage, timer) == Vitals.Hit{state, False{}} : Vitals.Hit}
  {==}

law Vitals.finish_hit_exact:
  for +remaining: Nat
  for +word: U32
  for +state: Vitals.State
  for +timer: U32
  for +exact: {U32.to_nat(word) == remaining : Nat}
  {U32.to_nat(Vitals.hp(Vitals.hit_state(Vitals.finish_hit(remaining, word, state, timer)))) == remaining : Nat}

def Vitals.finish_hit_exact(remaining, word, state, timer, exact):
  match remaining:
    case Zero{}:
      match state:
        case Vitals.State{hp, xp, dead, respawn, attack, spin}:
          {==}
    case Succ{positive}:
      match state:
        case Vitals.State{hp, xp, dead, respawn, attack, spin}:
          exact

law Vitals.live_hit_exact:
  for +state: Vitals.State
  for +damage: U32
  for +timer: U32
  for +alive: {Vitals.dead(state) == 0 : U32}
  {U32.to_nat(Vitals.hp(Vitals.hit_state(Vitals.hit(state, damage, timer)))) == H.Health.hurt(U32.to_nat(Vitals.hp(state)), U32.to_nat(damage)) : Nat}

def Vitals.live_hit_exact(state, damage, timer, alive):
  %Equal.sym(U32, Vitals.dead(state), 0, alive) : {U32.to_nat(Vitals.hp(Vitals.hit_state(Vitals.hit_gate(U32.is_eq(_, 1), state, damage, timer)))) == H.Health.hurt(U32.to_nat(Vitals.hp(state)), U32.to_nat(damage)) : Nat}
  %H.Health.hurt_word_exact(Vitals.hp(state), damage) : {U32.to_nat(Vitals.hp(Vitals.hit_state(Vitals.finish_hit(U32.to_nat(H.Health.hurt_word(Vitals.hp(state), damage)), H.Health.hurt_word(Vitals.hp(state), damage), state, timer)))) == _ : Nat}
  Vitals.finish_hit_exact(U32.to_nat(H.Health.hurt_word(Vitals.hp(state), damage)), H.Health.hurt_word(Vitals.hp(state), damage), state, timer, {==})

# The live server uses this entry with the U32 ceiling.
def Vitals.upkeep_hero(state: Vitals.State, amount: U32, +hero: G.Bq.Hero, ceiling: U32) -> Vitals.Upkeep:
  Vitals.upkeep(state, amount, R.Rewards.maximum(hero, ceiling))

law Vitals.upkeep_hero_ok:
  for +state: Vitals.State
  for +amount: U32
  for +hero: G.Bq.Hero
  for +ceiling: U32
  for +valid: Vitals.OK<state, R.Rewards.maximum(hero, ceiling)>
  for +limit_positive: {G.Bq.Nat.le(1n, U32.to_nat(ceiling)) == True{} : Bool}
  Vitals.OK<Vitals.upkeep_state(Vitals.upkeep_hero(state, amount, hero, ceiling)), R.Rewards.maximum(hero, ceiling)>

def Vitals.upkeep_hero_ok(state, amount, hero, ceiling, valid, limit_positive):
  Vitals.upkeep_ok(state, amount, R.Rewards.maximum(hero, ceiling), valid, R.Rewards.maximum_positive(hero, ceiling, limit_positive))

def Vitals.spawn(maximum: U32) -> Vitals.State:
  Vitals.State{maximum, 0, 0, 0, 0, 0}

law Vitals.spawn_ok:
  for +maximum: U32
  for +positive: {G.Bq.Nat.le(1n, U32.to_nat(maximum)) == True{} : Bool}
  Vitals.OK<Vitals.spawn(maximum), maximum>

def Vitals.spawn_ok(maximum, positive):
  Vitals.OK{H.Health.le_refl(U32.to_nat(maximum)), Vitals.Alive{{==}, positive}}

law Vitals.spawn_hero_ok:
  for +hero: G.Bq.Hero
  for +ceiling: U32
  for +limit_positive: {G.Bq.Nat.le(1n, U32.to_nat(ceiling)) == True{} : Bool}
  Vitals.OK<Vitals.spawn(R.Rewards.maximum(hero, ceiling)), R.Rewards.maximum(hero, ceiling)>

def Vitals.spawn_hero_ok(hero, ceiling, limit_positive):
  Vitals.spawn_ok(R.Rewards.maximum(hero, ceiling), R.Rewards.maximum_positive(hero, ceiling, limit_positive))

def Vitals.fell(hit: Vitals.Hit) -> Bool:
  match hit:
    case Vitals.Hit{state, fell}:
      fell

law Vitals.finish_hit_fell_dead:
  for +remaining: Nat
  for +word: U32
  for +state: Vitals.State
  for +timer: U32
  for +fell: {Vitals.fell(Vitals.finish_hit(remaining, word, state, timer)) == True{} : Bool}
  {Vitals.dead(Vitals.hit_state(Vitals.finish_hit(remaining, word, state, timer))) == 1 : U32}

def Vitals.finish_hit_fell_dead(remaining, word, state, timer, fell):
  match remaining:
    case Zero{}:
      match state:
        case Vitals.State{hp, xp, dead, respawn, attack, spin}:
          {==}
    case Succ{positive}:
      match state:
        case Vitals.State{hp, xp, dead, respawn, attack, spin}:
          Empty.absurd({0 == 1 : U32}, G.Bq.Bool.false_ne_true(fell))

law Vitals.hit_gate_fell_dead:
  for +is_dead: Bool
  for +state: Vitals.State
  for +damage: U32
  for +timer: U32
  for +fell: {Vitals.fell(Vitals.hit_gate(is_dead, state, damage, timer)) == True{} : Bool}
  {Vitals.dead(Vitals.hit_state(Vitals.hit_gate(is_dead, state, damage, timer))) == 1 : U32}

def Vitals.hit_gate_fell_dead(is_dead, state, damage, timer, fell):
  match is_dead:
    case True{}:
      Empty.absurd({Vitals.dead(state) == 1 : U32}, G.Bq.Bool.false_ne_true(fell))
    case False{}:
      Vitals.finish_hit_fell_dead(U32.to_nat(H.Health.hurt_word(Vitals.hp(state), damage)), H.Health.hurt_word(Vitals.hp(state), damage), state, timer, fell)

law Vitals.lethal_hit_reports_death:
  for +state: Vitals.State
  for +damage: U32
  for +timer: U32
  for +lethal: {G.Bq.Nat.le(U32.to_nat(Vitals.hp(state)), U32.to_nat(damage)) == True{} : Bool}
  {Vitals.fell(Vitals.hit_gate(False{}, state, damage, timer)) == True{} : Bool}

def Vitals.lethal_hit_reports_death(state, damage, timer, lethal):
  %Equal.sym(Nat, U32.to_nat(H.Health.hurt_word(Vitals.hp(state), damage)), 0n, H.Health.hurt_word_zero(Vitals.hp(state), damage, lethal)) : {Vitals.fell(Vitals.finish_hit(_, H.Health.hurt_word(Vitals.hp(state), damage), state, timer)) == True{} : Bool}
  {==}
