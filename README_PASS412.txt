Phase 579 pass 412 - concurrent type header grammar pass

This pass extends the Ada token-cursor parser toward complete Ada grammar coverage for concurrent declarations.

Implemented:
- Added Production_Task_Type_Declaration and Production_Protected_Type_Declaration.
- Task/protected declarations now parse the optional `type` marker, defining name, and discriminant part before entering the definition body.
- Task/protected bodies now retain the body name structurally before the `is`/`separate` boundary.
- Added AUnit coverage for discriminated `task type` and `protected type` declarations with nested entries, protected operations, and private parts.
- Updated phase validation/release guard markers and documentation.

Non-goals retained:
- No compiler-grade tasking legality checking.
- No protected/action barrier validation.
- No runtime rendezvous or concurrency semantics.
- No GNAT-equivalent placement/conformance validation.
