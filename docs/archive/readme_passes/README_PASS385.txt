Pass385: executable condition and iteration-source binding completeness

This pass extends parser-owned executable binding metadata with simple
condition/selector names and for-loop iteration sources.

Implemented:
- Added Binding_Condition_Target and Binding_Iteration_Source to
  Editor.Ada_Language_Model.Executable_Binding_Kind.
- Editor.Ada_Declaration_Parser now retains:
  * if-condition leading targets, such as `if Ready then`
  * elsif-condition leading targets, such as `elsif Done then`
  * while-condition leading targets, such as `while Ready loop`
  * case selector leading targets, such as `case State is`
  * for-loop iteration sources, such as `for Item of Items loop`
- Loop parameters remain distinct Binding_Loop_Parameter entries.
- The extraction remains bounded and conservative. It records syntactic
  leading names and optional local symbol matches, but it does not perform full
  expression legality checking or compiler-equivalent condition typing.
- Added regression test:
  Test_Language_Model_Executable_Condition_And_Iteration_Bindings

No Python, shell scripts, parser generators, rendering-side parsing, external
compiler integration, or LSP integration were added.
