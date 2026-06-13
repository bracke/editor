Pass538: freezing-rule interaction tightening.

Implemented in this pass:
- Replaced freezing target substring matching with identifier-boundary matching so short type names do not falsely match unrelated identifiers such as Integer.
- Added a retained Freezing_Generic_Formal_Use freezing-point kind for generic formal object/subprogram/package declarations that mention an existing representation target.
- Late representation diagnostics now report generic-formal freezing points before following representation clauses.
- Added regression coverage for:
  * legal representation clauses after unrelated Integer declarations when the target is named T;
  * generic formal declarations freezing a referenced target before a later representation clause;
  * retained freezing-point kind exposure for generic formal triggers.

Scope note: this remains a bounded IDE-grade retained semantic model; it does not attempt full RM 13.14 elaboration/freezing proof construction.
