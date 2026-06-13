Pass 604 - Direct qualified String bound attributes in later constraints

- Extended the signed static integer evaluator with the same direct static String bound-attribute scanner used by representation-expression static arithmetic.
- Later constrained String subtypes can now derive bounds from forms such as `subtype Direct_Bounds_Name is String (String'("Green")'First .. String'("Green")'Last);`.
- The new signed path also accepts the one-dimensional array attribute argument, for example `String'("Green")'First (1) .. String'("Green")'Last (1)`.
- Qualification apostrophes are skipped before selecting the final `First` / `Last` / `Length` attribute, preserving the existing direct qualified String expression handling.
- Added regression coverage for direct and dimensioned direct qualified String bound attributes feeding later representation static values.
