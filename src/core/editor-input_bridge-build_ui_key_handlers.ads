with Editor.Commands;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Build_UI_Key_Handlers is

   type Focused_Key_Result is
     (Build_UI_Not_Focused,
      Build_UI_Key_Handled,
      Build_UI_Key_Not_Handled);

   function Handle_Build_UI_Tab_Key
     (S     : in out Editor.State.State_Type;
      Chord : Editor.Keybindings.Key_Chord) return Boolean;

   function Handle_Build_UI_Focused_Surface_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Focused_Key_Result;

   function Handle_Build_UI_Key
     (S           : in out Editor.State.State_Type;
      Chord       : Editor.Keybindings.Key_Chord;
      Execute     : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Report_Info : not null access procedure (Text : String)) return Boolean;

end Editor.Input_Bridge.Build_UI_Key_Handlers;
