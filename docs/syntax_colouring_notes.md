### Pass956 — Type graph metadata

Pass956 adds `Editor.Ada_Type_Graph`, allowing future semantic-colouring and diagnostics to distinguish declaration-derived type roots, derived types, subtypes, formal types, and unresolved parent subtype relationships. The model remains conservative and snapshot-owned, preserving the existing no-renderer-parsing and no-dirty-state-mutation invariants.

### Pass955 — Subtype compatibility metadata

Pass955 adds subtype-compatibility metadata for expected-call filtering. The semantic-colouring pipeline can keep using conservative symbol classes, while diagnostics and future colour refinements can distinguish exact subtype matches, universal-numeric compatibility, known numeric-family mismatches, and indeterminate user-defined relationships without invoking a compiler or reparsing in the renderer.

### Pass958 semantic metadata

The Ada semantic pipeline now exposes type-graph metadata for private/full-view links, interface declarations, and class-wide expected-call compatibility. Semantic-colouring consumers should treat these as analysis metadata only; they must not trigger rendering-side parsing or mutate buffer dirty state.

### Pass959 semantic metadata

Expected-call semantic metadata now includes implicit-conversion classification. Colouring and diagnostics can distinguish subtype/class-wide/universal-numeric compatibility from derived-type ancestry that requires an explicit Ada conversion, while still avoiding renderer-side parsing or dirty-state mutation.

### Pass960 semantic metadata

Pass960 adds static-expression metadata through `Editor.Ada_Static_Expressions`. Syntax colouring may use the model conservatively to distinguish named-number/static-constant bindings that have resolved static integer values from unresolved or non-static expressions. The metadata remains snapshot-owned and must not trigger renderer-side parsing or buffer mutation.


### Pass961 semantic metadata

Pass961 adds static subtype-bound and attribute metadata. Syntax colouring may surface resolved scalar subtype attributes conservatively, but it must continue to consume only snapshot-owned semantic data and must not perform renderer-side parsing, file reloads, project scans, or dirty-state mutation.

Pass962 extends static-expression metadata with enumeration literal position records. Syntax colouring may use the snapshot-owned metadata conservatively to distinguish enumeration literal static operands used by `T'Pos` / `T'Val`, but it must not perform renderer-side parsing, compiler invocation, LSP queries, file mutation, or dirty-state mutation.

Pass963 extends static-expression metadata with modular type modulus records and reduced modular integer values. Syntax colouring may use the snapshot-owned metadata conservatively for modular-type declarations and static modular constants, but it must not perform renderer-side parsing, compiler invocation, LSP queries, file mutation, or dirty-state mutation.

Pass964 extends static-expression metadata with real/universal numeric values. Syntax colouring may use snapshot-owned `Static_Value_Real` metadata conservatively for static named numbers/constants and diagnostics-facing overlays, but it must not perform renderer-side parsing, compiler invocation, LSP queries, file mutation, background scans, or dirty-state mutation.

Pass965 extends static-expression metadata with fixed-point type/delta/range information. Syntax colouring may use the snapshot-owned fixed-point statuses only as conservative semantic metadata; renderer-side parsing, compiler invocation, LSP queries, file mutation, background scans, and dirty-state mutation remain forbidden.

Pass966 adds generic contract metadata. Syntax colouring may use snapshot-owned formal-kind and instantiation-actual-shape metadata conservatively for diagnostics-facing overlays, but it must not perform renderer-side parsing, compiler invocation, LSP queries, file mutation, background scans, or dirty-state mutation.
Pass967 adds generic formal/actual matching metadata. Syntax colouring may consume the staged `Generic_Actual_Match_Status` only as snapshot-owned semantic data and must not trigger renderer-side parsing, compiler invocation, LSP queries, file mutation, background scans, or dirty-state mutation.

### Pass968 - generic formal/actual kind conformance metadata

Pass968 keeps generic formal/actual kind conformance in `Editor.Ada_Generic_Contracts`, not in rendering code. Semantic-colouring clients may use the new actual-kind metadata to distinguish generic instantiation actual-shape diagnostics from ordinary unresolved names, but they must treat it as snapshot-owned semantic metadata and must not reparse source text or mutate buffer state.


### Pass969 - generic formal subprogram profile conformance

Pass969 extends `Editor.Ada_Generic_Contracts` with formal subprogram profile conformance metadata. Generic formal subprograms now retain parameter-count, normalized parameter-subtype shape, result presence, and result-subtype metadata. Generic instantiation actuals retain positional/named actual designator text, allowing declaration-shaped subprogram actuals to be resolved through direct visibility and compared against the formal profile. The match model now distinguishes formal-kind mismatches from formal subprogram profile mismatches and records deterministic compatible/mismatched/unknown profile counts. Regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`. This is a compiler-grade generic-contract building block; full Ada generic conformance still requires overload-aware subprogram actual selection, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass970 - generic formal package contract conformance

Pass970 extends `Editor.Ada_Generic_Contracts` with formal package contract conformance metadata. Generic formal package records now retain their expected target generic name, normalized target, and box actual-state marker. Generic instantiation matching resolves package actuals through direct visibility, recognizes inline `new Generic (...)` package actuals, verifies that declaration-shaped package actuals are package instantiations, and compares the actual package instance target generic against the formal package contract. The match model now distinguishes formal package contract mismatches and unknown formal package contract cases, including unresolved actuals, ambiguous actuals, non-instance package actuals, wrong-generic package instances, unknown formal contracts, and malformed package actuals, with deterministic compatible/mismatched/unknown counters exposed through `Formal_Package_Compatible_Count_For_Instance`, `Formal_Package_Mismatch_Count_For_Instance`, and `Formal_Package_Unknown_Count_For_Instance`. Regression coverage is in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`. This pass adds one compiler-grade generic-contract building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, and cross-unit semantic closure are fully integrated.

## Phase 579 pass971

Generic body contract visibility is now modelled in the parser-owned semantic layer.  Semantic-colouring consumers can distinguish generic formal contract symbols that are visible inside a matching generic body without reparsing from rendering code or mutating editor state.

## Phase 579 pass972

The generic-contract layer now distinguishes overloaded subprogram actual selection from ordinary name ambiguity.  Semantic colouring remains a consumer only; the new metadata is generated by `Editor.Ada_Generic_Contracts` from the snapshot-owned syntax tree, regions, and direct-visibility model.

## Phase 579 pass973 — Generic default-expression legality metadata

The semantic-colouring path remains projection-only.  Pass973 adds generic-contract metadata for static-aware object formal defaults and explicit object actual expressions, but it does not move parsing or legality checking into rendering.  Future diagnostic/colour consumers can read the checked/static/illegal/unknown counters from `Editor.Ada_Generic_Contracts` after the snapshot-owned analysis pipeline has built the static-expression model.
\nPass974: Generic-contract analysis now retains formal subprogram parameter mode vectors and classifies declaration-shaped subprogram actuals with same arity/subtypes but nonconforming modes as deterministic mode mismatches. Regression coverage: Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974.

### Phase 579 pass975

Generic semantic-colouring metadata now has a stricter type-graph-aware profile-conformance source. The syntax-colouring layer remains projection-only; it consumes the language model and does not perform rendering-side parsing or mutate buffers.


Pass976 adds a compiler-grade generic profile-conformance building block for formal subprogram null-exclusion and anonymous access-to-subprogram profile matching. Generic actual matching now records and reports null-exclusion mismatches and access-profile mismatches separately from generic profile mismatches, with deterministic counters and regression coverage in Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976. Full compiler-grade Ada analysis remains incomplete until private-view rules, freezing, representation legality, cross-unit closure, and full expression type inference are fully integrated.

### Phase 579 pass976

Generic-contract semantic metadata now contains separate null-exclusion and access-profile mismatch classifications for formal subprogram actuals. Semantic colouring remains projection-only and does not parse or mutate editor state.


Pass977: generic formal subprogram Convention conformance metadata is available for diagnostics/colouring overlays without rendering-side parsing.

Pass978: generic-contract semantic metadata now separates defaulted-parameter profile mismatches for formal subprogram actuals. Semantic-colouring and diagnostics consumers may use `Generic_Actual_Match_Formal_Subprogram_Default_Mismatch` and the associated counter as snapshot-owned model data only; rendering-side parsing and buffer/workspace mutation remain prohibited.

Pass979: generic-contract semantic metadata now separates class-wide/profile-control mismatches for formal subprogram actuals. Semantic-colouring and diagnostics consumers may use `Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch` and `Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance` as snapshot-owned semantic metadata only; rendering-side parsing and buffer/workspace mutation remain prohibited.

Pass980: generic-contract semantic metadata now separates formal subprogram parameter-name mismatches from broad profile mismatches. Semantic-colouring and diagnostics consumers may use `Generic_Actual_Match_Formal_Subprogram_Name_Mismatch` and `Subprogram_Profile_Name_Mismatch_Count_For_Instance` as snapshot-owned semantic metadata only; rendering-side parsing and buffer/workspace mutation remain prohibited.

Pass981: generic-contract semantic metadata now separates formal subprogram function result-subtype mismatches from broad profile mismatches. Semantic-colouring and diagnostics consumers may use `Generic_Actual_Match_Formal_Subprogram_Result_Mismatch` and the result-subtype counters as snapshot-owned semantic metadata only; rendering-side parsing and buffer/workspace mutation remain prohibited.

Pass982: private-view semantic metadata is now staged in `Editor.Ada_Private_View_Visibility`. Semantic-colouring and diagnostics consumers may use the model to distinguish partial-only and full-view contexts, but rendering-side parsing and buffer/workspace mutation remain prohibited.

Pass983: subtype-compatibility semantic metadata can now be private-view aware. Consumers may distinguish partial-view compatibility, full-view compatibility, and hidden full-view cases from snapshot-owned model data only; rendering-side parsing and buffer/workspace mutation remain prohibited.

Pass984: freezing-point metadata is staged in `Editor.Ada_Freezing_Points`. Consumers may distinguish representation clauses before/after freezing using model data only; rendering-side parsing and editor-state mutation remain prohibited.


Pass985: added Editor.Ada_Representation_Legality as a compiler-grade representation-legality foundation. It combines parser-owned representation clauses with freezing-order checks, static-expression metadata, and type-graph target-kind checks, with AUnit coverage for static values, late clauses, and incompatible target kinds.
Pass986: representation-legality metadata now includes record representation component checks. Semantic consumers can distinguish valid layout component clauses from unresolved component names, duplicate clauses, non-static/negative positions, and reversed bit ranges without rendering-side parsing or dirty-state mutation.

### Pass987

Enumeration representation legality now exposes deterministic literal-association metadata. Syntax colouring and diagnostics can distinguish valid literal mappings from unresolved literals, duplicate literal associations, duplicate values, incomplete coverage, and non-static representation values without rendering-side parsing.

### Pass988
Address clause legality metadata now separates addressable targets from value-shape failures, allowing syntax/semantic colouring consumers to highlight invalid Address clauses from snapshot-owned analysis metadata only.

### Pass989

Size, Alignment, and Storage_Size legality metadata now separates target-shape failures from integer/static value failures. Syntax-colouring and diagnostics consumers may use these snapshot-owned statuses without rendering-side parsing or editor-state mutation.

Pass990 note: interfacing representation legality now has deterministic model coverage for Convention, Import, Export, External_Name, and Link_Name clauses, including target/value errors, Import/Export conflicts, and Link_Name/External_Name dependency errors.


### Pass991 — stream attribute representation legality

- `Editor.Ada_Representation_Legality` now recognizes Read, Write, Input, Output, and Put_Image representation clauses.
- Stream clauses stage subprogram-designator metadata, classify malformed values, and reject incompatible non-type/subtype targets.
- Profile-unknown stream designators are preserved explicitly for later callable-profile conformance.
- Regression: `Test_Ada_Stream_Attribute_Representation_Legality_Pass991`.

### Pass992 — stream attribute profile conformance

Stream attribute clauses now expose resolved profile-conformance metadata when callers use `Build_With_Stream_Profiles`. Syntax-colouring and diagnostics consumers may distinguish compatible stream subprogram designators from mismatched or unknown profiles using snapshot-owned representation-legality metadata only; rendering-side parsing and editor-state mutation remain prohibited.


Pass 993: operational representation attributes expose deterministic target/value statuses for downstream diagnostics and colouring hints without rendering-side parsing.


- Pass994: representation-property aspects now feed the same legality model as attribute-definition clauses, preserving source form for colouring/diagnostic projection without adding rendering-side parsing.

### Pass995 cross-unit closure notes

Cross-unit relationships are now available through `Editor.Ada_Cross_Unit_Closure`. Semantic-colouring and diagnostic consumers use snapshot-owned analysis data only; the closure model is a cross-file semantic context source, not a rendering-side parser or file reload mechanism.

### Pass996 note

Cross-unit semantic closure now includes context dependency links for ordinary `with`, `limited with`, `private with`, and context `use` package clauses. The dependency model is snapshot-owned, project-index-backed, deterministic, and preserves missing/ambiguous/overflow states for semantic consumers.

## Pass997 cross-unit spec/body consistency

Pass997 extends the cross-unit semantic-closure model with deterministic spec/body consistency metadata. The model now records confirmed package/subprogram spec/body pairs and missing, ambiguous, overflow, role-mismatch, and name-mismatch conditions with stable fingerprints. This is parser/index-owned semantic data and does not require rendering-side parsing, file reloads, dirty-state mutation, or compiler invocation.

Pass998: cross-unit closure now includes deterministic child-unit and private-child legality metadata. Child library units are classified as resolved public children, resolved private children, missing-parent children, ambiguous-parent children, overflowed children, or parent-role mismatches, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Child_Private_Legality_Pass998`.

Pass999: cross-unit closure now includes deterministic separate-body legality metadata. Separate bodies are classified separately from raw separate-parent links as resolved parent bodies, missing parents, ambiguous parents, overflow, parent-role mismatches, or missing parent-name text, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Separate_Body_Legality_Pass999`.

Pass1000: expression type inference metadata is staged in `Editor.Ada_Expression_Types` for semantic-colouring and diagnostics consumers; unresolved and ambiguous expression types remain explicit.

Pass1001 note: expression type inference now has an opt-in expected-type propagation layer. Declaration-default contexts and existing expected-context metadata are staged into deterministic expression records with compatible/propagated/mismatch/unknown statuses for diagnostics and overload/type checking.

Pass1002 note: expression type inference now records operator operand/result metadata for predefined numeric, Boolean, short-circuit, relational, and membership-shaped operators. Unknown and mismatched operands are preserved explicitly for diagnostics and overload-aware passes.

Pass1003: expression aggregate context inference extends the Ada expression-type model with context-sensitive aggregate/container-aggregate metadata, component-shape counters, and deterministic unknown/mismatch states for diagnostics.

Pass1004 update: expression type inference now includes conversion and qualified-expression target/operand metadata. The model exposes deterministic counters for resolved conversion targets, compatible operands, explicit-conversion operands, mismatches, and unknown conversion cases, with regression coverage in `Test_Ada_Expression_Conversion_Qualified_Inference_Pass1004`.

Pass1005 update: attribute-reference expression inference now preserves deterministic result-family metadata for common Ada attributes and keeps unknown/unresolved cases explicit for diagnostics and semantic colouring.

Pass1006: Added conditional/declare/reduction expression type inference metadata in Editor.Ada_Expression_Types. The model now tracks compatible/mismatched/unknown conditional branches, Boolean quantified results, declare-expression result staging, reduction-expression result staging, deterministic counters, and fingerprint contribution. Regression coverage: Test_Ada_Expression_Conditional_Declare_Reduction_Inference_Pass1006.


Pass1007: Added expression membership/range inference metadata. Membership expressions now retain Boolean result plus operand/choice compatibility state; range expressions retain bound subtype compatibility state; deterministic counters and fingerprints cover resolved, mismatch, and unknown cases.

Pass1008: Added expression target-name/update inference metadata. Ada 2022 target-name @ expressions now preserve context-required versus context-propagated status, delta/update aggregates retain expected/source subtype compatibility metadata, and deterministic counters/fingerprints expose compatible, mismatch, and unknown update-expression cases.


Pass1009: indexed and slice expressions expose typed metadata for semantic-colouring refinement while preserving snapshot-owned analysis.

Pass1010 note: expression-type metadata now exposes dereference/access-designator inference for semantic colouring, while rendering remains a non-parsing projection consumer.
Pass1011 note: expression-type metadata now exposes allocator target/result and expected access-designated subtype inference for semantic colouring, while rendering remains projection-only and performs no parsing.

Pass1012 note: expression-type metadata now exposes parameter-association formal subtype context for semantic-colouring/diagnostic consumers. Rendering remains projection-only and performs no parsing or semantic mutation.

Pass1013 note: expression-type metadata now exposes call actual/formal subtype compatibility for diagnostic and semantic-colouring consumers. Rendering remains projection-only and performs no parsing or semantic mutation.

Pass1014 note: expression-type metadata now exposes overload-aware operator resolution states for diagnostic and semantic-colouring consumers. Rendering remains projection-only and performs no parsing or semantic mutation.

Pass1015 note: expression-type metadata now exposes final universal numeric resolution states and range-error metadata for diagnostic and semantic-colouring consumers. Rendering remains projection-only and performs no parsing or semantic mutation.

Pass1016 note: aggregate expression metadata now exposes record component and array element validation states for diagnostics and semantic-colouring consumers. Rendering remains projection-only and performs no parsing or semantic mutation.

Pass1017: Expression type inference now includes raise-expression/no-return metadata with exception target, message shape, expected result context, deterministic counters, and AUnit coverage.

Pass1017: Expression type inference now includes raise-expression/no-return metadata with exception target, message shape, expected result context, deterministic counters, and AUnit coverage.

### Pass1018 — Boolean-context semantic metadata

Expression-type metadata now exposes Boolean-context classifications for short-circuit and condition-shaped expressions. Semantic-colouring consumers may use the metadata to distinguish resolved Boolean predicates from unknown or mismatched predicate contexts while keeping rendering projection-only.

### Pass1019 — concatenation semantic metadata

Expression-type metadata now exposes string/array concatenation classifications for `&`. Semantic-colouring consumers may use the metadata to distinguish resolved concatenations from unknown or mismatched operands while keeping rendering projection-only.

### Pass1020
Pass1020 adds dispatching-call inference metadata to `Editor.Ada_Expression_Types`, including primitive target, static binding, dynamic dispatch candidate, controlling-result, ambiguous, unresolved, and unknown classifications with deterministic counters and fingerprints.
### Pass1021
Expression diagnostics are now projected from expression-type metadata as stable semantic records. Rendering and colouring remain consumers only; no parsing or mutation is introduced on the rendering path.
Pass1022 notes: semantic colouring/navigation consumers can now consume cross-unit visibility metadata without parsing in the renderer. Imported units retain limited/private/use visibility status for future projection-only colouring and diagnostics.

Pass1023 notes: semantic colouring/navigation consumers can now identify units visible only through limited-with incomplete views and avoid presenting full-view-only assumptions from renderer-side projections.

### Pass1024 - private-with visibility constraints

Added `Editor.Ada_Private_With_Rules`, a deterministic lookup-facing projection
for private-with dependencies.  The model consumes cross-unit visibility
metadata, distinguishes visible-part/private-part/body lookup contexts, hides
private-with dependencies from ordinary visible-part lookup, exposes them in
private-part and body contexts, and retains missing/ambiguous/overflow cases as
explicit diagnostic metadata.  The regression
`Test_Ada_Private_With_Visibility_Constraints_Pass1024` covers the new counters,
context-sensitive lookup API, and fingerprinting behavior.

### Pass1025 - body/spec declaration conformance

Pass1025 adds `Editor.Ada_Body_Spec_Conformance`, a snapshot-owned semantic
closure projection over the project index and cross-unit spec/body consistency
model.  It confirms package body/spec pairs, confirms subprogram body/spec pairs
when retained profile summaries match, and preserves profile mismatches,
missing counterparts, ambiguous counterparts, overflow, role mismatches, and
name mismatches as deterministic metadata.

`Test_Ada_Body_Spec_Declaration_Conformance_Pass1025` covers the conformance
counters, profile mismatch preservation, missing counterpart preservation, and
deterministic fingerprints.

### Pass1026 - child-unit visibility from parent/private-child contexts

Pass1026 adds `Editor.Ada_Child_Unit_Visibility`, projecting child-unit legality metadata into context-sensitive lookup metadata for public children, private children, parent private parts, parent bodies, and external clients. Missing, ambiguous, overflow, and role-mismatch parent cases remain explicit diagnostic inputs, and the model remains deterministic, bounded, snapshot-owned, and free of render-side parsing or editor-state mutation.

- pass1027: separate-body stub placement metadata is now available to semantic consumers; rendering remains projection-only and performs no parsing.

### Pass1028

Freezing interactions are now available as deterministic semantic metadata. Rendering and colouring remain projection-only; no rendering-side parsing or mutation is introduced.

### Pass1029 - cross-unit representation target resolution

Cross-unit representation target metadata is now available as projection-only semantic data. Future colouring/diagnostic consumers can distinguish local unresolved representation targets from targets whose library-unit prefix is visible, limited-view-only, private-view-only, missing, ambiguous, or overflowed.

Pass1030 note: added Editor.Ada_Record_Layout_Validation as a compiler-grade record-layout validation building block. It derives deterministic bit-span metadata from record representation component clauses, detects overlapping component spans, preserves staged static/component errors, and exposes counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper alignment/size proof, overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
Pass1031 note: added Editor.Ada_Record_Storage_Order_Rules as a compiler-grade record representation building block. It projects Bit_Order and Scalar_Storage_Order clauses onto record component layout spans, classifies explicit order application, conflicts, operational errors, layout errors, and exposes deterministic counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1032 note: added Editor.Ada_Operational_Attribute_Rules as a compiler-grade operational representation building block. It consumes unified representation legality metadata after aspect/attribute-definition normalization, classifies duplicate operational properties, contradictory Boolean values, propagated target/value errors, and exposes deterministic counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1033: added aspect inheritance/overriding metadata through `Editor.Ada_Aspect_Inheritance_Rules`. The projection consumes unified representation/aspect legality and type-graph inheritance data to retain inherited properties, explicit overrides, contradictory override metadata, private-view override state, deterministic counters, and stable fingerprints without rendering-side parsing or mutation.

Pass1034: added generic formal type conformance metadata through `Editor.Ada_Generic_Formal_Type_Conformance`. The projection consumes parser-owned generic-contract and type-graph snapshots to classify private, derived, interface, access, scalar/discrete, array, and record formal type actuals, while preserving unresolved/mismatched/unknown states and deterministic counters/fingerprints without rendering-side parsing or mutation.

### Pass1035 - generic formal package nested actual metadata

Generic formal-package nested actual conformance is now available as deterministic semantic metadata. Semantic-colouring consumers may use the metadata to distinguish compatible nested package actuals from mismatched or unresolved formal package actuals while remaining projection-only.

### Pass1036 - generic renaming visibility metadata

Pass1036 exposes deterministic metadata for generic renamings and nested generic instantiations. Consumers can colour or annotate generic aliases and renamed-generic instantiations using stable source spans and fingerprints while preserving unresolved and ambiguous cases for diagnostics.

### Pass1037 - generic object default type metadata

Pass1037 exposes stable metadata for generic formal-object defaults and explicit object actuals. Semantic-colouring and diagnostics consumers can use the compatible/mismatch/range-error/unknown states to annotate generic instantiations without reparsing files or mutating editor state.

### Pass1038 generic contract diagnostics projection

Generic contract diagnostics are now available as projection metadata for semantic-colouring and diagnostics consumers. The layer remains diagnostics-only and does not alter rendering-side parsing or symbol classification.

Pass1039 update:
- Added Editor.Ada_Cross_Unit_Diagnostics to project cross-unit visibility and closure metadata into deterministic diagnostics.
- Covers missing/ambiguous dependencies, limited-view full-view restrictions, private-with visible-part restrictions, body/spec conformance failures, private-child visibility restrictions, child-parent errors, and separate-body stub/parent errors.
- Added Test_Ada_Cross_Unit_Diagnostics_Projection_Pass1039.

Pass1040: Added representation/freezing diagnostics projection through Editor.Ada_Representation_Diagnostics, covering representation legality, record layout, storage order, operational attributes, aspect inheritance, and freezing interaction metadata with deterministic spans/severities/fingerprints.

Pass1041: Semantic colouring can now consume parser-owned diagnostic projections through Editor.Ada_Semantic_Colour_Projection. The bridge maps diagnostic severities into existing Diagnostic_Error/Diagnostic_Warning token buckets and informational Identifier overlays while preserving deterministic spans and fingerprints without render-side parsing or mutation.

Pass1042: Added semantic diagnostic snapshot guards for diagnostic colouring overlays. Accepted overlays keep the pass1041 source/severity/span metadata; stale overlays are withheld and classified by mismatch reason before any editor-facing projection can consume them.

## Pass1045 notes

`Editor.Ada_Diagnostic_Navigation` projects indexed semantic diagnostics into IDE navigation targets. It supports deterministic first, last, next, previous, and severity-filtered target lookup while withholding all targets for rejected stale indexes. The colour/diagnostic pipeline remains snapshot-owned and projection-only.

## Pass1046 notes

`Editor.Ada_Diagnostic_Panel_Projection` projects indexed semantic diagnostics into stable IDE panel rows. It supports severity/source/file/unit grouping metadata, selected-row state, nearest-row selection, and stale-result withholding. The colour/diagnostic pipeline remains snapshot-owned and projection-only.

## Pass1047 notes

`Editor.Ada_Diagnostic_Status_Line` summarizes accepted semantic diagnostic indexes for status-line consumers. Stale rejected indexes expose no active diagnostic state and retain only rejected diagnostic totals, preserving the existing snapshot guard boundary.


## Pass1048 notes

`Editor.Ada_Diagnostic_Quick_Fix_Skeleton` projects accepted semantic diagnostics into non-editing action candidates. Rejected stale indexes expose no candidates and retain only rejected-candidate totals, preserving deterministic diagnostic ownership.

## Pass1049 notes

Added deterministic diagnostic provenance/explain metadata for semantic diagnostics. The layer preserves source-family and fingerprint evidence for each accepted diagnostic and withholds stale rejected indexes.

## Pass1050 notes

`Editor.Ada_Diagnostic_Suppression_Baseline` adds projection-only suppression/baseline metadata over accepted guarded diagnostics. It records rule reasons and fingerprints but does not remove diagnostics from the underlying index, apply edits, parse, mutate source buffers, or perform rendering-side semantic work.

Pass1051 note:
- Added overload ambiguity diagnostics over expression-type metadata. The model explains call/operator/universal-numeric ambiguity, mismatch, and unknown causes without adding rendering-side parsing, source mutation, file IO, command registration, workspace mutation, or compiler invocation.

Pass1052 update:
- Integrated overload ambiguity/candidate-rejection cause records into the expression diagnostics projection via `Editor.Ada_Expression_Diagnostics.Build_With_Overload_Causes`.
- Preserves deterministic overload cause detail, candidate counters, source spans, severity, and fingerprints for downstream semantic-colouring and diagnostic-feed consumers.
- Keeps the path projection-only and snapshot-owned; no render-side parsing, file IO, buffer mutation, command registration, workspace mutation, or edit application is introduced.

Pass1053 update:
- Added `Editor.Ada_Cross_Unit_Lookup_Integration`, routing cross-unit context visibility into deterministic lookup-facing metadata for ordinary with, use-package, limited, private, missing, ambiguous, and overflow cases.
- The pass preserves local-first lookup integration through `Resolve_With_Local` and keeps the model snapshot-owned, bounded, projection-only, and free of rendering-side parsing or editor-state mutation.

Pass1054 update:
- Selected-name metadata can now carry cross-unit prefix visibility status from the cross-unit lookup integration layer.
- The projection remains render-safe: semantic colouring may consume the metadata later, but this pass performs no rendering-side parsing or buffer/workspace mutation.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

#### Pass1056 — view-aware compatibility integration

Adds `Editor.Ada_View_Aware_Compatibility` as a deterministic consumer-facing bridge for private-view and limited-view compatibility effects. The pass classifies existing subtype-compatibility and cross-unit selected-name expression metadata into compatible, private-view, limited-view, unresolved, incompatible, and indeterminate buckets while preserving stable identities, spans, labels, and fingerprints. It remains projection/analysis-only and does not add rendering-side parsing, file IO, dirty-state mutation, command registration, or workspace mutation.
Pass1057: expression diagnostics now include private/limited-view compatibility barriers from the view-aware compatibility model, making those barriers available to the guarded semantic-colouring diagnostic overlay path without rendering-side parsing.

Pass1058: generic actual/default conformance now has a view-aware compatibility bridge for private, limited, and cross-unit unresolved barriers; this remains semantic metadata only and does not add rendering-side parsing.

Pass1059: generic contract diagnostics now consume generic view-compatibility metadata for private, limited, and cross-unit unresolved barriers; projection remains deterministic and render-safe.

Pass1060: Generic instantiated body analysis
- Adds `Editor.Ada_Generic_Instantiated_Body_Analysis`.
- Projects generic actual/default substitutions into matching generic body contract contexts.
- Preserves body contract identity, formal/instance identity, view-barrier metadata, cross-unit selector metadata, counters, and fingerprints.
- Regression: `Test_Ada_Generic_Instantiated_Body_Analysis_Pass1060`.

Pass1061: generic instantiated-body diagnostics projection extends the generic contract diagnostic source feeding semantic-colouring overlays. Instantiated-body private/limited/cross-unit/mismatch/missing-body statuses are now represented as deterministic diagnostics before any render-side projection; no rendering-side parsing or mutation is introduced.

Pass1062: Added nested body/spec declaration conformance metadata via Editor.Ada_Nested_Body_Spec_Conformance. The pass is snapshot-owned and projection-only, comparing direct nested declarations in confirmed body/spec unit pairs while preserving deterministic identities, spans, counters, and fingerprints.


### Pass1063 — Nested body/spec diagnostics projection

Pass1063 extends `Editor.Ada_Cross_Unit_Diagnostics` with `Build_With_Nested`, projecting `Editor.Ada_Nested_Body_Spec_Conformance` results into the cross-unit diagnostics model. Diagnostics now cover nested missing body declarations, extra body declarations, ambiguous body declarations, kind/profile mismatches, profile-unknown cases, and nonconforming enclosing unit pairs while preserving nested conformance identity/status, declaration names, spans, severity, messages, counters, and deterministic fingerprints. The existing `Build` path remains unchanged for first-order cross-unit diagnostics. Regression coverage is in `Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec_Pass1063`.

This pass adds one compiler-grade building block for nested body/spec diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1064 — Selected-name representation target resolution

Pass1064 adds `Editor.Ada_Selected_Representation_Targets`, a deterministic representation-target consumer that combines `Editor.Ada_Cross_Unit_Representation_Targets` with `Editor.Ada_Selected_Name_Resolution`. Representation clauses whose targets are selected names now preserve selected-name identity/status, prefix/selector text, visible cross-unit target unit/path, candidate counts, classification counters, and deterministic fingerprints. The layer distinguishes local selected targets, cross-unit visible selected targets, use-visible selected targets, limited/private-view barriers, missing/ambiguous/overflow prefixes, selector errors, and non-selected targets without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work. Regression coverage is in `Test_Ada_Selected_Representation_Targets_Pass1064`.

## Pass1065 selected representation diagnostics

Selected-name representation target failures now enter `Editor.Ada_Representation_Diagnostics` through `Build_With_Selected_Targets`. Once consumed by the existing guarded semantic diagnostic feed, these diagnostics can be surfaced by semantic-colouring overlays without rendering-side parsing or direct renderer semantic analysis.


### Pass1066

Added exact record layout size/alignment validation via `Editor.Ada_Record_Layout_Exact_Validation`, including exact/padded/exceeded Size clause classification, Alignment power-of-two validation, component-error propagation, target lookup, counters, fingerprints, and AUnit coverage in `Test_Ada_Record_Layout_Exact_Size_Alignment_Pass1066`.

### Pass1067 — Exact record layout diagnostics projection

Pass1067 projects exact record-layout validation results into `Editor.Ada_Representation_Diagnostics`. Size clauses smaller than occupied bits, padded Size clauses, invalid Alignment clauses, and propagated component-layout errors are now represented as deterministic representation diagnostics with stable spans, severity, counters, and fingerprints. The projection is metadata-only and does not introduce rendering-side parsing, file IO, buffer mutation, command registration, or workspace mutation.

Pass1068: Added Editor.Ada_Stream_Attribute_Profile_Conformance for deterministic stream attribute target-type profile conformance and representation diagnostic projection. The pass checks stream handler presence, ambiguity, procedure/function mode, arity, Input result subtype, target errors, and unknown profile cases while preserving snapshot-owned metadata and stale-safe diagnostic invariants.
Pass1069: Added Editor.Ada_Generic_Formal_Package_Substitutions for deterministic per-nested-actual formal package substitution metadata and generic diagnostic projection. The pass expands formal package nested conformance checks into substituted, boxed, mismatch, missing, wrong-generic, unresolved, malformed, and unknown entries while preserving formal/instance identity, nested position, source spans, fingerprints, and projection-only editor invariants.

### Pass1070 — Dispatching-call legality diagnostics

Added `Editor.Ada_Dispatching_Call_Legality` and expression-diagnostic integration for dispatching-call legality barriers. The pass consumes existing expression inference metadata only, preserves deterministic identities/spans/fingerprints, and projects unresolved, ambiguous, or unknown dispatching legality cases into the expression diagnostic model without rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, or edit application.

### Pass1071 — Overload ranking metadata

Pass1071 adds `Editor.Ada_Overload_Ranking`, a deterministic overload-ranking staging layer over expression type metadata and overload ambiguity causes. It classifies exact matches, implicit-conversion-ranked choices, universal-numeric tie-breaks, ambiguous-after-ranking cases, rejected candidate sets, and unknown ranking states while preserving expression identity, syntax node, candidate/rejection counts, source spans, source/cause fingerprints, and deterministic result fingerprints. `Editor.Ada_Expression_Diagnostics` now accepts ranking metadata through `Build_With_Overload_Ranking` and `Build_With_All_Semantic_Causes_And_Ranking`, projecting only rejected, ambiguous, or unknown ranking states as diagnostics while keeping successful ranking as non-mutating provenance metadata. Regression coverage is in `Test_Ada_Overload_Ranking_Pass1071`.

### Pass1072 — Overload ranking provenance/explain metadata

Overload-ranking provenance remains projection-only metadata. It explains ranking diagnostics already projected through expression diagnostics and semantic diagnostic overlays, without adding rendering-side parsing or renderer semantic work.

Pass1073 note: unified diagnostic provenance now accepts overload-ranking provenance through Editor.Ada_Diagnostic_Provenance.Build_With_Overload_Ranking.  The layer is projection-only, snapshot-guarded, and keeps overload-ranking explanation metadata out of rendering, command, workspace, and buffer mutation paths.

Pass1074 note: diagnostic quick-fix skeletons now accept overload-ranking provenance through Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build_With_Overload_Ranking.  The layer is projection-only, preserves ranked overload evidence for IDE explanation actions, and does not parse, apply edits, mutate buffers, touch workspace state, or perform rendering-side semantic work.

Pass1075 note: diagnostic action routing now joins quick-fix skeletons with diagnostic navigation, panel rows, provenance/explain items, status-line nearest-target metadata, and explicit feed edit hints through `Editor.Ada_Diagnostic_Action_Router`. The layer is projection-only and preserves stale-result rejection; it does not parse, mutate buffers, save/reload files, register commands, touch workspace state, or perform rendering-side semantic work.

Pass1076 note: diagnostic command projection now turns diagnostic action routes into deterministic command-facing descriptors through `Editor.Ada_Diagnostic_Command_Projection`, preserving explicit feed edit hints as descriptor metadata for executor-owned application. The layer is projection-only and does not register commands, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work. Rejected/stale action-route models expose no active command descriptors while preserving rejected-command totals.

Pass1077 note: diagnostic command palette projection now turns diagnostic command descriptors into deterministic command-palette-facing entries through `Editor.Ada_Diagnostic_Command_Palette_Projection`. The layer is projection-only and does not register command aliases, mutate keybindings, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work. Rejected/stale command projection models expose no active palette entries while preserving rejected-entry totals.

- Pass1078: diagnostic keybinding hints remain downstream projection metadata over guarded diagnostic command-palette entries; no syntax-colouring parser path or rendering-side semantic work is introduced.

### Pass1079 diagnostic workspace/session projection

Pass1079 adds a projection-only diagnostic workspace/session model over diagnostic keybinding hints. The layer produces stable persistable diagnostic/action keys, selection/restore-candidate metadata, counters, and fingerprints without mutating workspace/session state, registering commands, changing keybindings, invoking commands, parsing, saving/reloading files, mutating buffers, or adding rendering-side semantic work. Rejected/stale inputs expose no active workspace entries and retain rejected totals.

### Pass 1080

Adds diagnostic render projection coverage through `Editor.Ada_Diagnostic_Render_Projection`.  The pass keeps diagnostic rendering data immutable and projection-only: accepted workspace/session diagnostic state is converted into stable draw-facing rows and badges, while stale/rejected models expose no active rows and retain rejected-row counts.  No parser, renderer, command, keybinding, workspace, buffer, edit, save, or reload mutation path is introduced.

Pass1081: Added diagnostic lifecycle recovery projection over render rows and the guarded diagnostic index.  The layer validates retained/changed/missing/stale diagnostic UI state without parsing, rendering-side semantic work, command/keybinding/workspace mutation, buffer mutation, edits, or file save/reload.

### Pass1082 diagnostic recovery status notes

Diagnostic recovery status projection remains render-safe.  It consumes already
projected lifecycle recovery rows and exposes immutable status/headline metadata
for UI surfaces without parsing, semantic analysis, buffer mutation, or rendering
side effects.

### Pass1083

Added deterministic diagnostic recovery action projection.  Recovery/status rows for retained, changed, missing, and stale diagnostic UI state can now be surfaced as non-mutating IDE action metadata with stable identities and fingerprints.  The layer remains projection-only and preserves the parser, rendering, command, keybinding, workspace, buffer, and file lifecycle invariants.

- Pass1084: added projection-only diagnostic recovery command descriptors for lifecycle/recovery actions while preserving stale-result rejection and no mutation boundaries.

### Pass1085 recovery command palette projection

Diagnostic recovery command-palette entries remain downstream of guarded diagnostic projections. The pass adds no rendering-side parsing or semantic-colouring mutation; it only exposes immutable palette metadata for existing recovery commands.

Pass1086 diagnostic recovery keybinding hints remain downstream of guarded diagnostic recovery projections.  The pass adds no rendering-side parsing or semantic-colouring mutation; it only exposes immutable keybinding/invocation hint metadata for existing recovery command-palette entries.

Pass1087: Added Editor.Ada_Diagnostic_Recovery_Workspace_Projection for deterministic workspace/session-facing diagnostic recovery UI state descriptors. The projection consumes recovery keybinding hints, derives stable persistable keys without buffer-internal identifiers, preserves recovery/action/status/lifecycle/render/index identities and fingerprints, and remains projection-only with no workspace mutation, command registration, keybinding changes, edits, parsing, save/reload, or rendering-side semantic work.

Pass1088: Added Editor.Ada_Diagnostic_Recovery_Render_Projection. Diagnostic recovery workspace/session state can now be projected into immutable render-safe rows and recovery badges without rendering-side parsing, rendering-side semantic work, command registration, keybinding/workspace mutation, edits, buffer mutation, or file save/reload.

Pass1089: Added Editor.Ada_Diagnostic_Recovery_Render_Lifecycle. Render-safe diagnostic recovery UI state now has a deterministic lifecycle validation model over fresh semantic diagnostic indexes, preserving stable spans, recovery badges, and fingerprints without rendering-side analysis or mutation.

Pass1090: Added Editor.Ada_Diagnostic_Recovery_Render_Status. Render-safe diagnostic recovery lifecycle state can now be summarized for IDE surfaces while preserving recovery badges, stable spans, and fingerprints without adding rendering-side semantic work or mutation.

### Pass1091 diagnostic recovery render action projection

Added `Editor.Ada_Diagnostic_Recovery_Render_Action_Projection` as a deterministic projection-only consumer of diagnostic recovery render status.  It exposes retained/changed/missing/stale/restore-candidate recovery-render actions for IDE consumers while preserving stable diagnostic identities, source spans, severity/source metadata, persistent keys, and fingerprints.  No parsing, command registration, command aliases, command invocation, keybinding mutation, workspace/session mutation, edits, buffer mutation, file save/reload, or rendering-side semantic work is introduced.

Pass1092: Added Editor.Ada_Diagnostic_Recovery_Render_Command_Projection as a projection-only command-facing layer for diagnostic recovery-render actions. It preserves stable recovery render/action/diagnostic identities and availability metadata while avoiding command registration, aliases, keybinding/workspace mutation, edits, parsing, file save/reload, and rendering-side semantic work. Regression: Test_Ada_Diagnostic_Recovery_Render_Command_Projection_Pass1092.

Pass1093: Diagnostic recovery-render command palette projection remains downstream of guarded diagnostic projections. It does not change lexical or semantic-colouring classification and performs no rendering-side parsing or semantic work.

Pass1094 note: added `Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection` as a projection-only bridge from recovery-render command-palette entries to deterministic keybinding/invocation hint metadata. The layer preserves stable diagnostic/recovery-render identities, source spans, severities, lifecycle/recovery headline metadata, persistent keys, previous/current diagnostic fingerprints, and hint fingerprints while avoiding command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, workspace/session mutation, rendering, or rendering-side semantic work.

Pass1095 note: added `Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection` as a projection-only bridge from recovery-render keybinding hints to deterministic workspace/session-facing UI state descriptors. The layer preserves stable diagnostic/recovery-render identities, source spans, severities, lifecycle/recovery headline metadata, persistent diagnostic/action/command keys, previous/current diagnostic fingerprints, selected/restore-candidate metadata, and workspace fingerprints while avoiding workspace/session mutation, command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, rendering, or rendering-side semantic work.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1097: final diagnostic recovery-render lifecycle validation is covered as a projection-only consumer of final render-safe rows and the guarded semantic diagnostic index. It preserves stale-result rejection and stable fingerprints without parser, renderer, command, keybinding, workspace, buffer, or file lifecycle side effects.

Pass1098: final diagnostic recovery-render lifecycle status is now covered by `Editor.Ada_Diagnostic_Recovery_Render_Final_Status`. The status surface consumes final lifecycle rows only, withholds active rows for stale final lifecycle inputs, preserves rejected totals and deterministic fingerprints, and adds no rendering-side parsing, semantic-colouring mutation, command/keybinding/workspace mutation, buffer mutation, or file lifecycle side effects.

Pass1099 note: Added `Editor.Ada_Assignment_Legality` as a semantic rule-completion pass for assignment and object-initialization legality.  The pass is snapshot-owned and projection-free: it consumes existing expression, subtype, static, type/view metadata and classifies target/source compatibility, constant/in-formal target errors, null-exclusion violations, static range violations, private/limited view barriers, unresolved universal numeric cases, and indeterminate cases without render-side parsing or editor mutation.

Pass1100 note: added `Editor.Ada_Return_Legality`, a snapshot-owned semantic legality layer for Ada return statements. It consumes assignment/object-initialization legality results and classifies legal procedure/function/extended returns plus illegal expression shape, incompatible result subtype, private/limited view barriers, unresolved result metadata, static range violations, unresolved universal numeric returns, and No_Return subprogram return statements. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, or mutable IDE-surface side effect is introduced.

Pass1101 note: widened the semantic pass scope by adding `Editor.Ada_Conversion_Access_Aggregate_Legality`, a snapshot-owned semantic legality layer covering conversion and qualified-expression legality, numeric/static range conversion checks, tagged/class-wide conversion classification, access/null-exclusion/accessibility foundations, allocator designated-subtype compatibility, aggregate structural legality, and container aggregate missing-aspect classification. Added `Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101` and registered it in `Core_Suite`. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation is introduced.

Pass1102: Added `Editor.Ada_Control_Flow_Legality`, a wide snapshot-owned semantic legality layer for Ada control-flow and statement rules.  The pass classifies Boolean condition legality, case choice staticness/coverage/duplicates, exit/goto/label target legality, exception handler choices, raise targets, select/accept/requeue target checks, and return-path completeness without render-side parsing or editor mutation.

Pass1103 update: added `Editor.Ada_Tasking_Protected_Legality`, a snapshot-owned semantic legality layer for Ada task/protected type and body matching, entry declarations/bodies/families, protected barriers, accept/requeue legality, protected operation restrictions, select integration, and linked control-flow legality propagation. Added and registered `Test_Ada_Tasking_Protected_Legality_Pass1103`. No diagnostic projection chain, rendering-side parsing, file save/reload, dirty-state mutation, or command/keybinding/workspace/render mutation is introduced.

Pass1104 note: `Editor.Ada_Tagged_Derived_Legality` classifies tagged/derived/private/interface legality, overriding conformance, abstract-operation requirements, dispatching-call legality propagation, and class-wide conversion compatibility. The layer is snapshot-owned and does not add rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation.

Pass1105 note: generic instance body substitutions, formal-package substitutions, instance freezing effects, representation-after-freezing cases, and linked assignment/return/conversion/tagged legality failures can now be represented as snapshot-owned semantic legality metadata. Syntax-colouring remains projection-only.

Pass1106 note: cross-unit dependency, lookup, limited/private view, and linked legality failures across assignment, return, expression, control-flow, tasking, tagged, generic-instance, and representation layers can now be represented as snapshot-owned semantic closure metadata. Syntax-colouring remains projection-only.

Pass1107: wide semantic legality diagnostics bridge added for Pass1099-Pass1106 compiler-grade legality layers, preserving snapshot ownership and deterministic fingerprints.

Pass1108 update:
- Integrated the Pass1107 wide semantic legality diagnostics into the unified snapshot-guarded semantic diagnostic feed via Build_With_Wide_Legality.
- Wide assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and cross-unit legality failures now participate in the normal diagnostic feed and index.
- Stale wide legality inputs and rejected base semantic guards expose zero active feed rows while preserving rejected-entry accounting.
- Added AUnit coverage in Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Pass1108 and registered it in Core_Suite.

Pass1109 update: added Editor.Ada_Overload_Resolution_Legality as a compiler-grade overload/operator legality building block. It classifies exact and preference-based selections, expected-type and universal numeric preferences, primitive operator preference, implicit/class-wide/access conversion evidence, named/defaulted profile evidence, visibility failures, view barriers, cross-unit unresolved states, linked semantic errors, ambiguity, unknown, and indeterminate states. The layer is snapshot-owned and deterministic, with AUnit coverage in Test_Ada_Overload_Resolution_Legality_Pass1109.

Pass1110: added Editor.Ada_Staticness_Range_Predicate_Legality, a snapshot-owned semantic legality layer for Ada staticness requirements, range/choice legality, predicate metadata, linked assignment/return/conversion/access/aggregate/overload legality, deterministic lookup helpers, counters, and fingerprints. No diagnostic UI projection chain, rendering-side parser, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration is introduced.

Pass1111 update: added `Editor.Ada_Accessibility_Lifetime_Legality`, a widened snapshot-owned Ada accessibility/lifetime/aliasing legality layer covering accessibility levels, dynamic checks, null exclusion, access kind mismatches, aliased-object requirements, allocator/access-conversion/return-accessibility checks, anonymous access parameter escapes, access discriminant lifetime checks, dangling renaming risk metadata, and linked assignment/return/conversion/staticness failures. Added and registered `Test_Ada_Accessibility_Lifetime_Legality_Pass1111`.


Pass1112: Contract/aspect semantic legality metadata is snapshot-owned and can be projected into colouring/diagnostic surfaces without command, workspace, or render mutation.


## Pass1113

Elaboration-order and dependence legality statuses are snapshot-owned semantic facts and remain separate from rendering.


Pass1114: Added Editor.Ada_Unit_Completion_Order_Legality for compiler-grade unit/body completion and declaration-order legality, including package/subprogram/task/protected/generic body completion, private/deferred/incomplete completion, body-stub/separate-body completion, declaration-before-use, private-part ordering, frozen-before-completion, view barriers, and linked semantic blockers. Added AUnit coverage and deterministic counters/lookups/fingerprints.

Pass1115 update: added Editor.Ada_Renaming_Alias_Visibility_Legality as a widened semantic legality layer for Ada renaming declarations, alias views, direct/use/use-type visibility, selected-name targets, homograph hiding, private/limited-view barriers, aliased-target requirements, self/circular renames, dangling rename risks, invalid/duplicate use clauses, and linked accessibility/overload/cross-unit/completion blockers. Added and registered Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1116 update: added Editor.Ada_Exception_Finalization_Legality as a widened semantic legality layer for Ada exception, raise, handler, propagation, cleanup/finalization, task termination, controlled primitive, and No_Return contexts. It consumes control-flow, accessibility/lifetime, contract/aspect, elaboration/dependence, renaming/visibility, and unit completion/order legality metadata; classifies legal raise/reraise/handler/renaming/propagation/finalization/No_Return cases; and reports unresolved/ambiguous/non-exception raise targets, reraise outside handlers, handler choice errors, raise-expression result issues, invalid exception renaming targets, controlled finalization primitive/profile/order/propagation/abort/master errors, No_Return violations, private/limited view barriers, and linked semantic blockers. Added and registered Test_Ada_Exception_Finalization_Legality_Pass1116. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1117 update: added Editor.Ada_Representation_Layout_Stream_Integration_Legality. The pass integrates representation legality, exact record layout, stream attribute profile conformance, generic-instance freezing/representation effects, accessibility/lifetime, staticness/range/predicate, completion/order, contract/aspect, and exception/finalization legality into one deterministic snapshot-owned semantic model. It adds Test_Ada_Representation_Layout_Stream_Integration_Legality_Pass1117 and keeps the analysis non-mutating, bounded, and independent of rendering, command, keybinding, workspace, save/reload, file IO, compiler invocation, LSP, and external parser generators.

Pass1118 update: added Editor.Ada_Integrated_Semantic_Closure as a widened semantic closure layer. It folds wide semantic legality diagnostics with overload, staticness/range/predicate, accessibility/lifetime, contract/aspect, elaboration/dependence, unit completion/order, renaming/alias/visibility, exception/finalization, and representation/layout/stream integration blockers into one deterministic snapshot-owned closure model. It classifies local/cross-unit/with-use legal closure, limited/private-view barriers, missing/ambiguous/overflow/stale/rejected dependencies, individual legality blockers, multiple blockers, and indeterminate closure. Added and registered Test_Ada_Integrated_Semantic_Closure_Pass1118 with counters, lookups, and fingerprints. The pass remains non-mutating and introduces no rendering-side parser, save/reload path, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

Pass1119 update:
- Integrated semantic closure diagnostics now flow into the unified snapshot-guarded semantic diagnostic feed through Build_With_Integrated_Closure.
- Non-legal integrated closure rows become indexed semantic diagnostics; legal closure rows remain non-diagnostic.
- Stale integrated closure inputs and rejected base diagnostic guards expose zero active rows while preserving rejected-entry totals.
- This is a semantic integration pass, not a UI projection-chain extension.

Pass1120: Added integrated semantic closure provenance in `Editor.Ada_Diagnostic_Provenance`. Indexed diagnostics from `Editor.Ada_Integrated_Semantic_Closure` now retain explainable links to closure status, blocker family, dependency state, fingerprints, and diagnostic/index identity. The pass is deterministic, bounded, snapshot-owned, and non-mutating.

Pass1121 update: added `Editor.Ada_Definite_Initialization_Flow_Legality` with snapshot-owned definite-initialization and flow-sensitive object-state legality for read-before-write, component coverage, out-parameter obligations, return-object initialization, branch/loop merge failures, exception/finalization initialization effects, and linked semantic blockers. Regression: `Test_Ada_Definite_Initialization_Flow_Legality_Pass1121`.

### Pass1122 note

Semantic colouring diagnostics that consume the unified diagnostic feed can now receive definite-initialization/flow blockers through integrated semantic closure. The implementation does not add rendering-side parsing or colouring-specific analysis; it reuses snapshot-owned semantic closure rows.

### Pass1123 note

Global/Depends dataflow failures are now integrated semantic closure blockers. Semantic colouring diagnostics that consume the unified diagnostic feed can receive Global read/write, Depends source/target, linked contract-flow, and initialization-before-read blockers without rendering-side parsing or a colouring-specific analysis path.

### Pass1124 semantic note

Predicate/invariant use-site legality is now modelled in `Editor.Ada_Predicate_Invariant_Use_Site_Legality`. Semantic colouring should continue to consume language-model/resolver classifications only; predicate and invariant failures enter the semantic legality model rather than introducing rendering-side parsing or colour-specific diagnostics.

Pass1125 note: added Editor.Ada_Generic_Instance_Body_Semantic_Expansion, connecting instantiated generic body actual/formal substitutions to overload, accessibility/lifetime, contract/aspect, Global/Depends dataflow, definite-initialization, predicate/invariant, and representation/layout/stream legality.  This is a semantic integration pass, not a diagnostic or UI projection pass.

### Pass1125 semantic note

Generic instance body expansion is semantic-only.  It adds no syntax-colouring projection or render-side parsing; it exposes actual/formal substitution blockers through deterministic semantic legality data for later diagnostic consumers.

Pass1126: Added Ada overload preference legality. The semantic model now refines broad overload legality with direct/use visibility tiers, expected-type/profile evidence, primitive and dispatching primitive preferences, universal numeric preferences, conversion preferences, named/defaulted formal profile evidence, and distinct ambiguity classes. This is semantic legality integration only; it adds no rendering-side parsing or UI projection chain.

Pass1127 note: added Editor.Ada_Record_Variant_Aggregate_Legality to connect aggregate structural legality, discriminant constraints, variant coverage, predicate/invariant use-site checks, and representation/layout integration into deterministic record/variant aggregate semantic closure.
Pass1128 note: added Editor.Ada_Accessibility_Precision_Legality to deepen accessibility/lifetime precision across nested access levels, anonymous access parameters, allocator masters, access discriminants, return accessibility, generic actual lifetime substitution, and aggregate discriminant contexts.

## Pass1129

Elaboration precision diagnostics can now distinguish call-before-body elaboration, access-before-elaboration, missing Elaborate_All/Elaborate_Body closure, generic-instance body elaboration, policy restriction failures, dataflow blockers, overload preference blockers, and accessibility blockers without introducing rendering-side parsing.

## Pass1130

Tasking/protected precision legality remains analysis-owned. Syntax colouring continues to consume semantic facts only through existing snapshot-safe projections; no rendering-side parsing or colouring-specific semantic mutation was added.

Pass1131 update: representation/freezing precision now connects explicit representation items, implicit semantic-use freezing, private/full-view timing, generic-instance freezing effects, representation/layout/stream integration, elaboration precision, and tasking/protected precision through `Editor.Ada_Representation_Freezing_Precision_Legality` with AUnit coverage.

## Pass1132 semantic coverage audit note

The parser/AST semantic coverage audit is an analysis-side guard only. It does not add syntax-colouring categories or render-side parsing. It prevents semantic consumers from treating token-only or structurally incomplete parses as compiler-grade legality input.

Pass1133 note: parser/AST semantic coverage audit gaps now feed integrated semantic closure through `Editor.Ada_Integrated_Semantic_Closure.AST_Coverage`. Uncovered Ada 2022 constructs are actionable semantic blockers rather than passive audit findings.

Pass1134 update: semantic coverage gates consume parser/AST coverage audit rows and prevent downstream Ada legality layers from treating incomplete parser structure, missing semantic metadata, missing cross-unit metadata, or non-integrated semantic consumers as confident legal conclusions.


Pass1135: Integrated semantic closure coverage gates wire Pass1134 semantic coverage gates into integrated closure. Unsafe confident conclusions caused by parser/AST, metadata, consumer-integration, graceful-degradation, or cross-unit coverage gaps now become closure blockers, dependency failures, or indeterminate closure rows.


Pass1136: Added coverage-gated semantic result integration so semantic coverage gates preserve the original widened legality conclusion family, consumer, source row, gate reason, and fingerprint through integrated closure.

Pass1141: Added RM-grade overload edge legality for universal numeric/fixed/root preference, inherited primitive hiding, dispatching/nondispatching ambiguity, access-to-subprogram profiles, generic formal subprograms, nested generic overload ambiguity, and preservation of generic replay / coverage-gate blockers.

Pass1142: Added Editor.Ada_Discriminant_Dependent_Legality. Discriminant constraints/defaults, variant presence, constrained/unconstrained record semantics, and discriminant-dependent checks now connect to assignment, conversion, return, allocator, aggregate, generic actual, private/full-view, and coverage-gated semantic contexts.

## Pass1144 - Elaboration graph closure legality

Semantic colouring remains backed by language-model/resolver facts.  Pass1144 does not add rendering-side parsing; it adds elaboration graph closure facts that diagnostics and semantic consumers can use for transitive elaboration blockers, cycle paths, and body-before-use risks.


Pass1145: added tasking/protected effects legality connecting entry queues, accept/requeue/select effects, protected-state flow effects, elaboration graph closure, accessibility scope, finalization, and coverage-gated semantic blockers.

Pass1146 note: added Editor.Ada_Representation_Freezing_Exact_Propagation_Legality, which propagates implicit freezing from semantic uses and ties representation timing to generic body replay, discriminant/variant representation, operational/stream/finalization effects, flow-effect graphs, predicate/invariant propagation, accessibility scope graphs, elaboration graph closure, tasking/protected effects, and coverage-gated semantic blockers.

## Pass1147 coverage repair note

Syntax and semantic colouring consumers must not rely on token-only Ada syntax
coverage when the repair model still reports parser/AST/metadata gaps.  Once a
repair row proves structural coverage and consumer integration, downstream
semantic classifications may use the repaired construct facts confidently.


Pass1148: AST coverage repair gate application
- Added Editor.Ada_AST_Coverage_Repair_Gate_Application so Pass1147 parser/AST coverage repairs are consumed by widened legality coverage-gate enforcement. Complete repairs clear matching parser/AST, metadata, consumer-integration, suppressed-result, and unsafe-result blockers; missing, partial, cross-unit, and original semantic-error cases remain explicit blockers.

Pass1152 note: repaired parser/AST coverage is now fed back into semantic legality consumers through `Editor.Ada_Repaired_Coverage_Semantic_Feedback`. Syntax and semantic colouring remain projection-only; renderer code must consume only already-built semantic feedback/diagnostic rows and must not infer that a token-only or stale repair is safe.

Pass1153 update: Refined_Global / Refined_Depends conformance now consumes flow-effect graph rows and repaired coverage feedback before accepting body/spec flow-contract conclusions. Body reads/writes, refined Global coverage, refined Depends edges, call propagation, linked flow errors, and repaired coverage blockers are represented as deterministic semantic legality rows.

Pass1154 update: Refined_Global / Refined_Depends body-spec conformance now feeds integrated semantic closure as a first-class blocker family. Legal refined conformance remains confident local closure; missing Global coverage, invalid Refined_Depends edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers are exposed through integrated closure.

Pass1156: contract flow/refinement consumer legality is semantic-only. Syntax colouring remains projection-only; contract-flow highlighting must continue to consume snapshot-owned semantic rows and must not parse, repair, or mutate editor state.

Pass1173 keeps task/protected/select syntax-colouring confidence tied to semantic AST repair evidence. Tasking constructs with partial parser/AST/metadata repair remain blocked or indeterminate rather than being treated as confidently restored semantic constructs.
Pass1173 keeps task/protected/select syntax-colouring confidence tied to semantic AST repair evidence. Tasking constructs with partial parser/AST/metadata repair remain blocked or indeterminate rather than being treated as confidently restored semantic constructs.

Pass1174 note: generic formal declaration colouring/semantic attribution should rely on restored generic-formal AST repair facts only after parser, structure, span, name/type/staticness/contract metadata, cross-unit metadata, and generic consumer integration have been accepted.

Pass1175 does not add syntax-colouring projection. It strengthens access-definition semantic coverage repair so colouring and semantic consumers do not treat token-only or partially repaired access constructs as confidently typed/accessibility-checked.

Pass1176: representation/operational AST repair legality now requires complete parser node, structural AST, source span, token/degradation replacement, metadata, cross-unit, and integrated consumer evidence for representation clauses, operational attribute clauses, aspect specifications, and pragmas before clearing semantic coverage gates.
Pass1177 keeps semantic-colouring inputs gated for discriminant/variant constructs until discriminant specifications, variant parts, discriminant-dependent aggregates, and private/full-view discriminant views have repaired parser/AST coverage and integrated semantic consumer evidence.

Pass1178 keeps semantic colouring downstream of repaired expression AST coverage. Container aggregates, delta aggregates, reduction expressions, and quantified expressions remain gated until repaired expression metadata and integrated consumers make their semantic classification trustworthy.

Pass1179: Added Editor.Ada_Overload_Type_Edge_Precision_Legality. The overload/type precision layer now preserves remaining Ada RM edge blockers for access-to-subprogram profiles, universal fixed/root numeric choices, inherited primitive hiding, dispatching/nondispatching ambiguity, generic formal subprograms, nested generic named/defaulted actual ties, and class-wide controlling contexts while requiring repaired expression AST and generic replay representation contract-predicate/dataflow evidence before accepting confident legality.


Pass1180 does not add colouring categories. It strengthens the semantic source/instance mapping behind generic replay so future diagnostics and semantic highlights can identify both generic body source and instantiation/formal/actual context without relying on flattened replay errors.

Pass1181: Integrated semantic closure now consumes generic replay source/instance backmapping rows directly. Generic body source, instantiation, formal, actual, substituted body, replay CPD, and overload/type-edge evidence are preserved as closure-visible semantic blocker families.

Pass1182: Added discriminant/variant consumer integration legality so record layout, aggregate, freezing/representation, access-discriminant, generic replay, and private/full-view consumers require accepted discriminant/variant, repaired AST, representation CPD, and generic backmapping evidence before reporting confident semantic legality.

Pass1183: Added Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality, a final accessibility master/scope consumer layer that requires exact scope, object-flow, discriminant/variant, and generic replay backmapping evidence before accepting anonymous access results, access discriminants, allocators, aggregate access components, generic access escapes, renamings, and controlled finalization lifetime paths as confidently legal.

Pass1184: added Editor.Ada_Elaboration_Graph_Final_Consumer_Legality. The pass feeds elaboration graph closure into final call/default/aspect/representation/tasking/generic/policy consumers and preserves predicate/dataflow, overload/type, representation/freezing, tasking, generic backmapping, accessibility, missing-evidence, duplicate-evidence, and indeterminate blockers as deterministic semantic legality rows.

Pass1185: Added Editor.Ada_Tasking_Protected_Final_Effects_Legality, preserving final tasking/protected effect blockers for protected reentrancy, visible-state mutation, barrier side effects, requeue-with-abort safety, terminate alternatives, finalization hazards, and dependent elaboration/representation/accessibility/discriminant evidence.

Pass1186 update:
- Added Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality.
- Final cross-unit semantic closure now preserves blocker families from integrated closure, overload/type-edge precision, generic replay backmapping, discriminant/variant consumers, final accessibility master/scope evidence, final elaboration evidence, final tasking/protected effects, representation/freezing CPD evidence, contract/predicate/dataflow evidence, Refined_Global/Depends conformance, unit completion/order, renaming/alias/visibility, and exception/finalization legality.
- Added Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality_Pass1186 and registered it in the core AUnit suite.

Pass1187 note: Added Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality. Renaming declarations, separate bodies, body stubs, exception handlers, and raise expressions now have construct-specific parser/AST repair legality rows. These rows require parser nodes, structural AST shape, source spans, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated semantic consumers before repaired coverage can restore confident semantic conclusions.

Pass1188: Added expression control/target AST repair legality for membership tests, case expressions, if expressions, declare expressions, and target-name/update-expression contexts. Repaired coverage for these constructs only restores confident semantic conclusions when parser node, structural AST, source span, token/degradation replacement, required metadata, cross-unit metadata, and integrated semantic consumer evidence are present.

Pass1189: Added Editor.Ada_Overload_Type_Final_RM_Consumer_Legality. The overload/type final RM consumer now requires repaired access-definition AST evidence, overload/type edge precision evidence, and generic source/instance backmapping evidence before accepting prefixed-call primitive visibility, access-to-subprogram profile/null-exclusion/convention matching, class-wide controlling-result interactions, inherited/private-extension primitive hiding, universal fixed/root numeric mixed-mode ties, dispatching inherited operations, generic formal subprogram instances, and nested generic prefixed calls as confidently legal.

Pass1190: Added Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality. Nested generic replay closure now requires source/instance backmapping, final overload/type RM consumer evidence, cross-unit final semantic closure evidence, generic body availability, bounded dependency/cycle state, view/child visibility state, and source/substitution fingerprints before local, cross-unit, child/private-child, formal-package, nested-instance, body/subprogram, representation, and task/protected generic replay conclusions can remain confidently legal. It preserves nested dependency cycles, recursive instantiation cycles, cycle-depth overflow, dependency overflow, stale dependencies, missing evidence, view barriers, generic body availability failures, mapping/fingerprint mismatches, and multiple blockers as first-class semantic statuses.


Pass1191: final representation/freezing hard-case legality remains model-owned; rendering and colouring consume only stable semantic facts and do not perform representation parsing.
Pass1192: final flow/contract proof legality now preserves transitive Depends, dispatching Global refinement, abstract/refined state, volatile/atomic, independent-component, cross-unit, contract/dataflow, representation, and initialization blockers.

Pass1193 update:
- Added final deep tasking/protected edge legality for protected reentrancy, entry-family queue semantics, terminate graphs, and abort/deferred-finalization ordering.

## Pass1195 final semantic diagnostic feed integration

Pass1195 connects final semantic diagnostic rows to the snapshot-guarded semantic feed/index path while preserving blocker-family identity and stale-input rejection.  It adds no parser grammar or UI projection layer.


Pass1196 keeps semantic diagnostic provenance distinct from syntax-colouring projection: final blocker families are traced through the diagnostic feed/index path without introducing rendering-side parsing or colour-specific semantic decisions.

Pass1197 adds blocker-family-aware search indexing for final semantic diagnostics, preserving final semantic provenance across blocker family, status, stage, node, span, fingerprint, feed-link, and diagnostic-index-link queries.

Pass1198 update: added final semantic blocker trace closure.  Final semantic diagnostics can now be traced through blocker-family-preserving chains from final semantic closure and diagnostic integration through feed/index/provenance/search rows, including cross-unit, overload/type, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, AST repair, coverage-gate, view-barrier, stale, indeterminate, and multiple-blocker roots.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.


Pass1202 routes final remediation diagnostic rows through the semantic diagnostic feed with family-aware source mapping. This is semantic evidence plumbing only; no rendering-side parsing or colouring-side semantic inference was added.

Pass1203 adds final semantic remediation diagnostic provenance/search, preserving prerequisite blocker-family identity from remediation diagnostics through closure/gate/trace/feed/index/base-provenance links.

Pass1204: Added final semantic remediation worklist legality. The new worklist consumes remediation diagnostic provenance/search evidence and orders prerequisite semantic repair/re-analysis work by real blocker family while preserving deterministic node/span/fingerprint identity.

Pass1205 adds final semantic recheck eligibility legality.  It consumes remediation worklist ordering and emits bounded eligibility rows that preserve prerequisite blocker-family identity before semantic re-analysis is allowed.

Pass1206 adds Editor.Ada_Final_Semantic_Recheck_Application_Legality. It applies final semantic recheck eligibility back into the closure/feed boundary so only rows whose prerequisite chain is eligible now can become current, while stale, AST/coverage, cross-unit, view, generic, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, discriminant/variant, preserved-error, multiple-prerequisite, and indeterminate blockers remain explicit withheld-current semantic rows.

Pass1207 adds Editor.Ada_Final_Semantic_Recheck_Convergence_Legality. It consumes final semantic recheck application rows and marks results as converged, stably withheld, preserved-error, indeterminate, or changed relative to a prior application fingerprint, so the closure/feed boundary can stop cycling on unchanged prerequisite evidence while still rechecking stale, AST/coverage, cross-unit, view, generic, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, discriminant/variant, multiple-prerequisite, and indeterminate blocker families when their fingerprints change.

Pass1208 note: Added final semantic stabilization gate legality. Converged recheck rows may be promoted across the final closure/feed boundary; prerequisite-blocked rows remain withheld with their original blocker family and stable fingerprints.

Pass1209 note: final semantic stabilization now feeds a stabilized closure model,
so stable accepted rows and stable withheld prerequisite blockers are represented
before diagnostic/feed exposure.

Pass1210: Added Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration. Stable accepted closure rows from Pass1209 are withheld as current non-diagnostic semantic evidence, while stabilized blockers are emitted with their original blocker-family identity. Recheck-required and indeterminate rows remain warnings instead of being promoted as confident legal conclusions.

Pass1210 feed integration: `Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Final_Stabilized_Diagnostics` consumes stabilized diagnostic rows, emits only stabilized blockers/recheck/indeterminate rows, withholds stable accepted closure rows, and preserves source-family mapping for cross-unit, generic, representation/freezing, and expression-family blockers.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1213: Added final overload/shared-state RM edge legality.  Final overload/type decisions now consume abstract/refined-state and volatile/atomic/shared-state evidence and preserve effect blockers by family.

Pass1214 does not add rendering-side parsing; representation/shared-state findings remain semantic evidence for existing diagnostic/colouring consumers.

Pass1216: Added Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality. The final shared-state semantic chain now has cross-unit closure across abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, and tasking/protected shared-state evidence. Dependency, view, state-visibility, generic body/backmapping, volatile/atomic ordering, shared-variable, representation-effect, tasking-effect, fingerprint, multiple-blocker, and indeterminate states remain distinct blocker families.

Pass1218: Shared-state remediation worklist legality now orders prerequisite semantic re-analysis for stabilized shared-state blockers without flattening blocker-family identity.

Pass1219 update: shared-state remediation worklist rows now feed bounded recheck eligibility while preserving prerequisite blocker-family identity for abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, cross-unit, view, generic, state-visibility, fingerprint, multiple, and indeterminate blockers.

Pass1220 note: Editor.Ada_Shared_State_Recheck_Application_Legality applies shared-state recheck eligibility back into the final closure / stabilized diagnostic boundary.  Current shared-state conclusions are exposed only when prerequisite recheck evidence is eligible or already accepted as non-diagnostic current evidence; unresolved cross-unit, view, generic, state-visibility, abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, fingerprint, multiple, and indeterminate blockers remain withheld with their blocker-family identity preserved.

Pass1221 note: added Editor.Ada_Shared_State_Recheck_Convergence_Legality.  The pass consumes shared-state recheck application rows and records whether shared-state semantic evidence converged as current/not-required, stayed stably withheld by its original blocker family, remained indeterminate, or changed relative to a previous application fingerprint.  It preserves shared-state blocker-family identity across abstract/refined state, volatile/atomic/shared-variable, overload/type, representation/freezing, tasking/protected, cross-unit, state-visibility, generic-backmapping, source-fingerprint, stale-eligibility, multiple-prerequisite, and indeterminate evidence.

Pass1222 update: added shared-state stabilization gating for Pass1221 convergence rows, preserving prerequisite blocker families while promoting only stable current shared-state evidence.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.

Pass1224: Added abstract/refined state consumer integration legality. The new package Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality requires abstract/refined-state evidence before Global/Depends, dispatching, generic replay, representation/freezing, tasking/protected, volatile/atomic/shared-variable, cross-unit shared-state, and stabilized shared-state closure consumers may remain confidently accepted. Blocker-family identity is preserved for abstract state, shared state, overload/dispatching, representation/freezing, tasking/protected, cross-unit, stabilized-closure, source-fingerprint, multiple-blocker, and indeterminate cases.
### Pass1225 - Volatile/atomic representation consumer legality

Pass1225 adds `Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality`. It connects volatile/atomic/shared-state legality to representation consumers for volatile full-access objects, atomic components, independent components, representation clauses, record layout, stream and operational attributes, protected/task shared-object representation, and shared-passive layout. It preserves blocker-family identity for volatile/atomic evidence, representation/freezing evidence, abstract-state consumers, stabilized closure, local volatile/atomic representation errors, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225`.


### Pass1226 - Dispatching Global/Depends refinement legality

Pass1226 adds `Editor.Ada_Dispatching_Global_Refinement_Legality`. It connects dispatching-call Global/Depends proof to abstract/refined-state legality, abstract-state consumer integration, overload shared-state evidence, volatile/atomic representation consumer evidence, final flow/contract proof, and shared-state stabilized closure. It preserves blocker-family identity for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global/Depends mismatches, dynamic effect joins, inherited/renamed/generic dispatching effects, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Dispatching_Global_Refinement_Legality_Pass1226`.

Pass1227: Added Editor.Ada_Generic_Abstract_State_Replay_Legality, replaying abstract/refined-state, volatile/atomic, shared-state, and dispatching Global/Depends effects through generic bodies and nested instantiations while preserving source/instance backmapping, formal/actual substitution, shared-state closure, and blocker-family fingerprints.

Pass1228 adds Editor.Ada_Overload_Generic_Shared_State_Final_Legality. It connects final overload shared-state RM evidence with generic abstract-state replay, dispatching Global/Depends refinement, volatile/atomic representation consumers, abstract-state consumers, and stabilized shared-state closure. The pass keeps final overload/type conclusions withheld until matching prerequisite evidence and fingerprints agree.


Pass1229: Representation/generic/shared-state final legality

Adds Editor.Ada_Representation_Generic_Shared_State_Final_Legality. The pass consumes final representation/freezing hard-case evidence, representation/shared-state evidence, generic abstract-state replay, overload/generic shared-state final evidence, volatile/atomic representation consumers, and stabilized shared-state closure before accepting representation/freezing conclusions. It preserves blocker-family identity for final representation, representation/shared-state, generic replay, overload/generic shared state, volatile/atomic representation, stabilized closure, private/full-view freezing, generic formal freezing, stream/operational attributes, variant layout, independent components, task/protected representation, fingerprint mismatches, multiple blockers, and indeterminate states.
Pass1230: Added Editor.Ada_Tasking_Generic_Shared_State_Final_Legality, a tasking/protected generic shared-state final legality layer that consumes deep tasking, tasking shared-state, generic abstract replay, overload/generic shared-state, representation/generic shared-state, abstract-state consumer, and stabilized shared-state closure evidence while preserving blocker-family identity.

Pass1231: Syntax colouring remains a consumer of stabilized cross-unit generic/shared-state semantic evidence and must not perform rendering-side dependency or generic legality checks.

Pass1232 adds elaboration/generic shared-state final legality. The semantic model now withholds elaboration conclusions for dispatching calls, generic instances, generic body replay, representation items, task activation/termination, and partition policy contexts until final elaboration, cross-unit generic/shared-state closure, dispatching Global/Depends, generic abstract-state replay, representation/generic shared-state, and tasking/generic shared-state evidence agree. Blocker-family identity is preserved for downstream semantic consumers.

Pass1233: Added accessibility/generic shared-state final legality, preserving blocker-family identity for accessibility/lifetime conclusions that depend on generic/shared-state closure evidence.

Pass1234: Added Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality to connect discriminant/variant consumer evidence into the generic/shared-state final chain. The pass preserves blocker-family identity for discriminant consumers, cross-unit generic/shared-state closure, elaboration, generic replay, overload, representation/freezing, tasking/protected, accessibility, stabilized shared-state closure, discriminant constraints, variant coverage, aggregate associations, private/full-view mismatches, generic substitution, representation layout, task/protected effects, access-discriminant lifetime, cross-unit consistency, fingerprint mismatches, multiple blockers, and indeterminate states.


Pass1235 does not change syntax colouring. Exception/finalization generic shared-state results remain semantic evidence and diagnostics inputs only when later diagnostic integration consumes them.


Pass1236 keeps renaming/generic/shared-state legality as semantic evidence only; syntax colouring must not infer alias legality from token colouring or rendering state.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.
Pass1240: Added Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality. It consumes generic/shared-state final diagnostic rows and turns blocker-preserving evidence into a deterministic semantic remediation worklist. Accepted rows remain current semantic evidence; blockers become prerequisite work items ordered across stale/fingerprint evidence, definite initialization, dataflow, predicates, generic replay, stabilized shared-state closure, volatile/atomic representation, representation/freezing, tasking/protected, accessibility, discriminants/variants, exception/finalization, renaming/aliasing, multiple blockers, and indeterminate state before downstream re-analysis may trust generic/shared-state conclusions.


### Pass1241 semantic-colouring note

The recheck eligibility layer is analysis-only and does not change the semantic-colouring render path.

### Pass1242 semantic-colouring impact

No rendering-side parsing is added. Current semantic evidence is exposed only after generic/shared-state final recheck eligibility is applied.

Pass1243 adds Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality and Test_Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality_Pass1243. It detects convergence, stable withholding, indeterminate state, and changed application fingerprints for the generic/shared-state final chain while preserving prerequisite blocker-family identity.

Pass1244 adds Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality and Test_Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality_Pass1244. It promotes only stable generic/shared-state final convergence rows, withholds prerequisite blockers with their original family identity, and forces another bounded recheck when convergence fingerprints change.

Pass1245: Generic/shared-state final stabilized closure now promotes only stable accepted generic/shared-state final conclusions into first-class semantic closure evidence. Stable blockers remain explicit closure blockers with blocker-family identity preserved, and recheck-required rows remain non-confident.

Pass1246: overload/generic/shared-state RM edge completion adds semantic coverage for renamed primitive visibility, inherited/private-extension primitive hiding, dispatching abstract-state effects, prefixed-call side-effect contracts, access-to-subprogram effect profiles, generic formal subprogram effects, universal numeric expected-context state ambiguity, and class-wide controlling-result state joins. The pass consumes stabilized generic/shared-state final closure and prior overload/generic shared-state evidence, and preserves blocker-family identity for unresolved prerequisites and fingerprints.

Pass1247: added representation/generic/shared-state RM hard-case completion legality. Volatile/atomic representation clauses, independent component layout, limited/private stream attributes, inherited operational attributes, generic formal/instance freezing, discriminant-dependent layout, controlled/finalized components, and protected/task representation effects are now gated by previous representation evidence, overload RM edge evidence, stabilized generic/shared-state closure evidence, and stable fingerprints before downstream consumers may trust the result.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1249: Added Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality. The pass accepts parser/AST repair only when semantic coverage gates prove that a real generic/shared-state final consumer is blocked, and it preserves blocker-family identity across coverage gates, stabilized closure, overload/type, representation/freezing, tasking/protected, parser-node, structural-AST, token-only, source-span, metadata, consumer-integration, fingerprint, multiple-blocker, and indeterminate cases.


Pass1250 adds cross-unit generic/shared-state RM completion closure legality, consuming prior cross-unit closure plus completed overload, representation/freezing, tasking/protected, and coverage-proven AST repair evidence before accepting dependency-spanning generic/shared-state RM conclusions.


Pass1251 does not add colouring rules; it preserves semantic blocker-family identity for diagnostic/colouring consumers.

## Pass1252

Pass1252 adds accessibility generic/shared-state RM completion legality. It preserves blocker-family identity for access-level, lifetime, completed RM-chain, and coverage-proven AST repair blockers.


Pass1253: exception/finalization generic/shared-state RM completion legality consumes completed RM prerequisites and preserves blocker-family identity.

Pass1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.

Pass1255 adds Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality. It completes dataflow/initialization legality over the completed generic/shared-state RM chain by requiring prior dataflow, cross-unit RM completion, elaboration, accessibility, exception/finalization, predicate/invariant, overload, representation, tasking, and coverage-proven AST repair evidence to agree before dataflow conclusions are accepted.


Pass1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.
Pass1261 adds Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality, which consumes Pass1260 RM-completion recheck application rows and classifies current, not-required, stably withheld, indeterminate, and changed generic/shared-state RM-completion conclusions while preserving blocker-family identity.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Pass1263 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality. Stable RM-completion rows from the generic/shared-state stabilization gate now become first-class closure evidence, while blocked rows remain closure blockers with the original blocker-family identity preserved.

Pass1264: Added overload RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before overload/type RM edge conclusions may be trusted, while preserving blocker-family identity for closure, overload, cross-unit, representation, tasking, elaboration, accessibility, dataflow, and fingerprint blockers.
\nPass1265: Added representation RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before representation/freezing RM hard-case conclusions may be trusted, while preserving blocker-family identity for closure, representation, cross-unit, overload/type, tasking, elaboration, accessibility, dataflow, and fingerprint blockers.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.

Pass1267: Dataflow RM-completion closure consumer legality now requires stabilized generic/shared-state RM-completion closure evidence before dataflow/initialization RM-completion conclusions are considered current. Blocker-family identity is preserved for closure, dataflow, cross-unit, generic substitution, overload/type, representation/freezing, tasking/protected, elaboration, accessibility, predicates/invariants, multiple prerequisites, and indeterminate states.

Live semantic diagnostic update: expected-type context production now covers syntax-owned declaration defaults, simple assignments, and ordinary return statements, not only call-resolution rows. Return statement action nodes are typed as expression inputs, allowing assignment and return legality to feed live semantic diagnostics for non-call return mismatches while preserving snapshot ownership and keeping rendering projection-only.
