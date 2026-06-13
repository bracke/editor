Pass829 - Aggregate delimiter and recovery depth

This pass deepens Ada aggregate grammar metadata in the token cursor. Ordinary
aggregates, aggregate-like association lists, extension/delta aggregate
component lists, and malformed or in-progress aggregate primaries now expose
structural delimiter/separator/recovery productions:

- Production_Aggregate_Open_Delimiter
- Production_Aggregate_Close_Delimiter
- Production_Aggregate_Component_Separator
- Production_Aggregate_Missing_Close_Recovery_Boundary

AUnit coverage: Test_Language_Model_Token_Cursor_Aggregate_Delimiters_Pass829.

This improves structural grammar coverage for Ada aggregate delimiters,
separators, and missing-close recovery. It is not compiler-grade aggregate
legality checking, component-choice validation, overload resolution, compiler
invocation, LSP integration, render-side parsing, or dirty-state mutation.
