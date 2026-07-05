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

   procedure Execute_File_Conflict_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Keep_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Reload_From_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Overwrite_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_Retry_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Cancel_Pending_Transition
     (S : in out Editor.State.State_Type);

end Editor.Executor.File_Save_Commands;
