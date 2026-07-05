with Ada.Command_Line;
with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Editor_Workflow_Gate_Selftest is
   Tool : constant String := "editor_workflow_gate_selftest";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   procedure Require_Output
     (Result : Captured_Command_Output;
      Needle : String)
   is
   begin
      if not Output_Contains (Result, Needle) then
         Fail (Tool, "gate output missing: " & Needle);
      end if;
   end Require_Output;

   Args : GNAT.OS_Lib.Argument_List (1 .. 1) := (1 => new String'("--quick"));
   Result : Captured_Command_Output;
begin
   Require_File (Tool, "tools/bin/editor_workflow_gate");
   Result := Run_Capture_Bounded
     ("tools/bin/editor_workflow_gate",
      Args,
      "/tmp/editor_workflow_gate_selftest.out");

   if Result.Exit_Code /= 0 then
      Fail (Tool, "editor workflow gate --quick failed");
   end if;

   Require_Output
     (Result,
      "coverage: project open -> Quick Open -> file tree -> edit/save -> "
      & "workspace save/restore/clear confirmation -> command palette -> "
      & "Problems -> build -> Diagnostics -> render packet -> navigation back");
   Require_Output (Result, "running project/workspace unit slice");
   Require_Output (Result, "running editor core unit slice");
   Require_Output (Result, "running editor UI unit slice");
   Require_Output (Result, "running build/diagnostics unit slice");
   Require_Output (Result, "running documentation contract check");
   Require_Output (Result, "check_docs: documentation contract markers passed");
   Require_Output (Result, "running quick-open/file-tree product smoke");
   Require_Output (Result, "running command-palette product smoke");
   Require_Output (Result, "running diagnostics/problems product smoke");
   Require_Output (Result, "running Build UI product smoke");
   Require_Output (Result, "running render-packet product smoke");
   Require_Output
     (Result,
      "editor_product_smoke: behavior workspace save/restore/clear confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior quick-open file-tree navigation confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior editing save confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior build diagnostics navigation confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior diagnostics Problems filters confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior command palette ranking confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior workspace persistence roundtrip confirmed");
   Require_Output
     (Result,
      "editor_product_smoke: behavior render packet nonempty confirmed");
   Require_File (Tool, "/tmp/editor_product_smoke_report.txt");
   --  Focused smoke wrappers intentionally overwrite the shared product-smoke
   --  report; coverage is asserted from captured output above, and the final
   --  report should belong only to the last render-packet wrapper.
   if not File_Contains
     ("/tmp/editor_product_smoke_report.txt",
      "render_packet_nonempty=confirmed")
   then
      Fail (Tool, "product smoke report missing render behavior marker");
   end if;
   Require_Output
     (Result,
      "editor workflow gate passed; full all suite remains release-only");

   Info (Tool, "editor workflow gate self-test passed");
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
end Editor_Workflow_Gate_Selftest;
