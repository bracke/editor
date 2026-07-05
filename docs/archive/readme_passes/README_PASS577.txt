Pass 577 - Static null string slice evaluation

- Added bounded static evaluation for Ada null string slices over retained static string constants.
- Static string slices such as `Name (3 .. 2)` now remain static and produce the empty string when the lower bound is exactly one past the upper bound and remains within the retained string's bounded index model.
- Null-slice-derived static strings expose the existing static string attributes, including `Length`, `First`, `Last`, and dimensioned forms.
- Non-null out-of-range slices and malformed null ranges remain nonstatic and continue to trigger the existing static-value diagnostics when used by representation expressions.
- Extended the static string slice regression test to cover null-slice constants feeding representation arithmetic.
