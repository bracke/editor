Pass 450 - Deep generic formal type grammar

Implemented deep token-cursor parsing for Ada generic formal type declarations.

Highlights:
- Retains formal scalar boxes explicitly:
  * discrete formal type boxes: type T is (<>);
  * signed/modular range boxes: range <> / mod <>
  * floating digits boxes: digits <>
  * fixed-point delta and decimal digits boxes: delta <> [digits <>]
- Retains formal private type modifiers before private:
  * abstract
  * tagged
  * limited
  * synchronized
- Retains formal derived type internals:
  * modifiers before new
  * parent subtype mark
  * interface lists after the parent
  * with private extensions
- Retains formal interface type internals:
  * limited/task/protected/synchronized modifiers
  * interface keyword
  * trailing interface lists
- Retains formal array type internals:
  * index subtype part
  * component definition
- Retains formal access type internals through the shared access-definition parser:
  * object vs subprogram access
  * protected access-to-subprogram marker
  * access function result subtype marker
- Added regression coverage:
  Test_Language_Model_Token_Cursor_Generic_Formal_Type_Deep_Grammar_Completeness

This pass removes the previous shallow skip-to-semicolon behaviour for the internal
structure of generic formal type definitions while preserving existing outline and
semantic-colouring compatibility productions.
