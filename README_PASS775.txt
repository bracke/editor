# Editor Phase 579 pass775 — renaming aspect placement depth

Pass775 adds renaming-specific aspect-placement metadata to the editor-owned Ada token cursor. Object, package, and subprogram renaming declarations that carry a trailing `with ...` aspect specification now retain `Production_Renaming_Aspect_Specification` before the ordinary aspect associations are parsed.

Examples covered structurally:

```ada
Alias : Integer renames Source with Volatile;
package Inner_Alias renames Inner with Preelaborate;
procedure Run_Alias renames Inner.Run with Inline;
function Image (Value : Integer) return String
  renames Integer'Image with Post => Image'Result'Length > 0;
```

Regression coverage:

* `Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement_Pass775`

Validation/release guards were updated so the production, regression, and coverage-matrix note remain present.

This improves structural grammar coverage for Ada renaming-declaration aspect placement. It is not compiler-grade renaming legality checking, renamed-entity resolution, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
