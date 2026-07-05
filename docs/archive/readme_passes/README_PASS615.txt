Pass 615 - Canonical Standard.String qualified bounds

- Made the direct qualified String bound evaluator rely on the canonical subtype root when deciding whether a qualification prefix is String-compatible.
- This keeps fully qualified predefined String qualifiers such as Standard.String'("Green")'Length on the same bounded static path as String'("Green")'Length.
- Added regression coverage in the static String Length representation test for Standard.String-qualified bound attributes feeding Size arithmetic.
- Preserved constrained String subtype/object bound retention, copied Range handling, and one-dimensional dimension checks.
