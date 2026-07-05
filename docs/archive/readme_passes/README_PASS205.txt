Editor pass 205

Parser-completeness pass: entity pragmas are now retained as bounded declaration metadata.

Changes:
- Added Has_Pragma_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Added Mark_Symbol_Pragma_Metadata and included the flag in deterministic fingerprints.
- Added bounded pragma target binding in Editor.Ada_Declaration_Parser for common entity pragmas such as Import, Export, Convention, Inline, Atomic, and related forms.
- Pragmas remain metadata only: they do not create Outline rows, open scopes, or add pragma names/arguments as symbols.
- Outline details can show pragma metadata for represented declarations.
- Added AUnit regression coverage for pragma metadata and non-pollution of symbol lookup.
- Extended language_validation_check and documentation.

No Python or shell scripts were added.
