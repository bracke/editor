package body Editor.Input_Bridge.Pointer_Routing is

   use type Editor.Commands.Command_Kind;

   function Is_Minimap_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      case Kind is
         when Editor.Commands.Move_To_Point
            | Editor.Commands.Drag_To_Point
            | Editor.Commands.Start_Rectangle_Selection
            | Editor.Commands.Drag_Rectangle_To_Point
            | Editor.Commands.Add_Caret_At_Point
            | Editor.Commands.Select_Word_At_Point
            | Editor.Commands.Select_Line_At_Point =>
            return True;

         when others =>
            return False;
      end case;
   end Is_Minimap_Pointer_Command;

   function Is_Minimap_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Kind = Editor.Commands.Drag_To_Point
        or else Kind = Editor.Commands.Drag_Rectangle_To_Point;
   end Is_Minimap_Drag_Command;

   function Is_Scrollbar_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Is_Minimap_Pointer_Command (Kind);
   end Is_Scrollbar_Pointer_Command;

   function Is_Scrollbar_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Is_Minimap_Drag_Command (Kind);
   end Is_Scrollbar_Drag_Command;

   function Is_Gutter_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Kind = Editor.Commands.Move_To_Point
        or else Kind = Editor.Commands.Pointer_Hover
        or else Kind = Editor.Commands.Drag_To_Point
        or else Kind = Editor.Commands.Start_Rectangle_Selection
        or else Kind = Editor.Commands.Drag_Rectangle_To_Point
        or else Kind = Editor.Commands.Add_Caret_At_Point
        or else Kind = Editor.Commands.Select_Word_At_Point
        or else Kind = Editor.Commands.Select_Line_At_Point;
   end Is_Gutter_Pointer_Command;

   function Is_Gutter_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Kind = Editor.Commands.Drag_To_Point
        or else Kind = Editor.Commands.Drag_Rectangle_To_Point;
   end Is_Gutter_Drag_Command;

end Editor.Input_Bridge.Pointer_Routing;
