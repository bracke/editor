with Editor.State_Buffer;
with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Shared_Services;
with Editor.Feature_Diagnostics;
with Editor.Files;
use type Editor.Files.File_Save_Status;
with Editor.Outline;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.Settings;
with Editor.State;
with Editor.View;

package body Editor.Executor.File_Save_As_Commands is

   procedure Clear_Dirty_Close_Prompt
     (S : in out Editor.State.State_Type) renames
       Editor.Executor.Buffer_Close_Prompt_Commands.Clear_Dirty_Close_Prompt;

   procedure Clear_File_Conflict_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      S.File_Conflict_Prompt_Active := False;
      S.File_Conflict_Prompt_Buffer := 0;
      S.File_Conflict_Prompt_Path := Null_Unbounded_String;
      S.File_Conflict_Prompt_Display := Null_Unbounded_String;
      S.File_Conflict_Prompt_Kind := Editor.State.No_File_Conflict;
      S.File_Conflict_Prompt_Dirty := False;
      S.File_Conflict_Prompt_Buffer_Revision := 0;
      S.File_Conflict_Prompt_Token_Label := Null_Unbounded_String;
      S.File_Conflict_Close_After_Overwrite := False;
      S.File_Conflict_Close_After_Overwrite_Buffer := 0;
      S.File_Conflict_Close_After_Overwrite_Selected := False;
      S.File_Conflict_Close_After_Overwrite_All_Buffers := False;
   end Clear_File_Conflict_Prompt;

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

   function Active_Buffer_Save_Target_Available
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.State.Has_Active_Buffer (S);
   end Active_Buffer_Save_Target_Available;

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

   procedure Resolve_Active_Buffer_Save_As_Source
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);

      if Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
         if S.Active_Buffer_Token /= Natural (Editor.Buffers.Global_Active_Buffer) then
            Editor.Buffers.Load_Global_Active_Into_State (S);
         else
            Editor.Buffers.Sync_Global_Active_From_State (S);
         end if;
      end if;
   end Resolve_Active_Buffer_Save_As_Source;

   function Validate_Save_As_Target_Path
     (Path : String) return Boolean
   is
      Found    : Boolean := False;
      Existing : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      if Path'Length = 0 then
         return False;
      end if;

      Existing := Editor.Buffers.Global_Find_By_Path (Path, Found);
      return not Found or else Existing = Editor.Buffers.Global_Active_Buffer;
   end Validate_Save_As_Target_Path;

   function Serialize_Active_Buffer_Current_Text_For_Save_As
     (S : Editor.State.State_Type) return String
   is
   begin
      return Editor.State.Current_Text (S);
   end Serialize_Active_Buffer_Current_Text_For_Save_As;

   function Write_Active_Buffer_Text_To_Save_As_Target
     (S    : Editor.State.State_Type;
      Path : String) return Editor.Files.File_Save_Result
   is
   begin
      return Editor.Files.Save_File
        (Path     => Path,
         Contents => Serialize_Active_Buffer_Current_Text_For_Save_As (S));
   end Write_Active_Buffer_Text_To_Save_As_Target;

   procedure Update_Active_Buffer_Path_After_Save_As
     (S     : in out Editor.State.State_Type;
      Result : Editor.Files.File_Save_Result)
   is
   begin
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Path;
      S.File_Info.Display_Name := Result.Display_Name;
   end Update_Active_Buffer_Path_After_Save_As;

   procedure Update_Saved_Baseline_After_Save_As
     (S : in out Editor.State.State_Type)
   is
   begin
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
      Editor.State.Reset_Dirty_Line_Baseline (S);
   end Update_Saved_Baseline_After_Save_As;

   procedure Mark_Active_Buffer_Saved_As
     (S     : in out Editor.State.State_Type;
      Result : Editor.Files.File_Save_Result)
   is
   begin
      Update_Active_Buffer_Path_After_Save_As (S, Result);
      Update_Saved_Baseline_After_Save_As (S);
      Capture_Active_File_Token (S);
      Clear_File_Conflict_Prompt (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Mark_Active_Buffer_Saved_As;

   procedure Apply_Format_On_Save_If_Enabled
     (S : in out Editor.State.State_Type)
   is
      Cmd : Editor.Commands.Payloads.Command :=
        Editor.Commands.Payloads.Command_For_Id (Editor.Command_Ids.Command_Format_Buffer);
   begin
      if not Editor.Settings.Format_On_Save then
         return;
      end if;

      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Apply_Format_On_Save_If_Enabled;

   procedure File_Lifecycle_Invalidate_Derived_State
     (S      : in out Editor.State.State_Type;
      Reason : String)
   is
      pragma Unreferenced (Reason);
   begin
      Editor.Executor.Project_Search_Result_Commands
        .Refresh_Project_Search_After_File_Lifecycle (S);
      Editor.Executor.Semantic_Index_Commands
        .Rebuild_Language_Index_After_File_Lifecycle (S);
   end File_Lifecycle_Invalidate_Derived_State;

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Previous_File  : Editor.State_Buffer.File_State;
      Previous_Dirty : Boolean := False;
      Previous_Saved : Natural := 0;
      Previous_Valid : Boolean := False;
      Result         : Editor.Files.File_Save_Result;
      Parent_Missing : Boolean := False;
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);
      if S.File_Conflict_Prompt_Active
        or else (Editor.Executor.File_Lifecycle_Confirmation_Pending (S)
                 and then not S.Dirty_Close_Prompt_Active)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;
      Resolve_Active_Buffer_Save_As_Source (S);

      if not Active_Buffer_Save_Target_Available (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif Path'Length = 0 then
         Editor.Executor.Shared_Services.Report_Error (S, "No target path for Save As");
         return;
      elsif not Validate_Save_As_Target_Path (Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid Save As target");
         return;
      end if;

      Apply_Format_On_Save_If_Enabled (S);

      Previous_File := S.File_Info;
      Previous_Dirty := S.File_Info.Dirty;
      Previous_Saved := S.File_Info.Saved_Generation;
      Previous_Valid := S.File_Info.Baseline_Valid;

      Parent_Missing := Save_As_Target_Parent_Missing (Path);
      Result := Write_Active_Buffer_Text_To_Save_As_Target (S, Path);

      if Editor.Files.Is_Success (Result) then
         Mark_Active_Buffer_Saved_As (S, Result);
         Clear_Dirty_Close_Prompt (S);
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after save as");
         if Editor.Project.Has_Project (S.Project)
           and then Editor.Project.Is_Under_Project (S.Project, Path)
         then
            declare
               Tree_Result : Editor.File_Tree.File_Tree_Scan_Result;
               Selection_Disappeared : Boolean := False;
            begin
               Editor.Executor.Project_File_Index_Commands.Refresh_Project_File_State
                 (S, Tree_Result, Selection_Disappeared, False);
            end;
         end if;
         Editor.Executor.Project_Search_Result_Commands
           .Refresh_Project_Search_After_File_Lifecycle (S);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Saved file as");
      else
         S.File_Info := Previous_File;
         S.File_Info.Dirty := Previous_Dirty;
         S.File_Info.Saved_Generation := Previous_Saved;
         S.File_Info.Baseline_Valid := Previous_Valid;
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

         if Result.Status = Editor.Files.File_Save_Is_Directory
           or else Result.Status = Editor.Files.File_Save_No_Current_Path
           or else
             (Result.Status = Editor.Files.File_Save_Invalid_Path
              and then not Parent_Missing)
         then
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid Save As target");
         elsif Result.Status = Editor.Files.File_Save_Parent_Unavailable
           or else Parent_Missing
         then
            Editor.Executor.Shared_Services.Report_Error (S, "Could not save file as");
         elsif Result.Status = Editor.Files.File_Save_Permission_Denied then
            Editor.Executor.Shared_Services.Report_Error (S, "Could not save file as");
         else
            Editor.Executor.Shared_Services.Report_Error (S, "Could not save file as");
         end if;
      end if;
   end Execute_Save_As;

end Editor.Executor.File_Save_As_Commands;
