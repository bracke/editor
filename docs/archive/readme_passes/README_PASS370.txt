Editor pass370

Focus: ambiguity-aware IDE navigation UX completeness.

Implemented:
- Added pure, deterministic navigation candidate formatter APIs to Editor.Ada_Project_Index:
  * Navigation_Candidate_Display_Label
  * Navigation_Candidate_Detail_Label
- Display labels include validated path, line, column, symbol kind, name, and profile.
- Detail labels retain body/generic/rename/instantiation/separate flags and target metadata where present.
- Formatters do not open files, scan the filesystem, mutate buffers, or guess a target.
- Unique navigation remains conservative; chooser-style UI can present candidates returned by pass369 APIs.

Regression coverage:
- Test_Project_Index_Navigation_Candidate_Labels_Are_Presentable

No Python, shell scripts, .pyc files, parser generators, rendering-side parsing, external compiler integration, or LSP integration were added.
