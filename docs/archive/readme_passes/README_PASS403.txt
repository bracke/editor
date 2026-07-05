Pass 403 — executable asynchronous select abort metadata

Implemented one more executable expression/name binding completeness pass.

Changes:
- Added Binding_Select_Abort to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now retains asynchronous select abort alternatives:
  select Entry_Call;
  then abort
     ...
  end select;
- `then abort` is retained as select-structure executable metadata, distinct from select guards, entry-call alternatives, delay alternatives, terminate alternatives, and fallback call bindings.
- Extended Test_Language_Model_Executable_Select_Bindings to assert retained select-abort metadata.

Still conservative:
- No GNAT-equivalent asynchronous-select legality checking.
- No tasking control-flow model.
- Select-abort metadata carries no guessed target symbol.
