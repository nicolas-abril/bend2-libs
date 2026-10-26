# gralha-svg-render

An SVG renderer written in Bend: geometry, paths, strokes, styles and the CSS
cascade, gradients, patterns, masks, clips, markers, text (with TrueType
fonts) and text on paths, filters, embedded PNG/JPEG/SVG images, and
rasterization to RGB pixels. Its output matches the reference fixtures of
[bend2-svg-demo](https://github.com/nicolas-abril/bend2-svg-demo), which
uses it as its renderer.

    import gralha-svg-render@0.1.0.1/svg.bend as SVG

Main entry points: `document.fitted.fonts` and `paint.packed` (a parsed
`gralha-xml-doc` element to packed RGB pixels), `document`, `pixel`,
`text.present`.

Depends on: gralha-text-scan, gralha-xml-doc, gralha-css-style, gralha-bytes,
gralha-image, gralha-png-decode, gralha-jpeg-decode, gralha-coverage,
gralha-truetype. Tests: `tests/` (run each from this directory).
