with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;
with Test_Slice_Rules;

procedure Check_Repo_Hygiene is
   Tool : constant String := "check_repo_hygiene";

   procedure Require_Absent (Path : String; Message : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Fail (Tool, Message & ": " & Path);
      end if;
   end Require_Absent;

   procedure Require_No_Matching_Name
     (Directory : String;
      Pattern   : String;
      Message   : String)
   is
      Search : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
   begin
      if not Ada.Directories.Exists (Directory) then
         return;
      end if;

      Ada.Directories.Start_Search (Search, Directory, Pattern);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         Fail
           (Tool,
            Message & ": "
            & Ada.Directories.Compose
                (Directory, Ada.Directories.Simple_Name (Dir_Entry)));
      end loop;
      Ada.Directories.End_Search (Search);
   end Require_No_Matching_Name;

   procedure Require_No_Active_Text
     (Pattern : String;
      Message : String)
   is
      Args : GNAT.OS_Lib.Argument_List (1 .. 12) :=
        (new String'("-n"),
         new String'(Pattern),
         new String'("src/core"),
         new String'("tests/src"),
         new String'("tools"),
         new String'("config"),
         new String'("docs/testing.md"),
         new String'("docs/legacy_pass_migration.md"),
         new String'("--glob"),
         new String'("!docs/archive/**"),
         new String'("--glob"),
         new String'("!tools/check_repo_hygiene.adb"));
      Result : Captured_Command_Output;
   begin
      if not Command_Exists ("rg") then
         Fail (Tool, "rg is required for active hygiene scans");
      end if;

      Result := Run_Capture_Bounded
        ("rg", Args, "/tmp/check_repo_hygiene_rg.out", 16_384);
      if Result.Exit_Code = 0 then
         Fail (Tool, Message & ": " & Output_Text (Result));
      elsif Result.Exit_Code /= 1 then
         Fail (Tool, "active hygiene scan failed for pattern: " & Pattern);
      end if;
   end Require_No_Active_Text;

   procedure Require_Focused_Executor_Test_Slices is
      Search    : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
   begin
      if not Ada.Directories.Exists ("tests/src") then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search, "tests/src", "editor-executor-*_tests.adb");
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         declare
            Path : constant String :=
              Ada.Directories.Compose
                ("tests/src", Ada.Directories.Simple_Name (Dir_Entry));
         begin
            if Test_Slice_Rules.Slice_For (Path) = "editor-core" then
               Fail
                 (Tool,
                  "focused executor test package must route to a focused slice: "
                  & Path);
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);
   end Require_Focused_Executor_Test_Slices;
begin
   Require_Absent
     ("e2e_product_smoke_project",
      "product smoke fixture directory was left in the repo root");
   Require_Absent
     ("e2e_product_smoke_project_next",
      "dirty lifecycle product smoke fixture directory was left in the repo root");
   Require_Absent
     ("README_PASS1000.txt",
      "historical README_PASS files should be archived or ignored, not live");
   Require_Absent
     ("editor.o",
      "root-level generated object files should not be live repo evidence");
   Require_Absent
     ("text_buffer.ali",
      "root-level generated ALI files should not be live repo evidence");
   Require_No_Matching_Name
     (".", "phase*", "obsolete phase artifact should not be live");
   Require_No_Matching_Name
     ("tests", "phase*", "obsolete test phase artifact should not be live");
   Require_No_Active_Text
     ("phase[0-9]{3,}|Phase[0-9]{3,}",
      "obsolete phase wording should not appear in active sources");
   Require_No_Active_Text
     ("pass[0-9]{3,}|Pass[0-9]{3,}|_pass[0-9]{3,}",
      "obsolete numbered pass wording should not appear in active sources");
   Require_No_Active_Text
     ("Architecture_Cleanup_Pass1429|architecture_cleanup_pass1429"
      & "|Real_Ada_Corpus_Validation_Pass1430"
      & "|real_ada_corpus_validation_pass1430"
      & "|Release_Readiness_Validation_Pass1431"
      & "|release_readiness_validation_pass1431"
      & "|End_To_End_Editor_Integration_Validation_Pass1432"
      & "|end_to_end_editor_integration_validation_pass1432"
      & "|Documentation_Handoff_Pass1433|documentation_handoff_pass1433"
      & "|Performance_Boundedness_Validation_Pass1434"
      & "|performance_boundedness_validation_pass1434"
      & "|Diagnostic_Quality_Validation_Pass1435"
      & "|diagnostic_quality_validation_pass1435"
      & "|Project_Scale_Closure_Pass1436|project_scale_closure_pass1436"
      & "|Semantic_Integration_Audit_Pass1335"
      & "|semantic_integration_audit_pass1335"
      & "|Canonical_Semantic_Model_Agreement_Audit_Pass1336"
      & "|canonical_semantic_model_agreement_audit_pass1336"
      & "|End_To_End_Semantic_Scenario_Audit_Pass1337"
      & "|end_to_end_semantic_scenario_audit_pass1337"
      & "|RM_Coverage_Matrix_Audit_Pass1338"
      & "|rm_coverage_matrix_audit_pass1338"
      & "|RM_Coverage_Gap_Remediation_Audit_Pass1339"
      & "|rm_coverage_gap_remediation_audit_pass1339"
      & "|Semantic_Consumer_Enforcement_Audit_Pass1340"
      & "|semantic_consumer_enforcement_audit_pass1340"
      & "|Partial_Evidence_Precision_Audit_Pass1341"
      & "|partial_evidence_precision_audit_pass1341"
      & "|Semantic_Regression_Corpus_Balance_Audit_Pass1342"
      & "|semantic_regression_corpus_balance_audit_pass1342",
      "migrated validation and audit names must stay pass-free");
   Require_Focused_Executor_Test_Slices;

   if not File_Contains (".gitignore", "/README_PASS*.txt")
     or else not File_Contains (".gitignore", "/*_debug")
     or else not File_Contains (".gitignore", "/tools/bin/")
     or else not File_Contains (".gitignore", "/lib/*.o")
   then
      Fail (Tool, "generated artifact ignore policy is incomplete");
   end if;

   if File_Contains (".gitignore", "/phase")
     or else File_Contains (".gitignore", "/tests/phase")
   then
      Fail (Tool, "ignore policy must not preserve obsolete phase artifact names");
   end if;

   Info (Tool, "repository hygiene markers passed");
end Check_Repo_Hygiene;
