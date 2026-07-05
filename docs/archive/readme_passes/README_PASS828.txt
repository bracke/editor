Editor Pass828
===========================

Scope
-----
Pass828 improves structural Ada grammar coverage for subtype constraint actual
parts by adding delimiter, separator, and bounded missing-close recovery metadata
for index constraints and discriminant constraints.

Implemented
-----------
* Added token-cursor productions for index-constraint open/close delimiters,
  item separators, and missing-close recovery boundaries.
* Added token-cursor productions for discriminant-constraint open/close
  delimiters, association separators, and missing-close recovery boundaries.
* Updated index-constraint parsing so multi-dimensional constraints such as
  `Vector (1 .. 10, 1 .. 20)` retain top-level separator metadata.
* Updated discriminant-constraint parsing so named associations such as
  `Rec (Low => 1, High => 10)` retain top-level association separator metadata.
* Added bounded recovery for malformed/in-progress constraints so a missing
  right parenthesis does not consume the following declaration terminator.
* Added AUnit regression coverage in
  `Test_Language_Model_Token_Cursor_Constraint_Delimiters_Pass828`.
* Updated validation and release guard text.

Non-goals
---------
This is structural grammar coverage only. It is not compiler-grade subtype
constraint legality checking, discriminant/index disambiguation, static range
validation, subtype conformance validation, overload resolution, compiler
invocation, LSP integration, render-side parsing, or dirty-state mutation.
