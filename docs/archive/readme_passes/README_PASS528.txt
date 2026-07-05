Pass 528: pragma named-target extraction now uses top-level association scanning.

Changes:
- Replaced raw substring search for named pragma target associations with a top-level argument scanner.
- Named targets such as Entity =>, Handler =>, On =>, and similar are now recognized only when the association belongs to the pragma argument itself.
- Nested labels inside expression values, for example Make_Name (Entity => "nested"), no longer hijack pragma target binding.
- Positional interfacing pragma target fallback now uses the first top-level comma instead of the first comma anywhere in the argument text.
- Extended representation pragma regression coverage with an Import pragma whose External_Name expression contains a nested Entity => label before the real top-level Entity => target.
