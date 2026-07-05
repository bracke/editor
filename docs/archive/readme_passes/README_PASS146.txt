IDE-grade outline/semantic language-model pass 146

Implemented change:
- Hardened Editor.Ada_Symbol_Resolver.Resolve_In_Scope so invalid lexical scope ids do not silently fall back to the root scope.
- Added Test_Resolver_Invalid_Scope_Does_Not_Fall_Back_To_Root.
- Updated outline and syntax-colouring documentation with the pass 146 language-analysis note.
- Extended tools/release_check.adb guards for the resolver source change, regression test, and docs.

Rationale:
Stale or impossible scope stamps must degrade to no symbol. Falling back to root declarations could create false outline navigation targets or false semantic colouring when a caller holds an invalid scope id.

Validation note:
The Ada build/AUnit suite was not executed in this environment because GNAT/gprbuild is unavailable here.
