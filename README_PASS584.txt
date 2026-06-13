Pass584: direct static String-expression bounds feed representation evaluation.

Changes:
- Extended retained String bound evaluation so String'Length, String'First, and String'Last can resolve over any bounded static String expression, not only named retained String constants.
- Direct qualified String expressions and direct slice/literal expressions can now expose static Length/First/Last values in representation expressions.
- Added regression coverage for String'("Gr" & "een")'Length and direct sliced String expression Last values in Size clauses.
- Cleaned duplicated adjacent static-string regression declarations/assignments left in the test harness around the concatenation and slicing cases.
