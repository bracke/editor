with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Gutter_Pointer_Handlers is

   function Handle_Gutter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

end Editor.Input_Bridge.Gutter_Pointer_Handlers;
