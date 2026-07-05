# Editor — Pass715 subprogram body declarative-part depth

Pass715 deepens token-cursor coverage for Ada subprogram body structure before
and around the handled statement sequence:

* subprogram body declarative items now expose dedicated markers before `begin`;
* nested package/subprogram declarations before `begin` are skipped with bounded
  body-aware declarative-item recovery so inner `begin`/`end` pairs do not leak
  into the enclosing body scan;
* `begin` and `end` boundaries now have explicit subprogram-body productions;
* malformed subprogram bodies that reach `exception` or `end` before `begin`
  expose a bounded recovery boundary;
* recovery continues into following declarations after a malformed body.

AUnit coverage was added through
`Test_Language_Model_Token_Cursor_Subprogram_Body_Declarative_Part_Depth_Grammar_Completeness`,
and the phase validation guard now requires the new productions and regression
source.

This improves structural grammar coverage for Ada subprogram body declarative
parts. It is not compiler-grade legality checking for nested declaration
legality, body/spec conformance, missing-body completion, exception propagation,
visibility, elaboration, or control-flow semantics.
