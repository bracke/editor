Phase 579 pass 301 — syntax-tree alternative ownership completeness pass

Implemented:
- Added syntax-tree node kinds for elsif parts, else parts, when alternatives, and exception sections.
- Added parser-side alternative scope tracking for sibling alternatives.
- Alternatives now own nested statement-shape nodes where visible.
- End nodes pop an active alternative scope before closing the enclosing statement/body scope.
- Exception sections pop handled-sequence begin scope and then own handler alternatives.
- Added AUnit coverage for if alternative and exception-handler ownership.
- Extended phase579_language_validation_check guards.
- Updated README and docs.

Still conservative:
- This is source-shape syntax-tree ownership, not a full Ada statement AST.
- Executable alternatives do not create Outline rows, semantic symbols, declarations, scopes, or navigation targets.
