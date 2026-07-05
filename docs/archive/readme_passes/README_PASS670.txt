# Editor Pass 670

Focused area: generic formal subprogram internal grammar.

## Changes

- Added explicit token-cursor productions for generic formal subprogram defining designators and result subtype positions:
  - `Production_Formal_Subprogram_Defining_Designator`
  - `Production_Formal_Subprogram_Result_Subtype`
- Updated generic formal procedure/function parsing so the defining designator is retained before the optional parameter profile.
- Updated generic formal function parsing so the result subtype position after `return` is retained explicitly before ordinary subtype-indication parsing.
- Preserved existing productions for formal subprogram declarations, parameter profiles, defaults, box/null/abstract/name defaults, aspects, and generic formal declaration recovery.
- Extended AUnit regression coverage for formal procedure/function designators, parameter profiles, result subtype positions, default forms, and recovery into the following package declaration.

This improves structural grammar coverage for Ada generic formal subprogram declarations. It is not compiler-grade legality checking for subprogram profile conformance, default-name legality, mode/type matching, overload resolution, or generic contract rules.
