with Interfaces.C;

package Editor.Bridge is

   subtype C_Int is Interfaces.C.int;
   subtype C_Codepoint is Interfaces.C.unsigned;

   ------------------------------------------------------------------
   -- Platform Event Model
   --
   -- These numeric values must match the C runtime constants exactly.
   ------------------------------------------------------------------
   type Event_Kind is
     (Char_Input,
      Key_Left,
      Key_Right,
      Key_Up,
      Key_Down,
      Key_Home,
      Key_End,
      Key_Page_Up,
      Key_Page_Down,
      Key_Backspace,
      Key_Delete,
      Key_Undo,
      Key_Redo,
      Key_Save,
      Mouse_Down,
      Mouse_Drag,
      Select_Word,
      Select_Line,
      Add_Caret,
      Clear_Extra_Carets,
      Open_Command_Palette,
      Mouse_Move,
      Key_Tab,
      Key_F2,
      Key_F3,
      Mouse_Wheel);
   pragma Convention (C, Event_Kind);

   for Event_Kind use
     (Char_Input         => 0,
      Key_Left           => 1,
      Key_Right          => 2,
      Key_Up             => 3,
      Key_Down           => 4,
      Key_Home           => 5,
      Key_End            => 6,
      Key_Page_Up        => 7,
      Key_Page_Down      => 8,
      Key_Backspace      => 9,
      Key_Delete         => 10,
      Key_Undo           => 11,
      Key_Redo           => 12,
      Key_Save           => 13,
      Mouse_Down         => 14,
      Mouse_Drag         => 15,
      Select_Word        => 16,
      Select_Line        => 17,
      Add_Caret          => 18,
      Clear_Extra_Carets => 19,
      Open_Command_Palette => 20,
      Mouse_Move          => 21,
      Key_Tab             => 22,
      Key_F2              => 23,
      Key_F3              => 24,
      Mouse_Wheel         => 25);

   type Platform_Event is record
      Kind  : Event_Kind := Char_Input;
      Ch    : C_Codepoint := 0;
      Shift : C_Int := 0;
      Ctrl  : C_Int := 0;
      Alt   : C_Int := 0;
      X       : C_Int := 0;
      Y       : C_Int := 0;
      Wheel_X : C_Int := 0;
      Wheel_Y : C_Int := 0;
   end record;
   pragma Convention (C_Pass_By_Copy, Platform_Event);

   procedure Editor_Init;

   procedure Editor_Handle_Event
     (Ev : Platform_Event);

end Editor.Bridge;