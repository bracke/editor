Editor — Pass846
===========================

Pass846 adds iterated component association arrow and missing-arrow recovery
metadata to the Ada token cursor.

Implemented productions:

* Production_Iterated_Component_Association_Arrow
* Production_Iterated_Component_Missing_Arrow_Recovery_Boundary

Covered forms include:

* (for I in 1 .. 3 => I)
* (for I in 1 .. 3 when I > 1 => I)
* malformed/in-progress (for I in 1 .. 3)

Regression coverage:

* Test_Language_Model_Token_Cursor_Iterated_Component_Arrow_Recovery_Pass846

This improves structural grammar coverage for Ada iterated component
associations. It is not compiler-grade aggregate legality checking,
iterator legality checking, expression type resolution, overload resolution,
compiler invocation, LSP integration, render-side parsing, or dirty-state
mutation.
