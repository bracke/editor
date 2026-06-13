Editor Phase 579 pass397

This pass extends executable expression/name binding with bounded Ada 2022 delta aggregate metadata.

Implemented changes:
- Added Binding_Delta_Aggregate_Base to Editor.Ada_Language_Model.
- Added Binding_Delta_Aggregate_Component to Editor.Ada_Language_Model.
- Parser-owned executable expression scanning now retains delta aggregate bases and top-level component associations from forms such as:

    Next := (Current with delta Count => Value, Ready => Flag);

- The scanner records the aggregate base expression name (Current) rather than the assignment target (Next) when the whole assignment line is scanned.
- Delta aggregate component associations remain distinct from ordinary aggregate component associations and named call actuals.
- Semantic colouring can consume delta aggregate base/component metadata where safe.
- Added regression test:
  Test_Language_Model_Executable_Delta_Aggregate_Bindings

Conservative boundaries:
- No GNAT-equivalent delta aggregate legality checking.
- No full record-type-driven component resolution.
- Only top-level delta component associations are retained; nested expressions are handled by the existing bounded scanners.
- Unknown or unresolved names still degrade without guessed targets.
