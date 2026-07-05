# architecture cleanup case 1429

Case 1429 closes project-scale item 6: architecture cleanup.

The finite RM remaining-gap campaign is treated as closed by case 1428. New work
must not reopen `Remaining_*_Edge` families unless a source-shaped test, real Ada
corpus case, or RM contradiction exposes a concrete defect.

## Canonical production surfaces

The canonical Ada language-intelligence surfaces are the long-lived packages used
by editor consumers, including the language model, declaration parser, project
index, symbol resolver, semantic consumers, outline, diagnostics, and semantic
colouring integration. These surfaces must remain deterministic, bounded,
snapshot-owned, and free of rendering-side parsing or dirty-state mutation.

## Quarantined historical scaffolding

Pass-numbered diagnostic, provenance, recheck, stabilization, search, and closure
scaffolds from earlier development remain as regression evidence only. They are
not production extension points and must not be re-exported through command,
workspace, keybinding, render, or public semantic APIs.

## Rejected architecture leaks

The cleanup gate rejects command aliases, compatibility spellings, rendering-side
parsing, analysis-time dirty-state mutation, command-palette/keybinding/workspace
or render mutation leaks, unowned public APIs, reopened Remaining_* gaps, pass
churn in final comments or API names, and stale source/API/cleanup fingerprints.

## Future rule

Do not add new semantic remediation passes after case 1428 unless there is a
concrete failing case. Validation, corpus work, and release readiness checks may
add tests or focused fixes, but not speculative backlog expansion.
