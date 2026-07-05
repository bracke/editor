Editor pass331

This pass extends grammar-aware Ada syntax-tree recovery to declarations that appear after a handled-sequence begin.  The parser now emits Node_Unexpected_Declaration diagnostics with expected declare metadata, preserves the late declaration shape for deterministic diagnostics, and continues parsing following statements.
