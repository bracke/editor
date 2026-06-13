Pass 610 - Quoted dots in inline String Range copies

- Tightened constrained String subtype bound detection so explicit low/high separators are found only at the top level of the index constraint.
- The String constraint scanner now skips Ada string literals and character literals before treating `..` as a bound separator.
- Inline copied range constraints such as `subtype Inline_Dot_Text_Range_Name is String (String'("..")'Range);` now take the copied Range path instead of being misread as an explicit `Low .. High` constraint.
- Existing explicit `String (2 .. 6)`, copied `Range`, subtype-indication `Positive range X'Range`, and direct bound-attribute forms keep their previous behavior.
- Added regression coverage for quoted `..` text inside an inline qualified static String prefix feeding representation-expression static values.
