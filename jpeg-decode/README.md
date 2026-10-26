# gralha-jpeg-decode

JPEG decoder: baseline and progressive Huffman, restart markers, grayscale,
RGB, YCbCr and Adobe CMYK/YCCK, producing a `gralha-image` picture.

    import gralha-jpeg-decode@0.1.0.1/jpeg.bend as JPEG

Main entry point: `jpeg.decode`.

Depends on: gralha-text-scan, gralha-bytes, gralha-image. Tests: `tests/`
(run each from this directory).
