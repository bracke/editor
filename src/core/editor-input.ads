package Editor.Input is

   type Key_Type is (
      Key_Insert,
      Key_Delete,
      Key_Left,
      Key_Right,
      Key_Char
   );

   type Input_Event is record
      Key : Key_Type;
      Ch  : Character := ASCII.NUL;
   end record;

   function To_Command
     (E   : Input_Event;
      Pos : Natural) return Editor.Commands.Command;

end Editor.Input;