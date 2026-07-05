Pass 499 - Contract operational aspect/attribute unification

Implemented another representation/operational completeness pass focused on contract-style
operational properties that were still not explicit retained representation items.

Changes:
- Added explicit retained operational property kinds for:
  - Pre
  - Pre'Class
  - Post
  - Post'Class
  - Refined_Post
  - Global
  - Depends
  - Refined_Global
  - Refined_Depends
  - Nonblocking
  - Nonblocking'Class
  - Always_Terminates
  - Contract_Cases
  - Subprogram_Variant
  - Exceptional_Cases
- Lowered both aspect specifications and attribute-definition clauses into the same
  Representation_Clause_Info stream for these properties.
- Added Boolean defaulting for aspect-only forms without explicit values:
  - Nonblocking
  - Nonblocking'Class
  - Always_Terminates
- Reused shared target compatibility routing:
  - Pre/Post/refined post/variants/exceptional cases/nonblocking/termination: subprogram-like targets
  - Global/Depends/refined forms: package or subprogram-like targets
- Reused shared duplicate detection and required-expression diagnostics.
- Added regression coverage in
  Test_Language_Model_Contract_Operational_Unification_Pass.
