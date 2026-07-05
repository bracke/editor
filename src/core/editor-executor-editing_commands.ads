with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Editing_Commands is

   function Editing_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Editing_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Editing_Commands;
