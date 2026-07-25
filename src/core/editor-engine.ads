with Editor.Commands.Payloads;
with Editor.State;
with Editor.Commands;

package Editor.Engine is

   procedure Run_Command
     (S    : in out Editor.State.State_Type;
      Cmd  : Editor.Commands.Payloads.Command);

end Editor.Engine;