Pass 507 - GNAT code-generation operational property unification

Implemented another representation/operational property unification pass on top of pass 506.

Changes:
- Added explicit retained operational/representation property kinds for:
  - Linker_Section
  - Machine_Attribute
  - Weak_External
  - Unreferenced
  - Unmodified
  - No_Elaboration_Code
  - Persistent_BSS
  - Universal_Aliasing
- Unified aspect and attribute-definition clause lowering for these properties.
- Added default True handling for bare Boolean aspect forms:
  - Weak_External
  - Unreferenced
  - Unmodified
  - No_Elaboration_Code
  - Persistent_BSS
  - Universal_Aliasing
- Reused shared duplicate detection, required-expression diagnostics, target compatibility checks, and static Boolean legality checks.
- Added target compatibility routing for package, type, object, and subprogram categories appropriate to each property.
- Added regression coverage in Test_Language_Model_GNAT_Codegen_Operational_Unification_Pass.

Files changed:
- src/core/editor-ada_language_model.ads
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
