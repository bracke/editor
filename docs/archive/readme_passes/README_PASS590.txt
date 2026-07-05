Pass 590 - Subtype-indication constrained String bounds

- Extended retained constrained String subtype bound extraction for index constraints spelled with a subtype indication, such as String (Positive range 2 .. 6).
- The bounded static String subtype metadata now strips the index subtype marker before evaluating the low bound, preserving First/Last/Length for these forms.
- Static qualification length checks, qualified-prefix indexing/slicing, and subtype attribute evaluation now reuse those retained bounds.
- Added regression coverage for Ranged_Name is String (Positive range 2 .. 6) feeding Ranged_Name'Last representation static values.
