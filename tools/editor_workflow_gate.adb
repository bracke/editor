with Ada.Command_Line;
with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Editor_Workflow_Gate is
   Tool : constant String := "editor_workflow_gate";
   Tool_Failed : Boolean := False;
   No_Build : Boolean := False;
   Quick    : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   procedure Print_Usage is
   begin
      Info
        (Tool,
         "usage: tools/bin/editor_workflow_gate [--no-build|--quick]");
      Info
        (Tool,
         "select focused checks first with: tools/bin/test_commands_for --why <changed-path>...");
      Info
        (Tool,
         "coverage: open project, Quick Open, file tree, edit/save, "
         & "workspace save/restore/clear, command palette, Problems, build, "
         & "diagnostics, render packet, navigation back");
   end Print_Usage;

   procedure Run_Unit_Slice (Label, Slice : String) is
      Status : Integer;
   begin
      Info (Tool, "running " & Label);
      if No_Build then
         declare
            Args : GNAT.OS_Lib.Argument_List (1 .. 2) :=
              (new String'(Slice),
               new String'("--no-build"));
         begin
            Status := Run ("tools/bin/unit_tests", Args);
         end;
      else
         Status := Run1 ("tools/bin/unit_tests", Slice);
      end if;

      if Status /= 0 then
         Fail (Tool, Label & " failed");
      end if;
   end Run_Unit_Slice;

   procedure Run_Focused_Product_Smoke (Command, Label : String) is
      Status : Integer;
   begin
      Info (Tool, "running " & Label);
      Status := Run0 (Command);
      if Status /= 0 then
         Fail (Tool, Label & " failed");
      end if;
   end Run_Focused_Product_Smoke;

   procedure Run_Docs_Check is
      Status : Integer;
   begin
      Info (Tool, "running documentation contract check");
      Status := Run0 ("tools/bin/check_docs");
      if Status /= 0 then
         Fail (Tool, "documentation contract check failed");
      end if;
   end Run_Docs_Check;
begin
   for I in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         Arg : constant String := Ada.Command_Line.Argument (I);
      begin
         if Arg = "--no-build" then
            No_Build := True;
         elsif Arg = "--quick" then
            Quick := True;
            No_Build := True;
         else
            Print_Usage;
            Fail (Tool, "unknown argument: " & Arg);
         end if;
      end;
   end loop;

   Require_File (Tool, "tools/bin/unit_tests");
   Require_File (Tool, "tools/bin/product_smoke");
   Require_File (Tool, "tools/bin/check_docs");

   Info
     (Tool,
      "coverage: project open -> Quick Open -> file tree -> edit/save -> "
      & "workspace save/restore/clear confirmation -> command palette -> "
      & "Problems -> build -> Diagnostics -> render packet -> navigation back");
   if Quick then
      Info (Tool, "quick mode: reusing already-built unit slices");
   elsif No_Build then
      Info (Tool, "no-build mode: forwarding --no-build to unit slices");
   end if;

   Run_Unit_Slice ("project/workspace unit slice", "project-workspace");
   Run_Unit_Slice ("editor core unit slice", "editor-core");
   Run_Unit_Slice ("editor UI unit slice", "editor-ui");
   Run_Unit_Slice ("build/diagnostics unit slice", "build-tools");
   Run_Docs_Check;
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_quick_open_file_tree",
      "quick-open/file-tree product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_edit_save",
      "edit/save product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_workspace_session",
      "workspace/session product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_command_palette_ranking",
      "command-palette product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_diagnostics_problems",
      "diagnostics/problems product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_diagnostic_quick_fix",
      "diagnostic quick-fix product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_build_ui_interaction",
      "Build UI product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_build_diagnostics",
      "build/diagnostics product smoke");
   Run_Focused_Product_Smoke
     ("tools/bin/product_smoke_render_packet",
      "render-packet product smoke");

   Info
     (Tool,
      "editor workflow gate passed; full all suite remains release-only");
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
end Editor_Workflow_Gate;
