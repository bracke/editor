Pass 491 - Representation/operational property unification depth

Implemented another aspect/attribute-definition unification pass for representation properties.

Highlights:
- Added explicit retained representation clause kinds for Default_Value and Default_Component_Value.
- Extended the common representation-property lowering table so both aspect syntax and attribute-definition clause syntax feed the same metadata model:
  - with Default_Value => ...
  - for T'Default_Value use ...;
  - with Default_Component_Value => ...
  - for T'Default_Component_Value use ...;
- Reused the existing mixed-source duplicate detection for these properties.
- Added target legality for Default_Component_Value so it requires an array type target, independent of whether it came from an aspect or attribute-definition clause.
- Expanded regression coverage in the representation/operational property unification test to verify explicit kinds, aspect/clause retention, duplicate behavior, and target diagnostics.
