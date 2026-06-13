Pass1429: Phase 579 architecture cleanup

Selected project-scale item:
Architecture cleanup after finite RM remaining-gap closure.

Added:
Editor.Ada_Phase579_Architecture_Cleanup_Pass1429
Test_Ada_Phase579_Architecture_Cleanup_Pass1429
README_PASS1429.txt
docs/release/ARCHITECTURE_CLEANUP_PASS1429.md

Purpose:
This pass does not create a new Remaining_* Ada RM semantic edge. It freezes the
architecture cleanup rule after pass1428 by classifying artifacts as canonical
production surfaces, quarantined historical scaffolding, release documentation,
or registered tests.

The cleanup gate rejects:
command aliases without an implementation reason
compatibility spellings without an implementation reason
rendering-side parsing
analysis-time dirty-state mutation
command-palette/keybinding/workspace/render mutation leaks
unowned public API surfaces
exported obsolete scaffolding
pass-churn comments or names that obscure final intent
reopened Remaining_* gaps after closure
stale source/API/cleanup fingerprints

Canonical surfaces named in tests:
Editor.Ada_Language_Model
Editor.Ada_Declaration_Parser

Historical scaffolding is not deleted wholesale. It is quarantined as regression
evidence and may not become a production extension point. Future cleanup work must
be driven by a concrete failure, not by adding new speculative semantic passes.
