# Canonical API Consolidation Case 1442

Case 1442 records the production-facing API boundary after the finite Remaining
Gap closure and project-scale validation passes.

Canonical production surfaces:

- semantic model
- bounded Ada parser / AST input
- name-resolution surface
- semantic diagnostic feed
- cross-unit project index

Regression-only evidence:

- finite `Remaining_*` closure evidence
- real Ada corpus validation evidence

Cleanup-only gates:

- legacy scaffold inventory
- legacy projection tower removal

Removed or quarantined surfaces may remain referenced in documentation as
historical evidence, but they must not become production APIs, command palette
surfaces, keybinding surfaces, workspace surfaces, render projections, or
mutation-capable editor integrations.

The pass rejects:

- command aliases or compatibility spellings
- production-facing legacy projection surfaces
- references to already removed legacy units
- reopened `Remaining_*` semantic gaps after case 1428
- missing tests or release documentation
- stale source, test, documentation, or API fingerprints

This creates the canonical API ledger needed before suite pruning and the
final documentation architecture map.
