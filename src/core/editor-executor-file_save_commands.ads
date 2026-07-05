with Editor.Commands;
with Editor.Files;
with Editor.Pending_Transitions;
with Editor.State;

package Editor.Executor.File_Save_Commands is

   function Active_File_External_Status
     (S : Editor.State.State_Type) return Editor.Files.File_External_Change_Status;

   function External_Status_Code
     (Status : Editor.Files.File_External_Change_Status) return Natural;

   function Pending_File_State_Still_Current
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Boolean;

   procedure Clear_File_Conflict_Prompt
     (S : in out Editor.State.State_Type);

   function File_Conflict_Prompt_Is_Valid
     (S : Editor.State.State_Type) return Boolean;

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

   procedure Execute_Save
     (S : in out Editor.State.State_Type);

   procedure Execute_Reload_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Revert_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Rename_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Delete_Buffer_File
     (S : in out Editor.State.State_Type);

   procedure Execute_Copy_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Move_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_File_Conflict_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Keep_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Reload_From_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Overwrite_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Retry_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Cancel_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_File_Save_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.File_Save_Commands;
