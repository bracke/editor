# Editor Phase 579 - Pass 645

Focused grammar-coverage pass: Ada 2022 declare-expression part structure.

## Changes

- Added `Production_Declare_Expression_Declarative_Part` to the Ada token-cursor grammar production set.
- Added `Production_Declare_Expression_Body_Expression` to retain the single expression after `begin` in a declare expression.
- Updated declare-expression parsing so declarations before `begin` and the body expression after `begin` are represented as explicit structural positions.
- Preserved existing nested declaration parsing inside declare-expression declarative parts.
- Extended AUnit coverage for declare expressions used in object initializers and assignment statements, including parser recovery into surrounding statements.

## Scope

This improves structural grammar coverage for Ada 2022 declare-expression declarative parts and body expressions. It is not compiler-grade legality checking for declaration placement, object lifetime, subtype compatibility, staticness, or expression expected-type conformance.
