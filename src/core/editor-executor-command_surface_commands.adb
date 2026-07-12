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
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Quick_Open_Commands;
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
            | Command_Quick_Open_Scope_Active_Directory
            | Command_Quick_Open_Priority_Toggle
            | Command_Quick_Open_Priority_Clear
            | Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query
            | Command_Palette_Show_Command_Help
            | Command_Close_Quick_Open
            | Command_Accept_Quick_Open
            | Command_Quick_Open_Next_Result
            | Command_Quick_Open_Previous_Result
            | Command_Quick_Open_Query_Set
            | Command_Quick_Open_Query_Clear
            | Command_Quick_Open_Kind_Next
            | Command_Quick_Open_Kind_Previous
            | Command_Quick_Open_Kind_Clear
            | Command_Quick_Open_Scope_Set
            | Command_Quick_Open_Scope_Clear
            | Command_Quick_Open_Scope_From_Selected
            | Command_Quick_Open_Scope_Parent =>
            return Editor.Executor.Quick_Open_Commands
              .Command_Surface_Command_Availability (S, Id);

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
         Editor.Executor.Shared_Services.Report_Info (S, "Command Palette closed.");
         return;
      end if;

      Editor.Command_Palette.Toggle_Show_Help_Row;
      Editor.Executor.Shared_Services.Report_Info (S, "Command help display toggled");
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
               Editor.Executor.Shared_Services.Report_Info (S, "Command Palette closed.");
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Execute_Palette_Show_Command_Help (S);
            return Editor.Command_Execution.Executed (Id);

         when Command_Cancel =>
            if S.Dirty_Close_Prompt_Active then
               Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Cancel_Close (S);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif S.File_Conflict_Prompt_Active then
               Editor.Executor.File_Save_Commands.Clear_File_Conflict_Prompt (S);
               Editor.Executor.Shared_Services.Report_Info (S, "File conflict cancelled");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Cancelled (Id);
            elsif Editor.Guided_Prompts.Is_Active (S.Guided_Prompt) then
               Editor.Guided_Prompts.Cancel (S.Guided_Prompt);
               Editor.Executor.Shared_Services.Report_Info (S, "Prompt cancelled.");
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

   procedure Execute_Command_Surface_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String := "")
   is
   begin
      case Kind is
         when Open_Command_Palette
            | Palette_Show_Command_Help
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
            case Kind is
               when Open_Command_Palette =>
                  Execute_Open_Command_Palette (S);
               when Palette_Show_Command_Help =>
                  Execute_Palette_Show_Command_Help (S);
               when Open_Quick_Open =>
                  Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
               when Close_Quick_Open =>
                  Editor.Executor.Quick_Open_Commands.Execute_Close_Quick_Open (S);
               when Toggle_Quick_Open =>
                  Editor.Executor.Quick_Open_Commands.Execute_Toggle_Quick_Open (S);
               when Accept_Quick_Open =>
                  Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);
               when Quick_Open_Next_Result =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Next_Result (S);
               when Quick_Open_Previous_Result =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Previous_Result (S);
               when Quick_Open_Query_Set =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query
                    (S, Text);
               when Quick_Open_Query_Clear =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Clear_Query (S);
               when Quick_Open_Kind_Next =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Kind_Next (S);
               when Quick_Open_Kind_Previous =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Kind_Previous (S);
               when Quick_Open_Kind_Clear =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Kind_Clear (S);
               when Quick_Open_Scope_Set =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Set
                    (S, Text);
               when Quick_Open_Scope_Clear =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Clear (S);
               when Quick_Open_Scope_From_Selected =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_From_Selected
                    (S);
               when Quick_Open_Scope_Parent =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Parent (S);
               when Quick_Open_Reveal_Active =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Reveal_Active (S);
               when Quick_Open_Scope_Active_Directory =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Active_Directory
                    (S);
               when Quick_Open_Create_From_Query =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_From_Query
                    (S);
               when Quick_Open_Create_With_Parents_From_Query =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_With_Parents_From_Query
                    (S);
               when Quick_Open_Priority_Toggle =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Priority_Toggle (S);
               when Quick_Open_Priority_Clear =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Priority_Clear (S);
               when Quick_Open_Insert_Text =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Insert_Text
                    (S, Text);
               when Quick_Open_Backspace =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Backspace (S);
               when Quick_Open_Delete_Forward =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Delete_Forward (S);
               when Quick_Open_Move_Cursor_Left =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Move_Cursor_Left
                    (S);
               when Quick_Open_Move_Cursor_Right =>
                  Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Move_Cursor_Right
                    (S);
               when others =>
                  null;
            end case;
         when Open_Goto_Line
            | Prefill_Goto_Line_Current
            | Toggle_Goto_Line
            | Close_Goto_Line
            | Accept_Goto_Line
            | Goto_Line_Query_Set
            | Goto_Line_Query_Clear
            | Goto_Line_Insert_Text
            | Goto_Line_Backspace
            | Goto_Line_Delete_Forward
            | Goto_Line_Move_Cursor_Left
            | Goto_Line_Move_Cursor_Right =>
            Editor.Executor.Navigation_Commands.Execute_Goto_Line_Kind
              (S, Kind, Text);
         when others =>
            raise Program_Error with "unsupported command-surface command kind";
      end case;
   end Execute_Command_Surface_Kind;

end Editor.Executor.Command_Surface_Commands;
