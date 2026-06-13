with Editor_Tool_Common; use Editor_Tool_Common;

procedure Real_Build_Runner_Smoke is
   Tool : constant String := "real_build_runner_smoke";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
begin
   Require_File (Tool, "tests/e2e_real_build_runner_smoke.gpr");
   if not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_REAL_BUILD_SMOKE") then
         Fail (Tool, "gprbuild not found");
      else
         Info (Tool, "gprbuild not found; real build-runner smoke skipped");
         return;
      end if;
   end if;
   Status := Run2 ("gprbuild", "-P", "tests/e2e_real_build_runner_smoke.gpr");
   if Status /= 0 then
      Fail (Tool, "real build-runner smoke build failed");
   end if;
   Status := Run0 ("tests/bin/editor_real_build_runner_smoke");
   if Status /= 0 then
      Fail (Tool, "real build-runner smoke failed");
   end if;
   Info (Tool, "real build-runner smoke passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Real_Build_Runner_Smoke;
