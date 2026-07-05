# Editor Pass 663

Pass 663 improves structural token-cursor grammar coverage for Ada generic
instantiation internals.

Implemented changes:

- Added `Production_Generic_Instance_Name` for the defining instance name in
  package, procedure, and function generic instantiations.
- Added `Production_Generic_Instantiated_Unit_Name` for the generic unit name
  after `is new`.
- Added `Production_Generic_Instantiation_Actual_Part` as an instantiation-
  specific wrapper before the existing generic actual-part parser is used.
- Reworked package/procedure/function instantiation parsing so it consumes the
  instance name, `is new` generic name, optional actual part, and attached
  aspects structurally instead of skipping directly to the actual list.
- Preserved existing generic instantiation and generic actual productions for
  current Outline, resolver, and semantic-colouring consumers.
- Added AUnit coverage for package, procedure, and function instantiations,
  selected generic names, named actuals, selected operator actual expressions,
  attached aspects, and recovery into a following declaration.

This pass improves structural grammar coverage for Ada generic instantiations.
It is not compiler-grade legality checking for generic contract conformance,
visibility, overload resolution, actual/default legality, or instance semantic
expansion.
