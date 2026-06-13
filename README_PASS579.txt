Pass 579 - Apostrophe character literal static evaluation

- Added a shared bounded decoder for Ada character literals in static representation evaluation.
- Recognized the Ada apostrophe character literal spelling `''''` as a static Character value.
- Wired apostrophe literals through Character-compatible typed constants, Character'Pos, Character'Value image parsing, and static string concatenation.
- Preserved existing rejection of malformed/multi-character fragments.
- Added regression coverage for direct apostrophe literals, Character'Value ("''''"), string concatenation, static string length, and indexed apostrophe strings.
