Editor Pass851

Delay statement missing-expression recovery depth.

This pass adds token-cursor recovery productions for malformed/in-progress Ada
delay statements that reach a terminator or synchronization boundary before the
required time expression:

* Production_Delay_Until_Missing_Expression_Recovery_Boundary
* Production_Delay_Relative_Missing_Expression_Recovery_Boundary

The parser keeps well-formed `delay until Clock;` and `delay 0.1;` expression
metadata intact, while `delay until;` and `delay;` retain bounded
delay-specific missing-expression metadata and leave following statements
visible to Outline, diagnostics, and semantic-colouring consumers.

Regression coverage: Test_Language_Model_Token_Cursor_Delay_Expression_Recovery_Pass851.

Scope: structural parser/token-cursor coverage only. This is not
compiler-grade delay legality checking, time-expression type checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.
