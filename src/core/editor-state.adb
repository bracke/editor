with Editor.Command_Ids; use Editor.Command_Ids;
with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Editor.Cursors; use Editor.Cursors;
with Editor.Render_Cache;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Messages;
with Editor.Project;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Dirty_Lines;
use type Editor.Gutter_Markers.Gutter_Marker_Kind;
with Editor.Search;
with Editor.Input_Field;
with Editor.Quick_Open;
with Editor.Buffer_Switcher;
with Editor.Recent_Buffers;
with Editor.Bookmarks;
with Editor.Go_To_Line;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Guided_Prompts;
with Editor.Search_Results;
with Editor.Problems;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Diagnostics;
with Editor.View;
with Editor.Buffers;
with Editor.Workspace_Persistence;
with Editor.Recent_Projects;
with Editor.Pending_Transitions;
with Editor.Settings;
with Editor.Feature_Panel;
with Editor.Feature_Messages;
with Editor.Feature_Search_Results;
with Editor.Feature_Diagnostics;
with Editor.Feature_Targets;
with Editor.Producer_Contracts;
with Editor.Feature_Panel_Controller;
with Editor.Outline;
with Editor.Keybindings;
with Editor.Keybinding_Config;
with Editor.Startup_Readiness;
with Editor.Navigation_History;
with Editor.Build_UI;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Terminal_Tasks;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;
with Editor.Ada_Project_Index;
with Editor.Ada_Language_Service;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Syntax;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.State is

   use Cursors_Vector;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Recent_Projects.Recent_Project_Status;
   use type Editor.Settings.Settings_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Feature_Panel.Feature_Id;

   Next_Registry_Token : Natural := 1;
   Runtime_Keybindings_Initialized : Boolean := False;
   Runtime_Keybinding_Status : Editor.Keybinding_Config.Keybinding_Config_Status :=
     Editor.Keybinding_Config.Keybinding_Config_Not_Found;

   function Allocate_Registry_Token return Natural is
      Result : constant Natural := Next_Registry_Token;
   begin
      if Next_Registry_Token = Natural'Last then
         Next_Registry_Token := 1;
      else
         Next_Registry_Token := Next_Registry_Token + 1;
      end if;
      return Result;
   end Allocate_Registry_Token;

   procedure Bump_Buffer_Revision (S : in out State_Type) is
   begin
      if S.Buffer_Lifecycle.Buffer_Revision = Natural'Last then
         S.Buffer_Lifecycle.Buffer_Revision := 1;
      else
         S.Buffer_Lifecycle.Buffer_Revision := S.Buffer_Lifecycle.Buffer_Revision + 1;
      end if;
   end Bump_Buffer_Revision;



   function Current_Message_Time_Ms return Natural
   is
      Now : constant Duration := Editor.View.Current_Time_Seconds;
   begin
      if Now <= 0.0 then
         return 0;
      elsif Now >= Duration (Natural'Last / 1000) then
         return Natural'Last;
      else
         return Natural (Float (Now) * 1000.0);
      end if;
   end Current_Message_Time_Ms;

   function Default_Message_Config return Editor.Messages.Message_Config
   is
   begin
      return (Default_Lifetime_Ms   => 3_000,
              Error_Lifetime_Ms     => 5_000,
              Max_Visible_Messages  => 3,
              Max_Text_Columns      => 96,
              Replace_Same_Category => True);
   end Default_Message_Config;

   procedure Report_Info
     (S    : in out State_Type;
      Text : String)
   is
   begin
      Editor.Messages.Push_Info
        (S.Panel.Messages, Text, Current_Message_Time_Ms, Default_Message_Config);
   end Report_Info;

   function Has_Active_Buffer (S : State_Type) return Boolean is
   begin
      if S.Buffer_Lifecycle.Active_Buffer_Token = 0 then
         return S.Buffer_Lifecycle.Registry_Token = 0
           and then
             (S.Buffer_Lifecycle.Buffer_Revision /= 0
              or else S.Buffer_Lifecycle.File_Info.Has_Path
              or else S.Buffer_Lifecycle.File_Info.Dirty
              or else Current_Text (S) /= "");
      elsif Editor.Buffers.Global_Registry_Current_For (S) then
         return Editor.Buffers.Global_Contains
           (Editor.Buffers.Buffer_Id (S.Buffer_Lifecycle.Active_Buffer_Token));
      else
         return S.Buffer_Lifecycle.Buffer_Revision /= 0
           or else S.Buffer_Lifecycle.File_Info.Has_Path
           or else S.Buffer_Lifecycle.File_Info.Dirty
           or else Current_Text (S) /= "";
      end if;
   end Has_Active_Buffer;

   function Active_Buffer (S : State_Type) return State_Type is
   begin
      return S;
   end Active_Buffer;

   function Current_File (S : State_Type) return File_State is
   begin
      return S.Buffer_Lifecycle.File_Info;
   end Current_File;

   procedure Set_Current_File
     (S    : in out State_Type;
      File : File_State)
   is
   begin
      S.Buffer_Lifecycle.File_Info := File;
   end Set_Current_File;

   function Is_Dirty (S : State_Type) return Boolean is
   begin
      return S.Buffer_Lifecycle.File_Info.Dirty;
   end Is_Dirty;

   procedure Set_Dirty
     (S     : in out State_Type;
      Dirty : Boolean)
   is
   begin
      S.Buffer_Lifecycle.File_Info.Dirty := Dirty;
   end Set_Dirty;

   procedure Initialize (S : out State_Type) is
   begin
      Init (S);
   end Initialize;

   procedure Clear_File_Target_Prompt (S : in out State_Type) is
   begin
      S.Buffer_Lifecycle.File_Target_Prompt_Active := False;
      S.Buffer_Lifecycle.File_Target_Prompt_Command := Editor.Command_Ids.No_Command;
      S.Buffer_Lifecycle.File_Target_Prompt_Label := Null_Unbounded_String;
      Editor.Input_Field.Clear (S.Buffer_Lifecycle.File_Target_Prompt_Input);
   end Clear_File_Target_Prompt;

   procedure Apply_Settings
     (S        : in out State_Type;
      Settings : Editor.Settings.Settings_Model;
      Summary  : out Editor.Settings.Settings_Apply_Summary)
   is
      Normalized : Editor.Settings.Settings_Model := Settings;
   begin
      Editor.Settings.Normalize (Normalized);
      S.Configuration.Settings := Normalized;
      Editor.Settings.Apply (S.Configuration.Settings, Summary);
      Editor.Render_Cache.Invalidate_All;
   end Apply_Settings;

   procedure Apply_Settings
     (S        : in out State_Type;
      Settings : Editor.Settings.Settings_Model)
   is
      Summary : Editor.Settings.Settings_Apply_Summary;
   begin
      Apply_Settings (S, Settings, Summary);
   end Apply_Settings;

   procedure Check_Line_Index (S : State_Type) is
   begin
      pragma Assert
        (Text_Buffer.Validate_Line_Counts (S.Buffer),
         "Rope line metadata is inconsistent");

      if S.Text_Projection.Line_Starts.Length > 0 then
         pragma Assert
           (S.Text_Projection.Line_Starts.Element (0) = 0,
            "Line index must start at 0 when present");
      end if;
   end Check_Line_Index;

   procedure Rebuild_Line_Index (S : in out State_Type) is
   begin
      S.Text_Projection.Line_Starts.Clear;
      S.Text_Projection.Line_Starts.Append (0);
   end Rebuild_Line_Index;

   function Line_Count (S : State_Type) return Natural is
   begin
      return Text_Buffer.Line_Count (S.Buffer);
   end Line_Count;

   function Row_For_Index
     (S     : State_Type;
      Index : Editor.Cursors.Cursor_Index) return Natural
   is
   begin
      return Text_Buffer.Row_For_Index (S.Buffer, Natural (Index));
   end Row_For_Index;

   procedure Row_Col_For_Index
     (S     : State_Type;
      Index : Editor.Cursors.Cursor_Index;
      Row   : out Natural;
      Col   : out Natural)
   is
   begin
      Text_Buffer.Row_Col_For_Index (S.Buffer, Natural (Index), Row, Col);
   end Row_Col_For_Index;

   function Line_Start
     (S   : State_Type;
      Row : Natural) return Editor.Cursors.Cursor_Index
   is
   begin
      return Editor.Cursors.Cursor_Index (Text_Buffer.Line_Start_Index (S.Buffer, Row));
   end Line_Start;

   function Line_End
     (S   : State_Type;
      Row : Natural) return Editor.Cursors.Cursor_Index
   is
   begin
      return Editor.Cursors.Cursor_Index (Text_Buffer.Line_End_Index (S.Buffer, Row));
   end Line_End;

   procedure Refresh_Dirty_Lines
     (S : in out State_Type)
   is
   begin
      Editor.Dirty_Lines.Recompute (S.Gutter.Dirty_Lines, Current_Text (S));
   end Refresh_Dirty_Lines;

   procedure Reset_Dirty_Line_Baseline
     (S : in out State_Type)
   is
   begin
      Editor.Dirty_Lines.Clear_Dirty_State_To_Current (S.Gutter.Dirty_Lines, Current_Text (S));
   end Reset_Dirty_Line_Baseline;

   procedure Toggle_Bookmark
     (S   : in out State_Type;
      Row : Natural)
   is
   begin
      Editor.Gutter_Markers.Toggle_Bookmark (S.Gutter.Markers, Row);
   end Toggle_Bookmark;

   procedure Clear_Gutter_Marker_Hover
     (S : in out State_Type)
   is
   begin
      S.Gutter.Marker_Hover := (Active => False, Row => 0, Kind => Editor.Gutter_Markers.Dirty_Line_Marker);
   end Clear_Gutter_Marker_Hover;

   procedure Set_Gutter_Marker_Hover
     (S    : in out State_Type;
      Row  : Natural;
      Kind : Editor.Gutter_Markers.Gutter_Marker_Kind)
   is
   begin
      S.Gutter.Marker_Hover := (Active => True, Row => Row, Kind => Kind);
   end Set_Gutter_Marker_Hover;

   procedure Replace_Document
     (S    : in out State_Type;
      Text : String)
   is
   begin
      Text_Buffer.Set_Text (S.Buffer, Text);

      --  Do not rebuild a full-document line-start vector. The rope stores
      --  newline counts and answers row/index queries directly.
      S.Text_Projection.Line_Starts.Clear;
      S.Text_Projection.Line_Starts.Append (0);

      S.Caret.Carets.Clear;
      S.Caret.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      S.Caret.Preferred_Column := 0;
      S.Caret.Rect_Select_Active := False;
      S.Caret.Rect_Anchor_Row := 0;
      S.Caret.Rect_Anchor_Col := 0;
      S.Search.Active_Find_Query := Null_Unbounded_String;
      S.Search.Active_Find_Matches.Clear;
      S.Search.Active_Find_Match := Editor.Search.No_Match;
      S.Search.Active_Find_Stale := False;
      S.Search.Active_Find_Case_Sensitive := False;
      S.Search.Active_Find_Whole_Word := False;
      S.Search.Active_Find_Source_Buffer_Token := 0;
      S.Search.Active_Find_Prompt := False;
      S.Search.Active_Replace_Text := Null_Unbounded_String;
      S.Search.Active_Replace_Error_Message := Null_Unbounded_String;
      S.Search.Active_Replace_Prompt := False;
      S.Panel.Diagnostics.Clear;
      S.Panel.Active_Diagnostic := (Has_Active => False, Index => Editor.Diagnostics.No_Diagnostic);
      Editor.Gutter_Markers.Clear (S.Gutter.Markers);
      Editor.Dirty_Lines.Clear_Dirty_State_To_Current
        (S.Gutter.Dirty_Lines, Text);
      Editor.Messages.Clear (S.Panel.Messages);
      Editor.Input_Field.Clear (S.Search.Active_Find_Input);
      Editor.Quick_Open.Clear (S.Surface.Quick_Open);
      Editor.Buffer_Switcher.Clear (S.Surface.Buffer_Switcher);
      Editor.Recent_Buffers.Clear (S.Navigation.Recent_Buffers);
      Editor.Go_To_Line.Clear (S.Surface.Go_To_Line);
      Editor.Project_Search.Clear (S.Surface.Project_Search);
      Editor.Bookmarks.Clear (S.Navigation.Bookmarks);
      S.Panel.Search_Results_View.Top_Row := 1;
      Editor.Panel_Focus.Focus_Editor_Text (S.Panel.Panel_Focus);
      Editor.Overlay_Focus.Clear (S.Panel.Overlay_Focus);
      Clear_Gutter_Marker_Hover (S);
      Editor.Folding.Clear (S.Syntax.Folding);
      S.Buffer_Lifecycle.File_Info.Has_Path := False;
      S.Buffer_Lifecycle.File_Info.Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.Buffer_Lifecycle.File_Info.Dirty := False;
      S.Buffer_Lifecycle.File_Info.Baseline_Valid := False;
      S.Buffer_Lifecycle.File_Info.Saved_Generation := 0;
      S.Buffer_Lifecycle.File_Info.Last_Save_Failed := False;
      S.Buffer_Lifecycle.File_Info.Last_Reload_Failed := False;
      S.Buffer_Lifecycle.File_Info.Last_Revert_Failed := False;
      S.Buffer_Lifecycle.File_Info.Missing_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.Unreadable_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.Unwritable_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.External_Change_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.File_Token_Known := False;
      S.Buffer_Lifecycle.File_Info.File_Token_Label := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Active := False;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Buffer := 0;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Display := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Kind := No_File_Conflict;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Dirty := False;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Buffer_Revision := 0;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Token_Label := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite := False;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_Buffer := 0;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_Selected := False;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_All_Buffers := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Active := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Scope := No_Dirty_Close_Scope;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_All_Buffers := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer_Fingerprint := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Fingerprint := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Buffer_Ids := Ada.Strings.Unbounded.Null_Unbounded_String;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_File_Backed_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Untitled_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Conflicted_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Unwritable_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Missing_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Save_Failure_Count := 0;
      S.Buffer_Lifecycle.Reopen_Candidate_Count := 0;
      S.Buffer_Lifecycle.Reopen_Candidate_Paths := (others => Null_Unbounded_String);
      S.Buffer_Lifecycle.Reopen_Candidate_Labels := (others => Null_Unbounded_String);
      S.Buffer_Lifecycle.Has_Reopen_Candidate := False;
      S.Buffer_Lifecycle.Reopen_Candidate_Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.Reopen_Candidate_Label := Null_Unbounded_String;
      Bump_Buffer_Revision (S);
      Editor.Syntax_Cache.Clear (S.Syntax.Cache);
      Editor.Syntax_Semantics.Clear (S.Syntax.Symbols);
      Editor.Ada_Language_Model.Clear (S.Syntax.Analysis);
      S.Semantic.Syntax_Source_Revision := Natural'Last;
      S.Semantic.Syntax_Source_Buffer_Token := 0;
      S.Semantic.Syntax_Symbols_Revision := Natural'Last;
      S.Semantic.Syntax_Symbols_Buffer_Token := 0;

      Check_Line_Index (S);
      Editor.Render_Cache.Invalidate_All;
   end Replace_Document;

   procedure Replace_Buffer_Contents
     (S        : in out State_Type;
      Contents : String)
   is
      File_Info : constant File_State := S.Buffer_Lifecycle.File_Info;
   begin
      Replace_Document (S, Contents);
      S.Buffer_Lifecycle.File_Info := File_Info;
      Editor.Feature_Search_Results.Mark_Stale_For_Buffer_Change
        (S.Panel.Feature_Search_Results, S.Buffer_Lifecycle.Active_Buffer_Token, S.Buffer_Lifecycle.Buffer_Revision);
      if S.Buffer_Lifecycle.Registry_Token /= 0
        and then S.Buffer_Lifecycle.Registry_Token /= S.Buffer_Lifecycle.Active_Buffer_Token
      then
         Editor.Feature_Search_Results.Mark_Stale_For_Buffer_Change
           (S.Panel.Feature_Search_Results, S.Buffer_Lifecycle.Registry_Token, S.Buffer_Lifecycle.Buffer_Revision);
      end if;
   end Replace_Buffer_Contents;

   procedure Load_Text
     (S    : in out State_Type;
      Text : String)
   is
   begin
      Replace_Buffer_Contents (S, Text);
      S.Buffer_Lifecycle.File_Info.Has_Path := False;
      S.Buffer_Lifecycle.File_Info.Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.Buffer_Lifecycle.File_Info.Dirty := False;
      S.Buffer_Lifecycle.File_Info.Baseline_Valid := False;
      S.Buffer_Lifecycle.File_Info.Saved_Generation := 0;
      S.Buffer_Lifecycle.File_Info.Last_Save_Failed := False;
      S.Buffer_Lifecycle.File_Info.Last_Reload_Failed := False;
      S.Buffer_Lifecycle.File_Info.Last_Revert_Failed := False;
      S.Buffer_Lifecycle.File_Info.Missing_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.Unreadable_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.Unwritable_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.External_Change_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.File_Token_Known := False;
      S.Buffer_Lifecycle.File_Info.File_Token_Label := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Active := False;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Buffer := 0;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Display := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Kind := No_File_Conflict;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Dirty := False;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Buffer_Revision := 0;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Token_Label := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite := False;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_Buffer := 0;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_Selected := False;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_All_Buffers := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Active := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Scope := No_Dirty_Close_Scope;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_All_Buffers := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer_Fingerprint := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Fingerprint := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Buffer_Ids := Ada.Strings.Unbounded.Null_Unbounded_String;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_File_Backed_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Untitled_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Conflicted_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Unwritable_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Missing_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Save_Failure_Count := 0;

      if S.Buffer_Lifecycle.Active_Buffer_Token /= 0 then
         Editor.Buffers.Mark_Global_Provisional_Active;
      end if;
   end Load_Text;

   function Current_Text
     (S : State_Type) return String
   is
   begin
      return Text_Buffer.UTF8_Text (S.Buffer);
   end Current_Text;

   function Current_Buffer_Revision
     (S : State_Type) return Natural
   is
   begin
      return S.Buffer_Lifecycle.Buffer_Revision;
   end Current_Buffer_Revision;

   function Current_Lifecycle_Generation
     (S : State_Type) return Natural
   is
   begin
      return S.Buffer_Lifecycle.Lifecycle_Generation;
   end Current_Lifecycle_Generation;

   procedure Init (S : out State_Type) is
      Startup_Settings_Status    : Editor.Settings.Settings_Status :=
        Editor.Settings.Settings_Not_Found;
      Startup_Keybinding_Status  : Editor.Keybinding_Config.Keybinding_Config_Status :=
        Editor.Keybinding_Config.Keybinding_Config_Not_Found;
      Startup_Recent_Status      : Editor.Recent_Projects.Recent_Project_Status :=
        Editor.Recent_Projects.Recent_Project_Not_Found;
      Startup_Workspace_Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status :=
        Editor.Workspace_Persistence.Workspace_Persistence_Not_Found;
      Startup_Workspace          : Editor.Workspace_Persistence.Workspace_Snapshot;
   begin
      S.Buffer_Lifecycle.Registry_Token := Allocate_Registry_Token;
      S.Buffer_Lifecycle.Active_Buffer_Token := S.Buffer_Lifecycle.Registry_Token;
      S.Buffer_Lifecycle.Buffer_Revision := 0;
      S.Buffer_Lifecycle.Lifecycle_Generation := 0;
      Editor.Syntax_Cache.Clear (S.Syntax.Cache);
      Editor.Syntax_Semantics.Clear (S.Syntax.Symbols);
      Editor.Ada_Language_Model.Clear (S.Syntax.Analysis);
      S.Semantic.Syntax_Source_Revision := Natural'Last;
      S.Semantic.Syntax_Source_Buffer_Token := 0;
      S.Semantic.Syntax_Symbols_Revision := Natural'Last;
      S.Semantic.Syntax_Symbols_Buffer_Token := 0;
      Text_Buffer.Clear (S.Buffer);

      S.Caret.Carets.Clear;
      S.Caret.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      S.Caret.Preferred_Column := 0;

      S.Caret.Rect_Select_Active := False;
      S.Caret.Rect_Anchor_Row := 0;
      S.Caret.Rect_Anchor_Col := 0;
      S.Search.Active_Find_Query := Null_Unbounded_String;
      S.Search.Active_Find_Matches.Clear;
      S.Search.Active_Find_Match := Editor.Search.No_Match;
      S.Search.Active_Find_Stale := False;
      S.Search.Active_Find_Case_Sensitive := False;
      S.Search.Active_Find_Whole_Word := False;
      S.Search.Active_Find_Source_Buffer_Token := 0;
      S.Search.Active_Find_Prompt := False;
      S.Search.Active_Replace_Text := Null_Unbounded_String;
      S.Search.Active_Replace_Error_Message := Null_Unbounded_String;
      S.Search.Active_Replace_Prompt := False;
      S.Panel.Diagnostics.Clear;
      S.Panel.Active_Diagnostic := (Has_Active => False, Index => Editor.Diagnostics.No_Diagnostic);
      Editor.Gutter_Markers.Clear (S.Gutter.Markers);
      Reset_Dirty_Line_Baseline (S);
      Editor.Project.Clear (S.Project_Runtime.Project);
      Editor.Feature_Panel.Clear (S.Panel.Feature_Panel);
      Editor.Feature_Messages.Reset_For_Workspace_Close (S.Panel.Feature_Messages);
      Editor.Feature_Search_Results.Reset_For_Workspace_Close (S.Panel.Feature_Search_Results);
      Editor.Outline.Clear (S.Outline_Runtime.Outline);
      S.Outline_Runtime.Cursor.Key_Valid := False;
      S.Outline_Runtime.Cursor.Buffer_Token := 0;
      S.Outline_Runtime.Cursor.Line := 0;
      S.Outline_Runtime.Cursor.Column := 0;
      declare
         Loaded_Settings : Editor.Settings.Settings_Model;
      begin
         Editor.Settings.Set_Defaults (S.Configuration.Settings);
         Editor.Settings.Load_From_File
           (Editor.Settings.Settings_File_Path, Loaded_Settings, Startup_Settings_Status);
         if Startup_Settings_Status = Editor.Settings.Settings_Ok
           or else Startup_Settings_Status = Editor.Settings.Settings_Partial_Load
         then
            Apply_Settings (S, Loaded_Settings);
         else
            Editor.Settings.Apply (S.Configuration.Settings);
         end if;
      end;
      if not Runtime_Keybindings_Initialized then
         declare
            Loaded_Keybindings : Editor.Keybinding_Config.Keybinding_Config_Model;
         begin
            Editor.Keybindings.Reset_To_Defaults;
            Editor.Keybinding_Config.Load_From_File
              (Editor.Keybinding_Config.Keybindings_File_Path,
               Loaded_Keybindings,
               Startup_Keybinding_Status);
            if Startup_Keybinding_Status = Editor.Keybinding_Config.Keybinding_Config_Ok
              or else Startup_Keybinding_Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load
            then
               Editor.Keybinding_Config.Apply_To_Runtime (Loaded_Keybindings);
            end if;
            Runtime_Keybinding_Status := Startup_Keybinding_Status;
            Runtime_Keybindings_Initialized := True;
         end;
      else
         Startup_Keybinding_Status := Runtime_Keybinding_Status;
      end if;
      Editor.Recent_Projects.Load_From_File
        (Editor.Recent_Projects.Recent_Projects_File_Path,
         S.Project_Runtime.Recent_Projects,
         Startup_Recent_Status);
      if Startup_Recent_Status = Editor.Recent_Projects.Recent_Project_Not_Found
        or else Startup_Recent_Status = Editor.Recent_Projects.Recent_Project_Invalid_Format
        or else Startup_Recent_Status = Editor.Recent_Projects.Recent_Project_Read_Error
      then
         Editor.Recent_Projects.Clear (S.Project_Runtime.Recent_Projects);
         S.Project_Runtime.Recent_Project_Selected_Index := 0;
      elsif Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects) = 0 then
         S.Project_Runtime.Recent_Project_Selected_Index := 0;
      else
         S.Project_Runtime.Recent_Project_Selected_Index := 1;
      end if;
      Editor.Workspace_Persistence.Clear (Startup_Workspace);

      Editor.File_Tree.Clear (S.Surface.File_Tree);
      Editor.File_Tree_View.Clear_View (S.Surface.File_Tree_View);
      Editor.Panels.Initialize_Defaults (S.Panel.Panels);
      Editor.Panels.Set_Current (S.Panel.Panels);
      Editor.Messages.Clear (S.Panel.Messages);
      Editor.Input_Field.Clear (S.Search.Active_Find_Input);
      Editor.Quick_Open.Clear (S.Surface.Quick_Open);
      Editor.Buffer_Switcher.Clear (S.Surface.Buffer_Switcher);
      Editor.Recent_Buffers.Clear (S.Navigation.Recent_Buffers);
      Editor.Go_To_Line.Clear (S.Surface.Go_To_Line);
      Editor.Input_Field.Clear (S.Search.Active_Find_Input);
      S.Search.Active_Find_Query := Null_Unbounded_String;
      S.Search.Active_Find_Matches.Clear;
      S.Search.Active_Find_Match := Editor.Search.No_Match;
      S.Search.Active_Find_Stale := False;
      S.Search.Active_Find_Case_Sensitive := False;
      S.Search.Active_Find_Whole_Word := False;
      S.Search.Active_Find_Source_Buffer_Token := 0;
      S.Search.Active_Find_Prompt := False;
      S.Search.Active_Replace_Text := Null_Unbounded_String;
      S.Search.Active_Replace_Error_Message := Null_Unbounded_String;
      S.Search.Active_Replace_Prompt := False;
      Editor.Navigation_History.Clear (S.Navigation.History);
      Editor.Project_Search.Clear (S.Surface.Project_Search);
      Editor.Bookmarks.Clear (S.Navigation.Bookmarks);
      S.Panel.Search_Results_View.Top_Row := 1;
      Editor.Panel_Focus.Focus_Editor_Text (S.Panel.Panel_Focus);
      Editor.Overlay_Focus.Clear (S.Panel.Overlay_Focus);
      Clear_Gutter_Marker_Hover (S);
      Editor.Folding.Clear (S.Syntax.Folding);
      S.Buffer_Lifecycle.File_Info.Has_Path := False;
      S.Buffer_Lifecycle.File_Info.Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.Buffer_Lifecycle.File_Info.Dirty := False;
      S.Buffer_Lifecycle.File_Info.Baseline_Valid := False;
      S.Buffer_Lifecycle.File_Info.Saved_Generation := 0;
      S.Buffer_Lifecycle.File_Info.Last_Save_Failed := False;
      S.Buffer_Lifecycle.File_Info.Last_Reload_Failed := False;
      S.Buffer_Lifecycle.File_Info.Last_Revert_Failed := False;
      S.Buffer_Lifecycle.File_Info.Missing_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.Unreadable_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.Unwritable_Target_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.External_Change_Surfaced := False;
      S.Buffer_Lifecycle.File_Info.File_Token_Known := False;
      S.Buffer_Lifecycle.File_Info.File_Token_Label := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Active := False;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Buffer := 0;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Display := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Kind := No_File_Conflict;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Dirty := False;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Buffer_Revision := 0;
      S.Buffer_Lifecycle.File_Conflict_Prompt_Token_Label := Null_Unbounded_String;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite := False;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_Buffer := 0;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_Selected := False;
      S.Buffer_Lifecycle.File_Conflict_Close_After_Overwrite_All_Buffers := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Active := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Scope := No_Dirty_Close_Scope;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_All_Buffers := False;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Buffer_Fingerprint := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Fingerprint := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Buffer_Ids := Ada.Strings.Unbounded.Null_Unbounded_String;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Dirty_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_File_Backed_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Untitled_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Conflicted_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Unwritable_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Missing_Count := 0;
      S.Buffer_Lifecycle.Dirty_Close_Prompt_Save_Failure_Count := 0;
      S.Buffer_Lifecycle.Reopen_Candidate_Count := 0;
      S.Buffer_Lifecycle.Reopen_Candidate_Paths := (others => Null_Unbounded_String);
      S.Buffer_Lifecycle.Reopen_Candidate_Labels := (others => Null_Unbounded_String);
      S.Buffer_Lifecycle.Has_Reopen_Candidate := False;
      S.Buffer_Lifecycle.Reopen_Candidate_Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.Reopen_Candidate_Label := Null_Unbounded_String;

      Editor.Startup_Readiness.Record_Startup_Summary
        (Editor.Startup_Readiness.Build_Observed_Startup_Summary
           (Startup_Settings_Status,
            Startup_Keybinding_Status,
            Startup_Workspace_Status,
            Startup_Recent_Status,
            Startup_Workspace,
            Restore_Requested => True));

      Rebuild_Line_Index (S);
      Editor.Render_Cache.Reset;
   end Init;

   procedure Normalize_Carets (S : in out State_Type) is
      Result : Cursors_Vector.Vector;
      Len    : constant Cursor_Index :=
        Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      for C of S.Caret.Carets loop
         declare
            Clamped : Caret_State := C;
         begin
            if Clamped.Pos > Len then
               Clamped.Pos := Len;
            end if;

            if Clamped.Anchor > Len then
               Clamped.Anchor := Len;
            end if;

            Result.Append (Clamped);
         end;
      end loop;

      if Result.Length = 0 then
         Result.Append
           (Caret_State'
              (Pos                   => 0,
               Anchor                => 0,
               Virtual_Column        => 0,
               Anchor_Virtual_Column => 0));
      end if;

      if Result.Length > 1 then
         declare
            Tmp : Caret_State;
         begin
            for I in Result.First_Index .. Result.Last_Index loop
               for J in I + 1 .. Result.Last_Index loop
                  if Result (J).Pos < Result (I).Pos
                    or else
                    (Result (J).Pos = Result (I).Pos
                     and then Result (J).Virtual_Column < Result (I).Virtual_Column)
                  then
                     Tmp := Result (I);
                     Result.Replace_Element (I, Result (J));
                     Result.Replace_Element (J, Tmp);
                  end if;
               end loop;
            end loop;
         end;
      end if;

      if Result.Length > 1 then
         declare
            I : Extended_Index := Result.First_Index;
         begin
            while I < Result.Last_Index loop
               if Result (I).Pos = Result (I + 1).Pos
                 and then Result (I).Anchor = Result (I + 1).Anchor
                 and then Result (I).Virtual_Column =
                          Result (I + 1).Virtual_Column
                 and then Result (I).Anchor_Virtual_Column =
                          Result (I + 1).Anchor_Virtual_Column
               then
                  Result.Delete (I + 1);
               else
                  I := I + 1;
               end if;
            end loop;
         end;
      end if;

      S.Caret.Carets := Result;
   end Normalize_Carets;

   procedure Rebuild_After_Buffer_Change
   (S      : in out State_Type;
      Change : Buffer_Change)
   is
   begin
      Bump_Buffer_Revision (S);

      --  row metadata is maintained by the rope itself during the
      --  mutation. Keep only a minimal line-start marker and avoid any
      --  document-wide scan here.
      S.Text_Projection.Line_Starts.Clear;
      S.Text_Projection.Line_Starts.Append (0);

      S.Search.Active_Find_Matches.Clear;
      S.Search.Active_Find_Match := Editor.Search.No_Match;
      if Length (S.Search.Active_Find_Query) > 0 then
         S.Search.Active_Find_Stale := True;
         S.Search.Active_Find_Source_Buffer_Token := S.Buffer_Lifecycle.Active_Buffer_Token;
      else
         S.Search.Active_Find_Stale := False;
         S.Search.Active_Find_Source_Buffer_Token := 0;
      end if;
      S.Panel.Diagnostics.Clear;
      S.Panel.Active_Diagnostic := (Has_Active => False, Index => Editor.Diagnostics.No_Diagnostic);
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale
        (S.Panel.Feature_Diagnostics, S.Buffer_Lifecycle.Active_Buffer_Token);
      --  ordinary edits make retained feature Diagnostics for the
      --  active buffer stale instead of deleting them through the buffer-close
      --  lifecycle path.  The stale marker is transient Diagnostics-owned
      --  review state; editing still must not reproject rows, navigate
      --  targets, parse build output, or mutate Build result/output state.
      if S.Buffer_Lifecycle.Registry_Token /= 0
        and then S.Buffer_Lifecycle.Registry_Token /= S.Buffer_Lifecycle.Active_Buffer_Token
      then
         --  Rows captured before the global buffer registry assigned a real
         --  buffer id used the registry owner token as an active-buffer alias.
         Editor.Feature_Diagnostics.Reset_Diagnostics_For_Buffer_Close
           (S.Panel.Feature_Diagnostics, S.Buffer_Lifecycle.Registry_Token);
      end if;
      Editor.Feature_Messages.Reset_For_Buffer_Close
        (S.Panel.Feature_Messages, S.Buffer_Lifecycle.Active_Buffer_Token);
      if S.Buffer_Lifecycle.Registry_Token /= 0
        and then S.Buffer_Lifecycle.Registry_Token /= S.Buffer_Lifecycle.Active_Buffer_Token
      then
         Editor.Feature_Messages.Reset_For_Buffer_Close
           (S.Panel.Feature_Messages, S.Buffer_Lifecycle.Registry_Token);
      end if;
      --  Keep visible Messages rows passive during ordinary editing; source
      --  cleanup above is enough to make later explicit feature use valid.
      if Editor.Outline.Source_Buffer_Token (S.Outline_Runtime.Outline) = 0 then
         Editor.Outline.Reset_For_Buffer_Change (S.Outline_Runtime.Outline);
      else
         Editor.Outline.Mark_For_Buffer_Change (S.Outline_Runtime.Outline);
      end if;
      --  Do not refresh or reproject Outline rows from the edit path.  The
      --  explicit Outline refresh/show path remains responsible for visible
      --  row replacement; accepted rows are retained only as stale display
      --  state and cannot be activated until refresh validates a new snapshot.
      --  Preserve explicit gutter marker state across ordinary edits.
      --  markers are row-level and intentionally do not implement
      --  a line-history remapping algorithm yet; markers beyond the current
      --  document range simply do not render.
      Editor.Folding.Clear (S.Syntax.Folding);
      S.Buffer_Lifecycle.File_Info.Dirty := True;
      Editor.Feature_Search_Results.Mark_Stale_For_Buffer_Change
        (S.Panel.Feature_Search_Results, S.Buffer_Lifecycle.Active_Buffer_Token, S.Buffer_Lifecycle.Buffer_Revision);
      if S.Buffer_Lifecycle.Registry_Token /= 0
        and then S.Buffer_Lifecycle.Registry_Token /= S.Buffer_Lifecycle.Active_Buffer_Token
      then
         Editor.Feature_Search_Results.Mark_Stale_For_Buffer_Change
           (S.Panel.Feature_Search_Results, S.Buffer_Lifecycle.Registry_Token, S.Buffer_Lifecycle.Buffer_Revision);
      end if;
      --  Mark visible Search Results stale, but do not rerun Search or mutate
      --  the visible Feature Panel rows from ordinary text editing.
      Editor.Project_Search.Mark_Stale (S.Surface.Project_Search);
      --  a searched file edited in a buffer makes retained Project
      --  Search rows unsafe to activate until the user reruns the explicit,
      --  bounded project search.  This is a transient stale marker only; it
      --  does not scan, search, open files, or persist search state.
      Refresh_Dirty_Lines (S);
      declare
         First_Row : constant Natural :=
           Row_For_Index (S, Editor.Cursors.Cursor_Index (Change.Start_Index));
      begin
         Editor.Syntax_Cache.Set_Line_Count (S.Syntax.Cache, Line_Count (S));
         --  The cache is line-indexed and does not apply edit deltas.  Any
         --  insertion/deletion before an existing cached row can shift the
         --  text that row represents, so every cached row from the first
         --  touched row through the end of the buffer must be considered
         --  invalid until relexed.  Lexical-state propagation will stop
         --  once the dirty suffix has stabilized during visible-range
         --  preparation.
         if Line_Count (S) = 0 then
            Editor.Syntax_Cache.Clear (S.Syntax.Cache);
         else
            Editor.Syntax_Cache.Mark_Range_Dirty
              (S.Syntax.Cache, First_Row + 1, Line_Count (S));
         end if;
         Editor.Syntax_Semantics.Clear (S.Syntax.Symbols);
         Editor.Ada_Language_Model.Clear (S.Syntax.Analysis);
         S.Semantic.Syntax_Source_Revision := S.Buffer_Lifecycle.Buffer_Revision;
         S.Semantic.Syntax_Source_Buffer_Token := S.Buffer_Lifecycle.Active_Buffer_Token;
         S.Semantic.Syntax_Symbols_Revision := Natural'Last;
         S.Semantic.Syntax_Symbols_Buffer_Token := 0;
      end;

      Check_Line_Index (S);
      Normalize_Carets (S);

      --  Conservative but correct during line-index migration.
      Editor.Render_Cache.Invalidate_All;
   end Rebuild_After_Buffer_Change;

   procedure Rebuild_After_Buffer_Change
     (S : in out State_Type)
   is
      Dummy : constant Buffer_Change :=
        (Start_Index => 0,
         Old_Length  => 0,
         New_Length  => 0);
   begin
      Rebuild_After_Buffer_Change (S, Dummy);
   end Rebuild_After_Buffer_Change;

   procedure Mutate_Buffer
     (S  : in out State_Type;
      Op : access procedure (B : in out Text_Buffer.Buffer_Type)) is
   begin
      Op (S.Buffer);
      Rebuild_After_Buffer_Change (S);
   end Mutate_Buffer;



   function Text_Line
     (S   : State_Type;
      Row : Natural) return String
   is
      Text  : constant String := Current_Text (S);
      Start : Natural := Text'First;
      Stop  : Natural := Text'First - 1;
      Current_Row : Natural := 0;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      for I in Text'Range loop
         if Current_Row = Row then
            Start := I;
            Stop := I;
            while Stop <= Text'Last
              and then Text (Stop) /= ASCII.LF
              and then Text (Stop) /= ASCII.CR
            loop
               Stop := Stop + 1;
            end loop;

            if Stop <= Start then
               return "";
            else
               return Text (Start .. Stop - 1);
            end if;
         end if;

         if Text (I) = ASCII.LF then
            Current_Row := Current_Row + 1;
         end if;
      end loop;

      if Current_Row = Row then
         return "";
      end if;

      return "";
   end Text_Line;

   procedure Rebuild_Syntax_Symbols
     (S : in out State_Type)
   is
      Source_Label : constant String :=
        (if S.Buffer_Lifecycle.File_Info.Has_Path then To_String (S.Buffer_Lifecycle.File_Info.Path)
         else To_String (S.Buffer_Lifecycle.File_Info.Display_Name));
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Current_Text (S), Source_Label);
   begin
      Editor.Syntax_Semantics.Clear (S.Syntax.Symbols);
      S.Syntax.Analysis := Analysis;

      --  completeness: visible-range syntax preparation
      --  now builds semantic colouring from the shared parser-owned Ada
      --  language model.  This keeps the normal render preparation path aligned
      --  with semantic.refresh-buffer and avoids re-projecting through Outline
      --  rows before semantic classification.
      Editor.Syntax_Semantics.Build_Map_From_Analysis (S.Syntax.Symbols, Analysis);

      --  Fallback remains intentionally conservative for unsupported or empty
      --  parser results, and still ignores comments/strings through the
      --  line-level learner.
      if Editor.Syntax_Semantics.Symbol_Count (S.Syntax.Symbols) = 0 then
         for Row in 0 .. Line_Count (S) - 1 loop
            declare
               Line : constant String := Text_Line (S, Row);
            begin
               Editor.Syntax_Semantics.Learn_Declarations_From_Line
                 (S.Syntax.Symbols, Line);
            end;
         end loop;
      end if;

      S.Semantic.Syntax_Symbols_Revision := S.Buffer_Lifecycle.Buffer_Revision;
      S.Semantic.Syntax_Symbols_Buffer_Token := S.Buffer_Lifecycle.Active_Buffer_Token;
   end Rebuild_Syntax_Symbols;

   procedure Prepare_Syntax_For_Visible_Range
     (S          : in out State_Type;
      First_Row  : Natural;
      Last_Row   : Natural;
      Use_Semantic_Colouring : Boolean := True)
   is
      Total : constant Natural := Line_Count (S);
      Empty_Document : constant Boolean := Current_Text (S)'Length = 0;
      Stop  : constant Natural := (if Total = 0 then 0 else Natural'Min (Last_Row, Total - 1));
      Row   : Natural := Natural'Min (First_Row, Stop);
      Dirty_Stop : Natural := Stop;
      Changed : Boolean := False;
   begin
      if Total = 0 or else Empty_Document then
         Editor.Syntax_Cache.Clear (S.Syntax.Cache);
         Editor.Syntax_Semantics.Clear (S.Syntax.Symbols);
         Editor.Ada_Language_Model.Clear (S.Syntax.Analysis);
         S.Semantic.Syntax_Source_Revision := Natural'Last;
         S.Semantic.Syntax_Source_Buffer_Token := 0;
         S.Semantic.Syntax_Symbols_Revision := Natural'Last;
         S.Semantic.Syntax_Symbols_Buffer_Token := 0;
         return;
      end if;

      if S.Semantic.Syntax_Source_Buffer_Token /= S.Buffer_Lifecycle.Active_Buffer_Token then
         Editor.Syntax_Cache.Clear (S.Syntax.Cache);
         Editor.Syntax_Semantics.Clear (S.Syntax.Symbols);
         Editor.Ada_Language_Model.Clear (S.Syntax.Analysis);
         S.Semantic.Syntax_Source_Revision := Natural'Last;
         S.Semantic.Syntax_Source_Buffer_Token := S.Buffer_Lifecycle.Active_Buffer_Token;
         S.Semantic.Syntax_Symbols_Revision := Natural'Last;
         S.Semantic.Syntax_Symbols_Buffer_Token := S.Buffer_Lifecycle.Active_Buffer_Token;
      end if;

      if S.Semantic.Syntax_Source_Revision /= S.Buffer_Lifecycle.Buffer_Revision
        or else Editor.Syntax_Cache.Cached_Line_Count (S.Syntax.Cache) /= Total
      then
         Editor.Syntax_Cache.Set_Line_Count (S.Syntax.Cache, Total);
         S.Semantic.Syntax_Source_Revision := S.Buffer_Lifecycle.Buffer_Revision;
         S.Semantic.Syntax_Source_Buffer_Token := S.Buffer_Lifecycle.Active_Buffer_Token;
      end if;

      if Use_Semantic_Colouring
        and then (S.Semantic.Syntax_Symbols_Revision /= S.Buffer_Lifecycle.Buffer_Revision
          or else S.Semantic.Syntax_Symbols_Buffer_Token /= S.Buffer_Lifecycle.Active_Buffer_Token)
      then
         Rebuild_Syntax_Symbols (S);
      end if;

      --  A visible line's start state depends on the nearest previous cached
      --  line-end state.  If an earlier dirty line exists before the visible
      --  range, relex from that line so unterminated strings/recovery state
      --  cannot leave the requested rows using stale predecessor state.
      for Candidate in 0 .. Stop loop
         if Editor.Syntax_Cache.Is_Dirty (S.Syntax.Cache, Candidate + 1) then
            Row := Candidate;
            exit;
         end if;
      end loop;

      while Row <= Dirty_Stop loop
         if Editor.Syntax_Cache.Is_Dirty (S.Syntax.Cache, Row + 1) then
            declare
               Line : constant String := Text_Line (S, Row);
            begin
               Editor.Syntax_Cache.Relex_Dirty_Line
                 (S.Syntax.Cache, Row + 1, Line, Changed);
            end;
         else
            Changed := False;
         end if;

         if Changed and then Dirty_Stop < Total - 1 then
            Dirty_Stop := Dirty_Stop + 1;
         end if;

         exit when Row = Dirty_Stop and then not Changed;
         if Row = Natural'Last then
            exit;
         end if;
         Row := Row + 1;
         exit when Row >= Total;
      end loop;
   end Prepare_Syntax_For_Visible_Range;


   procedure Add_Diagnostic
     (S           : in out State_Type;
      Start_Index : Editor.Cursors.Cursor_Index;
      End_Index   : Editor.Cursors.Cursor_Index;
      Severity    : Editor.Diagnostics.Diagnostic_Severity;
      Message     : String := "")
   is
   begin
      declare
         Row : Natural := 0;
         Col : Natural := 0;
      begin
         Row_Col_For_Index (S, Start_Index, Row, Col);
         Editor.Diagnostics.Add
           (S.Panel.Diagnostics, Start_Index, End_Index, Row, Col, Severity, Message);
      end;
      Editor.Render_Cache.Invalidate_All;
   end Add_Diagnostic;

   procedure Clear_Diagnostics
     (S : in out State_Type)
   is
   begin
      Editor.Diagnostics.Clear (S.Panel.Diagnostics);
      S.Panel.Active_Diagnostic := (Has_Active => False, Index => Editor.Diagnostics.No_Diagnostic);
      Editor.Render_Cache.Invalidate_All;
   end Clear_Diagnostics;

   function Normalize_Diagnostic_Source
     (Source : String) return String
   is
   begin
      return Editor.Producer_Contracts.Normalize_Producer_Source (Source);
   end Normalize_Diagnostic_Source;

   function Post_Diagnostic_With_Result
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String := "") return Editor.Producer_Contracts.Producer_Result
   is
      Clean_Message : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (Message);
      Clean_Source  : constant String := Normalize_Diagnostic_Source (Source);
   begin
      if Clean_Message'Length = 0 then
         return Editor.Producer_Contracts.Rejected_Empty_Text;
      end if;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Panel.Feature_Diagnostics,
         Severity     => Severity,
         Message      => Clean_Message,
         Source_Label => Clean_Source,
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Panel.Feature_Diagnostics, S.Panel.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
      return Editor.Producer_Contracts.Accepted_Untargeted;
   end Post_Diagnostic_With_Result;

   procedure Post_Diagnostic
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String := "")
   is
      Result : constant Editor.Producer_Contracts.Producer_Result :=
        Post_Diagnostic_With_Result (S, Severity, Message, Source);
      pragma Unreferenced (Result);
   begin
      null;
   end Post_Diagnostic;

   function Post_Targeted_Diagnostic_With_Result
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural) return Editor.Producer_Contracts.Producer_Result
   is
      Clean_Message : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (Message);
      Clean_Source  : constant String := Normalize_Diagnostic_Source (Source);
      Target        : constant Editor.Feature_Targets.Feature_Row_Target_Validation :=
        Editor.Feature_Targets.Validate_Buffer_Target_For_Feature_Row
          (S, Buffer, Line, Column);
      Keep_Target   : constant Boolean :=
        Target.Valid
        or else (Buffer /= Editor.Feature_Diagnostics.No_Buffer
                 and then Line > 0
                 and then Column = 0
                 and then Line <= Editor.State.Line_Count (S));
   begin
      if Clean_Message'Length = 0 then
         return Editor.Producer_Contracts.Rejected_Empty_Text;
      end if;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Panel.Feature_Diagnostics,
         Severity      => Severity,
         Message       => Clean_Message,
         Source_Label  => Clean_Source,
         Source_Kind   => Editor.Feature_Diagnostics.File_Diagnostic_Source,
         --  Diagnostics review must retain producer-supplied target
         --  metadata even when the target is only partially usable.  Do not
         --  collapse line-only, missing-line, or missing-buffer records into a
         --  source-less row by passing only Target.Valid here; Add_Diagnostic
         --  owns the navigable-vs-partial target distinction.
         Has_Target    => Keep_Target,
         Target_Buffer => Buffer,
         Target_Line   => Line,
         Target_Column => Column);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Panel.Feature_Diagnostics, S.Panel.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
      if Keep_Target then
         return Editor.Producer_Contracts.Accepted;
      else
         return Editor.Producer_Contracts.Accepted_Untargeted;
      end if;
   end Post_Targeted_Diagnostic_With_Result;

   procedure Post_Targeted_Diagnostic
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural)
   is
      Result : constant Editor.Producer_Contracts.Producer_Result :=
        Post_Targeted_Diagnostic_With_Result
          (S, Severity, Message, Source, Buffer, Line, Column);
      pragma Unreferenced (Result);
   begin
      null;
   end Post_Targeted_Diagnostic;

   procedure Start_Quick_Fix_Workflow
     (S                : in out State_Type;
      Diagnostic_Index : Natural;
      Action_Index     : Natural := 0)
   is
   begin
      S.Semantic.Pending_Quick_Fix :=
        (Diagnostic_Index => Diagnostic_Index,
         Action_Index     => Action_Index);
   end Start_Quick_Fix_Workflow;

   procedure Clear_Quick_Fix_Workflow
     (S : in out State_Type)
   is
   begin
      S.Semantic.Pending_Quick_Fix := (others => 0);
   end Clear_Quick_Fix_Workflow;

   function Has_Pending_Quick_Fix_Workflow
     (S : State_Type) return Boolean is
   begin
      return S.Semantic.Pending_Quick_Fix.Diagnostic_Index > 0;
   end Has_Pending_Quick_Fix_Workflow;

   function Pending_Quick_Fix_Diagnostic_Index
     (S : State_Type) return Natural is
   begin
      return S.Semantic.Pending_Quick_Fix.Diagnostic_Index;
   end Pending_Quick_Fix_Diagnostic_Index;

   function Pending_Quick_Fix_Action_Index
     (S : State_Type) return Natural is
   begin
      return S.Semantic.Pending_Quick_Fix.Action_Index;
   end Pending_Quick_Fix_Action_Index;




   function Project_Scoped_State_Summary_For
     (S : State_Type) return Project_Scoped_State_Summary
   is
      Snapshot : constant Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot
          (S.Surface.Project_Search, (others => <>));
      Pending_Kind : constant Editor.Pending_Transitions.Pending_Transition_Kind :=
        Editor.Pending_Transitions.Target_Kind (S.Workflow.Pending_Transitions);
      Panel_Summary : constant Editor.Feature_Panel.Feature_Panel_Summary :=
        Editor.Feature_Panel.Summary (S.Panel.Feature_Panel);
   begin
      return
        (Has_Project_Root            => Editor.Project.Has_Project (S.Project_Runtime.Project),
         File_Tree_Node_Count        => Editor.File_Tree.Node_Count (S.Surface.File_Tree),
         File_Tree_Expansion_Count   => Editor.File_Tree.Expanded_Node_Count (S.Surface.File_Tree),
         Quick_Open_Result_Count     => Editor.Quick_Open.Result_Count (S.Surface.Quick_Open),
         Project_Search_Result_Count => Editor.Project_Search.Result_Count (S.Surface.Project_Search),
         Bookmark_Count => Editor.Bookmarks.Count (S.Navigation.Bookmarks),
         Bookmarks_Visible => Editor.Bookmarks.Is_Visible (S.Navigation.Bookmarks),
         Search_Results_Row_Count    => Editor.Search_Results.Row_Count (Snapshot),
         Has_Project_Search_Query    =>
           Editor.Project_Search.Has_Query (S.Surface.Project_Search)
           or else Editor.Project_Search_Bar.Query_Text (S.Surface.Project_Search_Bar)'Length > 0,
         Feature_Panel_Row_Count     => Panel_Summary.Row_Count,
         Feature_Panel_Selected_Row  => Panel_Summary.Selected_Row,
         Feature_Panel_Has_Selection => Panel_Summary.Has_Selection,
         Feature_Panel_Visible       => Panel_Summary.Visible,
         Feature_Panel_Focused       => Panel_Summary.Focused,
         Feature_Panel_Fingerprint   =>
           Editor.Feature_Panel.Fingerprint (S.Panel.Feature_Panel),
         Outline_Item_Count          =>
           Editor.Outline.Item_Count (S.Outline_Runtime.Outline),
         Outline_Has_Items           =>
           Editor.Outline.Has_Items (S.Outline_Runtime.Outline),
         Outline_Fingerprint         =>
           Editor.Outline.Fingerprint (S.Outline_Runtime.Outline),
         Feature_Message_Row_Count   =>
           Editor.Feature_Messages.Row_Count (S.Panel.Feature_Messages),
         Feature_Search_Result_Count =>
           Editor.Feature_Search_Results.Row_Count (S.Panel.Feature_Search_Results),
         Feature_Diagnostic_Row_Count =>
           Editor.Feature_Diagnostics.Row_Count (S.Panel.Feature_Diagnostics),
         Has_Pending_Project_Target  =>
           Pending_Kind in Editor.Pending_Transitions.Pending_Close_Project
              | Editor.Pending_Transitions.Pending_Open_Project
              | Editor.Pending_Transitions.Pending_Switch_Project
              | Editor.Pending_Transitions.Pending_Open_Recent_Project
              | Editor.Pending_Transitions.Pending_Restore_Workspace
              | Editor.Pending_Transitions.Pending_Clear_Project);
   end Project_Scoped_State_Summary_For;

   procedure Reset_Project_Scoped_State
     (S : in out State_Type)
   is
      Active : constant Editor.Overlay_Focus.Overlay_Target :=
        Editor.Overlay_Focus.Active_Overlay (S.Panel.Overlay_Focus);
   begin
      Editor.Project.Clear (S.Project_Runtime.Project);
      S.Buffer_Lifecycle.Reopen_Candidate_Count := 0;
      S.Buffer_Lifecycle.Reopen_Candidate_Paths := (others => Null_Unbounded_String);
      S.Buffer_Lifecycle.Reopen_Candidate_Labels := (others => Null_Unbounded_String);
      S.Buffer_Lifecycle.Has_Reopen_Candidate := False;
      S.Buffer_Lifecycle.Reopen_Candidate_Path := Null_Unbounded_String;
      S.Buffer_Lifecycle.Reopen_Candidate_Label := Null_Unbounded_String;
      Editor.File_Tree.Clear (S.Surface.File_Tree);
      Editor.File_Tree_View.Clear_View (S.Surface.File_Tree_View);
      Editor.Quick_Open.Clear (S.Surface.Quick_Open);
      Editor.Buffer_Switcher.Clear (S.Surface.Buffer_Switcher);
      Editor.Recent_Buffers.Clear (S.Navigation.Recent_Buffers);
      Editor.Go_To_Line.Clear (S.Surface.Go_To_Line);
      Editor.Input_Field.Clear (S.Search.Active_Find_Input);
      S.Search.Active_Find_Query := Null_Unbounded_String;
      S.Search.Active_Find_Matches.Clear;
      S.Search.Active_Find_Match := Editor.Search.No_Match;
      S.Search.Active_Find_Stale := False;
      S.Search.Active_Find_Case_Sensitive := False;
      S.Search.Active_Find_Whole_Word := False;
      S.Search.Active_Find_Source_Buffer_Token := 0;
      S.Search.Active_Find_Prompt := False;
      S.Search.Active_Replace_Text := Null_Unbounded_String;
      S.Search.Active_Replace_Error_Message := Null_Unbounded_String;
      S.Search.Active_Replace_Prompt := False;
      Editor.Navigation_History.Clear (S.Navigation.History);
      Editor.Project_Search.Clear (S.Surface.Project_Search);
      Editor.Bookmarks.Clear (S.Navigation.Bookmarks);
      Editor.Project_Search_Bar.Clear (S.Surface.Project_Search_Bar);
      S.Panel.Search_Results_View.Top_Row := 1;
      Editor.Problems.Clear_View (S.Panel.Problems_View);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (S);
      --  the Ada project language index is
      --  project-scoped transient analysis state.  Closing, clearing, or
      --  switching a project must not leave indexed Outline/semantic targets
      --  from the previous lifecycle visible to later commands.
      Editor.Ada_Project_Index.Clear (S.Semantic.Language_Index);
      Editor.Ada_Language_Service.Clear (S.Semantic.Language_Service);

      --  repeated-use hardening: project close/switch/reload must
      --  remove all transient public-build workflow state, not only the
      --  candidate rows.  This prevents a later session or project from
      --  reusing old selected candidates, consent, latest result, or bounded
      --  output details after the project-scoped lifecycle state has been
      --  reset.
      S.Build.Build_UI := Editor.Build_UI.Empty_State;
      S.Build.Latest_Result := Editor.Build_Result_Summary.Empty_Summary;
      S.Build.Latest_Result_Focused := False;
      S.Build.Latest_Output_Details :=
        Editor.Build_Output_Details.Empty_Output_Details;
      Editor.Terminal_Tasks.Clear (S.Build.Terminal_Tasks);
      S.Project_Runtime.Recent_Projects_Focused := False;

      Clear_File_Target_Prompt (S);
      Editor.Guided_Prompts.Clear (S.Workflow.Guided_Prompt);

      if Active = Editor.Overlay_Focus.Quick_Open_Overlay
        or else Active = Editor.Overlay_Focus.Buffer_Switcher_Overlay
        or else Active = Editor.Overlay_Focus.Project_Search_Bar_Overlay
        or else Active = Editor.Overlay_Focus.Go_To_Line_Overlay
        or else Active = Editor.Overlay_Focus.File_Target_Prompt_Overlay
        or else Active = Editor.Overlay_Focus.Active_Find_Prompt_Overlay
      then
         Editor.Overlay_Focus.Dismiss
           (S.Panel.Overlay_Focus, Editor.Overlay_Focus.Dismiss_Command);
      end if;

      if Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel.Panel_Focus)
        or else Editor.Panel_Focus.Bottom_Content (S.Panel.Panel_Focus) =
          Editor.Panel_Focus.Search_Results_Focus
      then
         Editor.Panel_Focus.Focus_Editor_Text (S.Panel.Panel_Focus);
      end if;

      Editor.Pending_Transitions.Clear (S.Workflow.Pending_Transitions);
      if S.Buffer_Lifecycle.Lifecycle_Generation = Natural'Last then
         S.Buffer_Lifecycle.Lifecycle_Generation := 1;
      else
         S.Buffer_Lifecycle.Lifecycle_Generation := S.Buffer_Lifecycle.Lifecycle_Generation + 1;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Reset_Project_Scoped_State;

   function Build_Workspace_Snapshot
     (S : State_Type) return Editor.Workspace_Persistence.Workspace_Snapshot
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Registry : Editor.Buffers.Buffer_Registry;
      Summary  : Editor.Buffers.Buffer_Summary;
      Buffer   : State_Type;
      Row      : Natural := 0;
      Col      : Natural := 0;
      Path     : Unbounded_String;
      Rel_Path : Unbounded_String;
      Node     : Editor.File_Tree.File_Tree_Node_Summary;

      function Workspace_Feature
        (Feature : Editor.Feature_Panel.Feature_Id)
         return Editor.Workspace_Persistence.Workspace_Feature_Panel_Id
      is
      begin
         case Feature is
            when Editor.Feature_Panel.Messages_Feature =>
               return Editor.Workspace_Persistence.Workspace_Messages_Feature;
            when Editor.Feature_Panel.Search_Results_Feature =>
               return Editor.Workspace_Persistence.Workspace_Search_Results_Feature;
            when Editor.Feature_Panel.Diagnostics_Feature =>
               return Editor.Workspace_Persistence.Workspace_Diagnostics_Feature;
            when others =>
               return Editor.Workspace_Persistence.Workspace_Outline_Feature;
         end case;
      end Workspace_Feature;

      function Workspace_Quick_Filter
        (Filter : Editor.Quick_Open.Quick_Open_File_Kind_Filter)
         return Editor.Workspace_Persistence.Workspace_Quick_Open_File_Kind_Filter
      is
      begin
         case Filter is
            when Editor.Quick_Open.Ada_Files =>
               return Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files;
            when Editor.Quick_Open.Test_Files =>
               return Editor.Workspace_Persistence.Workspace_Quick_Open_Test_Files;
            when Editor.Quick_Open.Doc_Files =>
               return Editor.Workspace_Persistence.Workspace_Quick_Open_Doc_Files;
            when Editor.Quick_Open.Other_Files =>
               return Editor.Workspace_Persistence.Workspace_Quick_Open_Other_Files;
            when Editor.Quick_Open.All_Files =>
               return Editor.Workspace_Persistence.Workspace_Quick_Open_All_Files;
         end case;
      end Workspace_Quick_Filter;
   begin
      Editor.Workspace_Persistence.Clear (Snapshot);

      if Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Editor.Workspace_Persistence.Set_Project_Root
           (Snapshot, Editor.Project.Root_Path (S.Project_Runtime.Project));
      end if;

      Editor.Workspace_Persistence.Set_File_Tree_Panel
        (Snapshot,
         Editor.Panels.Is_Visible (S.Panel.Panels, Editor.Panels.File_Tree_Panel),
         Editor.Panels.Current_Size (S.Panel.Panels, Editor.Panels.File_Tree_Panel));

      Editor.Workspace_Persistence.Set_Bottom_Panel
        (Snapshot,
         Editor.Panels.Is_Visible (S.Panel.Panels, Editor.Panels.Bottom_Panel),
         Editor.Panels.Current_Size (S.Panel.Panels, Editor.Panels.Bottom_Panel),
         (if Editor.Panels.Active_Bottom_Content (S.Panel.Panels) =
               Editor.Panels.Search_Results_Content
          then Editor.Workspace_Persistence.Workspace_Search_Results_Content
          else Editor.Workspace_Persistence.Workspace_Problems_Content));

      if Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Editor.Workspace_Persistence.Set_Recent_Project_Path
           (Snapshot, Editor.Project.Root_Path (S.Project_Runtime.Project));
      elsif S.Project_Runtime.Recent_Project_Selected_Index in
        1 .. Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects)
      then
         Editor.Workspace_Persistence.Set_Recent_Project_Path
           (Snapshot,
            To_String
              (Editor.Recent_Projects.Item
                 (S.Project_Runtime.Recent_Projects,
                  S.Project_Runtime.Recent_Project_Selected_Index).Root_Path));
      elsif Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects) > 0 then
         Editor.Workspace_Persistence.Set_Recent_Project_Path
           (Snapshot,
            To_String
              (Editor.Recent_Projects.Item (S.Project_Runtime.Recent_Projects, 1).Root_Path));
      end if;

      Editor.Workspace_Persistence.Set_Quick_Open_Path_Scope
        (Snapshot, Editor.Quick_Open.Path_Scope (S.Surface.Quick_Open));
      Editor.Workspace_Persistence.Set_Quick_Open_File_Kind_Filter
        (Snapshot,
         Workspace_Quick_Filter
           (Editor.Quick_Open.File_Kind_Filter (S.Surface.Quick_Open)));
      Editor.Workspace_Persistence.Set_Feature_Panel
        (Snapshot,
         Editor.Feature_Panel.Is_Visible (S.Panel.Feature_Panel),
         Workspace_Feature (Editor.Feature_Panel.Active_Feature (S.Panel.Feature_Panel)));

      Registry := Editor.Buffers.Global_Registry_For_UI;
      for I in 1 .. Editor.Buffers.Count (Registry) loop
         Summary := Editor.Buffers.Summary_At (Registry, I);
         if Summary.Id /= Editor.Buffers.No_Buffer then
            Buffer := Editor.Buffers.Buffer (Registry, Summary.Id);
            if Buffer.Buffer_Lifecycle.File_Info.Has_Path and then Length (Buffer.Buffer_Lifecycle.File_Info.Path) > 0 then
               Path := Buffer.Buffer_Lifecycle.File_Info.Path;
               if Editor.Project.Has_Project (S.Project_Runtime.Project)
                 and then Editor.Project.Is_Under_Project (S.Project_Runtime.Project, To_String (Path))
               then
                  Rel_Path := To_Unbounded_String
                    (Editor.Project.Relative_Path (S.Project_Runtime.Project, To_String (Path)));
               else
                  Rel_Path := Null_Unbounded_String;
               end if;

               if Length (Rel_Path) > 0 then
                  if Buffer.Caret.Carets.Length > 0 then
                     Row_Col_For_Index
                       (Buffer,
                        Buffer.Caret.Carets (Buffer.Caret.Carets.First_Index).Pos,
                        Row,
                        Col);
                  else
                     Row := 0;
                     Col := 0;
                  end if;

                  Editor.Workspace_Persistence.Add_Open_File
                    (Snapshot,
                     (Path                => Rel_Path,
                      Is_Project_Relative => True,
                      Cursor_Row          => Row,
                      Cursor_Column       => Col,
                      View_First_Row      => 0));

                  if Summary.Id = Editor.Buffers.Active_Buffer (Registry) then
                     Editor.Workspace_Persistence.Set_Active_File_Path
                       (Snapshot, To_String (Rel_Path), True);
                  end if;
               end if;
            end if;
         end if;
      end loop;

      for I in 1 .. Editor.File_Tree.Node_Count (S.Surface.File_Tree) loop
         if Editor.File_Tree.Contains
           (S.Surface.File_Tree, Editor.File_Tree.File_Tree_Node_Id (I))
         then
            Node := Editor.File_Tree.Node
              (S.Surface.File_Tree, Editor.File_Tree.File_Tree_Node_Id (I));
            if Node.Kind = Editor.File_Tree.Directory_Node
              and then Node.Is_Expanded
              and then Length (Node.Relative_Path) > 0
            then
               Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path
                 (Snapshot, To_String (Node.Relative_Path));
            end if;
         end if;
      end loop;

      if not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot)
        and then S.Buffer_Lifecycle.File_Info.Has_Path
        and then Editor.Project.Has_Project (S.Project_Runtime.Project)
        and then Editor.Project.Is_Under_Project
          (S.Project_Runtime.Project, To_String (S.Buffer_Lifecycle.File_Info.Path))
      then
         Editor.Workspace_Persistence.Set_Active_File_Path
           (Snapshot,
            Editor.Project.Relative_Path (S.Project_Runtime.Project, To_String (S.Buffer_Lifecycle.File_Info.Path)),
            True);
      end if;

      return Snapshot;
   end Build_Workspace_Snapshot;

end Editor.State;
