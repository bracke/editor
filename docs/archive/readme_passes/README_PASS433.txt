Pass 433 — parser completeness: numeric subtype constraints

Implemented:
- Added Production_Digits_Constraint and Production_Delta_Constraint to Editor.Ada_Token_Cursor.
- Added structural parsing for digits constraints in subtype indications, including optional range constraints.
- Added structural parsing for delta constraints in fixed-point subtype indications, including optional digits and range constraints.
- Added AUnit coverage for floating- and fixed-point subtype declarations using digits/delta/range constraints.
- Updated validation guards, release guard comments, README/docs, and release checklist.

Still not claimed:
- compiler-grade fixed-point model/scale legality;
- decimal fixed-point conformance;
- static expression validation;
- range compatibility checking;
- GNAT-equivalent semantic legality.
