Editor Phase 579 IDE-grade Outline/Semantic Language Model - Pass 392

This pass extends executable expression/name binding with bounded quantified-expression metadata.

Changes:
- Added Binding_Quantified_Parameter and Binding_Quantified_Source to Editor.Ada_Language_Model.
- Editor.Ada_Declaration_Parser now retains quantified-expression parameters from forms such as:
    for all I in Items'Range => ...
    for some Item of Items => ...
- Quantified domains are retained as source bindings when a leading domain name can be identified.
- The extraction is parser-owned and bounded; unresolved domains keep No_Symbol instead of being guessed.
- Semantic colouring can treat quantified parameters as value-like local bindings where safe.
- Added regression coverage in Test_Language_Model_Executable_Quantified_Expression_Bindings.

Still conservative:
- No GNAT-equivalent quantified-expression legality checking.
- No full expression AST or quantified-domain type evaluation.
- Unknown domain expressions degrade without guessed targets.
