Pass 503 - Synonym operational property unification

Implemented another aspect/attribute-definition legality unification pass.

Changes:
- Added explicit retained operational property kinds for:
  - Predicate
  - Invariant
  - Precondition
  - Postcondition
  - All_Calls_Remote
- Lowered aspect forms and attribute-definition clauses for those properties into the same representation/operational metadata stream.
- Added Predicate/Invariant as type-target operational properties alongside Static_Predicate, Dynamic_Predicate, Predicate_Failure, Type_Invariant, and Type_Invariant'Class.
- Added Precondition/Postcondition as subprogram-target operational properties alongside Pre, Pre'Class, Post, Post'Class, and Refined_Post.
- Added All_Calls_Remote as a package-target Boolean operational property alongside library-unit categorization properties.
- Added default True handling for bare All_Calls_Remote aspect forms.
- Extended representation pragma lowering for pragma All_Calls_Remote.
- Fixed the duplicate Global mapping branch in the representation-kind resolver while extending the table.
- Added regression coverage proving the synonym aspect forms and attribute-definition clauses retain the same explicit property kinds.
