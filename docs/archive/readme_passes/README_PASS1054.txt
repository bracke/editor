Pass1054 - Ada selected-name cross-unit lookup consumer

This pass extends Editor.Ada_Selected_Name_Resolution with cross-unit-aware consumer entry points:

- Build_With_Cross_Unit
- Resolve_Selected_With_Cross_Unit

The original Build and Resolve_Selected paths remain local/direct/use based and unchanged. The new cross-unit path consults Editor.Ada_Cross_Unit_Lookup_Integration only after local/use prefix lookup reports not found. Selected-name metadata now records:

- cross-unit lookup identity
- cross-unit lookup status
- target unit name
- target path
- deterministic fingerprint contribution

Covered cross-unit prefix states:

- ordinary with-visible prefix
- context use-visible prefix
- limited incomplete-view prefix
- private-view prefix
- missing dependency prefix
- ambiguous prefix
- overflow prefix

This pass is deliberately prefix-oriented. It does not yet resolve selectors inside imported units. That remains a later cross-unit semantic-closure task.

Regression:

- Test_Ada_Selected_Name_Cross_Unit_Lookup_Consumer_Pass1054
