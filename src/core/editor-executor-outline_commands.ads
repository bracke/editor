with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Payloads;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Outline_Commands is

   function Outline_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   function Execute_Outline_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id;
      Cmd : Editor.Commands.Payloads.Command)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Outline_Row_Click
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Outline_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Outline_Commands;
