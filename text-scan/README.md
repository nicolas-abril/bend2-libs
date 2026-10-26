# gralha-text-scan

Text scanning and number parsing over Bend `String`s: the SVG/CSS number
grammar (signs, fractions, exponents, comma/space separated lists), length
units, hex, trimming, prefix tests, scanning up to a delimiter, plus small
`choose`/`branch`/`min`/`max`/`clamp` helpers over `U32` and `F32`.

    import gralha-text-scan@0.1.0.1/scan.bend as Scan

Main entry points: `number`, `numbers`, `scalar`, `unit`, `hex`, `until`,
`until.sequence`, `through`, `prefix`, `drop`, `trim`, `trim.both`,
`unquote`, `string.equal`, `string.contains`, `choose`, `branch`.

Depends on: Base only. Tests: `tests/` (run each from this directory).
