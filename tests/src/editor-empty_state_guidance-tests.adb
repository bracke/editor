with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Commands;
with Editor.Configuration_Recovery;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Executor;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Diagnostics;
with Editor.Cursors;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.Render_Model;
with Editor.Messages;
with Editor.State;

package body Editor.Empty_State_Guidance.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Executor.Command_Execution_Status;
   use type Empty_State_Kind;
   use type Empty_State_Surface;

   overriding function Name
     (T : Empty_State_Guidance_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Empty_State_Guidance");
   end Name;

   procedure Test_First_Use_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Assert_First_Use_Empty_State_Guidance_Coherent,
              "first-use empty-state guidance must be coherent and display-only");
   end Test_First_Use_Coherent;

   procedure Test_First_Run_Main_Guidance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Snapshot.Surface = Main_Surface, "main guidance must target main surface");
      Assert (Snapshot.Kind = First_Run_State, "blank state must be first-run guidance");
      Assert (To_String (Snapshot.Primary_Message) = "Start by opening a project.",
              "primary first-run message must be deterministic");
      Assert (Snapshot.Suggestion_Count >= 4, "first-run should expose useful next actions");
      Assert (Snapshot.Suggestions (1).Command = Editor.Commands.Command_Open_Project,
              "open project must be the primary next action");
      Assert (To_String (Snapshot.Suggestions (1).Stable_Name) = "project.open",
              "suggestion must use the stable command name");
      Assert (not Snapshot.Suggestions (1).Carries_Payload,
              "suggestion must not carry a payload");
      Assert (Assert_Empty_State_Is_Display_Only (Snapshot),
              "first-run guidance must be display-only");
   end Test_First_Run_Main_Guidance;

   procedure Test_Render_Snapshot_Carries_Guidance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Render : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Render_Model.Build_Render_Snapshot (S, Render);
      Assert (Render.Main_Empty_State.Kind = First_Run_State,
              "render snapshot must include main empty-state guidance");
      Assert (Render.File_Tree_Empty_State.Kind = No_Project_State,
              "render snapshot must include File Tree no-project guidance");
      Assert (Render.Build_Empty_State.Kind = No_Project_State,
              "render snapshot must include Build no-project guidance");
      Assert (Assert_Empty_State_Suggestions_Have_No_Payloads (Render.Main_Empty_State),
              "rendered suggestions must not carry payloads");
   end Test_Render_Snapshot_Carries_Guidance;

   procedure Test_Project_Open_No_Buffer_Guidance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);
      Snapshot := Build_Main_Empty_State (S);
      Assert (Snapshot.Kind = No_Active_Buffer_State,
              "project-open empty editor must suggest file navigation");
      Assert (To_String (Snapshot.Primary_Message) = "Project open; no file selected.",
              "project-open no-buffer message must be deterministic");
      Assert (Assert_Empty_State_Is_Display_Only (Snapshot),
              "project-open no-buffer guidance must be display-only");
   end Test_Project_Open_No_Buffer_Guidance;

   procedure Test_Major_Surface_Coverage_Is_Descriptor_Derived
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Assert_Major_Empty_State_Surface_Coverage (S),
              "every major first-use surface must expose a primary message and no-payload suggestions");
      Assert (Assert_Empty_State_Suggestions_Are_Descriptor_Derived (Snapshot),
              "main suggestions must be projected from command descriptors");
      Assert (Assert_Empty_State_Suggestions_Are_Stable_Names_Only (Snapshot),
              "main suggestions must use stable command names only");
      Assert (Assert_Empty_State_Suggestions_Resolve_From_Stable_Names (Snapshot),
              "main suggestions must resolve back from stable command names");
   end Test_Major_Surface_Coverage_Is_Descriptor_Derived;

   procedure Test_Project_Open_Panel_Empty_States_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      File_Tree_State : Empty_State_Snapshot;
      Search_State    : Empty_State_Snapshot;
      Build_State     : Empty_State_Snapshot;
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);
      File_Tree_State := Build_File_Tree_Empty_State (S);
      Search_State := Build_Project_Search_Empty_State (S);
      Build_State := Build_Build_UI_Empty_State (S);

      Assert (File_Tree_State.Kind = Not_Refreshed_State,
              "project-open File Tree should distinguish unrefreshed state");
      Assert (Search_State.Kind = No_Query_State,
              "project-open Project Search should request an explicit query");
      Assert (Build_State.Kind = Not_Refreshed_State,
              "project-open Build UI should request explicit candidate refresh");
      Assert (Contains_Command_Suggestion
                (Build_State, Editor.Commands.Command_Build_Refresh_Candidates),
              "project-open Build UI should suggest Build candidate refresh");
      Assert (Contains_Command_Suggestion
                (Build_State, Editor.Commands.Command_Build_UI_Show),
              "project-open Build UI should suggest showing the Build UI");
      Assert (Assert_Empty_State_Is_Display_Only (File_Tree_State)
              and then Assert_Empty_State_Is_Display_Only (Search_State)
              and then Assert_Empty_State_Is_Display_Only (Build_State),
              "panel empty states must stay display-only");
   end Test_Project_Open_Panel_Empty_States_Are_Explicit;

   procedure Test_Build_Guidance_Uses_Row_Action_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);

      Snapshot := Build_Build_UI_Empty_State (S);
      Assert (Snapshot.Kind = Not_Refreshed_State,
              "Build guidance fixture should start in unrefreshed state");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_Refresh_Candidates),
              "unrefreshed Build guidance should suggest candidate refresh");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_UI_Show),
              "Build guidance should keep the panel action visible");
      Assert (not Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Refresh_Project_Files),
              "Build guidance should not use project-file refresh as a proxy");

      S.Build_UI.Candidate_Refresh_Status :=
        Editor.Build_UI.Build_Candidate_Refresh_No_Candidates;
      Snapshot := Build_Build_UI_Empty_State (S);
      Assert (Snapshot.Kind = No_Candidates_State,
              "Build guidance should distinguish refreshed empty candidates");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_Refresh_Candidates),
              "no-candidates Build guidance should suggest candidate refresh");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_UI_Show),
              "no-candidates Build guidance should keep the panel action visible");
      Assert (not Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Refresh_Project_Files),
              "no-candidates Build guidance should not use project-file refresh");
   end Test_Build_Guidance_Uses_Row_Action_Commands;

   procedure Test_Project_Search_No_Results_Guidance_Offers_Filter_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Snapshot : Empty_State_Snapshot;
      Valid : Boolean := False;
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);
      Editor.Project_Search.Set_Query (S.Project_Search, "absent");
      Editor.Project_Search.Set_Status
        (S.Project_Search, Editor.Project_Search.Project_Search_Ok);
      Editor.Project_Search.Set_Path_Scope (S.Project_Search, "src", Valid);
      Assert (Valid, "test scope should be valid");
      Editor.Project_Search.Set_Include_Path_Filter (S.Project_Search, "*.adb", Valid);
      Assert (Valid, "test include filter should be valid");
      Editor.Project_Search.Set_Exclude_Path_Filter (S.Project_Search, "obj", Valid);
      Assert (Valid, "test exclude filter should be valid");
      Editor.Project_Search.Set_Status
        (S.Project_Search, Editor.Project_Search.Project_Search_Ok);
      Editor.Project_Search.Clear_Stale (S.Project_Search);

      Snapshot := Build_Project_Search_Empty_State (S);
      Assert (Snapshot.Kind = No_Results_State,
              "no-result Project Search guidance should distinguish no matches");
      Assert (To_String (Snapshot.Primary_Message) = "No Project Search matches.",
              "no-result Project Search guidance should use product-facing copy");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Open_Project_Search_Bar),
              "no-result Project Search should offer query editing");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Project_Search_Scope_Clear),
              "no-result Project Search should offer scope clearing");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Project_Search_Include_Filter_Clear),
              "no-result Project Search should offer include-filter clearing");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Project_Search_Exclude_Filter_Clear),
              "no-result Project Search should offer exclude-filter clearing");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Run_Project_Search),
              "no-result Project Search should offer rerunning search");
   end Test_Project_Search_No_Results_Guidance_Offers_Filter_Recovery;

   procedure Test_Project_Search_Stale_Guidance_Offers_Rerun
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Project_Search.Set_Status
        (S.Project_Search, Editor.Project_Search.Project_Search_Ok);
      Editor.Project_Search.Mark_Stale_Unconditionally (S.Project_Search);

      Snapshot := Build_Project_Search_Empty_State (S);
      Assert (Snapshot.Kind = Stale_State,
              "stale Project Search guidance should be explicit");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Rerun_Project_Search),
              "stale Project Search should offer rerun");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Open_Project_Search_Bar),
              "stale Project Search should offer query/filter editing");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Clear_Project_Search),
              "stale Project Search should offer clearing stale results");
   end Test_Project_Search_Stale_Guidance_Offers_Rerun;

   procedure Test_Recent_Projects_Does_Not_Mutate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      Snapshot := Build_Recent_Projects_Empty_State (After);
      Assert (Snapshot.Kind = No_Recent_Projects_State,
              "empty recent projects must be explicit and semantically distinct");
      Assert (Editor.Recent_Projects.Count (Before.Recent_Projects) =
              Editor.Recent_Projects.Count (After.Recent_Projects),
              "recent-projects empty state must not create or remove entries");
      Assert (Assert_First_Run_Guidance_Fabricates_No_Project (Before, After),
              "guidance construction must not fabricate project or buffer state");
   end Test_Recent_Projects_Does_Not_Mutate;


   procedure Test_All_Surface_Snapshots_Are_Complete
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Snapshots'Length = Max_Empty_State_Surfaces,
              "all major empty-state surfaces must be represented");
      for I in Snapshots'Range loop
         Assert (Length (Snapshots (I).Primary_Message) > 0,
                 "every surface must have a deterministic primary message");
         Assert (Assert_Empty_State_Is_Display_Only (Snapshots (I)),
                 "every surface snapshot must be display-only");
         Assert (Assert_Empty_State_Suggestions_Are_Descriptor_Derived (Snapshots (I)),
                 "every suggestion must come from command descriptors");
         Assert (Assert_Empty_State_Suggestions_Resolve_From_Stable_Names (Snapshots (I)),
                 "every suggestion must resolve from its stable command name");
      end loop;
   end Test_All_Surface_Snapshots_Are_Complete;

   procedure Test_Diagnostics_Source_Less_Selected_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.Diagnostics.Add
        (S.Diagnostics,
         Start_Index => Editor.Cursors.Cursor_Index (1),
         End_Index   => Editor.Cursors.Cursor_Index (2),
         Severity    => Editor.Diagnostics.Warning,
         Message     => "source-less warning");
      S.Active_Diagnostic :=
        (Has_Active => True, Index => Editor.Diagnostics.Diagnostic_Index (1));

      Snapshot := Build_Diagnostics_Empty_State (S);
      Assert (Snapshot.Kind = Source_Less_Selected_State,
              "selected diagnostics without source targets need explicit guidance");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Diagnostics_Clear_Selected),
              "source-less diagnostic guidance should suggest clearing selected diagnostic");
      Assert (Assert_Empty_State_Is_Display_Only (Snapshot),
              "diagnostics empty guidance must not navigate or clear automatically");
   end Test_Diagnostics_Source_Less_Selected_State;

   procedure Test_Diagnostics_Selected_Unavailable_Target_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "missing source file",
         Source_Label  => "src/missing.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Snapshot := Build_Diagnostics_Empty_State (S);
      Assert (Snapshot.Kind = Selected_Unavailable_State,
              "selected missing Diagnostics targets need explicit recovery guidance");
      Assert (To_String (Snapshot.Primary_Message) =
                Editor.Commands.Reason_Target_Missing,
              "missing Diagnostics target guidance should use canonical missing-target wording");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Diagnostics_Clear_Selected),
              "missing Diagnostics target guidance should offer clearing the selected row");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "missing target line",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 42,
         Target_Line   => 0,
         Target_Column => 0);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Snapshot := Build_Diagnostics_Empty_State (S);
      Assert (Snapshot.Kind = Selected_Unavailable_State,
              "selected missing-line Diagnostics targets need explicit recovery guidance");
      Assert (Ada.Strings.Unbounded.Index
                (Snapshot.Primary_Message,
                 "Target line is unavailable") > 0,
              "missing-line Diagnostics guidance should use canonical target-line wording");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_UI_Show),
              "selected unavailable target guidance should offer inspecting/rerunning the producer");
   end Test_Diagnostics_Selected_Unavailable_Target_State;

   procedure Test_Diagnostics_Filtered_None_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "hidden warning",
         Source_Label => "build",
         Source_Kind  => Editor.Feature_Diagnostics.Project_Diagnostic_Source);
      Editor.Feature_Diagnostics.Filter_Errors_Only (S.Feature_Diagnostics);

      Snapshot := Build_Diagnostics_Empty_State (S);
      Assert (Snapshot.Kind = Filtered_None_State,
              "diagnostics guidance must distinguish filtered-empty from no diagnostics");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Diagnostics_Clear_Filter),
              "filtered-empty diagnostics should suggest clearing the filter");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "filtered-empty guidance must not delete diagnostic rows");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 0,
              "test fixture should remain filtered to zero visible rows");
   end Test_Diagnostics_Filtered_None_State;

   procedure Test_Diagnostics_Zero_Build_Result_Is_Contextual
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      S.Latest_Build_Result := Editor.Build_Result_Summary.Build_Summary
        (Kind           => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
         Invocation_Label => "gprbuild",
         Tool_Kind      => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode   => Editor.Build_Result_Summary.Build_Result_Request_Manual,
         Working_Context_Label => "/tmp/project",
         Runner_Status_Label => "succeeded",
         Primary_Message => "Build completed.",
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics,
         Diagnostics_Count => 0,
         Has_Diagnostics_Count => True);

      Snapshot := Build_Diagnostics_Empty_State (S);
      Assert (Snapshot.Kind = No_Build_Diagnostics_State,
              "zero-diagnostic build result should keep build-specific diagnostics context");
      Assert (To_String (Snapshot.Primary_Message) =
                "Build completed with no diagnostics.",
              "zero-diagnostic build result should say the build completed cleanly");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_UI_Show),
              "zero-diagnostic build guidance should suggest inspecting Build Output");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Build_Run),
              "zero-diagnostic build guidance should keep rerun build available");
   end Test_Diagnostics_Zero_Build_Result_Is_Contextual;


   procedure Test_Render_Construction_Is_Observational
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Render : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Render_Model.Build_Render_Snapshot (After, Render);
      Assert (Assert_Render_Empty_State_Construction_Is_Observational
                (Before, After),
              "render empty-state construction must not mutate project, buffers, panels, diagnostics, search, or build candidates");
      Assert (Render.Main_Empty_State.Kind = First_Run_State,
              "render still carries first-run state after observational construction");
   end Test_Render_Construction_Is_Observational;

   procedure Test_Main_Guidance_Uses_Metadata_Titles
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Open_Project),
              "main guidance should expose open-project action");
      Assert (Assert_Empty_State_Suggestions_Are_Descriptor_Derived (Snapshot),
              "suggestion titles must be copied from command descriptors");
      Assert (Assert_Empty_State_Suggestions_Are_Stable_Names_Only (Snapshot),
              "suggestions must carry only stable command names, not payloads");
      Assert (Assert_Empty_State_Suggestions_Resolve_From_Stable_Names (Snapshot),
              "suggestion activation must be able to resolve stable names without payloads");
   end Test_Main_Guidance_Uses_Metadata_Titles;


   procedure Test_Suggestion_Activation_Routes_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (After);
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Result := Activate_Suggested_Command (After, Snapshot, 1);
      Assert (Assert_Empty_State_Activation_Uses_Executor
                (Before, After, Result, Editor.Commands.Command_Open_Project),
              "suggestion activation must use the stable command id through Executor");
      Assert (Assert_First_Run_Guidance_Fabricates_No_Project (Before, After),
              "unavailable suggestion activation must not fabricate project state");
   end Test_Suggestion_Activation_Routes_Executor;

   procedure Test_Invalid_Suggestion_Activation_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Result := Activate_Suggested_Command
        (S, Snapshot, Positive (Max_Empty_State_Suggestions));
      Assert (Result.Command = Editor.Commands.No_Command,
              "out-of-range suggestion activation must carry no command");
      Assert (Assert_First_Run_Guidance_Fabricates_No_Project (S, S),
              "invalid activation must be a state no-op");
   end Test_Invalid_Suggestion_Activation_Is_No_Op;


   procedure Test_Payload_Like_Stable_Name_Activation_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Snapshot.Suggestions (1).Stable_Name :=
        To_Unbounded_String ("project.open:/tmp/project");
      Result := Activate_Suggested_Command (S, Snapshot, 1);
      Assert (Result.Command = Editor.Commands.No_Command,
              "payload-like stable command names must not activate");
      Assert (Assert_First_Run_Guidance_Fabricates_No_Project (S, S),
              "payload-like activation must not mutate project or buffer state");
   end Test_Payload_Like_Stable_Name_Activation_Is_No_Op;


   procedure Test_Suggestion_Safety_Rejects_Target_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Snapshot.Suggestions (1).Stable_Name := To_Unbounded_String ("project.open /tmp/project");
      Assert (not Suggestion_Is_Activation_Safe (Snapshot.Suggestions (1)),
              "target-bearing stable-name text must be rejected before Executor routing");

      Snapshot.Suggestions (1).Stable_Name := To_Unbounded_String ("project.open?path=/tmp/project");
      Assert (not Suggestion_Is_Activation_Safe (Snapshot.Suggestions (1)),
              "query-like stable-name text must be rejected before Executor routing");

      Snapshot.Suggestions (1).Stable_Name := To_Unbounded_String ("project.open");
      Assert (Suggestion_Is_Activation_Safe (Snapshot.Suggestions (1)),
              "canonical stable command name should remain activation-safe");
   end Test_Suggestion_Safety_Rejects_Target_Strings;

   procedure Test_Suggestion_Safety_Rejects_Hidden_Or_Mismatched_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Snapshot.Suggestions (1).Command := Editor.Commands.Command_Move_Left;
      Snapshot.Suggestions (1).Stable_Name :=
        To_Unbounded_String
          (Editor.Commands.Stable_Command_Name
             (Editor.Commands.Command_Move_Left));
      Snapshot.Suggestions (1).Title :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Move_Left).Name;
      Assert (not Suggestion_Is_Activation_Safe (Snapshot.Suggestions (1)),
              "hidden command metadata must not be activation-safe guidance");

      Snapshot := Build_Main_Empty_State (S);
      Snapshot.Suggestions (1).Title := To_Unbounded_String ("Open /tmp/project");
      Assert (not Suggestion_Is_Descriptor_Consistent (Snapshot.Suggestions (1)),
              "suggestion titles must match descriptor titles exactly and carry no target text");
      Assert (not Suggestion_Is_Activation_Safe (Snapshot.Suggestions (1)),
              "mismatched descriptor metadata must not activate");
   end Test_Suggestion_Safety_Rejects_Hidden_Or_Mismatched_Metadata;

   procedure Test_Guidance_State_Not_Persisted_Or_Stored
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (After);
   begin
      Assert (Snapshots'Length = Max_Empty_State_Surfaces,
              "guidance snapshots are returned values, not stored editor state");
      Assert (Assert_Empty_State_Not_Persisted (Before, After),
              "building guidance must not alter persistence-domain state");
   end Test_Guidance_State_Not_Persisted_Or_Stored;



   procedure Test_Surface_Labels_Are_Explicit_And_Unique
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Assert_All_Empty_State_Surfaces_Are_Present_Once (Snapshots),
              "aggregate guidance must contain each major surface exactly once");
      Assert (Assert_All_Empty_State_Surfaces_In_Canonical_Order (Snapshots),
              "aggregate guidance must keep the canonical render order stable");
      for I in Snapshots'Range loop
         Assert (Empty_State_Surface_Label (Snapshots (I).Surface)'Length > 0,
                 "each empty-state snapshot must expose a surface label");
         Assert (Empty_State_Kind_Label (Snapshots (I).Kind)'Length > 0,
                 "each empty-state snapshot must expose a state-kind label");
         Assert (Empty_State_Severity_Label (Snapshots (I).Severity)'Length > 0,
                 "each empty-state snapshot must expose a severity label");
         Assert (Assert_Empty_State_Display_Line_Is_Labelled (Snapshots (I)),
                 "display line must include surface, kind, and severity labels");
      end loop;
   end Test_Surface_Labels_Are_Explicit_And_Unique;

   procedure Test_Display_Lines_Are_Compact_And_Target_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for I in Snapshots'Range loop
         Assert (Assert_Empty_State_Text_Is_Deterministic_And_Compact (Snapshots (I)),
                 "empty-state guidance text must remain compact and deterministic");
         Assert (Assert_Empty_State_Snapshot_Has_No_Target_Text (Snapshots (I)),
                 "empty-state guidance must not contain project/file/result target text");
         Assert (Empty_State_Display_Line (Snapshots (I))'Length > 0,
                 "each empty-state snapshot must render to a display line");
         Assert (Assert_Empty_State_Display_Line_Is_Labelled (Snapshots (I)),
                 "display lines must expose surface, kind, and severity labels");
      end loop;
   end Test_Display_Lines_Are_Compact_And_Target_Free;

   procedure Test_Suggestions_Are_Unique_And_Tail_Clean
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for I in Snapshots'Range loop
         Assert (Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean
                   (Snapshots (I)),
                 "suggestion lists must contain no duplicate command rows and no stale tail entries");
      end loop;
   end Test_Suggestions_Are_Unique_And_Tail_Clean;

   procedure Test_Duplicate_Suggestion_Is_Collapsed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      Snapshot.Surface := Main_Surface;
      Snapshot.Kind := No_Project_State;
      Snapshot.Primary_Message := To_Unbounded_String ("No project open.");
      Snapshot.Suggestion_Count := 2;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Open_Project);
      Snapshot.Suggestions (2) :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Open_Project);

      Assert (not Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean
                    (Snapshot),
              "duplicate command suggestions must be detectable as invalid guidance");
   end Test_Duplicate_Suggestion_Is_Collapsed;

   procedure Test_Suggestion_Display_Line_Shows_Unavailable_Reason
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         declare
            Line : constant String := Suggestion_Display_Line (Snapshot.Suggestions (I));
         begin
            Assert (Line'Length > 0,
                    "visible suggestions must have compact display text");
            if not Snapshot.Suggestions (I).Available then
               Assert (Ada.Strings.Unbounded.Index
                         (To_Unbounded_String (Line), "unavailable") /= 0,
                       "unavailable suggestions must expose their unavailable state");
            end if;
         end;
      end loop;
   end Test_Suggestion_Display_Line_Shows_Unavailable_Reason;


   procedure Test_Non_Ready_States_Are_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for I in Snapshots'Range loop
         Assert (Assert_Non_Ready_Empty_State_Is_Actionable (Snapshots (I)),
                 "non-ready empty-state guidance must include at least one descriptor-derived command suggestion");
      end loop;
   end Test_Non_Ready_States_Are_Actionable;

   procedure Test_Outline_No_Buffer_Guidance_Is_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Outline_Empty_State (S);
   begin
      Assert (Snapshot.Kind = No_Active_Buffer_State,
              "outline without active buffer must keep the no-active-buffer state");
      Assert (Contains_Command_Suggestion
                (Snapshot, Editor.Commands.Command_Open_Project),
              "outline no-buffer guidance should provide a safe project-opening next action");
      Assert (Assert_Non_Ready_Empty_State_Is_Actionable (Snapshot),
              "outline no-buffer guidance must be actionable without parsing or navigation");
      Assert (Assert_Empty_State_Is_Display_Only (Snapshot),
              "outline no-buffer guidance must remain display-only");
   end Test_Outline_No_Buffer_Guidance_Is_Actionable;

   procedure Test_Semantic_State_Kinds_Are_Not_Collapsed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Recent : constant Empty_State_Snapshot :=
        Build_Recent_Projects_Empty_State (S);
      Config : constant Empty_State_Snapshot :=
        Build_Config_Recovery_Empty_State (S);
      Quick : constant Empty_State_Snapshot :=
        Build_Quick_Open_Empty_State (S);
   begin
      Assert (Recent.Kind = No_Recent_Projects_State,
              "recent-projects empty guidance must not collapse into generic no-results");
      Assert (Config.Kind = Clean_State,
              "configuration clean guidance must use an explicit clean state");
      Assert (Quick.Kind = No_Project_State,
              "quick-open before project open must remain no-project, not no-candidates");
      Assert (Empty_State_Kind_Label (No_Candidates_State) = "no candidates",
              "no-candidates state label must be deterministic");
      Assert (Empty_State_Kind_Label (Refresh_Required_State) = "refresh required",
              "refresh-required state label must be deterministic");
      Assert (Empty_State_Kind_Label (Selected_Unavailable_State) = "selected unavailable",
              "selected-unavailable state label must be deterministic");
   end Test_Semantic_State_Kinds_Are_Not_Collapsed;


   procedure Test_Ready_States_Are_Not_Rendered_As_Empty_Cards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Main : Empty_State_Snapshot;
   begin
      --  A ready snapshot may still be useful diagnostic/status data, but it
      --  must not be treated as an empty-state guidance card by render-facing
      --  code.  This prevents from turning normal editor surfaces
      --  into persistent onboarding cards.
      Editor.Project.Apply_Open_Result (S.Project, Result);
      S.Active_Buffer_Token := 1;
      Main := Build_Main_Empty_State (S);

      Assert (Main.Kind = Ready_State,
              "active-buffer main surface should be ready, not empty guidance");
      Assert (not Empty_State_Should_Render (Main),
              "ready snapshots must not render as empty-state cards");
      Assert (Assert_Ready_Empty_State_Is_Suppressed (Main),
              "ready snapshot suppression must be assertion-covered");
   end Test_Ready_States_Are_Not_Rendered_As_Empty_Cards;

   procedure Test_Non_Ready_States_Are_Renderable_Guidance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for I in Snapshots'Range loop
         if Snapshots (I).Kind /= Ready_State then
            Assert (Empty_State_Should_Render (Snapshots (I)),
                    "non-ready snapshots must remain renderable guidance cards");
         end if;
         Assert (Assert_Ready_Empty_State_Is_Suppressed (Snapshots (I)),
                 "render gating must agree with ready/non-ready state kind");
      end loop;
   end Test_Non_Ready_States_Are_Renderable_Guidance;

   procedure Test_Display_Line_Target_Guard_Covers_Final_Render_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for I in Snapshots'Range loop
         Assert (Assert_Empty_State_Display_Line_Is_Labelled (Snapshots (I)),
                 "final render line must remain labelled for each surface");
         Assert (Assert_Empty_State_Display_Line_Has_No_Target_Text (Snapshots (I)),
                 "final render line must not contain path, URI, query, or payload delimiters");
         Assert (Assert_Empty_State_Is_Display_Only (Snapshots (I)),
                 "central display-only assertion must include final-line guards");
      end loop;
   end Test_Display_Line_Target_Guard_Covers_Final_Render_Text;


   procedure Test_Renderable_Count_And_Severity_Are_Semantic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Empty_State_Renderable_Count (Snapshots) > 0,
              "first-use aggregate must expose at least one renderable guidance card");
      Assert (Empty_State_Renderable_Count (Snapshots) <= Max_Empty_State_Surfaces,
              "renderable guidance count must stay bounded by the surface array");

      for I in Snapshots'Range loop
         Assert (Assert_Empty_State_Severity_Is_Semantic (Snapshots (I)),
                 "empty-state severity must agree with the semantic state kind");
         if Empty_State_Should_Render (Snapshots (I)) then
            Assert (Snapshots (I).Kind /= Ready_State,
                    "only non-ready snapshots may be counted as renderable guidance");
         end if;
      end loop;
   end Test_Renderable_Count_And_Severity_Are_Semantic;


   procedure Test_Aggregate_Array_Is_Display_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Assert_Empty_State_Array_Is_Display_Only (Snapshots),
              "aggregate empty-state array must be canonical, bounded, and display-only");

      for I in Snapshots'Range loop
         Assert (Assert_Empty_State_Is_Display_Only (Snapshots (I)),
                 "aggregate member must preserve the central display-only invariant");
      end loop;
   end Test_Aggregate_Array_Is_Display_Only;


   procedure Test_Suggestion_Display_Lines_Are_Target_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Assert_Empty_State_Array_Suggestion_Budget (Snapshots),
              "aggregate guidance must stay within the bounded suggestion budget");
      Assert (Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text (Snapshot),
              "normal suggestion display lines must be target-free");

      Snapshot.Suggestions (1).Available := False;
      Snapshot.Suggestions (1).Unavailable_Reason :=
        To_Unbounded_String ("payload path=/tmp/project");
      Assert (not Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text (Snapshot),
              "target-like unavailable reasons must be rejected at final suggestion display line level");
      Assert (not Assert_Empty_State_Is_Display_Only (Snapshot),
              "central display-only invariant must include suggestion display-line target guards");
   end Test_Suggestion_Display_Lines_Are_Target_Free;


   procedure Test_Snapshot_Equivalence_Covers_All_Rendered_Fields
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Left : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Right : Empty_State_Snapshot := Left;
   begin
      Assert (Empty_State_Snapshots_Equivalent (Left, Right),
              "identical snapshots must compare equivalent");

      Right.Primary_Message := To_Unbounded_String ("Different primary");
      Assert (not Empty_State_Snapshots_Equivalent (Left, Right),
              "snapshot equivalence must include primary render text");

      Right := Left;
      Right.Suggestions (1).Unavailable_Reason :=
        To_Unbounded_String ("different reason");
      Assert (not Empty_State_Snapshots_Equivalent (Left, Right),
              "snapshot equivalence must include suggestion availability text");

      Right := Left;
      Right.Suggestions (1).Carries_Payload := True;
      Assert (not Empty_State_Snapshots_Equivalent (Left, Right),
              "snapshot equivalence must include no-payload suggestion state");

      Right := Left;
      Right.Suggestions (1).Activation_Mode := Suggestion_Display_Only;
      Assert (not Empty_State_Snapshots_Equivalent (Left, Right),
              "snapshot equivalence must include guided-action activation mode");

      Right := Left;
      Right.Suggestions (1).Selected := not Left.Suggestions (1).Selected;
      Assert (not Empty_State_Snapshots_Equivalent (Left, Right),
              "snapshot equivalence must include transient selection markers");

      Right := Left;
      Right.Suggestions (1).Availability_Label := To_Unbounded_String ("changed availability");
      Assert (not Empty_State_Snapshots_Equivalent (Left, Right),
              "snapshot equivalence must include explicit availability labels");
   end Test_Snapshot_Equivalence_Covers_All_Rendered_Fields;


   procedure Test_Canonical_Surface_Slot_Map_Is_Bidirectional
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Assert_Empty_State_Array_Uses_Canonical_Slots (Snapshots),
              "aggregate empty-state array must use canonical surface slots");

      for Surface in Empty_State_Surface loop
         declare
            Slot : constant Positive := Empty_State_Slot_For_Surface (Surface);
         begin
            Assert (Slot in 1 .. Max_Empty_State_Surfaces,
                    "surface slot must remain inside aggregate bounds");
            Assert (Empty_State_Surface_For_Slot (Slot) = Surface,
                    "surface to slot to surface mapping must round-trip");
            Assert (Snapshots (Slot).Surface = Surface,
                    "canonical aggregate slot must hold the expected surface");
         end;
      end loop;
   end Test_Canonical_Surface_Slot_Map_Is_Bidirectional;


   procedure Test_Surface_Model_Is_Closed_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Assert (Empty_State_Surface_Count = Max_Empty_State_Surfaces,
              "surface enum count must match aggregate capacity");
      Assert (Assert_Empty_State_Surface_Model_Is_Closed,
              "surface enum, slot map, and aggregate bounds must stay closed together");
      Assert (Assert_Empty_State_Array_Uses_Canonical_Slots (Snapshots),
              "canonical aggregate must use the closed surface-slot model");

      for I in 1 .. Max_Empty_State_Surfaces loop
         declare
            Surface : constant Empty_State_Surface :=
              Empty_State_Surface_For_Slot (I);
         begin
            Assert (Empty_State_Slot_For_Surface (Surface) = I,
                    "each canonical slot must round-trip through its surface");
         end;
      end loop;
   end Test_Surface_Model_Is_Closed_And_Bounded;


   procedure Test_Render_Model_Fields_Match_Canonical_Array
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Render : Editor.Render_Model.Render_Snapshot;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      Editor.Render_Model.Build_Render_Snapshot (S, Render);

      Assert (Empty_State_Snapshots_Equivalent
                (Render.Main_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Main_Surface))),
              "render main empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.File_Tree_Empty_State, Snapshots (Empty_State_Slot_For_Surface (File_Tree_Surface))),
              "render File Tree empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Quick_Open_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Quick_Open_Surface))),
              "render Quick Open empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Project_Search_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Project_Search_Surface))),
              "render Project Search empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Outline_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Outline_Surface))),
              "render Outline empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Diagnostics_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Diagnostics_Surface))),
              "render Diagnostics empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Build_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Build_Surface))),
              "render Build empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Recent_Projects_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Recent_Projects_Surface))),
              "render Recent Projects empty state must exactly match canonical aggregate slot");
      Assert (Empty_State_Snapshots_Equivalent
                (Render.Configuration_Recovery_Empty_State, Snapshots (Empty_State_Slot_For_Surface (Configuration_Recovery_Surface))),
              "render Configuration Recovery empty state must exactly match canonical aggregate slot");

      Assert (Assert_Empty_State_Array_Is_Display_Only (Snapshots),
              "canonical aggregate render contract must remain display-only");
   end Test_Render_Model_Fields_Match_Canonical_Array;


   procedure Test_Guided_Actions_Are_Command_Name_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Assert_Guided_Action_Routing_Coherent (S),
              "guided action routing should be coherent across empty-state surfaces");
      Assert (Snapshot.Suggestion_Count > 0,
              "main empty state should expose at least one guided action");
      Assert (Suggestion_Is_Activation_Safe (Snapshot.Suggestions (1)),
              "guided action must be descriptor-backed and activation-safe");
      Assert (not Snapshot.Suggestions (1).Carries_Payload,
              "guided action must not carry project/file/result/build payloads");
      Assert (Length (Snapshot.Suggestions (1).Availability_Label) > 0,
              "guided action must carry an availability snapshot label");
   end Test_Guided_Actions_Are_Command_Name_Only;

   procedure Test_Open_Suggestion_In_Command_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Editor.Command_Palette.Reset;
      Assert (Open_Suggested_Command_In_Command_Palette (Snapshot, 1),
              "opening a guided action should focus the Command Palette on the stable command");
      Assert (Editor.Command_Palette.Is_Open,
              "Command Palette should be open after guided-action palette activation");
      Assert (Editor.Command_Palette.Selected_Command = Snapshot.Suggestions (1).Command,
              "palette selection must be the suggested stable command only");
      Assert (not Editor.Command_Palette.Transient_State_Clear,
              "palette state is transient and should not be mistaken for persistence state while open");
      Editor.Command_Palette.Reset;
   end Test_Open_Suggestion_In_Command_Palette;

   procedure Test_Execute_Suggestion_Checks_Availability_First
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Result := Execute_Suggested_Command (S, Snapshot, 1);
      Assert (Result.Command = Snapshot.Suggestions (1).Command,
              "guided execution should resolve and report the selected stable command");
      Assert (Result.Status = Editor.Executor.Command_Unavailable
              or else Result.Status = Editor.Executor.Command_Executed
              or else Result.Status = Editor.Executor.Command_No_Op,
              "guided execution must use the normal Executor result states");
      Assert (Assert_First_Run_Guidance_Fabricates_No_Project (S, S),
              "blocked guided execution must not fabricate a project or hidden payload state");
   end Test_Execute_Suggestion_Checks_Availability_First;

   procedure Test_Suggestion_Selection_Is_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Next : Natural;
      Prev : Natural;
   begin
      Next := Suggested_Action_Select_Next (Snapshot, 0);
      Assert (Next = 1,
              "first suggestion selection should start at the first action row");
      Prev := Suggested_Action_Select_Previous (Snapshot, Next);
      Assert (Prev = Snapshot.Suggestion_Count,
              "previous from the first suggestion should wrap within the action list");
      Mark_Selected_Suggestion (Snapshot, Next);
      Assert (Snapshot.Suggestions (Next).Selected,
              "selection marker should be applied only to the transient snapshot");
      Mark_Selected_Suggestion (Snapshot, 0);
      Assert (not Snapshot.Suggestions (Next).Selected,
              "selection marker should clear without persisting state");
   end Test_Suggestion_Selection_Is_Transient;

   procedure Test_Activation_Mode_Opens_Palette_Without_Executing_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Index : Natural := 0;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Editor.Commands.Command_Open_Command_Palette then
            Index := I;
         end if;
      end loop;

      Assert (Index > 0,
              "first-run guidance should expose Command Palette as a guided entry point");
      Assert (Snapshot.Suggestions (Index).Activation_Mode =
                Suggestion_Open_In_Command_Palette,
              "Command Palette guidance should use palette-opening activation mode");
      Assert (Assert_Suggested_Action_Open_Palette_Carries_No_Payload
                (Snapshot, Positive (Index)),
              "palette-opening guided action must carry only a stable command name");

      Editor.Command_Palette.Reset;
      Result := Activate_Suggested_Command (S, Snapshot, Positive (Index));
      Assert (Result.Command = Editor.Commands.Command_Open_Command_Palette
              and then Result.Status = Editor.Executor.Command_Executed,
              "activation mode should report the palette-opening command, not a payload target");
      Assert (Editor.Command_Palette.Is_Open,
              "activation mode should open the Command Palette through the safe entry point");
      Editor.Command_Palette.Reset;
   end Test_Activation_Mode_Opens_Palette_Without_Executing_Target;

   procedure Test_Unavailable_Suggestion_Does_Not_Execute
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Snapshot.Surface := Outline_Surface;
      Snapshot.Kind := Not_Refreshed_State;
      Snapshot.Suggestion_Count := 1;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor (S, Editor.Commands.Command_Refresh_Outline);

      Assert (not Snapshot.Suggestions (1).Available,
              "refresh outline should be unavailable with no active buffer");
      Result := Execute_Suggested_Command (S, Snapshot, 1);
      Assert (Assert_Unavailable_Suggested_Action_Does_Not_Execute
                (Snapshot.Suggestions (1), Result),
              "unavailable guided action should be blocked before execution");
   end Test_Unavailable_Suggestion_Does_Not_Execute;

   procedure Test_Keybindings_Cannot_Carry_Suggestion_Payloads
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Assert_Keybindings_Have_No_Suggestion_Payloads,
              "keybindings must remain canonical command-name/chord routes without suggestion payloads");
   end Test_Keybindings_Cannot_Carry_Suggestion_Payloads;

   procedure Test_Selection_Skips_Display_Only_Suggestions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Next : Natural;
   begin
      Snapshot.Surface := Main_Surface;
      Snapshot.Kind := First_Run_State;
      Snapshot.Suggestion_Count := 2;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor (S, Editor.Commands.Command_Open_Project);
      Snapshot.Suggestions (1).Activation_Mode := Suggestion_Display_Only;
      Snapshot.Suggestions (2) :=
        Command_Suggestion_From_Descriptor (S, Editor.Commands.Command_Open_Command_Palette);

      Next := Suggested_Action_Select_Next (Snapshot, 0);
      Assert (Next = 2,
              "selection must skip display-only guidance rows and land on actionable suggestions");

      Mark_Selected_Suggestion (Snapshot, 1);
      Assert (not Snapshot.Suggestions (1).Selected,
              "display-only suggestions must not receive the selected action marker");
      Mark_Selected_Suggestion (Snapshot, 2);
      Assert (Snapshot.Suggestions (2).Selected,
              "actionable suggestions may receive the transient selected marker");
   end Test_Selection_Skips_Display_Only_Suggestions;

   procedure Test_Render_Building_Does_Not_Open_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Render : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Editor.Render_Model.Build_Render_Snapshot (S, Render);
      Assert (not Editor.Command_Palette.Is_Open,
              "render snapshot construction must not activate guided actions or open Command Palette");
      Assert (Assert_Empty_State_Suggestions_Have_No_Payloads (Render.Main_Empty_State),
              "rendered guided actions must remain no-payload command references");
   end Test_Render_Building_Does_Not_Open_Palette;

   procedure Test_Availability_Labels_Show_Guard_Class
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Consent : constant Empty_State_Suggested_Command :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Build_Acknowledge_Consent);
      Project_Open : constant Empty_State_Suggested_Command :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Open_Project);
   begin
      Assert (Ada.Strings.Unbounded.Index
                (To_Unbounded_String
                   (Suggested_Action_Availability_Label (Consent)),
                 "Consent required") > 0,
              "Build consent guidance should expose a consent-required availability marker");
      Assert (Ada.Strings.Unbounded.Index
                (To_Unbounded_String
                   (Suggested_Action_Availability_Label (Project_Open)),
                 "Project/file safety check") > 0,
              "lifecycle guided actions should expose that normal project/file safety checks still apply");
   end Test_Availability_Labels_Show_Guard_Class;

   procedure Test_Pending_Confirmation_Blocks_Conflicting_Suggestion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Snapshot.Surface := Main_Surface;
      Snapshot.Kind := First_Run_State;
      Snapshot.Suggestion_Count := 1;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor (S, Editor.Commands.Command_Open_Project);

      Editor.Configuration_Recovery.Request_Reset_All_Confirmation;
      Result := Execute_Suggested_Command (S, Snapshot, 1);
      Editor.Configuration_Recovery.Clear_Reset_All_Confirmation;

      Assert (Result.Command = Editor.Commands.Command_Open_Project
              and then Result.Status = Editor.Executor.Command_Unavailable,
              "pending confirmations must make conflicting suggested execution unavailable");
      Assert (Assert_First_Run_Guidance_Fabricates_No_Project (S, S),
              "blocked pending-confirmation suggestion must not fabricate project state");
   end Test_Pending_Confirmation_Blocks_Conflicting_Suggestion;

   procedure Test_Suggested_Action_Route_Audit_Rejects_Bypass_And_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Suggested_Action_Route
        (Result                   => Audit,
         Command                  => Editor.Commands.Command_Open_Project,
         Routed_Through_Executor  => True,
         Used_Stable_Command_Name => True,
         Availability_Checked     => True,
         Carried_Payload          => False);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "safe guided-action route should pass route audit");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Suggested_Action_Route
        (Result                   => Audit,
         Command                  => Editor.Commands.Command_Open_Project,
         Routed_Through_Executor  => False,
         Used_Stable_Command_Name => False,
         Availability_Checked     => False,
         Carried_Payload          => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 4,
              "guided-action route audit must reject Executor bypass, display-label routing, availability bypass, and payloads");
   end Test_Suggested_Action_Route_Audit_Rejects_Bypass_And_Payload;

   procedure Test_Suggested_Action_Route_Audit_Allows_Palette_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Suggested_Action_Route
        (Result                               => Audit,
         Command                              => Editor.Commands.Command_Open_Project,
         Routed_Through_Executor              => False,
         Used_Stable_Command_Name             => True,
         Availability_Checked                 => True,
         Carried_Payload                      => False,
         Routed_Through_Command_Palette_Entry => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "guided open-in-palette routes should pass through the canonical palette entry without being treated as Executor bypasses");
   end Test_Suggested_Action_Route_Audit_Allows_Palette_Entry;

   procedure Test_Suggested_Action_Route_Audit_Rejects_Mixed_Route_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Suggested_Action_Route
        (Result                               => Audit,
         Command                              => Editor.Commands.Command_Open_Project,
         Routed_Through_Executor              => True,
         Used_Stable_Command_Name             => True,
         Availability_Checked                 => True,
         Carried_Payload                      => False,
         Routed_Through_Command_Palette_Entry => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
              "guided routes must not mix direct Executor dispatch and palette-entry routing in one activation");
   end Test_Suggested_Action_Route_Audit_Rejects_Mixed_Route_Mode;

   procedure Test_Metadata_Currentness_Rejects_Stale_Descriptor_Copy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Snapshot.Suggestion_Count > 0,
              "test setup should expose a descriptor-derived guided action");
      Assert (Assert_Suggested_Action_Metadata_Is_Current (Snapshot.Suggestions (1)),
              "fresh guided action metadata should match the current command descriptor");

      Snapshot.Suggestions (1).Short_Explanation := To_Unbounded_String ("stale copied help text");
      Assert (not Assert_Suggested_Action_Metadata_Is_Current (Snapshot.Suggestions (1)),
              "metadata assertion must reject stale copied command descriptions");
      Assert (not Assert_Empty_State_Is_Display_Only (Snapshot),
              "empty-state coherence must reject stale copied descriptor metadata");
   end Test_Metadata_Currentness_Rejects_Stale_Descriptor_Copy;

   procedure Test_Selection_Clears_When_Surface_Has_No_Suggestions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Ready : Empty_State_Snapshot;
   begin
      Mark_Selected_Suggestion (Snapshot, 1);
      Assert (Snapshot.Suggestions (1).Selected,
              "test setup should mark a transient guided action selection");

      Ready.Surface := Main_Surface;
      Ready.Kind := Ready_State;
      Ready.Suggestion_Count := 0;
      Mark_Selected_Suggestion (Ready, 1);

      for I in 1 .. Max_Empty_State_Suggestions loop
         Assert (not Ready.Suggestions (I).Selected,
                 "surface without suggestions must not retain selected guided-action state");
      end loop;
   end Test_Selection_Clears_When_Surface_Has_No_Suggestions;

   procedure Test_Palette_Open_Blocked_By_Pending_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Editor.Command_Palette.Reset;
      Editor.Configuration_Recovery.Request_Reset_All_Confirmation;
      Assert (not Open_Suggested_Command_In_Command_Palette (Snapshot, 1),
              "pending confirmation must block conflicting guided palette opening");
      Editor.Configuration_Recovery.Clear_Reset_All_Confirmation;
      Assert (not Editor.Command_Palette.Is_Open,
              "blocked guided palette opening must not transfer focus to the Command Palette");
   end Test_Palette_Open_Blocked_By_Pending_Confirmation;

   procedure Test_Execute_Respects_Activation_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Snapshot.Surface := Main_Surface;
      Snapshot.Kind := First_Run_State;
      Snapshot.Suggestion_Count := 1;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Open_Command_Palette);
      Snapshot.Suggestions (1).Activation_Mode := Suggestion_Open_In_Command_Palette;

      Result := Execute_Suggested_Command (S, Snapshot, 1);
      Assert (Result.Command = Editor.Commands.Command_Open_Command_Palette
              and then Result.Status = Editor.Executor.Command_No_Op,
              "direct guided execution must not execute a palette-opening suggestion mode");

      Snapshot.Suggestions (1).Activation_Mode := Suggestion_Display_Only;
      Result := Execute_Suggested_Command (S, Snapshot, 1);
      Assert (Result.Command = Editor.Commands.Command_Open_Command_Palette
              and then Result.Status = Editor.Executor.Command_No_Op,
              "direct guided execution must not execute display-only suggestions");
   end Test_Execute_Respects_Activation_Mode;

   procedure Test_Unavailable_Execution_Reports_Normal_Reason
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Before_Messages : Natural;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Snapshot.Surface := Outline_Surface;
      Snapshot.Kind := Not_Refreshed_State;
      Snapshot.Suggestion_Count := 1;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor (S, Editor.Commands.Command_Refresh_Outline);

      Before_Messages := Editor.Messages.Count (S.Messages);
      Result := Execute_Suggested_Command (S, Snapshot, 1);

      Assert (Result.Command = Editor.Commands.Command_Refresh_Outline
              and then Result.Status = Editor.Executor.Command_Unavailable,
              "unavailable guided execution must remain unavailable");
      Assert (Editor.Messages.Count (S.Messages) > Before_Messages,
              "unavailable guided execution must report through the normal Executor message path");
   end Test_Unavailable_Execution_Reports_Normal_Reason;

   procedure Test_Empty_State_Assertion_Covers_Suggestion_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.State.State_Type;
      After  : Editor.State.State_Type := Before;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (Before);
   begin
      Mark_Selected_Suggestion (Snapshot, 1);
      Assert (Snapshot.Suggestions (1).Selected,
              "test setup should prove guided-action selection can exist transiently");
      Assert (Assert_Empty_State_Not_Persisted (Before, After),
              "guided-action suggestions and selected marker must have no workspace/settings/recent persistence footprint");
   end Test_Empty_State_Assertion_Covers_Suggestion_Persistence;


   procedure Test_Surface_Source_Labels_Are_Owned_By_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for Surface_Index in Snapshots'Range loop
         declare
            Snapshot : constant Empty_State_Snapshot := Snapshots (Surface_Index);
            Expected : constant String := Empty_State_Surface_Label (Snapshot.Surface);
         begin
            for I in 1 .. Snapshot.Suggestion_Count loop
               Assert
                 (To_String (Snapshot.Suggestions (I).Surface_Source_Label) = Expected,
                  "guided-action source labels must be owned by the emitting surface");
               Assert
                 (Expected'Length > 0,
                  "guided-action source labels must be explicit and non-empty");
            end loop;
         end;
      end loop;
   end Test_Surface_Source_Labels_Are_Owned_By_Surface;

   procedure Test_Display_Only_Suggestion_Cannot_Open_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
   begin
      Editor.Command_Palette.Reset;
      Snapshot.Surface := Main_Surface;
      Snapshot.Kind := First_Run_State;
      Snapshot.Suggestion_Count := 1;
      Snapshot.Suggestions (1) :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Open_Command_Palette);
      Snapshot.Suggestions (1).Activation_Mode := Suggestion_Display_Only;

      Assert (not Open_Suggested_Command_In_Command_Palette (Snapshot, 1),
              "display-only guided actions must not open the Command Palette");
      Assert (not Editor.Command_Palette.Is_Open,
              "rejected display-only suggestion must not transfer focus");
   end Test_Display_Only_Suggestion_Cannot_Open_Palette;

   procedure Test_Activate_Pending_Block_Reports_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
      Before_Messages : Natural;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Configuration_Recovery.Request_Reset_All_Confirmation;
      Before_Messages := Editor.Messages.Count (S.Messages);
      Result := Activate_Suggested_Command (S, Snapshot, 1);
      Editor.Configuration_Recovery.Clear_Reset_All_Confirmation;

      Assert (Result.Command = Editor.Commands.Command_Open_Project
              and then Result.Status = Editor.Executor.Command_Unavailable,
              "conflicting guided activation must remain unavailable while confirmation is pending");
      Assert (Editor.Messages.Count (S.Messages) > Before_Messages,
              "blocked guided activation must leave a clear outcome message");
   end Test_Activate_Pending_Block_Reports_Message;


   procedure Test_Selected_Index_Is_Single_And_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      First : Natural;
   begin
      First := Suggested_Action_Select_Next (Snapshot, 0);
      Assert (First > 0,
              "test setup should find an actionable guided suggestion");

      Mark_Selected_Suggestion (Snapshot, First);
      Assert (Suggested_Action_Selected_Index (Snapshot) = First,
              "selected guided-action index must resolve to exactly one actionable row");
      Assert (Assert_Selected_Suggested_Action_Is_Actionable (Snapshot),
              "selected guided action must be actionable, descriptor-backed, and no-payload");

      if Snapshot.Suggestion_Count >= 2 then
         Snapshot.Suggestions (2).Selected := True;
         Assert (Suggested_Action_Selected_Index (Snapshot) = 0,
                 "multiple selected guided actions must be treated as invalid selection state");
         Assert (not Assert_Selected_Suggested_Action_Is_Actionable (Snapshot),
                 "assertion must reject ambiguous guided-action selection");
      end if;
   end Test_Selected_Index_Is_Single_And_Actionable;

   procedure Test_Activation_Mode_Coherence_Is_Asserted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Suggestion : Empty_State_Suggested_Command :=
        Command_Suggestion_From_Descriptor
          (S, Editor.Commands.Command_Open_Project);
   begin
      Assert (Assert_Suggested_Action_Activation_Mode_Is_Coherent (Suggestion),
              "normal guided action activation mode should be coherent");

      Suggestion.Activation_Mode := Suggestion_Display_Only;
      Suggestion.Selected := True;
      Assert (not Assert_Suggested_Action_Activation_Mode_Is_Coherent (Suggestion),
              "display-only guided action must not be allowed to carry selected actionable state");

      Suggestion.Selected := False;
      Suggestion.Carries_Payload := True;
      Assert (not Assert_Suggested_Action_Activation_Mode_Is_Coherent (Suggestion),
              "activation-mode assertion must still reject payload-bearing suggestions");
   end Test_Activation_Mode_Coherence_Is_Asserted;

   procedure Test_Selected_Activation_Uses_Selected_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Selected : Natural;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Selected := Suggested_Action_Select_Next (Snapshot, 0);
      Assert (Selected > 0,
              "test setup should find a selectable guided action");
      Mark_Selected_Suggestion (Snapshot, Selected);

      Result := Execute_Selected_Suggested_Command (S, Snapshot);
      Assert (Result.Command = Snapshot.Suggestions (Selected).Command,
              "execute-selected must resolve the command from the selected suggestion only");

      Mark_Selected_Suggestion (Snapshot, 0);
      Result := Execute_Selected_Suggested_Command (S, Snapshot);
      Assert (Result.Command = Editor.Commands.No_Command,
              "execute-selected must no-op when no guided suggestion is selected");
   end Test_Selected_Activation_Uses_Selected_Index;

   procedure Test_Source_And_Availability_Assertions_Reject_Stale_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned (Snapshot),
              "fresh guided-action source labels should match their emitting surface");
      Assert (Assert_Suggested_Action_Availability_Label_Is_Current
                (S, Snapshot.Suggestions (1)),
              "fresh guided-action availability labels should reflect current availability");

      Snapshot.Suggestions (1).Surface_Source_Label := To_Unbounded_String ("wrong surface");
      Assert (not Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned (Snapshot),
              "source-label assertion must reject stale or cross-surface suggestion state");

      Snapshot := Build_Main_Empty_State (S);
      Snapshot.Suggestions (1).Availability_Label := To_Unbounded_String ("Available");
      Snapshot.Suggestions (1).Available := not Snapshot.Suggestions (1).Available;
      Assert (not Assert_Suggested_Action_Availability_Label_Is_Current
                (S, Snapshot.Suggestions (1)),
              "availability assertion must reject stale guided-action labels");
   end Test_Source_And_Availability_Assertions_Reject_Stale_Snapshot;


   procedure Test_Indexed_Activation_Rejects_Mismatched_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Selected : Natural;
      Other    : Natural := 0;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Selected := Suggested_Action_Select_Next (Snapshot, 0);
      Assert (Selected > 0,
              "test setup should find a selectable guided action");

      for I in 1 .. Snapshot.Suggestion_Count loop
         if I /= Selected
           and then Snapshot.Suggestions (I).Activation_Mode =
             Suggestion_Execute_Through_Executor
         then
            Other := I;
            exit;
         end if;
      end loop;

      Assert (Other > 0,
              "test setup should contain another executable suggestion");
      Mark_Selected_Suggestion (Snapshot, Selected);

      Assert (not Assert_Suggested_Action_Index_Is_Activatable
                (Snapshot, Positive (Other)),
              "indexed activation must reject rows that conflict with the selected guided action");
      Result := Execute_Suggested_Command (S, Snapshot, Positive (Other));
      Assert (Result.Command = Editor.Commands.No_Command,
              "mismatched indexed activation must no-op instead of executing another row");
   end Test_Indexed_Activation_Rejects_Mismatched_Selection;

   procedure Test_Phase_Fields_Are_Clean_Beyond_Suggestion_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
      Tail : Positive;
   begin
      Assert (Snapshot.Suggestion_Count < Max_Empty_State_Suggestions,
              "test setup should leave at least one unused suggestion slot");
      Assert (Assert_Empty_State_Suggestion_Tail_Is_Clean (Snapshot),
              "fresh snapshots must keep all fields clean beyond Suggestion_Count");

      Tail := Positive (Snapshot.Suggestion_Count + 1);
      Snapshot.Suggestions (Tail).Availability_Label :=
        To_Unbounded_String ("stale availability");
      Assert (not Assert_Empty_State_Suggestion_Tail_Is_Clean (Snapshot),
              "tail-clean assertion must reject stale availability labels");

      Snapshot.Suggestions (Tail).Availability_Label := Null_Unbounded_String;
      Snapshot.Suggestions (Tail).Activation_Mode := Suggestion_Open_In_Command_Palette;
      Assert (not Assert_Empty_State_Suggestion_Tail_Is_Clean (Snapshot),
              "tail-clean assertion must reject stale activation modes");
   end Test_Phase_Fields_Are_Clean_Beyond_Suggestion_Count;





   procedure Test_Suggestions_Are_Canonical_Surface_Projections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      for I in Snapshots'Range loop
         Assert (Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections
                   (S, Snapshots (I)),
                 "guided suggestions must come from the canonical descriptor projection for their surface");
      end loop;
   end Test_Suggestions_Are_Canonical_Surface_Projections;

   procedure Test_Canonical_Projection_Rejects_Hand_Rolled_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot := Build_Main_Empty_State (S);
   begin
      Assert (Snapshot.Suggestion_Count > 0,
              "test setup should expose at least one guided suggestion");
      Assert (Assert_Suggested_Action_Is_Canonical_Surface_Projection
                (S, Snapshot.Surface, Snapshot.Suggestions (1)),
              "fresh guided suggestion should match the canonical surface projection");

      Snapshot.Suggestions (1).Short_Explanation :=
        To_Unbounded_String ("hand-rolled explanation");
      Assert (not Assert_Suggested_Action_Is_Canonical_Surface_Projection
                (S, Snapshot.Surface, Snapshot.Suggestions (1)),
              "canonical projection assertion must reject hand-rolled descriptor text");

      Snapshot := Build_Main_Empty_State (S);
      Snapshot.Suggestions (1).Surface_Source_Label :=
        To_Unbounded_String (Empty_State_Surface_Label (Build_Surface));
      Assert (not Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections
                (S, Snapshot),
              "canonical projection assertion must reject cross-surface copied suggestions");
   end Test_Canonical_Projection_Rejects_Hand_Rolled_State;


   overriding procedure Register_Tests
     (T : in out Empty_State_Guidance_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Guided_Actions_Are_Command_Name_Only'Access,
                        "guided actions are stable command-name references only");
      Register_Routine (T, Test_Open_Suggestion_In_Command_Palette'Access,
                        "guided action opens Command Palette without payloads");
      Register_Routine (T, Test_Execute_Suggestion_Checks_Availability_First'Access,
                        "guided execution checks availability and uses Executor");
      Register_Routine (T, Test_Suggestion_Selection_Is_Transient'Access,
                        "guided action selection is transient");
      Register_Routine (T, Test_Activation_Mode_Opens_Palette_Without_Executing_Target'Access,
                        "activation mode opens palette without target execution");
      Register_Routine (T, Test_Unavailable_Suggestion_Does_Not_Execute'Access,
                        "unavailable guided action is blocked before execution");
      Register_Routine (T, Test_Keybindings_Cannot_Carry_Suggestion_Payloads'Access,
                        "keybindings cannot carry suggestion payloads");
      Register_Routine (T, Test_Selection_Skips_Display_Only_Suggestions'Access,
                        "selection skips display-only suggestion rows");
      Register_Routine (T, Test_Render_Building_Does_Not_Open_Palette'Access,
                        "render building does not activate suggestions");
      Register_Routine (T, Test_Availability_Labels_Show_Guard_Class'Access,
                        "availability labels expose input confirmation consent guard classes");
      Register_Routine (T, Test_Pending_Confirmation_Blocks_Conflicting_Suggestion'Access,
                        "pending confirmations block conflicting guided action execution");
      Register_Routine (T, Test_Suggested_Action_Route_Audit_Rejects_Bypass_And_Payload'Access,
                        "route audit rejects guided-action bypasses and payloads");
      Register_Routine (T, Test_Suggested_Action_Route_Audit_Allows_Palette_Entry'Access,
                        "route audit accepts canonical guided palette entry routes");
      Register_Routine (T, Test_Suggested_Action_Route_Audit_Rejects_Mixed_Route_Mode'Access,
                        "route audit rejects mixed guided route modes");
      Register_Routine (T, Test_Metadata_Currentness_Rejects_Stale_Descriptor_Copy'Access,
                        "metadata currentness rejects stale descriptor copies");
      Register_Routine (T, Test_Selection_Clears_When_Surface_Has_No_Suggestions'Access,
                        "selection clears when suggestion surface disappears");
      Register_Routine (T, Test_Palette_Open_Blocked_By_Pending_Confirmation'Access,
                        "pending confirmation blocks guided palette opening");
      Register_Routine (T, Test_Execute_Respects_Activation_Mode'Access,
                        "direct guided execution respects activation mode");
      Register_Routine (T, Test_Unavailable_Execution_Reports_Normal_Reason'Access,
                        "unavailable guided execution reports the normal reason");
      Register_Routine (T, Test_Empty_State_Assertion_Covers_Suggestion_Persistence'Access,
                        "suggestion state remains excluded from persistence assertions");
      Register_Routine (T, Test_Surface_Source_Labels_Are_Owned_By_Surface'Access,
                        "surface source labels are owned by emitting surfaces");
      Register_Routine (T, Test_Display_Only_Suggestion_Cannot_Open_Palette'Access,
                        "display-only suggestions cannot open the Command Palette");
      Register_Routine (T, Test_Activate_Pending_Block_Reports_Message'Access,
                        "pending-confirmation activation block reports an outcome");
      Register_Routine (T, Test_Selected_Index_Is_Single_And_Actionable'Access,
                        "selected suggestion index is single and actionable");
      Register_Routine (T, Test_Activation_Mode_Coherence_Is_Asserted'Access,
                        "activation-mode coherence rejects selected display-only and payload suggestions");
      Register_Routine (T, Test_Selected_Activation_Uses_Selected_Index'Access,
                        "selected activation resolves only the selected suggestion");
      Register_Routine (T, Test_Source_And_Availability_Assertions_Reject_Stale_Snapshot'Access,
                        "source and availability assertions reject stale suggestion state");
      Register_Routine (T, Test_Indexed_Activation_Rejects_Mismatched_Selection'Access,
                        "indexed activation rejects rows outside the selected guided action");
      Register_Routine (T, Test_Phase_Fields_Are_Clean_Beyond_Suggestion_Count'Access,
                        "tail-clean assertions cover availability and activation fields");
      Register_Routine (T, Test_Suggestions_Are_Canonical_Surface_Projections'Access,
                        "suggestions are canonical surface projections");
      Register_Routine (T, Test_Canonical_Projection_Rejects_Hand_Rolled_State'Access,
                        "canonical projection rejects hand-rolled suggestion state");
      Register_Routine (T, Test_First_Use_Coherent'Access,
                        "first-use empty-state guidance coherent");
      Register_Routine (T, Test_First_Run_Main_Guidance'Access,
                        "first-run main guidance is deterministic and no-payload");
      Register_Routine (T, Test_Render_Snapshot_Carries_Guidance'Access,
                        "render snapshot carries empty-state guidance");
      Register_Routine (T, Test_Project_Open_No_Buffer_Guidance'Access,
                        "project-open no-buffer guidance is useful");
      Register_Routine (T, Test_Major_Surface_Coverage_Is_Descriptor_Derived'Access,
                        "major surfaces have descriptor-derived stable suggestions");
      Register_Routine (T, Test_Project_Open_Panel_Empty_States_Are_Explicit'Access,
                        "project-open panel empty states are explicit");
      Register_Routine (T, Test_Build_Guidance_Uses_Row_Action_Commands'Access,
                        "Build guidance uses row action commands");
      Register_Routine (T, Test_Project_Search_No_Results_Guidance_Offers_Filter_Recovery'Access,
                        "Project Search no-result guidance offers filter recovery");
      Register_Routine (T, Test_Project_Search_Stale_Guidance_Offers_Rerun'Access,
                        "Project Search stale guidance offers rerun");
      Register_Routine (T, Test_Recent_Projects_Does_Not_Mutate'Access,
                        "recent-projects guidance is non-mutating");
      Register_Routine (T, Test_All_Surface_Snapshots_Are_Complete'Access,
                        "all major surfaces produce complete snapshots");
      Register_Routine (T, Test_Diagnostics_Source_Less_Selected_State'Access,
                        "source-less diagnostics have explicit empty guidance");
      Register_Routine (T, Test_Diagnostics_Selected_Unavailable_Target_State'Access,
                        "selected unavailable diagnostics have recovery guidance");
      Register_Routine (T, Test_Diagnostics_Filtered_None_State'Access,
                        "filtered diagnostics have explicit empty guidance");
      Register_Routine (T, Test_Diagnostics_Zero_Build_Result_Is_Contextual'Access,
                        "zero-diagnostic build result keeps build context");
      Register_Routine (T, Test_Render_Construction_Is_Observational'Access,
                        "render empty-state construction is observational");
      Register_Routine (T, Test_Main_Guidance_Uses_Metadata_Titles'Access,
                        "suggestions use metadata titles and stable names");
      Register_Routine (T, Test_Suggestion_Activation_Routes_Executor'Access,
                        "suggestion activation routes through Executor");
      Register_Routine (T, Test_Invalid_Suggestion_Activation_Is_No_Op'Access,
                        "invalid suggestion activation is a no-op");
      Register_Routine (T, Test_Payload_Like_Stable_Name_Activation_Is_No_Op'Access,
                        "payload-like stable names do not activate");
      Register_Routine (T, Test_Suggestion_Safety_Rejects_Target_Strings'Access,
                        "suggestion safety rejects target-bearing strings");
      Register_Routine (T, Test_Suggestion_Safety_Rejects_Hidden_Or_Mismatched_Metadata'Access,
                        "suggestion safety rejects hidden or mismatched metadata");
      Register_Routine (T, Test_Guidance_State_Not_Persisted_Or_Stored'Access,
                        "guidance construction is not persisted or stored");
      Register_Routine (T, Test_Surface_Labels_Are_Explicit_And_Unique'Access,
                        "aggregate guidance labels every surface exactly once");
      Register_Routine (T, Test_Display_Lines_Are_Compact_And_Target_Free'Access,
                        "display lines are compact and target-free");
      Register_Routine (T, Test_Suggestions_Are_Unique_And_Tail_Clean'Access,
                        "suggestions are unique and tail-clean");
      Register_Routine (T, Test_Duplicate_Suggestion_Is_Collapsed'Access,
                        "duplicate suggestions are detected");
      Register_Routine (T, Test_Suggestion_Display_Line_Shows_Unavailable_Reason'Access,
                        "suggestion display exposes unavailable reasons");
      Register_Routine (T, Test_Non_Ready_States_Are_Actionable'Access,
                        "non-ready empty states are actionable");
      Register_Routine (T, Test_Outline_No_Buffer_Guidance_Is_Actionable'Access,
                        "outline no-buffer guidance is actionable");
      Register_Routine (T, Test_Semantic_State_Kinds_Are_Not_Collapsed'Access,
                        "semantic empty-state kinds are not collapsed");
      Register_Routine (T, Test_Ready_States_Are_Not_Rendered_As_Empty_Cards'Access,
                        "ready states are not rendered as empty guidance cards");
      Register_Routine (T, Test_Non_Ready_States_Are_Renderable_Guidance'Access,
                        "non-ready states remain renderable guidance cards");
      Register_Routine (T, Test_Display_Line_Target_Guard_Covers_Final_Render_Text'Access,
                        "final render display lines remain labelled and target-free");
      Register_Routine (T, Test_Renderable_Count_And_Severity_Are_Semantic'Access,
                        "renderable count and severity semantics are bounded");
      Register_Routine (T, Test_Aggregate_Array_Is_Display_Only'Access,
                        "aggregate guidance array is canonical and display-only");
      Register_Routine (T, Test_Suggestion_Display_Lines_Are_Target_Free'Access,
                        "suggestion render lines are target-free and budgeted");
      Register_Routine (T, Test_Snapshot_Equivalence_Covers_All_Rendered_Fields'Access,
                        "snapshot equivalence covers all render-facing fields");
      Register_Routine (T, Test_Canonical_Surface_Slot_Map_Is_Bidirectional'Access,
                        "canonical surface slot map is bidirectional");
      Register_Routine (T, Test_Surface_Model_Is_Closed_And_Bounded'Access,
                        "surface model is closed and bounded");
      Register_Routine (T, Test_Render_Model_Fields_Match_Canonical_Array'Access,
                        "render model empty-state fields match canonical array");
   end Register_Tests;

end Editor.Empty_State_Guidance.Tests;
