Editor Phase 579 pass760 — coverage matrix refresh after pass737-pass759

This pass refreshes docs/ada_parser_coverage_matrix.md so the canonical parser/status matrix reflects the later structural Ada grammar/model passes.

Updated coverage rows include:

* case/select/exception alternatives;
* loop iteration schemes;
* entry/tasking statements;
* statement labels, blocks, gotos, and call-shaped statement ambiguity;
* return/raise/delay/requeue/abort statement detail;
* variant records and aggregate associations;
* callable profile parameter metadata;
* generic formal type detail metadata;
* separate subunits and body stubs;
* context clauses;
* recovery diagnostics and hostile-source coverage;
* local duplicate representation diagnostics.

The validation guard now requires the refreshed pass760 title and key matrix rows.

This pass is documentation and validation-guard consolidation only. It does not add new Ada grammar recognition, compiler invocation, LSP integration, rendering-side parsing, file save/reload mutation, dirty-state mutation, or compiler-grade legality checking.
