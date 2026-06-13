with Editor.Commands;
with Editor.Unicode;

package Editor.Input is

   type Key_Type is
     (Key_Insert_Text_Input,
      Key_Delete_Char,
      Key_Forward_Delete_Char,
      Key_Move_Left,
      Key_Move_Right,
      Key_Move_Up,
      Key_Move_Down,
      Key_Home,
      Key_End,
      Key_Page_Up,
      Key_Page_Down,
      Key_Mouse_Left,
      Key_Undo,
      Key_Redo,
      Key_Save,
      Key_Command_Palette);

   type Input_Event is record
      Key   : Key_Type   := Key_Insert_Text_Input;
      Ch    : Character  := ASCII.NUL;
      Code  : Editor.Unicode.Code_Point := Wide_Wide_Character'Val (0);
      Shift : Boolean    := False;
      Ctrl  : Boolean    := False;
      Alt   : Boolean    := False;
      X     : Natural    := 0;
      Y     : Natural    := 0;
   end record;

   function To_Command
     (E   : Input_Event;
      Pos : Natural) return Editor.Commands.Command;

end Editor.Input;