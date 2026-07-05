Editor IDE-grade Outline / Semantic Colouring / Ada Parser - Pass904

This pass improves structural Ada grammar recovery for malformed goto statements
whose target position contains a reserved statement-sequence boundary.

Scope:
- Adds Production_Goto_Target_Reserved_Boundary_Recovery_Boundary.
- Refines goto-target parsing so forms such as `goto else;` are treated as
  missing-target recovery instead of fabricating `else` as a label name.
- Preserves broader goto recovery metadata, generic recovery metadata, valid
  following goto label names, and statement terminator metadata.
- Adds AUnit regression coverage in
  Test_Language_Model_Token_Cursor_Goto_Target_Reserved_Boundary_Recovery_Pass904.

This remains editor-grade structural parsing. It is not compiler-grade label
legality checking, control-flow legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
