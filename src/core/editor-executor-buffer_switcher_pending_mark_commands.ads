with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Pending_Mark_Commands is

   function Buffer_Switcher_Pending_Mark_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Buffer_Switcher_Pending_Mark_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Buffer_Switcher_Pending_Mark_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

end Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
