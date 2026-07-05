pass 396

This pass extends bounded executable expression/name binding with raise-expression targets.

Changes:
- Added Binding_Raise_Expression_Target to Editor.Ada_Language_Model.
- Added parser-owned detection of embedded Ada raise expressions such as:
    X := (if Ready then Count else raise E);
    Ready := Check (raise E);
- Statement-level raise targets remain Binding_Raise_Target.
- Semantic-colouring consumers may treat retained raise-expression targets as value-like metadata where safe.
- Added Test_Language_Model_Executable_Raise_Expression_Bindings.
- Updated README/docs/release guard comments.

Still conservative:
- No GNAT-equivalent raise-expression legality checking.
- No full expression AST construction.
- Unknown targets degrade through No_Symbol instead of being guessed.
