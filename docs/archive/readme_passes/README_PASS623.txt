Pass 623 - Compatible subtype-qualified discrete constants

- Extended bounded qualified discrete constant retention so the qualifier subtype mark may be a compatible scalar subtype, not only the declared constant type itself.
- Qualified defaults such as `Primary_Color'(Green)` now evaluate the inner operand against `Primary_Color` first, preserving subtype range checks before retaining the value for a `Color` constant.
- Out-of-range qualified defaults such as `Primary_Color'(Blue)` remain nonstatic and therefore do not feed later representation-expression arithmetic.
- Added regression coverage in the qualified discrete constant pass.
