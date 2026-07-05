pass 189 completeness

This pass hardens the pass188 render-time semantic scope bridge.

Changes:
- Added source-range containment to Editor.Ada_Language_Model.Scope_For_Position.
- Kept one-point/unknown ranges conservative so incomplete parser metadata still degrades safely.
- Added Test_Semantic_Scope_For_Position_Respects_Source_Ranges.
- Updated outline, syntax-colouring, command docs, and release_check guards.

Rationale:
A parser-owned declaration that starts before a token should not keep acting as the token's lexical scope after its retained source range has ended. This prevents semantic colouring from leaking a finished nested/package/body owner into later source.

Validation:
GNAT/gprbuild/AUnit were not available in this environment, so build/test execution is still pending in a proper Ada toolchain.
