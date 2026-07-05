Pass 537 - Freezing-rule interaction refinement

Implemented a follow-up pass for Ada representation/freezing legality in the retained language model.

Code changes:
- Added clause-independent freezing-point index construction in Editor.Ada_Declaration_Parser.
- Freezing points are now retained even when the representation clause itself is legal and appears before the freeze.
- Late representation diagnostics now first consult retained freezing-point metadata, preserving the trigger symbol/range/reason instead of rediscovering only diagnostic cases.
- Refined body/spec completion handling so unrelated package/subprogram bodies are not treated as freezing every previously declared representation target.
- Refined generic instantiation handling so an instance freezes only targets referenced by retained profile/target/generic-actual metadata, rather than every preceding entity.

Regression coverage:
- Added a legality regression for retained freezing metadata after a legal representation clause followed by a later object use.
- Added a regression guard that an unrelated body completion before a representation clause does not produce a false late-representation diagnostic.

Bounded scope:
- This remains a retained IDE-grade semantic model, not a full Ada compiler freezing implementation.
- It now has a better internal freezing index for diagnostics/navigation and fewer broad false positives around body and generic-instance triggers.
