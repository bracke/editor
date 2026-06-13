Editor phase579 IDE-grade outline/semantic language-model pass330

This pass extends grammar-aware syntax-tree recovery for malformed subprogram and concurrent declaration headers.

Changes:
- subprogram declarations without semicolons retain subprogram declaration nodes and receive expected ';' recovery metadata;
- subprogram-shaped headers that already contain handled-sequence/body text but omit 'is' receive expected 'is' recovery metadata;
- task/protected declarations without semicolons retain their concurrent declaration node kinds and receive expected ';' recovery metadata;
- task/protected/body-stub headers that omit 'is' receive expected 'is' recovery metadata;
- added AUnit coverage for malformed subprogram, task, and protected declaration recovery;
- extended phase579 language validation guards;
- updated documentation to mention declaration-header recovery.

No Python, shell scripts, or parser-generator tooling were added.
