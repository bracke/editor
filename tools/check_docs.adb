with Editor_Tool_Common; use Editor_Tool_Common;

procedure Check_Docs is
   Tool : constant String := "check_docs";

   procedure Require_Marker
     (Path    : String;
      Marker  : String;
      Message : String) is
   begin
      Require_File (Tool, Path);
      if not File_Contains (Path, Marker) then
         Fail (Tool, Message);
      end if;
   end Require_Marker;

   procedure Require_Focused_Smoke
     (Source_Path : String;
      Source_Main : String;
      Command     : String;
      Scenario    : String;
      Marker      : String) is
   begin
      Require_Marker
        ("tools/editor_tools.gpr", Source_Main,
         Source_Main & " must be built by editor_tools.gpr");
      Require_Marker
        ("tools/show_developer_tools.adb", Command,
         Command & " must appear in the developer tool listing");
      Require_Marker
        ("tools/test_slice_rules.adb", Command,
         Command & " must be selected by test slice rules");
      Require_Marker
        (Source_Path, Scenario,
         Source_Path & " must forward the focused smoke scenario");
      Require_Marker
        (Source_Path, Marker,
         Source_Path & " must validate its focused smoke marker");
      Require_Marker
        ("tools/product_smoke_focus_selftest.adb", Command,
         Command & " must be covered by the focused smoke selftest");
      Require_Marker
        ("docs/testing.md", Command,
         Command & " must be documented in the testing guide");
      Require_Marker
        ("docs/editor_workflow_contracts.md", Command,
         Command & " must be documented in workflow contracts");
   end Require_Focused_Smoke;
begin
   Require_Marker
     ("README.md",
      "tools/bin/test_commands_for",
      "README must point contributors at focused test-command selection");
   Require_Marker
     ("README.md",
      "docs/editor_workflow_contracts.md",
      "README must link the editor workflow contract");

   Require_Marker
     ("docs/README.md",
      "editor_workflow_contracts.md",
      "docs index must include the editor workflow contract");

   Require_Marker
     ("docs/testing.md",
      "Run slice builds serially",
      "testing guide must document serialized focused slice runs");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/test_commands_for",
      "testing guide must document mapped command selection");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/test_commands_for --why",
      "testing guide must document focused command selection reasons");
   Require_Marker
     ("tools/test_commands_for.adb",
      "# why ",
      "test_commands_for must expose optional command selection reasons");
   Require_Marker
     ("tools/test_commands_for.adb",
      "# run next:",
      "test_commands_for must expose a compact follow-up command block");
   Require_Marker
     ("docs/testing.md",
      "# run next:",
      "testing guide must document compact focused command output");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/unit_tests all",
      "testing guide must keep full suite as a release-only gate");
   Require_Marker
     ("tools/release_commands.adb",
      "tools/bin/unit_tests all",
      "release command list must expose release-only full-suite gate");
   Require_Marker
     ("tools/release_commands.adb",
      "tools/bin/check_docs",
      "release command list must expose documentation contract gate");
   Require_Marker
     ("tools/release_commands.adb",
      "tools/bin/check_repo_hygiene",
      "release command list must expose repository hygiene gate");
   Require_Marker
     ("tools/release_check.adb",
      "Run_Tool_Gate (""check_docs""",
      "release_check must run documentation contract gate");
   Require_Marker
     ("tools/release_check.adb",
      "Run_Tool_Gate (""check_repo_hygiene""",
      "release_check must run repository hygiene gate");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/product_smoke_quick_open_file_tree",
      "testing guide must document focused editor smoke entry points");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/product_smoke_focus_selftest",
      "testing guide must document focused smoke wrapper isolation checks");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/editor_workflow_gate --quick",
      "testing guide must document dogfood editor workflow gate");
   Require_Marker
     ("tools/editor_workflow_gate.adb",
      "command-palette product smoke",
      "editor workflow gate must cover combined editor workflows");
   Require_Marker
     ("docs/testing.md",
      "docs/archive",
      "testing guide must document generated/archive scan exclusions");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/check_repo_hygiene",
      "testing guide must document repository hygiene check");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/source_status",
      "testing guide must document filtered source status");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/source_status --only",
      "testing guide must document source_status category filters");
   Require_Marker
     ("docs/testing.md",
      "per-category counts",
      "testing guide must document source_status category summary counts");
   Require_Marker
     ("docs/testing.md",
      "Focused Validation Matrix",
      "testing guide must document the focused validation matrix");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/unit_tests diagnostics-problems",
      "testing guide must document diagnostics-problems slice");
   Require_Marker
     ("tools/unit_tests.adb",
      "diagnostics-problems",
      "unit_tests must expose diagnostics-problems slice");
   Require_Marker
     ("tools/test_slice_rules.adb",
      "diagnostics-problems",
      "slice rules must select diagnostics-problems slice");
   Require_Marker
     ("tools/show_developer_tools.adb",
      "tools/bin/source_status --only tools",
      "developer tool listing must advertise source_status category filters");
   Require_Marker
     ("tools/source_status.adb",
      "source_status: categories",
      "source_status must emit category summary counts");
   Require_Marker
     ("tools/source_status.adb",
      "renames=",
      "source_status category summary must include renames");
   Require_Marker
     ("tools/source_status.adb",
      "filtered generated/archive",
      "source_status must distinguish generated/archive filtering");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/product_smoke_command_palette_ranking",
      "testing guide must document command palette ranking smoke");
   Require_Marker
     ("docs/testing.md",
      "Command Palette ranking and execution",
      "testing guide must document command palette execution smoke coverage");
   Require_Marker
     ("tools/product_smoke_command_palette_ranking.adb",
      "command_palette_execution=confirmed",
      "command palette focused smoke must require execution marker");
   Require_Marker
     ("tools/product_smoke_focus_selftest.adb",
      "Require_Marker (""command_palette_execution"")",
      "focused smoke selftest must require command palette execution marker");
   Require_Marker
     ("tools/test_slice_rules.adb",
      "tools/bin/product_smoke_command_palette_ranking",
      "slice rules must select command palette ranking smoke");
   Require_Marker
     ("tools/test_commands_for.adb",
      "--changed",
      "test command resolver must support direct changed-file discovery");
   Require_Marker
     ("tools/test_commands_for.adb",
      "Additional_Companion_Slice_For",
      "test command resolver must print additional companion slices");
   Require_Marker
     ("docs/testing.md",
      "Generated Ada build artifacts are not release evidence",
      "testing guide must document generated artifact policy");
   Require_Marker
     ("docs/testing.md",
      "tools/bin/test_commands_for --changed",
      "testing guide must document direct changed-file slice resolution");
   Require_Marker
     ("docs/testing.md",
      "additional=",
      "testing guide must document additional companion slice output");
   Require_Marker
     ("docs/legacy_pass_migration.md",
      "Safe migration order",
      "legacy pass migration guide must document safe rename ordering");
   Require_Marker
     ("docs/testing.md",
      "docs/legacy_pass_migration.md",
      "testing guide must link the legacy pass migration guide");
   Require_Marker
     (".gitignore",
      "/README_PASS*.txt",
      "ignore policy must keep historical pass logs out of normal changes");
   Require_Marker
     (".gitignore",
      "/lib/*.o",
      "ignore policy must keep library object files out of normal changes");
   Require_Marker
     ("tools/source_status.adb",
      "filtered generated/archive",
      "source status must summarize filtered generated and archive entries");
   Require_Marker
     ("tools/source_status.adb",
      "Name = ""generated""",
      "source status must expose generated-only filtering");
   Require_Marker
     ("tools/source_status.adb",
      "Name = ""archive""",
      "source status must expose archive-only filtering");
   Require_Marker
     ("docs/testing.md",
      "`--only generated`",
      "testing guide must document generated-only source status filtering");
   Require_Marker
     ("tools/check_repo_hygiene.adb",
      "obsolete phase artifact should not be live",
      "repo hygiene must reject obsolete phase artifacts");

   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "Status Surfaces",
      "editor workflow contract must cover status surfaces");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "Pending Transitions",
      "editor workflow contract must cover pending transitions");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "Render Packets",
      "editor workflow contract must cover render packets");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "Focused Smoke",
      "editor workflow contract must cover focused smoke scenarios");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "tools/bin/product_smoke_dirty_lifecycle_persistence",
      "editor workflow contract must document dirty lifecycle smoke");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "docs/archive",
      "editor workflow contract must document live scan exclusions");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "tools/bin/check_repo_hygiene",
      "editor workflow contract must document repository hygiene gate");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "tools/bin/source_status",
      "editor workflow contract must document filtered source status");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "tools/bin/source_status --only",
      "editor workflow contract must document source_status category filters");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "per-category counts",
      "editor workflow contract must document source_status category summary counts");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "Test Selection",
      "editor workflow contract must cover test selection");
   Require_Marker
     ("docs/editor_workflow_contracts.md",
      "tools/bin/unit_tests diagnostics-problems",
      "editor workflow contract must document diagnostics-problems slice");

   Require_Focused_Smoke
     ("tools/product_smoke_quick_open_file_tree.adb",
      "product_smoke_quick_open_file_tree.adb",
      "tools/bin/product_smoke_quick_open_file_tree",
      "quick_open_file_tree",
      "quick_open_file_tree_navigation=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_edit_save.adb",
      "product_smoke_edit_save.adb",
      "tools/bin/product_smoke_edit_save",
      "edit_save",
      "editing_save_conflict_free=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_daily_editing.adb",
      "product_smoke_daily_editing.adb",
      "tools/bin/product_smoke_daily_editing",
      "daily_editing",
      "daily_editing_workflow=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_workspace_session.adb",
      "product_smoke_workspace_session.adb",
      "tools/bin/product_smoke_workspace_session",
      "workspace_session",
      "workspace_save_restore_clear=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_dirty_lifecycle_persistence.adb",
      "product_smoke_dirty_lifecycle_persistence.adb",
      "tools/bin/product_smoke_dirty_lifecycle_persistence",
      "dirty_lifecycle_persistence",
      "dirty_lifecycle_persistence=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_build_ui_interaction.adb",
      "product_smoke_build_ui_interaction.adb",
      "tools/bin/product_smoke_build_ui_interaction",
      "build_ui_interaction",
      "build_ui_interaction=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_command_palette_ranking.adb",
      "product_smoke_command_palette_ranking.adb",
      "tools/bin/product_smoke_command_palette_ranking",
      "command_palette_ranking",
      "command_palette_ranking=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_diagnostics_problems.adb",
      "product_smoke_diagnostics_problems.adb",
      "tools/bin/product_smoke_diagnostics_problems",
      "diagnostics_problems",
      "diagnostics_problems_filters=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_diagnostic_quick_fix.adb",
      "product_smoke_diagnostic_quick_fix.adb",
      "tools/bin/product_smoke_diagnostic_quick_fix",
      "diagnostic_quick_fix",
      "diagnostic_quick_fix=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_build_diagnostics.adb",
      "product_smoke_build_diagnostics.adb",
      "tools/bin/product_smoke_build_diagnostics",
      "build_diagnostics",
      "build_diagnostics_navigation=confirmed");
   Require_Focused_Smoke
     ("tools/product_smoke_render_packet.adb",
      "product_smoke_render_packet.adb",
      "tools/bin/product_smoke_render_packet",
      "render_packet",
      "render_packet_nonempty=confirmed");

   Info (Tool, "documentation contract markers passed");
end Check_Docs;
