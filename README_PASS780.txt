# Editor Phase 579 pass780 - asynchronous select statement depth

Pass780 deepens tasking statement grammar for asynchronous select statements. The token cursor now tags select statements that contain a top-level `then abort` arm with asynchronous-select-specific metadata, retains the triggering alternative, distinguishes delay triggering statements, and marks the abortable part while preserving the existing shared select, delay, and abortable-part productions.

This improves structural grammar coverage for Ada asynchronous select statements. It is not compiler-grade tasking legality checking, triggering-statement legality checking, abort completion semantics, entry-call matching, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
