with Editor.Buffers;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Buffer_Close_Commands is

   procedure Execute_Close_All_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Other_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_All_Clean_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Discard_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Buffer
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id);

   procedure Execute_Buffer_Close_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Buffer_Close_Commands;
