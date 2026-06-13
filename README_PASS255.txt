Editor phase 579 pass 255

This pass expands parser-owned Ada statement awareness for executable
alternative actions.  The parser now recognizes simple control/tasking
actions after alternative arrows as bounded language-model metadata:

* Statement_Alternative_Exit
* Statement_Alternative_Goto
* Statement_Alternative_Delay
* Statement_Alternative_Requeue
* Statement_Alternative_Abort

Base statement metadata is also retained where appropriate, including
conditional exit, delay-until, and requeue-with-abort refinements.  The
new metadata is fingerprinted but does not create Outline rows, semantic
symbols, scopes, or navigation targets.

Record variant alternatives remain excluded from executable-statement
metadata.
