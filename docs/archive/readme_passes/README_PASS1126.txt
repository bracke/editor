Pass1126 — Ada overload preference legality

This pass adds Editor.Ada_Overload_Preference_Legality, a deterministic snapshot-owned semantic layer that deepens overload resolution after the existing broad overload legality model.

The new layer consumes Editor.Ada_Overload_Resolution_Legality rows and semantic preference contexts. It classifies Ada-specific preference ordering across direct/use visibility tiers, exact profile evidence, expected-type/profile evidence, primitive operator evidence, dispatching primitive evidence, universal integer and universal real preferences, implicit conversion preferences, class-wide conversion preference, access conversion preference, named actual/profile evidence, and defaulted-formal evidence.

It also preserves ambiguity when preferences do not select a unique interpretation: homograph ties, visibility ties, profile ties, expected-type ties, universal numeric ties, conversion ties, and remaining ambiguity after RM preference ordering are distinct statuses. Existing overload legality failures are preserved as linked blockers instead of being hidden by preference refinement.

The package provides deterministic counters, node/status/kind/designator lookups, row identity, linked overload status, source fingerprints, overload fingerprints, and model fingerprints. It performs no parsing, file IO, save/reload, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP integration, external parser generation, Python integration, or shell-script integration.

AUnit regression added:
- Test_Ada_Overload_Preference_Legality_Pass1126

This pass adds one compiler-grade building block for Ada overload resolution precision. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
