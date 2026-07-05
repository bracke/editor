Pass1349 - RM Gap Burn-Down Pass 7

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1349 and its AUnit suite.

The pass burns down the name / visibility / attribute / selector resolution gap by forcing direct visibility, selected names, expanded names, child/private-child visibility, use-package/use-type visibility, selector legality, attribute prefix/result/staticness, dereference, array/generalized indexing, overload-fed resolution, callable-profile agreement, private/limited/incomplete views, runtime-check preservation, and semantic consumers to agree on one canonical source-shaped result.

The new model rejects private-child visibility leaks, noncanonical selected-name resolution, ambiguous selectors, use-visible homographs outside overloadable contexts, wrong attribute prefixes, missing static attribute evidence, dereference/indexing legality failures, overload/profile disagreement, missing visible candidates, ambiguous overloads, stale entity/type/profile/view/overload evidence, and consumer-local reinterpretation of names or attributes.

The regression suite includes balanced legal, illegal, legal-with-runtime-check, and indeterminate cases, plus consumer/audit gate failures for source-shape, remediation, coverage promotion, unconsumed results, unstable blocker families, and fingerprint freshness.
