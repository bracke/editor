with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Outline_Commands is

   function Outline_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Outline_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
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

   procedure Execute_Outline_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Outline_Commands;
