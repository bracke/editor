# Editor pass707 — Outline precision for expanded Ada constructs

This pass improves Outline presentation for Ada constructs that previous passes
already parse structurally. It does not redesign the parser, does not add a
rendering-side parser, and does not perform compiler-grade semantic analysis.

## Implemented

- Refined Outline labels for variant record types:
  - `variant record type T`
  - still uses the existing type Outline kind.
- Refined Outline labels for entry-family declarations:
  - `entry family E`
  - still uses the existing subprogram Outline kind.
- Refined generic formal detail text so formal packages, formal subprograms,
  formal types, and formal objects no longer collapse to the same generic-formal
  detail wording.
- Preserved visible metadata already supplied by the language model:
  - `variant-record`
  - `entry-family`
  - `body-stub`
  - `generic-actuals`
  - `box`
- Added AUnit coverage for Outline extraction across:
  - generic formal packages
  - variant records
  - entry families
  - exceptions
  - package body stubs
- Updated validation guards and user-facing documentation.

## Non-goals

This is Outline precision only. It is not compiler-grade legality checking for
variant choice coverage, entry-family profiles, generic contract matching,
exception visibility, separate body matching, body/spec conformance, visibility,
overload resolution, or elaboration rules.
