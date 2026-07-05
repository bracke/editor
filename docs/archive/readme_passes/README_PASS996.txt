Pass996 — with/use dependency semantic closure

Implemented in this pass:
- Extended Editor.Ada_Cross_Unit_Closure with context dependency link kinds.
- Added ordinary with, limited with, private with, and context use package dependency staging.
- Preserved clause name, limited/private flags, source unit, target unit, target path, status, candidate count, and deterministic fingerprint per dependency.
- Added project-index file accessors so cross-unit consumers can iterate snapshot-owned per-file analysis without re-parsing or reading files.
- Added deterministic counters for with dependencies, limited with dependencies, private with dependencies, use dependencies, and total context dependencies.
- Added AUnit regression Test_Ada_Cross_Unit_Context_Dependency_Closure_Pass996.

This pass adds one compiler-grade building block for cross-unit semantic closure. Full compiler-grade Ada analysis remains incomplete until private/limited cross-unit view rules, body/spec semantic completion, subunit body-stub closure, and cross-unit expression/type/generic legality are fully integrated.
