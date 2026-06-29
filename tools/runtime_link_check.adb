with Ada.Directories;
with Ada.Environment_Variables;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Runtime_Link_Check is
   use type GNAT.OS_Lib.String_Access;

   Tool : constant String := "runtime_link_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
   Alr : GNAT.OS_Lib.String_Access;
   Gprbuild : GNAT.OS_Lib.String_Access;
begin
   Require_File (Tool, "editor.gpr");
   Alr := GNAT.OS_Lib.Locate_Exec_On_Path ("alr");
   Gprbuild := GNAT.OS_Lib.Locate_Exec_On_Path ("gprbuild");

   if Alr /= null then
      if Ada.Environment_Variables.Exists ("HOME")
      then
         declare
            Home : constant String := Ada.Environment_Variables.Value ("HOME");
         begin
            if not Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
               Ada.Environment_Variables.Set
                 ("XDG_CONFIG_HOME", Home & "/.config");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_DATA_HOME") then
               Ada.Environment_Variables.Set
                 ("XDG_DATA_HOME", Home & "/.local/share");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_CACHE_HOME") then
               Ada.Environment_Variables.Set
                 ("XDG_CACHE_HOME", Home & "/.cache");
            end if;
         end;
      end if;

      declare
         Args : GNAT.OS_Lib.Argument_List (1 .. 5) :=
           (new String'("exec"),
            new String'("--"),
            new String'("gprbuild"),
            new String'("-P"),
            new String'("editor.gpr"));
      begin
         Status := Run (Alr.all, Args);
      end;
   elsif Gprbuild /= null then
      Status := Run2 (Gprbuild.all, "-P", "editor.gpr");
   else
      if Strict ("EDITOR_REQUIRE_RUNTIME_LINK") then
         Fail (Tool, "neither alr nor gprbuild found");
      else
         Info (Tool, "neither alr nor gprbuild found; runtime link/build check skipped");
         return;
      end if;
   end if;

   if Status /= 0 then
      Fail
        (Tool,
         "runtime build/link failed with exit status"
         & Integer'Image (Status));
   end if;

   if Strict ("EDITOR_REQUIRE_RUNTIME_EXE")
     and then not Ada.Directories.Exists ("bin/editor")
   then
      Fail (Tool, "canonical bin/editor executable was not produced");
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
