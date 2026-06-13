Phase 579 pass 419 - modified type-definition grammar

This pass extends the Ada token-cursor parser to retain grammar-significant
modifiers that precede type definition bodies. Earlier parser paths recognized
record/private/interface/new definitions only when those keywords were the first
token after `is`; modified forms such as `abstract tagged limited record`,
`tagged private`, `synchronized interface`, and `abstract new Root and Iface
with private` could be approximated as subtype indications.

Implemented changes:
- Added Production_Type_Modifier.
- Added Parse_Type_Modifiers and invoked it at the start of Parse_Type_Definition.
- Added modified null-record support for `tagged null record`.
- Preserved derived-type interface lists before `with private` / `with record`.
- Added AUnit coverage in
  Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness.
- Updated validation/release guards and docs.

This is grammar retention only. It does not add compiler-grade legality checks
for taggedness, interface compatibility, limitedness, private extensions,
primitive operation rules, or inheritance legality.
