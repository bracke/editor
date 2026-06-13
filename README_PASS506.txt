Pass 506 - GNAT/SPARK operational property unification

Implemented another aspect/attribute-definition unification pass over the remaining operational-property surface.

Changes:
- Added explicit retained operational property kinds for SPARK_Mode, Side_Effects, No_Caching, Test_Case, Annotate, and Warnings.
- Unified aspect and attribute-definition clause lowering for those properties.
- Added default True handling for bare Boolean aspect forms for Side_Effects, No_Caching, and Warnings.
- Routed SPARK_Mode, Test_Case, Annotate, and Warnings through the shared required-expression and duplicate-detection paths.
- Added target compatibility routing for package/subprogram level SPARK/GNAT properties and subprogram-only side-effect/cache properties.
- Added regression coverage in Test_Language_Model_GNAT_SPARK_Operational_Unification_Pass.
