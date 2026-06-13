Pass1358 - Predefined Environment / Literal Resolution Burn-Down

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1358 and the corresponding AUnit suite Test_Ada_RM_Gap_Burn_Down_Pass1358.

The pass burns down the predefined-environment and literal-resolution gap by forcing one canonical source-shaped result across package Standard identity, root and universal types, Boolean/Character/String families, predefined exceptions, predefined attributes/operators, integer/real/character/string/enumeration/null literal resolution, expected-type propagation, and the consumers that surface those results.

Concrete legality/composition coverage added:

* package Standard entity identity for predefined scalar, string, exception, attribute, and operator entities;
* root_integer, root_real, root_fixed, universal integer, universal real, and universal access/null-literal agreement;
* integer and real literal agreement between static evaluation, overload resolution, expected-type propagation, and assignment/conversion consumers;
* character/enumeration literal ambiguity rejection;
* string and wide-string literal compatibility with character-array contexts;
* null literal rejection when no access/access-like expected type exists;
* null literal access-view agreement;
* aggregate/assignment and subtype/range/predicate consumers of literal evidence;
* runtime string bounds and range check preservation;
* indeterminate handling for missing predefined environment, literal evidence, expected type, cross-unit evidence, and private/limited/incomplete/formal views;
* diagnostics, semantic colouring, outline/navigation, hover/detail, and build-diagnostic bridge agreement;
* source, AST, predefined-environment, literal, root-type, type, expected-type, static, overload, profile, substitution, and consumer fingerprint freshness.

The AUnit coverage includes balanced legal, illegal, legal-with-runtime-check, and indeterminate source-shaped rows and rejects stale or unconsumed evidence.  This continues the RM gap burn-down strategy by closing a foundational semantic identity gap instead of adding another wrapper/status layer.
