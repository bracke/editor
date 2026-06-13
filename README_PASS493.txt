Pass 493 - Broader operational aspect/attribute-definition unification

Scope
-----
Continues the representation/operational property convergence from pass 489-492.

Implemented
-----------
- Added explicit retained representation/operational clause kinds for:
  - Constant_Indexing
  - Variable_Indexing
  - Implicit_Dereference
  - Default_Iterator
  - Iterator_Element
  - Iterable
  - Aggregate
  - Max_Entry_Queue_Length
- Extended attribute-definition clause lowering so forms such as:
  - for T'Constant_Indexing use F;
  - for T'Max_Entry_Queue_Length use N;
  are retained as the same explicit metadata kinds used by aspects.
- Extended aspect lowering so matching aspect specifications feed the same retained representation/operational property stream.
- Reused common target compatibility, duplicate detection, and static natural checks for the newly explicit operational properties.
- Added regression coverage to the representation/operational unification pass for the new explicit operational properties.

Notes
-----
This pass keeps the implementation intentionally model-backed: properties that name complex aggregates or subprogram families are retained structurally and share duplicate/target/value legality without attempting full Ada RM proof of each handler profile yet.
