with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;

package body Test_Slice_Rules.Tests is

   overriding function Name
     (T : Test_Slice_Rules_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Slice_Rules.Tests");
   end Name;

   procedure Test_Representative_Path_Mappings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Slice_For ("docs/testing.md") = "docs",
              "testing policy docs should not imply a unit slice");
      Assert (Slice_For ("docs/archive/README.md") = "docs",
              "archive policy docs should not imply a unit slice");
      Assert (Slice_For ("docs/commands.md") = "docs",
              "active docs should not imply a unit slice");
      Assert (Slice_For ("README.md") = "docs",
              "top-level README should not imply a unit slice");
      Assert (Slice_For ("tools/release_commands.adb") = "build-tools",
              "Ada release tools should be owned by build-tools");
      Assert (Slice_For ("tests/src/test_slice_rules-tests.adb") = "build-tools",
              "slice-rule tests should be owned by build-tools");
      Assert (Slice_For (".gitignore") = "build-tools",
              "repository hygiene policy should be owned by build-tools");
      Assert (Slice_For ("tests/tests.gpr") = "build-tools",
              "test project plumbing should be owned by build-tools");
      Assert (Slice_For ("editor_core.gpr") = "build-tools",
              "project files should be owned by build-tools");
      Assert (Slice_For ("src/core/editor-search_results.adb") = "project-workspace",
              "Search Results belongs to project-workspace");
      Assert (Slice_For ("src/core/editor-ada_language_model.adb") = "ada-language",
              "Ada language model belongs to ada-language");
      Assert (Slice_For ("src/core/editor-syntax_semantics.adb") =
                "ada-parser-outline",
              "Ada syntax semantics belongs to the parser/outline slice");
      Assert (Slice_For ("tests/src/ada_parser_outline_suite.adb") =
                "ada-parser-outline",
              "Ada parser/outline suite plumbing belongs to the parser/outline slice");
      Assert (Slice_For ("tests/src/ada_parser_outline_tests.adb") =
                "ada-parser-outline",
              "Ada parser/outline runner belongs to the parser/outline slice");
      Assert (Slice_For ("tests/src/ada_language_service_suite.adb") =
                "ada-language-service",
              "Ada language service suite plumbing belongs to its focused slice");
      Assert (Slice_For ("tests/src/test_ada_language_service_integration.adb") =
                "ada-language-service",
              "Ada language service integration belongs to its focused slice");
      Assert
        (Slice_For
           ("tests/src/editor-executor-semantic_language_service_tests.adb") =
           "ada-language-service",
         "executor semantic language-service tests belong to ada-language-service");
      Assert
        (Slice_For ("tests/src/editor-executor-semantic_rename_tests.adb") =
           "ada-language-service",
         "executor semantic rename tests belong to ada-language-service");
      Assert
        (Slice_For ("tests/src/editor-executor-semantic_index_state_tests.adb") =
           "ada-language-service",
         "executor semantic index-state tests belong to ada-language-service");
      Assert
        (Slice_For ("src/core/editor-ada_rm_gap_burn_down_case_1366.adb") =
           "ada-rm-validation",
         "RM burn-down validation belongs to ada-rm-validation");
      Assert
        (Slice_For
           ("tests/src/test_ada_rm_remaining_gap_remediation_case_1428.adb") =
           "ada-rm-validation",
         "remaining RM remediation tests belong to ada-rm-validation");
      Assert (Slice_For ("src/core/editor-feature_diagnostics.adb") =
                "diagnostics-problems",
              "feature diagnostics belongs to diagnostics-problems");
      Assert (Slice_For ("tests/src/buffer_tests.adb") = "text",
              "text buffer primitive tests should stay in text");
      Assert (Slice_For ("src/core/editor-render_model.adb") = "editor-ui",
              "render model belongs to editor-ui");
      Assert (Slice_For ("tests/src/executor_diagnostics_tests.adb") =
                "executor-diagnostics",
              "executor diagnostics runner belongs to its focused slice");
      Assert (Slice_For ("tests/src/executor_search_tests.adb") =
                "executor-search",
              "executor search runner belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-search_tests.adb") =
                "executor-search",
              "executor search test package belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-diagnostics_tests.adb") =
                "executor-diagnostics",
              "executor diagnostics test package belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-test_support.adb") =
                "executor-search",
              "executor test support keeps a stable primary owner");
      Assert (Slice_For ("tests/src/executor_navigation_tests.adb") =
                "executor-navigation",
              "executor navigation runner belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-navigation_tests.adb") =
                "executor-navigation",
              "executor navigation test package belongs to its focused slice");
      Assert (Slice_For ("tests/src/executor_buffer_switcher_tests.adb") =
                "executor-buffer-switcher",
              "executor buffer-switcher runner belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-buffer_switcher_tests.adb") =
                "executor-buffer-switcher",
              "executor buffer-switcher test package belongs to its focused slice");
      Assert (Slice_For ("src/core/editor-buffer_switcher.adb") =
                "executor-buffer-switcher",
              "buffer switcher source belongs to focused executor-buffer-switcher");
      Assert (Slice_For ("tests/src/executor_buffer_prune_tests.adb") =
                "executor-buffer-prune",
              "executor buffer-prune runner belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-buffer_prune_tests.adb") =
                "executor-buffer-prune",
              "executor buffer-prune test package belongs to its focused slice");
      Assert (Slice_For ("tests/src/executor_lifecycle_tests.adb") =
                "executor-lifecycle",
              "executor lifecycle runner belongs to its focused slice");
      Assert (Slice_For ("tests/src/editor-executor-lifecycle_tests.adb") =
                "executor-lifecycle",
              "executor lifecycle test package belongs to its focused slice");
      Assert (Slice_For ("src/core/editor-executor-navigation.adb") =
                "executor-navigation",
              "executor navigation source belongs to focused executor-navigation");
      Assert (Slice_For ("src/core/editor-bookmarks.adb") =
                "executor-navigation",
              "bookmark source belongs to focused executor-navigation");
      Assert (Slice_For ("src/core/editor-executor-structural.adb") =
                "executor-lifecycle",
              "executor structural source belongs to focused executor-lifecycle");
      Assert (Slice_For ("src/core/editor-project_search.adb") =
                "executor-search",
              "project search source belongs to focused executor-search");
      Assert (Slice_For ("tests/src/editor-executor-project_workspace_tests.adb") =
                "project-workspace",
              "executor project/workspace tests belong to project-workspace");
      Assert (Slice_For ("tests/src/editor-executor-ui_tests.adb") =
                "editor-ui",
              "executor UI tests belong to editor-ui");
      Assert (Slice_For ("src/core/editor-quick_open.adb") = "editor-core",
              "default editor behavior should fall back to editor-core");
      Assert (Companion_Slice_For ("src/core/editor-feature_diagnostics.adb") =
                "editor-ui",
              "diagnostic projection changes should also cover editor UI rendering");
      Assert (Companion_Slice_For ("tests/src/editor-executor-test_support.adb") =
                "executor-diagnostics",
              "shared executor test support should cover diagnostics and search slices");
      Assert (Additional_Companion_Slice_For ("src/core/editor-feature_diagnostics.adb") =
                "build-tools",
              "diagnostic projection changes should also cover Build UI diagnostics rows");
      Assert (Companion_Slice_For ("src/core/editor-input_bridge.adb") =
                "diagnostics-problems",
              "input bridge changes should also cover diagnostics/problem routing");
      Assert (Additional_Companion_Slice_For ("src/core/editor-build_ui_actions.adb") =
                "editor-ui",
              "Build UI action changes should also cover render/input UI surfaces");
      Assert (Companion_Slice_For ("src/core/editor-quick_open.adb") = "",
              "ordinary editor-core files should not add companion slices");
      Assert (Additional_Companion_Slice_For ("src/core/editor-quick_open.adb") = "",
              "ordinary editor-core files should not add additional companion slices");
   end Test_Representative_Path_Mappings;

   procedure Test_Unit_Test_Command_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Unit_Test_Command ("build-tools") = "tools/bin/unit_tests build-tools",
              "command helper should produce the unit_tests slice invocation");
      Assert (Unit_Test_Command ("docs") = "",
              "docs pseudo-slice should not produce a unit_tests invocation");
      Assert (Run_Next_Command_Line ("tools/bin/unit_tests editor-core") =
                "#   tools/bin/unit_tests editor-core",
              "run-next command lines should keep exact comment indentation");
      Assert (Is_Changed_File_Set_Argument ("--changed"),
              "changed-file argument helper should recognize --changed");
      Assert (not Is_Changed_File_Set_Argument ("changed"),
              "changed-file argument helper should reject ordinary paths");
      Assert (Is_Actionable_Changed_File ("src/core/editor-executor.adb"),
              "source changes should be actionable");
      Assert
        (Changed_File_Category ("src/core/editor-executor.adb") =
           Changed_File_Actionable,
         "source changes should classify as actionable");
      Assert (not Is_Actionable_Changed_File ("editor-executor.ali"),
              "generated ALI files should not select test slices");
      Assert (Changed_File_Category ("editor-executor.ali") =
                Changed_File_Generated,
              "generated ALI files should classify as generated");
      Assert (not Is_Actionable_Changed_File ("docs/archive/README_PASS1435.txt"),
              "archived pass notes should not select test slices");
      Assert (Changed_File_Category ("docs/archive/README_PASS1435.txt") =
                Changed_File_Archive,
              "archived notes should classify as archive");
      Assert (not Is_Actionable_Changed_File ("obj/core/editor.o"),
              "object files should not select test slices");
      Assert (Changed_File_Category ("") = Changed_File_Empty,
              "empty changed paths should classify as empty");
   end Test_Unit_Test_Command_Text;

   procedure Test_Smoke_And_Gate_Command_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Product_Smoke_Command_For ("tests/e2e/editor_product_smoke.adb") =
         "tools/bin/product_smoke_focus_selftest",
         "shared product smoke driver should map to focused wrapper selftest");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_build_diagnostics.adb") =
         "tools/bin/product_smoke_build_diagnostics",
         "focused product smoke wrappers should map to their focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_quick_open_file_tree.adb") =
         "tools/bin/product_smoke_quick_open_file_tree",
         "Quick Open/File Tree smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_edit_save.adb") =
         "tools/bin/product_smoke_edit_save",
         "edit/save smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_workspace_session.adb") =
         "tools/bin/product_smoke_workspace_session",
         "workspace session smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_command_palette_ranking.adb") =
         "tools/bin/product_smoke_command_palette_ranking",
         "command palette smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_diagnostics_problems.adb") =
         "tools/bin/product_smoke_diagnostics_problems",
         "diagnostics Problems smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_diagnostic_quick_fix.adb") =
         "tools/bin/product_smoke_diagnostic_quick_fix",
         "diagnostic quick-fix smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_build_ui_interaction.adb") =
         "tools/bin/product_smoke_build_ui_interaction",
         "Build UI product smoke wrapper should map to its focused command");
      Assert
        (Product_Smoke_Command_For ("tools/product_smoke_focus_selftest.adb") =
         "tools/bin/product_smoke_focus_selftest",
         "focused smoke selftest should map to its dedicated command");
      Assert
        (Workflow_Gate_Command_For ("tools/editor_workflow_gate_selftest.adb") =
         "tools/bin/editor_workflow_gate_selftest",
         "workflow gate files should map to workflow gate selftest");
      Assert
        (Product_Smoke_Command_For ("src/core/editor-problems.adb") =
         "tools/bin/product_smoke_diagnostics_problems",
         "Problems changes should run diagnostics Problems product smoke");
      Assert
        (Product_Smoke_Command_For ("src/core/editor-feature_diagnostics.adb") =
         "tools/bin/product_smoke_diagnostic_quick_fix",
         "Feature Diagnostics changes should run diagnostic quick-fix product smoke");
      Assert
        (Product_Smoke_Command_For ("src/core/editor-executor.adb") =
         "tools/bin/product_smoke_diagnostic_quick_fix",
         "executor quick-fix routing changes should run diagnostic quick-fix product smoke");
      Assert
        (Product_Smoke_Command_For ("src/core/editor-build_ui_actions.adb") =
         "tools/bin/product_smoke_build_ui_interaction",
         "Build UI action changes should run Build UI product smoke");
      Assert
        (Additional_Companion_Slice_For ("src/core/editor-build_ui_actions.adb") =
         "editor-ui",
         "Build UI action changes should also run editor-ui for input/render paths");
      Assert
        (Product_Smoke_Command_For ("src/core/editor-input_bridge.adb") =
         "tools/bin/product_smoke_build_ui_interaction",
         "input bridge Build UI keyboard changes should run Build UI product smoke");
      Assert
        (Product_Smoke_Command_For ("src/core/editor-status_bar.adb") = "",
         "ordinary source files should not add product smoke command");
      Assert
        (Product_Smoke_Command_For ("docs/testing.md") = "",
         "docs mentioning product smoke commands should not add product smoke command");
   end Test_Smoke_And_Gate_Command_Text;

   overriding procedure Register_Tests
     (T : in out Test_Slice_Rules_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Representative_Path_Mappings'Access,
         "test slice rules map representative paths to stable slices");
      Register_Routine
        (T, Test_Unit_Test_Command_Text'Access,
         "test slice rules print stable unit test commands");
      Register_Routine
        (T, Test_Smoke_And_Gate_Command_Text'Access,
         "test slice rules print smoke and gate commands for workflow files");
   end Register_Tests;

end Test_Slice_Rules.Tests;
