with Editor.Commands;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.File_Tree_Key_Handlers is

   type Focused_Key_Result is
     (File_Tree_Not_Focused,
      File_Tree_Key_Handled,
      File_Tree_Key_Not_Handled);

   function Handle_File_Tree_Focused_Surface_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Focused_Key_Result;

   function Handle_File_Tree_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean;

end Editor.Input_Bridge.File_Tree_Key_Handlers;
