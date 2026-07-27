with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Project;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Quick_Open;
with Editor.Project_Search;
with Editor.Outline;
with Editor.Diagnostics;
with Editor.Recent_Projects;
with Editor.Build_UI;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Executor;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Configuration_Audit;
with Editor.Configuration_Recovery;
with Editor.Commands.Workflow_Messages;
with Editor.Feature_Diagnostics;
with Editor.Keybindings;
with Editor.Messages;
with Editor.State;


package body Editor.Empty_State_Guidance.Surfaces is

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Command_Ids.Command_Id;
   use type Editor.Commands.Descriptors.Command_Visibility;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Feature_Diagnostics.Diagnostic_Severity;

   procedure Set_Text
     (Snapshot  : in out Empty_State_Snapshot;
      Surface   : Empty_State_Surface;
      Kind      : Empty_State_Kind;
      Primary   : String;
      Secondary : String := "";
      Severity  : Empty_State_Severity := Empty_Info)
   is
   begin
      Snapshot.Surface := Surface;
      Snapshot.Kind := Kind;
      Snapshot.Primary_Message :=
        To_Unbounded_String
          (Editor.Commands.Workflow_Messages.Normalize_Workflow_Message (Primary));
      Snapshot.Secondary_Explanation :=
        To_Unbounded_String
          (Editor.Commands.Workflow_Messages.Normalize_Workflow_Message (Secondary));
      Snapshot.Severity := Severity;
   end Set_Text;

   function Has_Active_Buffer (S : Editor.State.State_Type) return Boolean is
   begin
      return S.Buffer_Lifecycle.Active_Buffer_Token /= 0 or else S.Buffer_Lifecycle.File_Info.Has_Path;
   end Has_Active_Buffer;

   function Canonical_Surface_Suggestion
     (S       : Editor.State.State_Type;
      Surface : Empty_State_Surface;
      Command : Editor.Command_Ids.Command_Id)
      return Empty_State_Suggested_Command
   is
      Suggestion : Empty_State_Suggested_Command :=
        Command_Suggestion_From_Descriptor (S, Command);
   begin
      --  keeps every surface-specific guided action on one
      --  construction path: descriptor projection first, then the emitting
      --  surface label only.  No caller may attach paths, row ids, result ids,
      --  recovery domains, setting values, or other hidden payload state.
      if Suggestion.Visible then
         Suggestion.Surface_Source_Label :=
           To_Unbounded_String (Empty_State_Surface_Label (Surface));
      end if;
      return Suggestion;
   end Canonical_Surface_Suggestion;

   procedure Add_Suggestion
     (Snapshot : in out Empty_State_Snapshot;
      S        : Editor.State.State_Type;
      Command  : Editor.Command_Ids.Command_Id)
   is
      Suggestion : Empty_State_Suggested_Command :=
        Canonical_Surface_Suggestion (S, Snapshot.Surface, Command);
   begin
      if not Suggestion.Visible
        or else Snapshot.Suggestion_Count >= Max_Empty_State_Suggestions
      then
         return;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Suggestion.Command
           or else To_String (Snapshot.Suggestions (I).Stable_Name) =
             To_String (Suggestion.Stable_Name)
         then
            return;
         end if;
      end loop;

      Snapshot.Suggestion_Count := Snapshot.Suggestion_Count + 1;
      Snapshot.Suggestions (Snapshot.Suggestion_Count) := Suggestion;
   end Add_Suggestion;


   function Build_All_Empty_State_Snapshots
     (S : Editor.State.State_Type) return Empty_State_Snapshot_Array
   is
   begin
      return
        (Build_Main_Empty_State (S),
         Build_File_Tree_Empty_State (S),
         Build_Quick_Open_Empty_State (S),
         Build_Project_Search_Empty_State (S),
         Build_Outline_Empty_State (S),
         Build_Diagnostics_Empty_State (S),
         Build_Build_UI_Empty_State (S),
         Build_Recent_Projects_Empty_State (S),
         Build_Config_Recovery_Empty_State (S));
   end Build_All_Empty_State_Snapshots;

   function Contains_Command_Suggestion
     (Snapshot : Empty_State_Snapshot;
      Command  : Editor.Command_Ids.Command_Id) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Command then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Command_Suggestion;

   function Selected_Diagnostic_Is_Source_Less
     (S : Editor.State.State_Type) return Boolean
   is
      D : Editor.Diagnostics.Diagnostic;
   begin
      if not S.Active_Diagnostic.Has_Active
        or else not Editor.Diagnostics.Is_Valid_Diagnostic_Index
          (S.Diagnostics, S.Active_Diagnostic.Index)
      then
         return False;
      end if;

      D := Editor.Diagnostics.Diagnostic_At
        (S.Diagnostics, Positive (S.Active_Diagnostic.Index));
      return not D.Has_Location;
   end Selected_Diagnostic_Is_Source_Less;

   function File_Tree_Selection_Is_Stale
     (S : Editor.State.State_Type) return Boolean
   is
      Found : Boolean := False;
      Selected_Row : constant Natural :=
        Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View);
      Node_Id : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
   begin
      if Selected_Row = 0 then
         return False;
      end if;

      Node_Id := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree, Selected_Row, Found);
      return not Found
        or else Node_Id = Editor.File_Tree.No_File_Tree_Node
        or else not Editor.File_Tree.Contains (S.File_Tree, Node_Id);
   end File_Tree_Selection_Is_Stale;

   function Quick_Open_Selection_Is_Stale
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot) return Boolean
   is
   begin
      return Snapshot.Selected_Index > 0
        and then (Snapshot.Visible_Count = 0
                  or else Snapshot.Selected_Index > Snapshot.Visible_Count);
   end Quick_Open_Selection_Is_Stale;

   function Feature_Diagnostics_Has_Stale_Target
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (I))
         then
            return True;
         end if;
      end loop;
      return False;
   end Feature_Diagnostics_Has_Stale_Target;

   function Feature_Diagnostics_Selected_Source_Less
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Feature_Diagnostics.Has_Selected_Diagnostic
          (S.Feature_Diagnostics, S.Feature_Panel)
        and then Editor.Feature_Diagnostics.Selected_Diagnostic_Target_Unavailable_Label
          (S.Feature_Diagnostics, S.Feature_Panel) = "No source target";
   end Feature_Diagnostics_Selected_Source_Less;

   function Feature_Diagnostics_Selected_Unavailable_Reason
     (S : Editor.State.State_Type) return String
   is
      Reason : constant String :=
        Editor.Feature_Diagnostics.Selected_Diagnostic_Open_Unavailable_Reason
          (S.Feature_Diagnostics, S.Feature_Panel);
   begin
      if not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
        (S.Feature_Diagnostics, S.Feature_Panel)
        or else Feature_Diagnostics_Selected_Source_Less (S)
        or else Reason'Length = 0
      then
         return "";
      end if;

      return Reason;
   end Feature_Diagnostics_Selected_Unavailable_Reason;

   function Build_Main_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Has_Project : constant Boolean := Editor.Project.Has_Project (S.Project);
      Has_Buffer  : constant Boolean := Has_Active_Buffer (S);
      Recent_Count : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
   begin
      if not Has_Project and then not Has_Buffer and then Recent_Count = 0 then
         Set_Text
           (Snapshot, Main_Surface, First_Run_State,
            "Start by opening a project.",
            "No project, buffer, workspace, or recent project is active. "
            & "Missing optional configuration files are normal on first run.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Restore_Workspace_State);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Show_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Command_Palette);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Recover_Show);
      elsif not Has_Project then
         Set_Text
           (Snapshot, Main_Surface, No_Project_State,
            "No project open.",
            "Open a project, restore workspace state, inspect recent projects, "
            & "or review configuration before editing.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Show_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Restore_Workspace_State);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Reload_Settings);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Keybindings_Show);
      elsif not Has_Buffer then
         Set_Text (Snapshot, Main_Surface, No_Active_Buffer_State, "Project open; no file selected.",
                   "Use File Tree, Quick Open, Project Search, or Build candidate discovery to continue.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Focus_File_Tree);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Quick_Open);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Project_Files);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      else
         Set_Text (Snapshot, Main_Surface, Ready_State, "Ready.");
      end if;
      return Snapshot;
   end Build_Main_Empty_State;

   function Build_File_Tree_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Scan : constant Editor.File_Tree.File_Tree_Scan_Result := Editor.File_Tree.Scan_Status (S.File_Tree);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text
           (Snapshot, File_Tree_Surface, No_Project_State,
            "No project open.", "Open a project before using File Tree.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
      elsif Scan.Status = Editor.File_Tree.File_Tree_No_Project then
         Set_Text (Snapshot, File_Tree_Surface, Not_Refreshed_State, "File Tree has not been refreshed.",
                   "Refresh builds the in-memory tree; this empty state does not scan the filesystem.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      elsif Scan.Status /= Editor.File_Tree.File_Tree_Scan_Ok then
         Set_Text (Snapshot, File_Tree_Surface, Missing_Root_State, "Project root unavailable.",
                   "File Tree target is stale; refresh after the project root is available.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
      elsif File_Tree_Selection_Is_Stale (S) then
         Set_Text (Snapshot, File_Tree_Surface, Stale_State,
                   "File Tree target is stale; refresh required.",
                   "The selected row no longer maps to a live File Tree node.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
         Set_Text (Snapshot, File_Tree_Surface, Not_Refreshed_State, "File Tree has not been refreshed.",
                   "No tree nodes are present and no placeholder nodes are created.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      elsif Editor.File_Tree.File_Node_Count (S.File_Tree) = 0 then
         Set_Text (Snapshot, File_Tree_Surface, Empty_Project_State, "No files found in project.",
                   "The tree contains no file rows and no placeholder nodes are created.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      else
         Set_Text (Snapshot, File_Tree_Surface, Ready_State, "File Tree ready.");
      end if;
      Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Reveal_Active_File_In_Tree);
      return Snapshot;
   end Build_File_Tree_Empty_State;

   function Build_Quick_Open_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Quick : constant Editor.Quick_Open.Quick_Open_Snapshot := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text (Snapshot, Quick_Open_Surface, No_Project_State, "Open a project to use Quick Open.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
      elsif Quick.Known_Count = 0 then
         Set_Text (Snapshot, Quick_Open_Surface, No_Candidates_State, "No project files available.",
                   "Refresh project files or File Tree before opening by name.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      elsif not Quick.Has_Query then
         Set_Text (Snapshot, Quick_Open_Surface, No_Query_State, "Type to search project files.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Quick_Open_Query_Clear);
      elsif Quick_Open_Selection_Is_Stale (Quick) then
         Set_Text (Snapshot, Quick_Open_Surface, Stale_State, "Selected result is stale.",
                   "Clear or update the query before opening a file.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Quick_Open_Query_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      elsif Quick.Visible_Count = 0 then
         Set_Text (Snapshot, Quick_Open_Surface, No_Matches_State, "No matching files.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Quick_Open_Query_Clear);
      else
         Set_Text (Snapshot, Quick_Open_Surface, Ready_State, "Quick Open ready.");
      end if;
      return Snapshot;
   end Build_Quick_Open_Empty_State;

   function Build_Project_Search_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Status : constant Editor.Project_Search.Project_Search_Status := Editor.Project_Search.Status (S.Project_Search);
      Replace_Status : constant Editor.Project_Search.Project_Replace_Preview_Status :=
        Editor.Project_Search.Replace_Preview_Status (S.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text (Snapshot, Project_Search_Surface, No_Project_State, "Open a project to search files.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
      elsif not Editor.Project_Search.Has_Query (S.Project_Search) then
         Set_Text (Snapshot, Project_Search_Surface, No_Query_State, "Enter a query and run Project Search.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project_Search_Bar);
      elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
         Set_Text (Snapshot, Project_Search_Surface, Stale_State,
                   "Search results are stale.",
                   "Rerun Project Search before opening or replacing matches.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Rerun_Project_Search);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Clear_Project_Search);
      elsif Replace_Status = Editor.Project_Search.Project_Replace_Search_Stale
        or else Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search)
      then
         Set_Text (Snapshot, Project_Search_Surface, Stale_State,
                   "Replacement preview is stale.",
                   "Regenerate the preview before applying replacements.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Replace_Preview);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Replace_Clear_Preview);
      elsif Replace_Status = Editor.Project_Search.Project_Replace_No_Preview
        and then Editor.Project_Search.Result_Count (S.Project_Search) > 0
      then
         Set_Text (Snapshot, Project_Search_Surface, Replace_Preview_Empty_State, "No replacement preview.",
                   "Create a replace preview explicitly before applying replacements.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Replace_Preview);
      elsif Status = Editor.Project_Search.Project_Search_Idle then
         Set_Text (Snapshot, Project_Search_Surface, Not_Refreshed_State, "Project Search has not run.",
                   "Run search explicitly; this empty state does not compute matches.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Run_Project_Search);
      elsif Status = Editor.Project_Search.Project_Search_No_Files then
         Set_Text (Snapshot, Project_Search_Surface, No_Files_State, "No project files available.",
                   "Refresh File Tree or project files before searching.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_File_Tree);
      elsif Status = Editor.Project_Search.Project_Search_Invalid_Regex then
         Set_Text (Snapshot, Project_Search_Surface, Unavailable_State, "Project Search query is invalid.",
                   "Edit the query or disable regex mode.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project_Search_Bar);
      elsif Status = Editor.Project_Search.Project_Search_Read_Error then
         Set_Text
           (Snapshot, Project_Search_Surface, Unavailable_State,
            "Project Search could not read one or more files.",
            "Results are not repaired or re-run by this guidance.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Run_Project_Search);
      elsif Editor.Project_Search.Was_Truncated (S.Project_Search)
        or else Editor.Project_Search.Results_Truncated (S.Project_Search)
      then
         Set_Text (Snapshot, Project_Search_Surface, Limit_Reached_State, "Search limit reached.",
                   "Refine the query or scope and run Project Search again.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Scope_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Include_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Exclude_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Run_Project_Search);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Clear_Project_Search);
      elsif Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Set_Text (Snapshot, Project_Search_Surface, No_Results_State,
                   "No Project Search matches.",
                   "Clear scope/filter options or adjust the query, then run Project Search again.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Scope_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Kind_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Include_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Exclude_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Run_Project_Search);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Clear_Project_Search);
      else
         Set_Text (Snapshot, Project_Search_Surface, Ready_State, "Project Search ready.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Selected_Project_Search_Result);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Next_Project_Search_Result);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Previous_Project_Search_Result);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Project_Search_Replace_Preview);
      end if;
      return Snapshot;
   end Build_Project_Search_Empty_State;

   function Build_Outline_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Source : constant Editor.Outline.Outline_Source_Class := Editor.Outline.Source_Class (S.Outline);
   begin
      if not Has_Active_Buffer (S) then
         Set_Text (Snapshot, Outline_Surface, No_Active_Buffer_State, "Open a file to use Outline.");
         if Editor.Project.Has_Project (S.Project) then
            Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Quick_Open);
            Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Focus_File_Tree);
         else
            Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
         end if;
      elsif Source = Editor.Outline.No_Outline then
         Set_Text (Snapshot, Outline_Surface, Not_Refreshed_State, "Refresh Outline to extract symbols.",
                   "No parsing is triggered by this guidance.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Unsupported_Content then
         Set_Text (Snapshot, Outline_Surface, Unsupported_Buffer_State,
                   "Outline is unavailable for this buffer.",
                   "Open a supported source file or refresh after changing buffers.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Extraction_Failed then
         Set_Text (Snapshot, Outline_Surface, Unavailable_State,
                   "Outline refresh failed.",
                   "Refresh explicitly after fixing the buffer or extractor input.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Extracted_Outline
        and then not Editor.Outline.Outline_Buffer_Identity_Matches
          (S.Outline, S.Buffer_Lifecycle.Active_Buffer_Token)
      then
         Set_Text (Snapshot, Outline_Surface, Different_Buffer_State,
                   "Outline belongs to another buffer.",
                   "Refresh Outline for the active buffer before navigating.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Stale_Extracted_Outline then
         Set_Text (Snapshot, Outline_Surface, Stale_State, "Outline is stale; refresh required.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Outline);
      elsif not Editor.Outline.Has_Items (S.Outline) then
         Set_Text (Snapshot, Outline_Surface, No_Symbols_State, "No symbols found.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Refresh_Outline);
      else
         Set_Text (Snapshot, Outline_Surface, Ready_State, "Outline ready.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Reveal_Current_Outline_Symbol);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Clear_Outline_Filter);
      end if;
      return Snapshot;
   end Build_Outline_Empty_State;

   function Build_Diagnostics_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Feature_Total : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Feature_Visible : constant Natural :=
        Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics);
   begin
      if Feature_Total > 0 and then Feature_Visible = 0 then
         Set_Text
           (Snapshot, Diagnostics_Surface, Filtered_None_State,
            "No diagnostics match current filter.",
            "Clear the filter explicitly; guidance does not delete or rewrite diagnostic rows.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear_Filter);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Show_All);
      elsif Feature_Diagnostics_Selected_Source_Less (S) then
         Set_Text (Snapshot, Diagnostics_Surface, Source_Less_Selected_State,
                   "Selected diagnostic has no source target.",
                   "Navigation is unavailable until a diagnostic carries a source location.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear_Selected);
      elsif Feature_Diagnostics_Selected_Unavailable_Reason (S)'Length > 0 then
         Set_Text
           (Snapshot, Diagnostics_Surface, Selected_Unavailable_State,
            Feature_Diagnostics_Selected_Unavailable_Reason (S),
            "Clear the selected diagnostic or run the producer again after fixing the target.",
            Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear_Selected);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif Feature_Diagnostics_Has_Stale_Target (S) then
         Set_Text (Snapshot, Diagnostics_Surface, Stale_State,
                   "Some diagnostics may be stale.",
                   "Clear stale diagnostics or run the producer again explicitly.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear);
      elsif S.Build.Latest_Result.Has_Diagnostics_Count
        and then S.Build.Latest_Result.Diagnostics_Count_If_Available = 0
      then
         Set_Text (Snapshot, Diagnostics_Surface, No_Build_Diagnostics_State,
                   "Build completed with no diagnostics.",
                   "Inspect Build Output for command details or run build again after changes.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif Feature_Total = 0
        and then Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0
      then
         Set_Text (Snapshot, Diagnostics_Surface, No_Diagnostics_State,
                   "No diagnostics yet.",
                   "Run build or diagnostics-producing commands to populate this panel.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear_Filter);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif S.Active_Diagnostic.Has_Active
        and then not Editor.Diagnostics.Is_Valid_Diagnostic_Index
          (S.Diagnostics, S.Active_Diagnostic.Index)
      then
         Set_Text (Snapshot, Diagnostics_Surface, Stale_State, "Some diagnostics may be stale.", "", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear);
      elsif Selected_Diagnostic_Is_Source_Less (S) then
         Set_Text (Snapshot, Diagnostics_Surface, Source_Less_Selected_State,
                   "Selected diagnostic has no source target.",
                   "Navigation is unavailable until a diagnostic carries a source location.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear_Selected);
      else
         Set_Text (Snapshot, Diagnostics_Surface, Ready_State, "Diagnostics ready.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Clear_Filter);
      end if;
      Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Run);
      return Snapshot;
   end Build_Diagnostics_Empty_State;

   function Build_Build_UI_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Candidate_Count : constant Natural := Editor.Build_UI.Candidate_Count (S.Build.Build_UI);
      Validation : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Validate_Build_UI_State (S.Build.Build_UI);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text (Snapshot, Build_Surface, No_Project_State, "Open a project to build.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
      elsif Candidate_Count = 0
        and then S.Build.Build_UI.Candidate_Refresh_Status = Editor.Build_UI.Build_Candidate_Refresh_Not_Requested
      then
         Set_Text (Snapshot, Build_Surface, Not_Refreshed_State, "Refresh build candidates.",
                   "Candidate discovery is explicit; this guidance does not scan or run anything.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Refresh_Candidates);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif Candidate_Count = 0 then
         Set_Text (Snapshot, Build_Surface, No_Candidates_State, "No build candidates found.",
                   "Refresh build candidates explicitly; this guidance does not scan or run anything.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Refresh_Candidates);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif Validation = Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale then
         Set_Text (Snapshot, Build_Surface, Stale_State, "Selected build candidate is stale.",
                   "Refresh candidates before running build.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Refresh_Candidates);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif Validation = Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected then
         Set_Text (Snapshot, Build_Surface, No_Selected_Candidate_State, "Select a build candidate.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Select_First_Candidate);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      elsif Validation = Editor.Build_UI.Build_UI_Rejected_Missing_Consent
        or else Validation = Editor.Build_UI.Build_UI_Rejected_Stale_Consent
      then
         Set_Text (Snapshot, Build_Surface, Consent_Required_State, "Consent required before running build.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Acknowledge_Consent);
      elsif Validation /= Editor.Build_UI.Build_UI_Valid then
         Set_Text
         (Snapshot, Build_Surface, Request_Invalid_State,
            "Build request is invalid.",
            Editor.Build_UI.Validation_Message (Validation), Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Refresh_Candidates);
      elsif S.Build.Latest_Result.Diagnostics_Ingestion_Status =
        Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled
      then
         Set_Text (Snapshot, Build_Surface, Diagnostics_Disabled_State, "Diagnostics ingestion is disabled.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Toggle_Diagnostics_Ingestion);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Show);
      elsif not S.Build.Latest_Result.Has_Result then
         Set_Text (Snapshot, Build_Surface, No_Result_State, "No build has run.",
                   "Run build or inspect output details after an explicit build request.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Run);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Show);
      elsif S.Build.Latest_Output_Details.Has_Output_Details
        and then S.Build.Latest_Output_Details.Kind = Editor.Build_Output_Details.Build_Output_Details_None
      then
         Set_Text (Snapshot, Build_Surface, No_Output_State, "No output captured.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
      else
         Set_Text (Snapshot, Build_Surface, Ready_State, "Build Output ready.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_Run);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Build_UI_Show);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Diagnostics_Show);
      end if;
      return Snapshot;
   end Build_Build_UI_Empty_State;

   function Build_Recent_Projects_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
      Missing : constant Natural := Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects);
   begin
      if Total = 0 then
         Set_Text (Snapshot, Recent_Projects_Surface, No_Recent_Projects_State, "No recent projects.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Restore_Workspace_State);
      elsif S.Recent_Project_Selected_Index in 1 .. Total
        and then not Editor.Recent_Projects.Is_Available
          (Editor.Recent_Projects.Item
             (S.Recent_Projects, Positive (S.Recent_Project_Selected_Index)))
      then
         Set_Text (Snapshot, Recent_Projects_Surface, Selected_Unavailable_State,
                   "Recent project is unavailable.",
                   "Remove missing entries or open a project explicitly.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Remove_Selected_Recent_Project);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Remove_Missing_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Project);
      elsif Missing = Total then
         Set_Text (Snapshot, Recent_Projects_Surface, Only_Missing_Projects_State, "Some recent projects are missing.",
                   "Missing entries are not removed until a command does it.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Remove_Missing_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Clear_Recent_Projects);
      else
         Set_Text (Snapshot, Recent_Projects_Surface, Ready_State, "Recent Projects ready.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Open_Selected_Recent_Project);
      end if;
      return Snapshot;
   end Build_Recent_Projects_Empty_State;

   function Build_Config_Recovery_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Summary : constant Editor.Configuration_Audit.Configuration_State_Summary :=
        Editor.Configuration_Audit.Configuration_State_Summary_For (S);
   begin
      if Summary.Has_Pending_Transition then
         Set_Text
           (Snapshot, Configuration_Recovery_Surface,
            Configuration_Warning_State, "Configuration warnings available.",
            "Pending transition state is runtime-only; run audit or recovery view "
            & "explicitly.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Recover_Show);
      elsif Summary.Message_Count > 0 then
         Set_Text
           (Snapshot, Configuration_Recovery_Surface, Safe_Defaults_State,
            "Safe defaults are active for one or more domains.",
            "Inspect recovery details explicitly; guidance does not reset or save "
            & "configuration.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Recover_Show);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Reset_Settings);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Reset_Keybindings);
      else
         Set_Text (Snapshot, Configuration_Recovery_Surface, Clean_State, "Configuration is clean.",
                   "Run configuration audit when you want an explicit domain report.");
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Recover_Show);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Reset_Settings);
         Add_Suggestion (Snapshot, S, Editor.Command_Ids.Command_Configuration_Reset_Keybindings);
      end if;
      return Snapshot;
   end Build_Config_Recovery_Empty_State;

end Editor.Empty_State_Guidance.Surfaces;
