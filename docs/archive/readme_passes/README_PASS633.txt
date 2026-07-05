Editor Pass 633
===========================

Focus
-----
Improve token-cursor grammar coverage for subprogram completion tails with
attached aspects.

Changes
-------
- Updated Parse_Subprogram_Construct so detected `is abstract` and `is null`
  completions consume the completion keyword before looking for an attached
  aspect specification or semicolon.
- Retained aspects after null procedure declarations and abstract subprogram
  declarations as explicit aspect productions instead of allowing balanced
  semicolon recovery to skip them.
- Left expression-function completion handling on its existing expression path
  and covered it in the same regression fixture to guard tail consistency.
- Added AUnit coverage for:
  * `procedure P (...) is null with Pre => ..., Post => ...;`
  * `function F (...) return T is abstract with Global => null;`
  * expression-function aspects after `is (...)`
  * recovery into a following object declaration.

Validation / scope
------------------
This pass improves structural Ada grammar coverage for subprogram completion
aspects. It does not perform compiler-grade legality checking for contract
semantics, abstract-operation placement, null-procedure conformance, or
aspect-specific rules.
