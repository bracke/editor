Editor Phase 579 - IDE-grade Outline / Semantic Colouring / Ada Parser
Pass943 - Declarative-region model foundation

Base snapshot: editor_phase579_ide_grade_outline_semantic_language_model_pass942.zip
Output snapshot: editor_phase579_ide_grade_outline_semantic_language_model_pass943.zip

Implemented in this pass:

* Added Editor.Ada_Declarative_Regions as a parser-owned compiler-grade semantic foundation.
* The region model is built from Editor.Ada_Syntax_Tree.Tree_Type and stores:
  - stable Region_Id values,
  - Region_Kind classification,
  - owner syntax-tree node IDs,
  - parent region IDs,
  - nesting depth,
  - source line range,
  - labels,
  - deterministic fingerprints.
* Region families currently covered:
  - compilation units,
  - generic formal parts,
  - package specs and bodies,
  - subprogram specs and bodies,
  - task specs and bodies,
  - protected specs and bodies,
  - entry bodies,
  - record definitions,
  - block regions.
* Added AUnit regression:
  - Test_Ada_Declarative_Region_Model_Foundation_Pass943
* Updated parser coverage docs, syntax-colouring notes, release checklist, and README.

Scope:

This is a compiler-grade semantic building block for later direct visibility, use-clause visibility, name resolution, overload resolution, and legality diagnostics. It does not yet perform compiler-grade lookup, overload resolution, type checking, static evaluation, generic contract checking, freezing, representation legality, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
