with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor.Edits;
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

   procedure Report_Line_Edit_Status
     (S       : in out Editor.State.State_Type;
      Command : Editor.Commands.Command_Id;
      Status  : Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Editing_Commands;
