Editor pass954 — expected-call result-subtype filtering

Implemented:
- Added Editor.Ada_Expected_Call_Filters.
- Applied expected-subtype context metadata to unique-profile call-resolution results.
- Classified call result subtypes as matching or mismatching the expected subtype context.
- Preserved context-free and unresolved calls as deterministic staging metadata for later diagnostics.
- Added AUnit regression Test_Ada_Expected_Call_Filter_Foundation_Pass954.
- Updated README, parser coverage notes, release guards, and validation notes.

Scope:
This is a compiler-grade overload-resolution building block for expected-type filtering. It does not yet complete derived-type compatibility, class-wide compatibility, implicit conversions, universal numeric resolution, full profile conformance, generic contracts, freezing/representation legality, or cross-unit semantic closure.
