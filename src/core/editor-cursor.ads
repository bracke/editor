package Editor.Cursor is

   --  Cursor shape used by render-packet caret rectangle emission.
   --
   --  The cursor is always rendered as a rectangle on Caret_Layer.  It is not
   --  represented as a glyph and does not affect Textrender state.
   type Cursor_Style is
     (Bar_Cursor,
      Block_Cursor,
      Underline_Cursor);

   --  Global cursor rendering configuration.
   --
   --  Bar_Width is used only for Bar_Cursor.  Underline_H is used only for
   --  Underline_Cursor.  Block_Cursor always uses the current font-derived
   --  editor cell width and height.
   type Cursor_Config is record
      Style       : Cursor_Style := Bar_Cursor;
      Bar_Width   : Positive := 1;
      Underline_H : Positive := 2;
   end record;

   --  Global cursor blink configuration.
   --
   --  Blink_Period_Sec is the complete on+off cycle.  Blink_Duty_Cycle is the
   --  visible fraction of that cycle.  Last_Input_Time_Sec anchors the phase so
   --  input makes the next render visible immediately.
   type Blink_Config is record
      Blink_Enabled       : Boolean := True;
      Blink_Period_Sec    : Float := 1.0;
      Blink_Duty_Cycle    : Float := 0.5;
      Last_Input_Time_Sec : Float := 0.0;
   end record;

   --  Return the active cursor rendering configuration.
   function Current return Cursor_Config;

   --  Replace the active cursor rendering configuration.
   procedure Set_Current
     (Config : Cursor_Config);

   --  Return the active cursor blink configuration.
   function Current_Blink return Blink_Config;

   --  Replace the active cursor blink configuration.
   procedure Set_Blink
     (Config : Blink_Config);

   --  Enable or disable cursor blinking.  Disabled blinking is always visible.
   procedure Set_Blink_Enabled
     (Enabled : Boolean);

   --  Reset the blink phase after input.  The cursor is visible at Now_Sec.
   procedure Notify_Input
     (Now_Sec : Float);

   --  Return whether cursor geometry should be emitted at Now_Sec.
   function Visible
     (Now_Sec : Float) return Boolean;

end Editor.Cursor;
