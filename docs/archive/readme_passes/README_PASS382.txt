pass382 — executable block/exit binding completeness

This pass extends parser-owned executable semantic binding metadata with two
bounded control-flow/navigation cases:

* Binding_Block_Label for named loops and blocks such as Main_Loop : loop and
  Helper : declare.
* Binding_Exit_Target for exit statements such as exit Main_Loop when Done;

The new extraction is conservative: it is only applied to prefix-label forms
whose tail begins with loop/declare/begin/for/while, so ordinary declarations,
assignments, and representation clauses are not treated as block labels.  Exit
statements without a name, for example exit when Done;, do not produce a target
binding.

Regression coverage:

* Test_Language_Model_Executable_Block_And_Exit_Targets

No Python, shell scripts, .pyc files, parser generators, rendering-side parsing,
external compiler integration, or LSP integration were added.
