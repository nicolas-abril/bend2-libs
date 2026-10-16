# gralha-crc32: the IEEE CRC-32 (gzip's, zip's, PNG's) over bytes packed
# four to a U32 word, little-endian, in an Array<U32>. update_raw is a
# foreign effect (ARM CRC instructions where the C target has them, a
# table elsewhere); pure is the same function in Bend, for proofs and
# for code that must not do IO. prior is the finished CRC of the bytes
# before start, 0 for none, so a long input is checked in pieces.
import Base

# n bytes of a from byte start, after prior; the Array comes back
def update_raw(a: Array<U32>, +start: U32, +n: U32, +prior: U32) -> IO(Array<U32> & Result<&1, &1, U32 & String, U32>):
  import "./effs/words_crc32.c"
  import "./effs/words_crc32.js"

def update_got(what: String, r: Array<U32> & Result<&1, &1, U32 & String, U32>) -> IO(Array<U32> & U32):
  (a, v) = r
  match v:
    case Done{c}:
      IO.pure(Array<U32> & U32, (a, c))
    case Fail{e}:
      (code, msg) = e
      IO.die(Array<U32> & U32, 1, what ++ ": " ++ msg)

# update_raw, exiting with what and the error on a failure
def update(+what: String, a: Array<U32>, +start: U32, +n: U32, +prior: U32) -> IO(Array<U32> & U32):
  do IO<Array<U32> & U32>:
    r : Array<U32> & Result<&1, &1, U32 & String, U32> <- update_raw(a, start, n, prior)
    update_got(what, r)

# Pure
# ----

# one bit of the reflected polynomial 0xEDB88320
def bit_odd(+c: U32, odd: Bool) -> U32:
  match odd:
    case True{}:
      ((c >> 1n) .^. 3988292384 : U32)
    case False{}:
      (c >> 1n : U32)

def bit(+c: U32) -> U32:
  bit_odd(c, U32.is_eq((c .&. 1 : U32), 1))

def bits(n: Nat, +c: U32) -> U32:
  match n:
    case 0n:
      c
    case 1n+p:
      bits(p, bit(c))

def byte(+c: U32, +b: U32) -> U32:
  bits(8n, (c .^. b : U32))

type St is Type:
  St{a: Array<U32>, c: U32}

def pure_at(r: Array<U32> & U32, +c: U32, +sh: U32) -> St:
  (a, w) = r
  St{a, byte(c, (U32.shrn(w, U32.to_nat(sh)) .&. 255 : U32))}

def pure_go(n: Nat, st: St, +j: U32) -> St:
  match n, st:
    case 0n, r:
      r
    case 1n+p, St{a, c}:
      +cc = c
      pure_go(p, pure_at(Array.get(U32, a, (j >> 2n : U32)), cc, ((j .&. 3) << 3n : U32)), (j + 1 : U32))

def pure_fin(st: St) -> Array<U32> & U32:
  match st:
    case St{a, c}:
      (a, (c .^. 4294967295 : U32))

# update_raw in Bend: a bit at a time, so slow, but total and pure
def pure(a: Array<U32>, +start: U32, +n: U32, +prior: U32) -> Array<U32> & U32:
  pure_fin(pure_go(U32.to_nat(n), St{a, (prior .^. 4294967295 : U32)}, start))
