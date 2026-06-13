Pass 534 - pragma target literal preservation

Implemented a focused hardening pass for the unified pragma/aspect/attribute representation path.

Changes:
- Added pragma-specific comment stripping that preserves string and character literals.
- Rewired Pragma_Target to use the literal-preserving pragma line text instead of the generic sanitized line.
- This fixes quoted operator targets in interfacing pragmas, e.g. pragma Import (C, "+"), where the generic sanitizer had blanked the operator literal before target extraction.
- Retained existing string/character-literal-safe parenthesis, comma, and association-arrow scanning for pragma arguments.
- Kept comment text ignored without losing valid literal targets before the comment.

Rationale:
- The generic line sanitizer is correct for keyword scanning, but not for pragma target extraction because Ada operator subprogram names are string literals.  Target extraction must preserve those literals while still ignoring comments.
