# gralha-css-style

CSS for XML documents: stylesheets, selectors and combinators, specificity,
inline `style` declarations, `!important`, screen/viewport media queries and
the cascade over a `gralha-xml-doc` tree.

    import gralha-css-style@0.1.0.0/css.bend as CSS

Main entry points: `css.sheets` (collect `<style>` rules), `css.rules`,
`css.tree` (cascade rules into a tree's attributes), `css.lower`,
`css.element.count`.

Depends on: gralha-text-scan, gralha-xml-doc. Exercised by
gralha-svg-render's tests.
