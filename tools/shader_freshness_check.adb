with Ada.Directories;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Shader_Freshness_Check is
   Tool : constant String := "shader_freshness_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Work : constant String := "build/shader-freshness-check";
   Status : Integer;

   function Glslang_First_Line return String is
      Args : GNAT.OS_Lib.Argument_List (1 .. 1) := (1 => new String'("--version"));
   begin
      return Capture_First_Line
        ("glslangValidator", Args, Work & "/glslangValidator-version.txt");
   end Glslang_First_Line;

   function Recorded_Glslang_First_Line return String is
      Prefix : constant String := "GLSLANG_VALIDATOR_VERSION_FIRST_LINE=";
      F      : Ada.Text_IO.File_Type;
      Line   : String (1 .. 4096);
      Last   : Natural;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, "docs/release/SHADER_TOOLCHAIN_VERSION.txt");
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
   end Recorded_Glslang_First_Line;

   procedure Check (Src, Checked : String) is
      Tmp : constant String := Work & "/" & Ada.Directories.Simple_Name (Checked);
   begin
      Require_File (Tool, Src);
      Require_File (Tool, Checked);
      Status := Run4 ("glslangValidator", "-V", Src, "-o", Tmp);
      if Status /= 0 then
         Fail (Tool, "glslangValidator failed for " & Src);
      end if;
      if not Files_Equal (Tmp, Checked) then
         Fail (Tool, "checked-in SPIR-V is stale for " & Src
               & "; run tools/bin/compile_shaders --record-toolchain-manifest"
               & " with the recorded release shader toolchain");
      end if;
   end Check;

begin
   if not Command_Exists ("glslangValidator") then
      if Strict ("EDITOR_REQUIRE_SHADER_FRESHNESS") then
         Fail (Tool, "glslangValidator not found");
      else
         Info (Tool, "glslangValidator not found; shader freshness check skipped");
         return;
      end if;
   end if;

   if not Ada.Directories.Exists ("build") then
      Ada.Directories.Create_Directory ("build");
   end if;
   if not Ada.Directories.Exists (Work) then
      Ada.Directories.Create_Directory (Work);
   end if;

   Require_File (Tool, "docs/release/SHADER_TOOLCHAIN_VERSION.txt");

   declare
      Current_Version  : constant String := Glslang_First_Line;
      Recorded_Version : constant String := Recorded_Glslang_First_Line;
      Require_Manifest : constant Boolean :=
        Strict ("EDITOR_REQUIRE_SHADER_TOOLCHAIN_MANIFEST")
        or else Strict ("EDITOR_REQUIRE_SHADER_FRESHNESS");
   begin
      if Current_Version = "" then
         Fail (Tool, "could not capture glslangValidator --version first line");
      end if;

      Info (Tool, "glslangValidator first line: " & Current_Version);

      if Require_Manifest then
         if Recorded_Version = "" then
            Fail
              (Tool,
               "shader toolchain manifest does not contain "
               & "GLSLANG_VALIDATOR_VERSION_FIRST_LINE");
         elsif Recorded_Version = "UNRECORDED" then
            Fail
              (Tool,
               "shader toolchain manifest is still UNRECORDED; run "
               & "tools/bin/compile_shaders --record-toolchain-manifest");
         elsif Recorded_Version /= Current_Version then
            Fail (Tool, "glslangValidator toolchain mismatch; recorded '" & Recorded_Version
                  & "' but current is '" & Current_Version
                  & "'. See docs/release/SHADER_TOOLCHAIN.md.");
         end if;
      elsif Recorded_Version /= "" and then Recorded_Version /= "UNRECORDED"
        and then Recorded_Version /= Current_Version
      then
         Info
           (Tool,
            "warning: current glslangValidator differs from recorded "
            & "release toolchain; strict mode would fail");
      end if;
   end;

   Check ("src/runtime/shaders/rect.vert", "src/runtime/shaders/rect.vert.spv");
   Check ("src/runtime/shaders/rect.frag", "src/runtime/shaders/rect.frag.spv");
   Check ("src/runtime/shaders/text.vert", "src/runtime/shaders/text.vert.spv");
   Check ("src/runtime/shaders/text.frag", "src/runtime/shaders/text.frag.spv");
   Info (Tool, "checked-in SPIR-V shaders match regenerated output");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Shader_Freshness_Check;
