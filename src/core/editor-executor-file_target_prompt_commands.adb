with Editor.Commands;
with Editor.Executor.File_Save_Commands;
with Editor.State;

package body Editor.Executor.File_Target_Prompt_Commands is

   function Command_Requires_File_Target_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean
      renames Editor.Executor.File_Save_Commands.Command_Requires_File_Target_Prompt;

   function File_Target_Prompt_Is_Active
     (S : Editor.State.State_Type) return Boolean
      renames Editor.Executor.File_Save_Commands.File_Target_Prompt_Is_Active;

   function File_Target_Prompt_Input_Text
     (S : Editor.State.State_Type) return String
      renames Editor.Executor.File_Save_Commands.File_Target_Prompt_Input_Text;

   function File_Target_Prompt_Label
     (S : Editor.State.State_Type) return String
      renames Editor.Executor.File_Save_Commands.File_Target_Prompt_Label;

   procedure Open_File_Target_Prompt
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      renames Editor.Executor.File_Save_Commands.Open_File_Target_Prompt;

   procedure Cancel_File_Target_Prompt
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Cancel_File_Target_Prompt;

   procedure Confirm_File_Target_Prompt
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Confirm_File_Target_Prompt;

   procedure Insert_File_Target_Prompt_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
      renames Editor.Executor.File_Save_Commands.Insert_File_Target_Prompt_Text;

   procedure Select_All_File_Target_Prompt_Text
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Select_All_File_Target_Prompt_Text;

   procedure Backspace_File_Target_Prompt
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Backspace_File_Target_Prompt;

   procedure Delete_Forward_File_Target_Prompt
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Delete_Forward_File_Target_Prompt;

   procedure Move_File_Target_Prompt_Cursor_Left
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Move_File_Target_Prompt_Cursor_Left;

   procedure Move_File_Target_Prompt_Cursor_Right
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Move_File_Target_Prompt_Cursor_Right;

   procedure Move_File_Target_Prompt_Cursor_Start
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Move_File_Target_Prompt_Cursor_Start;

   procedure Move_File_Target_Prompt_Cursor_End
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Move_File_Target_Prompt_Cursor_End;

   procedure Clear_File_Target_Prompt
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Clear_File_Target_Prompt;

   procedure Execute_File_Target_Command
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Target : String)
      renames Editor.Executor.File_Save_Commands.Execute_File_Target_Command;

end Editor.Executor.File_Target_Prompt_Commands;
