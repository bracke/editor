# Editor — pass750

Pass750 deepens structural grammar coverage for Ada raise statements and raise
expressions.

Changes:

* Added selected exception-name metadata for raise statements and raise
  expressions.
* Added an explicit `with` keyword boundary production for raise messages.
* Added bounded recovery productions for malformed raise message expressions and
  malformed raise expressions.
* Extended the token-cursor raise grammar regression to cover:
  * bare `raise;`
  * `raise Constraint_Error with "...";`
  * selected exception names such as `Ada.IO_Exceptions.Name_Error`
  * raise expressions inside conditional expressions
  * malformed `raise ... with` message recovery
* Updated validation guard markers and parser coverage documentation.

This improves structural grammar coverage for Ada raise statements and raise
expressions. It is not compiler-grade exception-name resolution, exception
propagation analysis, message-expression type checking, handler-placement
legality checking, or control-flow analysis.
