Pass 1323 - Enumeration representation vertical slice

This pass adds Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality.

The pass is a concrete vertical semantic slice for Ada enumeration representation clauses. It models enumeration type evidence, literal declarations, and representation clause items directly, then checks literal coverage, duplicate literal clauses, duplicate representation codes, static representation values, negative and out-of-size codes, monotonic ordering, freezing order, private/limited/incomplete/generic-formal view barriers, stream attribute profile conflicts, conflicting representation evidence, and source/type/clause fingerprint freshness.

Added AUnit coverage in Test_Ada_Enumeration_Representation_Vertical_Slice_Legality_Pass1323 and registered it in Core_Suite.

This pass intentionally avoids the previous diagnostic/provenance/recheck loop and adds one compiler-grade Ada legality slice with source-shaped enumeration representation scenarios.
