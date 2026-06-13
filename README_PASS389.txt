Pass 389 — executable entry barrier bindings

This pass extends the Phase 579 Ada language-model executable binding layer with bounded protected-entry barrier metadata.

Changes:
- Added Binding_Entry_Barrier to Editor.Ada_Language_Model.Executable_Binding_Kind.
- Extended Editor.Ada_Declaration_Parser executable binding extraction to retain protected entry barrier expression names such as:

      entry Start when Ready is

  and expression-led barriers such as:

      entry Stop when not Ready is

- Entry barrier names are retained as parser-owned executable metadata, distinct from select guards, case choices, exception choices, and entry declarations.
- Added Test_Language_Model_Executable_Entry_Barrier_Bindings.
- Updated documentation and release/static guard notes.

Conservative behavior:
- No GNAT-equivalent protected-entry legality checking.
- Only the leading barrier expression name is retained.
- Unknown or unresolved barrier names degrade through No_Symbol instead of being guessed.
- No rendering-side parsing, external compiler/LSP integration, Python, shell scripts, or parser generators were added.
