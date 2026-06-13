Phase 579 pass 200

Completeness focus:
- Harden indexed Outline body/spec navigation against stale projected targets.
- Add exact target-key revalidation to Editor.Ada_Project_Index.
- Carry Indexed_File_Key through executor Outline indexed targets.
- Reject open-buffer indexed navigation unless buffer token, revision, lifecycle generation, and analysis fingerprint still match.
- Add AUnit regression coverage for target-key revalidation.
- Update docs and validation guard markers.

Validation performed in this environment:
- Static source and marker checks only.
- GNAT/gprbuild/AUnit are unavailable here.
- No Python or shell scripts were added.
