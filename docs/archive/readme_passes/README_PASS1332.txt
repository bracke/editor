Pass1332: Interface/synchronized/tagged integration vertical slice.

Added Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality as a source-shaped Ada semantic legality engine for ordinary, limited, task, protected, and synchronized interfaces.  The pass covers interface declarations, interface inheritance, primitive overriding, synchronized overriding, dispatching over interfaces, and null procedures.

The checker preserves deterministic blocker families for missing interface/type/primitive evidence, non-interface declarations, parent-interface mismatches, interface-kind mismatches, limited/synchronized interface requirements, incompatible inheritance, profile/mode/result conformance failures, overriding indicator failures, abstract primitive implementation requirements, synchronized override failures, dispatching ambiguity, static calls through interface primitives, null-procedure legality, private/limited/incomplete/generic-formal view barriers, and source/AST/type/profile/effect fingerprint freshness.

Added Test_Ada_Interface_Synchronized_Vertical_Slice_Legality_Pass1332 and registered it in Core_Suite.  Tests use source-shaped interface, primitive, override, dispatching, null procedure, view-barrier, and stale-evidence rows.
