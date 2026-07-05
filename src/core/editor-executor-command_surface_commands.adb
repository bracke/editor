with Ada.Containers;
use type Ada.Containers.Count_Type;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.IO_Exceptions;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Feature_Panel;
with Editor.Guided_Prompts;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;
with Editor.Project;
with Editor.Go_To_Line;
with Editor.Quick_Open;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
use type Editor.Quick_Open.Quick_Open_Priority_Mode;
with Editor.Quick_Open_Markers;
with Editor.Rectangle_Selection;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Command_Surface_Commands is

   function Command_Surface_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;

      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;

      function Active_Overlay_Is
        (Overlay : Editor.Overlay_Focus.Overlay_Target) return Boolean is
      begin
         return Editor.Overlay_Focus.Is_Active (S.Overlay_Focus, Overlay);
      end Active_Overlay_Is;

      function Quick_Open_Has_Selected_Result return Boolean is
      begin
         return Editor.Quick_Open.Result_Count (S.Quick_Open) > 0
           and then Editor.Quick_Open.Selected_Result_Index (S.Quick_Open) /= 0;
      end Quick_Open_Has_Selected_Result;

      function Normalize_Quick_Open_Project_Path
        (Text : String) return String
      is
         Result : String (Text'Range);
      begin
         for I in Text'Range loop
            if Text (I) = '\' then
               Result (I) := '/';
            else
               Result (I) := Text (I);
            end if;
         end loop;
         return Result;
      end Normalize_Quick_Open_Project_Path;

      function Quick_Open_Selected_File_Still_Known return Boolean is
         Found  : Boolean := False;
         Result : constant Editor.Quick_Open.Quick_Open_Result :=
           Editor.Quick_Open.Selected_Result (S.Quick_Open, Found);
         Label  : constant String := To_String (Result.Display_Path);
         Path   : constant String := To_String (Result.Absolute_Path);
      begin
         if not Found then
            return False;
         end if;

         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            declare
               File_Item : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
            begin
               if Normalize_Quick_Open_Project_Path
                 (To_String (File_Item.Relative_Path)) = Label
                 and then To_String (File_Item.Absolute_Path) = Path
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Quick_Open_Selected_File_Still_Known;
   begin
      case Id is
         when Command_Goto_Line
            | Command_Goto_Line_Toggle
            | Command_Open_Command_Palette
            | Command_Cancel =>
            return Editor.Commands.Available;

         when Command_Goto_Line_Prefill_Current =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0
              or else Editor.State.Line_Count (S) = 0
            then
               return Editor.Commands.Unavailable ("No current caret location");
            end if;
            return Editor.Commands.Available;

         when Command_Open_Quick_Open =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open.");
            end if;
            return Editor.Commands.Available;

         when Command_Toggle_Quick_Open =>
            if not Has_Project
              and then not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("No project open.");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Reveal_Active
            | Command_Quick_Open_Scope_Active_Directory =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif Editor.Project.Known_File_Count (S.Project) = 0 then
               return Editor.Commands.Unavailable ("No project files.");
            else
               declare
                  Found   : Boolean := False;
                  Ignored : constant String :=
                    Editor.Executor.Active_Buffer_Known_Project_File
                      (S, Found);
                  pragma Unreferenced (Ignored);
               begin
                  if not Found then
                     return Editor.Commands.Unavailable
                       ("Active buffer is not a known project file");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Priority_Toggle
            | Command_Quick_Open_Priority_Clear =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project.Root_Path (S.Project)'Length = 0 then
               return Editor.Commands.Unavailable ("No project open.");
            elsif not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif Ada.Strings.Fixed.Trim
              (Editor.Quick_Open.Query_Text (S.Quick_Open),
               Ada.Strings.Both)'Length = 0
            then
               return Editor.Commands.Unavailable ("No Quick Open query");
            end if;
            return Editor.Commands.Available;

         when Command_Palette_Show_Command_Help =>
            if not Editor.Command_Palette.Is_Open then
               return Editor.Commands.Unavailable ("Command Palette closed");
            end if;
            return Editor.Commands.Available;

         when Command_Close_Quick_Open =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Accept_Quick_Open =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Quick_Open_Has_Selected_Result then
               return Editor.Commands.Unavailable ("No Quick Open selection");
            elsif not Quick_Open_Selected_File_Still_Known then
               return Editor.Commands.Unavailable
                 ("Selected file is no longer in project");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Next_Result
            | Command_Quick_Open_Previous_Result =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
               if Editor.Project.Known_File_Count (S.Project) = 0 then
                  return Editor.Commands.Unavailable ("No project files");
               else
                  return Editor.Commands.Unavailable ("No Quick Open matches.");
               end if;
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Query_Set =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Query_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Quick_Open.Query_Text (S.Quick_Open)'Length = 0 then
               return Editor.Commands.Unavailable
                 ("No Quick Open query to clear");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Kind_Next
            | Command_Quick_Open_Kind_Previous =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Kind_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Quick_Open.File_Kind_Filter (S.Quick_Open) =
              Editor.Quick_Open.All_Files
            then
               return Editor.Commands.Unavailable
                 ("No Quick Open file-kind filter to clear");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Scope_Set =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Scope_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Quick_Open.Path_Scope (S.Quick_Open)'Length = 0 then
               return Editor.Commands.Unavailable
                 ("No Quick Open scope to clear");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Scope_From_Selected =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Quick_Open_Has_Selected_Result then
               return Editor.Commands.Unavailable ("No Quick Open selection");
            end if;
            return Editor.Commands.Available;

         when Command_Quick_Open_Scope_Parent =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Quick_Open.Path_Scope (S.Quick_Open)'Length = 0 then
               return Editor.Commands.Unavailable ("No Quick Open scope");
            end if;
            return Editor.Commands.Available;

         when Command_Goto_Line_Query_Set =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Go_To_Line_Overlay)
              or else not Editor.Go_To_Line.Is_Open (S.Go_To_Line)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Goto_Line_Query_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Go_To_Line_Overlay)
              or else not Editor.Go_To_Line.Is_Open (S.Go_To_Line)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Ada.Strings.Fixed.Trim
              (Editor.Go_To_Line.Text (S.Go_To_Line),
               Ada.Strings.Both)'Length = 0
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line)
            then
               return Editor.Commands.Unavailable
                 ("No go-to-line query to clear");
            end if;
            return Editor.Commands.Available;

         when Command_Close_Goto_Line
            | Command_Accept_Goto_Line =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Go_To_Line_Overlay)
              or else not Editor.Go_To_Line.Is_Open (S.Go_To_Line)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a command-surface command");
      end case;
   end Command_Surface_Command_Availability;

   procedure Execute_Open_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
   end Execute_Open_Goto_Line;

   procedure Execute_Close_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Close_Goto_Line (S);
   end Execute_Close_Goto_Line;

   procedure Execute_Toggle_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Toggle_Goto_Line (S);
   end Execute_Toggle_Goto_Line;

   procedure Execute_Prefill_Goto_Line_Current
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Prefill_Goto_Line_Current (S);
   end Execute_Prefill_Goto_Line_Current;

   procedure Execute_Accept_Goto_Line
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Accept_Goto_Line (S);
   end Execute_Accept_Goto_Line;

   procedure Execute_Goto_Line_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Goto_Line_Set_Query (S, Text);
   end Execute_Goto_Line_Set_Query;

   procedure Execute_Goto_Line_Clear_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Goto_Line_Clear_Query (S);
   end Execute_Goto_Line_Clear_Query;

   procedure Execute_Goto_Line_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Goto_Line_Insert_Text
        (S, Text);
   end Execute_Goto_Line_Insert_Text;

   procedure Execute_Goto_Line_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Goto_Line_Backspace (S);
   end Execute_Goto_Line_Backspace;

   procedure Execute_Goto_Line_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Navigation_Commands.Execute_Goto_Line_Delete_Forward (S);
   end Execute_Goto_Line_Delete_Forward;

   procedure Execute_Goto_Line_Move_Cursor_Left
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Go_To_Line.Move_Cursor_Left (S.Go_To_Line);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Goto_Line_Move_Cursor_Left;

   procedure Execute_Goto_Line_Move_Cursor_Right
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Go_To_Line.Move_Cursor_Right (S.Go_To_Line);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Goto_Line_Move_Cursor_Right;

   function Default_Quick_Open_Config return Editor.Quick_Open.Quick_Open_Config is
   begin
      return (others => <>);
   end Default_Quick_Open_Config;

   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, Default_Quick_Open_Config);
      Editor.Render_Cache.Invalidate_All;
   end Recompute_Quick_Open;


   procedure Execute_Open_Command_Palette
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Command_Palette_Overlay);
   end Execute_Open_Command_Palette;

   procedure Execute_Close_Command_Palette
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Command_Palette_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Command_Palette.Close;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Close_Command_Palette;

   procedure Execute_Palette_Show_Command_Help
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Command_Palette.Is_Open then
         Editor.Executor.Report_Info (S, "Command Palette closed.");
         return;
      end if;

      Editor.Command_Palette.Toggle_Show_Help_Row;
      Editor.Executor.Report_Info (S, "Command help display toggled");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Palette_Show_Command_Help;

   function Has_Primary_Selection
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      if S.Carets.Length = 0 then
         return False;
      else
         return Editor.Rectangle_Selection.Has_Selection
           (S.Carets (S.Carets.First_Index));
      end if;
   end Has_Primary_Selection;

   procedure Collapse_All_Selections
     (S : in out Editor.State.State_Type)
   is
      C : Editor.Cursors.Caret_State;
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

   function Execute_Command_Surface_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Command_Palette_Show_Command_Help =>
            if not Editor.Command_Palette.Is_Open then
               Editor.Executor.Report_Info (S, "Command Palette closed.");
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Execute_Palette_Show_Command_Help (S);
            return Editor.Command_Execution.Executed (Id);

         when Command_Cancel =>
            if S.Dirty_Close_Prompt_Active then
               Editor.Executor.File_Lifecycle_Commands.Execute_Cancel_Close (S);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif S.File_Conflict_Prompt_Active then
               Editor.Executor.File_Lifecycle_Commands.Clear_File_Conflict_Prompt (S);
               Editor.Executor.Report_Info (S, "File conflict cancelled");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif Editor.Guided_Prompts.Is_Active (S.Guided_Prompt) then
               Editor.Guided_Prompts.Cancel (S.Guided_Prompt);
               Editor.Executor.Report_Info (S, "Prompt cancelled.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus) then
               Editor.Executor.Dismiss_Active_Overlay
                 (S, Editor.Overlay_Focus.Dismiss_Escape);
               return Editor.Command_Execution.Cancelled (Id);
            elsif Editor.Feature_Panel.Is_Focused (S.Feature_Panel) then
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus)
              or else Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus)
            then
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif Has_Primary_Selection (S) then
               Collapse_All_Selections (S);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            else
               return Editor.Command_Execution.No_Op (Id);
            end if;

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Command_Surface_Result_Command;

   procedure Report_Quick_Open_Shown
     (S : in out Editor.State.State_Type)
   is
      Count : constant Natural := Editor.Quick_Open.Result_Count (S.Quick_Open);
   begin
      if Count = 0 then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
         elsif Editor.Project.Known_File_Count (S.Project) = 0 then
            Editor.Executor.Report_Info (S, "No project files");
         else
            Editor.Executor.Report_Info (S, "No Quick Open matches.");
         end if;
      else
         Editor.Executor.Report_Info (S, "Quick Open shown");
      end if;
   end Report_Quick_Open_Shown;

   procedure Execute_Open_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Quick_Open_Overlay);
      Recompute_Quick_Open (S);
      Report_Quick_Open_Shown (S);
   end Execute_Open_Quick_Open;

   procedure Execute_Close_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
         Editor.Render_Cache.Invalidate_All;
      end if;
      Editor.Executor.Report_Info (S, "Quick Open hidden");
   end Execute_Close_Quick_Open;

   procedure Execute_Toggle_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        and then Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Execute_Close_Quick_Open (S);
      else
         Execute_Open_Quick_Open (S);
      end if;
   end Execute_Toggle_Quick_Open;

   procedure Execute_Accept_Quick_Open
     (S : in out Editor.State.State_Type)
   is
      Found        : Boolean := False;
      Buffer_Found : Boolean := False;
      Existing_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      pragma Unreferenced (Existing_Id);
      Preflight    : Editor.Files.File_Open_Result;
      Result       : constant Editor.Quick_Open.Quick_Open_Result :=
        Editor.Quick_Open.Selected_Result (S.Quick_Open, Found);
      Path         : constant String := To_String (Result.Absolute_Path);
      Label        : constant String := To_String (Result.Display_Path);

      function Normalize_Project_Path (Text : String) return String is
         Result : String (Text'Range);
      begin
         for I in Text'Range loop
            if Text (I) = '\' then
               Result (I) := '/';
            else
               Result (I) := Text (I);
            end if;
         end loop;
         return Result;
      end Normalize_Project_Path;

      function Selected_File_Still_Known return Boolean is
      begin
         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            declare
               File_Item : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
            begin
               if Normalize_Project_Path (To_String (File_Item.Relative_Path)) = Label
                 and then To_String (File_Item.Absolute_Path) = Path
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Selected_File_Still_Known;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;
   begin
      --  accepting a Quick Open result is an ordinary open/focus
      --  action and should replace restore-only current feedback.
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No Quick Open selection");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if not Selected_File_Still_Known then
         Editor.Executor.Report_Error (S, "Selected file is no longer in project");
         Recompute_Quick_Open (S);
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Existing_Id := Editor.Buffers.Global_Find_By_Path (Path, Buffer_Found);
      if not Buffer_Found then
         --  Keep Quick Open visible and unchanged for open failures that the
         --  ordinary open path would report after attempting to read the file
         --  (missing, directory, unreadable, invalid encoding, and I/O errors).
         --  Existing open buffers skip this preflight so dirty/open state is
         --  never reloaded or inspected through the filesystem.
         Preflight := Editor.Files.Open_File (Path);
         if not Editor.Files.Is_Success (Preflight) then
            if Current_State_Is_Disposable_Initial_Untitled then
               S.Active_Buffer_Token := 0;
            end if;
            Editor.Executor.Report_Error (S, "Could not open " & Label & ": "
               & (case Preflight.Status is
                    when Editor.Files.File_Open_Not_Found => "file not found",
                    when Editor.Files.File_Open_Permission_Denied => "permission denied",
                    when others => Editor.Files.Status_Message (Preflight)));
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;
      end if;

      declare
         Before_Location : constant Editor.Navigation_History.Navigation_Location :=
           Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Unknown);
      begin
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
         if S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = Path
         then
            Editor.Executor.Record_Navigation_If_Target_Changed (S, Before_Location,
               Editor.Executor.Structured_File_Navigation_Target (Path));
         end if;
      end;

      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
      end if;
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Accept_Quick_Open;

   procedure Move_Quick_Open_Selection_By_Snapshot
     (S       : in out Editor.State.State_Type;
      Forward : Boolean)
   is
      Snapshot : constant Editor.Quick_Open.Quick_Open_Snapshot :=
        Editor.Quick_Open_Markers.Build_Snapshot
          (S.Quick_Open, S.Project, Editor.Buffers.Global_Registry_For_UI,
           S.Recent_Buffers);
      Count : constant Natural := Natural (Snapshot.Candidates.Length);
      Current : Natural := 0;
      Target  : Natural := 0;
      Found   : Boolean := False;
   begin
      if Count = 0 then
         return;
      end if;

      for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
         if Snapshot.Candidates (I).Is_Selected then
            Current := I;
            exit;
         end if;
      end loop;

      if Current = 0 and then not Snapshot.Candidates (Snapshot.Candidates.First_Index).Is_Selected then
         Target := Snapshot.Candidates.First_Index;
      elsif Forward then
         if Current = Snapshot.Candidates.Last_Index then
            Target := Snapshot.Candidates.First_Index;
         else
            Target := Current + 1;
         end if;
      else
         if Current = Snapshot.Candidates.First_Index then
            Target := Snapshot.Candidates.Last_Index;
         else
            Target := Current - 1;
         end if;
      end if;

      Editor.Quick_Open.Select_Path
        (S.Quick_Open,
         To_String (Snapshot.Candidates (Target).Project_Relative_Path),
         Found);
   end Move_Quick_Open_Selection_By_Snapshot;


   procedure Execute_Quick_Open_Next_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
         elsif Editor.Project.Known_File_Count (S.Project) = 0 then
            Editor.Executor.Report_Info (S, "No project files");
         else
            Editor.Executor.Report_Info (S, "No Quick Open matches.");
         end if;
      else
         Move_Quick_Open_Selection_By_Snapshot (S, Forward => True);
         Editor.Executor.Report_Info (S, "Selected next Quick Open candidate");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Next_Result;

   procedure Execute_Quick_Open_Previous_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
         elsif Editor.Project.Known_File_Count (S.Project) = 0 then
            Editor.Executor.Report_Info (S, "No project files");
         else
            Editor.Executor.Report_Info (S, "No Quick Open matches.");
         end if;
      else
         Move_Quick_Open_Selection_By_Snapshot (S, Forward => False);
         Editor.Executor.Report_Info (S, "Selected previous Quick Open candidate");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Previous_Result;

   procedure Execute_Quick_Open_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Text);
         Recompute_Quick_Open (S);
         if Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
            if not Editor.Project.Has_Project (S.Project) then
               Editor.Executor.Report_Info (S, "No project open");
            elsif Editor.Project.Known_File_Count (S.Project) = 0 then
               Editor.Executor.Report_Info (S, "No project files");
            else
               Editor.Executor.Report_Info (S, "No Quick Open matches.");
            end if;
         else
            Editor.Executor.Report_Info (S, "Quick Open query set");
         end if;
      end if;
   end Execute_Quick_Open_Set_Query;

   procedure Execute_Quick_Open_Clear_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if Editor.Quick_Open.Query_Text (S.Quick_Open)'Length = 0 then
            Editor.Executor.Report_Info (S, "No Quick Open query to clear");
         else
            Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "");
            Recompute_Quick_Open (S);
            Editor.Executor.Report_Info (S, "Quick Open query cleared");
         end if;
      end if;
   end Execute_Quick_Open_Clear_Query;


   procedure Execute_Quick_Open_Kind_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Quick_Open.Cycle_File_Kind_Next (S.Quick_Open);
         Recompute_Quick_Open (S);
         Editor.Executor.Report_Info (S, "Quick Open filter: " &
            Editor.Quick_Open.File_Kind_Filter_Name
              (Editor.Quick_Open.File_Kind_Filter (S.Quick_Open)));
      end if;
   end Execute_Quick_Open_Kind_Next;

   procedure Execute_Quick_Open_Kind_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Quick_Open.Cycle_File_Kind_Previous (S.Quick_Open);
         Recompute_Quick_Open (S);
         Editor.Executor.Report_Info (S, "Quick Open filter: " &
            Editor.Quick_Open.File_Kind_Filter_Name
              (Editor.Quick_Open.File_Kind_Filter (S.Quick_Open)));
      end if;
   end Execute_Quick_Open_Kind_Previous;

   procedure Execute_Quick_Open_Kind_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif Editor.Quick_Open.File_Kind_Filter (S.Quick_Open) = Editor.Quick_Open.All_Files then
            Editor.Executor.Report_Info (S, "No Quick Open file-kind filter to clear");
         else
            Editor.Quick_Open.Clear_File_Kind_Filter (S.Quick_Open);
            Recompute_Quick_Open (S);
            Editor.Executor.Report_Info (S, "Quick Open filter: All");
         end if;
      end if;
   end Execute_Quick_Open_Kind_Clear;

   function Quick_Open_Scope_Has_Parent_Traversal (Text : String) return Boolean is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
      Segment : Unbounded_String := Null_Unbounded_String;

      function Segment_Is_Parent return Boolean is
      begin
         return To_String (Segment) = "..";
      end Segment_Is_Parent;
   begin
      for Ch of Trimmed loop
         if Ch = '/' or else Ch = '\' then
            if Segment_Is_Parent then
               return True;
            end if;
            Segment := Null_Unbounded_String;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      return Segment_Is_Parent;
   end Quick_Open_Scope_Has_Parent_Traversal;

   procedure Execute_Quick_Open_Scope_Set
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
      Scope : constant String := Editor.Quick_Open.Normalize_Quick_Open_Scope (Text);
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
         elsif Quick_Open_Scope_Has_Parent_Traversal (Text) then
            Editor.Executor.Report_Info (S, "Invalid Quick Open scope");
         else
            Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, Text);
            Recompute_Quick_Open (S);
            if Scope'Length = 0 then
               Editor.Executor.Report_Info (S, "Quick Open scope cleared");
            else
               Editor.Executor.Report_Info (S, "Quick Open scope: " & Scope);
            end if;
         end if;
      end if;
   end Execute_Quick_Open_Scope_Set;

   procedure Execute_Quick_Open_Scope_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif Editor.Quick_Open.Path_Scope (S.Quick_Open)'Length = 0 then
            Editor.Executor.Report_Info (S, "No Quick Open scope");
         else
            Editor.Quick_Open.Clear_Path_Scope (S.Quick_Open);
            Recompute_Quick_Open (S);
            Editor.Executor.Report_Info (S, "Quick Open scope cleared");
         end if;
      end if;
   end Execute_Quick_Open_Scope_Clear;

   procedure Execute_Quick_Open_Scope_From_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Scope : constant String :=
        Editor.Quick_Open.Selected_Directory_Scope (S.Quick_Open, Found);
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif not Found then
            Editor.Executor.Report_Info (S, "No Quick Open selection");
         else
            Editor.Quick_Open.Set_Path_Scope_From_Selected (S.Quick_Open, Found);
            Recompute_Quick_Open (S);
            if Scope'Length = 0 then
               Editor.Executor.Report_Info (S, "Quick Open scope cleared");
            else
               Editor.Executor.Report_Info (S, "Quick Open scope: " & Scope);
            end if;
         end if;
      end if;
   end Execute_Quick_Open_Scope_From_Selected;

   procedure Execute_Quick_Open_Scope_Parent
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Parent : constant String :=
        Editor.Quick_Open.Parent_Scope
          (Editor.Quick_Open.Path_Scope (S.Quick_Open), Found);
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif not Found then
            Editor.Executor.Report_Info (S, "No Quick Open scope");
         else
            Editor.Quick_Open.Move_Path_Scope_To_Parent (S.Quick_Open, Found);
            Recompute_Quick_Open (S);
            if Parent'Length = 0 then
               Editor.Executor.Report_Info (S, "Quick Open scope cleared");
            else
               Editor.Executor.Report_Info (S, "Quick Open scope: " & Parent);
            end if;
         end if;
      end if;
   end Execute_Quick_Open_Scope_Parent;


   function Quick_Open_Reveal_Query_For_Path (Path : String) return String is
      Normalized : String (Path'Range);
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '\' then
            Normalized (I) := '/';
         else
            Normalized (I) := Path (I);
         end if;
      end loop;

      for I in Normalized'Range loop
         if Normalized (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return Normalized;
      elsif Last_Slash >= Normalized'Last then
         return "";
      else
         return Normalized (Last_Slash + 1 .. Normalized'Last);
      end if;
   end Quick_Open_Reveal_Query_For_Path;


   procedure Execute_Quick_Open_Reveal_Active
     (S : in out Editor.State.State_Type)
   is
      Found_Path : Boolean := False;
      Selected   : Boolean := False;
      Keep_Open_Recent_Priority : constant Boolean :=
        Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
        Editor.Quick_Open.Open_Recent;
      Path       : constant String := Editor.Executor.Active_Buffer_Known_Project_File (S, Found_Path);
      Query      : constant String := Quick_Open_Reveal_Query_For_Path (Path);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.State.Has_Active_Buffer (S) then
         Editor.Executor.Report_Info (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Editor.Executor.Report_Info (S, "No project files.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found_Path then
         Editor.Executor.Report_Info (S, "Active buffer is not a known project file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Quick_Open_Overlay);
      if Keep_Open_Recent_Priority
        and then Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
          Editor.Quick_Open.Path
      then
         Editor.Quick_Open.Toggle_Priority_Mode (S.Quick_Open);
      end if;
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Query);
      Editor.Quick_Open.Clear_File_Kind_Filter (S.Quick_Open);
      Editor.Quick_Open.Clear_Path_Scope (S.Quick_Open);
      Recompute_Quick_Open (S);
      Editor.Quick_Open.Select_Path (S.Quick_Open, Path, Selected);

      if Selected then
         Editor.Executor.Report_Info (S, "Quick Open selected active file: " & Path);
      else
         Editor.Executor.Report_Info (S, "Active buffer is not a known project file");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Reveal_Active;

   procedure Execute_Quick_Open_Scope_Active_Directory
     (S : in out Editor.State.State_Type)
   is
      Found_Path : Boolean := False;
      Selected   : Boolean := False;
      Keep_Open_Recent_Priority : constant Boolean :=
        Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
        Editor.Quick_Open.Open_Recent;
      Path       : constant String := Editor.Executor.Active_Buffer_Known_Project_File (S, Found_Path);
      Scope      : constant String := Editor.Quick_Open.Directory_Scope_Of_Path (Path);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.State.Has_Active_Buffer (S) then
         Editor.Executor.Report_Info (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Editor.Executor.Report_Info (S, "No project files.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found_Path then
         Editor.Executor.Report_Info (S, "Active buffer is not a known project file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Quick_Open_Overlay);
      if Keep_Open_Recent_Priority
        and then Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
          Editor.Quick_Open.Path
      then
         Editor.Quick_Open.Toggle_Priority_Mode (S.Quick_Open);
      end if;
      Editor.Quick_Open.Set_Query_Text
        (S.Quick_Open, Quick_Open_Reveal_Query_For_Path (Path));
      Editor.Quick_Open.Clear_File_Kind_Filter (S.Quick_Open);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, Scope);
      Recompute_Quick_Open (S);
      Editor.Quick_Open.Select_Path (S.Quick_Open, Path, Selected);

      if not Selected then
         Editor.Executor.Report_Info (S, "Active buffer is not a known project file");
      elsif Scope'Length = 0 then
         Editor.Executor.Report_Info (S, "Quick Open scope cleared");
      else
         Editor.Executor.Report_Info (S, "Quick Open scope: " & Scope);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Scope_Active_Directory;


   procedure Execute_Quick_Open_Create_From_Query
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Quick_Open.Quick_Open_Create_Target_Result;
      Rule_Check : Editor.Project.Project_Create_Path_Validation_Result;
      Rel_Path : Unbounded_String := Null_Unbounded_String;
      Abs_Path : Unbounded_String := Null_Unbounded_String;
      Parent_Rel : Unbounded_String := Null_Unbounded_String;
      Parent_Abs : Unbounded_String := Null_Unbounded_String;
      Created_File : Ada.Text_IO.File_Type;
      Created_File_Open : Boolean := False;
      Open_Check : Editor.Files.File_Open_Result;

      function Last_Slash (Text : String) return Natural is
      begin
         for I in reverse Text'Range loop
            if Text (I) = '/' then
               return I;
            end if;
         end loop;
         return 0;
      end Last_Slash;

      function Open_Failure_Text
        (Result : Editor.Files.File_Open_Result) return String is
      begin
         case Result.Status is
            when Editor.Files.File_Open_Not_Found =>
               return "file not found";
            when Editor.Files.File_Open_Permission_Denied =>
               return "permission denied";
            when others =>
               return Editor.Files.Status_Message (Result);
         end case;
      end Open_Failure_Text;
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project.Root_Path (S.Project)'Length = 0 then
         Editor.Executor.Report_Warning (S, "No project open.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Editor.Executor.Report_Warning (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Target := Editor.Quick_Open.Create_Target_From_Query (S.Quick_Open);
      case Target.Status is
         when Editor.Quick_Open.Quick_Open_Create_Target_No_Query =>
            Editor.Executor.Report_Warning (S, "No Quick Open query");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path =>
            Editor.Executor.Report_Warning (S, "Invalid project file path");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Ok =>
            null;
      end case;

      Rel_Path := Target.Project_Relative_Path;
      Abs_Path := To_Unbounded_String
        (Editor.Project.Absolute_Project_File_Path (S.Project, To_String (Rel_Path)));

      Rule_Check := Editor.Project.Validate_Project_Create_Path_Rules
        (S.Project, To_String (Rel_Path));
      case Rule_Check.Status is
         when Editor.Project.Project_Create_Path_Ok =>
            null;
         when Editor.Project.Project_Create_Path_No_Project =>
            Editor.Executor.Report_Warning (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Invalid_Root =>
            Editor.Executor.Report_Warning (S, "No project open.");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignored =>
            Editor.Executor.Report_Warning (S, "Path is ignored by project rules: " & To_String (Rel_Path));
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignore_Read_Error =>
            Editor.Executor.Report_Warning (S, To_String (Rule_Check.Failure_Reason));
            Editor.Render_Cache.Invalidate_All;
            return;
      end case;

      if Editor.Project.Has_Known_File (S.Project, To_String (Rel_Path)) then
         Editor.Executor.Report_Warning (S, "Project file already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Ada.Directories.Exists (To_String (Abs_Path)) then
         Editor.Executor.Report_Warning (S, "File already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Rel : constant String := To_String (Rel_Path);
         Slash : constant Natural := Last_Slash (Rel);
      begin
         if Slash = 0 then
            Parent_Abs := To_Unbounded_String (Editor.Project.Root_Path (S.Project));
            Parent_Rel := Null_Unbounded_String;
         else
            Parent_Rel := To_Unbounded_String (Rel (Rel'First .. Slash));
            Parent_Abs := To_Unbounded_String
              (Editor.Project.Absolute_Project_File_Path
                 (S.Project, Rel (Rel'First .. Slash - 1)));
         end if;
      end;

      if not Ada.Directories.Exists (To_String (Parent_Abs))
        or else Ada.Directories.Kind (To_String (Parent_Abs)) /= Ada.Directories.Directory
      then
         Editor.Executor.Report_Warning (S, "Parent directory does not exist: " & To_String (Parent_Rel));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      begin
         Ada.Text_IO.Create
           (File => Created_File,
            Mode => Ada.Text_IO.Out_File,
            Name => To_String (Abs_Path));
         Created_File_Open := True;
         Ada.Text_IO.Close (Created_File);
         Created_File_Open := False;
      exception
         when Ada.IO_Exceptions.Use_Error =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": permission denied");
            Editor.Render_Cache.Invalidate_All;
            return;
         when others =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": filesystem error");
            Editor.Render_Cache.Invalidate_All;
            return;
      end;

      Editor.Project.Add_Known_File
        (S.Project, To_String (Rel_Path), To_String (Abs_Path));
      Recompute_Quick_Open (S);
      declare
         Selected : Boolean := False;
      begin
         Editor.Quick_Open.Select_Path (S.Quick_Open, To_String (Rel_Path), Selected);
      end;

      Open_Check := Editor.Files.Open_File (To_String (Abs_Path));
      if not Editor.Files.Is_Success (Open_Check) then
         Editor.Executor.Report_Error (S, "Created " & To_String (Rel_Path)
            & " but could not open it: " & Open_Failure_Text (Open_Check));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Before_Location : constant Editor.Navigation_History.Navigation_Location :=
           Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Unknown);
      begin
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, To_String (Abs_Path));
         if S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Abs_Path)
         then
            Editor.Executor.Record_Navigation_If_Target_Changed (S, Before_Location,
               Editor.Executor.Structured_File_Navigation_Target (To_String (Abs_Path)));
         end if;
      end;
      --  Execute_Open_File is the existing activation/open path and owns the
      --  buffer/recent-buffer side effects.  Suppress its local success text
      --  so this filesystem-writing command still reports exactly one primary
      --  create result.
      Editor.Messages.Dismiss_Latest (S.Messages);
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
      end if;
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Executor.Report_Success (S, "Created " & To_String (Rel_Path));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Create_From_Query;


   procedure Execute_Quick_Open_Create_With_Parents_From_Query
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Quick_Open.Quick_Open_Create_Target_Result;
      Rule_Check : Editor.Project.Project_Create_Path_Validation_Result;
      Rel_Path : Unbounded_String := Null_Unbounded_String;
      Abs_Path : Unbounded_String := Null_Unbounded_String;
      Created_File : Ada.Text_IO.File_Type;
      Created_File_Open : Boolean := False;
      Open_Check : Editor.Files.File_Open_Result;
      Created_Parent_Directory_Count : Natural := 0;

      function Last_Slash (Text : String) return Natural is
      begin
         for I in reverse Text'Range loop
            if Text (I) = '/' then
               return I;
            end if;
         end loop;
         return 0;
      end Last_Slash;

      function Open_Failure_Text
        (Result : Editor.Files.File_Open_Result) return String is
      begin
         case Result.Status is
            when Editor.Files.File_Open_Not_Found =>
               return "file not found";
            when Editor.Files.File_Open_Permission_Denied =>
               return "permission denied";
            when others =>
               return Editor.Files.Status_Message (Result);
         end case;
      end Open_Failure_Text;

      procedure Ensure_Parent_Directories
        (Relative_File_Path : String;
         Failed             : out Boolean;
         Failure_Message    : out Unbounded_String)
      is
         Slash : constant Natural := Last_Slash (Relative_File_Path);
         Parent_Rel : constant String :=
           (if Slash = 0 then ""
            else Relative_File_Path (Relative_File_Path'First .. Slash - 1));
         Component_Start : Positive := Parent_Rel'First;

         procedure Check_Or_Create (Dir_Rel : String) is
            Dir_Abs : constant String :=
              Editor.Project.Absolute_Project_File_Path (S.Project, Dir_Rel);
            Display : constant String := Dir_Rel & "/";

            function Directory_Remains_Under_Project return Boolean is
            begin
               return Editor.Project.Is_Under_Project
                 (S.Project, Ada.Directories.Full_Name (Dir_Abs));
            exception
               when others =>
                  return False;
            end Directory_Remains_Under_Project;
         begin
            if Failed then
               return;
            end if;

            if Ada.Directories.Exists (Dir_Abs) then
               if Ada.Directories.Kind (Dir_Abs) /= Ada.Directories.Directory then
                  Failed := True;
                  Failure_Message := To_Unbounded_String
                    ("Parent path is not a directory: " & Dir_Rel);
               elsif not Directory_Remains_Under_Project then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Invalid project file path");
               end if;
               return;
            end if;

            begin
               Ada.Directories.Create_Directory (Dir_Abs);
               Created_Parent_Directory_Count := Created_Parent_Directory_Count + 1;
               if not Directory_Remains_Under_Project then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Invalid project file path");
               end if;
            exception
               when Ada.IO_Exceptions.Use_Error =>
                  Failed := True;
                  Failure_Message := To_Unbounded_String
                    ("Could not create parent directory " & Display & ": permission denied");
               when others =>
                  Failed := True;
                  Failure_Message := To_Unbounded_String
                    ("Could not create parent directory " & Display & ": filesystem error");
            end;
         end Check_Or_Create;
      begin
         Failed := False;
         Failure_Message := Null_Unbounded_String;

         if Parent_Rel'Length = 0 then
            return;
         end if;

         for I in Parent_Rel'Range loop
            if Parent_Rel (I) = '/' then
               if I > Component_Start then
                  Check_Or_Create (Parent_Rel (Parent_Rel'First .. I - 1));
               end if;
               Component_Start := I + 1;
            end if;
         end loop;

         if not Failed then
            Check_Or_Create (Parent_Rel);
         end if;
      end Ensure_Parent_Directories;
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project.Root_Path (S.Project)'Length = 0 then
         Editor.Executor.Report_Warning (S, "No project open.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Editor.Executor.Report_Warning (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Target := Editor.Quick_Open.Create_Target_From_Query (S.Quick_Open);
      case Target.Status is
         when Editor.Quick_Open.Quick_Open_Create_Target_No_Query =>
            Editor.Executor.Report_Warning (S, "No Quick Open query");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path =>
            Editor.Executor.Report_Warning (S, "Invalid project file path");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Ok =>
            null;
      end case;

      Rel_Path := Target.Project_Relative_Path;
      Abs_Path := To_Unbounded_String
        (Editor.Project.Absolute_Project_File_Path (S.Project, To_String (Rel_Path)));

      Rule_Check := Editor.Project.Validate_Project_Create_Path_Rules
        (S.Project, To_String (Rel_Path));
      case Rule_Check.Status is
         when Editor.Project.Project_Create_Path_Ok =>
            null;
         when Editor.Project.Project_Create_Path_No_Project =>
            Editor.Executor.Report_Warning (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Invalid_Root =>
            Editor.Executor.Report_Warning (S, "No project open.");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignored =>
            Editor.Executor.Report_Warning (S, "Path is ignored by project rules: " & To_String (Rel_Path));
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignore_Read_Error =>
            Editor.Executor.Report_Warning (S, To_String (Rule_Check.Failure_Reason));
            Editor.Render_Cache.Invalidate_All;
            return;
      end case;

      if Editor.Project.Has_Known_File (S.Project, To_String (Rel_Path)) then
         Editor.Executor.Report_Warning (S, "Project file already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Ada.Directories.Exists (To_String (Abs_Path)) then
         Editor.Executor.Report_Warning (S, "File already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Failed : Boolean := False;
         Failure_Message : Unbounded_String := Null_Unbounded_String;
      begin
         Ensure_Parent_Directories
           (To_String (Rel_Path), Failed, Failure_Message);
         if Failed then
            Editor.Executor.Report_Error (S, To_String (Failure_Message));
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;
      end;

      begin
         Ada.Text_IO.Create
           (File => Created_File,
            Mode => Ada.Text_IO.Out_File,
            Name => To_String (Abs_Path));
         Created_File_Open := True;
         Ada.Text_IO.Close (Created_File);
         Created_File_Open := False;
      exception
         when Ada.IO_Exceptions.Use_Error =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": permission denied");
            Editor.Render_Cache.Invalidate_All;
            return;
         when others =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": filesystem error");
            Editor.Render_Cache.Invalidate_All;
            return;
      end;

      Editor.Project.Add_Known_File
        (S.Project, To_String (Rel_Path), To_String (Abs_Path));
      Recompute_Quick_Open (S);
      declare
         Selected : Boolean := False;
      begin
         Editor.Quick_Open.Select_Path (S.Quick_Open, To_String (Rel_Path), Selected);
      end;

      Open_Check := Editor.Files.Open_File (To_String (Abs_Path));
      if not Editor.Files.Is_Success (Open_Check) then
         Editor.Executor.Report_Error (S, "Created " & To_String (Rel_Path)
            & " but could not open it: " & Open_Failure_Text (Open_Check));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Before_Location : constant Editor.Navigation_History.Navigation_Location :=
           Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Unknown);
      begin
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, To_String (Abs_Path));
         if S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Abs_Path)
         then
            Editor.Executor.Record_Navigation_If_Target_Changed (S, Before_Location,
               Editor.Executor.Structured_File_Navigation_Target (To_String (Abs_Path)));
         end if;
      end;
      Editor.Messages.Dismiss_Latest (S.Messages);
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
      end if;
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Executor.Report_Success (S, "Created " & To_String (Rel_Path));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Create_With_Parents_From_Query;

   procedure Execute_Quick_Open_Priority_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Editor.Executor.Report_Info (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Quick_Open.Toggle_Priority_Mode (S.Quick_Open);
      Recompute_Quick_Open (S);

      case Editor.Quick_Open.Priority_Mode (S.Quick_Open) is
         when Editor.Quick_Open.Open_Recent =>
            Editor.Executor.Report_Info (S, "Quick Open priority: Open/Recent");
         when Editor.Quick_Open.Path =>
            Editor.Executor.Report_Info (S, "Quick Open priority: Path");
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Priority_Toggle;


   procedure Execute_Quick_Open_Priority_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Editor.Executor.Report_Info (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Quick_Open.Priority_Mode (S.Quick_Open) = Editor.Quick_Open.Path then
         Editor.Executor.Report_Info (S, "Quick Open priority already Path");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Quick_Open.Clear_Priority_Mode (S.Quick_Open);
      Recompute_Quick_Open (S);
      Editor.Executor.Report_Info (S, "Quick Open priority: Path");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Priority_Clear;


   procedure Execute_Quick_Open_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Insert_Text (S.Quick_Open, Text);
         Recompute_Quick_Open (S);
      end if;
   end Execute_Quick_Open_Insert_Text;

   procedure Execute_Quick_Open_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Backspace (S.Quick_Open);
         Recompute_Quick_Open (S);
      end if;
   end Execute_Quick_Open_Backspace;

   procedure Execute_Quick_Open_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Delete_Forward (S.Quick_Open);
         Recompute_Quick_Open (S);
      end if;
   end Execute_Quick_Open_Delete_Forward;

   procedure Execute_Quick_Open_Move_Cursor_Left
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Quick_Open.Move_Cursor_Left (S.Quick_Open);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Move_Cursor_Left;

   procedure Execute_Quick_Open_Move_Cursor_Right
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Quick_Open.Move_Cursor_Right (S.Quick_Open);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Move_Cursor_Right;

   procedure Execute_Command_Surface_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String := "")
   is
   begin
      case Kind is
         when Open_Command_Palette =>
            Execute_Open_Command_Palette (S);
         when Palette_Show_Command_Help =>
            Execute_Palette_Show_Command_Help (S);
         when Open_Goto_Line =>
            Execute_Open_Goto_Line (S);
         when Prefill_Goto_Line_Current =>
            Execute_Prefill_Goto_Line_Current (S);
         when Toggle_Goto_Line =>
            Execute_Toggle_Goto_Line (S);
         when Close_Goto_Line =>
            Execute_Close_Goto_Line (S);
         when Accept_Goto_Line =>
            Execute_Accept_Goto_Line (S);
         when Goto_Line_Query_Set =>
            Execute_Goto_Line_Set_Query (S, Text);
         when Goto_Line_Query_Clear =>
            Execute_Goto_Line_Clear_Query (S);
         when Goto_Line_Insert_Text =>
            Execute_Goto_Line_Insert_Text (S, Text);
         when Goto_Line_Backspace =>
            Execute_Goto_Line_Backspace (S);
         when Goto_Line_Delete_Forward =>
            Execute_Goto_Line_Delete_Forward (S);
         when Goto_Line_Move_Cursor_Left =>
            Execute_Goto_Line_Move_Cursor_Left (S);
         when Goto_Line_Move_Cursor_Right =>
            Execute_Goto_Line_Move_Cursor_Right (S);
         when Open_Quick_Open =>
            Execute_Open_Quick_Open (S);
         when Close_Quick_Open =>
            Execute_Close_Quick_Open (S);
         when Toggle_Quick_Open =>
            Execute_Toggle_Quick_Open (S);
         when Accept_Quick_Open =>
            Execute_Accept_Quick_Open (S);
         when Quick_Open_Next_Result =>
            Execute_Quick_Open_Next_Result (S);
         when Quick_Open_Previous_Result =>
            Execute_Quick_Open_Previous_Result (S);
         when Quick_Open_Query_Set =>
            Execute_Quick_Open_Set_Query (S, Text);
         when Quick_Open_Query_Clear =>
            Execute_Quick_Open_Clear_Query (S);
         when Quick_Open_Kind_Next =>
            Execute_Quick_Open_Kind_Next (S);
         when Quick_Open_Kind_Previous =>
            Execute_Quick_Open_Kind_Previous (S);
         when Quick_Open_Kind_Clear =>
            Execute_Quick_Open_Kind_Clear (S);
         when Quick_Open_Scope_Set =>
            Execute_Quick_Open_Scope_Set (S, Text);
         when Quick_Open_Scope_Clear =>
            Execute_Quick_Open_Scope_Clear (S);
         when Quick_Open_Scope_From_Selected =>
            Execute_Quick_Open_Scope_From_Selected (S);
         when Quick_Open_Scope_Parent =>
            Execute_Quick_Open_Scope_Parent (S);
         when Quick_Open_Reveal_Active =>
            Execute_Quick_Open_Reveal_Active (S);
         when Quick_Open_Scope_Active_Directory =>
            Execute_Quick_Open_Scope_Active_Directory (S);
         when Quick_Open_Create_From_Query =>
            Execute_Quick_Open_Create_From_Query (S);
         when Quick_Open_Create_With_Parents_From_Query =>
            Execute_Quick_Open_Create_With_Parents_From_Query (S);
         when Quick_Open_Priority_Toggle =>
            Execute_Quick_Open_Priority_Toggle (S);
         when Quick_Open_Priority_Clear =>
            Execute_Quick_Open_Priority_Clear (S);
         when Quick_Open_Insert_Text =>
            Execute_Quick_Open_Insert_Text (S, Text);
         when Quick_Open_Backspace =>
            Execute_Quick_Open_Backspace (S);
         when Quick_Open_Delete_Forward =>
            Execute_Quick_Open_Delete_Forward (S);
         when Quick_Open_Move_Cursor_Left =>
            Execute_Quick_Open_Move_Cursor_Left (S);
         when Quick_Open_Move_Cursor_Right =>
            Execute_Quick_Open_Move_Cursor_Right (S);
         when others =>
            raise Program_Error with "unsupported command-surface command kind";
      end case;
   end Execute_Command_Surface_Kind;

end Editor.Executor.Command_Surface_Commands;
