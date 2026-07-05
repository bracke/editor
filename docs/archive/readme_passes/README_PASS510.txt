Pass 510 - GNAT policy operational property unification

This pass extends the representation/operational property unification layer to another
cluster of policy-style GNAT/Ada operational properties. The parser now retains these
properties as explicit representation metadata when written as aspects, attribute-
definition clauses, or matching entity pragmas where applicable.

Implemented:
- No_Heap_Finalization
- Suppress_Debug_Info
- Assertion_Policy
- Check_Policy
- Debug_Policy
- Restrictions
- Restriction_Warnings
- Profile

The new explicit kinds share the existing legality machinery for duplicate detection,
target compatibility, required-expression diagnostics, and Boolean defaulting for bare
Boolean aspect forms.
