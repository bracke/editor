Editor pass696 -- formal package generic-contract edge cases

This pass implements the requested numbered item 1 follow-up as a focused
formal package / generic-contract grammar improvement.  It remains structural
parser coverage only, not compiler-grade generic legality checking.

Changes:
- Added formal-package-specific token-cursor productions for nested actual
  parts, nested named associations, and explicit actual-list recovery
  boundaries.
- Improved formal package actual parsing so nested calls/instantiations with
  named associations do not terminate the enclosing formal_package_actual_part.
- Preserved existing formal-package association, selector, whole-part (<>) box,
  and association-level => <> box productions.
- Added bounded recovery for trailing-comma and missing-close-parenthesis cases
  so parsing resumes at following generic formal declarations.
- Added AUnit regression coverage for nested actual associations, box defaults,
  association boxes, trailing-comma recovery, missing-close recovery, and
  continuation into a following formal type declaration.
- Updated the  validation guard so the new productions and regression
  test are required.

Invariant notes:
- No rendering-side parsing.
- No dirty-state mutation.
- No file save/reload during analysis.
- No LSP, compiler invocation, external parser generator, Python, or shell
  script is introduced into the project.
- The pass does not validate generic contract matching, visibility, conformance,
  staticness, box legality, or elaboration rules.
