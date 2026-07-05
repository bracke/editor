# Editor Pass 690

Pass 690 deepens package/spec/body declarative-item boundary grammar coverage in the Ada token cursor.

## Implemented

- Added package-spec part/item productions:
  - `Production_Package_Visible_Part`
  - `Production_Package_Visible_Declarative_Item`
  - `Production_Package_Private_Declarative_Part`
  - `Production_Package_Private_Declarative_Item`
- Added package-body declarative-item production:
  - `Production_Package_Body_Declarative_Item`
- Package specifications now retain visible-part and private-part declarative-item boundaries separately from the broad package declaration marker.
- Package-body declarative parts now retain individual declarative-item start markers before the body `begin`.
- Nested package declarations/specifications inside visible parts and package bodies are skipped as one bounded declarative item for part-boundary recovery, so nested `private`/`end` tokens do not leak into the enclosing package boundary scan.
- Existing declaration/statement parsing remains unchanged; the new markers are additive token-cursor metadata for Outline, semantic-colouring, and syntax-tree consumers.

## Tests

- Added AUnit coverage for package visible-part retention.
- Added coverage for package private declarative-part and private-item retention.
- Added coverage for nested package specifications inside visible parts without leaking their private boundary to the enclosing package.
- Added coverage for package-body declarative-item retention and recovery into the following statement sequence.

## Scope

This improves structural grammar coverage for Ada package specification/body declarative-item boundaries. It is not compiler-grade legality checking for package visibility, private completion rules, nested unit legality, body/spec conformance, freezing, elaboration, or declaration ordering.
