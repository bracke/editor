Editor Phase 579 pass1060

This pass adds Editor.Ada_Generic_Instantiated_Body_Analysis.

The package consumes Editor.Ada_Generic_Contracts and Editor.Ada_Generic_View_Compatibility and projects generic actual/default substitutions into matching generic body contract contexts. It records whether each substitution is ordinary, defaulted, blocked by private/limited views, unresolved through cross-unit visibility, mismatched, unknown, missing a body contract, or invalid because the generic actual match is not valid.

The pass preserves generic instance identity, formal identity, body contract identity, syntax nodes, body region, formal name/subtype, actual/default text, generic view identity/status, cross-unit target/selector metadata, stable spans, counters, and deterministic fingerprints.

No parsing is performed by render code. No file IO, buffer mutation, dirty-state mutation, command registration, workspace mutation, compiler invocation, LSP, external parser generators, Python, or shell scripts are introduced into the editor implementation.

Regression coverage: Test_Ada_Generic_Instantiated_Body_Analysis_Pass1060.
