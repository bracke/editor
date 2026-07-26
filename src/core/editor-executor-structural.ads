with Editor.Commands.Payloads;
with Editor.State;

package Editor.Executor.Structural is

   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command);

end Editor.Executor.Structural;