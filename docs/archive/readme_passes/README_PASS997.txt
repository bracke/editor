# Editor Pass 997

This pass adds one compiler-grade building block for cross-unit semantic closure: deterministic spec/body consistency records over resolved unit-family links.

Implemented:

- Extended `Editor.Ada_Cross_Unit_Closure` with `Spec_Body_Consistency_Info`.
- Records package/subprogram spec-to-body and body-to-spec consistency independently from raw navigation links.
- Classifies confirmed matches, missing counterparts, ambiguous counterparts, overflow, role mismatch, and name mismatch.
- Retains source and counterpart unit names, roles, paths, candidate counts, and deterministic fingerprints.
- Added query APIs and counters:
  - `Spec_Body_Consistency_Count`
  - `Spec_Body_Consistency_At`
  - `Spec_Body_Consistent_Count`
  - `Spec_Body_Inconsistent_Count`
  - `Spec_Body_Missing_Count`
  - `Spec_Body_Ambiguous_Count`
- Added AUnit regression:
  - `Test_Ada_Cross_Unit_Spec_Body_Consistency_Pass997`

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper body/spec conformance, full expression type inference, overload resolution across units, private-view closure across clients, and complete freezing/representation legality are fully integrated.
