Editor Phase 579 - Pass 642
===========================

Focus: iterated component association domain/filter grammar.

What changed
------------

- Added dedicated token-cursor productions for aggregate iterated component association internals:
  - `Production_Iterated_Component_Domain`
  - `Production_Iterated_Component_Iterator_Filter`
  - `Production_Iterated_Component_Expression`
- Updated aggregate iterated component association parsing so the domain side is parsed structurally instead of being skipped by bounded recovery to `=>`.
- Preserved existing separation from quantified expressions: aggregate forms such as `(for I in 1 .. 4 => I)` still do not emit `Production_Quantified_Expression`.
- Retained discrete-range productions for `for ... in Low .. High` aggregate iterator domains.
- Added structural handling for optional `when` filters before the association arrow.
- Extended AUnit regression coverage for for-in, for-of-reverse, filtered, and mixed aggregate iterated component associations.

Scope
-----

This improves structural grammar coverage for Ada aggregate iterated component associations. It is not compiler-grade legality checking for aggregate index coverage, container iterator legality, iterator-filter typing, or component-expression conformance.
