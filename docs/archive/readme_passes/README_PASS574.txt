Pass574: Static string indexing in representation evaluation

Implemented bounded static evaluation for retained one-dimensional static string component selection.

Changes:
- Added Static_String_Element_Position for indexed retained static string constants.
- Static string expressions can now treat S (N) as a Character-valued operand when S is a retained static string and N is a static in-range index.
- Concatenated strings feeding scalar Value now accept indexed string characters, for example:
  - Color'Value (Green_Name (1) & "reen")
- Character-compatible typed constants can now be initialized from indexed retained static strings, for example:
  - First_Letter : constant Character := Green_Name (1);
- Out-of-range string indexes remain nonstatic and continue to produce the existing static-value diagnostic when used by representation clauses.
- Added regression coverage for Value-fed indexing, Character constant indexing, and out-of-range index rejection.
