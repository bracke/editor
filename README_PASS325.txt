Editor Phase 579 IDE-grade Ada language model pass 325

This pass extends grammar-aware recovery for malformed Ada headers.

Implemented:
- Added Node_Expected_Token syntax-tree detail nodes.
- Added parser-owned recovery points for malformed Ada headers that are missing required grammar tokens.
- Covered missing `then` in if/elsif headers, missing `is` in case/variant headers, and missing `loop` in for/while loop headers.
- Recovery nodes retain expected-token children while preserving the subsequent structured statement/end tree.
- Added AUnit coverage and release-check guards for malformed-header expected-token recovery.

No Python, shell scripts, or external parser generators were added.
