Phase 579 pass 318 — declaration grammar completeness pass

This pass extends the parser-owned Ada syntax tree beyond the pass317 subprogram refinements by adding first-class structure for declaration families that still degraded to generic declaration/statement shapes:

* enumeration literal declarations inside enumeration type declarations;
* record variant parts and variants inside record declarations;
* entry bodies and entry body stubs;
* renaming declaration targets for object/exception-style renames.

The new nodes remain syntax-tree metadata owned by the Ada language analysis layer. They do not create rendering-side parsing, file reloads, Outline statement rows, semantic declaration symbols from executable code, or compiler-grade legality analysis.
