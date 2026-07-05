with Editor.Commands;

package Editor.Input_Bridge.Pointer_Routing is

   function Is_Minimap_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean;

   function Is_Minimap_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean;

   function Is_Scrollbar_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean;

   function Is_Scrollbar_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean;

   function Is_Gutter_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean;

   function Is_Gutter_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean;

end Editor.Input_Bridge.Pointer_Routing;
