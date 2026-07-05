with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Product_Smoke is
   Tool : constant String := "product_smoke";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   procedure Normalize_Alire_Environment is
   begin
      if Ada.Environment_Variables.Exists ("HOME") then
         declare
            Home : constant String := Ada.Environment_Variables.Value ("HOME");
         begin
            if not Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
               Ada.Environment_Variables.Set ("XDG_CONFIG_HOME", Home & "/.config");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_DATA_HOME") then
               Ada.Environment_Variables.Set ("XDG_DATA_HOME", Home & "/.local/share");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_CACHE_HOME") then
               Ada.Environment_Variables.Set ("XDG_CACHE_HOME", Home & "/.cache");
            end if;
         end;
      end if;
   end Normalize_Alire_Environment;

   Status : Integer;
   Root   : constant String := Ada.Directories.Current_Directory;
   Scenario : constant String :=
     (if Ada.Command_Line.Argument_Count = 0
      then ""
      else Ada.Command_Line.Argument (1));
begin
   Require_File (Tool, "tests/e2e_product_smoke.gpr");
   if not Command_Exists ("alr") and then not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_PRODUCT_SMOKE") then
         Fail (Tool, "neither alr nor gprbuild found");
      else
         Info (Tool, "neither alr nor gprbuild found; product smoke skipped");
         return;
      end if;
   end if;
   if Command_Exists ("alr") then
      Normalize_Alire_Environment;
      Ada.Directories.Set_Directory ("tests");
      Status := Run4 ("alr", "exec", "--", "gprbuild", "-Pe2e_product_smoke.gpr");
      Ada.Directories.Set_Directory (Root);
   else
      Status := Run2 ("gprbuild", "-P", "tests/e2e_product_smoke.gpr");
   end if;
   if Status /= 0 then
      Fail (Tool, "product smoke build failed");
   end if;
   if Scenario'Length = 0 then
      Status := Run0 ("tests/bin/editor_product_smoke");
   else
      Status := Run1 ("tests/bin/editor_product_smoke", Scenario);
   end if;
   if Status /= 0 then
      Fail (Tool, "product smoke failed");
   end if;
   Info (Tool, "product smoke passed");
exception
   when Program_Error =>
      if Ada.Directories.Current_Directory /= Root then
         Ada.Directories.Set_Directory (Root);
      end if;
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Product_Smoke;
