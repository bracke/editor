Pass1120 adds integrated semantic closure provenance support to Editor.Ada_Diagnostic_Provenance.

The pass extends the existing provenance model with an Integrated_Closure stage and a Build_With_Integrated_Closure entry point. Indexed diagnostics produced from the integrated semantic closure feed can now be traced back to their consolidated closure row, closure status, blocker family, dependency state, original closure fingerprint, and diagnostic/index identity.

The implementation is projection-only over already-produced snapshot-owned semantic data. It performs no parsing, compiler invocation, file IO, save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation.

Added and registered AUnit regression:

  Test_Ada_Diagnostic_Provenance_Integrated_Closure_Pass1120

This pass makes the consolidated semantic closure path explainable while preserving deterministic counters, lookup behavior, and fingerprints.
