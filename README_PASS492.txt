Pass 492 - Interfacing property explicit representation unification

Implemented the next representation/operational unification pass by promoting
interfacing representation properties out of generic Representation_Other_Clause
retention and into explicit representation kinds shared by aspects,
attribute-definition clauses, and interfacing pragmas.

Changes:
- Added explicit retained representation kinds for Convention, Import, Export,
  External_Name, and Link_Name.
- Updated attribute-definition clause lowering so forms such as
  `for Entity'Convention use C;`, `for Entity'Import use True;`, and
  `for Entity'Link_Name use "...";` map to the explicit interfacing kinds.
- Updated aspect lowering so `with Convention => ...`, `with Import`,
  `with Export => True`, `with External_Name => ...`, and `with Link_Name => ...`
  use the same explicit kinds.
- Updated interfacing pragma lowering so `pragma Convention`, `pragma Import`,
  `pragma Export`, `pragma Interface`, and `pragma External` feed the same
  explicit representation kinds.
- Kept target/value legality unified through the existing common interfacing
  checks, including convention identifier validation, static string checks,
  import/export Boolean validation, link-name requires import/export, and
  import/export conflict detection.
- Expanded regression coverage to assert that interfacing pragmas now retain
  explicit Convention/Import/External_Name/Link_Name representation kinds.
