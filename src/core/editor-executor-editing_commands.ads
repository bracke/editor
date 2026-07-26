with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Command_Execution;
with Editor.Executor.Edits;
with Editor.State;

package Editor.Executor.Editing_Commands is

   function Editing_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   function Execute_Editing_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Command_Ids.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Report_Line_Edit_Status
     (S       : in out Editor.State.State_Type;
      Command : Editor.Command_Ids.Command_Id;
      Status  : Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Editing_Commands;
