pass 376: executable-statement semantic binding completeness

This pass extends the pass375 executable binding bridge so call targets that appear
inside executable expressions are retained as parser-owned language-model metadata,
not only standalone call statements.

Implemented:
- expression call-target scanning for executable lines
- call-target bindings inside if conditions, assignment RHS expressions, and nested
  actual expressions
- attribute-call false-positive avoidance for forms such as Integer'Image (...)
- declaration/visibility line exclusion so subprogram specs, package/type clauses,
  with/use clauses, and representation clauses do not become executable bindings
- regression coverage for embedded executable expression call targets

Still conservative:
- no full GNAT statement legality checking
- no full expression/name AST binding for every executable form
- no wildcard binding for unknown executable expressions
- unresolved names still degrade to ordinary identifiers
