Editor phase 579 pass431
========================

Parser-completeness pass focused on Ada object declaration qualifier grammar.

Changes
-------
- Added Production_Object_Qualifier to Editor.Ada_Token_Cursor.
- Object declarations now retain the Ada qualifier sequence after ':' before
  subtype/access parsing:
  - aliased
  - constant
  - aliased constant
- Anonymous access object declarations with qualifiers, such as
  `Handle : aliased not null access Item;`, now keep null-exclusion and access
  definition productions instead of treating `aliased` as a subtype mark.
- Added AUnit coverage in
  Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness.
- Updated release/static validation guards and documentation notes.

Scope
-----
This is syntactic grammar retention only.  It does not perform compiler-grade
object declaration legality, aliased-object legality, constant initialization
rules, accessibility checks, null-exclusion legality, or subtype conformance.
