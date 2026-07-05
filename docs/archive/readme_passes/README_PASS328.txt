Editor IDE-grade Ada language layer pass 328

This pass extends grammar-aware syntax-tree recovery beyond declarations,
alternatives, headers, and end-targets.

Implemented:
- malformed delimited-list recovery for pragmas, aspect specifications,
  representation clauses, generic actual parts, and other parser-owned
  metadata nodes;
- expected-token recovery for missing close parentheses and unexpected close
  parentheses in those source-shape nodes;
- malformed end-boundary recovery for `end ...` lines that are missing their
  required semicolon while still retaining `Node_End` and end-target metadata;
- AUnit coverage for malformed metadata lists and end boundaries;
- release-check guards for the new recovery coverage.

Recovery nodes remain parser-owned diagnostics only. They are not Outline rows,
semantic symbols, or navigation targets.
