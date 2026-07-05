Pass 456 - Legality checking first pass

Implemented a bounded Ada legality-diagnostic layer in the in-process language model.

Scope:
- Added Legality_Diagnostic_Severity, Legality_Diagnostic_Kind, and Legality_Diagnostic_Info.
- Added bounded storage and public query API:
  - Add_Legality_Diagnostic
  - Legality_Diagnostic_Count
  - Legality_Diagnostic_At
  - Has_Legality_Diagnostics
- Wired legality diagnostics into Editor.Ada_Declaration_Parser.Parse after syntax-tree projection and executable binding extraction.

Diagnostics implemented:
- Duplicate same-scope non-overloadable declarations.
- Duplicate representation clauses for the same target/attribute kind.
- Duplicate static enumeration representation values for the same enumeration target.
- Invalid record representation component bit ranges where first bit is greater than last bit.
- Static record representation component overlap at the same storage unit.

Design constraints:
- The checker is deterministic, bounded, and uses only retained parser/language-model metadata.
- It avoids compiler-only global legality where the model does not yet retain enough information.
- It explicitly avoids flagging overloadable subprogram homographs and package body/spec pairs as duplicate declarations.

Validation:
- Added Test_Language_Model_Legality_Checking_First_Pass covering duplicate declarations, duplicate representation clauses, duplicate enumeration representation values, and invalid record representation bit ranges.
