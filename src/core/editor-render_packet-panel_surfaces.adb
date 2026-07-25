with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Guikit.Draw;
with Editor.Command_Palette;
with Editor.Diagnostics;
with Editor.File_Tree;
with Editor.Lifecycle_Guidance;
with Editor.Recent_Projects;
with Editor.Render_Model;
with Editor.Startup_Readiness;
with Editor.Buffers;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Contextual_Help;
with Editor.Feature_Panel;
with Editor.Focus_Management;
with Editor.History;
with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Messages;
with Editor.Outline;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Pending_Transition_Bar.Surface_Rendering;
with Editor.Pending_Transitions;
with Editor.Problems.Surface_Rendering;
with Editor.Project;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Packet.Render_Context;
with Editor.Search;
with Editor.Search_Results.Surface_Rendering;
with Editor.State;
with Editor.Status_Bar;
with Editor.Status_Bar.Surface_Rendering;
with Editor.Terminal_Tasks.Surface_Rendering;
with Editor.View;
with Editor.Workspace_Persistence;

package body Editor.Render_Packet.Panel_Surfaces is

   use type Editor.Search.Search_Match_Index;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;

   procedure Render
     (Packet : in out Render_Packet;
      Context : Editor.Render_Packet.Render_Context.Context)
   is
      Snap   : Editor.Render_Model.Render_Snapshot renames Context.Snap;
      S      : Editor.State.State_Type renames Context.State;
      Layout : Editor.Layout.Layout_Config renames Context.Layout;
      Cell_W : Positive renames Context.Cell_W;
      Cell_H : Positive renames Context.Cell_H;
      Line_Number_Config : Editor.Line_Numbers.Line_Number_Config renames Context.Line_Number_Config;
      Out_Packet : Render_Packet renames Packet;
      function Line_Mode_Text return String is
      begin
         case Line_Number_Config.Mode is
            when Editor.Line_Numbers.Absolute_Line_Numbers =>
               return "absolute lines";
            when Editor.Line_Numbers.Relative_Line_Numbers =>
               return "relative lines";
            when Editor.Line_Numbers.Hybrid_Line_Numbers =>
               return "hybrid lines";
         end case;
      end Line_Mode_Text;

      function Severity_Label
        (Severity : Editor.Messages.Message_Severity) return String
      is
      begin
         case Severity is
            when Editor.Messages.Info_Message =>
               return "info";
            when Editor.Messages.Success_Message =>
               return "ok";
            when Editor.Messages.Warning_Message =>
               return "warn";
            when Editor.Messages.Error_Message =>
               return "error";
         end case;
      end Severity_Label;

      function Focus_Owner
        return Editor.Focus_Management.Focus_Owner
      is
      begin
         case Snap.Active_Overlay is
            when Editor.Overlay_Focus.Command_Palette_Overlay =>
               return Editor.Focus_Management.Focus_Command_Palette;
            when Editor.Overlay_Focus.Quick_Open_Overlay =>
               return Editor.Focus_Management.Focus_Quick_Open;
            when Editor.Overlay_Focus.Project_Search_Bar_Overlay =>
               return Editor.Focus_Management.Focus_Project_Search_Query;
            when Editor.Overlay_Focus.Buffer_Switcher_Overlay =>
               return Editor.Focus_Management.Focus_Buffer_List;
            when Editor.Overlay_Focus.Active_Find_Prompt_Overlay
               | Editor.Overlay_Focus.Go_To_Line_Overlay
               | Editor.Overlay_Focus.File_Target_Prompt_Overlay =>
               return Editor.Focus_Management.Focus_Workspace_Prompt;
            when Editor.Overlay_Focus.No_Overlay =>
               null;
         end case;

         if Snap.Feature_Panel_Focused then
            case Snap.Active_Feature is
               when Editor.Feature_Panel.Outline_Feature =>
                  return Editor.Focus_Management.Focus_Outline;
               when Editor.Feature_Panel.Diagnostics_Feature =>
                  return Editor.Focus_Management.Focus_Diagnostics;
               when Editor.Feature_Panel.Search_Results_Feature =>
                  return Editor.Focus_Management.Focus_Project_Search_Results;
               when others =>
                  return Editor.Focus_Management.Focus_Project_Search_Results;
            end case;
         end if;

         case Snap.Panel_Focus_Target is
            when Editor.Panel_Focus.Editor_Text_Focus =>
               return Editor.Focus_Management.Focus_Editor;
            when Editor.Panel_Focus.File_Tree_Focus =>
               return Editor.Focus_Management.Focus_File_Tree;
            when Editor.Panel_Focus.Bottom_Panel_Focus =>
               case Snap.Bottom_Focus_Content is
                  when Editor.Panel_Focus.Search_Results_Focus =>
                     return Editor.Focus_Management.Focus_Project_Search_Results;
                  when Editor.Panel_Focus.Problems_Focus =>
                     return Editor.Focus_Management.Focus_Diagnostics;
                  when Editor.Panel_Focus.No_Bottom_Focus =>
                     return Editor.Focus_Management.Focus_None;
               end case;
         end case;
      end Focus_Owner;

      function Focus_Label return String is
      begin
         --  status focus text is a projection of the same
         --  effective focus-owner model that input routing uses.  Render
         --  observes the snapshot/state only; it never repairs or changes
         --  focus while producing this label.
         return Editor.Focus_Management.Focus_Owner_Label (Focus_Owner);
      end Focus_Label;

      function Active_Panel_Label return String is
      begin
         return Editor.Focus_Management.Active_Panel_Label (Focus_Owner);
      end Active_Panel_Label;

      function Input_Mode_Label return String is
      begin
         return Editor.Focus_Management.Input_Mode_Label (Focus_Owner);
      end Input_Mode_Label;

      function Is_Restore_Feedback
        (Text : String) return Boolean
      is
      begin
         return Text = "Workspace restored."
           or else Text = "Workspace restored with missing entries skipped."
           or else
             (Text'Length >= 24
              and then Text (Text'First .. Text'First + 23) =
                "Workspace state restored")
           or else
             (Text'Length >= 34
              and then Text (Text'First .. Text'First + 33) =
                "Workspace state partially restored");
      end Is_Restore_Feedback;


      function File_Label return String
      is
      begin
         if not Editor.State.Has_Active_Buffer (S) then
            return "No active buffer.";
         elsif S.File_Info.Has_Path then
            if Editor.Project.Has_Project (S.Project)
              and then Editor.Project.Is_Under_Project
                (S.Project, To_String (S.File_Info.Path))
            then
               return Editor.Project.Relative_Path
                 (S.Project, To_String (S.File_Info.Path));
            else
               return To_String (S.File_Info.Display_Name);
            end if;
         elsif Length (S.File_Info.Display_Name) > 0 then
            return To_String (S.File_Info.Display_Name);
         else
            return "Untitled";
         end if;
      end File_Label;

      function Buffer_Kind_Label return String
      is
      begin
         if not Editor.State.Has_Active_Buffer (S) then
            return "No buffer";
         elsif S.File_Info.Has_Path then
            if Editor.Project.Has_Project (S.Project)
              and then not Editor.Project.Is_Under_Project
                (S.Project, To_String (S.File_Info.Path))
            then
               return "File-backed, outside project";
            else
               return "File-backed";
            end if;
         else
            return "Scratch";
         end if;
      end Buffer_Kind_Label;

      function File_State_Label return String
      is
      begin
         if not Editor.State.Has_Active_Buffer (S) then
            return "Unavailable";
         elsif S.File_Conflict_Prompt_Active then
            return "Conflict pending";
         elsif S.File_Info.Missing_Target_Surfaced then
            return "Missing on disk";
         elsif S.File_Info.External_Change_Surfaced and then S.File_Info.Dirty then
            return "Conflict pending";
         elsif S.File_Info.External_Change_Surfaced then
            return "Changed on disk";
         elsif S.File_Info.Unreadable_Target_Surfaced
           or else S.File_Info.Last_Reload_Failed
           or else S.File_Info.Last_Revert_Failed
         then
            return "Unreadable";
         elsif S.File_Info.Unwritable_Target_Surfaced then
            return "Read-only";
         elsif S.File_Info.Last_Save_Failed then
            return "Save conflict";
         elsif S.File_Info.Dirty then
            return "Modified";
         else
            return "Clean";
         end if;
      end File_State_Label;

      function Pending_Status_Label return String
      is
      begin
         if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
            return "Confirmation required: "
              & Editor.Pending_Transitions.Display_Text (S.Pending_Transitions);
         elsif S.Dirty_Close_Prompt_Active then
            if S.Dirty_Close_Prompt_Save_Failure_Count > 0 then
               return "Dirty close review: save failed; buffer remains open";
            elsif S.Dirty_Close_Prompt_Conflicted_Count > 0 then
               return "Dirty close review: file conflict requires resolution";
            elsif S.Dirty_Close_Prompt_Unwritable_Count > 0 then
               return "Dirty close review: file is unwritable";
            elsif S.Dirty_Close_Prompt_Missing_Count > 0 then
               return "Dirty close review: backing file is missing";
            elsif S.Dirty_Close_Prompt_Untitled_Count > 0 then
               return "Dirty close review: scratch buffer requires discard or cancel";
            elsif S.Dirty_Close_Prompt_All_Buffers then
               return "Dirty close review: save all, discard all, or cancel";
            else
               return "Dirty close review: save, discard, or cancel";
            end if;
         elsif S.File_Conflict_Prompt_Active then
            if S.File_Conflict_Prompt_Dirty then
               return "File conflict: keep buffer, reload from disk, overwrite disk, or cancel";
            else
               return "File conflict: keep buffer, reload from disk, or cancel";
            end if;
         elsif S.File_Target_Prompt_Active then
            return "Pending file target";
         else
            return "";
         end if;
      end Pending_Status_Label;

      function Project_State_Label return String
      is
         Pending_Kind : constant Editor.Pending_Transitions.Pending_Transition_Kind :=
           Editor.Pending_Transitions.Target_Kind (S.Pending_Transitions);
      begin
         case Pending_Kind is
            when Editor.Pending_Transitions.Pending_Open_Project
               | Editor.Pending_Transitions.Pending_Switch_Project
               | Editor.Pending_Transitions.Pending_Open_Recent_Project
               | Editor.Pending_Transitions.Pending_Restore_Workspace =>
               return "Project switch pending";
            when Editor.Pending_Transitions.Pending_Close_Project
               | Editor.Pending_Transitions.Pending_Clear_Project =>
               return "Project close pending";
            when others =>
               null;
         end case;

         if Snap.Has_Project then
            return "Project: " & To_String (Snap.Project_Label);
         else
            return "No project open.";
         end if;
      end Project_State_Label;

      function Undo_Redo_Label return String
      is
         Undo : constant Boolean := not Editor.History.Undo_Stack.Is_Empty;
         Redo : constant Boolean := not Editor.History.Redo_Stack.Is_Empty;
      begin
         if Undo and Redo then
            return "Undo/Redo available";
         elsif Undo then
            return "Undo available";
         elsif Redo then
            return "Redo available";
         else
            return "Undo/Redo unavailable";
         end if;
      end Undo_Redo_Label;

      function Outline_Status_Label return String
      is
         Summary : constant Editor.Outline.Outline_Summary :=
           Editor.Outline.Summary (S.Outline);
         Filter  : constant String := Editor.Outline.Filter_Text (S.Outline);
      begin
         if Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
           Editor.Outline.Stale_Extracted_Outline
         then
            return "Outline: stale";
         end if;

         case Summary.Source_Class is
            when Editor.Outline.No_Outline =>
               return "Outline: not refreshed";
            when Editor.Outline.Stale_Extracted_Outline =>
               return "Outline: stale";
            when Editor.Outline.Unsupported_Content | Editor.Outline.Extraction_Failed =>
               return "Outline: unavailable";
            when others =>
               if Filter /= "" then
                  return "Outline: filter " & Natural'Image
                    (Editor.Outline.Filtered_Navigable_Symbol_Count (S.Outline)) &
                    " of" & Natural'Image
                    (Editor.Outline.Navigable_Symbol_Count (S.Outline));
               elsif Editor.Outline.Has_Current_Symbol (S.Outline) then
                  return "Current: " &
                    Editor.Outline.Current_Symbol_Label (S.Outline);
               else
                  return "Outline:" & Natural'Image
                    (Editor.Outline.Navigable_Symbol_Count (S.Outline)) &
                    " symbols";
               end if;
         end case;
      end Outline_Status_Label;

      function Status_Plural
        (Count       : Natural;
         Singular    : String;
         Plural_Text : String) return String
      is
      begin
         if Count = 1 then
            return Singular;
         else
            return Plural_Text;
         end if;
      end Status_Plural;

      function Diagnostics_Status_Label return String
      is
         Errors   : Natural := 0;
         Warnings : Natural := 0;
      begin
         for D of S.Diagnostics loop
            case D.Severity is
               when Editor.Diagnostics.Error =>
                  Errors := Errors + 1;
               when Editor.Diagnostics.Warning =>
                  Warnings := Warnings + 1;
               when others =>
                  null;
            end case;
         end loop;

         if Snap.Total_Diagnostic_Count = 0 then
            return "No diagnostics.";
         elsif Errors > 0 or else Warnings > 0 then
            return "Diagnostics:"
              & Natural'Image (Errors) & " "
              & Status_Plural (Errors, "error", "errors") & ","
              & Natural'Image (Warnings) & " "
              & Status_Plural (Warnings, "warning", "warnings");
         else
            return "Diagnostics:" & Natural'Image (Snap.Total_Diagnostic_Count)
              & " total";
         end if;
      end Diagnostics_Status_Label;

      function Build_Status_Label return String
      is
         Label : constant String :=
           Editor.Build_Result_Summary.Status_Label (S.Latest_Build_Result);
         Build_UI_View : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
           Editor.Build_UI.Build_Render_Snapshot
             (S.Build_UI,
              S.Latest_Build_Result,
              S.Latest_Build_Output_Details);
         Validation : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
           Editor.Build_UI.Validate_Build_UI_State (S.Build_UI);
         Candidate_Stale : constant Boolean :=
           S.Build_UI.Selected_Candidate_Stale
           or else Validation = Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale;

         function Normalized_Result_Label return String
         is
         begin
            if Label'Length >= 6
              and then Label (Label'First .. Label'First + 5) = "Build "
            then
               return Label (Label'First + 6 .. Label'Last);
            else
               return Label;
            end if;
         end Normalized_Result_Label;

         function Duration_Suffix return String
         is
         begin
            if not S.Latest_Build_Result.Has_Duration then
               return "";
            else
               return ", "
                 & Editor.Build_Result_Summary.Duration_Label (S.Latest_Build_Result);
            end if;
         end Duration_Suffix;

         function Command_Suffix return String
         is
            Label : constant String :=
              Editor.Build_Result_Summary.Command_Label (S.Latest_Build_Result);
         begin
            if Label = "command unavailable" then
               return "";
            else
               return ", " & Label;
            end if;
         end Command_Suffix;

         function Diagnostics_Suffix return String
         is
         begin
            if S.Latest_Build_Result.Has_Diagnostics_Count then
               return ", diagnostics"
                 & Natural'Image
                   (S.Latest_Build_Result.Diagnostics_Count_If_Available);
            else
               return "";
            end if;
         end Diagnostics_Suffix;

         function Detail_Suffix return String is
         begin
            return Command_Suffix & Duration_Suffix & Diagnostics_Suffix;
         end Detail_Suffix;

         function Action_Rows_Suffix return String
         is
            Result : Unbounded_String := Null_Unbounded_String;
         begin
            if Build_UI_View.Actions.Is_Empty then
               return "";
            end if;

            for I in Build_UI_View.Actions.First_Index ..
              Build_UI_View.Actions.Last_Index
            loop
               declare
                  Row : constant Editor.Build_UI.Build_UI_Action_Row :=
                    Build_UI_View.Actions.Element (I);
                  Reason : constant String := To_String (Row.Disabled_Reason);
               begin
                  Append (Result, ASCII.LF);
                  if Row.Selected then
                     Append (Result, "  > ");
                  else
                     Append (Result, "  - ");
                  end if;
                  Append (Result, To_String (Row.Label));
                  Append (Result, " [");
                  Append (Result, To_String (Row.Command_Name));
                  Append (Result, "]");
                  if Row.Enabled then
                     Append (Result, " enabled");
                  elsif Reason'Length > 0 then
                     Append (Result, " disabled: ");
                     Append (Result, Reason);
                  else
                     Append (Result, " disabled");
                  end if;
               end;
            end loop;
            return To_String (Result);
         end Action_Rows_Suffix;

      begin
         if Build_UI_View.Visible then
            return "Build: "
              & To_String (Build_UI_View.Candidate_Count_Label)
              & "; "
              & To_String (Build_UI_View.Candidate_Refresh_Action_Label)
              & "; "
              & To_String (Build_UI_View.Request_Status_Label)
              & "; "
             & To_String (Build_UI_View.Run_Command_Status_Label)
             & "; "
             & To_String (Build_UI_View.Run_Recovery_Hint)
              & ASCII.LF
              & "Actions:"
              & Action_Rows_Suffix;
         end if;

         if S.Latest_Build_Result.Has_Result then
            if S.Latest_Build_Result.Stdout_Truncated
              or else S.Latest_Build_Result.Stderr_Truncated
            then
               if Candidate_Stale then
                  return "Build: " & Normalized_Result_Label
                    & Detail_Suffix & ", output truncated, candidate stale";
               else
                  return "Build: " & Normalized_Result_Label
                    & Detail_Suffix & ", output truncated";
               end if;
            elsif Candidate_Stale then
               return "Build: " & Normalized_Result_Label
                 & Detail_Suffix & ", candidate stale";
            else
               return "Build: " & Normalized_Result_Label & Detail_Suffix;
            end if;
         elsif Candidate_Stale then
            return "Build: candidate stale";
         elsif Validation = Editor.Build_UI.Build_UI_Rejected_Missing_Consent
           or else Validation = Editor.Build_UI.Build_UI_Rejected_Stale_Consent
         then
            return "Build: consent required";
         elsif Validation = Editor.Build_UI.Build_UI_Valid then
            return "Build: ready";
         else
            return "Build: "
              & Editor.Build_UI.Recovery_Message (Validation);
         end if;
      end Build_Status_Label;

      function Search_Status_Label return String
      is
         Count : constant Natural :=
           Editor.Project_Search.Result_Count (S.Project_Search);
         Replace_Count : constant Natural :=
           Editor.Project_Search.Included_Replacement_Count (S.Project_Search);
      begin
         if Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
            return "Replace: stale preview";
         elsif Editor.Project_Search.Replace_Preview_Status (S.Project_Search) =
           Editor.Project_Search.Project_Replace_Preview_Ok
         then
            return "Replace: preview" & Natural'Image (Replace_Count)
              & " replacements";
         elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
            return "Search: stale";
         elsif not Editor.Project_Search.Has_Query (S.Project_Search) then
            return "Search: no query";
         elsif Editor.Project_Search.Results_Truncated (S.Project_Search)
           or else Editor.Project_Search.Was_Truncated (S.Project_Search)
         then
            return "Search:" & Natural'Image (Count) & " results, limit reached";
         elsif Count = 0 then
            return "Search: no matches";
         else
            return "Search:" & Natural'Image (Count) & " results";
         end if;
      end Search_Status_Label;

      function Quick_Open_Status_Label return String
      is
         Count : constant Natural := Editor.Quick_Open.Visible_Count (S.Quick_Open);
         Scope : constant String := Editor.Quick_Open.Path_Scope (S.Quick_Open);
         Filter : constant Editor.Quick_Open.Quick_Open_File_Kind_Filter :=
           Editor.Quick_Open.File_Kind_Filter (S.Quick_Open);
      begin
         if not Editor.Quick_Open.Is_Open (S.Quick_Open) then
            if Scope'Length = 0 and then Filter = Editor.Quick_Open.All_Files then
               return "";
            elsif Scope'Length > 0 then
               return "Quick Open: scope " & Scope & ", "
                 & Editor.Quick_Open.File_Kind_Filter_Name (Filter);
            else
               return "Quick Open: "
                 & Editor.Quick_Open.File_Kind_Filter_Name (Filter);
            end if;
         elsif Editor.Quick_Open.Query_Text (S.Quick_Open) = "" then
            return "Quick Open: type to open file";
         elsif Count = 0 then
            return "Quick Open: no matches";
         else
            return "Quick Open:" & Natural'Image (Count) & " matches";
         end if;
      end Quick_Open_Status_Label;

      function File_Tree_Status_Label return String
      is
         Scan : constant Editor.File_Tree.File_Tree_Scan_Result :=
           Editor.File_Tree.Scan_Status (S.File_Tree);
         Files : constant Natural := Editor.File_Tree.File_Node_Count (S.File_Tree);
      begin
         case Scan.Status is
            when Editor.File_Tree.File_Tree_No_Project =>
               return "File Tree: No project open.";
            when Editor.File_Tree.File_Tree_Scan_Ok =>
               if Files = 0 then
                  return "File Tree: ready";
               else
                  return "File Tree:" & Natural'Image (Files) & " files";
               end if;
            when Editor.File_Tree.File_Tree_Root_Not_Found
               | Editor.File_Tree.File_Tree_Invalid_Root =>
               return "File Tree: refresh required";
            when others =>
               return "File Tree: unavailable";
         end case;
      end File_Tree_Status_Label;

      function Workspace_Status_Label return String
      is
      begin
         if S.Post_Restore_Feedback_Current
           and then S.Last_Restore_Summary_Available
         then
            return "Workspace: "
              & Editor.Workspace_Persistence.Restore_Details_Label
                (S.Last_Restore_Summary);
         elsif S.Post_Restore_Feedback_Current then
            return "Workspace: restore feedback";
         else
            return "";
         end if;
      end Workspace_Status_Label;

      function Recent_Projects_Status_Label return String
      is
         Count : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
         Missing : constant Natural :=
           Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects);
      begin
         if Count = 0 then
            return "";
         elsif Missing > 0 then
            return "Recent Projects:" & Natural'Image (Count)
              & " entries," & Natural'Image (Missing) & " missing";
         else
            return "Recent Projects:" & Natural'Image (Count) & " entries";
         end if;
      end Recent_Projects_Status_Label;

      function Startup_Status_Label return String
      is
      begin
         if Editor.Startup_Readiness.Has_Recorded_Startup_Summary then
            return Editor.Startup_Readiness.Status_Bar_Label
              (Editor.Startup_Readiness.Current_Startup_Summary);
         else
            return "";
         end if;
      end Startup_Status_Label;

      function Build_Status_Snapshot
        return Editor.Status_Bar.Status_Bar_Snapshot
      is
         Result : Editor.Status_Bar.Status_Bar_Snapshot;
         Found  : Boolean := False;
         Msg    : Editor.Messages.Editor_Message;
         Msg_Text : Unbounded_String := Null_Unbounded_String;
      begin
         Result.File_Name := Snap.File_Name;
         if Length (Result.File_Name) = 0 then
            Result.File_Name := To_Unbounded_String ("Untitled");
         end if;
         Result.File_Label := To_Unbounded_String (File_Label);
         Result.Buffer_Kind_Label := To_Unbounded_String (Buffer_Kind_Label);
         Result.File_State_Label := To_Unbounded_String (File_State_Label);
         Result.Has_Active_Buffer := Editor.State.Has_Active_Buffer (S);
         Result.Is_Dirty := Snap.Is_Dirty;
         if Snap.Is_Dirty then
            Result.Dirty_State_Label := To_Unbounded_String ("Modified");
         end if;
         Result.Cursor_Row := Snap.Primary_Caret_Logical_Row;
         Result.Cursor_Column := Snap.Primary_Caret_Col;
         Result.Selection_Count := Snap.Selection_Count;
         Result.Selected_Character_Count := Snap.Selected_Character_Count;
         Result.Selected_Line_Count := Snap.Selected_Line_Count;
         Result.Rectangular_Selection_Active := Snap.Rectangular_Selection_Count > 0;
         Result.Undo_Redo_Label := To_Unbounded_String (Undo_Redo_Label);
         Result.Caret_Count := Natural'Max (1, Snap.Caret_Count);
         Result.Line_Number_Mode := To_Unbounded_String (Line_Mode_Text);
         Result.Find_Active_Match :=
           (if Snap.Active_Find_Match.Index = Editor.Search.No_Search_Match
            then 0
            else Natural (Snap.Active_Find_Match.Index));
         Result.Active_Find_Match_Count := Snap.Total_Find_Match_Count;
         --  Status/render packet projection fields are derived
         --  from canonical active-buffer Find snapshot data only.
         Result.Find_Input_Open := Snap.Find_Visible;
         Result.Find_Query_Present := Length (Snap.Find_Query) > 0;
         Result.Find_Wrapped := Snap.Find_Wrapped;
         Result.Diagnostic_Count := Snap.Total_Diagnostic_Count;
         Result.Has_Project := Snap.Has_Project;
         Result.Project_Label := Snap.Project_Label;
         Result.Project_State_Label := To_Unbounded_String (Project_State_Label);
         Result.Focus_Label := To_Unbounded_String (Focus_Label);
         Result.Active_Panel_Label := To_Unbounded_String (Active_Panel_Label);
         Result.Input_Mode_Label := To_Unbounded_String (Input_Mode_Label);
         Result.Overlay_Query_Active :=
           Editor.Focus_Management.Overlay_Query_Active (S);
         Result.Focus_Hint :=
           To_Unbounded_String
             (Editor.Contextual_Help.Focus_Hint
                (Focus_Label, Editor.Command_Palette.Current_Config.Show_Keybindings));
         Result.Lifecycle_Hint :=
           To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
         Result.Pending_Confirmation_Label := To_Unbounded_String (Pending_Status_Label);
         Result.Outline_Status_Label := To_Unbounded_String (Outline_Status_Label);
         Result.Diagnostics_Status_Label := To_Unbounded_String (Diagnostics_Status_Label);
         Result.Build_Status_Label := To_Unbounded_String (Build_Status_Label);
         Result.Search_Status_Label := To_Unbounded_String (Search_Status_Label);
         Result.Quick_Open_Status_Label :=
           To_Unbounded_String (Quick_Open_Status_Label);
         Result.File_Tree_Status_Label :=
           To_Unbounded_String (File_Tree_Status_Label);
         Result.Workspace_Status_Label :=
           To_Unbounded_String (Workspace_Status_Label);
         Result.Recent_Projects_Status_Label :=
           To_Unbounded_String (Recent_Projects_Status_Label);
         Result.Outline_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Outline_Status_Label);
         Result.Diagnostics_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Diagnostics_Status_Label);
         Result.Build_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Build_Status_Label);
         Result.Search_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Search_Status_Label);
         Result.Quick_Open_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Quick_Open_Status_Label);
         Result.File_Tree_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.File_Tree_Status_Label);
         Result.Workspace_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Workspace_Status_Label);
         Result.Recent_Projects_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For
             (Result.Recent_Projects_Status_Label);
         Result.Startup_Status_Label :=
           To_Unbounded_String (Startup_Status_Label);
         if Editor.Buffers.Global_Has_Active_Buffer_Group then
            if Length (Result.Lifecycle_Hint) > 0 then
               Append (Result.Lifecycle_Hint, " | ");
            end if;
            Append
              (Result.Lifecycle_Hint,
               "Group: " & Editor.Buffers.Global_Active_Buffer_Group);
         end if;
         if Snap.Feature_Panel_Visible
           and then Editor.Feature_Panel.Is_Known_Feature (Snap.Active_Feature)
         then
            Result.Active_Feature_Label :=
              To_Unbounded_String
                (Editor.Feature_Panel.Feature_Display_Label (Snap.Active_Feature));
         end if;
         Msg := Editor.Messages.Active_Message (Snap.Messages, Found);
         if Found then
            Msg_Text := To_Unbounded_String (Editor.Messages.Text (Msg));
            if Snap.Post_Restore_Feedback_Current
              or else not Is_Restore_Feedback (To_String (Msg_Text))
            then
               Result.Has_Command_Feedback := True;
               Result.Command_Feedback := Msg_Text;
               Result.Command_Feedback_Severity :=
                 To_Unbounded_String (Severity_Label (Editor.Messages.Severity (Msg)));
            end if;
         end if;
         return Result;
      end Build_Status_Snapshot;
   begin
      if Snap.Terminal_Tasks.Visible then
         Editor.Terminal_Tasks.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      elsif Editor.Panels.Active_Bottom_Content (Layout.Panels) = Editor.Panels.Search_Results_Content then
         Editor.Search_Results.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      else
         Editor.Problems.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end if;

      declare
         Status_Snapshot : constant Editor.Status_Bar.Status_Bar_Snapshot :=
           Build_Status_Snapshot;
      begin
         Editor.Status_Bar.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Status_Snapshot,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
         Pending_Visible : Boolean := False;
         Pending_Background : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Pending_Summary_Text : Guikit.Draw.Text_Command_Vectors.Vector;
         Pending_Action_Text : Guikit.Draw.Text_Command_Vectors.Vector;
         Pending_Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Pending_Transition_Bar.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Pending        => S.Pending_Transitions,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;
   end Render;

end Editor.Render_Packet.Panel_Surfaces;
