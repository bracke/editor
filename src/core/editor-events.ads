package Editor.Events is

   type Event_Type is
     (Key_Press);

   type Key_Code is
     (Key_Character,
      Key_Left,
      Key_Right,
      Key_Up,
      Key_Down,
      Key_Home,
      Key_End,
      Key_Page_Up,
      Key_Page_Down,
      Key_Mouse_Left,
      Key_Backspace,
      Key_Delete,
      Key_Undo,
      Key_Redo,
      Key_Save,
      Key_Command_Palette);

   type Event is record
      Kind  : Event_Type := Key_Press;
      Key   : Key_Code   := Key_Character;
      Ch    : Character  := ASCII.NUL;
      Shift : Boolean    := False;
      Ctrl  : Boolean    := False;
      Alt   : Boolean    := False;
      X     : Natural    := 0;
      Y     : Natural    := 0;
   end record;

end Editor.Events;