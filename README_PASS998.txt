# Editor Phase 579 Pass 998

This pass adds one compiler-grade building block for cross-unit semantic closure: deterministic child-unit and private-child legality records over the project unit index.

Implemented:

- Extended `Editor.Ada_Cross_Unit_Closure` with `Child_Unit_Legality_Info`.
- Records each child library unit independently from the raw child-to-parent link.
- Preserves child unit name, child role, child path, resolved parent name, parent role, parent path, private-child classification, candidate count, and deterministic fingerprint.
- Classifies:
  - public child with resolved package parent
  - private child with resolved package parent
  - missing parent
  - ambiguous parent
  - overflow
  - parent role mismatch
- Added query APIs and counters:
  - `Child_Unit_Legality_Count`
  - `Child_Unit_Legality_At`
  - `Child_Unit_Resolved_Count`
  - `Private_Child_Unit_Count`
  - `Child_Unit_Parent_Error_Count`
  - `Child_Unit_Missing_Parent_Count`
- Added AUnit regression:
  - `Test_Ada_Cross_Unit_Child_Private_Legality_Pass998`

Full compiler-grade Ada analysis remains incomplete until private/limited cross-unit view rules, body/spec semantic completion, subunit body-stub closure, overload/type resolution across units, and complete cross-unit generic legality are fully integrated.
