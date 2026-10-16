# Binary-word/natural conversion proofs for the game's actual Base codecs.
import Base
import ./game.bend as G

# Largest natural representable by a word of n bits.
def Numeric.limit(n: Nat) -> Nat:
  match n:
    case Zero{}:
      0n
    case Succ{p}:
      Succ{Nat.double(Numeric.limit(p))}

# Generalization of Base.U32.from_nat to arbitrary word widths.
def Numeric.encode(+n: Nat, k: Nat) -> Word(n):
  match k:
    case Zero{}:
      Word.zero(n)
    case Succ{p}:
      Word.inc(n, Numeric.encode(n, p))

def Numeric.full(n: Nat, w: Word(n)) -> Bool:
  match n:
    case Zero{}:
      True{}
    case Succ{p}:
      match w:
        case WCon{False{}, tail}:
          False{}
        case WCon{True{}, tail}:
          Numeric.full(p, tail)

law Numeric.encode_double:
  for +n: Nat
  for +k: Nat
  {Numeric.encode(Succ{n}, Nat.double(k)) == WCon{False{}, Numeric.encode(n, k)} : Word(Succ{n})}

def Numeric.encode_double(n, k):
  match k:
    case Zero{}:
      {==}
    case Succ{p}:
      %Numeric.encode_double(n, p) : {Word.inc(Succ{n}, Word.inc(Succ{n}, Numeric.encode(Succ{n}, Nat.double(p)))) == Word.inc(Succ{n}, Word.inc(Succ{n}, _)) : Word(Succ{n})}
      {==}

law Numeric.word_roundtrip:
  for +n: Nat
  for +w: Word(n)
  {Numeric.encode(n, Word.to_nat(n, w)) == w : Word(n)}

def Numeric.word_roundtrip(n, w):
  match n:
    case Zero{}:
      match w:
        case WNil{}:
          {==}
    case Succ{p}:
      match w:
        case WCon{False{}, tail}:
          %Numeric.word_roundtrip(p, tail) : {Numeric.encode(Succ{p}, Nat.double(Word.to_nat(p, tail))) == WCon{False{}, _} : Word(Succ{p})}
          Numeric.encode_double(p, Word.to_nat(p, tail))
        case WCon{True{}, tail}:
          %Numeric.word_roundtrip(p, tail) : {Word.inc(Succ{p}, Numeric.encode(Succ{p}, Nat.double(Word.to_nat(p, tail)))) == WCon{True{}, _} : Word(Succ{p})}
          %Numeric.encode_double(p, Word.to_nat(p, tail)) : {Word.inc(Succ{p}, Numeric.encode(Succ{p}, Nat.double(Word.to_nat(p, tail)))) == Word.inc(Succ{p}, _) : Word(Succ{p})}
          {==}

law Numeric.zero_value:
  for +n: Nat
  {Word.to_nat(n, Word.zero(n)) == 0n : Nat}

def Numeric.zero_value(n):
  match n:
    case Zero{}:
      {==}
    case Succ{p}:
      %Numeric.zero_value(p) : {Nat.double(Word.to_nat(p, Word.zero(p))) == Nat.double(_) : Nat}
      {==}

law Numeric.full_value:
  for +n: Nat
  for +w: Word(n)
  for +full: {Numeric.full(n, w) == True{} : Bool}
  {Word.to_nat(n, w) == Numeric.limit(n) : Nat}

def Numeric.full_value(n, w, full):
  match n:
    case Zero{}:
      {==}
    case Succ{p}:
      match w:
        case WCon{False{}, tail}:
          Empty.absurd({Nat.double(Word.to_nat(p, tail)) == Numeric.limit(Succ{p}) : Nat}, G.Bq.Bool.false_ne_true(full))
        case WCon{True{}, tail}:
          %Numeric.full_value(p, tail, full) : {Succ{Nat.double(Word.to_nat(p, tail))} == Succ{Nat.double(_)} : Nat}
          {==}

law Numeric.true_ne_false:
  for +e: {True{} == False{} : Bool}
  Empty

def Numeric.true_ne_false(e):
  G.Bq.Bool.false_ne_true(Equal.sym(Bool, True{}, False{}, e))

law Numeric.inc_exact:
  for +n: Nat
  for +w: Word(n)
  for +room: {Numeric.full(n, w) == False{} : Bool}
  {Word.to_nat(n, Word.inc(n, w)) == Succ{Word.to_nat(n, w)} : Nat}

def Numeric.inc_exact(n, w, room):
  match n:
    case Zero{}:
      Empty.absurd({0n == 1n : Nat}, Numeric.true_ne_false(room))
    case Succ{p}:
      match w:
        case WCon{False{}, tail}:
          {==}
        case WCon{True{}, tail}:
          %Numeric.inc_exact(p, tail, room) : {Nat.double(Word.to_nat(p, Word.inc(p, tail))) == Nat.double(_) : Nat}
          {==}

law Numeric.no_self_successor:
  for +n: Nat
  {G.Bq.Nat.le(Succ{n}, n) == False{} : Bool}

def Numeric.no_self_successor(n):
  match n:
    case Zero{}:
      {==}
    case Succ{p}:
      Numeric.no_self_successor(p)

law Numeric.below_full.go:
  for +n: Nat
  for +w: Word(n)
  for +k: Nat
  for +value: {Word.to_nat(n, w) == k : Nat}
  for +below: {G.Bq.Nat.le(Succ{k}, Numeric.limit(n)) == True{} : Bool}
  for +flag: Bool
  for +test: {Numeric.full(n, w) == flag : Bool}
  {flag == False{} : Bool}

def Numeric.below_full.go(n, w, k, value, below, flag, test):
  match flag:
    case False{}:
      {==}
    case True{}:
      +at_limit = Equal.trans(Nat, k, Word.to_nat(n, w), Numeric.limit(n), Equal.sym(Nat, Word.to_nat(n, w), k, value), Numeric.full_value(n, w, test))
      +self_below = Equal.trans(Bool, G.Bq.Nat.le(Succ{k}, Numeric.limit(n)), G.Bq.Nat.le(Succ{Numeric.limit(n)}, Numeric.limit(n)), False{}, Equal.cong(Nat, Bool, x => G.Bq.Nat.le(Succ{x}, Numeric.limit(n)), k, Numeric.limit(n), at_limit), Numeric.no_self_successor(Numeric.limit(n)))
      Empty.absurd({True{} == False{} : Bool}, G.Bq.Bool.false_ne_true(Equal.trans(Bool, False{}, G.Bq.Nat.le(Succ{k}, Numeric.limit(n)), True{}, Equal.sym(Bool, G.Bq.Nat.le(Succ{k}, Numeric.limit(n)), False{}, self_below), below)))

law Numeric.nat_roundtrip:
  for +n: Nat
  for +k: Nat
  for +fits: {G.Bq.Nat.le(k, Numeric.limit(n)) == True{} : Bool}
  {Word.to_nat(n, Numeric.encode(n, k)) == k : Nat}

def Numeric.nat_roundtrip(n, k, fits):
  match k:
    case Zero{}:
      Numeric.zero_value(n)
    case Succ{p}:
      +prev = Numeric.nat_roundtrip(n, p, G.Bq.le_step_down(p, Numeric.limit(n), fits))
      +room = Numeric.below_full.go(n, Numeric.encode(n, p), p, prev, fits, Numeric.full(n, Numeric.encode(n, p)), {==})
      %prev : {Word.to_nat(n, Word.inc(n, Numeric.encode(n, p))) == Succ{_} : Nat}
      Numeric.inc_exact(n, Numeric.encode(n, p), room)

law Numeric.double_le:
  for +a: Nat
  for +b: Nat
  for +ab: {G.Bq.Nat.le(a, b) == True{} : Bool}
  {G.Bq.Nat.le(Nat.double(a), Nat.double(b)) == True{} : Bool}

def Numeric.double_le(a, b, ab):
  match a:
    case Zero{}:
      {==}
    case Succ{p}:
      match b:
        case Zero{}:
          Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(ab))
        case Succ{q}:
          Numeric.double_le(p, q, ab)

law Numeric.word_bounded:
  for +n: Nat
  for +w: Word(n)
  {G.Bq.Nat.le(Word.to_nat(n, w), Numeric.limit(n)) == True{} : Bool}

def Numeric.word_bounded(n, w):
  match n:
    case Zero{}:
      {==}
    case Succ{p}:
      match w:
        case WCon{False{}, tail}:
          G.Bq.le_succ_r(Nat.double(Word.to_nat(p, tail)), Nat.double(Numeric.limit(p)), Numeric.double_le(Word.to_nat(p, tail), Numeric.limit(p), Numeric.word_bounded(p, tail)))
        case WCon{True{}, tail}:
          Numeric.double_le(Word.to_nat(p, tail), Numeric.limit(p), Numeric.word_bounded(p, tail))

law Numeric.u32_encode_agrees:
  for +k: Nat
  {U32.from_nat(k) == U32{Numeric.encode(32n, k)} : U32}

def Numeric.u32_encode_agrees(k):
  match k:
    case Zero{}:
      {==}
    case Succ{p}:
      %Numeric.u32_encode_agrees(p) : {U32.inc(U32.from_nat(p)) == U32.inc(_) : U32}
      {==}

law Numeric.u32_roundtrip:
  for +w: U32
  {U32.from_nat(U32.to_nat(w)) == w : U32}

def Numeric.u32_roundtrip(w):
  match w:
    case U32{bits}:
      %Numeric.word_roundtrip(32n, bits) : {U32.from_nat(Word.to_nat(32n, bits)) == U32{_} : U32}
      Numeric.u32_encode_agrees(Word.to_nat(32n, bits))

# A representability witness avoids evaluating a closed 2^32-sized unary
# bound during type conversion. It carries an actual word with the exact
# natural value; it is not an assumed upper bound.
type Numeric.Fits<-n: Nat, -k: Nat> is Data:
  Numeric.Fits{word: Word(n), exact: {Word.to_nat(n, word) == k : Nat}}

law Numeric.value_fits:
  for +n: Nat
  for +w: Word(n)
  Numeric.Fits<n, Word.to_nat(n, w)>

def Numeric.value_fits(n, w):
  Numeric.Fits{w, {==}}

law Numeric.fits_bound:
  for +n: Nat
  for +k: Nat
  for +fits: Numeric.Fits<n, k>
  {G.Bq.Nat.le(k, Numeric.limit(n)) == True{} : Bool}

def Numeric.fits_bound(n, k, fits):
  match fits:
    case Numeric.Fits{word, exact}:
      %exact : {G.Bq.Nat.le(_, Numeric.limit(n)) == True{} : Bool}
      Numeric.word_bounded(n, word)

law Numeric.representable_roundtrip:
  for +n: Nat
  for +k: Nat
  for +fits: Numeric.Fits<n, k>
  {Word.to_nat(n, Numeric.encode(n, k)) == k : Nat}

def Numeric.representable_roundtrip(n, k, fits):
  Numeric.nat_roundtrip(n, k, Numeric.fits_bound(n, k, fits))

law Numeric.le_trans:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for +ab: {G.Bq.Nat.le(a, b) == True{} : Bool}
  for +bc: {G.Bq.Nat.le(b, c) == True{} : Bool}
  {G.Bq.Nat.le(a, c) == True{} : Bool}

def Numeric.le_trans(a, b, c, ab, bc):
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
              Numeric.le_trans(ap, bp, cp, ab, bc)

law Numeric.fits_downward:
  for +n: Nat
  for +lower: Nat
  for +upper: Nat
  for +fits: Numeric.Fits<n, upper>
  for +below: {G.Bq.Nat.le(lower, upper) == True{} : Bool}
  Numeric.Fits<n, lower>

def Numeric.fits_downward(n, lower, upper, fits, below):
  Numeric.Fits{Numeric.encode(n, lower), Numeric.nat_roundtrip(n, lower, Numeric.le_trans(lower, upper, Numeric.limit(n), below, Numeric.fits_bound(n, upper, fits)))}

law Numeric.u32_value_fits:
  for +w: U32
  Numeric.Fits<32n, U32.to_nat(w)>

def Numeric.u32_value_fits(w):
  match w:
    case U32{bits}:
      Numeric.value_fits(32n, bits)

law Numeric.u32_nat_roundtrip:
  for +k: Nat
  for +fits: Numeric.Fits<32n, k>
  {U32.to_nat(U32.from_nat(k)) == k : Nat}

def Numeric.u32_nat_roundtrip(k, fits):
  %Equal.sym(U32, U32.from_nat(k), U32{Numeric.encode(32n, k)}, Numeric.u32_encode_agrees(k)) : {U32.to_nat(_) == k : Nat}
  Numeric.representable_roundtrip(32n, k, fits)

law Numeric.bool_cmp_refl:
  for +bit: Bool
  {Bool.cmp(bit, bit) == EQ{} : Cmp}

def Numeric.bool_cmp_refl(bit):
  match bit:
    case False{}:
      {==}
    case True{}:
      {==}

law Numeric.word_cmp_refl:
  for +n: Nat
  for +word: Word(n)
  {Word.cmp(n, word, word) == EQ{} : Cmp}

def Numeric.word_cmp_refl(n, word):
  match n:
    case Zero{}:
      {==}
    case Succ{p}:
      match word:
        case WCon{bit, rest}:
          %Equal.sym(Cmp, Word.cmp(p, rest, rest), EQ{}, Numeric.word_cmp_refl(p, rest)) : {Word.cmp.fin(bit, bit, _) == EQ{} : Cmp}
          Numeric.bool_cmp_refl(bit)

law Numeric.u32_eq_refl:
  for +word: U32
  {U32.is_eq(word, word) == True{} : Bool}

def Numeric.u32_eq_refl(word):
  match word:
    case U32{bits}:
      %Equal.sym(Cmp, Word.cmp(32n, bits, bits), EQ{}, Numeric.word_cmp_refl(32n, bits)) : {Cmp.is_eq(_) == True{} : Bool}
      {==}

law Numeric.cmp_eq:
  for +order: Cmp
  for +equal: {Cmp.is_eq(order) == True{} : Bool}
  {order == EQ{} : Cmp}

def Numeric.cmp_eq(order, equal):
  match order:
    case LT{}:
      Empty.absurd({LT{} == EQ{} : Cmp}, G.Bq.Bool.false_ne_true(equal))
    case EQ{}:
      {==}
    case GT{}:
      Empty.absurd({GT{} == EQ{} : Cmp}, G.Bq.Bool.false_ne_true(equal))

law Numeric.cmp_tail_eq:
  for +a: Bool
  for +b: Bool
  for +tail: Cmp
  for +equal: {Word.cmp.fin(a, b, tail) == EQ{} : Cmp}
  {tail == EQ{} : Cmp}

def Numeric.cmp_tail_eq(a, b, tail, equal):
  match tail:
    case LT{}:
      Empty.absurd({LT{} == EQ{} : Cmp}, G.Bq.Bool.false_ne_true(Equal.cong(Cmp, Bool, (c => Cmp.is_eq(c)), LT{}, EQ{}, equal)))
    case EQ{}:
      {==}
    case GT{}:
      Empty.absurd({GT{} == EQ{} : Cmp}, G.Bq.Bool.false_ne_true(Equal.cong(Cmp, Bool, (c => Cmp.is_eq(c)), GT{}, EQ{}, equal)))

law Numeric.bool_cmp_eq:
  for +a: Bool
  for +b: Bool
  for +equal: {Bool.cmp(a, b) == EQ{} : Cmp}
  {a == b : Bool}

def Numeric.bool_cmp_eq(a, b, equal):
  match a:
    case False{}:
      match b:
        case False{}:
          {==}
        case True{}:
          Empty.absurd({False{} == True{} : Bool}, G.Bq.Bool.false_ne_true(Equal.cong(Cmp, Bool, (c => Cmp.is_eq(c)), LT{}, EQ{}, equal)))
    case True{}:
      match b:
        case False{}:
          Empty.absurd({True{} == False{} : Bool}, G.Bq.Bool.false_ne_true(Equal.cong(Cmp, Bool, (c => Cmp.is_eq(c)), GT{}, EQ{}, equal)))
        case True{}:
          {==}

law Numeric.word_cmp_eq:
  for +n: Nat
  for +a: Word(n)
  for +b: Word(n)
  for +equal: {Word.cmp(n, a, b) == EQ{} : Cmp}
  {a == b : Word(n)}

def Numeric.word_cmp_eq(n, a, b, equal):
  match n:
    case Zero{}:
      match a:
        case WNil{}:
          match b:
            case WNil{}:
              {==}
    case Succ{p}:
      match a:
        case WCon{ah, at}:
          match b:
            case WCon{bh, bt}:
              +tail = Numeric.cmp_tail_eq(ah, bh, Word.cmp(p, at, bt), equal)
              %Numeric.bool_cmp_eq(ah, bh, (%tail : {Word.cmp.fin(ah, bh, _) == EQ{} : Cmp}; equal)) : {WCon{ah, at} == WCon{_, bt} : Word(Succ{p})}
              %Numeric.word_cmp_eq(p, at, bt, tail) : {WCon{ah, at} == WCon{ah, _} : Word(Succ{p})}
              {==}

law Numeric.u32_eq_sound:
  for +a: U32
  for +b: U32
  for +equal: {U32.is_eq(a, b) == True{} : Bool}
  {a == b : U32}

def Numeric.u32_eq_sound(a, b, equal):
  match a:
    case U32{ab}:
      match b:
        case U32{bb}:
          %Numeric.word_cmp_eq(32n, ab, bb, Numeric.cmp_eq(Word.cmp(32n, ab, bb), equal)) : {U32{ab} == U32{_} : U32}
          {==}
