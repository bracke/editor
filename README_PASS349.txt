Editor phase579 IDE-grade Outline/Semantic Language Model pass349

This pass hardens syntax-tree metadata projection for selected-name targets.

Implemented:
- Added bounded selected-name target matching to Editor.Ada_Declaration_Parser.Project_Syntax_Tree_Into_Model.
- Representation/metadata clauses such as `for Inner.Rec use record ...` can now mark the nested `Rec` symbol through retained parent ownership metadata.
- Kept selected metadata target matching conservative: exact selected names and parent-chain suffixes are accepted, but dotted targets do not degrade to leaf-only matching.
- Added regression coverage for a nested package record whose representation clause uses a relative selected name.

Validation hygiene:
- No Python, shell, pyc, or parser-generator tooling was added to the project.
