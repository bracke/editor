Editor Phase 579 IDE-grade outline/semantic language model - pass386

This pass extends executable expression/name binding for Ada select statements.

Changes:
- Added Binding_Select_Guard to Editor.Ada_Language_Model.
- Added Binding_Select_Entry_Call to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now distinguishes select guards from
  ordinary case alternatives and exception-handler choices.
- `when Guard =>` inside a select statement is retained as Binding_Select_Guard.
- `select Entry_Call;` and `or Entry_Call;` are retained as
  Binding_Select_Entry_Call.
- Standalone call fallback now excludes select/or/then keyword-led lines so
  keywords are not treated as callable names.
- Added regression coverage:
  Test_Language_Model_Executable_Select_Bindings.

Still conservative:
- No GNAT-equivalent select-statement legality checking.
- No full tasking semantic model.
- Unknown select guards or entry calls degrade through No_Symbol instead of
  being guessed.
- No rendering-side parsing, external compiler/LSP integration, Python, shell
  scripts, .pyc files, or parser generators were added.
