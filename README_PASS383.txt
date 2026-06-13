Editor Phase 579 pass383 — executable return binding completeness

This pass extends the parser-owned executable expression/name binding metadata added in passes 375-382.

Implemented:
- Added Binding_Return_Target for ordinary return expression name targets such as `return Saved;`.
- Added Binding_Return_Object for extended return object declarations such as `return Result : Rec := Saved do`.
- Return bindings preserve source spelling, normalized lookup names, ranges, lexical scope, expression text, and optional local target symbols.
- Function/subprogram specifications containing `return` remain excluded from executable return binding extraction.
- Semantic colouring can treat extended return objects as value-like local bindings when safe.

Added test:
- Test_Language_Model_Executable_Return_Bindings

Still conservative:
- No GNAT-equivalent return statement legality checking.
- No full expression AST for all return expressions.
- Unresolved return targets degrade instead of being guessed.
