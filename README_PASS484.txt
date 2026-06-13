Pass 484 - Interfacing / convention legality

Implemented the next bounded Ada legality completeness step for interfacing and convention items.

Changes:
- Corrected pragma External target extraction so the first pragma argument is treated as the entity.
- Lowered interfacing pragmas into the same retained representation metadata used by attribute clauses:
  - pragma Convention -> Convention metadata
  - pragma Import -> Convention + Import + optional External_Name / Link_Name metadata
  - pragma Export -> Convention + Export + optional External_Name / Link_Name metadata
  - pragma Interface -> Convention + Import metadata
  - pragma External -> External_Name metadata
- Added named-argument handling for interfacing pragma arguments such as Convention =>, Entity =>, External_Name => and Link_Name =>.
- Lowered interfacing aspects into representation metadata:
  - Import
  - Export
  - Convention
  - External_Name
  - Link_Name
- Routed pragma/aspect forms through the existing target, value, unknown-convention, link-name, and import/export conflict diagnostics.
- Expanded subprogram-like convention targets to include generic formal subprograms and convention targets to include exceptions.
- Added regression coverage for pragma Import, pragma Interface/External, malformed pragma Convention values, aspect Import target incompatibility, and aspect Link_Name string validation.
