with Ada.Command_Line;

with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Test_Commands_For_Selftest is
   Tool : constant String := "test_commands_for_selftest";

   procedure Require_Output
     (Result : Captured_Command_Output;
      Needle : String)
   is
   begin
      if not Output_Contains (Result, Needle) then
         Fail (Tool, "test_commands_for output missing: " & Needle);
      end if;
   end Require_Output;

   Args : GNAT.OS_Lib.Argument_List (1 .. 4) :=
     (new String'("--why"),
      new String'("editor-executor.ali"),
      new String'("docs/archive/README_PASS1435.txt"),
      new String'("src/core/editor-executor.adb"));
   Result : Captured_Command_Output;
begin
   Require_File (Tool, "tools/bin/test_commands_for");

   Result := Run_Capture_Bounded
     ("tools/bin/test_commands_for",
      Args,
      "/tmp/editor_test_commands_for_selftest.out");

   if Result.Exit_Code /= 0 then
      Fail (Tool, "test_commands_for --why failed");
   end if;

   Require_Output
     (Result,
      "# ignored changed paths: archive=1, generated=1, empty=0");
   Require_Output
     (Result,
      "# why editor-executor.ali: ignored=generated");
   Require_Output
     (Result,
      "# why docs/archive/README_PASS1435.txt: ignored=archive");
   Require_Output
     (Result,
      "# why src/core/editor-executor.adb: slice=editor-core");
   Require_Output
     (Result,
      "tools/bin/unit_tests editor-core");

   Info (Tool, "test_commands_for ignored-path reporting passed");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when Program_Error =>
      null;
   when others =>
      Unexpected_Program_Error (Tool);
end Test_Commands_For_Selftest;
