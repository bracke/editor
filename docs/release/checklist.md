
## case 948 — call-candidate overload foundation guard

- `Editor.Ada_Call_Candidates` must remain parser/snapshot owned and must not read files, invoke compilers, call LSP, mutate buffers, or perform renderer-side parsing.
- Call-candidate lookup must combine direct visibility, package-use visibility, and use-type primitive visibility deterministically.
- `Test_Ada_Call_Candidate_Foundation_Case 948` guards found, unresolved, and primitive-candidate metadata.
- This pass is a compiler-grade overload-resolution building block, not the completed overload/type/profile legality engine.


### Case 953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.


- Case 977: verify generic formal subprogram calling-convention conformance remains deterministic and reports convention mismatches separately from profile, mode, null-exclusion, and access-profile mismatches.
- Case 978: verify generic formal subprogram defaulted-parameter conformance remains deterministic and reports default mismatches separately from profile, mode, null-exclusion, access-profile, convention, overload, and type-graph mismatches.
Case 986: added record representation component-clause legality coverage, including component resolution, duplicate detection, static storage/bit-range evaluation, and reversed/negative position classification.

- Case 995: verify `Editor.Ada_Cross_Unit_Closure` remains deterministic, bounded, and project-index-owned for spec/body, child/parent, parent/child, and separate-body parent links.

Case 1003: expression aggregate context inference extends the Ada expression-type model with context-sensitive aggregate/container-aggregate metadata, component-shape counters, and deterministic unknown/mismatch states for later diagnostics.

- Case 1035: generic formal package nested actual conformance metadata and AUnit coverage added.
- Case 1036: generic renaming and nested generic instantiation visibility metadata and AUnit coverage added.
- Case 1037: generic object default-expression type conformance metadata and AUnit coverage added.

Case 1040: Added representation/freezing diagnostics projection through Editor.Ada_Representation_Diagnostics, covering representation legality, record layout, storage order, operational attributes, aspect inheritance, and freezing interaction metadata with deterministic spans/severities/fingerprints.

Case 1041: Added semantic-colouring diagnostics projection for expression, generic-contract, cross-unit, and representation/freezing diagnostics using render-safe deterministic overlay metadata.

Case 1042: Added stale-analysis guard for semantic diagnostic overlays using path, buffer token, revision, lifecycle generation, request token, and analysis fingerprint validation.

Case 1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Case 1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

- Case 1098: Validate final recovery-render lifecycle status projection, stale-input withholding, rejected-row accounting, deterministic summaries, and no mutation leaks.

Case 1099 note: Added `Editor.Ada_Assignment_Legality` as a semantic rule-completion pass for assignment and object-initialization legality.  The pass is snapshot-owned and projection-free: it consumes existing expression, subtype, static, type/view metadata and classifies target/source compatibility, constant/in-formal target errors, null-exclusion violations, static range violations, private/limited view barriers, unresolved universal numeric cases, and indeterminate cases without render-side parsing or editor mutation.

Case 1100 note: added `Editor.Ada_Return_Legality`, a snapshot-owned semantic legality layer for Ada return statements. It consumes assignment/object-initialization legality results and classifies legal procedure/function/extended returns plus illegal expression shape, incompatible result subtype, private/limited view barriers, unresolved result metadata, static range violations, unresolved universal numeric returns, and No_Return subprogram return statements. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, or mutable IDE-surface side effect is introduced.

Case 1101 note: widened the semantic pass scope by adding `Editor.Ada_Conversion_Access_Aggregate_Legality`, a snapshot-owned semantic legality layer covering conversion and qualified-expression legality, numeric/static range conversion checks, tagged/class-wide conversion classification, access/null-exclusion/accessibility foundations, allocator designated-subtype compatibility, aggregate structural legality, and container aggregate missing-aspect classification. Added `Test_Ada_Conversion_Access_Aggregate_Legality_Case 1101` and registered it in `Core_Suite`. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation is introduced.

Case 1102: Added `Editor.Ada_Control_Flow_Legality`, a wide snapshot-owned semantic legality layer for Ada control-flow and statement rules.  The pass classifies Boolean condition legality, case choice staticness/coverage/duplicates, exit/goto/label target legality, exception handler choices, raise targets, select/accept/requeue target checks, and return-path completeness without render-side parsing or editor mutation.

Case 1103 update: added `Editor.Ada_Tasking_Protected_Legality`, a snapshot-owned semantic legality layer for Ada task/protected type and body matching, entry declarations/bodies/families, protected barriers, accept/requeue legality, protected operation restrictions, select integration, and linked control-flow legality propagation. Added and registered `Test_Ada_Tasking_Protected_Legality_Case 1103`. No diagnostic projection chain, rendering-side parsing, file save/reload, dirty-state mutation, or command/keybinding/workspace/render mutation is introduced.

- Case 1104: verify `Editor.Ada_Tagged_Derived_Legality` preserves snapshot-owned tagged/derived/private/interface legality analysis, deterministic counters/lookups/fingerprints, and no projection-chain or IDE-mutation side effects.

- Case 1105: Confirm widened semantic legality coverage for generic instance body substitutions, formal package substitutions, instance freezing, and representation-after-freezing effects.

- Case 1106: Confirm widened semantic legality coverage for cross-unit dependency/lookup closure into assignment, return, expression, control-flow, tasking, tagged, generic-instance, and representation consumers.

Case 1107: wide semantic legality diagnostics bridge added for Case 1099-Case 1106 compiler-grade legality layers, preserving snapshot ownership and deterministic fingerprints.

Case 1108 update:
- Integrated the Case 1107 wide semantic legality diagnostics into the unified snapshot-guarded semantic diagnostic feed via Build_With_Wide_Legality.
- Wide assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and cross-unit legality failures now participate in the normal diagnostic feed and index.
- Stale wide legality inputs and rejected base semantic guards expose zero active feed rows while preserving rejected-entry accounting.
- Added AUnit coverage in Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Case 1108 and registered it in Ada_Language_Suite.

Case 1109 update: added Editor.Ada_Overload_Resolution_Legality as a compiler-grade overload/operator legality building block. It classifies exact and preference-based selections, expected-type and universal numeric preferences, primitive operator preference, implicit/class-wide/access conversion evidence, named/defaulted profile evidence, visibility failures, view barriers, cross-unit unresolved states, linked semantic errors, ambiguity, unknown, and indeterminate states. The layer is snapshot-owned and deterministic, with AUnit coverage in Test_Ada_Overload_Resolution_Legality_Case 1109.

Case 1110: added Editor.Ada_Staticness_Range_Predicate_Legality, a snapshot-owned semantic legality layer for Ada staticness requirements, range/choice legality, predicate metadata, linked assignment/return/conversion/access/aggregate/overload legality, deterministic lookup helpers, counters, and fingerprints. No diagnostic UI projection chain, rendering-side parser, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration is introduced.

Case 1111 update: added `Editor.Ada_Accessibility_Lifetime_Legality`, a widened snapshot-owned Ada accessibility/lifetime/aliasing legality layer covering accessibility levels, dynamic checks, null exclusion, access kind mismatches, aliased-object requirements, allocator/access-conversion/return-accessibility checks, anonymous access parameter escapes, access discriminant lifetime checks, dangling renaming risk metadata, and linked assignment/return/conversion/staticness failures. Added and registered `Test_Ada_Accessibility_Lifetime_Legality_Case 1111`.


- Case 1112: contract/aspect legality layer added and covered by AUnit regression.


- Case 1113: review elaboration/dependence legality diagnostics and ensure no render-side parsing or workspace mutation is introduced.


Case 1114: Added Editor.Ada_Unit_Completion_Order_Legality for compiler-grade unit/body completion and declaration-order legality, including package/subprogram/task/protected/generic body completion, private/deferred/incomplete completion, body-stub/separate-body completion, declaration-before-use, private-part ordering, frozen-before-completion, view barriers, and linked semantic blockers. Added AUnit coverage and deterministic counters/lookups/fingerprints.

Case 1115 update: added Editor.Ada_Renaming_Alias_Visibility_Legality as a widened semantic legality layer for Ada renaming declarations, alias views, direct/use/use-type visibility, selected-name targets, homograph hiding, private/limited-view barriers, aliased-target requirements, self/circular renames, dangling rename risks, invalid/duplicate use clauses, and linked accessibility/overload/cross-unit/completion blockers. Added and registered Test_Ada_Renaming_Alias_Visibility_Legality_Case 1115. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Case 1116 update: added Editor.Ada_Exception_Finalization_Legality as a widened semantic legality layer for Ada exception, raise, handler, propagation, cleanup/finalization, task termination, controlled primitive, and No_Return contexts. It consumes control-flow, accessibility/lifetime, contract/aspect, elaboration/dependence, renaming/visibility, and unit completion/order legality metadata; classifies legal raise/reraise/handler/renaming/propagation/finalization/No_Return cases; and reports unresolved/ambiguous/non-exception raise targets, reraise outside handlers, handler choice errors, raise-expression result issues, invalid exception renaming targets, controlled finalization primitive/profile/order/propagation/abort/master errors, No_Return violations, private/limited view barriers, and linked semantic blockers. Added and registered Test_Ada_Exception_Finalization_Legality_Case 1116. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Case 1117 update: added Editor.Ada_Representation_Layout_Stream_Integration_Legality. The pass integrates representation legality, exact record layout, stream attribute profile conformance, generic-instance freezing/representation effects, accessibility/lifetime, staticness/range/predicate, completion/order, contract/aspect, and exception/finalization legality into one deterministic snapshot-owned semantic model. It adds Test_Ada_Representation_Layout_Stream_Integration_Legality_Case 1117 and keeps the analysis non-mutating, bounded, and independent of rendering, command, keybinding, workspace, save/reload, file IO, compiler invocation, LSP, and external parser generators.

Case 1118 update: added Editor.Ada_Integrated_Semantic_Closure as a widened semantic closure layer. It folds wide semantic legality diagnostics with overload, staticness/range/predicate, accessibility/lifetime, contract/aspect, elaboration/dependence, unit completion/order, renaming/alias/visibility, exception/finalization, and representation/layout/stream integration blockers into one deterministic snapshot-owned closure model. It classifies local/cross-unit/with-use legal closure, limited/private-view barriers, missing/ambiguous/overflow/stale/rejected dependencies, individual legality blockers, multiple blockers, and indeterminate closure. Added and registered Test_Ada_Integrated_Semantic_Closure_Case 1118 with counters, lookups, and fingerprints. The pass remains non-mutating and introduces no rendering-side parser, save/reload path, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

Case 1119 update:
- Integrated semantic closure diagnostics now flow into the unified snapshot-guarded semantic diagnostic feed through Build_With_Integrated_Closure.
- Non-legal integrated closure rows become indexed semantic diagnostics; legal closure rows remain non-diagnostic.
- Stale integrated closure inputs and rejected base diagnostic guards expose zero active rows while preserving rejected-entry totals.
- This is a semantic integration pass, not a UI projection-chain extension.

Case 1120: Added integrated semantic closure provenance in `Editor.Ada_Diagnostic_Provenance`. Indexed diagnostics from `Editor.Ada_Integrated_Semantic_Closure` now retain explainable links to closure status, blocker family, dependency state, fingerprints, and diagnostic/index identity. The pass is deterministic, bounded, snapshot-owned, and non-mutating.

Case 1121 update: added `Editor.Ada_Definite_Initialization_Flow_Legality` with snapshot-owned definite-initialization and flow-sensitive object-state legality for read-before-write, component coverage, out-parameter obligations, return-object initialization, branch/loop merge failures, exception/finalization initialization effects, and linked semantic blockers. Regression: `Test_Ada_Definite_Initialization_Flow_Legality_Case 1121`.

Case 1123 update: Global/Depends dataflow legality now consumes contract flow facts and definite-initialization object-state facts, with failures entering integrated semantic closure and unified diagnostics/provenance. Regression: `Test_Ada_Dataflow_Global_Depends_Legality_Case 1123`.

Case 1131 update: representation/freezing precision now connects explicit representation items, implicit semantic-use freezing, private/full-view timing, generic-instance freezing effects, representation/layout/stream integration, elaboration precision, and tasking/protected precision through `Editor.Ada_Representation_Freezing_Precision_Legality` with AUnit coverage.

Case 1141: Added RM-grade overload edge legality for universal numeric/fixed/root preference, inherited primitive hiding, dispatching/nondispatching ambiguity, access-to-subprogram profiles, generic formal subprograms, nested generic overload ambiguity, and preservation of generic replay / coverage-gate blockers.

Case 1153 update: Refined_Global / Refined_Depends conformance now consumes flow-effect graph rows and repaired coverage feedback before accepting body/spec flow-contract conclusions. Body reads/writes, refined Global coverage, refined Depends edges, call propagation, linked flow errors, and repaired coverage blockers are represented as deterministic semantic legality rows.

Case 1154 update: Refined_Global / Refined_Depends body-spec conformance now feeds integrated semantic closure as a first-class blocker family. Legal refined conformance remains confident local closure; missing Global coverage, invalid Refined_Depends edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers are exposed through integrated closure.


- Case 1191: include final representation/freezing hard-case blocker-family preservation in release checks.

### Case 1194 final semantic diagnostic integration

Case 1194 adds blocker-preserving final semantic diagnostic integration. It consumes final semantic closure and consumer evidence, withholds legal rows as non-diagnostics, and keeps stale, AST repair, coverage-gate, view-barrier, indeterminate, and multiple-blocker states distinct. It does not add UI projection, render parsing, command routing, keybinding routing, workspace mutation, or file lifecycle mutation.

Case 1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Case 1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Case 1220 note: shared-state recheck application now gates current shared-state conclusions on eligible prerequisite evidence or explicitly current non-diagnostic stabilized evidence.  Dependency, view, generic, state-visibility, abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, fingerprint, multiple, and indeterminate blockers stay withheld with blocker-family identity preserved.

Case 1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.
### Case 1225 - Volatile/atomic representation consumer legality

Case 1225 adds `Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality`. It connects volatile/atomic/shared-state legality to representation consumers for volatile full-access objects, atomic components, independent components, representation clauses, record layout, stream and operational attributes, protected/task shared-object representation, and shared-passive layout. It preserves blocker-family identity for volatile/atomic evidence, representation/freezing evidence, abstract-state consumers, stabilized closure, local volatile/atomic representation errors, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Case 1225`.


### Case 1226 - Dispatching Global/Depends refinement legality

Case 1226 adds `Editor.Ada_Dispatching_Global_Refinement_Legality`. It connects dispatching-call Global/Depends proof to abstract/refined-state legality, abstract-state consumer integration, overload shared-state evidence, volatile/atomic representation consumer evidence, final flow/contract proof, and shared-state stabilized closure. It preserves blocker-family identity for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global/Depends mismatches, dynamic effect joins, inherited/renamed/generic dispatching effects, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Dispatching_Global_Refinement_Legality_Case 1226`.

Case 1227: Added generic abstract/refined-state replay legality for generic bodies and nested instantiations, preserving source/instance backmapping, formal/actual substitution, shared-state closure, and blocker-family identity.


Case 1229: Representation/generic/shared-state final legality

Adds Editor.Ada_Representation_Generic_Shared_State_Final_Legality. The pass consumes final representation/freezing hard-case evidence, representation/shared-state evidence, generic abstract-state replay, overload/generic shared-state final evidence, volatile/atomic representation consumers, and stabilized shared-state closure before accepting representation/freezing conclusions. It preserves blocker-family identity for final representation, representation/shared-state, generic replay, overload/generic shared state, volatile/atomic representation, stabilized closure, private/full-view freezing, generic formal freezing, stream/operational attributes, variant layout, independent components, task/protected representation, fingerprint mismatches, multiple blockers, and indeterminate states.
Case 1230: Added Editor.Ada_Tasking_Generic_Shared_State_Final_Legality, a tasking/protected generic shared-state final legality layer that consumes deep tasking, tasking shared-state, generic abstract replay, overload/generic shared-state, representation/generic shared-state, abstract-state consumer, and stabilized shared-state closure evidence while preserving blocker-family identity.

Case 1231: Confirm cross-unit generic/shared-state final closure keeps dependency, view, generic-backmapping, overload, representation, tasking, abstract-state, stabilized-closure, fingerprint, multiple-blocker, and indeterminate blocker families distinct.


### Case 1241 release checklist item

Confirm generic/shared-state final recheck eligibility preserves blocker-family identity and deterministic fingerprints.

Case 1246: overload/generic/shared-state RM edge completion adds semantic coverage for renamed primitive visibility, inherited/private-extension primitive hiding, dispatching abstract-state effects, prefixed-call side-effect contracts, access-to-subprogram effect profiles, generic formal subprogram effects, universal numeric expected-context state ambiguity, and class-wide controlling-result state joins. The pass consumes stabilized generic/shared-state final closure and prior overload/generic shared-state evidence, and preserves blocker-family identity for unresolved prerequisites and fingerprints.


Case 1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Case 1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Case 1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
