# Editor Pass 689

Pass 689 deepens subprogram contract/aspect grammar coverage in the Ada token cursor.

## Implemented

- Added contract-specific aspect productions:
  - `Production_Contract_Aspect_Association`
  - `Production_Contract_Aspect_Mark`
  - `Production_Contract_Aspect_Value`
  - `Production_Global_Aspect_Expression`
  - `Production_Depends_Aspect_Expression`
- Contract aspects such as `Pre`, `Post`, `Pre'Class`, `Post'Class`, `Type_Invariant`, `Global`, `Depends`, `Refined_Global`, and `Refined_Depends` are now retained separately from generic aspect associations.
- `Global` / `Refined_Global` payloads and `Depends` / `Refined_Depends` payloads receive dedicated value-position markers before expression parsing.
- Missing contract aspect values after `=>` now produce a bounded recovery point instead of being silently flattened into expression recovery.
- Existing generic aspect productions remain intact for current Outline, syntax-tree, and semantic-colouring consumers.

## Tests

- Added AUnit coverage for contract aspects on type declarations, subprogram specifications, and protected operations.
- Added coverage for class-wide contract aspect marks and Global/Depends payload markers.
- Added malformed contract-aspect recovery coverage that verifies parsing continues into following declarations.

## Scope

This improves structural grammar coverage for Ada subprogram contracts and contract-like aspects. It is not compiler-grade legality checking for aspect placement, staticness, Global/Depends semantics, refinement conformance, class-wide inheritance, visibility, freezing, or predicate/invariant legality.
