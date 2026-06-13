Pass 400 — executable accept-parameter binding

This pass extends the Ada language model's executable-statement binding coverage with accept statement formal parameters.

Implemented:
- Added Binding_Accept_Parameter to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now retains accept statement formals such as:

     accept Start (Value : in Integer; Flag, Other : Boolean) do

- Multiple names in one formal part are split and retained individually.
- Accept entry targets remain Binding_Accept_Entry; accept formals are separate local executable/value-like bindings.
- Added regression coverage by extending the executable transfer/tasking target test.

Still conservative:
- No GNAT-equivalent tasking legality checking.
- No full accept-body scope construction.
- Unknown accept formals degrade without guessed target symbols.

No Python, shell scripts, parser generators, rendering-side parsing, external compiler integration, or LSP integration were added to the project.
