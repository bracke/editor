Editor  IDE-grade outline/semantic language model pass440

This pass extends Ada token-cursor grammar coverage for generic actual associations in instantiations.

Changes:
- Added Production_Generic_Actual_Formal_Selector.
- Added Production_Generic_Actual_Box.
- Generic actual parts now parse named associations as selector + actual instead of parsing the selector as a generic expression and then recovering around =>.
- `Formal => <>` actuals are retained as explicit box actual defaults instead of being routed through ordinary expression parsing.
- Operator-symbol selectors such as `"=" => Some.Equal` are covered by the same selector grammar.
- Positional actuals such as `Capacity` continue to parse through ordinary expression/name grammar.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Generic_Actual_Box_Grammar_Completeness.
- Updated validation/release guards and parser documentation notes.

Remaining boundary:
The parser retains Ada grammar shape only. It does not validate generic contract matching, formal/actual conformance, box-default availability, visibility, overload legality, or compiler-grade instantiation legality.
