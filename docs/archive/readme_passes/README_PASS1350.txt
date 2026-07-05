Pass1350 — RM Gap Burn-Down Pass 8

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1350.

The pass burns down the subtype / constraint / static expression / static choice / predicate composition gap.  It is intentionally source-shaped and gap-driven: it does not add another projection, lifecycle, or status wrapper.

The new gate enforces one canonical semantic result across:

* scalar, discrete, modular, floating, fixed-point, array-index, and discriminant constraints;
* named numbers, static constants, universal integer/real resolution, qualified static expressions, static attributes, static arithmetic, divide-by-zero, and exponent naturalness;
* case, case-expression, variant, aggregate, index, discriminant, and membership choices;
* overlapping choices, incomplete coverage, duplicate others, and invalid others placement;
* Static_Predicate staticness and static predicate failure;
* Dynamic_Predicate, range, bounds, membership, and predicate runtime-check preservation;
* aggregate static-choice consumption;
* assignment/conversion range and predicate consumption;
* loop/iterator discrete subtype consumption;
* representation/layout static position consumption;
* private, limited, incomplete, generic-formal, missing-full-view, missing-cross-unit, missing-static-evidence, and missing-type-evidence indeterminate states;
* semantic consumer agreement for diagnostics, hover/details, semantic colouring, outline/navigation-style consumers, and build diagnostic bridge evidence;
* source, AST, type, static, choice, predicate, profile, substitution, effect, and consumer fingerprint freshness.

Added tests:

* Test_Ada_RM_Gap_Burn_Down_Pass1350

The tests cover balanced legal, illegal, legal-with-runtime-check, and indeterminate scenarios; concrete subtype/static-expression blockers; choice/predicate/runtime/cross-slice blockers; consumer disagreement; audit-gate failures; stale evidence; and fingerprint mismatches.

Core_Suite registers the new AUnit test case.
