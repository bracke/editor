Phase 579 pass972 — Overload-aware generic subprogram actual selection

This pass adds one compiler-grade building block for generic formal subprogram conformance.  `Editor.Ada_Generic_Contracts` now resolves overloaded subprogram actual designators against the expected formal subprogram profile instead of treating an ambiguous visible declaration name as unknown.

Implemented changes:

* Added profile-driven overload candidate enumeration for generic subprogram actuals.
* Searches the directly visible declaration set at the instantiation region and then enclosing regions, preserving Ada hiding order.
* Counts subprogram overload candidates, selected conforming overloads, ambiguous conforming overloads, and unresolved overload sets.
* Distinguishes profile mismatch from profile ambiguity with `Generic_Actual_Match_Formal_Subprogram_Profile_Ambiguous`.
* Keeps existing formal type substitution in profiles, so `Element` can be matched against the instance actual such as `Integer` or `String`.
* Added public deterministic counters:
  - `Subprogram_Profile_Overload_Selected_Count_For_Instance`
  - `Subprogram_Profile_Overload_Ambiguous_Count_For_Instance`
  - `Subprogram_Profile_Overload_Unresolved_Count_For_Instance`
* Added AUnit regression `Test_Ada_Generic_Formal_Subprogram_Overload_Selection_Pass972`.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as default-expression legality, private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and complete profile conformance are fully integrated.
