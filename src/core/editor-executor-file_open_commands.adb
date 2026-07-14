with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Buffer_Switcher;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Feature_Messages;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Files;
use type Editor.Files.File_Copy_Status;
use type Editor.Files.File_Move_Status;
use type Editor.Files.File_Open_Status;
use type Editor.Files.File_Rename_Status;
use type Editor.Files.File_Save_Status;
use type Editor.Files.File_Delete_Status;
use type Editor.Files.File_External_Change_Status;
with Editor.History;
with Editor.Input_Field;
with Editor.Message_Producers;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Outline;
with Editor.Panels;
use type Editor.Panels.Bottom_Panel_Content;
with Editor.Pending_Transitions;
use type Editor.Pending_Transitions.Pending_Transition_Kind;
with Editor.Problems;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Recent_Buffers;
with Editor.Recent_Projects;
with Editor.Render_Cache;
with Editor.Search;
with Editor.Settings;
with Editor.State;
use type Editor.State.Dirty_Close_Scope;
use type Editor.State.File_Conflict_Kind;
with Editor.View;
with Editor.Build_UI;

package body Editor.Executor.File_Open_Commands is

   use Editor.Commands;

   function File_Open_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Command_New_Buffer =>
            return Editor.Commands.Available;

         when Command_Open_File | Command_Switch_Buffer =>
            return Editor.Commands.Unavailable ("Command not available here");

         when Command_Reopen_Closed_Buffer =>
            if not S.Has_Reopen_Candidate
              or else Length (S.Reopen_Candidate_Path) = 0
            then
               return Editor.Commands.Unavailable ("No closed buffer to reopen");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a file open command");
      end case;
   end File_Open_Command_Availability;

   procedure Capture_Active_File_Token
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Label : Unbounded_String := Null_Unbounded_String;
   begin
      if S.File_Info.Has_Path and then Length (S.File_Info.Path) > 0 then
         Label := To_Unbounded_String
           (Editor.Files.Current_Token_Label (To_String (S.File_Info.Path), Found));
      end if;
      S.File_Info.File_Token_Known := Found;
      S.File_Info.File_Token_Label := Label;
   end Capture_Active_File_Token;

   procedure Execute_Open_File
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Result : Editor.Files.File_Open_Result;
      Found  : Boolean := False;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Preserve_Open_Find_State : Boolean := False;

      function Same_File_Path (Left, Right : String) return Boolean is
      begin
         return Left = Right
           or else Editor.Files.Canonical_Path_For_Existing_File (Left) =
             Editor.Files.Canonical_Path_For_Existing_File (Right);
      end Same_File_Path;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;

      procedure Load_Global_Active_Preserving_Language_Index is
         Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
           S.Language_Index;
         Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
           S.Language_Service;
      begin
         Editor.Buffers.Load_Global_Active_Into_State (S);
         S.Language_Index := Saved_Index;
         S.Language_Service := Saved_Service;
      end Load_Global_Active_Preserving_Language_Index;

      procedure Clear_Explicit_Open_Find_State is
      begin
         if Preserve_Open_Find_State then
            Editor.Input_Field.Set_Text
              (S.Active_Find_Input, To_String (S.Active_Find_Query));
            S.Active_Find_Matches.Clear;
            S.Active_Find_Match := Editor.Search.No_Match;
            S.Active_Find_Stale := Length (S.Active_Find_Query) > 0;
            S.Active_Find_Wrapped := False;
            S.Active_Find_Source_Buffer_Token := 0;
            S.Active_Replace_Error_Message := Null_Unbounded_String;
            return;
         end if;

         Editor.Input_Field.Clear (S.Active_Find_Input);
         S.Active_Find_Query := Null_Unbounded_String;
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := False;
         S.Active_Find_Wrapped := False;
         S.Active_Find_Case_Sensitive := False;
         S.Active_Find_Whole_Word := False;
         S.Active_Find_Source_Buffer_Token := 0;
         S.Active_Find_Prompt := False;
         S.Active_Replace_Prompt := False;
         S.Active_Replace_Text := Null_Unbounded_String;
         S.Active_Replace_Error_Message := Null_Unbounded_String;
         if Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
         then
            Editor.Overlay_Focus.Dismiss
              (S.Overlay_Focus, Editor.Overlay_Focus.Dismiss_Command);
         end if;
      end Clear_Explicit_Open_Find_State;
   begin
      --  a direct explicit open/focus action is ordinary user
      --  interaction.  It must replace current restore-only Status Bar
      --  feedback while leaving historical restore Messages in the log.
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      --  Keep any existing registry entry current, but do not create a new
      --  registry entry before the file has been read successfully.  Failed
      --  opens must preserve the existing open-buffer list exactly.
      Editor.Buffers.Sync_Global_Active_From_State (S);
      if Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
         Editor.Recent_Buffers.Mark_Activated
           (S.Recent_Buffers, Natural (Editor.Buffers.Global_Active_Buffer));
      end if;

      if S.File_Info.Has_Path
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
        and then Same_File_Path (To_String (S.File_Info.Path), Path)
      then
         --  Explicit open/focus is a command boundary.  Capture a missing
         --  token only as metadata; do not reload disk or change dirty text.
         if not S.File_Info.File_Token_Known then
            Capture_Active_File_Token (S);
            Editor.Buffers.Sync_Global_Active_From_State (S);
         end if;
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Recent_Buffers.Mark_Activated
           (S.Recent_Buffers, Natural (Editor.Buffers.Global_Active_Buffer));
         Editor.Executor.Shared_Services.Report_Info_Append (S,
            "Focused existing buffer " & To_String (S.File_Info.Display_Name)
            & "; disk was not reloaded");
         return;
      end if;

      Id := Editor.Buffers.Global_Find_By_Path (Path, Found);
      if Found then
         Editor.Buffers.Global_Set_Active_Buffer (Id);
         Load_Global_Active_Preserving_Language_Index;
         if not S.File_Info.File_Token_Known then
            Capture_Active_File_Token (S);
            Editor.Buffers.Sync_Global_Active_From_State (S);
         end if;
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
         Editor.Executor.Shared_Services.Report_Info_Append (S,
            "Focused existing buffer " & To_String (S.File_Info.Display_Name)
            & "; disk was not reloaded");
         return;
      end if;

      Result := Editor.Files.Open_File (Path);
      if Editor.Files.Is_Success (Result) then
         --  the first explicit file open should replace the
         --  disposable initial empty untitled editor state.  Preserve any
         --  real existing buffer state, including dirty untitled work, before
         --  adding later file-backed buffers.
         if Current_State_Is_Disposable_Initial_Untitled then
            if Editor.Buffers.Global_Count = 1 then
               declare
                  Active : constant Editor.Buffers.Buffer_Id :=
                    Editor.Buffers.Global_Active_Buffer;
                  Closed : Boolean := False;
               begin
                  if Active /= Editor.Buffers.No_Buffer then
                     Editor.Buffers.Global_Force_Close_Buffer (Active, Closed);
                     if Closed then
                        S.Active_Buffer_Token := 0;
                     end if;
                  end if;
               end;
            end if;
         else
            Editor.Buffers.Ensure_Global_Registry (S);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            if Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
               Editor.Recent_Buffers.Mark_Activated
                 (S.Recent_Buffers, Natural (Editor.Buffers.Global_Active_Buffer));
            end if;
         end if;

         Preserve_Open_Find_State :=
           Editor.Buffers.Global_Registry_Current_For (S)
           and then Editor.Buffers.Global_Count > 0
           and then S.File_Info.Has_Path;

         Id := Editor.Buffers.Global_Find_By_Path (To_String (Result.Path), Found);
         if Found then
            Editor.Buffers.Global_Set_Active_Buffer (Id);
            Load_Global_Active_Preserving_Language_Index;
            if not S.File_Info.File_Token_Known then
               Capture_Active_File_Token (S);
               Editor.Buffers.Sync_Global_Active_From_State (S);
            end if;
            Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
            Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
            Editor.Executor.Shared_Services.Report_Info_Append (S,
               "Focused existing buffer " & To_String (S.File_Info.Display_Name)
               & "; disk was not reloaded");
            return;
         end if;

         Editor.Buffers.Global_Add_File_Buffer
           (Path         => To_String (Result.Path),
            Display_Name => To_String (Result.Display_Name),
            Contents     => To_String (Result.Contents),
            New_Id       => Id);
         Load_Global_Active_Preserving_Language_Index;
         Clear_Explicit_Open_Find_State;
         --  successful command-boundary reads capture the
         --  best-effort file identity token immediately.  Without this, a
         --  freshly opened file-backed buffer would have no known baseline
         --  token and save could fall back to pre-conflict behavior.
         Capture_Active_File_Token (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
         Editor.Executor.Shared_Services.Report_Success (S, "Opened " & To_String (Result.Display_Name));
      else
         Editor.Executor.Shared_Services.Report_Error (S, "Open failed: " & Editor.Files.Status_Message (Result));
         Editor.Message_Producers.Post_Message
           (S,
            Editor.Feature_Messages.Error_Message,
            "Could not open file — " & Path,
            Path,
            Editor.Feature_Messages.File_Source);
      end if;
   end Execute_Open_File;

   procedure Execute_New_Buffer
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Had_Current_Buffers : constant Boolean :=
        Editor.Buffers.Global_Registry_Current_For (S)
        and then Editor.Buffers.Global_Count > 0;
      Disposable_Initial : constant Boolean :=
        not Had_Current_Buffers
        and then not S.File_Info.Has_Path
        and then not S.File_Info.Dirty
        and then Editor.State.Current_Text (S) = "";

      procedure Load_Global_Active_Preserving_Language_Index is
         Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
           S.Language_Index;
         Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
           S.Language_Service;
      begin
         Editor.Buffers.Load_Global_Active_Into_State (S);
         S.Language_Index := Saved_Index;
         S.Language_Service := Saved_Service;
      end Load_Global_Active_Preserving_Language_Index;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);

      if Had_Current_Buffers or else not Disposable_Initial then
         Editor.Buffers.Sync_Global_Active_From_State (S);
         if Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
            Editor.Recent_Buffers.Mark_Activated
              (S.Recent_Buffers, Natural (Editor.Buffers.Global_Active_Buffer));
         end if;
         Editor.Buffers.Global_Add_Untitled_Buffer (Id);
         Load_Global_Active_Preserving_Language_Index;
      elsif Editor.Buffers.Global_Count = 0 then
         Editor.Buffers.Global_Add_Untitled_Buffer (Id);
         Load_Global_Active_Preserving_Language_Index;
      else
         Id := Editor.Buffers.Global_Active_Buffer;
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      if Id /= Editor.Buffers.No_Buffer then
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
      end if;
      Editor.Executor.Shared_Services.Report_Info (S, "New buffer");
   end Execute_New_Buffer;

   procedure Execute_Switch_Buffer
     (S                : in out Editor.State.State_Type;
      Id               : Editor.Buffers.Buffer_Id;
      Recent_Traversal : Boolean := False;
      Emit_Feedback    : Boolean := True)
   is
      Before_Location : constant Editor.Navigation_History.Navigation_Location :=
        Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Buffer_Switch);

      function Active_Message_Is_Non_Info return Boolean is
         Found : Boolean := False;
         M     : constant Editor.Messages.Editor_Message :=
           Editor.Messages.Active_Message (S.Messages, Found);
      begin
         return Found and then M.Severity /= Editor.Messages.Info_Message;
      end Active_Message_Is_Non_Info;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if not Editor.Buffers.Global_Contains (Id) then
         Editor.Executor.Shared_Services.Report_Error (S, "Switch buffer failed: invalid buffer");
         return;
      end if;

      Editor.Buffers.Sync_Global_Active_From_State (S);

      if Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
         Editor.Recent_Buffers.Mark_Activated
           (S.Recent_Buffers, Natural (Editor.Buffers.Global_Active_Buffer),
            Preserve_Traversal => Recent_Traversal);
      end if;

      if Id = Editor.Buffers.Global_Active_Buffer then
         Editor.Recent_Buffers.Mark_Activated
           (S.Recent_Buffers, Natural (Id), Preserve_Traversal => Recent_Traversal);
         return;
      end if;

      declare
         Old_Id : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Active_Buffer;
      begin
         if Old_Id /= Editor.Buffers.No_Buffer then
            Editor.Outline.Remember_Filter_For_Buffer (S.Outline, Natural (Old_Id));
         end if;
      end;
      Editor.Buffers.Global_Set_Active_Buffer (Id);
      declare
         Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
           S.Language_Index;
         Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
           S.Language_Service;
      begin
         Editor.Buffers.Load_Global_Active_Into_State (S);
         S.Language_Index := Saved_Index;
         S.Language_Service := Saved_Service;
      end;
      Editor.Executor.Record_Navigation_If_Current_Changed (S, Before_Location);
      Editor.Recent_Buffers.Mark_Activated
        (S.Recent_Buffers, Natural (Id), Preserve_Traversal => Recent_Traversal);
      Editor.Outline.Deactivate_Filter_Input (S.Outline);
      if Editor.Outline.Restore_Filter_For_Buffer (S.Outline, Natural (Id)) then
         Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      end if;
      if Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        and then Editor.Panels.Active_Bottom_Content (S.Panels) =
          Editor.Panels.Problems_Content
      then
         declare
            Snapshot : constant Editor.Problems.Problems_Snapshot :=
              Editor.Problems.Build_Snapshot (S.Diagnostics);
         begin
            Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Snapshot);
         end;
      end if;
      if Emit_Feedback and then not Active_Message_Is_Non_Info then
         Editor.Executor.Shared_Services.Report_Info (S, "Switched to " & To_String (S.File_Info.Display_Name));
      end if;
   end Execute_Switch_Buffer;

   procedure Sync_Reopen_Candidate_Top
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Has_Reopen_Candidate := S.Reopen_Candidate_Count > 0;
      if S.Has_Reopen_Candidate then
         S.Reopen_Candidate_Path := S.Reopen_Candidate_Paths (1);
         S.Reopen_Candidate_Label := S.Reopen_Candidate_Labels (1);
      else
         S.Reopen_Candidate_Path := Null_Unbounded_String;
         S.Reopen_Candidate_Label := Null_Unbounded_String;
      end if;
   end Sync_Reopen_Candidate_Top;

   procedure Clear_Reopen_Candidate
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Reopen_Candidate_Count := 0;
      for I in Editor.State.Reopen_Candidate_Index loop
         S.Reopen_Candidate_Paths (I) := Null_Unbounded_String;
         S.Reopen_Candidate_Labels (I) := Null_Unbounded_String;
      end loop;
      Sync_Reopen_Candidate_Top (S);
   end Clear_Reopen_Candidate;

   procedure Pop_Reopen_Candidate
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.Reopen_Candidate_Count = 0 then
         Sync_Reopen_Candidate_Top (S);
         return;
      end if;

      for I in 1 .. Editor.State.Max_Reopen_Candidates - 1 loop
         S.Reopen_Candidate_Paths (I) := S.Reopen_Candidate_Paths (I + 1);
         S.Reopen_Candidate_Labels (I) := S.Reopen_Candidate_Labels (I + 1);
      end loop;
      S.Reopen_Candidate_Paths (Editor.State.Max_Reopen_Candidates) :=
        Null_Unbounded_String;
      S.Reopen_Candidate_Labels (Editor.State.Max_Reopen_Candidates) :=
        Null_Unbounded_String;
      S.Reopen_Candidate_Count := S.Reopen_Candidate_Count - 1;
      Sync_Reopen_Candidate_Top (S);
   end Pop_Reopen_Candidate;

   procedure Register_Reopen_Candidate_After_Close
     (S     : in out Editor.State.State_Type;
      Path  : String;
      Label : String)
   is
      Limit : constant Natural := Editor.State.Max_Reopen_Candidates;
   begin
      --  the reopen stack is deliberately path-only runtime
      --  state.  It is registered only after a successful associated close
      --  and stores no text, dirty content, Undo/Redo, selection/caret,
      --  Find/Replace, Clipboard, Navigation History, Text Feed_Item, render, or
      --  message state.
      if Path'Length = 0 then
         return;
      end if;

      for I in reverse 2 .. Limit loop
         S.Reopen_Candidate_Paths (I) := S.Reopen_Candidate_Paths (I - 1);
         S.Reopen_Candidate_Labels (I) := S.Reopen_Candidate_Labels (I - 1);
      end loop;
      S.Reopen_Candidate_Paths (1) := To_Unbounded_String (Path);
      S.Reopen_Candidate_Labels (1) := To_Unbounded_String (Label);
      if S.Reopen_Candidate_Count < Limit then
         S.Reopen_Candidate_Count := S.Reopen_Candidate_Count + 1;
      end if;
      Sync_Reopen_Candidate_Top (S);
   end Register_Reopen_Candidate_After_Close;

   function Reopen_Target_Is_Active
     (S    : Editor.State.State_Type;
      Path : String) return Boolean
   is
      Active_Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
   begin
      if Path'Length = 0 or else Active_Path'Length = 0 then
         return False;
      end if;

      if Active_Path = Path then
         return True;
      end if;

      return Editor.Files.Canonical_Path_For_Existing_File (Active_Path) =
        Editor.Files.Canonical_Path_For_Existing_File (Path);
   exception
      when others =>
         return False;
   end Reopen_Target_Is_Active;

   procedure Execute_Reopen_Closed_Buffer
     (S : in out Editor.State.State_Type)
   is
      Candidate_Path  : constant String := To_String (S.Reopen_Candidate_Path);
      Candidate_Label : constant String := To_String (S.Reopen_Candidate_Label);
      Display         : constant String :=
        (if Candidate_Label'Length > 0 then Candidate_Label else Candidate_Path);
   begin
      --  this is the only executable reopen path.  It consumes a
      --  transient path/reference candidate produced by successful clean
      --  associated close, delegates all new-open and duplicate-open behavior to
      --  canonical file-open, and never restores close-time text, dirty text,
      --  Undo/Redo, caret/selection, Find/Replace, Navigation, Text Feed_Item, or
      --  render state.
      if not S.Has_Reopen_Candidate or else Candidate_Path'Length = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No closed buffer to reopen");
         return;
      end if;

      if not Ada.Directories.Exists (Candidate_Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Could not reopen closed buffer");
         return;
      end if;

      Execute_Open_File (S, Candidate_Path);
      Editor.Messages.Dismiss_Latest (S.Messages);

      if Reopen_Target_Is_Active (S, Candidate_Path) then
         Pop_Reopen_Candidate (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Reopened " & Display);
      else
         --  Failed canonical open/read attempts preserve the candidate so a
         --  later retry can succeed after the filesystem condition is fixed.
         Editor.Executor.Shared_Services.Report_Error (S, "Could not reopen closed file");
      end if;
   end Execute_Reopen_Closed_Buffer;

   procedure Candidate_For_Closed_Associated_Buffer
     (Id       : Editor.Buffers.Buffer_Id;
      Has_Path : out Boolean;
      Path     : out Unbounded_String;
      Label    : out Unbounded_String)
   is
   begin
      Has_Path := False;
      Path := Null_Unbounded_String;
      Label := Null_Unbounded_String;

      if Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Id)
      then
         return;
      end if;

      declare
         Summary : constant Editor.Buffers.Buffer_Summary :=
           Editor.Buffers.Global_Summary_For (Id);
      begin
         if Summary.Has_Path and then Length (Summary.Path) > 0 then
            Has_Path := True;
            Path := Summary.Path;
            Label := Summary.Display_Name;
         end if;
      end;
   end Candidate_For_Closed_Associated_Buffer;

end Editor.Executor.File_Open_Commands;
