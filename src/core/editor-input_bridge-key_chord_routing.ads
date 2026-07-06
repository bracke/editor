with Editor.Commands;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Key_Chord_Routing is

   function Handle_Pre_Bound_Chord
     (S                            : in out Editor.State.State_Type;
      Chord                        : Editor.Keybindings.Key_Chord;
      Accept_Guided_Prompt_Enter   : not null access procedure;
      Report_Info                  : not null access procedure (Text : String);
      Execute_Command_With_Shift   : not null access procedure
        (Id : Editor.Commands.Command_Id; Shift : Boolean);
      Execute_Default_Command      : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Active_Find_Previous : not null access procedure;
      Hide_Active_Find             : not null access procedure)
      return Boolean;

end Editor.Input_Bridge.Key_Chord_Routing;
