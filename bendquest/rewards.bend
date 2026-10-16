# The authoritative XP loop and its hero-state preservation proofs.
import Base
import ./game.bend as G
import ./health.bend as H
import ./growth.bend as Growth

type Rewards.Result is Data:
  Rewards.Result{hero: G.Bq.Hero, xp: U32, levels: U32}

def Rewards.hero(result: Rewards.Result) -> G.Bq.Hero:
  match result:
    case Rewards.Result{hero, xp, levels}:
      hero

def Rewards.level(hero: G.Bq.Hero) -> Nat:
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      level

def Rewards.charm_amount(has_bonus: Bool) -> U32:
  match has_bonus:
    case True{}:
      30
    case False{}:
      0

def Rewards.charm_bonus(charm: G.Bq.Maybe(Nat)) -> U32:
  match charm:
    case Fail{unit}:
      0
    case Done{kind}:
      Rewards.charm_amount(U32.is_eq(U32.from_nat(kind), 17))

def Rewards.maximum(+hero: G.Bq.Hero, ceiling: U32) -> U32:
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      Growth.Growth.maximum(level, vitality, Rewards.charm_bonus(charm), ceiling)

def Rewards.cost(+level: U32) -> U32:
  U32.mul(U32.mul(25, level), level)

def Rewards.eligible(+hero: G.Bq.Hero, +xp: U32) -> Bool:
  +level = U32.from_nat(Rewards.level(hero))
  Bool.and(U32.is_lt(level, 20), U32.is_ge(xp, Rewards.cost(level)))

def Rewards.loop(fuel: Nat, eligible: Bool, +hero: G.Bq.Hero, +xp: U32, +levels: U32) -> Rewards.Result:
  match fuel:
    case Zero{}:
      Rewards.Result{hero, xp, levels}
    case Succ{remaining}:
      match eligible:
        case False{}:
          Rewards.Result{hero, xp, levels}
        case True{}:
          +next_hero = G.Bq.hero_step(G.Bq.HOp.LevelUp{}, hero)
          +next_xp = U32.sub(xp, Rewards.cost(U32.from_nat(Rewards.level(hero))))
          Rewards.loop(remaining, Rewards.eligible(next_hero, next_xp), next_hero, next_xp, U32.add(levels, 1))

def Rewards.go(fuel: Nat, +hero: G.Bq.Hero, +xp: U32, levels: U32) -> Rewards.Result:
  Rewards.loop(fuel, Rewards.eligible(hero, xp), hero, xp, levels)

def Rewards.gain(+hero: G.Bq.Hero, xp: U32, gained: U32) -> Rewards.Result:
  Rewards.go(20n, hero, U32.add(xp, gained), 0)

law Rewards.level_up_health:
  for +hero: G.Bq.Hero
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(G.Bq.hero_step(G.Bq.HOp.LevelUp{}, hero), ceiling))) == True{} : Bool}

def Rewards.level_up_health(hero, hp, ceiling, valid):
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      Growth.Growth.level_up_preserves_health(hp, level, vitality, Rewards.charm_bonus(charm), ceiling, valid)

law Rewards.loop_health:
  for +fuel: Nat
  for +eligible: Bool
  for +hero: G.Bq.Hero
  for +xp: U32
  for +levels: U32
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(Rewards.hero(Rewards.loop(fuel, eligible, hero, xp, levels)), ceiling))) == True{} : Bool}

def Rewards.loop_health(fuel, eligible, hero, xp, levels, hp, ceiling, valid):
  match fuel:
    case Zero{}:
      valid
    case Succ{remaining}:
      match eligible:
        case False{}:
          valid
        case True{}:
          +next_hero = G.Bq.hero_step(G.Bq.HOp.LevelUp{}, hero)
          +next_xp = U32.sub(xp, Rewards.cost(U32.from_nat(Rewards.level(hero))))
          Rewards.loop_health(remaining, Rewards.eligible(next_hero, next_xp), next_hero, next_xp, U32.add(levels, 1), hp, ceiling, Rewards.level_up_health(hero, hp, ceiling, valid))

law Rewards.gain_health:
  for +hero: G.Bq.Hero
  for +xp: U32
  for +gained: U32
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(Rewards.hero(Rewards.gain(hero, xp, gained)), ceiling))) == True{} : Bool}

def Rewards.gain_health(hero, xp, gained, hp, ceiling, valid):
  Rewards.loop_health(20n, Rewards.eligible(hero, U32.add(xp, gained)), hero, U32.add(xp, gained), 0, hp, ceiling, valid)

law Rewards.loop_equipped:
  for +fuel: Nat
  for +eligible: Bool
  for +hero: G.Bq.Hero
  for +xp: U32
  for +levels: U32
  for +valid: G.Bq.WellEquipped(hero)
  G.Bq.WellEquipped(Rewards.hero(Rewards.loop(fuel, eligible, hero, xp, levels)))

def Rewards.loop_equipped(fuel, eligible, hero, xp, levels, valid):
  match fuel:
    case Zero{}:
      valid
    case Succ{remaining}:
      match eligible:
        case False{}:
          valid
        case True{}:
          +next_hero = G.Bq.hero_step(G.Bq.HOp.LevelUp{}, hero)
          +next_xp = U32.sub(xp, Rewards.cost(U32.from_nat(Rewards.level(hero))))
          Rewards.loop_equipped(remaining, Rewards.eligible(next_hero, next_xp), next_hero, next_xp, U32.add(levels, 1), G.Bq.ops_respect_requirements(G.Bq.HOp.LevelUp{}, hero, valid))

law Rewards.gain_equipped:
  for +hero: G.Bq.Hero
  for +xp: U32
  for +gained: U32
  for +valid: G.Bq.WellEquipped(hero)
  G.Bq.WellEquipped(Rewards.hero(Rewards.gain(hero, xp, gained)))

def Rewards.gain_equipped(hero, xp, gained, valid):
  Rewards.loop_equipped(20n, Rewards.eligible(hero, U32.add(xp, gained)), hero, U32.add(xp, gained), 0, valid)

# Server-authored grants change inventory or gold, never equipped slots or stats.
def Rewards.add_item(hero: G.Bq.Hero, kind: U32) -> G.Bq.Hero:
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      G.Bq.Hero.Hero{G.Bq.Bag.add(G.Bq.one(U32.to_nat(kind)), inv), wea, arm, hel, charm, gold, level, strength, agility, vitality, points}

def Rewards.add_gold(hero: G.Bq.Hero, amount: U32) -> G.Bq.Hero:
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      G.Bq.Hero.Hero{inv, wea, arm, hel, charm, G.Bq.Nat.add(U32.to_nat(amount), gold), level, strength, agility, vitality, points}

def Rewards.sidequest_nat(quest: Nat, hero: G.Bq.Hero) -> G.Bq.Hero:
  match quest:
    case Zero{}:
      Rewards.add_item(Rewards.add_item(Rewards.add_item(hero, 0), 0), 0)
    case Succ{rest}:
      match rest:
        case Zero{}:
          Rewards.add_item(hero, 13)
        case Succ{later}:
          Rewards.add_item(hero, 16)

def Rewards.sidequest(hero: G.Bq.Hero, quest: U32) -> G.Bq.Hero:
  Rewards.sidequest_nat(U32.to_nat(quest), hero)

law Rewards.add_item_health:
  for +hero: G.Bq.Hero
  for +kind: U32
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(Rewards.add_item(hero, kind), ceiling))) == True{} : Bool}

def Rewards.add_item_health(hero, kind, hp, ceiling, valid):
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      valid

law Rewards.add_item_equipped:
  for +hero: G.Bq.Hero
  for +kind: U32
  for +valid: G.Bq.WellEquipped(hero)
  G.Bq.WellEquipped(Rewards.add_item(hero, kind))

def Rewards.add_item_equipped(hero, kind, valid):
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      valid

law Rewards.add_gold_health:
  for +hero: G.Bq.Hero
  for +amount: U32
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(Rewards.add_gold(hero, amount), ceiling))) == True{} : Bool}

def Rewards.add_gold_health(hero, amount, hp, ceiling, valid):
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      valid

law Rewards.add_gold_equipped:
  for +hero: G.Bq.Hero
  for +amount: U32
  for +valid: G.Bq.WellEquipped(hero)
  G.Bq.WellEquipped(Rewards.add_gold(hero, amount))

def Rewards.add_gold_equipped(hero, amount, valid):
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      valid

law Rewards.sidequest_nat_health:
  for +quest: Nat
  for +hero: G.Bq.Hero
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(Rewards.sidequest_nat(quest, hero), ceiling))) == True{} : Bool}

def Rewards.sidequest_nat_health(quest, hero, hp, ceiling, valid):
  match quest:
    case Zero{}:
      Rewards.add_item_health(Rewards.add_item(Rewards.add_item(hero, 0), 0), 0, hp, ceiling, Rewards.add_item_health(Rewards.add_item(hero, 0), 0, hp, ceiling, Rewards.add_item_health(hero, 0, hp, ceiling, valid)))
    case Succ{rest}:
      match rest:
        case Zero{}:
          Rewards.add_item_health(hero, 13, hp, ceiling, valid)
        case Succ{later}:
          Rewards.add_item_health(hero, 16, hp, ceiling, valid)

law Rewards.sidequest_nat_equipped:
  for +quest: Nat
  for +hero: G.Bq.Hero
  for +valid: G.Bq.WellEquipped(hero)
  G.Bq.WellEquipped(Rewards.sidequest_nat(quest, hero))

def Rewards.sidequest_nat_equipped(quest, hero, valid):
  match quest:
    case Zero{}:
      Rewards.add_item_equipped(Rewards.add_item(Rewards.add_item(hero, 0), 0), 0, Rewards.add_item_equipped(Rewards.add_item(hero, 0), 0, Rewards.add_item_equipped(hero, 0, valid)))
    case Succ{rest}:
      match rest:
        case Zero{}:
          Rewards.add_item_equipped(hero, 13, valid)
        case Succ{later}:
          Rewards.add_item_equipped(hero, 16, valid)

law Rewards.sidequest_health:
  for +hero: G.Bq.Hero
  for +quest: U32
  for +hp: U32
  for +ceiling: U32
  for +valid: {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}
  {G.Bq.Nat.le(U32.to_nat(hp), U32.to_nat(Rewards.maximum(Rewards.sidequest(hero, quest), ceiling))) == True{} : Bool}

def Rewards.sidequest_health(hero, quest, hp, ceiling, valid):
  Rewards.sidequest_nat_health(U32.to_nat(quest), hero, hp, ceiling, valid)

law Rewards.sidequest_equipped:
  for +hero: G.Bq.Hero
  for +quest: U32
  for +valid: G.Bq.WellEquipped(hero)
  G.Bq.WellEquipped(Rewards.sidequest(hero, quest))

def Rewards.sidequest_equipped(hero, quest, valid):
  Rewards.sidequest_nat_equipped(U32.to_nat(quest), hero, valid)

law Rewards.maximum_positive:
  for +hero: G.Bq.Hero
  for +ceiling: U32
  for +limit_positive: {G.Bq.Nat.le(1n, U32.to_nat(ceiling)) == True{} : Bool}
  {G.Bq.Nat.le(1n, U32.to_nat(Rewards.maximum(hero, ceiling))) == True{} : Bool}

def Rewards.maximum_positive(hero, ceiling, limit_positive):
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      H.Health.cap_nat_word_positive(Nat.add(U32.to_nat(Rewards.charm_bonus(charm)), G.Bq.max_hp(level, vitality)), ceiling,
        (%Equal.sym(Nat, Nat.add(U32.to_nat(Rewards.charm_bonus(charm)), G.Bq.max_hp(level, vitality)), G.Bq.Nat.add(U32.to_nat(Rewards.charm_bonus(charm)), G.Bq.max_hp(level, vitality)), H.Health.add_agrees(U32.to_nat(Rewards.charm_bonus(charm)), G.Bq.max_hp(level, vitality))) : {G.Bq.Nat.le(1n, _) == True{} : Bool};
          H.Health.le_trans(1n, G.Bq.max_hp(level, vitality), G.Bq.Nat.add(U32.to_nat(Rewards.charm_bonus(charm)), G.Bq.max_hp(level, vitality)), {==}, Growth.Growth.le_add_prefix(U32.to_nat(Rewards.charm_bonus(charm)), G.Bq.max_hp(level, vitality)))), limit_positive)
