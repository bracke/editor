with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Goto_Line_Key_Handlers is

   function Handle_Goto_Line_Key
     (S               : in out Editor.State.State_Type;
      Chord           : Editor.Keybindings.Key_Chord;
      Execute         : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Payloads.Command)) return Boolean;

end Editor.Input_Bridge.Goto_Line_Key_Handlers;
