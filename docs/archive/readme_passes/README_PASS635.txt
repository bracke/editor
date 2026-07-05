Editor Pass 635
===========================

Focus
-----
Improve token-cursor grammar coverage for selected subtype marks by routing
subtype-mark suffix parsing through the shared selected-name suffix parser.

Changes
-------
- Updated Parse_Subtype_Mark so dotted subtype marks use the shared
  Parse_Selected_Name_Suffix routine instead of a local two-token advance.
- Preserved ordinary selected subtype marks such as Numeric.Count before range
  constraints.
- Preserved attribute-style subtype marks such as Model.Root'Class.
- Exposed operator-symbol selectors in subtype-mark contexts, for example
  Operator_Types."+".
- Exposed character-literal selectors in subtype-mark contexts, for example
  Character_Types.'A'.
- Added AUnit regression coverage verifying selected subtype-mark selectors,
  following range constraints, and recovery into a later object declaration.

Validation / scope
------------------
This pass improves structural Ada grammar coverage for selected subtype marks
with operator-symbol and character-literal selectors. It does not perform
compiler-grade legality checking for selector visibility, whether the selected
entity denotes a subtype, overload resolution, or subtype compatibility.
