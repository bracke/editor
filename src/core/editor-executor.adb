with Text_Buffer;
with Editor.State;
use type Editor.State.Dirty_Close_Scope;
use type Editor.State.Semantic_Popup_Kind;
with Editor.Cursors;    use Editor.Cursors;
with Editor.Commands;   use Editor.Commands;
with Editor.History;    use Editor.History;
with Ada.Containers;    use Ada.Containers;

with Editor.Invariants;
with Editor.Navigation; use Editor.Navigation;
with Editor.Executor.History;
with Editor.Executor.Structural;
with Editor.Executor.Navigation;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Availability;
with Editor.Executor.Command_Palette_Projection;
with Editor.Executor.Shared_Services;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Buffer_Navigation_Commands;
with Editor.Executor.Buffer_Metadata_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Feature_Panel_Commands;
with Editor.Executor.Editor_Preferences_Commands;
with Editor.Executor.Editing_Commands;
with Editor.Executor.Terminal_Commands;
with Editor.Executor.Build_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Overlay_Commands;
with Editor.Executor.Semantic_Commands;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Buffer_Switcher_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Preview_Commands;
with Editor.Executor.Buffer_Switcher_Selected_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Command_Result_Commands;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.Executor.Configuration_Commands;
with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Selection_Commands;
with Editor.Executor.Edits;
with Editor.Executor.Rectangular;
with Editor.Executor.Clipboard;
with Editor.Rectangle_Selection;
with Editor.UTF8;
with Editor.Unicode;
with Editor.Files;
use type Editor.Files.File_Rename_Status;
use type Editor.Files.File_Copy_Status;
use type Editor.Files.File_Move_Status;
use type Editor.Files.File_Open_Status;
with Editor.Search;
use type Editor.Search.Search_Match_Index;
with Editor.Messages;
with Editor.Clipboard;
with Editor.Project;
use type Editor.Project.Project_File_Refresh_Status;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.View;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
use type Editor.Buffers.Buffer_Ownership_Kind;
with Editor.Panels;
with Editor.Render_Cache;
with Editor.Dirty_Lines;
with Editor.Diagnostics;
with Editor.Layout;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Selection;
use type Editor.Selection.Selection_Validation_Status;
with Editor.Input_Field;
with Editor.Quick_Open;
with Editor.Quick_Open_Markers;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
use type Editor.Quick_Open.Quick_Open_Priority_Mode;
with Editor.Buffer_Switcher;
use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
with Editor.Go_To_Line;
with Editor.Bookmarks;
with Editor.Problems;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Command_Palette;
with Editor.Workspace_Persistence;
with Editor.Dirty_Guards;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;
with Editor.Command_Execution;
use type Editor.Command_Execution.Command_Execution_Status;
with Editor.External_Producers;
use type Editor.External_Producers.Build_Run_Status;
use type Editor.External_Producers.Process_Run_Status;
with Editor.Feature_Panel;
with Editor.Focus_Management;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Messages;
with Editor.Feature_Diagnostics;
use type Editor.Feature_Diagnostics.Diagnostic_Id;
with Editor.Navigation_History;
with Editor.Recent_Buffers;
with Editor.Outline;
use type Editor.Outline.Outline_Item_Kind;
use type Editor.Outline.Outline_Freshness;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
use type Editor.Ada_Language_Service.Service_Status;
with Editor.Ada_Project_Index;
with Editor.Syntax_Semantics;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Directories;
use type Ada.Directories.File_Kind;

package body Editor.Executor is
   function Has_Primary_Selection
     (S : Editor.State.State_Type) return Boolean;
   procedure Collapse_All_Selections
     (S : in out Editor.State.State_Type);
   procedure Recompute_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   function Primary_Cursor_Line_Of_Buffer
     (Id : Editor.Buffers.Buffer_Id) return Natural;
   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type);
   procedure Close_Buffer_By_Discard
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean);
   function Dirty_Buffer_Summary_For_All_Buffers
     return Editor.Dirty_Guards.Dirty_Buffer_Summary;
   function Dirty_Buffer_Summary_For_All_Buffers
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;
   function Dirty_Close_Open_Buffer_Fingerprint return Natural;
   function Dirty_Close_Dirty_Buffer_Fingerprint return Natural;
   function Dirty_Close_Open_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String;
   function Dirty_Close_Dirty_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String;
   function Dirty_Close_Current_Dirty_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean;
   function Dirty_Close_Current_Dirty_Set_Equals_Review
     (S : Editor.State.State_Type) return Boolean;
   function Dirty_Close_Current_Open_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean;
   function Dirty_Close_All_Buffer_Identity_Current
     (S : Editor.State.State_Type) return Boolean;
   function Dirty_Close_All_Buffer_Review_Current
     (S : Editor.State.State_Type) return Boolean;
   function Dirty_Close_Start_Message
     (All_Buffers : Boolean;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String;
   function Marked_Open_Count (S : Editor.State.State_Type) return Natural;
   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row;
   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Buffer_Token /= 0 then
         return S.Active_Buffer_Token;
      elsif Editor.Buffers.Global_Count > 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
      then
         return Natural (Editor.Buffers.Global_Active_Buffer);
      else
         return S.Registry_Token;
      end if;
   end Active_Feature_Buffer_Token;
   function Is_Ada_Source_Path
     (Path : String) return Boolean
   is
   begin
      return Editor.Executor.Semantic_Commands.Is_Ada_Source_Path (Path);
   end Is_Ada_Source_Path;
   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural)
   is
   begin
      Editor.Executor.Semantic_Commands.Publish_Service_Diagnostics_To_Feature
        (S, Path, Buffer_Token);
   end Publish_Service_Diagnostics_To_Feature;
   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural)
   is
   begin
      Editor.Executor.Semantic_Commands.Refresh_Project_Language_Index
        (S, Build_Semantics, Indexed_File_Count, Indexed_Symbols,
         Skipped_File_Count, Read_Error_Count);
   end Refresh_Project_Language_Index;
   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Semantic_Commands
        .Load_Global_Active_Preserving_Language_Index (S);
   end Load_Global_Active_Preserving_Language_Index;
   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Semantic_Commands
        .Rebuild_Language_Index_After_File_Lifecycle (S);
   end Rebuild_Language_Index_After_File_Lifecycle;
   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Semantic_Commands
        .Clear_Service_Semantic_Diagnostics_From_Feature (S);
   end Clear_Service_Semantic_Diagnostics_From_Feature;
   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean;
   function Feature_Target_Buffer_Is_Current
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
   is
   begin
      return Target_Buffer /= 0
        and then Target_Buffer = Active_Feature_Buffer_Token (S);
   end Feature_Target_Buffer_Is_Current;
   function Feature_Target_Buffer_Exists
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
   is
   begin
      if Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         return True;
      elsif Target_Buffer = 0 then
         return False;
      else
         return Editor.Buffers.Global_Contains
           (Editor.Buffers.Buffer_Id (Target_Buffer));
      end if;
   end Feature_Target_Buffer_Exists;
   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean
   is
   begin
      return Editor.Executor.Diagnostics_Commands.Feature_Target_Position_Is_Valid
        (S, Target_Buffer, Line, Column);
   end Feature_Target_Position_Is_Valid;
   function Feature_Target_Line_Count
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural) return Natural
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = 0 then
         return 0;
      elsif Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         Target_State := S;
      elsif Editor.Buffers.Global_Contains (Editor.Buffers.Buffer_Id (Target_Buffer)) then
         Target_State := Editor.Buffers.Buffer
           (Editor.Buffers.Global_Registry_For_UI,
            Editor.Buffers.Buffer_Id (Target_Buffer));
      else
         return 0;
      end if;

      return Editor.State.Line_Count (Target_State);
   end Feature_Target_Line_Count;
   function Feature_Target_Line_Length
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural) return Natural
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = 0 or else Line = 0 then
         return 0;
      elsif Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         Target_State := S;
      elsif Editor.Buffers.Global_Contains (Editor.Buffers.Buffer_Id (Target_Buffer)) then
         Target_State := Editor.Buffers.Buffer
           (Editor.Buffers.Global_Registry_For_UI,
            Editor.Buffers.Buffer_Id (Target_Buffer));
      else
         return 0;
      end if;

      if Line > Editor.State.Line_Count (Target_State) then
         return 0;
      end if;

      return Editor.Navigation.Line_Length (Target_State, Line - 1);
   end Feature_Target_Line_Length;
   function Diagnostic_Target_Failure_Label
     (S             : Editor.State.State_Type;
      Mapped        : Natural;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return String
   is
      Line_Count : constant Natural := Feature_Target_Line_Count (S, Target_Buffer);
   begin
      if Mapped = 0 then
         return "Selected diagnostic is no longer available.";
      elsif not Editor.Feature_Diagnostics.Item_Has_Target
        (S.Feature_Diagnostics, Positive (Mapped))
      then
         return "Selected diagnostic has no source target.";
      elsif Target_Buffer = 0
        or else not Feature_Target_Buffer_Exists (S, Target_Buffer)
      then
         return Editor.Commands.Reason_Target_Missing;
      elsif Line = 0 then
         return Editor.Commands.Reason_Diagnostic_Target_Line_Unavailable;
      elsif Line_Count = 0 or else Line > Line_Count then
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (Mapped))
         then
            return Editor.Commands.Reason_Target_Stale;
         else
            return Editor.Commands.Reason_Diagnostic_Target_Line_Outside_Buffer & ".";
         end if;
      elsif Column = 0 then
         return Editor.Commands.Reason_Diagnostic_Target_Column_Unavailable;
      elsif Column - 1 > Feature_Target_Line_Length (S, Target_Buffer, Line) then
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (Mapped))
         then
            return Editor.Commands.Reason_Target_Stale;
         else
            return Editor.Commands.Reason_Diagnostic_Target_Column_Outside_Line & ".";
         end if;
      else
         return "Navigation target unavailable.";
      end if;
   end Diagnostic_Target_Failure_Label;
   function Diagnostic_Availability_Reason
     (S             : Editor.State.State_Type;
      Mapped        : Natural;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return String
   is
   begin
      return Editor.Executor.Diagnostics_Commands.Diagnostic_Availability_Reason
        (S, Mapped, Target_Buffer, Line, Column);
   end Diagnostic_Availability_Reason;
   function Diagnostic_Quick_Fix_Action_Availability
     (S                : Editor.State.State_Type;
      Diagnostic_Index : Natural;
      Action_Index     : Natural)
      return Editor.Commands.Command_Availability
   is
   begin
      return Editor.Executor.Diagnostics_Commands
        .Diagnostic_Quick_Fix_Action_Availability
          (S, Diagnostic_Index, Action_Index);
   end Diagnostic_Quick_Fix_Action_Availability;
   function Focus_Feature_Target_Buffer
     (S             : in out Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
   is
   begin
      if Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         return True;
      elsif Target_Buffer /= 0
        and then Editor.Buffers.Global_Contains
          (Editor.Buffers.Buffer_Id (Target_Buffer))
      then
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Buffers.Global_Set_Active_Buffer
           (Editor.Buffers.Buffer_Id (Target_Buffer));
         Load_Global_Active_Preserving_Language_Index (S);
         return True;
      else
         return False;
      end if;
   end Focus_Feature_Target_Buffer;


   use type Editor.Files.File_Save_Status;
   use type Editor.Files.File_Open_Status;
   use type Editor.Files.File_External_Change_Status;
   use type Editor.State.File_Conflict_Kind;

   use type Editor.Buffers.Buffer_Id;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.File_Tree_View.File_Tree_Action;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Overlay_Focus.Previous_Focus_Target;
   use type Editor.Diagnostics.Diagnostic_Index;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Workspace_Persistence.Bottom_Content_Id;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Dirty_Guards.Dirty_Transition_Status;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Messages.Message_Severity;
   use type Editor.Ada_Language_Model.Symbol_Kind;
   use type Ada.Containers.Count_Type;
   use type Editor.Feature_Panel.Feature_Id;

   use Cursors_Vector;
   procedure Apply_Feature_Target_Handoff
     (S             : in out Editor.State.State_Type;
      Target_Row    : Natural;
      Target_Column : Natural)
   is
      Target_Index       : Editor.Cursors.Cursor_Index;
      Viewport_Rows      : Natural := 1;
      Desired            : Natural := 0;
      Visible_Target_Row : Natural := 0;
      Visible_Found      : Boolean := False;
      Visible_Count      : Natural := 1;
      Layout             : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Target_Row);

      Target_Index := Editor.Cursors.Cursor_Index
        (Index_For_Line_Column (S, Target_Row, Target_Column));

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Target_Index,
           Anchor                => Target_Index,
           Virtual_Column        => 0,
           Anchor_Virtual_Column => 0));
      S.Preferred_Column := Target_Column;

      Visible_Target_Row := Editor.Folding.Document_Row_To_Visible_Row
        (S.Folding, Target_Row, Visible_Found);
      if not Visible_Found then
         Visible_Target_Row := Target_Row;
      end if;

      Viewport_Rows := Natural'Max
        (1,
         Editor.Layout.Visible_Row_Count
           (Layout, Editor.View.Viewport_Height));
      Visible_Count := Natural'Max
        (1,
         Editor.Folding.Visible_Row_Count
           (S.Folding, Editor.State.Line_Count (S)));

      if Visible_Target_Row > Viewport_Rows / 2 then
         Desired := Visible_Target_Row - Viewport_Rows / 2;
      else
         Desired := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Visible_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired);
      Editor.View.Clear_User_Scroll_Override;

      Sync_Current_Outline_Symbol_From_Caret (S);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
   end Apply_Feature_Target_Handoff;

   function Default_Message_Config return Editor.Messages.Message_Config
   is
   begin
      return Editor.Executor.Shared_Services.Default_Message_Config;
   end Default_Message_Config;
   function Normalize_Project_Path_For_Command (Path : String) return String is
      Result : String (Path'Range);
   begin
      for I in Path'Range loop
         if Path (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;
      return Result;
   end Normalize_Project_Path_For_Command;
   function Active_Buffer_Known_Project_File
     (S     : Editor.State.State_Type;
      Found : out Boolean) return String
   is
      File      : constant Editor.State.File_State := Editor.State.Current_File (S);
      Raw_Path  : constant String := To_String (File.Path);
      Candidate : Unbounded_String := Null_Unbounded_String;
   begin
      Found := False;

      if not Editor.Project.Has_Project (S.Project)
        or else not Editor.State.Has_Active_Buffer (S)
        or else not File.Has_Path
        or else Editor.Project.Known_File_Count (S.Project) = 0
      then
         return "";
      end if;

      if Editor.Project.Is_Under_Project (S.Project, Raw_Path) then
         Candidate := To_Unbounded_String
           (Normalize_Project_Path_For_Command
              (Editor.Project.Relative_Path (S.Project, Raw_Path)));
      else
         Candidate := To_Unbounded_String
           (Normalize_Project_Path_For_Command (Raw_Path));
      end if;

      for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
         declare
            File_Item : constant Editor.Project.Project_File_Entry :=
              Editor.Project.Known_File_At (S.Project, I);
            Rel   : constant String :=
              Normalize_Project_Path_For_Command (To_String (File_Item.Relative_Path));
            Abs_Path   : constant String :=
              Normalize_Project_Path_For_Command (To_String (File_Item.Absolute_Path));
         begin
            if To_String (Candidate) = Rel or else Normalize_Project_Path_For_Command (Raw_Path) = Abs_Path then
               Found := True;
               return Rel;
            end if;
         end;
      end loop;

      return "";
   end Active_Buffer_Known_Project_File;
   function File_Lifecycle_Confirmation_Pending
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      --  the transient file-conflict prompt is a lifecycle
      --  confirmation boundary just like dirty reload/revert retry prompts.
      --  Treat it as modal for command availability so unrelated command
      --  routes cannot replace the conflict decision or mutate the same
      --  buffer while keep/reload/overwrite/cancel is pending.
      if S.Dirty_Close_Prompt_Active or else S.File_Conflict_Prompt_Active then
         return True;
      end if;

      if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         return False;
      end if;

      declare
         Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
           Editor.Pending_Transitions.Target (S.Pending_Transitions);
      begin
         return Target.Kind in
           Editor.Pending_Transitions.Pending_Reload_Active_Buffer
             | Editor.Pending_Transitions.Pending_Revert_Active_Buffer;
      end;
   end File_Lifecycle_Confirmation_Pending;

   function Has_Selected_Outline_Activation_Target
     (S : Editor.State.State_Type) return Boolean
   is
      Panel       : Editor.Feature_Panel.Feature_Panel_State := S.Feature_Panel;
      Row         : Natural := 0;
      Outline_Row : Natural := 0;
   begin
      if not Editor.Feature_Panel.Is_Visible (Panel) then
         return False;
      end if;

      if Editor.Outline.Selected_Index (S.Outline) > 0
        and then
          (Editor.Feature_Panel.Active_Feature (Panel) /=
             Editor.Feature_Panel.Outline_Feature
           or else not Editor.Feature_Panel.Has_Selection (Panel))
      then
         Editor.Outline.Set_Rows_From_Outline (S.Outline, Panel);
      end if;
      if not Editor.Feature_Panel.Has_Selection (Panel) then
         return False;
      end if;

      Row := Editor.Feature_Panel.Selected_Row (Panel);
      Outline_Row := Editor.Outline.Map_Panel_Row_To_Outline_Row
        (S.Outline, Panel, Row);
      if Outline_Row = 0 then
         return False;
      end if;

      declare
         Target_Buffer : constant Natural :=
           Editor.Outline.Item_Buffer_Token
             (S.Outline, Positive (Outline_Row));
         Target_Line : constant Natural :=
           Editor.Outline.Item_Line (S.Outline, Positive (Outline_Row));
         Target_Column : constant Natural :=
           Editor.Outline.Item_Column (S.Outline, Positive (Outline_Row));
      begin
         --  declaration navigation and open-selected availability
         --  must expose the same stale-target policy as execution.  A selected
         --  row is not enough; the retained Outline target must still map to a
         --  live buffer and an in-range source position before the command is
         --  advertised as available.
         return Editor.Outline.Validate_Outline_Row_For_Activation
             (S.Outline, Panel, Row, Target_Buffer)
           and then Feature_Target_Position_Is_Valid
             (S, Target_Buffer, Target_Line, Target_Column);
      end;
   end Has_Selected_Outline_Activation_Target;
   function Rename_Preview_Is_Open_Buffers_Applyable
     (S       : Editor.State.State_Type;
      Preview : Editor.Ada_Language_Service.Rename_Preview;
      Reason  : out Unbounded_String) return Boolean
   is
      Old_Name : constant String := To_String (Preview.Old_Name);
      New_Name : constant String := To_String (Preview.New_Name);
      function Buffer_For_Target
        (Target : Editor.Ada_Language_Service.Language_Target)
         return Editor.State.State_Type
      is
         Found : Boolean := False;
         Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
         Open  : Editor.Files.File_Open_Result;
         Temp  : Editor.State.State_Type;
      begin
         if Target.Key.Buffer_Token = S.Active_Buffer_Token then
            return S;
         elsif Target.Key.Buffer_Token /= 0
           and then Editor.Buffers.Global_Contains
             (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token))
         then
            return Editor.Buffers.Global_Buffer
              (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token));
         end if;

         Id := Editor.Buffers.Global_Find_By_Path
           (To_String (Target.Target.Path), Found);
         if Found then
            return Editor.Buffers.Global_Buffer (Id);
         end if;

         Open := Editor.Files.Open_File (To_String (Target.Target.Path));
         if Open.Status = Editor.Files.File_Open_Ok then
            Editor.State.Initialize (Temp);
            Editor.State.Replace_Buffer_Contents
              (Temp, To_String (Open.Contents));
            Temp.File_Info.Has_Path := True;
            Temp.File_Info.Path := Open.Path;
            Temp.File_Info.Display_Name := Open.Display_Name;
            return Temp;
         end if;

         return S;
      end Buffer_For_Target;

      function Target_State_Available
        (Target : Editor.Ada_Language_Service.Language_Target) return Boolean
      is
         Found : Boolean := False;
      begin
         if Target.Key.Buffer_Token = S.Active_Buffer_Token then
            return True;
         elsif Target.Key.Buffer_Token /= 0
           and then Editor.Buffers.Global_Contains
             (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token))
         then
            return True;
         end if;

         declare
            Ignored : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffers.Global_Find_By_Path
                (To_String (Target.Target.Path), Found);
            pragma Unreferenced (Ignored);
         begin
            if Found then
               return True;
            end if;
         end;

         return Editor.Files.Open_File (To_String (Target.Target.Path)).Status =
           Editor.Files.File_Open_Ok;
      end Target_State_Available;
   begin
      Reason := Null_Unbounded_String;

      if Preview.Status /= Editor.Ada_Language_Service.Service_Success then
         Reason := To_Unbounded_String
           ("Rename apply unavailable for " & Old_Name & ": " &
            Editor.Executor.Semantic_Commands.Service_Status_Image
              (Preview.Status) & ".");
         return False;
      elsif Preview.Conflict_Count > 0 then
         Reason := To_Unbounded_String
           ("Rename apply blocked for " & Old_Name & ": conflicts.");
         return False;
      elsif Preview.Edit_Count = 0 then
         Reason := To_Unbounded_String
           ("Rename apply unavailable for " & Old_Name & ": no edits.");
         return False;
      elsif S.Active_Buffer_Token = 0 then
         Reason := To_Unbounded_String
           ("Rename apply unavailable for " & Old_Name & ": no active buffer.");
         return False;
      end if;

      for Target of Preview.Edits loop
         if not Target_State_Available (Target) then
            Reason := To_Unbounded_String
              ("Rename apply unavailable for " & Old_Name &
               ": target file unavailable.");
            return False;
         else
            declare
               Target_State : constant Editor.State.State_Type :=
                 Buffer_For_Target (Target);
               Found_Open_By_Path : Boolean := False;
               Open_By_Path_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Global_Find_By_Path
                   (To_String (Target.Target.Path), Found_Open_By_Path);
               pragma Unreferenced (Open_By_Path_Id);
               Open_Target : constant Boolean :=
                 Target.Key.Buffer_Token = S.Active_Buffer_Token
                 or else
                   (Target.Key.Buffer_Token /= 0
                    and then Editor.Buffers.Global_Contains
                      (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token)));
            begin
               if Open_Target
                 and then not Feature_Target_Position_Is_Valid
                   (Target_State, Target.Key.Buffer_Token,
                    Target.Target.Line, Target.Target.Column)
               then
                  Reason := To_Unbounded_String
                    ("Rename apply unavailable for " & Old_Name &
                     ": stale edit target.");
                  return False;
               elsif (not Open_Target)
                 and then
                   (Target.Target.Line = 0
                    or else Target.Target.Column = 0
                    or else Target.Target.Line >
                      Editor.State.Line_Count (Target_State)
                    or else Target.Target.Column - 1 >
                      Editor.Navigation.Line_Length
                        (Target_State, Target.Target.Line - 1))
               then
                  Reason := To_Unbounded_String
                    ("Rename apply unavailable for " & Old_Name &
                     ": stale edit target.");
                  return False;
               elsif Target.Target.Column = 0
                 or else Target.Target.Column - 1 + Old_Name'Length >
                   Editor.Navigation.Line_Length
                     (Target_State, Target.Target.Line - 1)
               then
                  Reason := To_Unbounded_String
                    ("Rename apply unavailable for " & Old_Name &
                     ": stale edit target.");
                  return False;
               else
                  declare
                     Pos : constant Natural :=
                       Index_For_Line_Column
                         (Target_State, Target.Target.Line - 1,
                          Target.Target.Column - 1);
                     Current : constant String :=
                       To_String
                         (Extract_Text
                            (Target_State.Buffer, Pos, Old_Name'Length));
                  begin
                     if Current /= Old_Name and then Current /= New_Name then
                        Reason := To_Unbounded_String
                          ("Rename apply unavailable for " & Old_Name &
                           ": stale edit target.");
                        return False;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;

      return True;
   end Rename_Preview_Is_Open_Buffers_Applyable;
   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String
   is
   begin
      return Editor.Executor.Semantic_Commands.Current_Semantic_Symbol_Name (State);
   end Current_Semantic_Symbol_Name;
   function Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      return Editor.Executor.Availability.Command_Availability (S, Id);
   end Command_Availability;

   function Visible_Restore_Message_In_History
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.Shared_Services.Visible_Restore_Message_In_History (S);
   end Visible_Restore_Message_In_History;
   function Current_Navigation_Location
     (S      : Editor.State.State_Type;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      return Editor.Executor.Navigation_Commands.Current_Navigation_Location
        (S, Reason);
   end Current_Navigation_Location;
   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      return Editor.Executor.Navigation_Commands.Structured_File_Navigation_Target
        (Path, Line, Column, Reason);
   end Structured_File_Navigation_Target;
   function Same_Navigation_Place
     (S        : Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location) return Boolean
   is
   begin
      return Editor.Executor.Navigation_Commands.Same_Navigation_Place
        (S, Location);
   end Same_Navigation_Place;
   procedure Record_Navigation_If_Target_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location;
      Target   : Editor.Navigation_History.Navigation_Location)
   is
   begin
      Editor.Executor.Navigation_Commands.Record_Navigation_If_Target_Changed
        (S, Previous, Target);
   end Record_Navigation_If_Target_Changed;
   procedure Record_Navigation_If_Current_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location)
   is
   begin
      Editor.Executor.Navigation_Commands.Record_Navigation_If_Current_Changed
        (S, Previous);
   end Record_Navigation_If_Current_Changed;
   function Apply_Navigation_Location
     (S        : in out Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location;
      Status   : out Navigation_Apply_Status) return Boolean
   is
   begin
      return Editor.Executor.Navigation_Commands.Apply_Navigation_Location
        (S, Location, Status);
   end Apply_Navigation_Location;
   procedure Clear_Restore_Feedback_Current
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Workspace_Commands.Clear_Restore_Feedback_Current (S);
   end Clear_Restore_Feedback_Current;
   procedure Mark_Restore_Summary_Current
     (S       : in out Editor.State.State_Type;
      Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary)
   is
   begin
      Editor.Executor.Workspace_Commands.Mark_Restore_Summary_Current
        (S, Summary);
   end Mark_Restore_Summary_Current;
   procedure Report_Restore_Success
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Workspace_Commands.Report_Restore_Success (S, Text);
   end Report_Restore_Success;
   procedure Report_Restore_Warning
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Workspace_Commands.Report_Restore_Warning (S, Text);
   end Report_Restore_Warning;
   function Restore_Summary_Message
      (Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Partial : Boolean) return String
   is
   begin
      return Editor.Executor.Workspace_Commands.Restore_Summary_Message
        (Summary, Partial);
   end Restore_Summary_Message;
   procedure Report_Workspace_Load_Status
     (S      : in out Editor.State.State_Type;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status)
   is
   begin
      Editor.Executor.Workspace_Commands.Report_Workspace_Load_Status
        (S, Status);
   end Report_Workspace_Load_Status;
   function Execute_Command_With_Result
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False) return Command_Execution_Result
   is
   begin
      return Editor.Executor.Command_Result_Commands.Execute_Command_With_Result
        (S, Id, Shift);
   end Execute_Command_With_Result;
   function Execute_User_Opt_In_Build_Command
     (S               : in out Editor.State.State_Type;
      Context         : Editor.External_Producers.User_Opt_In_Build_Command_Context;
      Supplied_Result : Editor.External_Producers.Process_Run_Result :=
        (Status        => Editor.External_Producers.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Editor.External_Producers.Build_Command_Result
   is
   begin
      return Editor.External_Producers.Execute_User_Opt_In_Build_Command
        (S, Context, Supplied_Result);
   end Execute_User_Opt_In_Build_Command;
   procedure Execute_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
   is
      Owner_Before : constant Editor.Focus_Management.Focus_Owner :=
        Editor.Focus_Management.Effective_Focus_Owner (S);
      Result : constant Command_Execution_Result :=
        Execute_Command_With_Result (S, Id, Shift);
   begin
      --  stable command-id execution is itself a product command
      --  route, not just an implementation helper for Input_Bridge.  Apply
      --  the same focus-return policy here so direct Executor callers,
      --  command-palette acceptance, tests, and surface-specific helpers do
      --  not diverge.  Unavailable/failed/no-op commands deliberately keep
      --  focus where the user can correct the problem.
      if Result.Status = Editor.Command_Execution.Command_Executed then
         Editor.Focus_Management.Apply_Command_Focus_Result
           (S, Id, Owner_Before);
      end if;
   end Execute_Command;

   ------------------------------------------------------------------------
   --  overlay-focus helpers
   ------------------------------------------------------------------------
   function Is_Focus_Target_Still_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target) return Boolean
   is
   begin
      return Editor.Executor.Overlay_Commands.Is_Focus_Target_Still_Valid
        (S, Target);
   end Is_Focus_Target_Still_Valid;

   procedure Restore_Previous_Overlay_Focus
     (S      : in out Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target)
   is
   begin
      Editor.Executor.Overlay_Commands.Restore_Previous_Overlay_Focus
        (S, Target);
   end Restore_Previous_Overlay_Focus;

   procedure Activate_Overlay
     (S       : in out Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target)
   is
   begin
      Editor.Executor.Overlay_Commands.Activate_Overlay (S, Overlay);
   end Activate_Overlay;

   procedure Deactivate_Active_Overlay_Only
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason)
   is
   begin
      Editor.Executor.Overlay_Commands.Deactivate_Active_Overlay_Only
        (S, Reason);
   end Deactivate_Active_Overlay_Only;

   procedure Dismiss_Active_Overlay
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason)
   is
   begin
      Editor.Executor.Overlay_Commands.Dismiss_Active_Overlay (S, Reason);
   end Dismiss_Active_Overlay;

   function Primary_Caret_Index
     (S : Editor.State.State_Type) return Extended_Index is
   begin
      return S.Carets.First_Index;
   end Primary_Caret_Index;
   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets (Primary_Caret_Index (S)).Pos;
      end if;
   end Safe_Caret;

   --  cursor/current-symbol synchronization seam.  Cursor movement
   --  may update the passive current-symbol state from the latest accepted
   --  extracted outline rows.  It must not trigger extraction, change outline
   --  selection, navigate the editor, or apply stale rows across buffer-token
   --  boundaries.  The cached cursor key suppresses duplicate recomputation
   --  when the active buffer identity and caret line/column are unchanged.
   procedure Sync_Current_Outline_Symbol_From_Caret
     (S : in out Editor.State.State_Type)
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if not Editor.State.Has_Active_Buffer (S) or else S.Registry_Token = 0 then
         S.Outline_Cursor_Key_Valid := False;
         if Editor.Outline.Has_Current_Symbol (S.Outline) then
            Editor.Outline.Clear_Current_Symbol (S.Outline);
            Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
         end if;
         return;
      end if;

      Line_Column_For_Index (S, Natural (Safe_Caret (S)), Row, Col);

      if S.Outline_Cursor_Key_Valid
        and then S.Outline_Cursor_Buffer_Token = Active_Feature_Buffer_Token (S)
        and then S.Outline_Cursor_Line = Row + 1
        and then S.Outline_Cursor_Column = Col + 1
      then
         if Editor.Outline.Source_Class (S.Outline) /= Editor.Outline.Extracted_Outline
           and then Editor.Outline.Has_Current_Symbol (S.Outline)
         then
            Editor.Outline.Clear_Current_Symbol (S.Outline);
            Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
         end if;
         return;
      end if;

      S.Outline_Cursor_Key_Valid := True;
      S.Outline_Cursor_Buffer_Token := Active_Feature_Buffer_Token (S);
      S.Outline_Cursor_Line := Row + 1;
      S.Outline_Cursor_Column := Col + 1;

      if Editor.Outline.Source_Class (S.Outline) /= Editor.Outline.Extracted_Outline then
         if Editor.Outline.Has_Current_Symbol (S.Outline) then
            Editor.Outline.Clear_Current_Symbol (S.Outline);
            Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
         end if;
         return;
      end if;

      Editor.Outline.Update_Current_Symbol_For_Cursor
        (S.Outline, Active_Feature_Buffer_Token (S), Row + 1, Col + 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
   end Sync_Current_Outline_Symbol_From_Caret;
   function Safe_Anchor
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets (Primary_Caret_Index (S)).Anchor;
      end if;
   end Safe_Anchor;
   function Has_Primary_Selection
     (S : Editor.State.State_Type) return Boolean is
   begin
      if S.Carets.Length = 0 then
         return False;
      else
         return Editor.Rectangle_Selection.Has_Selection
           (S.Carets (Primary_Caret_Index (S)));
      end if;
   end Has_Primary_Selection;
   procedure Set_Primary_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index) is
      C : Caret_State;
   begin
      if S.Carets.Length = 0 then
         S.Carets.Append (Caret_State'(
            Pos => Pos,
            Anchor => Pos,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      else
         C := S.Carets (Primary_Caret_Index (S));
         C.Pos := Pos;
         C.Anchor := Pos;
         S.Carets.Replace_Element (Primary_Caret_Index (S), C);
      end if;
   end Set_Primary_Caret;
   procedure Set_Primary_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Cursor_Index;
      Pos    : Cursor_Index) is
      C : Caret_State;
   begin
      if S.Carets.Length = 0 then
         S.Carets.Append (Caret_State'(
            Pos => Pos,
            Anchor => Anchor,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      else
         C := S.Carets (Primary_Caret_Index (S));
         C.Pos := Pos;
         C.Anchor := Anchor;
         S.Carets.Replace_Element (Primary_Caret_Index (S), C);
      end if;
   end Set_Primary_Selection;
   procedure Collapse_All_Selections
     (S : in out Editor.State.State_Type) is
      C : Caret_State;
   begin
      if S.Carets.Length = 0 then
         return;
      end if;

      for I in S.Carets.First_Index .. S.Carets.Last_Index loop
         C := S.Carets (I);
         C.Anchor := C.Pos;
         S.Carets.Replace_Element (I, C);
      end loop;
   end Collapse_All_Selections;
   procedure Collapse_Selection_To_Caret
     (S : in out Editor.State.State_Type; New_Caret : Cursor_Index) is
   begin
      Set_Primary_Caret (S, New_Caret);
   end Collapse_Selection_To_Caret;
   ------------------------------------------------------------------------
   -- Text helpers
   ------------------------------------------------------------------------
   function One_Char_Text (Ch : Character) return Unbounded_String is
   begin
      return To_Unbounded_String (String'(1 => Ch));
   end One_Char_Text;
   function Empty_Text return Unbounded_String is
   begin
      return Null_Unbounded_String;
   end Empty_Text;
   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;
   function Extract_Text
     (Buffer : Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Count  : Natural) return Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Count = 0 then
         return Result;
      end if;

      for I in 0 .. Count - 1 loop
         Append (Result, Editor.UTF8.Encode_UTF8
           (Text_Buffer.Code_Point_At (Buffer, Pos + I)));
      end loop;

      return Result;
   end Extract_Text;
   procedure Insert_Text_At
     (Buffer : in out Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Text   : Unbounded_String)
   is
      S : constant String := To_String (Text);
   begin
      if S'Length = 0 then
         return;
      end if;

      for I in S'Range loop
         Text_Buffer.Insert (Buffer, Pos + Natural (I - S'First), S (I));
      end loop;
   end Insert_Text_At;

   function File_Tree_Status_Message
     (Result : Editor.File_Tree.File_Tree_Scan_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when Editor.File_Tree.File_Tree_Scan_Ok =>
            return "ok";
         when Editor.File_Tree.File_Tree_No_Project =>
            return "no project";
         when Editor.File_Tree.File_Tree_Invalid_Root =>
            return "invalid root";
         when Editor.File_Tree.File_Tree_Root_Not_Found =>
            return "root not found";
         when Editor.File_Tree.File_Tree_Root_Not_Directory =>
            return "root is not a directory";
         when Editor.File_Tree.File_Tree_Permission_Denied =>
            return "permission denied";
         when Editor.File_Tree.File_Tree_Read_Error =>
            return "file tree read error";
      end case;
   end File_Tree_Status_Message;
   function File_Tree_Refresh_Failure_Message
     (Result : Editor.File_Tree.File_Tree_Scan_Result) return String
   is
   begin
      --  completeness: explicit File Tree refresh should surface the
      --  canonical project-explorer failure class instead of leaking low-level
      --  scan wording such as "root not found" or "root is not a directory".
      --  Detailed scan text remains available to project-open diagnostics via
      --  File_Tree_Status_Message; this helper is for the user-facing refresh
      --  command contract.
      case Result.Status is
         when Editor.File_Tree.File_Tree_Scan_Ok =>
            return "ok";
         when Editor.File_Tree.File_Tree_No_Project =>
            return "No project open";
         when Editor.File_Tree.File_Tree_Invalid_Root
            | Editor.File_Tree.File_Tree_Root_Not_Found
            | Editor.File_Tree.File_Tree_Root_Not_Directory =>
            return "Project root unavailable";
         when Editor.File_Tree.File_Tree_Permission_Denied =>
            return "Permission denied";
         when Editor.File_Tree.File_Tree_Read_Error =>
            return "File Tree unavailable";
      end case;
   end File_Tree_Refresh_Failure_Message;
   function Selected_Single_Line_Text
     (S     : Editor.State.State_Type;
      Found : out Boolean) return String
   is
      A : Cursor_Index := Safe_Anchor (S);
      B : Cursor_Index := Safe_Caret (S);
      Start_Pos : Cursor_Index := 0;
      End_Pos   : Cursor_Index := 0;
      Start_Row : Natural := 0;
      Start_Col : Natural := 0;
      End_Row   : Natural := 0;
      End_Col   : Natural := 0;
   begin
      Found := False;
      if S.Rect_Select_Active or else S.Carets.Length /= 1 or else A = B then
         return "";
      end if;

      if A < B then
         Start_Pos := A;
         End_Pos := B;
      else
         Start_Pos := B;
         End_Pos := A;
      end if;

      Editor.State.Row_Col_For_Index (S, Start_Pos, Start_Row, Start_Col);
      Editor.State.Row_Col_For_Index (S, End_Pos, End_Row, End_Col);
      if Start_Row /= End_Row then
         return "";
      end if;

      Found := True;
      return To_String
        (Extract_Text
           (S.Buffer, Natural (Start_Pos), Natural (End_Pos - Start_Pos)));
   end Selected_Single_Line_Text;
   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.Find_Replace_Commands.Has_Find_Target_Buffer (S);
   end Has_Find_Target_Buffer;
   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Command_Surface_Commands.Recompute_Quick_Open (S);
   end Recompute_Quick_Open;
   procedure Recompute_Buffer_Switcher
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
   end Recompute_Buffer_Switcher;
   function Primary_Cursor_Line_Of_Buffer
     (Id : Editor.Buffers.Buffer_Id) return Natural
   is
   begin
      return Editor.Executor.Buffer_Switcher_Shared.Primary_Cursor_Line_Of_Buffer (Id);
   end Primary_Cursor_Line_Of_Buffer;
   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target
        (S);
   end Normalize_Switcher_Preview_Target;
   function Natural_Image_Trimmed (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Natural_Image_Trimmed;
   function File_Count_Text (Count : Natural) return String is
   begin
      if Count = 1 then
         return "1 file";
      else
         return Natural_Image_Trimmed (Count) & " files";
      end if;
   end File_Count_Text;
   function Format_Project_File_Refresh_Message
     (Result : Editor.Project.Project_File_Refresh_Result) return String
   is
      Text : Unbounded_String := To_Unbounded_String
        ("Project files refreshed: " & File_Count_Text (Result.Total_Count));
   begin
      if Result.Added_Count > 0 then
         Append (Text, "; added " & Natural_Image_Trimmed (Result.Added_Count));
      end if;
      if Result.Removed_Count > 0 then
         Append (Text, "; removed " & Natural_Image_Trimmed (Result.Removed_Count));
      end if;
      if Result.Ignored_Path_Count > 0 then
         Append
           (Text,
            "; excluded " & Natural_Image_Trimmed (Result.Ignored_Path_Count)
            & (if Result.Ignored_Path_Count = 1 then " ignored path" else " ignored paths"));
      end if;
      if Result.Invalid_Ignore_Pattern_Count > 0 then
         Append
           (Text,
            "; ignored " & Natural_Image_Trimmed (Result.Invalid_Ignore_Pattern_Count)
            & (if Result.Invalid_Ignore_Pattern_Count = 1 then " invalid pattern" else " invalid patterns"));
      end if;
      if Result.Skipped_Directory_Count > 0 then
         Append
           (Text,
            "; skipped " & Natural_Image_Trimmed (Result.Skipped_Directory_Count)
            & (if Result.Skipped_Directory_Count = 1 then " directory" else " directories"));
      end if;
      return To_String (Text);
   end Format_Project_File_Refresh_Message;
   function Format_Project_File_Summary_Message
     (S : Editor.State.State_Type) return String
   is
      Count : constant Natural := Editor.Project.Known_File_Count (S.Project);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         return "No project open";
      elsif Count = 0 then
         return "No project open.";
      elsif Editor.Project.Has_Last_Refresh_Summary (S.Project) then
         declare
            Summary : constant Editor.Project.Project_File_Refresh_Result :=
              Editor.Project.Last_Refresh_Summary (S.Project);
            Text : Unbounded_String := To_Unbounded_String
              ("Project files: " & Natural_Image_Trimmed (Count) & " known files");
         begin
            if Summary.Added_Count > 0 or else Summary.Removed_Count > 0 then
               Append (Text, "; last refresh");
               if Summary.Added_Count > 0 then
                  Append (Text, " added " & Natural_Image_Trimmed (Summary.Added_Count));
               end if;
               if Summary.Removed_Count > 0 then
                  if Summary.Added_Count > 0 then
                     Append (Text, ",");
                  end if;
                  Append (Text, " removed " & Natural_Image_Trimmed (Summary.Removed_Count));
               end if;
            end if;
            if Summary.Ignored_Path_Count > 0 then
               Append
                 (Text,
                  (if Summary.Added_Count > 0 or else Summary.Removed_Count > 0 then ";" else "; last refresh")
                  & " excluded " & Natural_Image_Trimmed (Summary.Ignored_Path_Count)
                  & (if Summary.Ignored_Path_Count = 1 then " ignored path" else " ignored paths"));
            end if;
            if Summary.Invalid_Ignore_Pattern_Count > 0 then
               Append
                 (Text,
                  "; last refresh ignored "
                  & Natural_Image_Trimmed (Summary.Invalid_Ignore_Pattern_Count)
                  & (if Summary.Invalid_Ignore_Pattern_Count = 1 then " invalid pattern" else " invalid patterns"));
            end if;
            return To_String (Text);
         end;
      else
         return "Project files: " & Natural_Image_Trimmed (Count) & " known files";
      end if;
   end Format_Project_File_Summary_Message;
   procedure Apply_Project_Open_Workspace_Policy
     (S      : in out Editor.State.State_Type;
      Config : Editor.Workspace_Persistence.Workspace_Lifecycle_Config :=
        Editor.Workspace_Persistence.Default_Workspace_Lifecycle_Config)
   is
   begin
      Editor.Executor.Project_Lifecycle_Commands.Apply_Project_Open_Workspace_Policy
        (S, Config);
   end Apply_Project_Open_Workspace_Policy;
   procedure Populate_Project_Known_Files_From_File_Tree
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Project_Lifecycle_Commands.Populate_Project_Known_Files_From_File_Tree (S);
   end Populate_Project_Known_Files_From_File_Tree;
   function Existing_File_Tree_File_Target
     (Path : String) return Boolean
   is
   begin
      return Path'Length > 0
        and then Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File;
   exception
      when others =>
         return False;
   end Existing_File_Tree_File_Target;
   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : out Editor.Workspace_Persistence.Workspace_Restore_Summary)
   is
   begin
      Editor.Executor.Workspace_Commands.Restore_Workspace_Snapshot
        (S, Snapshot, Status, Summary);
   end Restore_Workspace_Snapshot;
   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status)
   is
   begin
      Editor.Executor.Workspace_Commands.Restore_Workspace_Snapshot
        (S, Snapshot, Status);
   end Restore_Workspace_Snapshot;
   function Save_Failure_Recovery_Message
     (Result : Editor.Files.File_Save_Result) return String
   is
      pragma Unreferenced (Result);
   begin
      return "Could not save file";
   end Save_Failure_Recovery_Message;
   function Read_Failure_Recovery_Message
     (Result    : Editor.Files.File_Open_Result;
      Operation : String) return String
   is
      pragma Unreferenced (Result);
   begin
      return "Could not " & Operation & " buffer";
   end Read_Failure_Recovery_Message;
   procedure Finalize_Cleanup_Buffer_Close
     (S          : in out Editor.State.State_Type;
      Id         : Editor.Buffers.Buffer_Id;
      Was_Active : Boolean)
   is
   begin
      Editor.Executor.File_Lifecycle_Commands.Finalize_Cleanup_Buffer_Close
        (S, Id, Was_Active);
   end Finalize_Cleanup_Buffer_Close;
   function Dirty_Close_Start_Message
     (All_Buffers : Boolean;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Start_Message
        (All_Buffers, Summary);
   end Dirty_Close_Start_Message;
   function Dirty_Buffer_Summary_For_All_Buffers
     return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return
        Editor.Executor.File_Lifecycle_Commands
          .Dirty_Buffer_Summary_For_All_Buffers;
   end Dirty_Buffer_Summary_For_All_Buffers;
   function Dirty_Buffer_Summary_For_All_Buffers
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Buffer_Summary_For_All_Buffers
        (Project);
   end Dirty_Buffer_Summary_For_All_Buffers;
   function Dirty_Close_Open_Buffer_Fingerprint return Natural is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Open_Buffer_Fingerprint;
   end Dirty_Close_Open_Buffer_Fingerprint;
   function Dirty_Close_Dirty_Buffer_Fingerprint return Natural is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Dirty_Buffer_Fingerprint;
   end Dirty_Close_Dirty_Buffer_Fingerprint;
   function Dirty_Close_Open_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Open_Buffer_Id_List;
   end Dirty_Close_Open_Buffer_Id_List;
   function Dirty_Close_Dirty_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Dirty_Buffer_Id_List;
   end Dirty_Close_Dirty_Buffer_Id_List;
   function Dirty_Close_Current_Dirty_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Current_Dirty_Set_Was_Reviewed (S);
   end Dirty_Close_Current_Dirty_Set_Was_Reviewed;
   function Dirty_Close_Current_Dirty_Set_Equals_Review
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Current_Dirty_Set_Equals_Review (S);
   end Dirty_Close_Current_Dirty_Set_Equals_Review;
   function Dirty_Close_Current_Open_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_Current_Open_Set_Was_Reviewed (S);
   end Dirty_Close_Current_Open_Set_Was_Reviewed;
   function Dirty_Close_All_Buffer_Identity_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_All_Buffer_Identity_Current (S);
   end Dirty_Close_All_Buffer_Identity_Current;
   function Dirty_Close_All_Buffer_Review_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.File_Lifecycle_Commands.Dirty_Close_All_Buffer_Review_Current (S);
   end Dirty_Close_All_Buffer_Review_Current;
   procedure Start_Dirty_Close_Prompt
     (S           : in out Editor.State.State_Type;
      Scope       : Editor.State.Dirty_Close_Scope;
      All_Buffers : Boolean;
      Buffer_Id   : Editor.Buffers.Buffer_Id;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary)
   is
   begin
      Editor.Executor.File_Lifecycle_Commands.Start_Dirty_Close_Prompt
        (S, Scope, All_Buffers, Buffer_Id, Summary);
   end Start_Dirty_Close_Prompt;
   procedure Close_Buffer_By_Discard
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean)
   is
   begin
      Editor.Executor.File_Lifecycle_Commands.Close_Buffer_By_Discard
        (S, Id, Closed);
   end Close_Buffer_By_Discard;
   function Trimmed_Command_Text (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed_Command_Text;
   function Valid_Buffer_Label_Text (Text : String) return Boolean is
   begin
      return Editor.Executor.Buffer_Metadata_Commands.Valid_Buffer_Label_Text
        (Text);
   end Valid_Buffer_Label_Text;
   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
   is
   begin
      return Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer (S, Found);
   end Selected_Switcher_Buffer;
   procedure Recompute_Buffer_Switcher_After_Selected_Action
     (S              : in out Editor.State.State_Type;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural)
   is
   begin
      Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher_After_Selected_Action (S, Preferred_Id, Fallback_Index);
   end Recompute_Buffer_Switcher_After_Selected_Action;
   function Marked_Open_Count (S : Editor.State.State_Type) return Natural
   is
   begin
      return Editor.Executor.Buffer_Switcher_Shared.Marked_Open_Count (S);
   end Marked_Open_Count;
   procedure Recompute_Buffer_Switcher_After_Marked_Action
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher_After_Marked_Action (S);
   end Recompute_Buffer_Switcher_After_Marked_Action;
   function Save_As_Target_Parent_Missing
     (Path : String) return Boolean
   is
      Dir : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      return Dir'Length > 0 and then not Ada.Directories.Exists (Dir);
   exception
      when others =>
         return False;
   end Save_As_Target_Parent_Missing;
   procedure Clear_Reopen_Candidate
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.File_Lifecycle_Commands.Clear_Reopen_Candidate (S);
   end Clear_Reopen_Candidate;
   function Problems_Visible_Row_Count return Natural
   is
   begin
      return Editor.Executor.Panel_Focus_Commands.Problems_Visible_Row_Count;
   end Problems_Visible_Row_Count;
   procedure Ensure_Problems_Selection_Visible
     (S : in out Editor.State.State_Type)
   is
      Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Filtered_Snapshot
          (Editor.Problems.Build_Snapshot (S.Diagnostics), S.Problems_View);
   begin
      Editor.Problems.Ensure_Selected_Row_Visible
        (S.Problems_View, Snapshot, Problems_Visible_Row_Count);
   end Ensure_Problems_Selection_Visible;
   function File_Tree_Visible_Row_Count_For_View return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.File_Tree_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
   begin
      if Editor.Layout.Cell_H = 0 then
         return 1;
      else
         return Natural'Max (1, Panel.Height / Editor.Layout.Cell_H);
      end if;
   end File_Tree_Visible_Row_Count_For_View;
   procedure Validate_File_Tree_View
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.File_Tree_View.Ensure_Valid_Selection (S.File_Tree_View, S.File_Tree);
      Editor.File_Tree_View.Ensure_Selected_Row_Visible
        (S.File_Tree_View, S.File_Tree, File_Tree_Visible_Row_Count_For_View);
   end Validate_File_Tree_View;
   function Selected_File_Tree_Node
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.File_Tree.File_Tree_Node_Id
   is
   begin
      return Editor.File_Tree_View.Node_For_Row
        (S.File_Tree, Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View), Found);
   end Selected_File_Tree_Node;
   procedure Select_File_Tree_Node
     (S    : in out Editor.State.State_Type;
      Node : Editor.File_Tree.File_Tree_Node_Id)
   is
      Found : Boolean := False;
      Row   : Natural := 0;
   begin
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      if Found then
         Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
         Validate_File_Tree_View (S);
      end if;
   end Select_File_Tree_Node;
   function Search_Results_Visible_Row_Count return Natural
   is
   begin
      return Editor.Executor.Search_Results_Commands.Search_Results_Visible_Row_Count;
   end Search_Results_Visible_Row_Count;
   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
   end Ensure_Search_Result_Visible;
   ------------------------------------------------------------------------
   -- Secondary helpers expected elsewhere in the codebase
   ------------------------------------------------------------------------
   procedure Normalize_Carets (S : in out Editor.State.State_Type) is
   begin
      Editor.State.Normalize_Carets (S);
   end Normalize_Carets;
   procedure Add_Caret_At_Point
     (S : in out Editor.State.State_Type; X : Natural; Y : Natural)
   is
      Pos : constant Cursor_Index := Index_For_Point (S, X, Y);
   begin
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      Editor.State.Normalize_Carets (S);
   end Add_Caret_At_Point;
   procedure Keep_Only_Primary_Caret
     (S : in out Editor.State.State_Type) is
      Primary : Caret_State := (
         Pos => 0,
         Anchor => 0,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      );
   begin
      if S.Carets.Length > 0 then
         Primary := S.Carets (Primary_Caret_Index (S));
      end if;

      S.Carets.Clear;
      S.Carets.Append (Primary);
   end Keep_Only_Primary_Caret;
   procedure Select_Word_At_Point
     (S         : in out Editor.State.State_Type;
      X         : Natural;
      Y         : Natural;
      New_Caret : out Cursor_Index)
   is
      Pos : constant Cursor_Index := Index_For_Point (S, X, Y);
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Natural (Pos), Row, Col);
      Editor.Executor.Selection_Commands.Execute_Select_Word_At (S, Row, Col);
      New_Caret := Safe_Caret (S);
   end Select_Word_At_Point;
   procedure Select_Line_At_Point
     (S         : in out Editor.State.State_Type;
      X         : Natural;
      Y         : Natural;
      New_Caret : out Cursor_Index)
   is
      Pos : constant Cursor_Index := Index_For_Point (S, X, Y);
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Natural (Pos), Row, Col);
      Editor.Executor.Selection_Commands.Execute_Select_Line_At (S, Row);
      New_Caret := Safe_Caret (S);
   end Select_Line_At_Point;
   procedure Drag_To_Point
     (S         : in out Editor.State.State_Type;
      X         : Natural;
      Y         : Natural;
      New_Caret : out Cursor_Index) is
      Pos : constant Cursor_Index := Index_For_Point (S, X, Y);
   begin
      if S.Carets.Length = 0 then
         S.Carets.Append (Caret_State'(
            Pos => Pos,
            Anchor => Pos,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      else
         declare
            C : Caret_State := S.Carets (Primary_Caret_Index (S));
         begin
            C.Pos := Pos;
            S.Carets.Replace_Element (Primary_Caret_Index (S), C);
         end;
      end if;
      New_Caret := Pos;
   end Drag_To_Point;
   function Preferred_Column_For_Caret
     (S : Editor.State.State_Type;
      C : Cursor_Index) return Natural is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Natural (C), Row, Col);
      return Col;
   end Preferred_Column_For_Caret;

   procedure Move_All_Carets_Vertically
     (S          : in out Editor.State.State_Type;
      Delta_Rows : Integer;
      New_Caret  : out Cursor_Index)
   is
      New_Carets : Cursors_Vector.Vector;
      Row        : Natural := 0;
      Col        : Natural := 0;
      P          : Cursor_Index;
   begin
      for C of S.Carets loop
         Line_Column_For_Index (S, Natural (C.Pos), Row, Col);

         P :=
           Vertical_Target
             (S                => S,
              Old_Caret        => C.Pos,
              Delta_Rows       => Delta_Rows,
              Preferred_Column => Col);

         New_Carets.Append (Caret_State'(
            Pos => P,
            Anchor => P,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      end loop;

      S.Carets := New_Carets;
      Normalize_Carets (S);
      New_Caret := Safe_Caret (S);
   end Move_All_Carets_Vertically;
   procedure Move_All_Carets_By_Word
     (S         : in out Editor.State.State_Type;
      Move_Left : Boolean;
      New_Caret : out Cursor_Index)
   is
      New_Carets : Cursors_Vector.Vector;
      P          : Cursor_Index;
   begin
      for C of S.Carets loop
         if Move_Left then
            P := Cursor_Index (Previous_Word_Start (S, Natural (C.Pos)));
         else
            P := Cursor_Index (Next_Word_End (S, Natural (C.Pos)));
         end if;

         New_Carets.Append (Caret_State'(
            Pos => P,
            Anchor => P,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      end loop;

      S.Carets := New_Carets;
      Normalize_Carets (S);
      New_Caret := Safe_Caret (S);
   end Move_All_Carets_By_Word;
   procedure Move_All_Carets_To_Line_Boundary
     (S          : in out Editor.State.State_Type;
      To_Home    : Boolean;
      New_Caret  : out Cursor_Index)
   is
      New_Carets : Cursors_Vector.Vector;
      Row        : Natural := 0;
      Col        : Natural := 0;
      Len        : Natural := 0;
      P          : Cursor_Index;
   begin
      for C of S.Carets loop
         Line_Column_For_Index (S, Natural (C.Pos), Row, Col);

         if To_Home then
            P := Cursor_Index (Index_For_Line_Column (S, Row, 0));
         else
            Len := Line_Length (S, Row);
            P := Cursor_Index (Index_For_Line_Column (S, Row, Len));
         end if;

         New_Carets.Append (Caret_State'(
            Pos => P,
            Anchor => P,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      end loop;

      S.Carets := New_Carets;
      Normalize_Carets (S);
      New_Caret := Safe_Caret (S);
   end Move_All_Carets_To_Line_Boundary;
   procedure Move_All_Carets_By_Page
     (S          : in out Editor.State.State_Type;
      Delta_Rows : Integer;
      New_Caret  : out Cursor_Index)
   is
      New_Carets : Cursors_Vector.Vector;
      Row        : Natural := 0;
      Col        : Natural := 0;
      P          : Cursor_Index;
   begin
      for C of S.Carets loop
         Line_Column_For_Index (S, Natural (C.Pos), Row, Col);

         P :=
           Vertical_Target
             (S                => S,
              Old_Caret        => C.Pos,
              Delta_Rows       => Delta_Rows,
              Preferred_Column => Col);

         New_Carets.Append (Caret_State'(
            Pos => P,
            Anchor => P,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0
         ));
      end loop;

      S.Carets := New_Carets;
      Normalize_Carets (S);
      New_Caret := Safe_Caret (S);
   end Move_All_Carets_By_Page;

   procedure Reveal_Search_Match
     (S : in out Editor.State.State_Type)
   is
      Row                : Natural := 0;
      Col                : Natural := 0;
      Viewport_Rows      : Natural := 1;
      Desired            : Natural := 0;
      Visible_Target_Row : Natural := 0;
      Visible_Found      : Boolean := False;
      Visible_Count      : Natural := 1;
      Layout             : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      if not Editor.Search.Has_Match (S.Active_Find_Match) then
         return;
      end if;

      Editor.State.Row_Col_For_Index
        (S, S.Active_Find_Match.Start_Index, Row, Col);
      pragma Unreferenced (Col);

      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Row);
      Visible_Target_Row := Editor.Folding.Document_Row_To_Visible_Row
        (S.Folding, Row, Visible_Found);
      if not Visible_Found then
         Visible_Target_Row := Row;
      end if;

      Viewport_Rows := Natural'Max
        (1,
         Editor.Layout.Visible_Row_Count
           (Layout, Editor.View.Viewport_Height));
      Visible_Count := Natural'Max
        (1,
         Editor.Folding.Visible_Row_Count
           (S.Folding, Editor.State.Line_Count (S)));

      if Visible_Target_Row > Viewport_Rows / 2 then
         Desired := Visible_Target_Row - Viewport_Rows / 2;
      else
         Desired := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Visible_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired);
      Editor.View.Clear_User_Scroll_Override;
   end Reveal_Search_Match;
   ------------------------------------------------------------------------
   -- Main executor
   ------------------------------------------------------------------------
   procedure Execute_No_Log_With_Status
     (S : in out Editor.State.State_Type;
      Cmd : Command;
      Line_Status : out Editor.Executor_Edit_Status.Line_Edit_Status)
   is
      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;

      function Command_Defers_Initial_Buffer_Materialization return Boolean is
      begin
         case Cmd.Kind is
            when File_Tree_Open_Selected =>
               return True;
            when others =>
               return False;
         end case;
      end Command_Defers_Initial_Buffer_Materialization;
   begin
      if not Editor.Buffers.Global_Registry_Current_For (S)
        and then not
          (Current_State_Is_Disposable_Initial_Untitled
           and then Command_Defers_Initial_Buffer_Materialization)
      then
         Editor.Buffers.Ensure_Global_Registry (S);
      end if;

      declare
         Before            : constant Editor.State.State_Type := S;
      Old_Len              : constant Natural := Buffer_Length (S);
      Old_Caret            : constant Cursor_Index := Safe_Caret (S);
      New_Caret            : Cursor_Index := Old_Caret;
      New_Preferred_Column : Natural := S.Preferred_Column;

      Had_Selection   : constant Boolean := Has_Primary_Selection (S);
      Sel_Start       : constant Cursor_Index := Safe_Anchor (S);
      Sel_End         : constant Cursor_Index := Safe_Caret (S);
         Forward_Cmd     : Command;
         Should_Log_Edit : Boolean := False;
      begin
         Line_Status := Editor.Executor.Edits.Line_Edit_None;

      case Cmd.Kind is

         when Start_Rectangle_Selection
            | Start_Rectangle_At_Caret
            | Drag_Rectangle_To_Point
            | Clear_Rectangle_Selection =>
            Editor.Executor.Rectangular.Execute
              (S                    => S,
               Cmd                  => Cmd,
               New_Caret            => New_Caret,
               New_Preferred_Column => New_Preferred_Column);

         when Undo | Redo =>
            Editor.Executor.History.Execute (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Break_Group =>
            Editor.Executor.History.Break_Group;
            Editor.Invariants.Check (S);
            return;

         when Run_Project
            | Run_Tests
            | Terminal_Toggle
            | Terminal_Show
            | Terminal_Hide
            | Terminal_Focus
            | Terminal_Clear
            | Terminal_Clear_Output
            | Terminal_Select_Next_Task
            | Terminal_Select_Previous_Task
            | Terminal_Run_Selected_Task
            | Terminal_Rerun_Last_Task
            | Terminal_Cancel_Task =>
            Editor.Invariants.Check (S);
            return;

         when Copy_Selection | Cut_Selection | Paste_Clipboard | Clear_Clipboard =>
            Editor.Executor.Clipboard.Execute (S, Cmd);
            Editor.Invariants.Check (S);
            return;


         when Open_Goto_Line
            | Prefill_Goto_Line_Current
            | Toggle_Goto_Line
            | Close_Goto_Line
            | Accept_Goto_Line
            | Goto_Line_Query_Set
            | Goto_Line_Query_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Command_Surface_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Active_Find_Show
            | Active_Find_Hide
            | Active_Find_Toggle
            | Active_Find_Query_Set
            | Active_Find_Query_Clear
            | Active_Find_Case_Toggle
            | Active_Find_Case_Clear
            | Active_Find_Whole_Word_Toggle
            | Active_Find_Whole_Word_Clear
            | Active_Find_From_Selection
            | Active_Find_From_Active_Word
            | Active_Find_Next
            | Active_Find_Previous
            | Active_Find_First
            | Active_Find_Last
            | Active_Find_Reveal_Current
            | Active_Replace_Show
            | Active_Replace_Hide
            | Active_Replace_Toggle
            | Active_Replace_Text_Set
            | Active_Replace_Text_Clear
            | Active_Replace_Current
            | Active_Replace_All =>
            Editor.Executor.Find_Replace_Commands.Execute_Find_Replace_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Navigation_Back
            | Navigation_Forward
            | Navigation_History_Clear =>
            Editor.Executor.Navigation_Commands.Execute_Navigation_History_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Previous_Recent_Buffer
            | Next_Recent_Buffer =>
            Editor.Executor.Buffer_Navigation_Commands
              .Execute_Buffer_Navigation_Kind (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Goto_Line_Insert_Text
            | Goto_Line_Backspace
            | Goto_Line_Delete_Forward
            | Goto_Line_Move_Cursor_Left
            | Goto_Line_Move_Cursor_Right
            | Open_Quick_Open
            | Close_Quick_Open
            | Toggle_Quick_Open
            | Accept_Quick_Open
            | Quick_Open_Next_Result
            | Quick_Open_Previous_Result
            | Quick_Open_Query_Set
            | Quick_Open_Query_Clear
            | Quick_Open_Kind_Next
            | Quick_Open_Kind_Previous
            | Quick_Open_Kind_Clear
            | Quick_Open_Scope_Set
            | Quick_Open_Scope_Clear
            | Quick_Open_Scope_From_Selected
            | Quick_Open_Scope_Parent
            | Quick_Open_Reveal_Active
            | Quick_Open_Scope_Active_Directory
            | Quick_Open_Create_From_Query
            | Quick_Open_Create_With_Parents_From_Query
            | Quick_Open_Priority_Toggle
            | Quick_Open_Priority_Clear
            | Quick_Open_Insert_Text
            | Quick_Open_Backspace
            | Quick_Open_Delete_Forward
            | Quick_Open_Move_Cursor_Left
            | Quick_Open_Move_Cursor_Right =>
            Editor.Executor.Command_Surface_Commands.Execute_Command_Surface_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Open_Buffer_Switcher
            | Close_Buffer_Switcher
            | Accept_Buffer_Switcher
            | Buffer_Switcher_Next_Result
            | Buffer_Switcher_Previous_Result
            | Buffer_Switcher_Insert_Text
            | Buffer_Switcher_Backspace
            | Buffer_Switcher_Delete_Forward =>
            Editor.Executor.Buffer_Switcher_Surface_Commands
              .Execute_Buffer_Switcher_Surface_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Move_Cursor_Left =>
            Editor.Buffer_Switcher.Move_Cursor_Left (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Move_Cursor_Right =>
            Editor.Buffer_Switcher.Move_Cursor_Right (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Filter_Clear
            | Buffer_Switcher_Filter_Pinned
            | Buffer_Switcher_Filter_Group
            | Buffer_Switcher_Filter_Label
            | Buffer_Switcher_Filter_Noted
            | Buffer_Switcher_Sort_Default
            | Buffer_Switcher_Sort_Recent
            | Buffer_Switcher_Sort_Name
            | Buffer_Switcher_Sort_Pinned
            | Buffer_Switcher_Sort_Group
            | Buffer_Switcher_Sort_Label
            | Buffer_Switcher_Sort_Next
            | Buffer_Switcher_Sort_Previous =>
            Editor.Executor.Buffer_Switcher_Surface_Commands
              .Execute_Buffer_Switcher_Surface_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Selected_Close
            | Buffer_Switcher_Selected_Pin
            | Buffer_Switcher_Selected_Unpin
            | Buffer_Switcher_Selected_Toggle_Pin
            | Buffer_Switcher_Selected_Group_Assign
            | Buffer_Switcher_Selected_Group_Clear
            | Buffer_Switcher_Selected_Label_Set
            | Buffer_Switcher_Selected_Label_Clear
            | Buffer_Switcher_Selected_Note_Set
            | Buffer_Switcher_Selected_Note_Clear =>
            Editor.Executor.Buffer_Switcher_Selected_Commands
              .Execute_Buffer_Switcher_Selected_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Preview_Toggle
            | Buffer_Switcher_Preview_Show
            | Buffer_Switcher_Preview_Hide
            | Buffer_Switcher_Preview_Next_Line
            | Buffer_Switcher_Preview_Previous_Line
            | Buffer_Switcher_Preview_Center_Cursor =>
            Editor.Executor.Buffer_Switcher_Preview_Commands
              .Execute_Buffer_Switcher_Preview_Kind (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Mark_Toggle
            | Buffer_Switcher_Mark_Set
            | Buffer_Switcher_Mark_Clear
            | Buffer_Switcher_Mark_Clear_All
            | Buffer_Switcher_Mark_Invert_Visible
            | Buffer_Switcher_Mark_Visible
            | Buffer_Switcher_Mark_Clear_Visible
            | Buffer_Switcher_Mark_Pinned
            | Buffer_Switcher_Mark_Group
            | Buffer_Switcher_Mark_Label
            | Buffer_Switcher_Mark_Noted
            | Buffer_Switcher_Mark_Close_Marked
            | Buffer_Switcher_Mark_Confirm
            | Buffer_Switcher_Mark_Cancel
            | Buffer_Switcher_Mark_Pin_Marked
            | Buffer_Switcher_Mark_Unpin_Marked
            | Buffer_Switcher_Mark_Clear_Metadata
            | Buffer_Switcher_Mark_Group_Assign
            | Buffer_Switcher_Mark_Group_Clear
            | Buffer_Switcher_Mark_Label_Set
            | Buffer_Switcher_Mark_Label_Clear
            | Buffer_Switcher_Mark_Note_Set
            | Buffer_Switcher_Mark_Note_Clear
            | Buffer_Switcher_Mark_Review_Toggle
            | Buffer_Switcher_Mark_Review_Show
            | Buffer_Switcher_Mark_Review_Hide =>
            Editor.Executor.Buffer_Switcher_Mark_Commands
              .Execute_Buffer_Switcher_Mark_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Pending_Mark_Review_Toggle
            | Buffer_Switcher_Pending_Mark_Review_Show
            | Buffer_Switcher_Pending_Mark_Review_Hide
            | Buffer_Switcher_Pending_Mark_Next
            | Buffer_Switcher_Pending_Mark_Previous
            | Buffer_Switcher_Pending_Mark_Summary
            | Buffer_Switcher_Pending_Mark_Remove_Selected
            | Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Buffer_Switcher_Pending_Mark_Pruned_Next
            | Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
            | Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Buffer_Switcher_Pending_Mark_Dirty_Next
            | Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Kind (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Mark_Next
            | Buffer_Switcher_Mark_Previous
            | Buffer_Switcher_Mark_Summary =>
            Editor.Executor.Buffer_Switcher_Mark_Commands
              .Execute_Buffer_Switcher_Mark_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Active_Find_Input_Insert_Text
            | Active_Find_Input_Backspace
            | Active_Find_Input_Delete_Forward
            | Active_Find_Input_Move_Cursor_Left
            | Active_Find_Input_Move_Cursor_Right =>
            Editor.Executor.Find_Replace_Commands.Execute_Find_Replace_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Toggle_Feature_Panel
            | Show_Feature_Panel
            | Hide_Feature_Panel
            | Focus_Feature_Panel
            | Clear_Feature_Panel
            | Feature_Panel_Select_Next
            | Feature_Panel_Select_Previous
            | Feature_Panel_Open_Selected =>
            Editor.Executor.Feature_Panel_Commands.Execute_Feature_Panel_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Goto_Declaration
            | Goto_Body
            | Goto_Spec
            | Find_References
            | Workspace_Symbols
            | Show_Hover
            | Show_Completions
            | Semantic_Completion_Select_Next
            | Semantic_Completion_Select_Previous
            | Semantic_Completion_Accept
            | Semantic_Popup_Dismiss
            | Rename_Symbol_Preview
            | Rename_Symbol_Apply
            | Semantic_Refresh_Buffer
            | Semantic_Refresh_Project_Index
            | Language_Index_Clear
            | Language_Index_Status =>
            Editor.Executor.Semantic_Commands.Execute_Semantic_Kind (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Refresh_Outline
            | Refresh_Outline_Project_Index
            | Clear_Outline
            | Show_Outline
            | Focus_Outline
            | Open_Selected_Outline_Item
            | Select_Current_Outline_Symbol
            | Reveal_Current_Outline_Symbol
            | Next_Outline_Symbol
            | Previous_Outline_Symbol
            | Select_Next_Outline_Item
            | Select_Previous_Outline_Item
            | Focus_Outline_Filter
            | Filter_Outline
            | Clear_Outline_Filter
            | Toggle_Outline_Filter
            | Outline_Filter_History_Previous
            | Outline_Filter_History_Next
            | Clear_Outline_Filter_History =>
            Editor.Executor.Outline_Commands.Execute_Outline_Kind (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Show_Messages
            | Clear_Messages
            | Clear_Selected_Message
            | Copy_Selected_Message_Text
            | Clear_Info_Messages
            | Clear_Warning_Messages
            | Clear_Error_Messages
            | Toggle_Message_Info
            | Toggle_Message_Warnings
            | Toggle_Message_Errors
            | Show_All_Messages
            | Clear_Message_Filter =>
            Editor.Executor.Message_Commands.Execute_Message_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Save_Settings
            | Reload_Settings
            | Reset_Settings_To_Defaults
            | Save_Keybindings
            | Reload_Keybindings
            | Validate_Keybindings =>
            Editor.Executor.Configuration_Commands.Execute_Configuration_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Save_Workspace_State
            | Restore_Workspace_State
            | Clear_Workspace_State =>
            Editor.Executor.Workspace_Commands.Execute_Workspace_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Open_File =>
            Editor.Executor.File_Open_Commands.Execute_File_Open_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Open_Project
            | Switch_Project
            | Show_Recent_Projects
            | Open_Selected_Recent_Project
            | Clear_Recent_Projects
            | Remove_Selected_Recent_Project
            | Remove_Missing_Recent_Projects
            | Select_Next_Recent_Project
            | Select_Previous_Recent_Project
            | Close_Project
            | Clear_Project =>
            Editor.Executor.Project_Lifecycle_Commands
              .Execute_Project_Lifecycle_Kind (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Refresh_File_Tree
            | Refresh_Project_Files
            | Project_Files_Summary
            | Reveal_Active_File_In_Tree =>
            Editor.Executor.File_Tree_Commands.Execute_File_Tree_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Save_File
            | Save_File_As
            | Save_All
            | Reload_Active_Buffer
            | Revert_Active_Buffer
            | Rename_Buffer_File
            | Delete_Buffer_File
            | Copy_Buffer_File
            | Move_Buffer_File
            | File_Conflict_Keep_Buffer
            | File_Conflict_Reload_From_Disk
            | File_Conflict_Overwrite_Disk
            | File_Conflict_Cancel =>
            Editor.Executor.File_Lifecycle_Commands.Execute_Lifecycle_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when New_Buffer
            | Reopen_Closed_Buffer =>
            Editor.Executor.File_Open_Commands.Execute_File_Open_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Close_Buffer
            | Close_Other_Buffers
            | Close_All_Clean_Buffers
            | Discard_Pending_Transition =>
            Editor.Executor.Buffer_Close_Commands.Execute_Buffer_Close_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Cancel_Pending_Transition
            | Retry_Pending_Transition =>
            Editor.Executor.File_Lifecycle_Commands.Execute_Lifecycle_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Pin_Buffer
            | Unpin_Buffer
            | Toggle_Buffer_Pin
            | Set_Buffer_Label
            | Edit_Buffer_Label
            | Clear_Buffer_Label
            | Show_Buffer_Label
            | Set_Buffer_Note
            | Edit_Buffer_Note
            | Clear_Buffer_Note
            | Show_Buffer_Note
            | Assign_Buffer_Group
            | Clear_Buffer_Group
            | Switch_Buffer_Group
            | Show_All_Buffer_Groups =>
            Editor.Executor.Buffer_Metadata_Commands
              .Execute_Buffer_Metadata_Kind (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Next_Buffer_Group
            | Previous_Buffer_Group
            | Next_Buffer
            | Previous_Buffer
            | Switch_Buffer =>
            Editor.Executor.Buffer_Navigation_Commands
              .Execute_Buffer_Navigation_Kind (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Toggle_Theme
            | Toggle_Minimap
            | Toggle_Scrollbars
            | Toggle_Format_On_Save
            | Toggle_Line_Number_Mode
            | Set_Theme_Light
            | Set_Theme_Dark
            | Toggle_Cursor_Blink =>
            Editor.Executor.Editor_Preferences_Commands
              .Execute_Editor_Preferences_Kind (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Toggle_Problems_Panel
            | Focus_Editor_Text
            | Focus_Search_Results
            | Focus_Problems
            | Toggle_Bottom_Panel_Focus =>
            Editor.Executor.Panel_Focus_Commands.Execute_Panel_Focus_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Next_Diagnostic
            | Previous_Diagnostic =>
            Editor.Executor.Diagnostics_Commands.Execute_Diagnostics_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Toggle_Bookmark
            | Next_Bookmark
            | Previous_Bookmark
            | Clear_Bookmarks
            | Clear_All_Bookmarks
            | Bookmark_Toggle_Current_Location
            | Bookmark_Clear_All
            | Bookmark_Next
            | Bookmark_Previous
            | Bookmark_Goto_Next
            | Bookmark_Goto_Previous
            | Bookmark_Open_Selected
            | Bookmark_Reveal_Current
            | Bookmark_Remove_Selected
            | Bookmark_Show
            | Bookmark_Hide
            | Bookmark_Toggle =>
            Editor.Executor.Bookmark_Commands.Execute_Bookmark_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Run_Project_Search
            | Rerun_Project_Search
            | Open_Project_Search_Bar
            | Toggle_Project_Search_Bar
            | Close_Project_Search_Bar
            | Run_Project_Search_From_Bar
            | Project_Search_Bar_Insert_Text
            | Project_Search_Bar_Backspace
            | Project_Search_Bar_Delete_Forward
            | Project_Search_Bar_Move_Cursor_Left
            | Project_Search_Bar_Move_Cursor_Right
            | Project_Search_From_Selection
            | Project_Search_From_Active_Word
            | Project_Search_Active_Directory
            | Clear_Project_Search
            | Open_Selected_Project_Search_Result
            | Move_Project_Search_Selection_Up
            | Move_Project_Search_Selection_Down
            | Next_Project_Search_Result
            | Previous_Project_Search_Result
            | First_Project_Search_Result
            | Last_Project_Search_Result
            | Reveal_Active_Project_Search_Result
            | Project_Search_Scope_Selected_Directory
            | Project_Search_Kind_Next
            | Project_Search_Kind_Previous
            | Project_Search_Kind_Clear
            | Project_Search_Scope_Set
            | Project_Search_Scope_Clear
            | Project_Search_Case_Toggle
            | Project_Search_Case_Clear
            | Project_Search_Whole_Word_Toggle
            | Project_Search_Whole_Word_Clear
            | Project_Search_Regex_Toggle
            | Project_Search_Regex_Clear
            | Project_Search_Include_Filter_Set
            | Project_Search_Exclude_Filter_Set
            | Project_Search_Include_Filter_Clear
            | Project_Search_Exclude_Filter_Clear
            | Project_Search_Replace_Preview
            | Project_Search_Replace_Toggle_Selected
            | Project_Search_Replace_Include_Selected
            | Project_Search_Replace_Exclude_Selected
            | Project_Search_Replace_Include_File
            | Project_Search_Replace_Exclude_File
            | Project_Search_Replace_Include_All
            | Project_Search_Replace_Exclude_All
            | Project_Search_Replace_Selected
            | Project_Search_Replace_All_Included
            | Project_Search_Replace_Clear_Preview
            | Show_Search_Results_Panel =>
            Editor.Executor.Search_Commands.Execute_Project_Search_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Problems_Move_Up
            | Problems_Move_Down
            | Problems_Page_Up
            | Problems_Page_Down
            | Problems_Open_Selected
            | Problems_Filter_All
            | Problems_Filter_Errors
            | Problems_Filter_Warnings
            | Problems_Filter_Info
            | Problems_Filter_Hints
            | Problems_Sort_By_Location
            | Problems_Sort_By_Severity
            | Problems_Sort_By_Source
            | Problems_Group_By_Severity
            | Problems_Group_By_Source
            | Problems_Focus_Editor =>
            Editor.Executor.Diagnostics_Commands.Execute_Diagnostics_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Focus_File_Tree
            | File_Tree_Move_Up
            | File_Tree_Move_Down
            | File_Tree_Page_Up
            | File_Tree_Page_Down
            | File_Tree_Open_Selected
            | File_Tree_Create_File
            | File_Tree_Create_Directory
            | File_Tree_Rename_Selected
            | File_Tree_Delete_Selected
            | File_Tree_Expand_Selected
            | File_Tree_Collapse_Selected
            | File_Tree_Toggle_Selected
            | File_Tree_Collapse_All
            | File_Tree_Expand_To_Active_File =>
            Editor.Executor.File_Tree_Commands.Execute_File_Tree_Kind
              (S, Cmd);
            Editor.Invariants.Check (S);
            return;

         when Search_Results_Move_Up
            | Search_Results_Move_Down
            | Search_Results_Page_Up
            | Search_Results_Page_Down
            | Search_Results_Open_Selected
            | Search_Results_Search_Active_Buffer
            | Search_Results_Focus_Query
            | Search_Results_Repeat_Active_Buffer
            | Search_Results_Query_History_Previous
            | Search_Results_Query_History_Next
            | Search_Results_Toggle_Case_Sensitive
            | Show_Search_Results_Feature
            | Clear_Search_Results_Feature
            | Search_Results_Close_Or_Hide =>
            Editor.Executor.Search_Results_Commands
              .Execute_Search_Results_Kind (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Diagnostics_Show
            | Diagnostics_Clear
            | Diagnostics_Toggle_Info
            | Diagnostics_Toggle_Warnings
            | Diagnostics_Toggle_Errors
            | Diagnostics_Show_All
            | Diagnostics_Clear_Filter
            | Diagnostics_Filter_Errors
            | Diagnostics_Filter_Warnings
            | Diagnostics_Filter_Info_Notes
            | Diagnostics_Filter_Source
            | Diagnostics_Filter_Build
            | Diagnostics_Clear_Build
            | Diagnostics_Open_Selected
            | Diagnostic_Open_Source
            | Diagnostic_Suppress_Selected
            | Diagnostic_Show_Suppressed
            | Diagnostic_Restore_Last_Suppressed
            | Diagnostic_Restore_Selected_Suppressed
            | Diagnostic_Clear_Suppressed
            | Diagnostic_Apply_Quick_Fix
            | Diagnostics_Execute_Selected_Action
            | Diagnostics_Select_Next
            | Diagnostics_Select_Previous
            | Diagnostics_Clear_Selected
            | Diagnostics_Copy_Selected_Text
            | Diagnostics_Clear_Info
            | Diagnostics_Clear_Warnings
            | Diagnostics_Clear_Errors
            | Diagnostics_Toggle_Editor_Source
            | Diagnostics_Toggle_File_Source
            | Diagnostics_Toggle_Project_Source
            | Diagnostics_Toggle_External_Source
            | Diagnostics_Toggle_Unknown_Source =>
            Editor.Executor.Diagnostics_Commands.Execute_Diagnostics_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Move_Left
            | Move_Right
            | Move_Up
            | Move_Down
            | Move_Home
            | Move_End
            | Move_Line_Start
            | Move_Line_End
            | Move_Document_Start
            | Move_Document_End
            | Move_Page_Up
            | Move_Page_Down
            | Move_Word_Left
            | Move_Word_Right
            | Select_Word_Left
            | Select_Word_Right
            | Select_Line_Start
            | Select_Line_End
            | Select_Document_Start
            | Select_Document_End
            | Select_Page_Up
            | Select_Page_Down
            | Select_Word
            | Select_Line
            | Extend_Selection_Line_Up
            | Extend_Selection_Line_Down
            | Move_To_Point
            | Drag_To_Point
            | Select_Word_At_Point
            | Select_Line_At_Point =>
            Editor.Executor.Navigation.Execute
               (S,
                  Cmd,
                  Had_Selection,
                  Sel_Start,
                  Old_Caret,
                  New_Caret,
                  New_Preferred_Column);


         when Add_Caret_At_Point
            | Clear_Extra_Carets =>
            Editor.Executor.Structural.Execute (S, Cmd);
            New_Caret := Safe_Caret (S);
            New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);

         when Insert_Text_Input
            | Delete_Char
            | Forward_Delete_Char
            | Delete_Current_Line
            | Duplicate_Current_Line
            | Move_Current_Line_Up
            | Move_Current_Line_Down
            | Indent_Current_Line
            | Outdent_Current_Line
            | Comment_Current_Line
            | Uncomment_Current_Line
            | Toggle_Current_Line_Comment
            | Join_Current_Line_With_Next
            | Split_Current_Line_At_Caret
            | Trim_Trailing_Whitespace
            | Delete_Previous_Character
            | Delete_Next_Character
            | Delete_Previous_Word
            | Delete_Next_Word
            | Delete_Selection_Range
            | Paste_Text =>
            Editor.Executor.Edits.Execute
              (S               => S,
               Cmd             => Cmd,
               Had_Selection   => Had_Selection,
               Sel_Start       => Sel_Start,
               Sel_End         => Sel_End,
               Old_Caret       => Old_Caret,
               New_Caret       => New_Caret,
               Forward_Cmd     => Forward_Cmd,
               Should_Log_Edit => Should_Log_Edit,
               Line_Status     => Line_Status);

            --  line-edit reliability: line commands can move the
            --  primary caret to a different logical line and clamp its column
            --  to that destination line.  Keep the preferred column aligned
            --  with the actual post-command caret so later vertical movement
            --  does not resurrect a stale column from the pre-edit line.
            case Cmd.Kind is
               when Insert_Text_Input
                  | Delete_Current_Line
                  | Duplicate_Current_Line
                  | Move_Current_Line_Up
                  | Move_Current_Line_Down
                  | Indent_Current_Line
                  | Outdent_Current_Line
                  | Comment_Current_Line
                  | Uncomment_Current_Line
                  | Toggle_Current_Line_Comment
                  | Join_Current_Line_With_Next
                  | Split_Current_Line_At_Caret
                  | Trim_Trailing_Whitespace
                  | Delete_Previous_Character
                  | Delete_Next_Character
                  | Delete_Previous_Word
                  | Delete_Next_Word
                  | Delete_Selection_Range =>
                  New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);
               when others =>
                  null;
            end case;

         when Open_Command_Palette =>
            Editor.Executor.Command_Surface_Commands.Execute_Command_Surface_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Palette_Show_Command_Help =>
            Editor.Executor.Command_Surface_Commands.Execute_Command_Surface_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            Execute_Command
              (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
            Editor.Invariants.Check (S);
            return;

         when Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            Execute_Command
              (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary);
            Editor.Invariants.Check (S);
            return;

         when Startup_Show_Summary
            | Configuration_Recover_Show
            | Configuration_Audit
            | Configuration_Reset_Settings
            | Configuration_Reset_Keybindings
            | Configuration_Reset_Workspace
            | Configuration_Reset_Recent_Projects
            | Configuration_Reset_All
            | Configuration_Reset_All_Confirm
            | Configuration_Reset_All_Cancel
            | Configuration_Save_Clean_Settings
            | Configuration_Save_Clean_Keybindings
            | Configuration_Save_Clean_Workspace
            | Configuration_Save_Clean_Recent_Projects =>
            Editor.Executor.Configuration_Commands.Execute_Configuration_Kind
              (S, Cmd.Kind);
            Editor.Invariants.Check (S);
            return;

         when Pointer_Hover
            | Keybindings_Show .. Keybindings_Cancel_Capture
            | Build_Ui_Toggle .. Build_Cancel
            | Apply_Replace_Batch
            | Palette_Accept
            | Palette_Cancel =>
            null;
      end case;

      declare
         Len2 : constant Natural := Buffer_Length (S);
      begin
         if New_Caret > Cursor_Index (Len2 + 1) then
            New_Caret := Cursor_Index (Len2 + 1);
         end if;
      end;

      S.Preferred_Column := New_Preferred_Column;

      if Should_Log_Edit then
         Clear_Restore_Feedback_Current (S);

         --  a command path may report an edit attempt even when
         --  the resulting text is unchanged, for example replacing a selected
         --  span with identical text.  Such no-op text changes must not mark
         --  the buffer dirty, must not create an undo entry, and must not
         --  clear redo history after an undo.  Caret/selection changes from
         --  the command are still synchronized to the active buffer record.
         if Text_Buffer.UTF8_Text (Before.Buffer) /=
            Text_Buffer.UTF8_Text (S.Buffer)
         then
            S.File_Info.Dirty := True;

            --  completeness: ordinary text edits stale
            --  parser-owned language-analysis state just like reload/revert
            --  lifecycle operations.  Drop current path/token index rows and
            --  semantic maps before recording the edit so Outline navigation,
            --  semantic colouring, and project-index lookups cannot reuse the
            --  pre-edit Ada analysis for the new buffer revision.
            declare
               Source_Path : constant String :=
                 (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
            begin
               if Source_Path'Length > 0 then
                  Editor.Ada_Project_Index.Invalidate_Path
                    (S.Language_Index, Source_Path);
                  Editor.Ada_Language_Service.Invalidate_Path
                    (S.Language_Service, Source_Path);
               end if;

               if S.Active_Buffer_Token /= 0 then
                  Editor.Ada_Project_Index.Invalidate_Buffer
                    (S.Language_Index, S.Active_Buffer_Token);
                  Editor.Ada_Language_Service.Invalidate_Buffer
                    (S.Language_Service, S.Active_Buffer_Token);
               end if;

               Editor.Syntax_Semantics.Clear (S.Syntax_Symbols);
               Editor.Ada_Language_Model.Clear (S.Syntax_Analysis);
               S.Syntax_Symbols_Revision := Natural'Last;
               S.Syntax_Symbols_Buffer_Token := 0;
            end;

            Editor.Executor.History.Log_Edit (Before, S, Forward_Cmd);
         else
            --  Rebuild_After_Buffer_Change may already have recomputed dirty
            --  observations for the attempted edit.  For an unchanged text
            --  result, restore the dirty observation to what the current
            --  baseline actually says, without creating a new baseline.
            if Editor.Dirty_Lines.Has_Baseline (S.Dirty_Lines) then
               Editor.State.Refresh_Dirty_Lines (S);
               Editor.State.Set_Dirty
                 (S, Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) > 0);
            else
               Editor.State.Set_Dirty (S, Before.File_Info.Dirty);
            end if;
         end if;

         --  ordinary text input is a real file-backed lifecycle
         --  mutation.  Keep the active registry entry synchronized
         --  immediately so open-buffer rows, Status Bar projections, buffer
         --  switching, undo/redo stacks, and subsequent command availability
         --  all observe the dirty active buffer without waiting for the next
         --  lifecycle command.  Strip_Global_UI_State keeps global chrome
         --  such as File Tree, Messages, panels, and overlays out of the
         --  per-buffer copy.
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      Editor.Invariants.Check (S);
      end;
   end Execute_No_Log_With_Status;
   procedure Execute_No_Log
     (S : in out Editor.State.State_Type;
      Cmd : Command)
   is
      Ignored_Line_Status : Editor.Executor.Edits.Line_Edit_Status;
   begin
      Execute_No_Log_With_Status (S, Cmd, Ignored_Line_Status);
   end Execute_No_Log;

end Editor.Executor;
