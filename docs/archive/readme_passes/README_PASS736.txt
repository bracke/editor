# pass736 — Ada parser coverage matrix consolidation

Pass736 consolidates the accumulated Ada parser coverage notes into a single
coverage matrix at `docs/ada_parser_coverage_matrix.md`.

The matrix records, by grammar/model family:

* token-cursor coverage;
* syntax-tree/parser coverage;
* language-model projection;
* resolver and semantic-colouring use;
* explicit non-goals.

The validation guard now requires the consolidated matrix and checks that it
retains the important current-family rows and non-goal wording.  Existing
Outline, semantic-colouring, README, and release-checklist documentation point
to the matrix so future passes have one canonical coverage-status document.

This is documentation and release-validation consolidation only.  It does not
add new Ada grammar recognition and it is not compiler-grade legality checking.
