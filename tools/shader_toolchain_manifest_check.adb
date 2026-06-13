with Ada.Text_IO;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Shader_Toolchain_Manifest_Check is
   Tool : constant String := "shader_toolchain_manifest_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Manifest : constant String := "docs/release/SHADER_TOOLCHAIN_VERSION.txt";

   function Value_For (Key : String) return String is
      F      : Ada.Text_IO.File_Type;
      Line   : String (1 .. 4096);
      Last   : Natural;
      Prefix : constant String := Key & "=";
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Manifest);
      while not Ada.Text_IO.End_Of_File (F) loop
         Ada.Text_IO.Get_Line (F, Line, Last);
         if Last >= Prefix'Length
           and then Line (1 .. Prefix'Length) = Prefix
         then
            Ada.Text_IO.Close (F);
            return Line (Prefix'Length + 1 .. Last);
         end if;
      end loop;
      Ada.Text_IO.Close (F);
      return "";
   exception
      when others =>
         return "";
   end Value_For;

begin
   Require_File (Tool, Manifest);

   declare
      State        : constant String := Value_For ("SHADER_TOOLCHAIN_MANIFEST_STATE");
      Version_Line : constant String := Value_For ("GLSLANG_VALIDATOR_VERSION_FIRST_LINE");
      Require_Recorded : constant Boolean :=
        Strict ("EDITOR_REQUIRE_SHADER_TOOLCHAIN_MANIFEST")
        or else Strict ("EDITOR_REQUIRE_SHADER_FRESHNESS");
   begin
      if Version_Line = "" then
         Fail (Tool, "shader toolchain manifest does not contain GLSLANG_VALIDATOR_VERSION_FIRST_LINE");
      end if;

      if State /= ""
        and then State /= "UNRECORDED"
        and then State /= "RECORDED"
      then
         Fail (Tool, "shader toolchain manifest has invalid SHADER_TOOLCHAIN_MANIFEST_STATE=" & State);
      end if;

      if Version_Line = "UNRECORDED"
        or else State = "UNRECORDED"
        or else State = ""
      then
         if Require_Recorded then
            Fail (Tool, "shader toolchain manifest is unrecorded; run tools/bin/compile_shaders --record-toolchain-manifest with the release glslangValidator");
         else
            Info (Tool, "shader toolchain manifest is UNRECORDED; this is allowed for source snapshots but strict release validation will fail");
            return;
         end if;
      end if;

      if State = "RECORDED" and then Version_Line = "UNRECORDED" then
         Fail (Tool, "shader toolchain manifest state is RECORDED but version line is UNRECORDED");
      end if;

      Info (Tool, "shader toolchain manifest recorded: " & Version_Line);
   end;
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Shader_Toolchain_Manifest_Check;
