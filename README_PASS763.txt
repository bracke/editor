# Editor Phase 579 Pass763

Pass763 deepens body-stub aspect placement grammar in the token-cursor Ada parser.

## Changed

* Subprogram body stubs now parse trailing aspect specifications through `Production_Body_Stub_Aspect_Specification`.
* Entry body stubs now retain the same body-stub-specific aspect placement metadata after `is separate`.
* Ordinary entry declaration/body aspect placement remains routed through `Production_Entry_Aspect_Specification`.
* Added AUnit regression `Test_Language_Model_Token_Cursor_Body_Stub_Aspect_Placement_Depth` covering procedure/function body stubs and entry body stubs with aspects.
* Updated the parser coverage matrix, release checklist, validation guard, and README.

## Non-goals

This improves structural grammar coverage for body-stub aspect placement. It is not compiler-grade body-stub legality checking, subunit conformance checking, contract legality checking, tasking semantics, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
