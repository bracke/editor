Pass 544 - Static representation attribute values

This pass extends the bounded static evaluator for Ada representation legality.

Implemented:
- Retains static values from prior representation attributes on a per-target basis.
- Supports static attribute references in later static expressions for:
  - Size
  - Object_Size
  - Value_Size
  - Alignment
  - Storage_Size
- Allows later representation clauses to use expressions such as:
  - Base'Size * 2
  - Aspect_Base'Size + 8
  - Aligned'Alignment * 8
- Registers both attribute-definition clauses and equivalent static aspects as static attribute-value sources.
- Keeps unknown attribute prefixes nonstatic and reports the existing static-value diagnostic.
- Adds regression coverage for clause-based Size, aspect-based Size, Alignment, and unknown-prefix rejection.

Scope:
This remains a bounded semantic model for IDE feedback. It does not attempt full compiler-grade representation attribute evaluation beyond values retained from explicit prior static representation items.
