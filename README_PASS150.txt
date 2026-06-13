Phase 579 IDE-grade outline/semantic language model pass 150

This pass hardens Ada resolver lexical scope traversal against malformed or stale
parent metadata. Resolve_In_Scope now bounds parent-chain walking by the number
of retained symbols, so a cyclic Parent_Symbol chain degrades to no match instead
of looping indefinitely during semantic colouring or outline/navigation lookup.

Changed files:
- src/core/editor-ada_symbol_resolver.adb
- tests/src/editor-syntax_semantics-tests.adb
- docs/outline.md
- docs/syntax_colouring.md
- tools/release_check.adb

Validation note:
The source changes are regression-tested in AUnit by
Test_Resolver_Cyclic_Parent_Chain_Degrades. The Ada build/AUnit suite was not
run in this environment because GNAT/gprbuild is not installed here.
