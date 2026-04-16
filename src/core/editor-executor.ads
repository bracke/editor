with Editor.State;
with Editor.Commands;

package Editor.Executor is

   procedure Execute_No_Log
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor;