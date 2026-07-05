# Editor — Pass951

Pass951 extends the compiler-grade overload-resolution foundation by teaching
call-profile shape metadata and call-profile filters about formal names and
formal defaults.

Implemented:

- `Editor.Ada_Call_Profile_Shapes` now records normalized formal-name lists for
  callable declarations.
- Callable profile shapes now retain defaulted formal counts and the normalized
  names of defaulted formals.
- Actual profile shapes now retain normalized named-actual names.
- `Editor.Ada_Call_Profile_Filters` now distinguishes:
  - named actuals that match formal names;
  - named actuals that do not name any formal;
  - calls that omit required non-defaulted formals;
  - calls accepted by arity and formal-name/default metadata.
- Added `Unknown_Named_Count_For_Node` for deterministic diagnostics-facing
  metadata.
- Added AUnit regression:
  - `Test_Ada_Call_Profile_Formal_Name_Filter_Pass951`

Scope:

This is a compiler-grade overload-resolution building block for formal-name and
defaulted-formal filtering.  It does not yet complete expected-type propagation,
full profile conformance, type checking, implicit conversion legality, generic
contract matching, freezing/representation legality, or cross-unit semantic
closure.
