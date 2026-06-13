Pass384: executable delay/abort binding completeness

This pass extends the parser-owned executable binding metadata added in the
previous passes with delay and abort statement targets.

Implemented:
- Added Binding_Delay_Target and Binding_Abort_Target to
  Editor.Ada_Language_Model.Executable_Binding_Kind.
- Editor.Ada_Declaration_Parser now retains:
  * delay until expression targets, such as `delay until Next_Time;`
  * relative delay expression targets, such as `delay Period;`
  * each target in abort statements, such as `abort A, B;`
- The extraction remains bounded and conservative.  It records syntactic
  targets and optional local symbol matches, but it does not perform tasking,
  timing, or legality analysis.
- Added regression test:
  Test_Language_Model_Executable_Delay_And_Abort_Bindings

No Python, shell scripts, parser generators, rendering-side parsing, external
compiler integration, or LSP integration were added.
