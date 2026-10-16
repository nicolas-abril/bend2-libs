# gralha-truetype

A TrueType reader and font book: `glyf`/`loca` outlines (including composite
glyphs), `hmtx` advances, `cmap` formats 4 and 12, `OS/2` metrics and GPOS
pair kerning. Glyphs are decoded from the font's bytes on first use.

    import gralha-truetype@0.1.0.0/font.bend as Font

Main entry points: `FontBook`, `font.empty`, `font.ttf` (add a face from
`Bytes`), `font.ttf.base64`, `font.glyph`, `font.kern`, `font.metric`.

Depends on: gralha-text-scan, gralha-bytes. Tests: `tests/` (run each from
this directory).
