Pass 316 — Ada declaration grammar expansion

This pass broadens the parser-owned Ada syntax tree so declaration syntax is no
longer limited to the earlier package/subprogram/type/object subset.  The tree
now has first-class node kinds for the remaining Ada declaration families and
structured child metadata for declaration names, subtypes/definitions, defaults,
and modes.

Implemented in this pass:
- generic formal object/type/subprogram/package declarations;
- incomplete types and private extensions;
- named-number declarations and deferred constants through structured declaration children;
- task/protected declarations and bodies;
- entry declarations;
- record component declarations and discriminant specifications;
- private parts and body stubs;
- declaration-name/subtype/default/mode child nodes shared by declaration forms.

The implementation remains deterministic, snapshot-owned, and parser-internal;
it does not introduce rendering-side parsing, Python, shell scripts, parser
generators, or compiler/LSP dependencies.
