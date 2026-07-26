with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Pending_Transition_Key_Handlers is

   function Handle_Pending_Transition_Key
     (S           : Editor.State.State_Type;
      Chord       : Editor.Keybindings.Key_Chord;
      Execute     : not null access procedure
        (Id : Editor.Command_Ids.Command_Id; Shift : Boolean);
      Report_Info : not null access procedure (Text : String)) return Boolean;

end Editor.Input_Bridge.Pending_Transition_Key_Handlers;
