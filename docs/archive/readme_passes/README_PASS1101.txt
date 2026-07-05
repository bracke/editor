Editor Pass1101

Pass1101 deliberately widens pass scope after Pass1099/1100 by adding one larger semantic-progress package instead of another thin projection layer.

Implemented package:

  Editor.Ada_Conversion_Access_Aggregate_Legality

Scope:

  * conversion and qualified-expression legality foundation
  * numeric/static range conversion checks
  * tagged/class-wide conversion classification
  * unresolved target/operand subtype classification
  * private/limited/cross-unit view barrier classification
  * null-exclusion legality
  * access object/subprogram kind mismatch checks
  * access parameter accessibility placeholder classification
  * allocator designated-subtype compatibility checks
  * record/array aggregate structural legality checks
  * container aggregate missing-aspect classification
  * deterministic counters, lookups, and fingerprints

Added regression:

  Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101

The regression covers conversion static range and universal numeric cases, access/null-exclusion/accessibility cases, and aggregate/container aggregate structural legality. The test is registered in Core_Suite.

This pass is snapshot-owned and fixture-friendly. It performs no rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation.
