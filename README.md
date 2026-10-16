# bend2-libs

Bend 2 libraries published on [BendHub](https://hub.bend-lang.com) under
the `gralha-` prefix, taken apart from three demos:
[bend2-svg-demo](https://github.com/nicolas-abril/bend2-svg-demo),
[bend2-tar-demo](https://github.com/nicolas-abril/bend2-tar-demo) and
[bend2-bendquest-demo](https://github.com/nicolas-abril/bend2-bendquest-demo).
The HTTP pair generalizes the svg demo's server.
Each directory is one package, imported as
`import gralha-<dir>@<version>/<entry>.bend as Name`. They need Bend 2.0.37
or newer. Each package's README covers its API.

| Package | Entry | Depends on | What |
| --- | --- | --- | --- |
| `gralha-text-scan` | `scan.bend` | | text scanning, number and hex parsing |
| `gralha-xml-doc` | `xml.bend` | text-scan | XML tokens, tree, entities, serialization |
| `gralha-css-style` | `css.bend` | text-scan, xml-doc | stylesheets, selectors, specificity, cascade |
| `gralha-bytes` | `bytes.bend` | text-scan | byte trees, DEFLATE inflate, base64, a file read effect |
| `gralha-image` | `image.bend` | text-scan | colors and pixel quadtrees |
| `gralha-png-decode` | `png.bend` | text-scan, bytes, image | PNG decoder |
| `gralha-jpeg-decode` | `jpeg.bend` | text-scan, bytes, image | baseline and progressive JPEG decoder |
| `gralha-truetype` | `font.bend` | text-scan, bytes | TrueType reader and font book |
| `gralha-coverage` | `cover.bend` | text-scan | scan-converted area coverage masks |
| `gralha-svg-render` | `svg.bend` | all of the above | SVG geometry, styles, painting, filters, rasterization |
| `gralha-byte-words` | `words.bend` | | bytes packed in `Array<U32>` and their file effects |
| `gralha-crc32` | `crc32.bend` | | CRC-32, as an effect and in pure Bend |
| `gralha-deflate` | `deflate.bend` | byte-words | DEFLATE encoder (LZ77 + Huffman) and decoder |
| `gralha-gzip-frame` | `gzip.bend` | byte-words, crc32, deflate | gzip header, trailer and members |
| `gralha-ustar` | `ustar.bend` | byte-words | ustar headers, archive streams and listing |
| `gralha-raylib` | `raylib.bend` | | a raylib binding (C only) |
| `gralha-bendquest` | `kernel.bend` | | BendQuest's proof-carrying rules kernel |
| `gralha-http-core` | `http.bend` | | HTTP/1.1 request parsing and response serialization, pure |
| `gralha-http-server` | `server.bend` | http-core | an HTTP/1.1 server loop over Base's TCP |

`<dir>/tests/` holds each package's checks; they are not published. A
package's C and JS effect files live in `<dir>/effs/` and are published with
it. `./publish.sh` publishes and names, in dependency order, every package
not yet named on the hub; BendHub registers five new names per account a
day, so it may take more than one run.

Licensed under MIT (`LICENSE`, copied into every package).
