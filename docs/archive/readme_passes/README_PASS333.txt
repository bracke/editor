pass333 — private-part syntax-tree ownership completeness

This pass extends the Ada syntax-tree grammar layer so private parts are scope-owning sections instead of flat markers.

Changes:
- Node_Private_Part now opens a bounded syntax-tree scope.
- Declarations after `private` in package/task/protected specifications are owned by the private-part node.
- The private-part scope closes structurally with Node_Implicit_End at the enclosing end boundary.
- Declarations before `private` remain owned by the visible part.
- Added regression coverage in Test_Language_Model_Syntax_Tree_Private_Parts_Own_Declarations.
- Extended language_validation_check guards for private-part scope ownership and closure.

No Python, shell scripts, or external parser generators were added.
