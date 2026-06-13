Editor Phase 579 Pass 346
=========================

Completeness pass focused on Ada token-cursor context-clause grammar.

Implemented:
- Added explicit token-cursor productions for limited with clauses.
- Added explicit token-cursor productions for private with clauses.
- Modified context-clause parsing to recognize:
  - limited with P;
  - private with P;
  - limited private with P;
- Retained the base with-clause production for modified with clauses so downstream consumers can handle the common with-clause shape while still inspecting modifiers.
- Preserved selected-name parsing for context unit names under modified with clauses.
- Added AUnit coverage for modified with clauses and interaction with use all type clauses.
- Extended phase579_language_validation_check and release_check guards.

No Python, shell, or external parser-generator tooling was added to the project.
