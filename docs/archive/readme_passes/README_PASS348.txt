Editor  IDE-grade Outline/Semantic Language Model pass348

This pass connects the expanded parser-owned Ada syntax tree back into the
semantic language model.

Implemented:
- Added Editor.Ada_Language_Model.Merge_Symbol_Flags so parser-derived metadata
  can be merged into existing symbols without duplicating declarations.
- Added Editor.Ada_Declaration_Parser.Project_Syntax_Tree_Into_Model.
- Projected structured syntax-tree declaration nodes into language-model symbols
  when the compatibility line parser did not already create them.
- Merged syntax-tree metadata into existing symbols for aspects, pragmas,
  representation clauses, generic actual parts, variant parts, body stubs,
  incomplete/private-extension declarations, task/protected type declarations,
  named numbers, deferred constants, null procedures, expression functions,
  renames, instantiations, and separate bodies.
- Projected variant record components and enumeration/discriminant/component
  syntax nodes into semantic symbols while preserving bounded duplicate checks.
- Added regression coverage ensuring syntax-tree representation clauses mark
  their target record, variant components become record-component symbols, and
  generic actual parts mark instantiation symbols.

Validation hygiene:
- Extended  language validation guards.
- Updated README and language-feature documentation.
- No Python, shell, pyc, or parser-generator tooling was added.
