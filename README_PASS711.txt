# Editor Phase 579 Pass711 — If-statement grammar depth

Pass711 deepens Ada token-cursor structural coverage for if statements.

Implemented:

* Added explicit production markers for if-statement `then` branch boundaries.
* Added explicit production markers for `elsif` branch ownership and `elsif then` boundaries.
* Added explicit production markers for if-statement `else` branches distinct from select-statement `else` alternatives.
* Added explicit `end if` retention so `end if;` is not flattened into a generic block end marker.
* Added bounded recovery marker coverage for malformed if/elsif statements missing `then`.
* Extended AUnit coverage for nested branches, `elsif`, `else`, `end if`, malformed missing-`then` recovery, and continuation into following statements.
* Updated validation/release guards and docs.

Scope note: this improves structural grammar coverage for Ada if statements. It is not compiler-grade legality checking for condition typing, reachability, control-flow semantics, branch completeness, label matching, or nested statement legality.
