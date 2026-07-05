with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Pointer_Scroll_Handlers is

   function Handle_Minimap_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Scrollbar_Pointer
     (S                       : in out Editor.State.State_Type;
      Cmd                     : Editor.Commands.Command;
      Max_Visible_Line_Length : Natural) return Boolean;

end Editor.Input_Bridge.Pointer_Scroll_Handlers;
