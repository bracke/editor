with Editor.Command_Kinds;
with Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Selected_Commands is

   function Buffer_Switcher_Selected_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   function Execute_Buffer_Switcher_Selected_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Buffer_Switcher_Selected_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Command_Kinds.Command_Kind;
      Text : String);

end Editor.Executor.Buffer_Switcher_Selected_Commands;
