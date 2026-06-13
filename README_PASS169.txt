Phase 579 IDE-grade language command surface pass 169

Implemented canonical command-surface item nr 1 from the missing list.

Changes:
- Added registered command ids for:
  - outline.refresh-project-index
  - outline.goto-declaration
  - outline.goto-body
  - outline.goto-spec
  - semantic.refresh-buffer
  - semantic.refresh-project-index
  - language.index.clear
  - language.index.status
- Added command descriptors, stable-name mapping, command-kind routing, availability checks, and executor cases.
- Added transient Editor.State.Language_Index using Editor.Ada_Project_Index.Index_State.
- Implemented active-buffer project-index refresh using Editor.Ada_Declaration_Parser.Parse and Editor.Ada_Project_Index.Put_Analysis.
- Implemented semantic.refresh-buffer and semantic.refresh-project-index using parser-owned Ada language-model analysis and Editor.Syntax_Semantics.Build_Map_From_Analysis.
- Implemented language.index.clear and language.index.status over the transient in-memory index.
- Implemented outline.goto-declaration by reusing the existing validated selected Outline row declaration-navigation path.
- Added command-surface tests for the canonical language command names and descriptors.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and release guards.

Notes:
- outline.goto-body and outline.goto-spec are registered canonical commands with deterministic availability and executor behavior, but remain unavailable until body/spec pair metadata is implemented.
- No Python or shell scripts were added.
- GNAT/gprbuild is not available in this environment, so build/AUnit verification was not run here.
