Pass 509 - GNAT restriction/review operational property unification

Implemented another representation/operational property completeness pass.

Changes:
- Added explicit retained operational property kinds for:
  - No_Strict_Aliasing
  - Obsolescent
  - Reviewable
  - Optimize
  - Suppress
  - Unsuppress
- Unified aspect and attribute-definition clause lowering for those properties.
- Added default True handling for bare Boolean aspect forms:
  - No_Strict_Aliasing
  - Obsolescent
  - Reviewable
- Extended entity pragma lowering for matching pragma forms where an entity target is present.
- Corrected Suppress/Unsuppress pragma target extraction so On => Entity is treated as the declaration target instead of the check name.
- Reused shared duplicate detection, target compatibility checks, required-expression diagnostics, and static Boolean legality checks.
- Added regression coverage in Test_Language_Model_GNAT_Restriction_Operational_Unification_Pass.
