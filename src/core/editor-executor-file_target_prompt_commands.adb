with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Commands;
with Editor.Executor;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Input_Field;
with Editor.Invariants;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.File_Target_Prompt_Commands is

   function Command_Requires_File_Target_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Command_Is_Target_Prompt_Capable (Id);
   end Command_Requires_File_Target_Prompt;

   function File_Target_Prompt_Is_Active
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return S.File_Target_Prompt_Active;
   end File_Target_Prompt_Is_Active;

   function File_Target_Prompt_Input_Text
     (S : Editor.State.State_Type) return String
   is
   begin
      return Editor.Input_Field.Text (S.File_Target_Prompt_Input);
   end File_Target_Prompt_Input_Text;

   function File_Target_Prompt_Label
     (S : Editor.State.State_Type) return String
   is
   begin
      return To_String (S.File_Target_Prompt_Label);
   end File_Target_Prompt_Label;

   procedure Clear_File_Target_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.State.Clear_File_Target_Prompt (S);
      Editor.Render_Cache.Invalidate_All;
   end Clear_File_Target_Prompt;

   function Prompt_Label_For_File_Target_Command
     (Id : Editor.Commands.Command_Id) return String
   is
   begin
      return Editor.Commands.Command_Target_Prompt_Label (Id);
   end Prompt_Label_For_File_Target_Command;

   procedure Open_File_Target_Prompt
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
   is
      Availability : Editor.Commands.Command_Availability;
   begin
      if not Command_Requires_File_Target_Prompt (Id) then
         return;
      end if;

      Availability := Editor.Executor.Command_Availability (S, Id);
      if not Editor.Commands.Is_Available (Availability) then
         declare
            Reason : constant String :=
              Editor.Commands.Unavailable_Reason (Availability);
         begin
            if Reason = "Command unavailable while confirmation is pending." then
               Editor.Executor.Report_Warning (S, Reason);
            else
               Editor.Executor.Report_Info (S, Reason);
            end if;
         end;
         return;
      end if;

      S.File_Target_Prompt_Active := True;
      S.File_Target_Prompt_Command := Id;
      S.File_Target_Prompt_Label :=
        To_Unbounded_String (Prompt_Label_For_File_Target_Command (Id));
      Editor.Input_Field.Clear (S.File_Target_Prompt_Input);
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.File_Target_Prompt_Overlay);
      Editor.Render_Cache.Invalidate_All;
   end Open_File_Target_Prompt;

   procedure Cancel_File_Target_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      if not S.File_Target_Prompt_Active then
         return;
      end if;
      Clear_File_Target_Prompt (S);
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay)
      then
         Editor.Executor.Deactivate_Active_Overlay_Only
           (S, Editor.Overlay_Focus.Dismiss_Escape);
      end if;
   end Cancel_File_Target_Prompt;

   procedure Execute_File_Target_Command
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Target : String)
   is
   begin
      case Id is
         when Editor.Commands.Command_Save_File_As =>
            Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target);
         when Editor.Commands.Command_Rename_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File
              (S, Target);
         when Editor.Commands.Command_Copy_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File
              (S, Target);
         when Editor.Commands.Command_Move_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File
              (S, Target);
         when others =>
            null;
      end case;
      Editor.Invariants.Check (S);
   end Execute_File_Target_Command;

   procedure Confirm_File_Target_Prompt
     (S : in out Editor.State.State_Type)
   is
      Id     : constant Editor.Commands.Command_Id := S.File_Target_Prompt_Command;
      Target : constant String :=
        Editor.Input_Field.Text (S.File_Target_Prompt_Input);
   begin
      if not S.File_Target_Prompt_Active
        or else not Command_Requires_File_Target_Prompt (Id)
      then
         return;
      end if;

      Clear_File_Target_Prompt (S);
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay)
      then
         Editor.Executor.Deactivate_Active_Overlay_Only
           (S, Editor.Overlay_Focus.Dismiss_Accept);
      end if;

      Execute_File_Target_Command (S, Id, Target);
   end Confirm_File_Target_Prompt;

   procedure Insert_File_Target_Prompt_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Insert_Text (S.File_Target_Prompt_Input, Text);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Insert_File_Target_Prompt_Text;

   procedure Select_All_File_Target_Prompt_Text
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Select_All (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Select_All_File_Target_Prompt_Text;

   procedure Backspace_File_Target_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Backspace (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Backspace_File_Target_Prompt;

   procedure Delete_Forward_File_Target_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Delete_Forward (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Delete_Forward_File_Target_Prompt;

   procedure Move_File_Target_Prompt_Cursor_Left
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Move_Cursor_Left (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Move_File_Target_Prompt_Cursor_Left;

   procedure Move_File_Target_Prompt_Cursor_Right
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Move_Cursor_Right (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Move_File_Target_Prompt_Cursor_Right;

   procedure Move_File_Target_Prompt_Cursor_Start
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Move_Cursor_Start (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Move_File_Target_Prompt_Cursor_Start;

   procedure Move_File_Target_Prompt_Cursor_End
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Target_Prompt_Active then
         Editor.Input_Field.Move_Cursor_End (S.File_Target_Prompt_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Move_File_Target_Prompt_Cursor_End;

end Editor.Executor.File_Target_Prompt_Commands;
