Editor Phase 579 pass756
========================

This pass deepens structural token-cursor coverage for Ada call-shaped
statements where procedure calls, selected calls, indexed prefixes, and
entry-family calls are syntactically ambiguous without semantic lookup.

Implemented:

* Added call ambiguity productions for selected prefixes, selected operation
  names, dispatching-style prefixes, indexed prefixes, actual/index lists, and
  entry-family/procedure-call ambiguity.
* Extended statement-name suffix analysis so call-shaped statements expose these
  markers while assignment-target metadata remains separate.
* Added AUnit regression:
  Test_Language_Model_Token_Cursor_Entry_Procedure_Call_Ambiguity_Metadata.
* Updated validation guards, coverage matrix, Outline notes, semantic-colouring
  notes, release checklist, and README.

This improves structural grammar coverage for Ada entry/procedure call-shaped
statements. It is not compiler-grade overload resolution, dispatching legality
checking, entry-family target resolution, profile conformance checking, or
tasking semantics.
