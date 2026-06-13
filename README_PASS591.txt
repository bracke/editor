Pass 591 - Constrained String alias bound propagation

- Added bounded propagation of retained constrained String subtype bounds through simple subtype aliases, for example `subtype Alias_Name is Offset_Name;` where `Offset_Name` is `String (2 .. 6)`.
- Alias subtypes now preserve static `First`, `Last`, and `Length` metadata instead of only retaining root String compatibility.
- Constrained alias qualification and constant retention now reuse the inherited component-count check.
- Removed a duplicated local declaration in the static String slice evaluator.
- Extended the qualified static String regression to cover aliased constrained String bounds feeding representation-expression static values.
