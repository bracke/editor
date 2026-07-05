Editor Pass 634
===========================

Focus
-----
Improve token-cursor grammar coverage for formal package actual parts,
especially the Ada box form used by generic formal package declarations.

Changes
-------
- Added a dedicated Parse_Formal_Package_Actual_Part routine.
- Kept `with package P is new G (<>);` on the formal-package box path instead
  of routing the `(<>)` payload through generic-actual association parsing.
- Continued to route non-box formal package actual parts through the existing
  generic-actual association parser so named associations and `others => <>`
  remain structural.
- Preserved the existing generic package name, selected-name, and optional
  no-actual-part formal package declaration paths.
- Extended AUnit coverage to distinguish:
  * explicit formal package actual parts
  * the dedicated `(<>)` formal package box production
  * non-box named generic actual associations
  * `others => <>` box defaults inside a non-box actual part

Validation / scope
------------------
This pass improves structural Ada grammar coverage for formal package actual
parts. It does not perform compiler-grade legality checking for formal package
matching, generic contract conformance, actual/default legality, or visibility.
