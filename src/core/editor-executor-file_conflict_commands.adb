with Text_Buffer;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Cursors;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Shared_Services;
with Editor.Feature_Diagnostics;
with Editor.Feature_Messages;
with Editor.Files;
use type Editor.Files.File_External_Change_Status;
use type Editor.Files.File_Open_Status;
use type Editor.Files.File_Save_Status;
with Editor.History;
with Editor.Project;
with Editor.Outline;
with Editor.Project_Search;
with Editor.Build_UI;
with Editor.State;
with Editor.View;

package body Editor.Executor.File_Conflict_Commands is

   function Natural_Text
     (Value : Natural) return String
   is
      Image : constant String := Natural'Image (Value);
   begin
      return Image (Image'First + 1 .. Image'Last);
   end Natural_Text;

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

   procedure Apply_Reloaded_Text_After_Read
     (S        : in out Editor.State.State_Type;
      Contents : Unbounded_String)
   is
      procedure Set_Reloaded_Text (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Set_Text (B, To_String (Contents));
      end Set_Reloaded_Text;
   begin
      Editor.State.Mutate_Buffer (S, Set_Reloaded_Text'Access);
   end Apply_Reloaded_Text_After_Read;

   procedure Apply_Reload_Buffer_Local_Lifecycle
     (S : in out Editor.State.State_Type) is
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      S.Preferred_Column := 0;
      S.Rect_Select_Active := False;
      S.Rect_Anchor_Row := 0;
      S.Rect_Anchor_Col := 0;
      Editor.View.Reset_Scroll;
   end Apply_Reload_Buffer_Local_Lifecycle;

   procedure File_Lifecycle_Invalidate_Derived_State
     (S      : in out Editor.State.State_Type;
      Reason : String)
   is
      Source_Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
      Relative_Path : constant String :=
        (if Source_Path'Length > 0
           and then Editor.Project.Has_Project (S.Project)
           and then Editor.Project.Is_Under_Project (S.Project, Source_Path)
         then Editor.Project.Relative_Path (S.Project, Source_Path)
         else "");
   begin
      S.Active_Find_Stale := True;
      Editor.Outline.Clear (S.Outline);
      S.Outline_Cursor_Key_Valid := False;
      Editor.Project_Search.Mark_Stale_Unconditionally (S.Project_Search);
      Editor.Project_Search.Mark_Replace_Preview_Stale (S.Project_Search);
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale
        (S.Feature_Diagnostics, S.Active_Buffer_Token);

      if Source_Path'Length > 0 then
         Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
           (S.Feature_Diagnostics, Source_Path, Source_Path);
      end if;

      if Relative_Path'Length > 0 then
         Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
           (S.Feature_Diagnostics, Relative_Path, Relative_Path);
      end if;

      if Source_Path'Length > 0 then
         Editor.Ada_Project_Index.Invalidate_Path (S.Language_Index, Source_Path);
         Editor.Ada_Language_Service.Invalidate_Path
           (S.Language_Service, Source_Path);
      end if;
      if S.Active_Buffer_Token /= 0 then
         Editor.Ada_Project_Index.Invalidate_Buffer
           (S.Language_Index, S.Active_Buffer_Token);
         Editor.Ada_Language_Service.Invalidate_Buffer
           (S.Language_Service, S.Active_Buffer_Token);
      end if;

      if To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0 then
         S.Build_UI.Selected_Candidate_Stale := True;
         S.Build_UI.Consent_Acknowledged := False;
         S.Build_UI.Pending_Public_Build_Request := False;
         S.Build_UI.Candidate_Selection_Message := To_Unbounded_String (Reason);
         S.Build_UI.Validation_Status :=
           Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale;
         S.Build_UI.Validation_Message := To_Unbounded_String
           (Editor.Build_UI.Validation_Message
              (Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale));
      end if;
   end File_Lifecycle_Invalidate_Derived_State;

   procedure Update_Saved_Baseline_After_Reload
     (S              : in out Editor.State.State_Type;
      Reload_Path    : Unbounded_String;
      Reload_Display : Unbounded_String)
   is
   begin
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Reload_Path;
      S.File_Info.Display_Name := Reload_Display;
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Blocked_Close_Surfaced := False;
      Capture_Active_File_Token (S);
      Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Update_Saved_Baseline_After_Reload;

   procedure Mark_Active_Buffer_Saved_After_Overwrite
     (S      : in out Editor.State.State_Type;
      Result : Editor.Files.File_Save_Result)
   is
   begin
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Path;
      S.File_Info.Display_Name := Result.Display_Name;
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Blocked_Close_Surfaced := False;
      Capture_Active_File_Token (S);
      Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Mark_Active_Buffer_Saved_After_Overwrite;

   procedure Execute_File_Conflict_Cancel
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
      Editor.Executor.Shared_Services.Report_Info (S, "File conflict cancelled");
   end Execute_File_Conflict_Cancel;

   procedure Execute_File_Conflict_Keep_Buffer
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Executor.File_Save_Commands.File_Conflict_Prompt_Is_Valid (S) then
         Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
         Editor.Executor.Shared_Services.Report_Warning (S, "Conflict prompt is stale");
         return;
      end if;
      Editor.Executor.File_Save_Commands.Load_File_Conflict_Buffer (S);
      Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Shared_Services.Report_Info (S, "Kept buffer changes; file remains conflicted");
   end Execute_File_Conflict_Keep_Buffer;

   procedure Execute_File_Conflict_Reload_From_Disk
     (S : in out Editor.State.State_Type)
   is
      Result : Editor.Files.File_Open_Result;
      Reload_Path    : Unbounded_String;
      Reload_Display : Unbounded_String;
   begin
      if not Editor.Executor.File_Save_Commands.File_Conflict_Prompt_Is_Valid (S) then
         Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
         Editor.Executor.Shared_Services.Report_Warning (S, "Conflict prompt is stale");
         return;
      end if;
      Editor.Executor.File_Save_Commands.Load_File_Conflict_Buffer (S);
      Reload_Path := S.File_Info.Path;
      Reload_Display := S.File_Info.Display_Name;
      Result := Editor.Files.Open_File (To_String (S.File_Info.Path));
      if not Editor.Files.Is_Success (Result) then
         S.File_Info.Last_Reload_Failed := True;
         S.File_Info.Missing_Target_Surfaced :=
           Result.Status = Editor.Files.File_Open_Not_Found;
         S.File_Info.Unreadable_Target_Surfaced :=
           Result.Status in Editor.Files.File_Open_Permission_Denied
             | Editor.Files.File_Open_Read_Error
             | Editor.Files.File_Open_Decode_Error
             | Editor.Files.File_Open_Is_Directory
             | Editor.Files.File_Open_Invalid_Path;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Error (S, "Could not reload file; buffer unchanged");
         return;
      end if;
      Apply_Reloaded_Text_After_Read (S, Result.Contents);
      Apply_Reload_Buffer_Local_Lifecycle (S);
      Update_Saved_Baseline_After_Reload (S, Reload_Path, Reload_Display);
      Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
      File_Lifecycle_Invalidate_Derived_State
        (S, "Derived state is stale after reload");
      Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
      Editor.Executor.Shared_Services.Report_Success (S, "File reloaded from disk");
   end Execute_File_Conflict_Reload_From_Disk;

   procedure Resume_Close_After_Overwrite
     (S              : in out Editor.State.State_Type;
      Resume_Buffer   : Editor.Buffers.Buffer_Id;
      Resume_Selected : Boolean;
      Resume_All      : Boolean;
      Closed          : out Boolean)
   is
   begin
      Closed := False;
      if Resume_Buffer /= Editor.Buffers.No_Buffer
        and then Editor.Buffers.Global_Contains (Resume_Buffer)
      then
         Editor.Executor.Buffer_Close_Prompt_Commands.Close_Buffer_By_Discard
           (S, Resume_Buffer, Closed);
         if Resume_Selected then
            Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
            Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
         end if;
         if Resume_All then
            declare
               Remaining : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
                 Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Buffer_Summary_For_All_Buffers
                   (S.Project);
            begin
               if Remaining.Dirty_Count > 0 then
                  Editor.Executor.Buffer_Close_Prompt_Commands.Start_Dirty_Close_Prompt
                    (S, Editor.State.All_Buffers_Close_Scope, True,
                     Editor.Buffers.No_Buffer, Remaining);
                  Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Confirm_Close_Save (S);
               else
                  Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Close_All_Buffers_Confirmed (S);
               end if;
            end;
         elsif Closed then
            Editor.Executor.Shared_Services.Report_Info (S, "Buffer closed");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No changes to overwrite");
         end if;
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No changes to overwrite");
      end if;
   end Resume_Close_After_Overwrite;

   procedure Execute_File_Conflict_Overwrite_Disk
     (S : in out Editor.State.State_Type)
   is
      Result : Editor.Files.File_Save_Result;
      Resume_Close    : Boolean := False;
      Resume_Buffer   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Resume_Selected : Boolean := False;
      Resume_All      : Boolean := False;
      Closed          : Boolean := False;
   begin
      if not Editor.Executor.File_Save_Commands.File_Conflict_Prompt_Is_Valid (S) then
         Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
         Editor.Executor.Shared_Services.Report_Warning (S, "Conflict prompt is stale");
         return;
      end if;

      Resume_Close := S.File_Conflict_Close_After_Overwrite;
      Resume_Buffer :=
        Editor.Buffers.Buffer_Id (S.File_Conflict_Close_After_Overwrite_Buffer);
      Resume_Selected := S.File_Conflict_Close_After_Overwrite_Selected;
      Resume_All := S.File_Conflict_Close_After_Overwrite_All_Buffers;

      Editor.Executor.File_Save_Commands.Load_File_Conflict_Buffer (S);
      if not S.File_Info.Dirty then
         Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
         if Resume_Close
           and then Resume_Buffer /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Global_Contains (Resume_Buffer)
         then
            Resume_Close_After_Overwrite
              (S, Resume_Buffer, Resume_Selected, Resume_All, Closed);
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No changes to overwrite");
         end if;
         return;
      end if;
      Result := Editor.Files.Save_File
        (Path     => To_String (S.File_Info.Path),
         Contents => Editor.State.Current_Text (S));
      if Editor.Files.Is_Success (Result) then
         Mark_Active_Buffer_Saved_After_Overwrite (S, Result);
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after overwrite");
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
         if Resume_Close
           and then Resume_Buffer /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Global_Contains (Resume_Buffer)
         then
            Resume_Close_After_Overwrite
              (S, Resume_Buffer, Resume_Selected, Resume_All, Closed);
         else
            Editor.Executor.Shared_Services.Report_Success (S, "Overwrite confirmed");
         end if;
      else
         S.File_Info.Last_Save_Failed := True;
         S.File_Info.Missing_Target_Surfaced :=
           Result.Status in Editor.Files.File_Save_No_Current_Path
             | Editor.Files.File_Save_Invalid_Path
             | Editor.Files.File_Save_Parent_Unavailable;
         S.File_Info.Unwritable_Target_Surfaced :=
           Result.Status in Editor.Files.File_Save_Permission_Denied
             | Editor.Files.File_Save_Write_Error
             | Editor.Files.File_Save_Is_Directory;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Error (S, "Overwrite failed; buffer remains dirty");
      end if;
   end Execute_File_Conflict_Overwrite_Disk;

end Editor.Executor.File_Conflict_Commands;
