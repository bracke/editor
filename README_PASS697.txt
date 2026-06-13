Editor Phase 579 - Pass 697
===========================

Scope
-----
Pass 697 implements the next bounded legality-adjacent item after pass696:
conservative local duplicate-declaration diagnostics for declaration families
whose owning region is retained structurally by the Ada language model.

Changes
-------
- Added local duplicate diagnostic kinds for:
  - duplicate record component names in the same retained record type;
  - duplicate discriminant names in the same retained discriminant part owner;
  - duplicate enumeration literal names in the same retained enumeration type;
  - duplicate generic formal names in the same retained generic formal part.
- Added a deterministic local declaration-family scan in the Ada declaration
  parser legality pass.
- Kept the scan intentionally structural and local: it uses retained parent
  symbols/scopes and normalized names, and it does not attempt visibility,
  overload resolution, generic contract matching, or conformance checks.
- Preserved existing duplicate aspect-association and duplicate representation
  clause diagnostics.
- Added AUnit regression coverage for the new local duplicate declaration
  diagnostics.
- Updated the phase579 validation guard to require the new diagnostic kinds,
  parser pass marker, and regression test.

Limitations
-----------
This pass improves bounded local diagnostics. It is not compiler-grade legality
checking for visibility, overloadability, inherited declarations, generic
contract legality, full declarative-region equivalence, representation legality,
or cross-unit semantic analysis.
