# Editor pass730 — aspect placement grammar depth

This pass deepens Ada aspect placement coverage in the token cursor without
changing the editor architecture.

Implemented:

* Added bounded placement productions for aspect specifications attached to:
  * generic formal declarations,
  * task/protected declarations and types,
  * entries and entry bodies,
  * protected operations,
  * body stubs,
  * private/incomplete type completion-like declarations,
  * package/task/protected bodies.
* Kept ordinary `Production_Aspect_Specification`, aspect associations, aspect
  marks, contract-aspect markers, and aspect values unchanged.
* Added context-retaining overloads for attached-aspect parsing so the parser
  can record the placement class before consuming the ordinary aspect
  association list.
* Extended `Test_Language_Model_Token_Cursor_Aspect_Placement_Grammar_Completeness`
  to cover the new placement markers.
* Updated phase validation guards and user-facing parser/colouring docs.

This improves structural grammar coverage for aspect placement on less-common
Ada declarations. It is not compiler-grade aspect legality checking, aspect
semantic interpretation, private completion conformance checking, or contract
verification.
