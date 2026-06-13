Pass 405 — token-cursor Ada name/statement grammar completeness

Implemented another parser-completeness pass focused on Ada statement target/name grammar rather than UI, rendering, or build-runner code.

Changes:
- Extended Editor.Ada_Token_Cursor with Production_Slice and Production_Explicit_Dereference.
- Statement parsing now consumes the full Ada name prefix before deciding whether a construct is an object declaration, assignment statement, or call statement.
- Selected, indexed, sliced, attribute-bearing, and explicit-dereference statement targets such as Obj.Field := X, Arr (I) := X, Arr (A .. B) := X, Ptr.all := X, and Pkg.Op (...) are now represented structurally instead of being flattened into generic calls.
- Association-list parsing now consumes range/slice suffixes so slice forms do not leave the cursor stranded before the assignment operator.
- Added AUnit coverage for selected-name, indexed-component, slice, explicit-dereference, assignment, and selected-call grammar productions.
- Extended the phase language validation guard so the new token-cursor name-target grammar cannot silently regress.

Still conservative:
- This improves syntactic Ada grammar coverage for editor analysis; it is not a GNAT-equivalent legality checker.
- The parser distinguishes syntactic statement/name forms but does not evaluate target assignability, overload legality, accessibility, or subtype constraints.
