Pass 357 — defaulted-formal overload filtering

Implemented another overload-resolution completeness pass.

Changes:
- Extended Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope profile matching.
- Formal parameters now retain a local Has_Default bit while matching call shapes.
- Omitted trailing formals are accepted only when they have default expressions.
- Named actual associations may skip earlier/later formals only when the skipped formals have defaults.
- Required unmatched formals reject the candidate instead of being treated as optional.
- Ambiguous matches are still preserved; the resolver does not guess.

Added regression coverage:
- Test_Resolver_Call_Overload_Resolution_Uses_Defaulted_Formals

Still conservative:
- Does not evaluate default expressions.
- Does not infer actual expression types.
- Does not implement GNAT-equivalent overload legality, universal numeric rules, dispatching, or generic contract resolution.

No Python, shell scripts, .pyc files, or parser-generator tooling were added.
