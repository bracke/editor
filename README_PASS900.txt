Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser
Pass900 — Entry-family empty-definition recovery

This pass improves structural grammar coverage for malformed Ada entry-family
specifications.

Implemented:

* Added Production_Entry_Family_Empty_Definition_Recovery_Boundary.
* Refined entry parenthesized-part parsing so empty entry-family definitions such
  as `entry Empty ();` produce entry-family-specific recovery metadata.
* Preserved ordinary entry declaration metadata, entry-family metadata, valid
  following entry-family index subtype metadata, parameter-profile metadata, and
  generic recovery points.
* Added AUnit regression:
  Test_Language_Model_Token_Cursor_Entry_Family_Empty_Definition_Recovery_Pass900.
* Updated validation guard markers, parser coverage docs, syntax-colouring docs,
  release checklist, and README.

Scope note:

This improves structural grammar coverage for malformed Ada entry-family
definitions. It is not compiler-grade entry-family legality checking, discrete
subtype validation, tasking legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
