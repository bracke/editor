pass 302: expression/name parsing foundation

Changes:
- Extended Editor.Ada_Syntax_Tree.Node_Kind with expression/name production nodes.
- Added bounded expression/name child parsing under existing declaration and statement source-shape nodes.
- Added nodes for names, selected names, attributes, calls/indexing, slices, operators, literals, qualified expressions, aggregates, conditional/case/quantified expressions, ranges, and associations.
- Added AUnit coverage proving the parser-owned syntax tree retains expression/name nodes.
- Extended language_validation_check.
- Updated README and docs.

Limitations:
- This is still conservative editor-grade expression/name parsing, not GNAT-equivalent overload/type/legality analysis.
