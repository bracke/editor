Pass 323 completeness update

This pass extends the grammar-aware Ada syntax-tree recovery introduced in the
previous passes.  The parser now distinguishes genuinely missing explicit Ada
end boundaries from handled statement parts that are implicitly closed by the
owning body/block end.

Key changes:
- Added Node_Implicit_End recovery nodes.
- Added parser logic that closes begin/exception/exception-handler statement
  part scopes implicitly when an enclosing package body, subprogram body, task
  body, protected body, entry body, accept statement, or declare block end is
  reached.
- Preserved Node_Missing_End for true malformed nesting, such as a missing
  end if before a subprogram end.
- Added the previously referenced Pop_Alternative_Scope implementation so
  alternative scopes are synchronized before end-boundary matching.
- Added AUnit coverage for implicit statement-part recovery.
- Extended release validation guards for the new recovery node and test.

No Python, shell scripts, generated parser tooling, rendering-side parsing, or
external parser dependencies were added.
