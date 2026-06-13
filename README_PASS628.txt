Pass 628 - Root-range chained Base scalar attributes

- Corrected direct representation-expression evaluation for chained scalar attributes whose prefix explicitly names `'Base` on a constrained scalar subtype.
- `Primary_Color'Base'Val (2)`, `Primary_Color'Base'Succ (Green)`, and `Primary_Color'Base'Last` now evaluate against the scalar root range instead of the constrained subtype range.
- This brings direct representation arithmetic into parity with the retained qualified-discrete default handling added in passes 624-625.
- Added regression coverage in the qualified discrete constant pass for direct Base Val/Succ/Last arithmetic feeding static `Size` values.
