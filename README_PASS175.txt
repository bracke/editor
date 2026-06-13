Phase 579 pass 175 - completeness pass

This pass extends indexed Outline body/spec navigation beyond package units to ordinary subprograms where the shared Ada language model has enough parser-owned metadata to distinguish declarations from bodies.

Changes:
- Added Declaration_Flags.Is_Body to Editor.Ada_Language_Model.
- Included Is_Body in language-model fingerprinting.
- Stamped package bodies and conservative procedure/function body headers in Editor.Ada_Declaration_Parser.
- Preserved procedure body / function body labels for model-projected Outline rows.
- Extended outline.goto-body and outline.goto-spec indexed navigation filtering to ordinary procedure/function rows using Is_Body metadata.
- Added AUnit coverage for project-index procedure/function spec/body target retention.
- Updated docs/commands.md, docs/outline.md, docs/syntax_colouring.md, and tools/release_check.adb.

Limitations:
- Generic subprogram body/spec navigation remains conservative because Symbol_Generic_Subprogram does not yet expose a public procedure/function distinction.
- Full overload disambiguation by profile is still not compiler-grade.
- This environment does not include GNAT/gprbuild, so the Ada build and AUnit suite were not run here.
