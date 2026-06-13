Pass 438 parser-completeness update

This pass extends the Ada token-cursor grammar for generic formal object
specifications.  Formal object declarations now retain their mode (`in`,
`out`, `in out`) and default expression grammar instead of being recognized
and then skipped opaquely to the next semicolon.

New token-cursor productions:

* Production_Formal_Object_Mode
* Production_Formal_Object_Default

Covered forms include:

* `Item : in Element;`
* `Defaulted, Second : in out Element := <>;`
* `Named : Element := Make_Element (1);`

This remains syntactic grammar retention only.  The editor parser does not
perform compiler-grade generic contract matching, formal object mode legality,
staticness checks, subtype conformance, or default-expression legality.
