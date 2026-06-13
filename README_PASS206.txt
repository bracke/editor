Pass 206 - Ada parser completeness: context/use clause metadata

This pass expands parser-owned Ada declaration analysis with bounded metadata awareness for context clauses:

- with clauses, including limited/private context forms, stamp the analysis with with-clause awareness.
- use clauses, including use type / use all type forms, stamp the analysis with use-clause awareness.
- context/use clauses remain metadata only: they do not create Outline rows, do not create symbols for imported package names, and do not alter lexical scope ownership.
- fingerprints include the new metadata through the existing analysis fingerprint mutations.
- regression coverage verifies that ordinary declarations still parse and that imported package names do not pollute symbol lookup.

Updated files include:
- src/core/editor-ada_language_model.ads
- src/core/editor-ada_language_model.adb
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/phase579_language_validation_check.adb
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
- README.md
