Pass 388 — executable select terminate binding

- Added Binding_Select_Terminate to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now retains select terminate alternatives, including split `or` / `terminate;` forms.
- Select terminate alternatives are distinct from select guards, select entry calls, and select delay targets.
- Extended Test_Language_Model_Executable_Select_Bindings to cover terminate alternatives.
- No Python, shell scripts, parser generators, rendering-side parsing, external compiler integration, or LSP integration were added.
