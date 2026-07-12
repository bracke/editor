with Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Files;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.State;

package Editor.Executor.File_Lifecycle_Commands is

   procedure Lifecycle_Command_Availability
     (S        : Editor.State.State_Type;
      Id       : Editor.Commands.Command_Id;
      Handled  : out Boolean;
      Result   : out Editor.Commands.Command_Availability);

   function Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Lifecycle_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Lifecycle_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   function Active_File_External_Status
     (S : Editor.State.State_Type) return Editor.Files.File_External_Change_Status;

   function External_Status_Code
     (Status : Editor.Files.File_External_Change_Status) return Natural;

   function Pending_File_State_Still_Current
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Boolean;

end Editor.Executor.File_Lifecycle_Commands;
