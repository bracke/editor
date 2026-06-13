with Editor_Tool_Common; use Editor_Tool_Common;

procedure Unit_Tests is
   Tool : constant String := "unit_tests";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
begin
   Require_File (Tool, "tests/tests.gpr");
   if not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_UNIT_TESTS") then
         Fail (Tool, "gprbuild not found");
      else
         Info (Tool, "gprbuild not found; unit tests skipped");
         return;
      end if;
   end if;

   Status := Run2 ("gprbuild", "-P", "tests/tests.gpr");
   if Status /= 0 then
      Fail (Tool, "unit test build failed");
   end if;

   Status := Run0 ("tests/bin/tests");
   if Status /= 0 then
      Fail (Tool, "unit tests failed");
   end if;

   Info (Tool, "unit tests passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Unit_Tests;
