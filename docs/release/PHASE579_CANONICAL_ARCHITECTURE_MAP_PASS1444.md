# Phase 579 canonical architecture map - pass1444

Pass1444 completes the documentation cleanup item for Phase 579.

## Canonical production-facing surfaces

The production-facing Ada language-intelligence surfaces are:

- `Editor.Ada_Language_Model`
- `Editor.Ada_Declaration_Parser`
- `Editor.Ada_Token_Cursor`
- `Editor.Ada_Symbol_Resolver`
- the semantic diagnostic feed and canonical diagnostic index
- the cross-unit project semantic index
- release validation gates added after the pass1428 finite semantic closure

These surfaces remain the extension points for future evidence-driven work.

## Regression evidence

Historical pass packages and tests are not automatically production APIs. They may remain as regression evidence only when they still protect a source-shaped Ada legality, diagnostic, stale-evidence, or consumer-agreement case.

## Archived historical notes

Pass-level `README_PASS*.txt` files before the release-validation campaign are historical ledger entries. They are not canonical architecture specifications and must not be used to justify reintroducing removed diagnostic/projection scaffolding.

## Removed or quarantined scaffolding

Legacy diagnostic projection towers, repair-gated provenance scaffolds, and superseded worklist/search-index layers removed or pruned by passes 1437 through 1443 remain closed. Documentation must not refer to them as active production surfaces.

## Future work rule

No new `Remaining_*` edge, speculative semantic category, command alias, compatibility spelling, or projection layer may be added from documentation alone. Future semantic work requires a real failing source-shaped corpus case, an AUnit regression exposing a contradiction, or a concrete RM conflict.

## Handoff

After pass1444, the correct next cleanup item is a final dead-code sweep against the canonical architecture map and the pass1440 cleanup ledger.
