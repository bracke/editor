Pass 502 - Subprogram and library-unit operational property unification

Implemented another representation/operational completeness pass over the common
aspect / attribute-definition clause model.

Changes:
- Added explicit retained operational property kinds for:
  - Inline
  - Inline_Always
  - No_Return
  - Elaborate_Body
  - Preelaborate
  - Pure
  - Remote_Types
  - Remote_Call_Interface
  - Shared_Passive
- Unified aspect and attribute-definition clause lowering for these properties.
- Added Boolean defaulting for aspect-only forms without explicit values.
- Added target compatibility routing:
  - Inline, Inline_Always, No_Return: subprogram-like targets
  - Elaborate_Body, Preelaborate, Pure, Remote_Types, Remote_Call_Interface,
    Shared_Passive: package-like targets
- Extended representation pragma lowering for matching pragma forms where an
  entity target is present.
- Reused common duplicate detection and static Boolean legality diagnostics.
- Added regression coverage in
  Test_Language_Model_Subprogram_Library_Operational_Unification_Pass.
