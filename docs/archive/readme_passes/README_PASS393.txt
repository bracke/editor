Editor pass393

Executable expression/name binding completeness pass.

Changes:
- Added Binding_Named_Actual to Editor.Ada_Language_Model.
- Parser-owned executable expression scanning now retains top-level named actual associations from call argument lists, e.g. Sink (Value => Count, Flag => Ready).
- Named actual metadata is distinct from Binding_Aggregate_Component so call parameter associations are not conflated with aggregate component associations.
- Named actual extraction is bounded to top-level associations in the current call argument list; nested calls/aggregates remain handled by their own scans.
- Semantic colouring can treat named actual names as parameter-like local metadata where safe.
- Added Test_Language_Model_Executable_Named_Actual_Bindings.

Still conservative:
- No GNAT-equivalent parameter association legality checking.
- No full expression AST for every actual expression.
- Unknown named actuals degrade without guessed target symbols.
