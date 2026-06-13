Editor Phase 579 IDE-grade outline/semantic language model - pass381

This pass continues the bounded executable expression/name binding work from
pass380.

Implemented:
- Added executable binding kinds for transfer/tasking executable targets:
  * Binding_Raise_Target
  * Binding_Requeue_Target
  * Binding_Accept_Entry
- Parser-owned executable binding extraction now retains:
  * raise exception targets, e.g. raise E;
  * requeue entry targets, e.g. requeue Start;
  * accept entry targets, e.g. accept Start;
- These bindings preserve source spelling, normalized lookup metadata, source
  range, lexical scope, expression text, and optional local target symbol.
- Added regression coverage:
  * Test_Language_Model_Executable_Transfer_And_Tasking_Targets

Conservative boundaries:
- No GNAT-equivalent tasking/exception legality checking.
- Requeue/accept targets are retained syntactically and resolve locally only
  when the indexed model has a safe target symbol.
- Unknown targets still degrade through No_Symbol rather than being guessed.
- No rendering-side parsing, external compiler/LSP integration, Python, shell
  scripts, or parser generators were added.
