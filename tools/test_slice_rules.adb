with Ada.Characters.Handling;

package body Test_Slice_Rules is
   function Lower (S : String) return String is
      Result : String := S;
   begin
      for C of Result loop
         C := Ada.Characters.Handling.To_Lower (C);
      end loop;
      return Result;
   end Lower;

   function Contains (Text, Needle : String) return Boolean is
   begin
      if Needle'Length = 0 or else Text'Length < Needle'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Needle'Length + 1 loop
         if Text (I .. I + Needle'Length - 1) = Needle then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Ends_With (Text, Suffix : String) return Boolean is
   begin
      return Suffix'Length > 0
        and then Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Slice_For (Path : String) return String is
      P : constant String := Lower (Path);
   begin
      if Contains (P, "tests/src/buffer_tests")
        or else Contains (P, "text_buffer")
        or else Contains (P, "/text/")
      then
         return "text";
      elsif Contains (P, "docs/")
        or else P = "readme.md"
      then
         return "docs";
      elsif Contains (P, "rm_gap_burn_down")
        or else Contains (P, "rm_remaining_gap_remediation")
        or else Contains (P, "rm_coverage_matrix_audit")
        or else Contains (P, "rm_coverage_gap_remediation_audit")
        or else Contains (P, "semantic_integration_audit")
        or else Contains (P, "canonical_semantic_model_agreement_audit")
        or else Contains (P, "end_to_end_semantic_scenario_audit")
        or else Contains (P, "semantic_consumer_enforcement_audit")
        or else Contains (P, "partial_evidence_precision_audit")
        or else Contains (P, "semantic_regression_corpus_balance_audit")
        or else Contains (P, "architecture_cleanup")
        or else Contains (P, "real_ada_corpus_validation")
        or else Contains (P, "release_readiness_validation")
        or else Contains (P, "end_to_end_editor_integration_validation")
        or else Contains (P, "documentation_handoff")
        or else Contains (P, "performance_boundedness_validation")
        or else Contains (P, "diagnostic_quality_validation")
        or else Contains (P, "project_scale_closure")
      then
         return "ada-rm-validation";
      elsif Contains (P, "ada_language_service")
        or else Contains (P, "semantic_language_service")
        or else Contains (P, "semantic_rename")
        or else Contains (P, "semantic_index_state")
        or else Contains (P, "test_ada_language_service_integration")
      then
         return "ada-language-service";
      elsif Contains (P, "ada_parser_outline")
        or else Contains (P, "editor-syntax")
        or else Contains (P, "syntax_cache")
        or else Contains (P, "syntax_semantics")
        or else Contains (P, "editor-outline")
        or else Contains (P, "ada_declaration_parser")
        or else Contains (P, "ada_token_cursor")
        or else Contains (P, "ada_syntax_tree")
        or else Contains (P, "ada_separate_body_stub_rules")
        or else Contains (P, "parser_ast_coverage_vertical_slice")
      then
         return "ada-parser-outline";
      elsif Contains (P, "ada_")
        or else Contains (P, "test_ada_")
        or else Contains (P, "syntax")
        or else Contains (P, "outline")
        or else Contains (P, "language_model")
        or else Contains (P, "parser")
        or else Contains (P, "semantic")
        or else Contains (P, "rm_")
      then
         return "ada-language";
      elsif Contains (P, "editor-problems")
        or else Contains (P, "editor-feature_diagnostics")
        or else Contains (P, "editor-diagnostics-tests")
        or else Contains (P, "editor-diagnostics.ads")
        or else Contains (P, "editor-diagnostics.adb")
        or else Contains (P, "diagnostics_review_ux")
        or else Contains (P, "diagnostics_problems")
      then
         return "diagnostics-problems";
      elsif Contains (P, "executor_diagnostics")
        or else Contains (P, "executor-diagnostics")
        or else Contains (P, "editor-executor-diagnostics")
        or else Contains (P, "editor-diagnostics_review_ux")
      then
         return "executor-diagnostics";
      elsif Contains (P, "executor_search")
        or else Contains (P, "executor-search")
        or else Contains (P, "editor-executor-search")
        or else Contains (P, "editor-executor-test_support")
        or else Contains (P, "editor-project_search")
      then
         return "executor-search";
      elsif Contains (P, "executor_navigation")
        or else Contains (P, "executor-navigation")
        or else Contains (P, "editor-executor-navigation")
        or else Contains (P, "editor-executor-navigation_tests")
        or else Contains (P, "editor-bookmarks")
      then
         return "executor-navigation";
      elsif Contains (P, "executor_buffer_switcher")
        or else Contains (P, "executor-buffer-switcher")
        or else Contains (P, "editor-executor-buffer_switcher")
        or else Contains (P, "editor-executor-buffer_switcher_tests")
        or else Contains (P, "editor-buffer_switcher")
      then
         return "executor-buffer-switcher";
      elsif Contains (P, "executor_buffer_prune")
        or else Contains (P, "executor-buffer-prune")
        or else Contains (P, "editor-executor-buffer_prune")
        or else Contains (P, "editor-executor-buffer_prune_tests")
      then
         return "executor-buffer-prune";
      elsif Contains (P, "executor_lifecycle")
        or else Contains (P, "executor-lifecycle")
        or else Contains (P, "editor-executor-lifecycle_tests")
        or else Contains (P, "editor-executor-structural")
        or else Contains (P, "editor-lifecycle")
      then
         return "executor-lifecycle";
      elsif Contains (P, "build")
        or else Contains (P, "diagnostic")
        or else Contains (P, "problem")
        or else Contains (P, "terminal")
        or else Contains (P, "producer")
        or else Contains (P, "command_extension")
        or else Contains (P, "test_slice_rules")
        or else Contains (P, "tools/")
        or else Contains (P, ".gitignore")
        or else Contains (P, ".gpr")
        or else Contains (P, "tests.gpr")
        or else Contains (P, "release")
      then
         return "build-tools";
      elsif Contains (P, "project")
        or else Contains (P, "file_tree")
        or else Contains (P, "editor-executor-project_workspace")
        or else Contains (P, "workspace")
        or else Contains (P, "recent_projects")
        or else Contains (P, "search_results")
        or else Contains (P, "dirty_guard")
        or else Contains (P, "pending_transition")
        or else Contains (P, "lifecycle")
        or else Contains (P, "configuration")
      then
         return "project-workspace";
      elsif Contains (P, "render")
        or else Contains (P, "executor-ui")
        or else Contains (P, "editor-executor-ui")
        or else Contains (P, "editor-executor-ui_tests")
        or else Contains (P, "palette")
        or else Contains (P, "keybinding")
        or else Contains (P, "line_number")
        or else Contains (P, "scrollbar")
        or else Contains (P, "folding")
        or else Contains (P, "gutter")
        or else Contains (P, "status_bar")
        or else Contains (P, "message")
        or else Contains (P, "tab_bar")
        or else Contains (P, "panel")
        or else Contains (P, "focus")
        or else Contains (P, "input_")
        or else Contains (P, "command_surface")
        or else Contains (P, "contextual_help")
        or else Contains (P, "feature_")
        or else Contains (P, "empty_state")
        or else Contains (P, "startup_readiness")
        or else Contains (P, "product_surface")
        or else Contains (P, "dogfood")
      then
         return "editor-ui";
      else
         return "editor-core";
      end if;
   end Slice_For;

   function Companion_Slice_For (Path : String) return String is
      P : constant String := Lower (Path);
   begin
      if Contains (P, "editor-executor-test_support")
      then
         return "executor-diagnostics";
      elsif Contains (P, "editor-feature_diagnostics")
        or else Contains (P, "editor-diagnostics")
        or else Contains (P, "editor-problems")
        or else Contains (P, "diagnostic_quick_fix")
      then
         return "editor-ui";
      elsif Contains (P, "editor-build_ui")
        or else Contains (P, "editor-input_bridge")
      then
         return "diagnostics-problems";
      end if;
      return "";
   end Companion_Slice_For;

   function Additional_Companion_Slice_For (Path : String) return String is
      P : constant String := Lower (Path);
   begin
      if Contains (P, "editor-feature_diagnostics")
        or else Contains (P, "editor-diagnostics")
        or else Contains (P, "editor-problems")
        or else Contains (P, "diagnostic_quick_fix")
      then
         return "build-tools";
      elsif Contains (P, "editor-build_ui")
      then
         return "editor-ui";
      end if;
      return "";
   end Additional_Companion_Slice_For;

   function Unit_Test_Command (Slice : String) return String is
   begin
      if Slice = "docs" then
         return "";
      end if;
      return "tools/bin/unit_tests " & Slice;
   end Unit_Test_Command;

   function Run_Next_Command_Line (Command : String) return String is
   begin
      return "#   " & Command;
   end Run_Next_Command_Line;

   function Is_Changed_File_Set_Argument (Argument : String) return Boolean is
   begin
      return Argument = "--changed";
   end Is_Changed_File_Set_Argument;

   function Changed_File_Category
     (Path : String) return Changed_File_Filter_Category
   is
      P : constant String := Lower (Path);
   begin
      if Path'Length = 0 then
         return Changed_File_Empty;
      elsif Contains (P, "/docs/archive/")
        or else Contains (P, "docs/archive/")
        or else Contains (P, "readme_pass")
      then
         return Changed_File_Archive;
      elsif Contains (P, "/obj/")
        or else Contains (P, "obj/")
        or else Contains (P, "/lib/")
        or else Contains (P, "lib/")
      then
         return Changed_File_Generated;
      elsif Ends_With (P, ".ali")
        or else Ends_With (P, ".o")
        or else Ends_With (P, ".a")
        or else Ends_With (P, ".lexch")
        or else Ends_With (P, ".bexch")
      then
         return Changed_File_Generated;
      end if;
      return Changed_File_Actionable;
   end Changed_File_Category;

   function Is_Actionable_Changed_File (Path : String) return Boolean is
   begin
      return Changed_File_Category (Path) = Changed_File_Actionable;
   end Is_Actionable_Changed_File;

   function Product_Smoke_Command_For (Path : String) return String is
      P : constant String := Lower (Path);
   begin
      if Contains (P, "docs/") or else P = "readme.md" then
         return "";
      elsif Contains (P, "product_smoke_quick_open_file_tree") then
         return "tools/bin/product_smoke_quick_open_file_tree";
      elsif Contains (P, "product_smoke_edit_save") then
         return "tools/bin/product_smoke_edit_save";
      elsif Contains (P, "product_smoke_daily_editing") then
         return "tools/bin/product_smoke_daily_editing";
      elsif Contains (P, "product_smoke_workspace_session") then
         return "tools/bin/product_smoke_workspace_session";
      elsif Contains (P, "product_smoke_dirty_lifecycle_persistence") then
         return "tools/bin/product_smoke_dirty_lifecycle_persistence";
      elsif Contains (P, "product_smoke_build_ui_interaction") then
         return "tools/bin/product_smoke_build_ui_interaction";
      elsif Contains (P, "product_smoke_command_palette_ranking") then
         return "tools/bin/product_smoke_command_palette_ranking";
      elsif Contains (P, "product_smoke_diagnostics_problems") then
         return "tools/bin/product_smoke_diagnostics_problems";
      elsif Contains (P, "product_smoke_diagnostic_quick_fix") then
         return "tools/bin/product_smoke_diagnostic_quick_fix";
      elsif Contains (P, "product_smoke_build_diagnostics") then
         return "tools/bin/product_smoke_build_diagnostics";
      elsif Contains (P, "product_smoke_render_packet") then
         return "tools/bin/product_smoke_render_packet";
      elsif Contains (P, "product_smoke_focus_selftest") then
         return "tools/bin/product_smoke_focus_selftest";
      elsif Contains (P, "e2e_product_smoke")
        or else Contains (P, "editor_product_smoke")
      then
         return "tools/bin/product_smoke_focus_selftest";
      elsif Contains (P, "product_smoke")
      then
         return "tools/bin/product_smoke";
      elsif Contains (P, "editor-feature_diagnostics")
        or else Contains (P, "diagnostic_quick_fix")
        or else Contains (P, "editor-executor")
      then
         return "tools/bin/product_smoke_diagnostic_quick_fix";
      elsif Contains (P, "editor-build_ui")
        or else Contains (P, "editor-input_bridge")
        or else Contains (P, "build_ui")
      then
         return "tools/bin/product_smoke_build_ui_interaction";
      elsif Contains (P, "editor-problems")
        or else Contains (P, "diagnostics_problems")
        or else Contains (P, "editor-diagnostics")
        or else Contains (P, "diagnostics_review_ux")
      then
         return "tools/bin/product_smoke_diagnostics_problems";
      end if;
      return "";
   end Product_Smoke_Command_For;

   function Workflow_Gate_Command_For (Path : String) return String is
      P : constant String := Lower (Path);
   begin
      if Contains (P, "editor_workflow_gate")
        or else Contains (P, "workflow_gate")
      then
         return "tools/bin/editor_workflow_gate_selftest";
      end if;
      return "";
   end Workflow_Gate_Command_For;
end Test_Slice_Rules;
