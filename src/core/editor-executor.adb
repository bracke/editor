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
with Editor.Executor_Edit_Status;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Buffer_Metadata_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Overlay_Commands;
with Editor.Executor.Semantic_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Semantic_Symbol_Selection;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Command_Kind_Routing;
with Editor.Executor.Command_Result_Commands;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Workspace_Commands;
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
use type Editor.File_Tree.File_Tree_Node_Id;
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
   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;
   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;
   procedure Report_Error
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Error;

   function Primary_Cursor_Line_Of_Buffer
     (Id : Editor.Buffers.Buffer_Id) return Natural;
   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type);
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
         Editor.Executor.Semantic_Index_Commands
           .Load_Global_Active_Preserving_Language_Index (S);
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
      then
         return "";
      end if;

      if Editor.File_Tree.File_Node_Count (S.File_Tree) > 0 then
         declare
            Tree_Found : Boolean := False;
            Node_Id    : constant Editor.File_Tree.File_Tree_Node_Id :=
              Editor.File_Tree.Find_By_Path (S.File_Tree, Raw_Path, Tree_Found);
         begin
            if Tree_Found
              and then Node_Id /= Editor.File_Tree.No_File_Tree_Node
            then
               Found := True;
               return Normalize_Project_Path_For_Command
                 (To_String (Editor.File_Tree.Node (S.File_Tree, Node_Id).Relative_Path));
            end if;
         end;
      end if;

      if Editor.Project.Known_File_Count (S.Project) = 0 then
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
   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String
   is
   begin
      return Editor.Executor.Semantic_Symbol_Selection
        .Current_Semantic_Symbol_Name (State);
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

      if Editor.Executor.Command_Kind_Routing.Try_Execute_Non_Edit_Kind
        (S, Cmd)
      then
         return;
      end if;

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

         when Pointer_Hover
            | Keybindings_Show .. Keybindings_Cancel_Capture
            | Build_Ui_Toggle .. Build_Cancel
            | Apply_Replace_Batch
            | Palette_Accept
            | Palette_Cancel =>
            null;
         when others =>
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
