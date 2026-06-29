# Strict runtime validation record

Final runtime release validation is not complete until the strict runtime gates
have been run on a machine with the required Ada, GLFW, Vulkan, display, shader,
and runtime dependencies. Source-only structural checks are useful, but they do
not prove the graphical runtime.

Use the reporting driver when producing release evidence:

```sh
tools/bin/strict_runtime_validation_record
```

The validation driver forces the same strict gates as `tools/bin/strict_runtime_validation`:

- `EDITOR_REQUIRE_RUNTIME_COMPILE=1` for the runtime entrypoint/backend gate;
- `EDITOR_REQUIRE_RUNTIME_LINK=1` for the runtime build/link gate;
- `EDITOR_REQUIRE_RUNTIME_EXE=1` for the canonical `bin/editor` executable;
- `EDITOR_REQUIRE_SHADER_FRESHNESS=1` for byte-for-byte shader freshness;
- `EDITOR_REQUIRE_RUNTIME_SMOKE=1` for graphical GLFW/Vulkan launch/render/resize smoke;
- `EDITOR_REQUIRE_RUNTIME_MISSING_ASSET=1` for the missing-shader negative gate.

It records the platform, relevant environment variables, toolchain versions, and
per-gate output under:

```text
build/release-validation/
```

Set a custom output directory with:

```sh
EDITOR_RUNTIME_VALIDATION_REPORT_DIR=/path/to/reports \
  tools/bin/strict_runtime_validation_record
```

Generated reports are release-validation artifacts. They are intentionally not
part of the normal release source archive unless the release process separately
collects signed validation evidence.

## Minimum pass criteria

A completed report must show PASS for all of these gates:

1. Runtime C entrypoint/Ada backend check.
2. Runtime link/build check.
3. Canonical executable production: `bin/editor`.
4. Shader freshness check.
5. Graphical runtime smoke, including multi-resize, zero-framebuffer restore,
   and font-atlas dirty/upload/cache-hit validation.
6. Display-independent missing-shader negative check.

If any gate is skipped, the report is not a final release runtime validation
record. Skips are acceptable only for ordinary source-tree structural checks, not
for final runtime release approval.


Strict runtime validation record note: `tools/bin/strict_runtime_validation_record` captures bounded per-gate command output and toolchain probe output into `build/release-validation/strict-runtime-validation.md`; console-only PASS/FAIL records are not sufficient final runtime evidence.


Strict runtime preflight: final runtime validation includes the Ada `tools/bin/strict_runtime_preflight` gate before compile/link/smoke execution. In non-strict structural checks it reports missing runtime-machine requirements without failing; with `EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT=1` it fails if required tools or environment are missing. The preflight checks for `gcc`, an Ada build tool (`alr` or `gprbuild`), `glslangValidator`, a graphical session (`DISPLAY` or `WAYLAND_DISPLAY`), required runtime sources, shader binaries, and the shader toolchain manifest. `vulkaninfo` is reported as optional diagnostic context; the graphical smoke remains the authoritative Vulkan runtime gate.

## Final evidence consumption

`tools/bin/final_release_validation_check` consumes this report together with
`build/release-validation/release-check-validation.md`. The final evidence gate
requires the strict runtime report to contain:

```text
PASS: strict runtime validation completed successfully.
```

and rejects reports containing failed, missing-tool, or nonzero gate result
markers. Enable the final gate through:

```text
EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1 tools/bin/release_check
```

Pass935 parser-only validation guard: subprogram contract/aspect placement depth is covered by token-cursor AUnit registration and documentation updates. This guard is structural parser metadata only and adds no runtime validation gate, compiler-semantic query, LSP integration, rendering-side parsing, background scan, or dirty-state mutation.
Pass936 parser-only validation guard: subprogram contract/aspect value-family depth is covered by token-cursor AUnit registration and documentation updates. This guard is structural parser metadata only and adds no runtime validation gate, compiler-semantic query, LSP integration, rendering-side parsing, background scan, or dirty-state mutation.
Pass941 parser-only validation guard: protected entry-body missing-barrier recovery is covered by token-cursor AUnit registration and documentation updates. This guard is structural parser metadata only and adds no runtime validation gate, compiler-semantic query, LSP integration, rendering-side parsing, background scan, or dirty-state mutation.

## Pass943 declarative-region validation marker

Pass943 adds `Test_Ada_Declarative_Region_Model_Foundation_Pass943`, which exercises the new parser-owned declarative-region model across generic formal parts, package specs, package bodies, nested subprogram bodies, protected bodies, and protected entry bodies. The marker ensures region identity, parentage, child-region retention, and deterministic fingerprints remain visible to later compiler-grade semantic passes.

## Pass945

Added `Editor.Ada_Use_Visibility` as a snapshot-derived semantic model. It reads
only the parser-owned syntax tree plus declarative-region/direct-visibility
models, mutates no editor dirty state, performs no renderer parsing, and adds no
compiler/LSP/background-scan dependency.

Phase 579 pass947: added deterministic use-type primitive visibility model (`Editor.Ada_Use_Type_Operators`) and AUnit regression coverage for primitive operator candidates exposed by `use type` / `use all type`.  The pass preserves snapshot-owned analysis and does not introduce renderer-side parsing, compiler invocation, LSP, file mutation, or dirty-state mutation.
Phase 579 pass948: added deterministic call-candidate overload foundation (`Editor.Ada_Call_Candidates`) and AUnit regression coverage for direct/use-package/use-type candidate lookup.  The pass preserves snapshot-owned analysis and does not introduce renderer-side parsing, compiler invocation, LSP, file mutation, dirty-state mutation, or background project scans.

- Phase 579 pass949 records a compiler-grade overload-resolution foundation in `Editor.Ada_Call_Profile_Shapes`.  The validation marker is `Test_Ada_Call_Profile_Shape_Foundation_Pass949`, covering callable profile arity/result extraction and actual positional/named argument shape extraction without compiler invocation, LSP integration, render-side parsing, background scans, or dirty-state mutation.

- Phase 579 pass950 records a compiler-grade overload-resolution foundation in `Editor.Ada_Call_Profile_Filters`.  The validation marker is `Test_Ada_Call_Profile_Filter_Foundation_Pass950`, covering deterministic arity filtering, too-many-actual rejection, named-actual classification, and fingerprints without compiler invocation, LSP integration, render-side parsing, background scans, or dirty-state mutation.

- Phase 579 pass951 records a compiler-grade overload-resolution foundation in `Editor.Ada_Call_Profile_Shapes` and `Editor.Ada_Call_Profile_Filters`. The validation marker is `Test_Ada_Call_Profile_Formal_Name_Filter_Pass951`, covering formal-name matching, unknown named actual rejection, defaulted-formal metadata, missing required formals, and deterministic fingerprints without compiler invocation, LSP integration, render-side parsing, background scans, or dirty-state mutation.
- Phase 579 pass952 records a compiler-grade overload-resolution staging layer in `Editor.Ada_Call_Resolution`. The validation marker is `Test_Ada_Call_Resolution_Profile_Result_Pass952`, covering unique matches, rejected profile-filter sets, unresolved names, pre-profile ambiguity, and deterministic fingerprints without compiler invocation, LSP integration, render-side parsing, background scans, or dirty-state mutation.


### Pass953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.

- Phase 579 pass954 records a compiler-grade overload-resolution building block in `Editor.Ada_Expected_Call_Filters`. The validation marker is `Test_Ada_Expected_Call_Filter_Foundation_Pass954`, covering expected-subtype match/mismatch classification for unique-profile call results while preserving snapshot ownership and avoiding compiler invocation, LSP integration, render-side parsing, background scans, file mutation, and dirty-state mutation.

- Phase 579 pass955 records the first conservative subtype-compatibility foundation in `Editor.Ada_Subtype_Compatibility`. The validation marker is `Test_Ada_Subtype_Compatibility_Foundation_Pass955`, covering exact subtype matches, universal numeric compatibility, known numeric-family mismatches, indeterminate user-defined relationships, deterministic fingerprints, and preservation of editor invariants.
- Phase 579 pass956 records the declaration-derived type graph foundation in `Editor.Ada_Type_Graph`. The validation marker is `Test_Ada_Type_Graph_Foundation_Pass956`, covering type/subtype retention, derived parent resolution through direct visibility, unresolved parent preservation, ancestry compatibility, deterministic fingerprints, and preservation of editor invariants.

- Phase 579 pass957 records declaration-derived type-graph compatibility integration for expected-call filtering. The validation marker is `Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility_Pass957`, covering derived/subtype result compatibility, known-different-root mismatch metadata, deterministic fingerprints, and preservation of editor invariants.

Pass958 validation note: added compiler-grade type-system metadata for private/full views, interface declarations, and class-wide expected-call compatibility. The pass remains snapshot-owned and does not introduce LSP, compiler invocation, external parsers, renderer parsing, background project scans, or dirty-state mutation.
Pass959 validation note: added compiler-grade implicit-conversion metadata for expected-call filtering. The pass remains snapshot-owned and does not introduce LSP, compiler invocation, external parsers, renderer parsing, background project scans, or dirty-state mutation.

Pass960 validation note: added snapshot-owned static-expression evaluation metadata for named numbers and static constants. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.


Pass961 validation note: extended snapshot-owned static-expression metadata with scalar subtype bounds and bounded static attribute evaluation. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.

Pass963 validation note: extended snapshot-owned static-expression metadata with modular type modulus staging and deterministic static modular reduction. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.

Pass964 validation note: extended snapshot-owned static-expression metadata with real/universal numeric static values and deterministic numeric evaluation. The pass preserves integer-only evaluation boundaries and does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.

Pass965 validation note: extended snapshot-owned static-expression metadata with fixed-point type staging and deterministic fixed-value quantization statuses. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.

Pass966 validation note: added snapshot-owned generic contract metadata for formal declarations and instantiation actual shapes. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.
Pass967 validation note: extended generic contract metadata with deterministic formal/actual matching records for staged generic instantiations. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.

Pass968 validation note: extended generic contract metadata with deterministic formal/actual kind conformance and mismatch records for staged generic instantiations. The pass does not introduce compiler invocation, LSP, external parsers, renderer parsing, background scans, file reloads/saves, or dirty-state mutation.


### Pass969 - generic formal subprogram profile conformance

Pass969 extends `Editor.Ada_Generic_Contracts` with formal subprogram profile conformance metadata. Generic formal subprograms now retain parameter-count, normalized parameter-subtype shape, result presence, and result-subtype metadata. Generic instantiation actuals retain positional/named actual designator text, allowing declaration-shaped subprogram actuals to be resolved through direct visibility and compared against the formal profile. The match model now distinguishes formal-kind mismatches from formal subprogram profile mismatches and records deterministic compatible/mismatched/unknown profile counts. Regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`. This is a compiler-grade generic-contract building block; full Ada generic conformance still requires overload-aware subprogram actual selection, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass970 - generic formal package contract conformance

Pass970 extends `Editor.Ada_Generic_Contracts` with formal package contract conformance metadata. Generic formal package records now retain their expected target generic name, normalized target, and box actual-state marker. Generic instantiation matching resolves package actuals through direct visibility, recognizes inline `new Generic (...)` package actuals, verifies that declaration-shaped package actuals are package instantiations, and compares the actual package instance target generic against the formal package contract. The match model now distinguishes formal package contract mismatches and unknown formal package contract cases, including unresolved actuals, ambiguous actuals, non-instance package actuals, wrong-generic package instances, unknown formal contracts, and malformed package actuals, with deterministic compatible/mismatched/unknown counters exposed through `Formal_Package_Compatible_Count_For_Instance`, `Formal_Package_Mismatch_Count_For_Instance`, and `Formal_Package_Unknown_Count_For_Instance`. Regression coverage is in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`. This pass adds one compiler-grade generic-contract building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, and cross-unit semantic closure are fully integrated.

- Phase 579 pass973 recorded invariant: generic default-expression legality is model metadata only; no render, command, workspace, file-save, reload, or dirty-state mutation path is introduced.
\nPass974: Generic-contract analysis now retains formal subprogram parameter mode vectors and classifies declaration-shaped subprogram actuals with same arity/subtypes but nonconforming modes as deterministic mode mismatches. Regression coverage: Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974.

Pass995: cross-unit closure validation entry added. The closure model stages spec/body, child/parent, parent/child, and separate-body relationships from the project index with explicit status metadata and no external parser/compiler dependency.

Pass1032 note: added Editor.Ada_Operational_Attribute_Rules as a compiler-grade operational representation building block. It consumes unified representation legality metadata after aspect/attribute-definition normalization, classifies duplicate operational properties, contradictory Boolean values, propagated target/value errors, and exposes deterministic counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1152 record: repaired coverage feedback separates structurally restored, metadata-restored, consumer-restored, cross-unit-required, stale, partial, mismatched, indeterminate, and original-error rows before widened legality consumers accept repaired constructs.

Pass1153 update: Refined_Global / Refined_Depends body/spec conformance is represented as a deterministic semantic legality layer consuming flow-effect graph rows and repaired coverage feedback.

Pass1154 update: Refined_Global / Refined_Depends body-spec conformance now feeds integrated semantic closure as a first-class blocker family. Legal refined conformance remains confident local closure; missing Global coverage, invalid Refined_Depends edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers are exposed through integrated closure.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
