Pass 532 - quoted operator pragma target retention

Implemented another focused convergence pass for the unified pragma/aspect/attribute-definition representation path.

Changes:
- Hardened pragma target extraction for quoted Ada operator symbols.
- Interfacing pragmas such as `pragma Import (C, "+");` now retain the operator symbol target instead of rejecting it as a non-identifier.
- Returned the complete quoted operator literal target, preserving doubled quotes inside the literal if present.
- Kept quoted operator targets on the same unified representation metadata path used by aspects and attribute-definition clauses.
- Added regression coverage proving an imported operator function receives retained `Import` representation metadata.
