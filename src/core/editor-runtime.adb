with Editor.Input;
with Editor.Commands;
with Editor.Engine;

package body Editor.Runtime is

   procedure Process_Event
     (S : in out Editor.State.State_Type;
      E : Editor.Events.Event) is

      Input : Editor.Input.Input_Event;
      Cmd   : Editor.Commands.Command;
   begin

      Input := Editor.Input_Bridge.To_Input (E);
      Cmd   := Editor.Input.To_Command (Input, 0);

      Editor.Engine.Run_Command (S, Cmd);

   end Process_Event;

end Editor.Runtime;