# Editor pass771

Pass771 tightens semantic-colouring projection for parser-owned Ada metadata. `Editor.Syntax_Semantics.Build_Map_From_Analysis` now treats newer metadata-only names from visibility clauses, generic formal type details, profile parameters, pragma metadata, representation metadata, and unresolved executable bindings as conservative fallback classifications. These fallback classifications are only inserted when the bounded semantic map does not already contain a concrete parser-owned symbol for the same Ada name.

This prevents metadata-only roles such as pragma targets, profile-parameter metadata, use-clause metadata, and unresolved assignment/call bindings from downgrading a concrete declaration that was already retained in the language-model symbol table. For example, a concrete function named `Ready` remains callable-coloured even if later metadata also mentions `Ready` as a pragma target, profile parameter, or unresolved assignment target.

AUnit coverage was added with `Test_Syntax_Semantics_Metadata_Does_Not_Downgrade_Symbols_Pass771`.

This improves semantic-colouring projection precision for newer Ada parser/model metadata. It is not compiler-grade name resolution, overload resolution, visibility checking, metadata legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
