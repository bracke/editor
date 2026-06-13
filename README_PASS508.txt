Pass 508 - GNAT low-level operational property unification

Implemented another representation/operational property unification pass on top of pass 507.

Changes:
- Added explicit retained operational/representation property kinds for:
  - Volatile_Full_Access
  - Atomic_Always_Lock_Free
  - No_Inline
- Unified aspect and attribute-definition clause lowering for these properties.
- Extended representation pragma lowering for matching pragma forms so pragmas, aspects, and attribute-definition clauses use the same metadata stream.
- Added default True handling for bare Boolean aspect/pragma forms.
- Reused shared duplicate detection, target compatibility checks, and static Boolean legality diagnostics.
- Added target compatibility routing:
  - Volatile_Full_Access / Atomic_Always_Lock_Free: type-like or object-like targets
  - No_Inline: subprogram-like targets
- Expanded regression coverage in Test_Language_Model_GNAT_Codegen_Operational_Unification_Pass.

Files changed:
- src/core/editor-ada_language_model.ads
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
