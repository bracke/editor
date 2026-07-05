with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Preview_Commands is

   function Buffer_Switcher_Preview_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Buffer_Switcher_Preview_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Buffer_Switcher_Preview_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

   procedure Execute_Buffer_Switcher_Preview_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Next_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Previous_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Center_Cursor
     (S : in out Editor.State.State_Type);

end Editor.Executor.Buffer_Switcher_Preview_Commands;
