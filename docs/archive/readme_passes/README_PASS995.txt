Pass995 — cross-unit semantic closure foundation

This pass adds Editor.Ada_Cross_Unit_Closure, a deterministic compiler-grade building block for project-wide Ada unit closure.  The model is built from Editor.Ada_Project_Index and records first-class links for spec/body pairs, body/spec pairs, child-to-parent units, parent-to-child units, and separate-body parent relationships.

The closure model records source and target unit names, roles, paths, link status, candidate count, and a deterministic fingerprint.  Missing, ambiguous, and overflow relationships are preserved explicitly instead of being silently collapsed, which gives future semantic consumers a stable boundary for cross-file legality checks.

New project-index helpers expose indexed unit rows without making the index mutable or leaking private storage:

* Unit_At
* Unit_Role_For_Symbol

Regression coverage:

* Test_Ada_Cross_Unit_Semantic_Closure_Foundation_Pass995

This pass adds one compiler-grade building block for cross-unit semantic closure. Full compiler-grade Ada analysis remains incomplete until with/use dependency closure, private/limited views across units, body/spec semantic completion, subunit body-stub closure, and cross-unit expression/type/generic legality are fully integrated.
