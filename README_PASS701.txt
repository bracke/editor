# Editor Phase 579 pass 701 - exception grammar depth

Pass 701 deepens token-cursor structural grammar coverage for Ada exception
constructs.  It adds explicit markers for exception-renaming targets, exception
handler local choice-parameter names, exception choice separators/arrows,
`others` choices, raise-statement targets, and raise-expression target/message
positions.

The pass also adds AUnit regression coverage for exception declarations,
exception renaming, multi-choice handlers, handler-local names, `others`
handlers, raise statements with messages, bare re-raise statements, and malformed
handler recovery.

This is structural editor grammar coverage only.  It is not compiler-grade
legality checking for exception visibility, handler ordering, `others` placement,
exception-message typing, raise-expression typing, or handler reachability.
