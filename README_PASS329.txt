Editor phase 579 pass 329

This pass extends grammar-aware recovery for malformed handled statement parts.

Changes:
- Added Node_Implicit_Begin syntax-tree recovery nodes.
- Detects executable statements that appear directly under handled-sequence owners such as subprogram/package/task/entry bodies, accept statements, and declare blocks before an explicit begin.
- Inserts a parser-owned implicit begin recovery node with Node_Recovery_Point and Node_Expected_Token = begin.
- Parents the recovered executable statement under the implicit statement part so statement structure is preserved.
- Reuses Node_Implicit_End when the recovered statement part closes at the enclosing end boundary.
- Added AUnit coverage and release validation guards.

No Python, shell scripts, parser generators, rendering-side parsing, or external LSP dependencies were added.
