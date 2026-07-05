with Ada.Text_IO;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Release_Candidate_Check is
   Tool        : constant String := "release_candidate_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Release_State_File : constant String := "docs/release/RELEASE_STATE.txt";
   Manifest           : constant String := "docs/release/SHADER_TOOLCHAIN_VERSION.txt";
   Release_Report     : constant String :=
     Env ("EDITOR_RELEASE_CHECK_REPORT",
          "build/release-validation/release-check-validation.md");
   Runtime_Report     : constant String :=
     Env ("EDITOR_STRICT_RUNTIME_VALIDATION_REPORT",
          "build/release-validation/strict-runtime-validation.md");

   function Value_For (Path : String; Key : String) return String is
      F      : Ada.Text_IO.File_Type;
      Line   : String (1 .. 4096);
      Last   : Natural;
      Prefix : constant String := Key & "=";
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
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
   Require_File (Tool, Release_State_File);
   Require_File (Tool, Manifest);

   declare
      Release_State : constant String := Value_For (Release_State_File, "RELEASE_STATE");
      Candidate_Required : constant Boolean :=
        Release_State = "RELEASE_CANDIDATE"
        or else Strict ("EDITOR_REQUIRE_RELEASE_CANDIDATE")
        or else Strict ("EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION");
   begin
      if Release_State /= "DEVELOPMENT_SNAPSHOT"
        and then Release_State /= "RELEASE_CANDIDATE"
      then
         Fail
           (Tool,
            "docs/release/RELEASE_STATE.txt must declare "
            & "RELEASE_STATE=DEVELOPMENT_SNAPSHOT or "
            & "RELEASE_STATE=RELEASE_CANDIDATE");
      end if;

      if not Candidate_Required then
         Info
           (Tool,
            "release state is DEVELOPMENT_SNAPSHOT; release-candidate evidence is not required");
         return;
      end if;

      if Release_State = "RELEASE_CANDIDATE"
        and then File_Contains ("README.md", "current tree is a development snapshot")
      then
         Fail
           (Tool,
            "README still describes the tree as a development snapshot while RELEASE_STATE=RELEASE_CANDIDATE");
      end if;

      if not File_Contains (Manifest, "SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED") then
         Fail
           (Tool,
            "release-candidate status requires a RECORDED shader toolchain manifest");
      end if;

      if File_Contains (Manifest, "GLSLANG_VALIDATOR_VERSION_FIRST_LINE=UNRECORDED") then
         Fail
           (Tool,
            "release-candidate status requires the real glslangValidator version first line");
      end if;

      Require_Report
        (Release_Report,
         "release-check validation report",
         "PASS: release_check completed successfully.");

      Require_Report
        (Runtime_Report,
         "strict runtime validation report",
         "PASS: strict runtime validation completed successfully.");

      Info (Tool, "release-candidate status is backed by final validation evidence");
   end;
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Release_Candidate_Check;

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
