Editor Phase 579 pass776 — generic formal type edge-depth pass

Implemented bounded structural grammar-depth improvements for generic formal type definitions:

* Added Production_Formal_Scalar_Box_Recovery_Boundary.
* Added Production_Formal_Derived_Interface_List.
* Added Production_Formal_Interface_Ancestor_List.
* Malformed formal scalar definitions such as `type Count is range ;`, `type Mask is mod with Atomic;`, `type Real is digits ;`, and `type Rate is delta with Volatile;` now expose a formal-scalar recovery boundary without consuming the semicolon or aspect introducer.
* Formal derived/interface ancestor chains now retain family-specific metadata in addition to existing per-ancestor subtype metadata.
* Added AUnit regression Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth_Pass776.
* Updated validation/release guards and parser coverage documentation.

This improves structural grammar coverage for Ada generic formal type definitions. It is not compiler-grade generic contract conformance, formal type matching, private-extension legality checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
