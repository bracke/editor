# Editor Phase 579 Pass 655 - Return-statement expression grammar

This pass continues the IDE-grade Outline / semantic-colouring Ada parser work by tightening structural grammar coverage for Ada return statements.

## Scope

Pass 655 is limited to token-cursor grammar coverage for return-statement operands and extended-return do-parts. It does not redesign the language model, perform compiler invocation, add LSP integration, or introduce external parser generators.

## Parser/token cursor changes

- Added `Production_Return_Expression` for ordinary `return Expression;` statements.
- Added `Production_Extended_Return_Statement_Sequence` for `return Obj : T ... do ... end return;` do-parts.
- Kept existing `Production_Return_Statement`, `Production_Extended_Return_Statement`, `Production_Return_Object_Declaration`, and `Production_Extended_Return_Initializer` classifications intact.
- Preserved generic `Production_Statement_Sequence` markers for current consumers.

## Regression coverage

AUnit coverage now checks ordinary return statements with nested qualified, case, and raise expressions, plus recovery into following statements. Existing extended-return coverage now also checks the dedicated extended-return statement-sequence production.

## Non-goals

This is structural grammar coverage only. It is not compiler-grade legality checking for return type conformance, function/procedure context, accessibility, extended-return object legality, or control-flow semantics.
