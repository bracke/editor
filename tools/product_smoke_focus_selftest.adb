with Ada.Command_Line;
with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Product_Smoke_Focus_Selftest is
   Tool : constant String := "product_smoke_focus_selftest";
   Report : constant String := "/tmp/editor_product_smoke_report.txt";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   procedure Require_Marker (Marker : String) is
   begin
      if not File_Contains (Report, Marker & "=confirmed") then
         Fail (Tool, "focused smoke report missing marker: " & Marker);
      end if;
   end Require_Marker;

   procedure Reject_Marker (Marker : String) is
   begin
      if File_Contains (Report, Marker & "=confirmed") then
         Fail (Tool, "focused smoke report carried unrelated marker: " & Marker);
      end if;
   end Reject_Marker;

   procedure Run_Wrapper (Command : String) is
      Status : constant Integer := Run0 (Command);
   begin
      if Status /= 0 then
         Fail (Tool, Command & " failed");
      end if;
      Require_File (Tool, Report);
   end Run_Wrapper;
begin
   Run_Wrapper ("tools/bin/product_smoke_quick_open_file_tree");
   Require_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_edit_save");
   Require_Marker ("editing_save_conflict_free");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_daily_editing");
   Require_Marker ("daily_editing_workflow");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_workspace_session");
   Require_Marker ("workspace_save_restore_clear");
   Require_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_dirty_lifecycle_persistence");
   Require_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_build_ui_interaction");
   Require_Marker ("build_ui_interaction");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_command_palette_ranking");
   Require_Marker ("command_palette_ranking");
   Require_Marker ("command_palette_execution");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_diagnostics_problems");
   Require_Marker ("diagnostics_problems_filters");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_diagnostic_quick_fix");
   Require_Marker ("diagnostic_quick_fix");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("workspace_persistence_roundtrip");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");

   Run_Wrapper ("tools/bin/product_smoke_build_diagnostics");
   Require_Marker ("build_diagnostics_navigation");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("render_packet_nonempty");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Run_Wrapper ("tools/bin/product_smoke_render_packet");
   Require_Marker ("render_packet_nonempty");
   Reject_Marker ("quick_open_file_tree_navigation");
   Reject_Marker ("editing_save_conflict_free");
   Reject_Marker ("daily_editing_workflow");
   Reject_Marker ("workspace_save_restore_clear");
   Reject_Marker ("dirty_lifecycle_persistence");
   Reject_Marker ("build_ui_interaction");
   Reject_Marker ("diagnostics_problems_filters");
   Reject_Marker ("build_diagnostics_navigation");
   Reject_Marker ("command_palette_ranking");
   Reject_Marker ("command_palette_execution");
   Reject_Marker ("diagnostic_quick_fix");

   Info (Tool, "focused product smoke wrapper self-test passed");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
   when others =>
      if Ada.Directories.Current_Directory'Length > 0 then
         null;
      end if;
      Fail (Tool, "unexpected failure");
end Product_Smoke_Focus_Selftest;
