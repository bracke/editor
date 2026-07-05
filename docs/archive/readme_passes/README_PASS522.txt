Pass 522 - Named interfacing pragma target convergence

Implemented another representation/operational legality convergence pass.

Changes:
- Corrected target extraction for named interfacing pragmas.
- `pragma Import`, `pragma Export`, `pragma Convention`, and `pragma Interface` now prefer `Entity =>` when present, instead of assuming the entity is always the second positional argument.
- `pragma External` now also honors `Entity =>` when the entity appears after `External_Name =>` / other named arguments.
- This keeps named interfacing pragmas on the same retained representation metadata and legality path as aspects and attribute-definition clauses.
- Added regression coverage proving:
  - `pragma Import (Entity => Imported_Named, Convention => C, ...)` binds `Imported_Named` as the target.
  - `pragma External (External_Name => ..., Entity => External_Named)` binds `External_Named` as the target even when the name argument appears first.
