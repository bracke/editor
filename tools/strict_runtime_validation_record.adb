with Ada.Calendar;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Strict_Runtime_Validation_Record is
   Tool : constant String := "strict_runtime_validation_record";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Out_Dir : constant String := Env ("EDITOR_RUNTIME_VALIDATION_REPORT_DIR", "build/release-validation");
   Report_Path : constant String := Out_Dir & "/strict-runtime-validation.md";
   F : Ada.Text_IO.File_Type;

   procedure Put (S : String) is
   begin
      Ada.Text_IO.Put_Line (F, S);
   end Put;

   procedure Put_Output_Block (Result : Captured_Command_Output) is
      Text : constant String := Output_Text (Result);
   begin
      Put ("Output provenance: merged stdout/stderr");
      Put ("```text");
      if Text'Length = 0 then
         Put ("(no output captured)");
      else
         Put (Text);
      end if;
      if Result.Truncated then
         Put ("");
         Put ("[output truncated by strict validation report capture limit]");
      end if;
      Put ("```");
   end Put_Output_Block;

   function Empty_Args return GNAT.OS_Lib.Argument_List is
      Args : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      return Args;
   end Empty_Args;

   procedure Capture_Info (Name, Program : String; Slug : String) is
      Args   : GNAT.OS_Lib.Argument_List (1 .. 0);
      Result : Captured_Command_Output;
   begin
      Put ("### " & Name);
      Put ("");
      Put ("Command: `" & Program & "`");
      if not Command_Exists (Program) then
         Put ("Result: TOOL NOT FOUND");
         Put ("");
         return;
      end if;

      Result := Run_Capture_Bounded
        (Program,
         Args,
         Out_Dir & "/" & Slug & ".out");
      Put ("Exit code: " & Integer'Image (Result.Exit_Code));
      Put ("Captured output:");
      Put_Output_Block (Result);
      Put ("");
   end Capture_Info;

   procedure Capture_Info_Arg1 (Name, Program, Arg1 : String; Slug : String) is
      Args   : GNAT.OS_Lib.Argument_List (1 .. 1) := (1 => new String'(Arg1));
      Result : Captured_Command_Output;
   begin
      Put ("### " & Name);
      Put ("");
      Put ("Command: `" & Program & " " & Arg1 & "`");
      if not Command_Exists (Program) then
         Put ("Result: TOOL NOT FOUND");
         Put ("");
         return;
      end if;

      Result := Run_Capture_Bounded
        (Program,
         Args,
         Out_Dir & "/" & Slug & ".out");
      Put ("Exit code: " & Integer'Image (Result.Exit_Code));
      Put ("Captured output:");
      Put_Output_Block (Result);
      Put ("");
   end Capture_Info_Arg1;

   procedure Capture_Info_Args
     (Name    : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Slug    : String)
   is
      Result : Captured_Command_Output;
      Command_Line : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Put ("### " & Name);
      Put ("");
      Ada.Strings.Unbounded.Append (Command_Line, Program);
      for I in Args'Range loop
         Ada.Strings.Unbounded.Append (Command_Line, " ");
         Ada.Strings.Unbounded.Append (Command_Line, Args (I).all);
      end loop;
      Put ("Command: `" & Ada.Strings.Unbounded.To_String (Command_Line) & "`");
      if not Command_Exists (Program) then
         Put ("Result: TOOL NOT FOUND");
         Put ("");
         return;
      end if;

      Result := Run_Capture_Bounded
        (Program,
         Args,
         Out_Dir & "/" & Slug & ".out");
      Put ("Exit code: " & Integer'Image (Result.Exit_Code));
      Put ("Captured output:");
      Put_Output_Block (Result);
      Put ("");
   end Capture_Info_Args;

   procedure Step (Name, Program, Slug : String) is
      Args   : GNAT.OS_Lib.Argument_List (1 .. 0);
      Result : Captured_Command_Output;
   begin
      Put ("## " & Name);
      Put ("");
      Put ("Command: `" & Program & "`");
      Result := Run_Capture_Bounded
        (Program,
         Args,
         Out_Dir & "/" & Slug & ".out");
      Put ("Exit code: " & Integer'Image (Result.Exit_Code));
      Put ("Captured output:");
      Put_Output_Block (Result);
      if Result.Exit_Code = 0 then
         Put ("Result: PASS");
      else
         Put ("Result: FAIL");
         Put ("");
         Ada.Text_IO.Close (F);
         Fail (Tool, Name & " failed; report written to " & Report_Path);
      end if;
      Put ("");
   end Step;

begin
   if not Ada.Directories.Exists ("build") then
      Ada.Directories.Create_Directory ("build");
   end if;
   if not Ada.Directories.Exists (Out_Dir) then
      Ada.Directories.Create_Path (Out_Dir);
   end if;

   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_COMPILE", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_LINK", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_EXE", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_SHADER_FRESHNESS", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_SHADER_TOOLCHAIN_MANIFEST", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_SMOKE", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_RUNTIME_MISSING_ASSET", "1");
   Ada.Environment_Variables.Set ("EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT", "1");

   Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Report_Path);
   Put ("# Strict runtime validation report");
   Put ("");
   Put ("Generated by the Ada tool `tools/bin/strict_runtime_validation_record`.");
   Put ("A report with skipped gates is not final runtime release approval.");
   Put ("");
   Put ("## Required gates");
   Put ("- Runtime C entrypoint/Ada backend gate");
   Put ("- Runtime link/build gate");
   Put ("- Canonical `bin/editor` executable gate");
   Put ("- Shader toolchain manifest gate");
   Put ("- Shader freshness gate");
   Put ("- Graphical GLFW/Vulkan smoke gate");
   Put ("- Strict runtime machine preflight gate");
   Put ("- Display-independent missing-shader negative gate");
   Put ("");

   Put ("## Strict environment");
   Put ("- `EDITOR_REQUIRE_RUNTIME_COMPILE=1`");
   Put ("- `EDITOR_REQUIRE_RUNTIME_LINK=1`");
   Put ("- `EDITOR_REQUIRE_RUNTIME_EXE=1`");
   Put ("- `EDITOR_REQUIRE_SHADER_FRESHNESS=1`");
   Put ("- `EDITOR_REQUIRE_SHADER_TOOLCHAIN_MANIFEST=1`");
   Put ("- `EDITOR_REQUIRE_RUNTIME_SMOKE=1`");
   Put ("- `EDITOR_REQUIRE_RUNTIME_MISSING_ASSET=1`");
   Put ("- `EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT=1`");
   Put ("");
   Put ("## Toolchain and platform probes");
   Put ("");
   Capture_Info_Arg1 ("gcc", "gcc", "--version", "toolchain-gcc");
   Capture_Info_Arg1 ("alr", "alr", "--version", "toolchain-alr");
   declare
      Gnatls_Args : GNAT.OS_Lib.Argument_List (1 .. 4) :=
        (new String'("exec"),
         new String'("--"),
         new String'("gnatls"),
         new String'("--version"));
   begin
      Capture_Info_Args ("Alire-selected GNAT", "alr", Gnatls_Args, "toolchain-gnatls");
   end;
   --  Report output file: toolchain-glslangvalidator.out
   Capture_Info_Arg1
     ("glslangValidator",
      "glslangValidator",
      "--version",
      "toolchain-glslangvalidator");
   Capture_Info_Arg1 ("vulkaninfo", "vulkaninfo", "--summary", "toolchain-vulkaninfo");

   Step ("strict runtime preflight", "tools/bin/strict_runtime_preflight", "gate-strict-runtime-preflight");
   Step ("runtime compile check", "tools/bin/runtime_compile_check", "gate-runtime-compile");
   Step ("runtime link check", "tools/bin/runtime_link_check", "gate-runtime-link");
   Step
     ("shader toolchain manifest check",
      "tools/bin/shader_toolchain_manifest_check",
      "gate-shader-toolchain-manifest");
   Step ("shader freshness check", "tools/bin/shader_freshness_check", "gate-shader-freshness");
   --  Report output file: gate-runtime-smoke.out
   Step ("runtime smoke", "tools/bin/runtime_smoke", "gate-runtime-smoke");
   Step
     ("missing shader negative check",
      "tools/bin/runtime_missing_asset_check",
      "gate-runtime-missing-asset");

   Put ("# Final result");
   Put ("PASS: strict runtime validation completed successfully.");
   Ada.Text_IO.Close (F);
   Info (Tool, "strict runtime validation passed; report written to " & Report_Path);
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Strict_Runtime_Validation_Record;

--  Case 946 guard: selected-name resolution foundation must remain parser-owned,
--  deterministic, snapshot-derived, and free of renderer-side parsing, file
--  reloads, dirty-state mutation, compiler invocation, LSP integration, external
--  parser generators, Python, and shell-script project hooks.

--  Case 947 guard: use-type primitive visibility foundation is covered by
--  Editor.Ada_Use_Type_Operators and
--  Test_Ada_Use_Type_Operator_Visibility_Foundation_Case 947.  This remains
--  snapshot-owned compiler-grade semantic metadata, not full overload/type
--  legality.

--  Case 948 guard: call-candidate overload foundation is covered by
--  Editor.Ada_Call_Candidates and
--  Test_Ada_Call_Candidate_Foundation_Case 948.  This remains a deterministic
--  compiler-grade semantic building block before expected-type/profile
--  filtering; it must not introduce compiler invocation, LSP, renderer-side
--  parsing, file IO, background scans, or dirty-state mutation.
