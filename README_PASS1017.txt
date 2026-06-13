Editor Phase 579 pass1017

This pass adds one compiler-grade building block for raise expression and no-return expression analysis. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:

- Extended Editor.Ada_Expression_Types with Raise_No_Return_Inference_Status metadata.
- Added raise-expression / raise-statement inference for parser-owned expression and statement nodes without rendering-side parsing.
- Staged exception target names, normalized target metadata, message-expression shape metadata, expected result subtype propagation, and context-unknown cases.
- Added conservative No_Return call classification when resolved callable declarations expose No_Return-style source metadata.
- Added deterministic counters:
  - Raise_Expression_Count
  - Raise_No_Return_Count
  - Raise_Message_Count
  - Raise_Unknown_Count
- Added deterministic fingerprint contribution for raise/no-return metadata.
- Added AUnit regression Test_Ada_Expression_Raise_No_Return_Inference_Pass1017.

Invariants preserved:

- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Analysis remains deterministic, bounded, and snapshot-owned.
- No LSP, compiler invocation, external parser generators, Python, or shell scripts were added to the project.
