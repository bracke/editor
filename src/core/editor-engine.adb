with Editor.Commands.Payloads;
with Editor.Executor;

package body Editor.Engine is

   procedure Run_Command
     (S    : in out Editor.State.State_Type;
      Cmd  : Editor.Commands.Payloads.Command) is
   begin
      Editor.Executor.Execute_No_Log (S, Cmd);
   end Run_Command;

end Editor.Engine;