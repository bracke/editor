Editor Phase 579 - Pass 630

Focused area: selected-name selector grammar.

Changes:
- Added structural token-cursor production kinds for selected-name selectors:
  - ordinary identifier/keyword selectors
  - operator-symbol selectors represented by Ada string literals, for example Math."+"
  - character-literal selectors, for example Symbols.'A'
- Introduced a shared selected-name suffix parser used by expression names, use/visibility names, allocator subtype marks, and representation targets.
- Preserved `.all` explicit dereference production emission when the selected selector is `all`.
- Added AUnit regression coverage for expression and representation-clause contexts that use operator-symbol and character-literal selected-name selectors.

Scope:
This pass improves structural grammar coverage for selected names with literal selectors. It does not perform compiler-grade legality checking for selector declarations, overload resolution, or callable profile conformance.
