with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Feature_Panel_Commands is

   function Feature_Panel_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Feature_Panel_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Feature_Panel_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

end Editor.Executor.Feature_Panel_Commands;
