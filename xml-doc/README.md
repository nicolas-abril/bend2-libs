# gralha-xml-doc

XML tokenizer, element tree, attributes, entity decoding (`&amp;`, `&#x41;`,
...) and serialization. Source text round-trips through `parse` and
`serialize`.

    import gralha-xml-doc@0.1.0.1/xml.bend as XML

Main entry points: `parse`, `serialize`, `Element`, `Attr`, `attr.get`,
`attr.find`, `attrs.set`, `attrs.remove`, `element.find`, `escape`.

Depends on: gralha-text-scan. Tests: `tests/` (run each from this directory).
