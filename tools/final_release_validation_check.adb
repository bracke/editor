with Editor_Tool_Common; use Editor_Tool_Common;

procedure Final_Release_Validation_Check is
   Tool        : constant String := "final_release_validation_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Release_Report : constant String :=
     Env ("EDITOR_RELEASE_CHECK_REPORT",
          "build/release-validation/release-check-validation.md");
   Runtime_Report : constant String :=
     Env ("EDITOR_STRICT_RUNTIME_VALIDATION_REPORT",
          "build/release-validation/strict-runtime-validation.md");

   procedure Require_Report
     (Path      : String;
      Name      : String;
      Pass_Line : String) is
   begin
      Require_File (Tool, Path);

      if not File_Contains (Path, Pass_Line) then
         Fail (Tool, Name & " does not contain final PASS marker: " & Path);
      end if;

      if File_Contains (Path, "Result: FAIL") then
         Fail (Tool, Name & " contains a failed gate: " & Path);
      end if;

      if File_Contains (Path, "Result: TOOL NOT FOUND") then
         Fail (Tool, Name & " contains a missing required tool probe: " & Path);
      end if;

      if File_Contains (Path, "Result: NONZERO") then
         Fail (Tool, Name & " contains a nonzero optional gate result: " & Path);
      end if;
   end Require_Report;

begin
   Require_File (Tool, "docs/release/SHADER_TOOLCHAIN_VERSION.txt");
   if not File_Contains
       ("docs/release/SHADER_TOOLCHAIN_VERSION.txt",
        "SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED")
   then
      Fail
        (Tool,
         "final release validation requires a RECORDED shader toolchain manifest");
   end if;

   if File_Contains
       ("docs/release/SHADER_TOOLCHAIN_VERSION.txt",
        "GLSLANG_VALIDATOR_VERSION_FIRST_LINE=UNRECORDED")
   then
      Fail
        (Tool,
         "final release validation requires the real glslangValidator version first line");
   end if;

   Require_Report
     (Release_Report,
      "release-check validation report",
      "PASS: release_check completed successfully.");

   Require_Report
     (Runtime_Report,
      "strict runtime validation report",
      "PASS: strict runtime validation completed successfully.");

   Info (Tool, "final release validation evidence is complete");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Final_Release_Validation_Check;
