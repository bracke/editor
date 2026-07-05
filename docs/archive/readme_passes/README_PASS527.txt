Pass 527 - Top-level pragma association parsing

Implemented another completeness pass for representation/operational pragma unification.

Changes:
- Added top-level-only pragma association arrow detection.
- `Pragma_Argument_Name` and `Pragma_Argument_Value` now ignore `=>` arrows nested inside expression values.
- Positional pragma values such as `Milliseconds (Value => 11)` are retained intact instead of being truncated to the nested association value.
- Kept named pragma argument handling for true top-level associations such as `Entity => X` and `Check_Name => Range_Check`.
- Added regression coverage proving nested named associations inside `pragma Relative_Deadline` values stay on the unified representation/operational legality path unchanged.
