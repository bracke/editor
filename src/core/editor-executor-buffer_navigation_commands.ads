with Editor.Commands;
with Editor.State;

package Editor.Executor.Buffer_Navigation_Commands is

   function Buffer_Navigation_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Next_Buffer_Group
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Buffer_Group
     (S : in out Editor.State.State_Type);

   procedure Execute_Next_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Recent_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Next_Recent_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Navigation_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Buffer_Navigation_Commands;
