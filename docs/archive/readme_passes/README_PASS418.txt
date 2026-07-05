Pass418 parser-completeness pass

Implemented structured token-cursor grammar for parameter and discriminant profile items.

Changes:
- Added Production_Aliased_Part.
- Added Production_Parameter_Mode.
- Added Production_Default_Expression.
- Replaced opaque parameter-profile item skipping with structural parsing of:
  - defining-name lists;
  - aliased profile qualifiers;
  - in/out/in out modes;
  - subtype indications;
  - anonymous access definitions;
  - not-null access definitions;
  - default expressions.
- Replaced opaque discriminant-specification skipping with structural parsing of:
  - defining-name lists;
  - subtype indications;
  - default expressions.
- Added AUnit coverage in Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness.
- Updated validation and release guards.
- Updated README and language-analysis docs.

This is syntax coverage only. It does not attempt compiler-grade parameter-mode legality,
profile conformance, accessibility, subtype conformance, or default-expression legality.
