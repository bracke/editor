Pass1119 — Integrated semantic closure diagnostic feed integration

This pass extends Editor.Ada_Semantic_Diagnostic_Feed with Build_With_Integrated_Closure, allowing the consolidated semantic closure model from Pass1118 to flow into the existing snapshot-guarded unified diagnostic feed and semantic diagnostic index.

Implemented:
- Integrated semantic closure rows are converted into deterministic semantic diagnostic feed entries.
- Legal closure rows are withheld from diagnostics; non-legal closure states become active feed entries.
- Closure statuses map to deterministic severity:
  - hard semantic blockers and dependency failures become errors;
  - private/limited/stale/not-checked/indeterminate closure states become warnings;
  - legal rows remain non-diagnostic.
- Closure blockers map into the existing semantic source families:
  - expression/overload/staticness/accessibility/contract/elaboration/completion/renaming/exception/multiple/indeterminate blockers map to expression diagnostics;
  - dependency failures map to cross-unit diagnostics;
  - representation blockers map to representation diagnostics.
- Stale integrated-closure inputs expose zero active rows and preserve rejected-entry totals.
- Rejected base semantic diagnostic guards withhold integrated closure diagnostics and preserve rejected accounting.
- Existing semantic diagnostic index consumers can query integrated closure diagnostics by node and position without a new projection chain.

Added regression:
- Test_Ada_Integrated_Semantic_Diagnostic_Feed_Pass1119

Registered in:
- tests/src/core_suite.adb

Invariant notes:
- No rendering-side parsing.
- No file save/reload or dirty-state mutation.
- No command-palette, keybinding, workspace, or render mutation.
- No compiler invocation, LSP, parser generator, Python, or shell scripts added to the project.
- Analysis remains deterministic, bounded, and snapshot-owned.
