# Editor Phase 579 — Pass714 exit/goto/null/delay statement refinement

Pass714 deepens token-cursor coverage for small Ada statement forms that are
important in executable-region recovery:

* `null;` now exposes an explicit terminator boundary.
* `exit Loop_Name when Condition;` now separates the loop-name target, `when`
  keyword, and condition expression.
* malformed `exit when;` now exposes a bounded exit recovery boundary.
* malformed `goto;` now exposes a bounded goto recovery boundary.
* `delay until Expr;` now retains the `until` mode keyword separately from the
  absolute-time expression.
* malformed bare `delay;` now exposes a bounded delay recovery boundary.

AUnit coverage was added through
`Test_Language_Model_Token_Cursor_Exit_Goto_Null_Delay_Statement_Depth_Grammar_Completeness`,
and the phase validation guard now requires the new productions and regression
sources.

This improves structural grammar coverage for Ada exit, goto, null, and delay
statements. It is not compiler-grade legality checking for loop-name matching,
label visibility, null-statement placement, delay-expression typing, tasking
semantics, reachability, or control-flow legality.
