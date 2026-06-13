Pass 513 - GNAT/SPARK entity pragma lowering completeness

This pass closes a drift bug in the representation/operational property
unification layer.  The shared aspect/attribute-definition property table had
explicit kinds for GNAT/SPARK operational properties such as SPARK_Mode,
Side_Effects, No_Caching, Test_Case, Annotate, and Warnings, and the pragma
kind resolver recognized their pragma names, but the pragma attribute-name
resolver did not.  Because Add_Representation_Pragma_Representation rejected
empty attribute names, entity pragmas in this cluster could be skipped before
reaching the common legality path.

Changes:
- Added pragma attribute-name lowering for SPARK_Mode, Side_Effects,
  No_Caching, Test_Case, Annotate, and Warnings.
- Kept these pragma forms on the same explicit representation/operational kinds
  already used by aspects and attribute-definition clauses.
- Added regression coverage proving entity-first GNAT operational pragmas
  (Side_Effects and No_Caching) are retained as the same explicit operational
  properties with default True values.

This reinforces the invariant that source-form aliases feed one retained
property stream before duplicate detection, target compatibility, and
value/profile legality are applied.
