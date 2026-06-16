with AUnit.Assertions; use AUnit.Assertions;
with Interfaces.C;     use Interfaces.C;
with Editor.Layout;     use Editor.Layout;
with Editor.View;
with Editor.Render_Packet;
with Editor.Render_Layers; use Editor.Render_Layers;
with Editor.Input_Bridge;

package body Editor.Bridge.Tests is

   overriding function Name
     (T : Bridge_Test_Case)
      return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Bridge");
   end Name;

   -------------------------------------------------------------------------
   --  GLFW constants still used by the tests as input vocabulary
   -------------------------------------------------------------------------

   GLFW_Key_Left      : constant Interfaces.C.int := 263;
   GLFW_Key_Right     : constant Interfaces.C.int := 262;
   GLFW_Key_Up        : constant Interfaces.C.int := 265;
   GLFW_Key_Down      : constant Interfaces.C.int := 264;
   GLFW_Key_Home      : constant Interfaces.C.int := 268;
   GLFW_Key_End       : constant Interfaces.C.int := 269;
   GLFW_Key_Page_Up   : constant Interfaces.C.int := 266;
   GLFW_Key_Page_Down : constant Interfaces.C.int := 267;
   GLFW_Key_Z         : constant Interfaces.C.int := 90;
   GLFW_Key_Y         : constant Interfaces.C.int := 89;

   -------------------------------------------------------------------------
   --  Local helpers
   -------------------------------------------------------------------------
   function Text_X
   (Layout     : Editor.Layout.Layout_Config;
      Col        : Natural;
      Line_Count : Natural := 9) return Float
   is
   begin
      return Float
      (Editor.Layout.Text_Origin_X (Layout, Line_Count)
         + Col * Editor.Layout.Cell_W);
   end Text_X;

   function Text_Glyph_Count
   (Packet     : Editor.Render_Packet.Render_Packet;
      Layout     : Editor.Layout.Layout_Config;
      Line_Count : Natural := 9) return Natural
   is
      Count : Natural := 0;
      Left  : constant Float := Text_X (Layout, 0, Line_Count);
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Text_Layer)
           and then Float (Packet.Glyphs (Natural (I)).X) >= Left
         then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Text_Glyph_Count;

   procedure Reset_Bridge is
   begin
      Editor.Bridge.Editor_Init;
      Editor.View.Reset;
      Editor.View.Set_Viewport (800, 600);
      Editor.View.Set_Time_Seconds (0.0);
   end Reset_Bridge;

   procedure Send_Event
     (Kind  : Editor.Bridge.Event_Kind;
      Ch    : Interfaces.C.unsigned := 0;
      Shift : Boolean := False;
      Ctrl  : Boolean := False;
      Alt   : Boolean := False;
      X     : Interfaces.C.int := 0;
      Y     : Interfaces.C.int := 0)
   is
      Ev : Editor.Bridge.Platform_Event;
   begin
      Ev.Kind := Kind;
      Ev.Ch := Ch;
      Ev.Shift := (if Shift then 1 else 0);
      Ev.Ctrl := (if Ctrl then 1 else 0);
      Ev.Alt := (if Alt then 1 else 0);
      Ev.X := X;
      Ev.Y := Y;

      Editor.Bridge.Editor_Handle_Event (Ev);
   end Send_Event;

   procedure Drag_To
      (X     : Interfaces.C.int;
       Y     : Interfaces.C.int;
       Shift : Boolean := False) is
   begin
      Send_Event
      (Kind  => Editor.Bridge.Mouse_Drag,
         Shift => Shift,
         X     => X,
         Y     => Y);
   end Drag_To;

   procedure Send_Char (Ch : Character) is
   begin
      Send_Event
        (Kind => Editor.Bridge.Char_Input,
         Ch   => Interfaces.C.unsigned (Character'Pos (Ch)));
   end Send_Char;

   procedure Send_Codepoint (Code : Interfaces.C.unsigned) is
   begin
      Send_Event
        (Kind => Editor.Bridge.Char_Input,
         Ch   => Code);
   end Send_Codepoint;

   procedure Send_Key
     (Key   : Interfaces.C.int;
      Shift : Boolean := False;
      Ctrl  : Boolean := False) is
   begin
      case Key is
         when GLFW_Key_Left =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Left,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Right =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Right,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Up =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Up,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Down =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Down,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Home =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Home,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_End =>
            Send_Event
              (Kind  => Editor.Bridge.Key_End,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Page_Up =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Page_Up,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Page_Down =>
            Send_Event
              (Kind  => Editor.Bridge.Key_Page_Down,
               Shift => Shift,
               Ctrl  => Ctrl);

         when GLFW_Key_Z =>
            if Ctrl then
               Send_Event
                 (Kind  => Editor.Bridge.Key_Undo,
                  Shift => Shift,
                  Ctrl  => Ctrl);
            else
               Assert (False, "Send_Key: Z without Ctrl is unsupported in this test");
            end if;

         when GLFW_Key_Y =>
            if Ctrl then
               Send_Event
                 (Kind  => Editor.Bridge.Key_Redo,
                  Shift => Shift,
                  Ctrl  => Ctrl);
            else
               Assert (False, "Send_Key: Y without Ctrl is unsupported in this test");
            end if;

         when others =>
            Assert (False, "Send_Key: unsupported key code");
      end case;
   end Send_Key;

   procedure Send_Left (Shift : Boolean := False) is
   begin
      Send_Key (GLFW_Key_Left, Shift => Shift);
   end Send_Left;

   procedure Send_Right (Shift : Boolean := False) is
   begin
      Send_Key (GLFW_Key_Right, Shift => Shift);
   end Send_Right;

   procedure Send_Undo is
   begin
      Send_Key (GLFW_Key_Z, Ctrl => True);
   end Send_Undo;

   procedure Send_Redo is
   begin
      Send_Key (GLFW_Key_Y, Ctrl => True);
   end Send_Redo;

   procedure Send_Home is
   begin
      Send_Key (GLFW_Key_Home);
   end Send_Home;

   procedure Send_End is
   begin
      Send_Key (GLFW_Key_End);
   end Send_End;

   procedure Click_At
     (X     : Interfaces.C.int;
      Y     : Interfaces.C.int;
      Shift : Boolean := False) is
   begin
      Send_Event
        (Kind  => Editor.Bridge.Mouse_Down,
         Shift => Shift,
         X     => X,
         Y     => Y);
   end Click_At;

   procedure Get_Packet
     (Packet : out Editor.Render_Packet.Render_Packet) is
   begin
      Editor.Render_Packet.Build_Render_Packet (Packet);
   end Get_Packet;

   function Glyph_Count
     (Packet : Editor.Render_Packet.Render_Packet) return Natural is
   begin
      return Natural (Packet.Glyph_Count);
   end Glyph_Count;

   function Rect_Count
     (Packet : Editor.Render_Packet.Render_Packet) return Natural is
   begin
      return Natural (Packet.Rect_Count);
   end Rect_Count;

   function Rect_X
     (Packet : Editor.Render_Packet.Render_Packet;
      Index  : Natural) return Float is
   begin
      return Float (Packet.Rects (Index).X);
   end Rect_X;

   function Rect_W
     (Packet : Editor.Render_Packet.Render_Packet;
      Index  : Natural) return Float is
   begin
      return Float (Packet.Rects (Index).W);
   end Rect_W;

   function First_Rect_X_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Float
   is
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Layer) then
            return Float (Packet.Rects (Natural (I)).X);
         end if;
      end loop;

      Assert (False, "Expected rectangle layer was not present");
      return 0.0;
   end First_Rect_X_On_Layer;

   -------------------------------------------------------------------------
   --  Empty packet
   -------------------------------------------------------------------------

   procedure Test_Empty_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;
      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 0,
              "Empty bridge packet must contain no glyphs");
      Assert (Rect_Count (Packet) >= 1,
              "Empty bridge packet must still contain caret rect");
   end Test_Empty_Packet;

   -------------------------------------------------------------------------
   --  Insert text through bridge
   -------------------------------------------------------------------------

   procedure Test_Insert_Text_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 3,
              "Bridge packet must contain 3 glyphs after inserting abc");
      Assert (Rect_Count (Packet) >= 1,
              "Bridge packet must contain caret after inserting abc");
   end Test_Insert_Text_Packet;

   -------------------------------------------------------------------------
   --  Active selection through bridge
   -------------------------------------------------------------------------



   procedure Test_Unicode_Codepoint_Input_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('A');
      Send_Codepoint (16#00E9#);
      Send_Codepoint (16#1F642#);

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 3,
              "Unicode codepoint input must produce one grid glyph per scalar");
   end Test_Unicode_Codepoint_Input_Packet;


   procedure Test_Invalid_Codepoint_Input_Uses_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Codepoint (16#D800#);

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 1,
              "Invalid codepoint input must be replaced by one scalar");
   end Test_Invalid_Codepoint_Input_Uses_Replacement;

   procedure Test_Active_Selection_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');

      Send_Left (Shift => True);
      Send_Left (Shift => True);

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 3,
              "Selection must not change glyph count");
      Assert (Rect_Count (Packet) >= 2,
              "Active selection must add a selection rectangle");
   end Test_Active_Selection_Packet;

   -------------------------------------------------------------------------
   --  Replace selection through bridge
   -------------------------------------------------------------------------

   procedure Test_Replace_Selection_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');

      Send_Left (Shift => True);
      Send_Left (Shift => True);

      Send_Char ('x');

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 2,
              "Replacing selection in abc with x must leave 2 glyphs");
      Assert (Rect_Count (Packet) >= 1,
              "Packet must still contain caret after replace");
   end Test_Replace_Selection_Packet;

   -------------------------------------------------------------------------
   --  Undo / Redo through bridge
   -------------------------------------------------------------------------

   procedure Test_Undo_Redo_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');

      Send_Left (Shift => True);
      Send_Left (Shift => True);
      Send_Char ('X');

      Send_Undo;
      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 3,
              "Undo must restore abc, i.e. 3 glyphs");

      Send_Redo;
      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 2,
              "Redo must restore aX, i.e. 2 glyphs");
   end Test_Undo_Redo_Packet;

   -------------------------------------------------------------------------
   --  Shift-click selection through bridge
   -------------------------------------------------------------------------

   --  procedure Test_Shift_Click_Selection_Packet
   --    (T : in out AUnit.Test_Cases.Test_Case'Class) is
   --     pragma Unreferenced (T);

   --     Packet : Editor.Render_Packet.Render_Packet;
   --  begin
   --     Reset_Bridge;

   --     Send_Char ('a');
   --     Send_Char ('b');
   --     Send_Char ('c');
   --     Send_Char ('d');

   --     Click_At (18, 10, Shift => False);
   --     Send_Event
   --       (Kind  => Editor.Bridge.Mouse_Down,
   --        Shift => True,
   --        X     => 58,
   --        Y     => 10);
   --     Drag_To (58, 10, Shift => True);

   --     Get_Packet (Packet);

   --     Assert (Glyph_Count (Packet) = 4,
   --             "Shift-click selection must not change glyph count");
   --     Assert (Rect_Count (Packet) >= 2,
   --             "Shift-click selection must add a selection rectangle");
   --  end Test_Shift_Click_Selection_Packet;

   -------------------------------------------------------------------------
   --  Home / End through bridge
   -------------------------------------------------------------------------

   procedure Test_Home_End_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
      Caret_X_After_Home : Float;
      Caret_X_After_End  : Float;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');
      Send_Char (ASCII.LF);
      Send_Char ('d');
      Send_Char ('e');
      Send_Char ('f');

      Send_Home;
      Get_Packet (Packet);
      Caret_X_After_Home := First_Rect_X_On_Layer (Packet, Caret_Layer);

      Send_End;
      Get_Packet (Packet);
      Caret_X_After_End := First_Rect_X_On_Layer (Packet, Caret_Layer);

      Assert (Caret_X_After_End > Caret_X_After_Home,
              "End must move caret to the right of Home on the same line");
   end Test_Home_End_Packet;

   -------------------------------------------------------------------------
   --  Uneven line vertical movement through bridge
   -------------------------------------------------------------------------

   procedure Test_Uneven_Line_Up_Down_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');
      Send_Char ('d');
      Send_Char ('e');
      Send_Char ('f');
      Send_Char (ASCII.LF);
      Send_Char ('x');
      Send_Char ('y');
      Send_Char (ASCII.LF);
      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');
      Send_Char ('d');
      Send_Char ('e');
      Send_Char ('f');

      Send_Left;
      Send_Key (GLFW_Key_Up);
      Send_Key (GLFW_Key_Down);

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current, 3) = 14,
              "Vertical movement must not change glyph count");
      Assert (Rect_Count (Packet) >= 1,
              "Packet must still contain caret after vertical movement");
   end Test_Uneven_Line_Up_Down_Packet;

   procedure Test_NewLine_Should_Not_Be_A_Glyph
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char (ASCII.LF);
      Send_Char ('b');

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current, 3) = 2,
              "Newlines must not produce glyphs");
   end Test_NewLine_Should_Not_Be_A_Glyph;

   procedure Test_Drag_Selection_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Bridge;

      Send_Char ('a');
      Send_Char ('b');
      Send_Char ('c');
      Send_Char ('d');

      --  Establish anchor with a normal click near column 1
      Click_At (18, 10, Shift => False);

      --  Extend selection by dragging to the right
      Drag_To (58, 10, Shift => False);

      Get_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) = 4,
              "Drag selection must not change glyph count");
      Assert (Rect_Count (Packet) >= 2,
              "Drag selection must add a selection rectangle");
   end Test_Drag_Selection_Packet;

   procedure Test_Bridge_Build_Render_Packet_After_Reset
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
      (Packet.Rect_Count >= 1,
         "Bridge render packet after reset must contain caret");
   end Test_Bridge_Build_Render_Packet_After_Reset;

   overriding procedure Register_Tests
     (T : in out Bridge_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Packet'Access, "Empty Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Insert_Text_Packet'Access, "Insert Text Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unicode_Codepoint_Input_Packet'Access,
         "Unicode Codepoint Input Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Invalid_Codepoint_Input_Uses_Replacement'Access,
         "Invalid Codepoint Input Uses Replacement");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Selection_Packet'Access, "Active Selection Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Selection_Packet'Access, "Replace Selection Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Drag_Selection_Packet'Access, "Drag Selection Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Redo_Packet'Access, "Undo Redo Packet");

  --    AUnit.Test_Cases.Registration.Register_Routine
  --      (T, Test_Shift_Click_Selection_Packet'Access,
  --       "Shift Click Selection Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Home_End_Packet'Access, "Home End Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Uneven_Line_Up_Down_Packet'Access,
         "Uneven Line Up Down Packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_NewLine_Should_Not_Be_A_Glyph'Access,
         "NewLine Should Not Be A Glyph");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bridge_Build_Render_Packet_After_Reset'Access,
         "Bridge Build Render Packet After Reset");
   end Register_Tests;

end Editor.Bridge.Tests;
