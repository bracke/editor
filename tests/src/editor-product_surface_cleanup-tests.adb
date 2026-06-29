with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Editor.Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Feature_Search_Results;
with Editor.File_Tree;
with Editor.Outline;
with Editor.Outline.Fixtures; use Editor.Outline.Fixtures;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Product_Surface_Cleanup;
with Editor.Quick_Open;
with Editor.State;

package body Editor.Product_Surface_Cleanup.Tests is

   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Id;

   overriding function Name
     (T : Product_Surface_Cleanup_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Product_Surface_Cleanup");
   end Name;

   procedure Test_Normal_Startup_Has_No_Demo_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Product_Surface_Cleanup.Product_Surface_Cleanup_Result;
   begin
      Editor.State.Initialize (S);
      R := Editor.Product_Surface_Cleanup.Audit_Product_Surface_No_Demo_State (S);
      Assert (R.Feature_Panel_Clean, "normal startup has no placeholder feature rows");
      Assert (R.Outline_Clean, "normal startup has no synthetic outline rows");
      Assert (R.Diagnostics_Clean, "normal startup has no fake Diagnostics rows");
      Assert (R.Command_Surface_Clean, "normal command surface exposes no demo commands");
      Assert (R.Build_UI_Clean, "normal startup has no fake build candidates");
      Assert (R.Search_Clean, "normal startup has no fake project-search results");
      Assert (R.Quick_Open_Clean, "normal startup has no fake quick-open rows");
      Assert (R.File_Tree_Clean, "normal startup has no fake file-tree nodes");
      Assert (R.Coherent, "product surface cleanup audit is coherent");
   end Test_Normal_Startup_Has_No_Demo_Surface;

   procedure Test_Removed_Name_Demo_Command_Removed_From_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := True;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("populate-feature-panel-placeholder", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "removed placeholder population command is not registered");
      Assert (not Editor.Product_Surface_Cleanup.Demo_Command_Exposed_To_Product_Surface,
              "no demo command is exposed to palette or keybindings");
   end Test_Removed_Name_Demo_Command_Removed_From_Command_Surface;

   procedure Test_Test_Fixture_Placeholders_Are_Detected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);
      Assert (Editor.Product_Surface_Cleanup.Feature_Panel_Has_Demo_Rows (S),
              "audit detects explicit test fixture feature-panel rows");

      declare
         O_Result : constant Editor.Outline.Outline_Refresh_Result :=
           Editor.Outline.Fixtures.Populate_Synthetic_Outline (S.Outline);
         pragma Unreferenced (O_Result);
      begin
         Assert (Editor.Product_Surface_Cleanup.Outline_Has_Fixture_Data (S),
                 "audit detects explicit test fixture outline rows");
      end;
   end Test_Test_Fixture_Placeholders_Are_Detected;


   procedure Test_Audit_Detects_Normal_Surface_Demo_Leaks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidate : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Manual_Request_Candidate;
   begin
      Editor.State.Initialize (S);

      Editor.Diagnostics.Add
        (S.Diagnostics, 0, 1, Editor.Diagnostics.Warning,
         "fake diagnostic should never be normal product data");
      Assert (Editor.Product_Surface_Cleanup.Diagnostics_Has_Demo_Rows (S),
              "audit detects fake Diagnostics rows");

      Candidate.Display_Label :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("placeholder build candidate");
      S.Build_UI.Build_Candidates.Append (Candidate);
      Assert (Editor.Product_Surface_Cleanup.Build_UI_Has_Demo_State (S),
              "audit detects fake Build UI candidate state");

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label        => "demo search result",
         Source_Label => "placeholder source",
         Has_Target   => False);
      Assert (Editor.Product_Surface_Cleanup.Search_Has_Demo_Results (S),
              "audit detects fake active-buffer Search rows");

      Assert (not Editor.Product_Surface_Cleanup.Quick_Open_Has_Demo_Results (S),
              "empty Quick Open state has no fake rows");
      Assert (not Editor.Product_Surface_Cleanup.File_Tree_Has_Demo_Nodes (S),
              "empty File Tree state has no fake nodes");

      Assert (not Editor.Product_Surface_Cleanup.Assert_Product_Surface_No_Demo_State_Coherent (S),
        "coherence predicate rejects demo data on normal surfaces");
   end Test_Audit_Detects_Normal_Surface_Demo_Leaks;

   procedure Test_Product_Empty_And_Manual_Build_State_Not_Classified_As_Demo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Manual_Request_Candidate;
   begin
      Editor.State.Initialize (S);
      S.Build_UI.Build_Candidates.Append (Candidate);

      Assert (not Editor.Product_Surface_Cleanup.Build_UI_Has_Demo_State (S),
              "manual/unavailable build request state is a real empty workflow state, not demo data");
      Assert (Editor.Product_Surface_Cleanup.Assert_Product_Surface_No_Demo_State_Coherent (S),
        "manual build state remains product-surface clean");
   end Test_Product_Empty_And_Manual_Build_State_Not_Classified_As_Demo;


   procedure Test_Show_Focus_Toggle_Commands_Do_Not_Create_Demo_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Show_Feature_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_Feature_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Feature_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Feature_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Problems_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_Problems);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Quick_Open);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_File_Tree);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Project_Search_Bar);

      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "Feature Panel show/focus/toggle/clear do not create placeholder rows");
      Assert (Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0,
              "Problems show/focus commands do not create fake diagnostics");
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) = 0,
              "Quick Open show command does not create fake files");
      Assert (Editor.File_Tree.Node_Count (S.File_Tree) = 0,
              "File Tree focus command does not create fake nodes");
      Assert (Editor.Product_Surface_Cleanup.Assert_Product_Surface_No_Demo_State_Coherent (S),
        "normal show/focus/toggle commands leave product surfaces demo-free");
   end Test_Show_Focus_Toggle_Commands_Do_Not_Create_Demo_Data;


   procedure Test_Empty_States_Remain_Display_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);

      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "Feature Panel empty state has no data rows");
      Assert (Editor.Outline.Item_Count (S.Outline) = 0,
              "Outline empty state has no target rows");
      Assert (Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0,
              "Diagnostics empty state has no diagnostics rows");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "Build UI empty state has no candidates");
      Assert (Editor.Feature_Search_Results.Row_Count
                (S.Feature_Search_Results) = 0,
              "Search empty state has no search rows");
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) = 0,
              "Quick Open empty state has no file rows");
      Assert (Editor.File_Tree.Node_Count (S.File_Tree) = 0,
              "File Tree empty state has no file nodes");
      Assert (Editor.Product_Surface_Cleanup.Assert_Product_Surface_No_Demo_State_Coherent (S),
        "empty states are display-only and audit-clean");
   end Test_Empty_States_Remain_Display_Only;

   overriding procedure Register_Tests
     (T : in out Product_Surface_Cleanup_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Removed_Name_Demo_Command_Removed_From_Command_Surface'Access,
         "Phase 530 removed demo command is absent from command surface");
      Register_Routine
        (T, Test_Normal_Startup_Has_No_Demo_Surface'Access,
         "Phase 530 normal startup has no demo product surface");
      Register_Routine
        (T, Test_Test_Fixture_Placeholders_Are_Detected'Access,
         "Phase 530 audits detect explicit test fixture placeholders");
      Register_Routine
        (T, Test_Audit_Detects_Normal_Surface_Demo_Leaks'Access,
         "Phase 530 audit detects fake data on normal surfaces");
      Register_Routine
        (T, Test_Product_Empty_And_Manual_Build_State_Not_Classified_As_Demo'Access,
         "Phase 530 manual build empty state is not classified as demo data");
      Register_Routine
        (T, Test_Show_Focus_Toggle_Commands_Do_Not_Create_Demo_Data'Access,
         "Phase 530 normal show/focus/toggle commands do not create demo data");
      Register_Routine
        (T, Test_Empty_States_Remain_Display_Only'Access,
         "Phase 530 empty states remain display-only");
   end Register_Tests;

end Editor.Product_Surface_Cleanup.Tests;
