Editor Phase 579 IDE-grade outline/semantic language-model pass380

This pass continues the executable expression/name binding work from pass379.

Implemented:
- Added Binding_Attribute_Prefix to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now retains Ada attribute prefixes
  such as Obj'Length, X'Size, and T'Image (...).
- Qualified expressions such as T'(...) remain Binding_Qualified_Expression_Target
  and are not confused with attribute prefixes.
- Attribute-prefix bindings retain source spelling, normalized lookup metadata,
  source range, lexical scope, expression text, and an optional resolved target
  symbol where the existing language model can resolve the prefix.
- Added regression coverage:
  Test_Language_Model_Executable_Attribute_Prefix_Bindings

Conservative behavior retained:
- No GNAT-equivalent attribute legality or result-type evaluation.
- Unknown prefixes degrade to ordinary identifiers.
- No rendering-side parsing, external compiler integration, LSP integration,
  Python, shell scripts, or parser generators were added.
