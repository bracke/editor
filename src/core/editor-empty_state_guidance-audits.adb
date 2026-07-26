with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_UI;
with Editor.Diagnostics;
with Editor.Feature_Diagnostics;
with Editor.File_Tree;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.Empty_State_Guidance.Surfaces;

package body Editor.Empty_State_Guidance.Audits is

   use type Editor.Command_Ids.Command_Id;
   use type Editor.Executor.Command_Execution_Status;

   function Safe_Stable_Command_Name (Name : String) return Boolean is
   begin
      return Name'Length > 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), " ") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), ":") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "\") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "?") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "=") = 0;
   end Safe_Stable_Command_Name;

   function Assert_Guided_Action_Routing_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
      Snapshots : constant Empty_State_Snapshot_Array :=
        Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S);
   begin
      if not Assert_Empty_State_Array_Is_Display_Only (Snapshots) then
         return False;
      end if;

      for Surface_Index in Snapshots'Range loop
         declare
            Snapshot : constant Empty_State_Snapshot := Snapshots (Surface_Index);
         begin
            for I in 1 .. Snapshot.Suggestion_Count loop
               if not Suggestion_Is_Activation_Safe (Snapshot.Suggestions (I))
                 or else Snapshot.Suggestions (I).Carries_Payload
                 or else Length (Snapshot.Suggestions (I).Stable_Name) = 0
                 or else not Safe_Stable_Command_Name
                   (To_String (Snapshot.Suggestions (I).Stable_Name))
                 or else Length (Snapshot.Suggestions (I).Title) = 0
                 or else Length (Snapshot.Suggestions (I).Availability_Label) = 0
                 or else not Assert_Suggested_Action_Metadata_Is_Current
                   (Snapshot.Suggestions (I))
                 or else not Assert_Suggested_Action_Is_Canonical_Surface_Projection
                   (S, Snapshot.Surface, Snapshot.Suggestions (I))
                 or else not Assert_Suggested_Action_Source_Label_Is_Surface_Owned
                   (Snapshot, Positive (I))
                 or else not Assert_Suggested_Action_Availability_Label_Is_Current
                   (S, Snapshot.Suggestions (I))
                 or else not Assert_Suggested_Action_Activation_Mode_Is_Coherent
                   (Snapshot.Suggestions (I))
               then
                  return False;
               end if;
            end loop;
         end;
      end loop;

      return True;
   end Assert_Guided_Action_Routing_Coherent;

   function Assert_Render_Empty_State_Construction_Is_Observational
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_First_Run_Guidance_Fabricates_No_Project (Before, After)
        and then Editor.Diagnostics.Diagnostic_Count (Before.Diagnostics) =
          Editor.Diagnostics.Diagnostic_Count (After.Diagnostics)
        and then Editor.File_Tree.File_Node_Count (Before.File_Tree) =
          Editor.File_Tree.File_Node_Count (After.File_Tree)
        and then Editor.Project_Search.Result_Count (Before.Project_Search) =
          Editor.Project_Search.Result_Count (After.Project_Search)
        and then Editor.Build_UI.Candidate_Count (Before.Build_UI) =
          Editor.Build_UI.Candidate_Count (After.Build_UI)
        and then Editor.Feature_Diagnostics.Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Row_Count (After.Feature_Diagnostics)
        and then Editor.Feature_Diagnostics.Visible_Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Visible_Row_Count (After.Feature_Diagnostics);
   end Assert_Render_Empty_State_Construction_Is_Observational;

   function Assert_Empty_State_Not_Persisted
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Render_Empty_State_Construction_Is_Observational (Before, After)
        and then Editor.Recent_Projects.Count (Before.Recent_Projects) =
          Editor.Recent_Projects.Count (After.Recent_Projects)
        and then Editor.Build_UI.Candidate_Count (Before.Build_UI) =
          Editor.Build_UI.Candidate_Count (After.Build_UI)
        and then Editor.Feature_Diagnostics.Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Row_Count (After.Feature_Diagnostics)
        and then Editor.Feature_Diagnostics.Visible_Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Visible_Row_Count (After.Feature_Diagnostics);
   end Assert_Empty_State_Not_Persisted;

   function Assert_Empty_State_Activation_Uses_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Command : Editor.Command_Ids.Command_Id) return Boolean
   is
   begin
      return Result.Command = Command
        and then Result.Status /= Editor.Executor.Command_No_Op
        and then Assert_First_Run_Guidance_Fabricates_No_Project (Before, After);
   end Assert_Empty_State_Activation_Uses_Executor;

   function Assert_Major_Empty_State_Surface_Coverage
     (S : Editor.State.State_Type) return Boolean
   is
      Snapshots : constant Empty_State_Snapshot_Array :=
        Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S);
   begin
      if not Assert_Empty_State_Surface_Model_Is_Closed
        or else not Assert_All_Empty_State_Surfaces_Are_Present_Once (Snapshots)
        or else not Assert_All_Empty_State_Surfaces_In_Canonical_Order (Snapshots)
        or else not Assert_Empty_State_Array_Uses_Canonical_Slots (Snapshots)
        or else not Assert_Empty_State_Array_Suggestion_Budget (Snapshots)
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Length (Snapshots (I).Primary_Message) = 0
           or else not Assert_Empty_State_Is_Display_Only (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Are_Descriptor_Derived (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Are_Stable_Names_Only (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Resolve_From_Stable_Names (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean (Snapshots (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Major_Empty_State_Surface_Coverage;

   function Assert_First_Use_Empty_State_Guidance_Coherent return Boolean is
      S : Editor.State.State_Type;
      Main : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Main_Empty_State (S);
      File_Tree : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_File_Tree_Empty_State (S);
      Quick : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Quick_Open_Empty_State (S);
      Search : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Project_Search_Empty_State (S);
      Outline : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Outline_Empty_State (S);
      Diagnostics : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Diagnostics_Empty_State (S);
      Build : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Build_UI_Empty_State (S);
      Recent : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Recent_Projects_Empty_State (S);
      Config : constant Empty_State_Snapshot :=
        Editor.Empty_State_Guidance.Surfaces.Build_Config_Recovery_Empty_State (S);
   begin
      return Assert_Empty_State_Surface_Model_Is_Closed
        and then Main.Kind = First_Run_State
        and then File_Tree.Kind = No_Project_State
        and then Quick.Kind = No_Project_State
        and then Search.Kind = No_Project_State
        and then Outline.Kind = No_Active_Buffer_State
        and then Diagnostics.Kind = No_Diagnostics_State
        and then Build.Kind = No_Project_State
        and then Recent.Kind = No_Recent_Projects_State
        and then Config.Kind = Clean_State
        and then Assert_All_Empty_State_Surfaces_Are_Present_Once
          (Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S))
        and then Assert_All_Empty_State_Surfaces_In_Canonical_Order
          (Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S))
        and then Assert_Empty_State_Array_Uses_Canonical_Slots
          (Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S))
        and then Empty_State_Renderable_Count
          (Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S)) > 0
        and then Assert_Empty_State_Is_Display_Only (Main)
        and then Assert_Empty_State_Is_Display_Only (File_Tree)
        and then Assert_Empty_State_Is_Display_Only (Quick)
        and then Assert_Empty_State_Is_Display_Only (Search)
        and then Assert_Empty_State_Is_Display_Only (Outline)
        and then Assert_Empty_State_Is_Display_Only (Diagnostics)
        and then Assert_Empty_State_Is_Display_Only (Build)
        and then Assert_Empty_State_Is_Display_Only (Recent)
        and then Assert_Empty_State_Is_Display_Only (Config)
        and then Assert_Major_Empty_State_Surface_Coverage (S);
   end Assert_First_Use_Empty_State_Guidance_Coherent;

end Editor.Empty_State_Guidance.Audits;
