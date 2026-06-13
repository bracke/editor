Pass 572 - Static integer Image strings

Implemented another bounded precise static-evaluation pass for representation-expression legality.

Changes:
- Added static string retention for integer/modular scalar Image attributes such as Integer'Image (-12) and Natural'Image (N).
- Preserved Ada Image spelling semantics for integers: nonnegative values retain the leading blank, while negative values retain the minus sign.
- Enforced retained scalar range compatibility before registering integer Image strings; out-of-range forms such as Positive'Image (0) remain nonstatic.
- Wired the resulting static strings through existing String'Length/First/Last and dimensioned String attribute evaluation paths.
- Extended regression coverage for signed Integer'Image strings, Natural'Image strings fed by another static expression, and rejected out-of-range integer Image string constants.

Scope:
- This remains a bounded semantic evaluator for IDE representation legality and does not attempt full general Ada string/object-bound inference.
