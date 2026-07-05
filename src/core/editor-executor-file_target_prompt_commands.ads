with Editor.Commands;
with Editor.State;

package Editor.Executor.File_Target_Prompt_Commands is

   function Command_Requires_File_Target_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean;

   function File_Target_Prompt_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function File_Target_Prompt_Input_Text
     (S : Editor.State.State_Type) return String;

   function File_Target_Prompt_Label
     (S : Editor.State.State_Type) return String;

   procedure Open_File_Target_Prompt
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id);

   procedure Cancel_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Confirm_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Insert_File_Target_Prompt_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Select_All_File_Target_Prompt_Text
     (S : in out Editor.State.State_Type);

   procedure Backspace_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Delete_Forward_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_Right
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_Start
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_End
     (S : in out Editor.State.State_Type);

   procedure Clear_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Target_Command
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Target : String);

end Editor.Executor.File_Target_Prompt_Commands;
