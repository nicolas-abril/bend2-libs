# gralha-png-decode

PNG decoder: chunks, all filters, Adam7 interlacing, palettes, transparency
and every legal color type and bit depth, producing a `gralha-image` picture.

    import gralha-png-decode@0.1.0.0/png.bend as PNG

Main entry point: `png.decode`.

Depends on: gralha-text-scan, gralha-bytes, gralha-image. Exercised by
gralha-svg-render's tests.
