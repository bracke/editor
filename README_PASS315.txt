Editor Phase 579 pass315

This pass is a completeness pass after structured aspect/pragma/representation/generic-actual parsing.

Changes:
- Added domain-specific syntax-tree child nodes for pragma names, named pragma argument associations, aspect names, aspect values, generic actual formals, and generic actual values.
- Split association parsing now emits those child nodes for aspect specifications and generic actual parts instead of only generic statement target/action nodes.
- Pragmas inside scopes are retained as pragma-statement nodes rather than being forced into root context clauses.
- Split aspect clauses are attached to the preceding declaration when possible.
- Split generic actual-part continuation lines are attached to the preceding instantiation when possible.
- Fixed the balanced-parenthesis helper so close parentheses decrement nesting exactly once.
- Removed an accidental duplicate elsif in syntax-tree line reclassification.
- Added AUnit coverage for domain-specific metadata association child nodes.
- Extended release validation guards and updated docs.

No Python, shell, or generated parser tooling was added to the project.
