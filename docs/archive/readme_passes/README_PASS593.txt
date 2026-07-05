Pass 593 - Spaced static String qualification

- Relaxed bounded static String qualification parsing to tolerate whitespace between the qualification apostrophe and opening parenthesis.
- Static string values such as String' ("Gr" & "een") now reuse the same retained image path as String'("Gr" & "een").
- Static bounds over constrained String qualified expressions such as Offset_Name' ("Green")'Last now preserve retained subtype bounds.
- Added regression coverage for spaced direct Value qualification and spaced constrained-qualified String bounds feeding representation expressions.
