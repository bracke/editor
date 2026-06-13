with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Runtime_Link_Check is
   Tool : constant String := "runtime_link_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
begin
   Require_File (Tool, "editor.gpr");
   if Command_Exists ("alr") then
      Status := Run1 ("alr", "build");
   elsif Command_Exists ("gprbuild") then
      Status := Run2 ("gprbuild", "-P", "editor.gpr");
   else
      if Strict ("EDITOR_REQUIRE_RUNTIME_LINK") then
         Fail (Tool, "neither alr nor gprbuild found");
      else
         Info (Tool, "neither alr nor gprbuild found; runtime link/build check skipped");
         return;
      end if;
   end if;

   if Status /= 0 then
      Fail (Tool, "runtime build/link failed");
   end if;

   if Strict ("EDITOR_REQUIRE_RUNTIME_EXE") and then not Ada.Directories.Exists ("bin/editor_app") then
      Fail (Tool, "canonical bin/editor_app executable was not produced");
   end if;
   Info (Tool, "runtime build/link check passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Runtime_Link_Check;
