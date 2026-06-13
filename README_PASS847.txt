Editor Phase 579 Pass847 - Iterated component domain recovery depth

This pass improves structural grammar metadata for Ada aggregate iterated
component associations.  The token cursor now records a dedicated bounded
missing-domain recovery production when an aggregate iterated component
association reaches `when` or `=>` before the required iteration domain.

Added production:

* Production_Iterated_Component_Missing_Domain_Recovery_Boundary

Covered examples include:

* `(for I in 1 .. 3 => I)` as the existing well-formed domain path.
* `(for I in => I)` as missing-domain recovery before the association arrow.
* `(for I in when I > 0 => I)` as missing-domain recovery before the filter.

The pass preserves the existing iterated component association, domain,
iterator-filter, arrow, component-expression, and missing-arrow metadata.
Recovery remains bounded and leaves following declarations visible to Outline,
diagnostics, and semantic-colouring consumers.

This is structural parser/token-cursor metadata only.  It is not compiler-grade
aggregate legality checking, iterator legality checking, expression type
resolution, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.
