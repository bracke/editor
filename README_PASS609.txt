Pass 609 - Quoted range-word String bound constraints

- Tightened constrained String low-bound subtype-indication scanning so it skips Ada string literals and character literals before looking for a leading discrete subtype marker.
- Direct static String bound constraints such as `String'("range")'First .. String'("range")'Last` are no longer misread as if the word `range` inside the literal were the marker in `Positive range X`.
- The fix preserves the existing `Positive range 2 .. 6` / `Positive range X'Range` support while keeping quoted static text independent of grammar marker detection.
- Added regression coverage for quoted `range` text in direct qualified String bound attributes feeding representation-expression static values.
