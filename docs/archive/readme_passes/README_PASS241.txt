Editor pass 241

This pass expands the Ada parser's statement-awareness metadata beyond the initial pass 240 executable statement recognizer.

Changes:
- Added Statement_Elsif, Statement_Else, Statement_When_Alternative,
  Statement_Exception_Handler, and Statement_Terminate_Alternative to
  Editor.Ada_Language_Model.Statement_Kind.
- Parser statement awareness now records conditional alternatives, executable
  case/exception when alternatives, exception sections, and terminate select
  alternatives.
- Record variant choices remain excluded from executable when-alternative
  metadata, matching the existing exclusion for executable case statements.
- Expanded AUnit coverage for conditional alternatives, select/terminate,
  exception handlers, and variant-record non-pollution.
- Updated Outline, semantic-colouring, release-checklist, and README notes.

This is still statement metadata, not a full Ada statement AST or expression parser.
