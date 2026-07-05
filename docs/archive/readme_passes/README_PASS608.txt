Pass 608 - Quoted range-word String Range copies

- Tightened copied String range-attribute constraint scanning so the subtype-indication stripper skips Ada string literals and character literals before looking for a leading discrete subtype indication marker.
- This prevents direct static String prefixes such as String'("range")'Range from being misread as if the word range inside the literal were the marker in a form like Positive range X'Range.
- Inline String Range copies now preserve the existing First/Last/Length metadata path even when the static image text itself contains the word range.
- Added regression coverage for subtype Inline_Text_Range_Name is String (String'("range")'Range) feeding representation-expression static values.
