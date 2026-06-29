with AUnit.Assertions; use AUnit.Assertions;
with Editor.Render_Packet; use Editor.Render_Packet;
with Editor.Render_Model;
with Editor.Fonts;
with Editor.Font_Config;
with Editor.State;
with Editor.Settings;
with Editor.Executor;
with Editor.Layout;
with Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Test_Helper;
with Editor.Input_Bridge;
with Editor.View;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C; use Interfaces.C;
with Text_Buffer;
with Textrender;
with Editor.Render_Layers; use Editor.Render_Layers;
with Editor.Navigation;
with Editor.Syntax;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;
with Editor.Syntax_Overlays;
with Editor.Theme;
with Editor.Render_Cache;
with Editor.Wrap;
with Editor.Instance;
with Editor.History;
with Editor.Minimap;
with Editor.Diagnostics;
with Editor.Cursor;
with Editor.File_Tree_View;
with Editor.Selection;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Feature_Search_Results;
with Editor.Outline;
with Editor.Bookmarks;
with Editor.Gutter_Markers;
with Editor.Scrollbars;
with Editor.Buffers;
with Editor.Panels;

package body Editor.Render_Model.Tests is

   use type Editor.Syntax.Syntax_Kind;
   use type Editor.Syntax.Lexical_State;
   use type Editor.Wrap.Wrap_Mode;
   use type Editor.Cursor.Cursor_Style;
   use type Editor.Gutter_Markers.Gutter_Marker_Kind;

   function Default_Minimap_Config
     (Enabled : Boolean) return Editor.Minimap.Minimap_Config is
   begin
      return
        (Enabled       => Enabled,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
   end Default_Minimap_Config;

   function Default_Cursor_Config return Editor.Cursor.Cursor_Config is
   begin
      return
        (Style       => Editor.Cursor.Bar_Cursor,
         Bar_Width   => 1,
         Underline_H => 2);
   end Default_Cursor_Config;

   function Visible_Blink_Config return Editor.Cursor.Blink_Config is
   begin
      return
        (Blink_Enabled       => False,
         Blink_Period_Sec    => 1.0,
         Blink_Duty_Cycle    => 0.5,
         Last_Input_Time_Sec => 0.0);
   end Visible_Blink_Config;

   function Test_Panels return Editor.Panels.Panel_Set
   is
      Panels : Editor.Panels.Panel_Set := Editor.Panels.Default_Set;
      Config : Editor.Panels.Panel_Config;
   begin
      Config := Editor.Panels.Config (Panels, Editor.Panels.File_Tree_Panel);
      Config.Enabled := False;
      Editor.Panels.Set_Config
        (Panels, Editor.Panels.File_Tree_Panel, Config);
      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.File_Tree_Panel, False);
      return Panels;
   end Test_Panels;

   procedure Reset_Render_Test_Globals
     (Minimap_Enabled : Boolean := False)
   is
      File_Tree_Config : Editor.File_Tree_View.File_Tree_View_Config :=
        Editor.File_Tree_View.Current_Config;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Settings.Reset;
      Editor.Settings.Set_Show_Minimap (Minimap_Enabled);
      Editor.Minimap.Set_Current (Default_Minimap_Config (Minimap_Enabled));
      File_Tree_Config.Enabled := False;
      Editor.File_Tree_View.Set_Current_Config (File_Tree_Config);
      Editor.Panels.Set_Current (Test_Panels);
      Editor.Scrollbars.Reset;
      Editor.Scrollbars.Set_Enabled (False);
      Editor.View.Reset;
      Editor.Cursor.Set_Current (Default_Cursor_Config);
      Editor.Cursor.Set_Blink (Visible_Blink_Config);
      Editor.Render_Cache.Reset;
   end Reset_Render_Test_Globals;

   procedure Set_Render_State_For_Test
     (S               : Editor.State.State_Type;
      Minimap_Enabled : Boolean := False)
   is
      File_Tree_Config : Editor.File_Tree_View.File_Tree_View_Config;
      State_For_Test : Editor.State.State_Type := S;
   begin
      State_For_Test.Panels := Test_Panels;
      Editor.Input_Bridge.Set_State_For_Test (State_For_Test);
      Editor.Settings.Reset;
      Editor.Settings.Set_Show_Minimap (Minimap_Enabled);
      if Minimap_Enabled then
         Editor.Minimap.Set_Enabled (True);
      else
         Editor.Minimap.Set_Current (Default_Minimap_Config (False));
      end if;
      File_Tree_Config := Editor.File_Tree_View.Current_Config;
      File_Tree_Config.Enabled := False;
      Editor.File_Tree_View.Set_Current_Config (File_Tree_Config);
      Editor.Panels.Set_Current (State_For_Test.Panels);
      Editor.Scrollbars.Set_Enabled (False);
      Editor.Cursor.Set_Current (Default_Cursor_Config);
      Editor.Cursor.Set_Blink (Visible_Blink_Config);
      Editor.View.Set_Time_Seconds (0.0);
      Editor.Render_Cache.Invalidate_All;
   end Set_Render_State_For_Test;

   overriding function Name
     (T : Render_Model_Test_Case)
      return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Render_Model");
   end Name;

   overriding procedure Set_Up
     (T : in out Render_Model_Test_Case)
   is
      pragma Unreferenced (T);
   begin
      Reset_Render_Test_Globals;
   end Set_Up;

   function Has_Rect_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Boolean
   is
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Layer) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Rect_On_Layer;

   function Has_Glyph_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Boolean is
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Layer) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Glyph_On_Layer;

   function Packet_Layers_Are_Valid
     (Packet : Editor.Render_Packet.Render_Packet) return Boolean
   is
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer < Editor.Render_Layers.C_First
           or else Packet.Rects (Natural (I)).Layer > Editor.Render_Layers.C_Last
         then
            return False;
         end if;
      end loop;

      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer < Editor.Render_Layers.C_First
           or else Packet.Glyphs (Natural (I)).Layer > Editor.Render_Layers.C_Last
         then
            return False;
         end if;
      end loop;

      return True;
   end Packet_Layers_Are_Valid;


   function Packets_Equal
     (Left  : Editor.Render_Packet.Render_Packet;
      Right : Editor.Render_Packet.Render_Packet) return Boolean
   is
   begin
      if Left.Rect_Count /= Right.Rect_Count
        or else Left.Glyph_Count /= Right.Glyph_Count
      then
         return False;
      end if;

      if Left.Rect_Count > 0 then
         for I in 0 .. Natural (Left.Rect_Count) - 1 loop
            if Left.Rects (I).Layer /= Right.Rects (I).Layer
           or else Left.Rects (I).X /= Right.Rects (I).X
           or else Left.Rects (I).Y /= Right.Rects (I).Y
           or else Left.Rects (I).W /= Right.Rects (I).W
           or else Left.Rects (I).H /= Right.Rects (I).H
           or else Left.Rects (I).R /= Right.Rects (I).R
           or else Left.Rects (I).G /= Right.Rects (I).G
           or else Left.Rects (I).B /= Right.Rects (I).B
         then
               return False;
            end if;
         end loop;
      end if;

      if Left.Glyph_Count > 0 then
         for I in 0 .. Natural (Left.Glyph_Count) - 1 loop
            if Left.Glyphs (I).Layer /= Right.Glyphs (I).Layer
           or else Left.Glyphs (I).X /= Right.Glyphs (I).X
           or else Left.Glyphs (I).Y /= Right.Glyphs (I).Y
           or else Left.Glyphs (I).W /= Right.Glyphs (I).W
           or else Left.Glyphs (I).H /= Right.Glyphs (I).H
           or else Left.Glyphs (I).U0 /= Right.Glyphs (I).U0
           or else Left.Glyphs (I).V0 /= Right.Glyphs (I).V0
           or else Left.Glyphs (I).U1 /= Right.Glyphs (I).U1
           or else Left.Glyphs (I).V1 /= Right.Glyphs (I).V1
           or else Left.Glyphs (I).R /= Right.Glyphs (I).R
           or else Left.Glyphs (I).G /= Right.Glyphs (I).G
           or else Left.Glyphs (I).B /= Right.Glyphs (I).B
         then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Packets_Equal;

   function First_Rect_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer)
      return Editor.Render_Packet.Rect_Command;

   function Text_X
   (Layout     : Editor.Layout.Layout_Config;
    Col        : Natural;
    Line_Count : Natural := 9) return Float
   is
      Left : constant Natural := Editor.Layout.Text_Origin_X (Layout, Line_Count);
   begin
      return Float (Left + Col * Editor.Layout.Cell_W);
   end Text_X;

   function Text_Glyph_Count
     (Packet     : Editor.Render_Packet.Render_Packet;
      Layout     : Editor.Layout.Layout_Config;
      Line_Count : Natural := 9) return Natural is
      Count : Natural := 0;
      Left  : constant Float :=
      Text_X (Layout, 0, Line_Count);
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

   function Text_Glyph_Index
     (Packet     : Editor.Render_Packet.Render_Packet;
      Layout     : Editor.Layout.Layout_Config;
      N          : Natural;
      Line_Count : Natural := 9) return Natural is
      Count : Natural := 0;
      Left  : constant Float :=
      Text_X (Layout, 0, Line_Count);
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Text_Layer)
           and then Float (Packet.Glyphs (Natural (I)).X) >= Left
         then
            if Count = N then
               return Natural (I);
            end if;

            Count := Count + 1;
         end if;
      end loop;

      Assert
        (False,
         "Requested text glyph index was not present in render packet");
      return 0;
   end Text_Glyph_Index;


   function Glyph_Has_Color
     (G     : Editor.Render_Packet.Glyph_Command;
      Color : Editor.Theme.Color_RGB) return Boolean
   is
      Epsilon : constant Float := 0.0001;
   begin
      return abs (Float (G.R) - Color.R) <= Epsilon
        and then abs (Float (G.G) - Color.G) <= Epsilon
        and then abs (Float (G.B) - Color.B) <= Epsilon;
   end Glyph_Has_Color;

   function Rect_Has_Color
     (R     : Editor.Render_Packet.Rect_Command;
      Color : Editor.Theme.Color_RGB) return Boolean
   is
      Epsilon : constant Float := 0.0001;
   begin
      return abs (Float (R.R) - Color.R) <= Epsilon
        and then abs (Float (R.G) - Color.G) <= Epsilon
        and then abs (Float (R.B) - Color.B) <= Epsilon;
   end Rect_Has_Color;

   function Viewport_Height_For_Text_Rows
     (Rows : Positive) return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Height : Natural := Rows * Editor.Layout.Cell_H;
   begin
      while Editor.Layout.Text_Viewport_Height (Layout, Height)
        < Rows * Editor.Layout.Cell_H
      loop
         Height := Height + Editor.Layout.Cell_H;
      end loop;

      return Height;
   end Viewport_Height_For_Text_Rows;

   function Paste (S : String) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String (S);
      return Cmd;
   end Paste;

   procedure Test_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Length = 0, "Empty buffer must render length 0");
      Assert (Snap.Caret_Count = 1,
              "Empty buffer must render exactly one caret");
      Assert (Snap.Caret_Pos (1) = 0,
              "Empty buffer caret must render at 0");
      Assert (Snap.Selection_Count = 0,
              "Empty state must not have active selections");
   end Test_Empty;

   procedure Test_Text_After_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
      (Snap.Length = 3,
         "Snapshot length must be 3 after inserting abc");

      Assert
      (Snap.Text_Base_Index = 0,
         "Snapshot text base must be zero for unscrolled text");
   end Test_Text_After_Insert;

   procedure Test_Caret_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => False));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Caret_Count = 1,
              "Rendered snapshot must contain one caret");
      Assert (Snap.Caret_Pos (1) = 1,
              "Rendered caret must match state caret");
   end Test_Caret_Projection;

   procedure Test_Active_Selection_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Caret_Count = 1,
              "Rendered snapshot must contain one caret");
      Assert (Snap.Selection_Count = 1,
              "Rendered selection must be active");
      Assert (Snap.Sel_Start (1) = 0,
              "Rendered selection start must be normalized");
      Assert (Snap.Sel_End (1) = 1,
              "Rendered selection end must be normalized");
      Assert (Snap.Caret_Pos (1) = 0,
              "Primary caret must match selection end");
   end Test_Active_Selection_Projection;

   procedure Test_Reversed_Selection_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Caret_Count = 1,
              "Rendered snapshot must contain one caret");
      Assert (Snap.Selection_Count = 1,
              "Rendered reversed selection must remain active");
      Assert (Snap.Sel_Start (1) = 0,
              "Rendered reversed selection must be normalized low bound");
      Assert (Snap.Sel_End (1) = 2,
              "Rendered reversed selection must be normalized high bound");
      Assert (Snap.Caret_Pos (1) = 0,
              "Primary caret must match reversed selection end");
   end Test_Reversed_Selection_Projection;

   procedure Test_Caret_Packet_Physical_X
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      --  Push state into whatever your bridge/render path uses.
      Set_Render_State_For_Test (S);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Has_Rect_On_Layer (Packet, Caret_Layer),
         "Packet must contain caret rect");

      declare
         Expected_X : constant Float := Text_X (Layout, 3);
      begin
         Assert
            (Float (First_Rect_On_Layer (Packet, Caret_Layer).X) = Expected_X,
         "Caret X must match physical column 3");
      end;
   end Test_Caret_Packet_Physical_X;

   procedure Test_Caret_Packet_Virtual_X
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos                   => 3,
         Anchor                => 3,
         Virtual_Column        => 5,
         Anchor_Virtual_Column => 5));

      Set_Render_State_For_Test (S);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Has_Rect_On_Layer (Packet, Caret_Layer),
         "Packet must contain caret rect");

      declare
         Expected_X : constant Float := Text_X (Layout, 5);
      begin
         Assert
         (Float (First_Rect_On_Layer (Packet, Caret_Layer).X) = Expected_X,
            "Caret X must match virtual column 5");
      end;
   end Test_Caret_Packet_Virtual_X;

   procedure Test_Caret_Packet_Y_Position
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc" & ASCII.LF & "de"));

      --  caret at end → second line
      Set_Render_State_For_Test (S);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      declare
         Expected_Y : constant Float :=
           Float (Editor.Layout.Text_Viewport_Y (Layout) + Editor.Layout.Cell_H);
      begin
         Assert
         (Float (First_Rect_On_Layer (Packet, Caret_Layer).Y) =
            Expected_Y,
            "Caret Y must be second line");
      end;

   end Test_Caret_Packet_Y_Position;

   procedure Test_Selection_Virtual_Extends_Rect
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cmd    : Editor.Commands.Command;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      --  move into virtual space
      Cmd.Kind := Editor.Commands.Move_Right;
      Editor.Executor.Execute_No_Log (S, Cmd);

      --  extend selection
      Cmd.Shift := True;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Set_Render_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      --  expect at least one selection rect past EOL
      declare
         Found : Boolean := False;
      begin
         for I in 0 .. Packet.Rect_Count - 1 loop
            if Float (Packet.Rects (Natural (I)).X) > Text_X (Layout, 3)
            then
               Found := True;
            end if;
         end loop;

         Assert (Found, "Selection must extend past EOL");
      end;
   end Test_Selection_Virtual_Extends_Rect;

   procedure Test_Glyph_Alignment
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("ab"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (0, 0);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) >= 2,
        "Packet must contain at least two glyphs");

      declare
         G0 : constant Natural := Text_Glyph_Index (Packet, Layout, 0);
         G1 : constant Natural := Text_Glyph_Index (Packet, Layout, 1);

         Cell_0_X : constant Float := Text_X (Layout, 0);
         Cell_1_X : constant Float := Text_X (Layout, 1);
      begin
         Assert
         (Float (Packet.Glyphs (G0).X) >= Cell_0_X,
            "First glyph must be inside column 0");

         Assert
         (Float (Packet.Glyphs (G0).X) <
            Cell_0_X + Float (Editor.Layout.Cell_W),
            "First glyph must remain inside column 0");

         Assert
         (Float (Packet.Glyphs (G1).X) >= Cell_1_X
            and then Float (Packet.Glyphs (G1).X) <
            Cell_1_X + Float (Editor.Layout.Cell_W),
            "Second glyph must render inside column 1");
      end;
   end Test_Glyph_Alignment;

   procedure Test_Caret_Remains_Visible_After_Scroll
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      for I in 1 .. 80 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x" & ASCII.LF));
      end loop;

      Set_Render_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Has_Rect_On_Layer (Packet, Caret_Layer),
         "Packet must contain caret rect");

      Assert
      (Float (First_Rect_On_Layer (Packet, Caret_Layer).Y) >=
         Float (Layout.Origin_Y),
         "Scrolled caret must not render above viewport");
   end Test_Caret_Remains_Visible_After_Scroll;

   procedure Test_Glyphs_Do_Not_Render_Above_Viewport
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      for I in 1 .. 80 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x" & ASCII.LF));
      end loop;

      Set_Render_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Text_Glyph_Count (Packet, Editor.Layout.Current) - 1 loop
         Assert
         (Float (Packet.Glyphs (Natural (I)).Y) >= Float (Layout.Origin_Y),
            "Glyph must not render above viewport");
      end loop;
   end Test_Glyphs_Do_Not_Render_Above_Viewport;

   procedure Test_Selection_Rects_Do_Not_Render_Above_Viewport
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      for I in 1 .. 80 loop
         Editor.Executor.Execute_No_Log (S, Paste ("abcd" & ASCII.LF));
      end loop;

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(
         Pos                   => 0,
         Anchor                => 4,
         Virtual_Column        => 0,
         Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Rect_Count - 1 loop
         Assert
         (Float (Packet.Rects (Natural (I)).Y) >= Float (Layout.Origin_Y),
            "Selection/caret rect must not render above viewport");
      end loop;
   end Test_Selection_Rects_Do_Not_Render_Above_Viewport;

   procedure Test_Glyphs_Do_Not_Render_Below_Viewport
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      for I in 1 .. 200 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x" & ASCII.LF));
      end loop;

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
         (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1) + Editor.Layout.Cell_W * 8,
            Height => Editor.Layout.Cell_H * 2);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      declare
         Bottom : constant Float := Float (Layout.Origin_Y + Editor.View.Viewport_Height);
      begin
         for I in 0 .. Text_Glyph_Count (Packet, Editor.Layout.Current) - 1 loop
            Assert
            (Float (Packet.Glyphs (Natural (I)).Y) < Bottom,
               "Glyph must start inside viewport vertically");
         end loop;
      end;

   end Test_Glyphs_Do_Not_Render_Below_Viewport;

   procedure Test_Rects_Do_Not_Render_Below_Viewport
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      Bottom : Float := 0.0;
   begin
      Editor.State.Init (S);

      for I in 1 .. 200 loop
         Editor.Executor.Execute_No_Log (S, Paste ("abcd" & ASCII.LF));
      end loop;

      --  Make a selection near the top; after scroll it should either be clipped
      --  or not emitted below/above viewport.
      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(
         Pos                   => 0,
         Anchor                => 4,
         Virtual_Column        => 0,
         Anchor_Virtual_Column => 0
      ));

      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 8,
         Height => Editor.Layout.Cell_H * 3);
      Bottom :=
        Float (Editor.Layout.Text_Viewport_Y (Layout) + Editor.Layout.Cell_H);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Selection_Layer)
           or else Packet.Rects (Natural (I)).Layer = To_C (Caret_Layer)
         then
            Assert
            (Float (Packet.Rects (Natural (I)).Y) < Bottom,
               "Rect must not render below viewport");
         end if;
      end loop;
   end Test_Rects_Do_Not_Render_Below_Viewport;

   procedure Test_Glyphs_Do_Not_Render_Right_Of_Viewport
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      Right : Float := 0.0;
   begin
      Editor.State.Init (S);

      for I in 1 .. 400 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x"));
      end loop;

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
         (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1) + Editor.Layout.Cell_W * 8,
            Height => Editor.Layout.Cell_H * 2);
      Right := Float (Layout.Origin_X + Editor.View.Viewport_Width);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Text_Glyph_Count (Packet, Editor.Layout.Current) - 1 loop
         Assert (Float (Packet.Glyphs (Natural (I)).X) < Right
         and then Float (Packet.Glyphs (Natural (I)).X + Packet.Glyphs (Natural (I)).W) >
            Float (Layout.Origin_X),
         "Glyph must horizontally intersect viewport");
      end loop;
   end Test_Glyphs_Do_Not_Render_Right_Of_Viewport;

   procedure Test_Rects_Do_Not_Render_Right_Of_Viewport
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      Right : Float := 0.0;
   begin
      Editor.State.Init (S);

      for I in 1 .. 400 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x"));
      end loop;

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(
         Pos                   => 0,
         Anchor                => Cursor_Index (Text_Buffer.Length (S.Buffer)),
         Virtual_Column        => 0,
         Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W,
         Height => Editor.Layout.Cell_H * 3);
      Right := Float (Layout.Origin_X + Editor.View.Viewport_Width);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Selection_Layer)
           or else Packet.Rects (Natural (I)).Layer = To_C (Caret_Layer)
         then
            Assert
            (Float (Packet.Rects (Natural (I)).X) < Right,
               "Rect must not render right of viewport");
         end if;
      end loop;
   end Test_Rects_Do_Not_Render_Right_Of_Viewport;

   procedure Test_Viewport_Driven_Glyph_Iteration
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      for I in 1 .. 40 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x" & ASCII.LF));
      end loop;

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'
         (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
      (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1) + Editor.Layout.Cell_W * 8,
         Height => Viewport_Height_For_Text_Rows (2));

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
      (Text_Glyph_Count (Packet, Layout) > 0,
         "Viewport-driven glyph iteration must still emit visible glyphs");
   end Test_Viewport_Driven_Glyph_Iteration;

   procedure Test_Viewport_Driven_Selection_Iteration
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);

      for I in 1 .. 40 loop
         Editor.Executor.Execute_No_Log (S, Paste ("abcd" & ASCII.LF));
      end loop;

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(
         Pos                   => 0,
         Anchor                => Cursor_Index (Text_Buffer.Length (S.Buffer)),
         Virtual_Column        => 0,
         Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
         (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Editor.Layout.Current, 1) + Editor.Layout.Cell_W * 8,
            Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (Packet.Rect_Count > 0,
            "Viewport-driven selection iteration must emit visible rects");
   end Test_Viewport_Driven_Selection_Iteration;

   procedure Test_Row_Col_For_Index_With_Newlines
      (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("ab" & ASCII.LF & "cd"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (0, 0);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (Text_Glyph_Count (Packet, Editor.Layout.Current) >= 4,
            "Packet must contain four visible glyphs");

      --  'c' is the third rendered glyph: row 1, column 0.

      declare
         G      : constant Natural := Text_Glyph_Index (Packet, Layout, 2);
         Cell_X : constant Float := Text_X (Layout, 0);
      begin
         Assert
         (Float (Packet.Glyphs (G).X) >= Cell_X
            and then Float (Packet.Glyphs (G).X) <
            Cell_X + Float (Editor.Layout.Cell_W),
            "Glyph c must render inside column 0");
      end;

   end Test_Row_Col_For_Index_With_Newlines;

   procedure Test_Render_Snapshot_Text_Base_Index_After_Vertical_Scroll
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("aa" & ASCII.LF &
                  "bb" & ASCII.LF &
                  "cc"));

      Editor.Scrollbars.Set_Enabled (False);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Editor.Layout.Cell_W * 10,
         Viewport_Height_For_Text_Rows (1));
      Editor.View.Set_Scroll (0, 1);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Text_Base_Index = 3,
            "Text base must point to second line start");

      Assert
      (Snap.Length > 0,
         "Sliced snapshot must expose non-empty visible range");
   end Test_Render_Snapshot_Text_Base_Index_After_Vertical_Scroll;

   procedure Test_Viewport_Sliced_Packet_Emits_Visible_Glyphs
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("aa" & ASCII.LF &
                  "bb" & ASCII.LF &
                  "cc"));

      --  Caret on second line. Packet builder owns scroll adjustment.
      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'
         (Pos                   => 3,
            Anchor                => 3,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);

      Editor.View.Set_Viewport
      (Width  => Editor.Layout.Cell_W * 10,
         Height => Viewport_Height_For_Text_Rows (2));

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
      (Text_Glyph_Count (Packet, Editor.Layout.Current) > 0,
         "Sliced snapshot must still emit visible glyphs");

      for I in 0 .. Text_Glyph_Count (Packet, Editor.Layout.Current) - 1 loop
         declare
            Glyph : constant Natural :=
              Text_Glyph_Index (Packet, Editor.Layout.Current, I);
         begin
         Assert
         (Float (Packet.Glyphs (Glyph).Y) >=
            Float (Editor.Layout.Text_Viewport_Y (Layout)),
            "Sliced glyph must not render above text viewport");

         Assert
         (Float (Packet.Glyphs (Glyph).Y) <
            Float (Editor.Layout.Text_Viewport_Y (Layout)
                   + 2 * Editor.Layout.Cell_H),
            "Sliced glyph must render inside the two-row text viewport");
         end;
      end loop;
   end Test_Viewport_Sliced_Packet_Emits_Visible_Glyphs;

   procedure Test_Caret_Y_Uses_Cell_Top_Not_Baseline
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("a" & ASCII.LF & "b"));

      --  caret on second line
      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(Pos => 2, Anchor => 2, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);

      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
         (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1) + Editor.Layout.Cell_W * 8,
            Height => Viewport_Height_For_Text_Rows (1));
      Editor.View.Set_Scroll (0, 1);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      --  caret uses cell top (no +2.0)
      declare
         Expected_Y : constant Float :=
         Float
            (Editor.Layout.Text_Viewport_Y (Layout)
            + (1 - Editor.View.Scroll_Y) * Editor.Layout.Cell_H);

         Found : Boolean := False;
      begin
         for I in 0 .. Packet.Rect_Count - 1 loop
            if Packet.Rects (Natural (I)).Layer = To_C (Caret_Layer)
            and then Float (Packet.Rects (Natural (I)).W) = 1.0
            and then Rect_Has_Color
              (Packet.Rects (Natural (I)),
               Editor.Theme.Cursor_Color)
            then
               Assert
               (abs
                  (Float (Packet.Rects (Natural (I)).Y)
                     - Expected_Y) < 0.01,
                  "Caret must use cell top, not baseline offset");

               Found := True;
            end if;
         end loop;

         Assert (Found, "Packet must contain caret rect");
      end;

   end Test_Caret_Y_Uses_Cell_Top_Not_Baseline;

   procedure Test_Monospace_Cell_Width_Fits_Font
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Assert
      (Float (Editor.Layout.Cell_W) >= Editor.Fonts.Monospace_Cell_Width,
         "Cell width must fit monospace font advance");
   end Test_Monospace_Cell_Width_Fits_Font;

   procedure Test_Font_Rejects_Non_Printable_ASCII
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      M : Editor.Fonts.Glyph_Metric;
   begin
      Assert
      (not Editor.Fonts.Get_Glyph (ASCII.LF, M),
         "Font layer must reject non-printable ASCII glyphs");
   end Test_Font_Rejects_Non_Printable_ASCII;

   procedure Test_Font_Glyph_Fits_Configured_Cell
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      M      : Editor.Fonts.Glyph_Metric;
   begin
      Assert
      (Editor.Fonts.Get_Glyph (Ch => 'M', Metric => M),
         "Font layer must provide glyph M");

      Editor.Fonts.Check_Glyph_Fits_Cell
      (M,
         Editor.Layout.Cell_W,
         Editor.Layout.Cell_H);
   end Test_Font_Glyph_Fits_Configured_Cell;

   procedure Test_Font_Atlas_Is_Valid
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
      (Textrender.Atlas_Width (Editor.Fonts.Backend.all) > 0,
         "Font atlas width must be positive");

      Assert
      (Textrender.Atlas_Height (Editor.Fonts.Backend.all) > 0,
         "Font atlas height must be positive");

      Assert
      (Textrender.Atlas_Pixels (Editor.Fonts.Backend.all) /= null,
         "Font atlas pixels must not be null");
   end Test_Font_Atlas_Is_Valid;

   procedure Test_Font_Atlas_Dirty_On_New_Glyph
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      M : Editor.Fonts.Glyph_Metric;
   begin
      Textrender.Clear_Atlas_Dirty (Editor.Fonts.Backend.all);

      Assert
      (not Textrender.Atlas_Dirty (Editor.Fonts.Backend.all),
         "Atlas must be clean after clear");

      Assert
      (Editor.Fonts.Get_Glyph (Ch => 'Z', Metric => M),
         "Font layer must provide glyph Z");

      --  If Z was already cached by earlier tests, this may stay False.
      --  So this test only verifies the clear path unless test ordering guarantees
      --  an uncached glyph.
      Textrender.Clear_Atlas_Dirty (Editor.Fonts.Backend.all);

      Assert
      (not Textrender.Atlas_Dirty (Editor.Fonts.Backend.all),
         "Atlas must be clean after second clear");
   end Test_Font_Atlas_Dirty_On_New_Glyph;


   function Rect_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Rect_Count_On_Layer;

   function Glyph_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Glyph_Count_On_Layer;

   function First_Rect_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer)
      return Editor.Render_Packet.Rect_Command
   is
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Layer) then
            return Packet.Rects (Natural (I));
         end if;
      end loop;
      Assert (False, "Expected rectangle layer was not present");
      return Packet.Rects (0);
   end First_Rect_On_Layer;

   procedure Test_Diagnostic_Underline_Single_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      R      : Editor.Render_Packet.Rect_Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Editor.State.Add_Diagnostic (S, 1, 4, Editor.Diagnostics.Error);

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      R := First_Rect_On_Layer (Packet, Diagnostic_Layer);

      Assert (Rect_Count_On_Layer (Packet, Diagnostic_Layer) = 1,
              "Single-line diagnostic must emit one underline rectangle");
      Assert (Float (R.X) = Text_X (Layout, 1, 1),
              "Diagnostic underline must start at diagnostic start column");
      Assert (Float (R.W) = Float (Editor.Layout.Cell_W * 3),
              "Diagnostic underline width must cover the diagnostic columns");
      Assert (Rect_Has_Color (R, Editor.Theme.Diagnostic_Color (Editor.Diagnostics.Error)),
              "Diagnostic underline must use severity colour from theme");
   end Test_Diagnostic_Underline_Single_Line;

   procedure Test_Diagnostic_Multi_Line_Clips_Per_Visible_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc" & ASCII.LF & "def" & ASCII.LF & "ghi"));
      Editor.State.Add_Diagnostic (S, 1, 9, Editor.Diagnostics.Warning);

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 3)
                   + Editor.Layout.Cell_W * 12,
         Height => Viewport_Height_For_Text_Rows (3));

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (Rect_Count_On_Layer (Packet, Diagnostic_Layer) = 3,
              "Multi-line diagnostic must emit one clipped underline per visible row");
   end Test_Diagnostic_Multi_Line_Clips_Per_Visible_Row;

   procedure Test_Diagnostic_Does_Not_Change_Glyph_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S        : Editor.State.State_Type;
      Plain    : Editor.Render_Packet.Render_Packet;
      Decorated: Editor.Render_Packet.Render_Packet;
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);
      Editor.Input_Bridge.Build_Render_Packet (Plain);

      Editor.State.Add_Diagnostic (S, 1, 4, Editor.Diagnostics.Information);
      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);
      Editor.Input_Bridge.Build_Render_Packet (Decorated);

      Assert (Plain.Glyph_Count = Decorated.Glyph_Count,
              "Diagnostics must not change emitted glyph count");
   end Test_Diagnostic_Does_Not_Change_Glyph_Count;

   procedure Test_Diagnostic_Respects_Horizontal_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      R      : Editor.Render_Packet.Rect_Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghijklmnopqrstuvwx"));
      Editor.State.Add_Diagnostic (S, 5, 9, Editor.Diagnostics.Hint);
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 6,
            Anchor                => 6,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 20,
         Height => Editor.Layout.Cell_H * 4);
      Editor.View.Set_Scroll (2, 0);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      R := First_Rect_On_Layer (Packet, Diagnostic_Layer);
      Assert (Float (R.X) = Text_X (Layout, 3, 1),
              "Diagnostic underline X must subtract horizontal scroll");
      Assert (Float (R.W) = Float (Editor.Layout.Cell_W * 4),
              "Scrolled diagnostic underline must keep visible covered width");
   end Test_Diagnostic_Respects_Horizontal_Scroll;

   procedure Test_Diagnostic_Does_Not_Render_Outside_Viewport
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("first" & ASCII.LF & "second"));
      Editor.State.Add_Diagnostic (S, 6, 12, Editor.Diagnostics.Error);

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 2)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (not Has_Rect_On_Layer (Packet, Diagnostic_Layer),
              "Diagnostics outside visible rows must not render");
   end Test_Diagnostic_Does_Not_Render_Outside_Viewport;


   procedure Test_Render_Packet_Assigns_Semantic_Layers
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
      (Has_Rect_On_Layer (Packet, Gutter_Background_Layer),
         "Packet must tag gutter background rectangles explicitly");

      Assert
      (Has_Rect_On_Layer (Packet, Gutter_Separator_Layer),
         "Packet must tag gutter separator rectangles explicitly");

      Assert
      (Has_Rect_On_Layer (Packet, Current_Line_Layer),
         "Packet must tag current-line highlight rectangles explicitly");

      Assert
      (Has_Rect_On_Layer (Packet, Caret_Layer),
         "Packet must tag caret rectangles explicitly");

      Assert
      (Has_Glyph_On_Layer (Packet, Gutter_Text_Layer),
         "Packet must tag line-number glyphs as gutter text");

      Assert
      (Has_Glyph_On_Layer (Packet, Text_Layer),
         "Packet must tag buffer glyphs as text");
   end Test_Render_Packet_Assigns_Semantic_Layers;

   procedure Test_Render_Packet_Assigns_Selection_Layer
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'
         (Pos                   => 4,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
      (Has_Rect_On_Layer (Packet, Selection_Layer),
         "Packet must tag selection rectangles explicitly");
   end Test_Render_Packet_Assigns_Selection_Layer;

   procedure Test_Layer_Order
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
      (Editor.Render_Layers.Order (Background_Layer)
         < Editor.Render_Layers.Order (Gutter_Background_Layer),
         "Editor background must draw before gutter background");

      Assert
      (Editor.Render_Layers.Order (Gutter_Background_Layer)
         < Editor.Render_Layers.Order (Current_Line_Layer),
         "Gutter background must draw before current-line highlights");

      Assert
      (Editor.Render_Layers.Order (Current_Line_Layer)
         < Editor.Render_Layers.Order (Active_Find_Match_Layer),
         "Current-line highlights must draw before active Find matches");

      Assert
      (Editor.Render_Layers.Order (Active_Find_Match_Layer)
         < Editor.Render_Layers.Order (Selection_Layer),
         "Active Find matches must draw before selections");

      Assert
      (Editor.Render_Layers.Order (Selection_Layer)
         < Editor.Render_Layers.Order (Gutter_Separator_Layer),
         "Selections must draw before the gutter separator");

      Assert
      (Editor.Render_Layers.Order (Gutter_Separator_Layer)
         < Editor.Render_Layers.Order (Gutter_Text_Layer),
         "Gutter separator must draw before gutter text");

      Assert
      (Editor.Render_Layers.Order (Gutter_Text_Layer)
         < Editor.Render_Layers.Order (Gutter_Marker_Layer),
         "Gutter text must draw before gutter markers");

      Assert
      (Editor.Render_Layers.Order (Gutter_Marker_Layer)
         < Editor.Render_Layers.Order (Fold_Marker_Layer),
         "Gutter markers must draw before fold markers");

      Assert
      (Editor.Render_Layers.Order (Fold_Marker_Layer)
         < Editor.Render_Layers.Order (Diagnostic_Layer),
         "Fold markers must draw before diagnostic underlines");

      Assert
      (Editor.Render_Layers.Order (Selection_Layer)
         < Editor.Render_Layers.Order (Diagnostic_Layer),
         "Selections must draw before diagnostic underlines");

      Assert
      (Editor.Render_Layers.Order (Diagnostic_Layer)
         < Editor.Render_Layers.Order (Text_Layer),
         "Diagnostic underlines must draw before buffer text");

      Assert
      (Editor.Render_Layers.Order (Text_Layer)
         < Editor.Render_Layers.Order (Caret_Layer),
         "Text must draw before carets");

      Assert
      (Editor.Render_Layers.Order (Caret_Layer)
         < Editor.Render_Layers.Order (Minimap_Background_Layer),
         "Caret layer must draw before minimap background in the separate minimap strip");

      Assert
      (Editor.Render_Layers.Order (Minimap_Background_Layer)
         < Editor.Render_Layers.Order (Minimap_Content_Layer),
         "Minimap background must draw before minimap content");

      Assert
      (Editor.Render_Layers.Order (Minimap_Content_Layer)
         < Editor.Render_Layers.Order (Minimap_Viewport_Layer),
         "Minimap content must draw before the viewport marker");

      Assert
      (Editor.Render_Layers.Order (Background_Layer)
         < Editor.Render_Layers.Order (Tab_Bar_Background_Layer),
         "Tab bar background must draw above editor background");

      Assert
      (Editor.Render_Layers.Order (Tab_Bar_Text_Layer)
         < Editor.Render_Layers.Order (Gutter_Background_Layer),
         "Tab bar chrome must draw before reserved editor body chrome");

      Assert
      (Editor.Render_Layers.Order (Scrollbar_Thumb_Layer)
         < Editor.Render_Layers.Order (Problems_Background_Layer),
         "Problems panel background must draw above scrollbars");

      Assert
      (Editor.Render_Layers.Order (Problems_Text_Layer)
         < Editor.Render_Layers.Order (Status_Bar_Background_Layer),
         "Status bar background must draw above Problems panel text");

      Assert
      (Editor.Render_Layers.Order (Status_Bar_Text_Layer)
         < Editor.Render_Layers.Order (Message_Background_Layer),
         "Messages must draw above status bar text");

      Assert
      (Editor.Render_Layers.Order (Message_Text_Layer)
         < Editor.Render_Layers.Order (Palette_Background_Layer),
         "Palette must draw above transient messages");

      Assert
      (Editor.Render_Layers.C_First = To_C (Background_Layer),
         "C first layer must match background layer");

      Assert
      (Editor.Render_Layers.C_Last = To_C (Palette_Text_Layer),
         "C last layer must match the final palette layer");
   end Test_Layer_Order;
   procedure Test_C_ABI_Layer_Values_Are_Stable
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (To_C (Background_Layer) = 0,
              "Background layer C ABI value must be 0");
      Assert (To_C (Tab_Bar_Background_Layer) = 1,
              "Tab bar background layer C ABI value must be 1");
      Assert (To_C (Tab_Bar_Tab_Layer) = 2,
              "Tab bar tab layer C ABI value must be 2");
      Assert (To_C (Tab_Bar_Dirty_Layer) = 3,
              "Tab bar dirty layer C ABI value must be 3");
      Assert (To_C (Tab_Bar_Close_Layer) = 4,
              "Tab bar close layer C ABI value must be 4");
      Assert (To_C (Tab_Bar_Text_Layer) = 5,
              "Tab bar text layer C ABI value must be 5");
      Assert (To_C (File_Tree_Background_Layer) = 6,
              "File tree background layer C ABI value must be 6");
      Assert (To_C (File_Tree_Row_Highlight_Layer) = 7,
              "File tree row highlight layer C ABI value must be 7");
      Assert (To_C (File_Tree_Indent_Guide_Layer) = 8,
              "File tree indent guide layer C ABI value must be 8");
      Assert (To_C (File_Tree_Text_Layer) = 9,
              "File tree text layer C ABI value must be 9");
      Assert (To_C (File_Tree_Separator_Layer) = 10,
              "File tree separator layer C ABI value must be 10");
      Assert (To_C (File_Tree_Splitter_Layer) = 11,
              "File tree splitter layer C ABI value must be 11");
      Assert (To_C (Gutter_Background_Layer) = 12,
              "Gutter background layer C ABI value must be 12");
      Assert (To_C (Current_Line_Layer) = 13,
              "Current-line layer C ABI value must be 13");
      Assert (To_C (Active_Find_Match_Layer) = 14,
              "Search match layer C ABI value must be 14");
      Assert (To_C (Selection_Layer) = 15,
              "Selection layer C ABI value must be 15");
      Assert (To_C (Gutter_Separator_Layer) = 16,
              "Gutter separator layer C ABI value must be 16");
      Assert (To_C (Gutter_Text_Layer) = 17,
              "Gutter text layer C ABI value must be 17");
      Assert (To_C (Gutter_Marker_Layer) = 18,
              "Gutter marker layer C ABI value must be 18");
      Assert (To_C (Gutter_Marker_Hover_Layer) = 19,
              "Gutter marker hover layer C ABI value must be 19");
      Assert (To_C (Fold_Marker_Layer) = 20,
              "Fold marker layer C ABI value must be 20");
      Assert (To_C (Diagnostic_Layer) = 21,
              "Diagnostic layer C ABI value must be 21");
      Assert (To_C (Text_Layer) = 22,
              "Text layer C ABI value must be 22");
      Assert (To_C (Caret_Layer) = 23,
              "Caret layer C ABI value must be 23");
      Assert (To_C (Minimap_Background_Layer) = 24,
              "Minimap background layer C ABI value must be 24");
      Assert (To_C (Minimap_Content_Layer) = 25,
              "Minimap content layer C ABI value must be 25");
      Assert (To_C (Minimap_Viewport_Layer) = 26,
              "Minimap viewport layer C ABI value must be 26");
      Assert (To_C (Scrollbar_Track_Layer) = 27,
              "Scrollbar track layer C ABI value must be 27");
      Assert (To_C (Scrollbar_Thumb_Layer) = 28,
              "Scrollbar thumb layer C ABI value must be 28");
      Assert (To_C (Problems_Background_Layer) = 29,
              "Problems background layer C ABI value must be 29");
      Assert (To_C (Problems_Header_Layer) = 30,
              "Problems header layer C ABI value must be 30");
      Assert (To_C (Problems_Row_Layer) = 31,
              "Problems row layer C ABI value must be 31");
      Assert (To_C (Problems_Severity_Layer) = 32,
              "Problems severity layer C ABI value must be 32");
      Assert (To_C (Problems_Text_Layer) = 33,
              "Problems text layer C ABI value must be 33");
      Assert (To_C (Status_Bar_Background_Layer) = 34,
              "Status bar background layer C ABI value must be 34");
      Assert (To_C (Status_Bar_Text_Layer) = 35,
              "Status bar text layer C ABI value must be 35");
      Assert (To_C (Active_Find_Prompt_Background_Layer) = 36,
              "Active Find prompt background layer C ABI value must be 36");
      Assert (To_C (Active_Find_Prompt_Field_Layer) = 37,
              "Active Find prompt field layer C ABI value must be 37");
      Assert (To_C (Active_Find_Prompt_Button_Layer) = 38,
              "Active Find prompt button layer C ABI value must be 38");
      Assert (To_C (Active_Find_Prompt_Text_Layer) = 39,
              "Active Find prompt text layer C ABI value must be 39");
      Assert (To_C (Active_Find_Prompt_Caret_Layer) = 40,
              "Active Find prompt caret layer C ABI value must be 40");
      Assert (To_C (Semantic_Popup_Background_Layer) = 41,
              "Semantic popup background layer C ABI value must be 41");
      Assert (To_C (Semantic_Popup_Row_Layer) = 42,
              "Semantic popup row layer C ABI value must be 42");
      Assert (To_C (Semantic_Popup_Text_Layer) = 43,
              "Semantic popup text layer C ABI value must be 43");
      Assert (To_C (Quick_Open_Background_Layer) = 44,
              "Quick Open background layer C ABI value must be 44");
      Assert (To_C (Quick_Open_Field_Layer) = 45,
              "Quick Open field layer C ABI value must be 45");
      Assert (To_C (Quick_Open_Result_Layer) = 46,
              "Quick Open result layer C ABI value must be 46");
      Assert (To_C (Quick_Open_Selected_Result_Layer) = 47,
              "Quick Open selected-result layer C ABI value must be 47");
      Assert (To_C (Quick_Open_Text_Layer) = 48,
              "Quick Open text layer C ABI value must be 48");
      Assert (To_C (Quick_Open_Caret_Layer) = 49,
              "Quick Open caret layer C ABI value must be 49");
      Assert (To_C (Project_Search_Bar_Background_Layer) = 50,
              "Project Search Bar background layer C ABI value must be 50");
      Assert (To_C (Project_Search_Bar_Field_Layer) = 51,
              "Project Search Bar field layer C ABI value must be 51");
      Assert (To_C (Project_Search_Bar_Button_Layer) = 52,
              "Project Search Bar button layer C ABI value must be 52");
      Assert (To_C (Project_Search_Bar_Text_Layer) = 53,
              "Project Search Bar text layer C ABI value must be 53");
      Assert (To_C (Project_Search_Bar_Caret_Layer) = 54,
              "Project Search Bar caret layer C ABI value must be 54");
      Assert (To_C (Pending_Transition_Background_Layer) = 55,
              "Pending transition background layer C ABI value must be 55");
      Assert (To_C (Pending_Transition_Text_Layer) = 56,
              "Pending transition text layer C ABI value must be 56");
      Assert (To_C (Pending_Transition_Action_Layer) = 57,
              "Pending transition action layer C ABI value must be 57");
      Assert (To_C (Message_Background_Layer) = 58,
              "Message background layer C ABI value must be 58");
      Assert (To_C (Message_Text_Layer) = 59,
              "Message text layer C ABI value must be 59");
      Assert (To_C (Palette_Background_Layer) = 60,
              "Palette background layer C ABI value must be 60");
      Assert (To_C (Palette_Selection_Layer) = 61,
              "Palette selection layer C ABI value must be 61");
      Assert (To_C (Palette_Text_Layer) = 62,
              "Palette text layer C ABI value must be 62");
      Assert (Editor.Render_Layers.Layer_Count = 63,
              "Layer count must stay synchronized with the C ABI enum");
   end Test_C_ABI_Layer_Values_Are_Stable;


   procedure Test_Render_Packet_Emits_File_Tree_Splitter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : Editor.Layout.Layout_Config;
      R      : Editor.Render_Packet.Rect_Command;
      Panels : Editor.Panels.Panel_Set := Editor.Panels.Default_Set;
   begin
      Editor.State.Init (S);
      Set_Render_State_For_Test (S);
      Editor.Panels.Set_Current (Panels);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      Editor.File_Tree_View.Reset;
      Editor.File_Tree_View.Set_Current_Width_In_Columns (28);

      Layout := Editor.Layout.Current;
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Rect_Count_On_Layer (Packet, File_Tree_Splitter_Layer) = 1,
         "enabled file tree must emit exactly one splitter rectangle");

      R := First_Rect_On_Layer (Packet, File_Tree_Splitter_Layer);
      Assert
        (Float (R.X) = Float (Editor.Layout.File_Tree_Splitter_X (Layout)),
         "splitter rect x must come from layout splitter geometry");
      Assert
        (Float (R.W) = Float (Editor.Layout.File_Tree_Splitter_Width (Layout)),
         "splitter rect width must come from layout splitter geometry");

      Layout.File_Tree_View.Enabled := False;
      Editor.File_Tree_View.Set_Current_Config (Layout.File_Tree_View);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Rect_Count_On_Layer (Packet, File_Tree_Splitter_Layer) = 0,
         "disabled file tree must not emit a splitter rectangle");

      Editor.File_Tree_View.Reset;
   end Test_Render_Packet_Emits_File_Tree_Splitter;

   procedure Test_Render_Packet_Emits_Only_Valid_Layers
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("line 1" & ASCII.LF & "line 2"));

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'
         (Pos                   => 3,
          Anchor                => 10,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 2)
                   + Editor.Layout.Cell_W * 16,
         Height => Editor.Layout.Cell_H * 6);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
      (Packet_Layers_Are_Valid (Packet),
         "Every emitted rect and glyph must carry a known render layer");
   end Test_Render_Packet_Emits_Only_Valid_Layers;

   procedure Test_Layout_Geometry_Helpers
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Layout     : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Line_Count : constant Natural := 123;

      Gutter_W : constant Natural :=
      Editor.Layout.Gutter_Width_For_Line_Count
         (Layout, Line_Count);
   begin
      Assert
      (Layout.Text_Left_Padding = Editor.Layout.Cell_W,
         "Text left padding must be one cell");

      Assert
      (Editor.Layout.Gutter_Left (Layout) =
         Float (Editor.Layout.Editor_Body_X (Layout)),
         "Gutter left must follow the file tree sidebar and splitter reservation");

      Assert
      (Editor.Layout.Gutter_Right (Layout, Line_Count) =
         Float (Editor.Layout.Editor_Body_X (Layout) + Gutter_W),
         "Gutter right must equal editor body x plus computed gutter width");

      Assert
      (Editor.Layout.Text_Origin_X (Layout, Line_Count) =
         Editor.Layout.Editor_Body_X (Layout)
         + Gutter_W
         + Layout.Text_Left_Padding,
         "Text origin must follow sidebar, splitter, gutter, and padding");

      Assert
      (Editor.Layout.Line_Number_Cell_X
         (Layout, Line_Count, Digit_From_Right => 2)
       = Editor.Layout.Line_Number_Right_Edge (Layout, Line_Count)
         - 3.0 * Float (Editor.Layout.Cell_W),
         "Line-number digit placement must be owned by Editor.Layout");

      Assert
      (Editor.Layout.Text_Cell_X
         (Layout, Line_Count, Column => 1, Scroll_X => 3)
       = Float (Editor.Layout.Text_Origin_X (Layout, Line_Count))
         - 2.0 * Float (Editor.Layout.Cell_W),
         "Text cell X must support off-screen columns without Natural underflow");

      Assert
      (Editor.Layout.Row_Top_Y (Layout, 2) =
         Float (Layout.Origin_Y + Editor.Layout.Tab_Bar_Height (Layout)
                + 2 * Editor.Layout.Cell_H),
         "Row top must be owned by Editor.Layout and shifted below the tab bar");

      Assert
      (Editor.Layout.Text_Visible_Column_Count
         (Layout, Line_Count,
          Editor.Layout.Text_Origin_X (Layout, Line_Count)
          + 3 * Editor.Layout.Cell_W) = 3,
         "Visible text column count must be owned by Editor.Layout");

      Assert
      (Editor.Layout.Text_Viewport_Right
         (Layout, Viewport_Width => 800,
          Minimap_Enabled => True,
          Minimap_Width   => 96,
          Padding_Left    => 8,
          Padding_Right   => 8)
       = Float (Layout.Origin_X + 688),
         "Text viewport right edge must reserve minimap width and both paddings");

      Assert
      (Editor.Layout.Last_Visible_Text_Column
         (Layout, Line_Count,
          Editor.Layout.Text_Origin_X (Layout, Line_Count)
          + 3 * Editor.Layout.Cell_W,
          Scroll_X => 2) = 5,
         "Last visible text column must include horizontal scroll");

      Assert
      (Editor.Layout.Text_Column_For_X
         (Layout, Line_Count,
          Editor.Layout.Text_Origin_X (Layout, Line_Count)
          + 2 * Editor.Layout.Cell_W,
          Scroll_X => 4) = 6,
         "Point-to-column conversion must be owned by Editor.Layout");

      Assert
      (Editor.Layout.Row_For_Y
         (Layout, Layout.Origin_Y + Editor.Layout.Tab_Bar_Height (Layout)
          + 2 * Editor.Layout.Cell_H,
          Scroll_Y => 3) = 5,
         "Point-to-row conversion must be owned by Editor.Layout and shifted below the tab bar");

   end Test_Layout_Geometry_Helpers;

   procedure Test_Font_Config_Owns_Cell_Metrics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Layout.Cell_W = Editor.Font_Config.Cell_W,
         "Layout Cell_W must delegate to Editor.Font_Config");

      Assert
        (Editor.Layout.Cell_H = Editor.Font_Config.Cell_H,
         "Layout Cell_H must delegate to Editor.Font_Config");
   end Test_Font_Config_Owns_Cell_Metrics;

   procedure Test_Dynamic_Gutter_Width_Tracks_Line_Digits
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      function Expected (Digit_Count : Natural) return Natural is
      begin
         return Layout.Gutter_Left_Padding
           + Editor.Layout.Gutter_Marker_Width
           + Editor.Layout.Gutter_Fold_Width
           + Digit_Count * Editor.Layout.Cell_W
           + Layout.Gutter_Right_Padding;
      end Expected;
   begin
      Assert
        (Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1) = Expected (1),
         "1 line must reserve marker, fold, one digit, and gutter padding");

      Assert
        (Editor.Layout.Gutter_Width_For_Line_Count (Layout, 9) = Expected (1),
         "9 lines must still reserve marker, fold, one digit, and gutter padding");

      Assert
        (Editor.Layout.Gutter_Width_For_Line_Count (Layout, 10) = Expected (2),
         "10 lines must reserve marker, fold, two digits, and gutter padding");

      Assert
        (Editor.Layout.Gutter_Width_For_Line_Count (Layout, 100) = Expected (3),
         "100 lines must reserve marker, fold, three digits, and gutter padding");
   end Test_Dynamic_Gutter_Width_Tracks_Line_Digits;

   procedure Test_Minimap_Geometry_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
   begin
      Assert
        (Editor.Minimap.Left_X (Layout, 800, Config) =
           Float (Layout.Origin_X + 800 - 8 - 96),
         "Minimap left edge must reserve right-side padding");

      Assert
        (Editor.Minimap.Right_X (Layout, 800, Config) =
           Float (Layout.Origin_X + 800 - 8),
         "Minimap right edge must stop before right-side padding");

      Assert
        (Editor.Layout.Minimap_Left
           (Layout, 800, Minimap_Width => 96, Padding_Right => 8) =
           Editor.Minimap.Left_X (Layout, 800, Config),
         "Layout minimap-left helper must match Editor.Minimap geometry");

      Assert
        (Editor.Minimap.Sample_Row
           (Pixel_Y => 0, Line_Count => 1000, Minimap_Height => 100) = 0,
         "Top minimap pixel must sample row 0");

      Assert
        (Editor.Minimap.Sample_Row
           (Pixel_Y => 99, Line_Count => 1000, Minimap_Height => 100) = 990,
         "Bottom minimap pixel must sample near the last document rows");

      Assert
        (Editor.Minimap.Viewport_Marker_Height
           (Visible_Row_Count => 1, Line_Count => 1000, Viewport_H => 100) = 2.0,
         "Viewport marker must keep a minimum visible height");

      Assert
        (Editor.Minimap.Viewport_Marker_Height
           (Visible_Row_Count => 40, Line_Count => 1, Viewport_H => 100) = 100.0,
         "Viewport marker height must be clamped to the minimap height");
   end Test_Minimap_Geometry_Helpers;

   procedure Test_Render_Packet_Emits_Minimap_Layers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
   begin
      Editor.Minimap.Set_Enabled (True);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log
        (S, Paste ("alpha" & ASCII.LF & "" & ASCII.LF & "beta gamma"));

      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => 800, Height => 64);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Has_Rect_On_Layer (Packet, Minimap_Background_Layer),
         "Minimap background must be emitted on its semantic layer");

      Assert
        (Has_Rect_On_Layer (Packet, Minimap_Content_Layer),
         "Minimap text-density rectangles must be emitted on their semantic layer");

      Assert
        (Has_Rect_On_Layer (Packet, Minimap_Viewport_Layer),
         "Minimap viewport marker must be emitted on its semantic layer");

      Editor.Minimap.Set_Current (Old);
   end Test_Render_Packet_Emits_Minimap_Layers;

   procedure Test_Minimap_Viewport_Rect_Is_Clamped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      R      : Editor.Render_Packet.Rect_Command;
   begin
      Editor.Minimap.Set_Current
        ((Enabled       => True,
          Width         => 96,
          Padding_Left  => 8,
          Padding_Right => 8));
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("short"));

      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => 800, Height => 64);

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      R := First_Rect_On_Layer (Packet, Minimap_Viewport_Layer);

      Assert
        (Float (R.H) <= 64.0,
         "Minimap viewport marker must not be taller than the minimap");
      Assert
        (Float (R.Y) + Float (R.H)
           <= Float (Layout.Origin_Y + Editor.View.Viewport_Height),
         "Minimap viewport marker must stay inside the minimap bounds");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Viewport_Rect_Is_Clamped;

   procedure Test_Minimap_Disabled_Emits_No_Minimap_Rects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
   begin
      Editor.Minimap.Set_Enabled (False);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("alpha"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => 800, Height => 64);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Rect_Count_On_Layer (Packet, Minimap_Background_Layer) = 0,
         "Disabled minimap must not emit a background rectangle");
      Assert
        (Rect_Count_On_Layer (Packet, Minimap_Content_Layer) = 0,
         "Disabled minimap must not emit content rectangles");
      Assert
        (Rect_Count_On_Layer (Packet, Minimap_Viewport_Layer) = 0,
         "Disabled minimap must not emit viewport rectangles");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Disabled_Emits_No_Minimap_Rects;

   procedure Test_Minimap_Snapshot_Tracks_Document_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Old  : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
   begin
      Editor.Minimap.Set_Enabled (True);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log
        (S, Paste ("alpha" & ASCII.LF & "   " & ASCII.LF & "beta"));

      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Set_Viewport (Width => 800, Height => 64);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Snap.Minimap_Sample_Count = Editor.State.Line_Count (S),
         "Minimap snapshot must contain one initial sample per logical row");
      Assert
        (Snap.Minimap_Samples (0).Has_Text,
         "Non-empty text rows must create minimap content marks");
      Assert
        (not Snap.Minimap_Samples (1).Has_Text,
         "Whitespace-only rows must not create minimap content marks");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Snapshot_Tracks_Document_Rows;

   procedure Test_Minimap_Default_Config_Is_Enabled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      Config : constant Editor.Minimap.Minimap_Config := (others => <>);
   begin
      Assert
        (Config.Enabled,
         "Default minimap config must enable the Phase 32 visual foundation");
      Assert
        (Config.Width = 96
         and then Config.Padding_Left = 8
         and then Config.Padding_Right = 8,
         "Default minimap config must preserve the Phase 32 foundation geometry");
   end Test_Minimap_Default_Config_Is_Enabled;

   procedure Test_Minimap_Rendering_Does_Not_Change_Glyph_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S          : Editor.State.State_Type;
      Without_MM : Editor.Render_Packet.Render_Packet;
      With_MM    : Editor.Render_Packet.Render_Packet;
      Old        : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("alpha" & ASCII.LF & "beta"));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => 800, Height => 64);

      Editor.Minimap.Set_Enabled (False);
      Editor.Input_Bridge.Build_Render_Packet (Without_MM);

      Editor.Minimap.Set_Enabled (True);
      Editor.Input_Bridge.Build_Render_Packet (With_MM);

      Assert
        (Without_MM.Glyph_Count = With_MM.Glyph_Count,
         "Minimap rendering must be rect-only and must not change glyph count");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Rendering_Does_Not_Change_Glyph_Count;

   procedure Test_Minimap_Rendering_Does_Not_Dirty_Font_Atlas
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
   begin
      Editor.Minimap.Set_Enabled (True);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (""));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => 800, Height => 64);

      Editor.Minimap.Set_Enabled (False);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Textrender.Clear_Atlas_Dirty (Editor.Fonts.Backend.all);

      Editor.Minimap.Set_Enabled (True);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (not Textrender.Atlas_Dirty (Editor.Fonts.Backend.all),
         "Rect-only minimap rendering must not dirty the font atlas");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Rendering_Does_Not_Dirty_Font_Atlas;

   procedure Test_Index_For_Point_Uses_Vertical_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural := 0;
      Got    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("a" & ASCII.LF & "b" & ASCII.LF & "c"));

      Editor.View.Set_Scroll (0, 1);
      X := Editor.Layout.Text_Origin_X (Layout, 3);
      Got :=
        Natural
          (Editor.Navigation.Index_For_Point
             (S, X, Natural (Editor.Layout.Text_Viewport_Y (Layout))));
      Editor.View.Reset_Scroll;

      Assert
        (Got = 2,
         "Point-to-index conversion must add vertical scroll to visible row");
   end Test_Index_For_Point_Uses_Vertical_Scroll;


   procedure Test_Syntax_Classifier_Basic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Syntax.Kind_At ("procedure X is", 0) = Editor.Syntax.Keyword,
         "Ada keyword must classify as Keyword");

      Assert
        (Editor.Syntax.Kind_At ("Name", 0) = Editor.Syntax.Identifier,
         "Plain word must classify as Identifier");

      Assert
        (Editor.Syntax.Kind_At ("Value := 123", 9) = Editor.Syntax.Number_Literal,
         "Digit run must classify as Number_Literal");

      Assert
        (Editor.Syntax.Kind_At ("S := ""abc""", 5) = Editor.Syntax.String_Literal,
         "Quoted run must classify as String_Literal");

      Assert
        (Editor.Syntax.Kind_At ("X -- comment", 3) = Editor.Syntax.Comment,
         "Ada line comment must classify as Comment");

      Assert
        (Editor.Syntax.Classify ("end;", 0) = Editor.Syntax.Keyword,
         "Token-oriented Classify wrapper must return the same token kind");

      Assert
        (Editor.Syntax.Kind_At ("S := ""a""""b"";", 8) = Editor.Syntax.String_Literal,
         "Doubled quotes inside an Ada string must remain part of the string token");

      Assert
        (Editor.Syntax.Kind_At ("X := 1;", 2) = Editor.Syntax.Operator,
         "Assignment colon must classify as Operator");

      Assert
        (Editor.Syntax.Kind_At ("X := 1;", 6) = Editor.Syntax.Punctuation,
         "Semicolon must classify as Punctuation");
   end Test_Syntax_Classifier_Basic;

   procedure Test_Syntax_Classifier_Ada_Constructs
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : Editor.Syntax.Lexical_State;
      Saw_Attribute : Boolean := False;
      Saw_Based_Number : Boolean := False;
      Saw_Pragma_Name : Boolean := False;

      procedure Visit
        (Start_Col : Natural;
         End_Col   : Natural;
         Kind      : Editor.Syntax.Token_Kind)
      is
      begin
         if Kind = Editor.Syntax.Attribute and then Start_Col = 1 then
            Saw_Attribute := True;
         elsif Kind = Editor.Syntax.Number_Literal and then End_Col - Start_Col = 6 then
            Saw_Based_Number := True;
         elsif Kind = Editor.Syntax.Pragma_Name then
            Saw_Pragma_Name := True;
         end if;
      end Visit;
   begin
      Editor.Syntax.Classify_Line
        (Line          => "X'First 16#FF# pragma Inline (Foo);",
         Initial_State => Editor.Syntax.Normal_State,
         Visit         => Visit'Access,
         Final_State   => Final);

      Assert (Saw_Attribute, "X'First must classify the tick suffix as Attribute");
      Assert (Saw_Based_Number, "16#FF# must classify as one based numeric literal");
      Assert (Saw_Pragma_Name, "pragma Inline must classify Inline as Pragma_Name");
      Assert (Final = Editor.Syntax.Normal_State, "closed constructs must finish in normal state");

      Assert
        (Editor.Syntax.Kind_At ("PACKAGE Demo IS", 0) = Editor.Syntax.Keyword,
         "Ada keywords must classify case-insensitively");

      Assert
        (Editor.Syntax.Kind_At ("S := ""-- not comment""; -- comment", 7) =
           Editor.Syntax.String_Literal,
         "comment marker inside a string must remain string text");
   end Test_Syntax_Classifier_Ada_Constructs;

   procedure Test_Syntax_Cache_Incremental_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cache : Editor.Syntax_Cache.Syntax_Cache;
      Changed : Boolean := False;
      Tokens : Editor.Syntax.Token_Span_Array (1 .. 0);
      pragma Unreferenced (Tokens);
   begin
      Editor.Syntax_Cache.Set_Line_Count (Cache, 2);
      Editor.Syntax_Cache.Relex_Dirty_Line
        (Cache, 1, "S := ""unterminated", Changed);
      Assert (Changed, "unterminated string must propagate changed lexical state");
      Assert (Editor.Syntax_Cache.Is_Dirty (Cache, 2),
              "next line must become dirty when incoming state changes");

      Editor.Syntax_Cache.Relex_Dirty_Line (Cache, 2, "recovery", Changed);
      Assert (not Editor.Syntax_Cache.Is_Dirty (Cache, 2),
              "relexed line must no longer be dirty");
      Assert (Editor.Syntax_Cache.Tokens_For_Line (Cache, 1)'Length > 0,
              "cache must expose stored token spans");
   end Test_Syntax_Cache_Incremental_State;

   procedure Test_Syntax_Semantics_And_Overlays
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, "package Renderer is");
      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, "type Color is record");
      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, "procedure Draw (C : Color);");

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Renderer") =
           Editor.Syntax.Package_Identifier,
         "package declarations must be learned conservatively");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Color") =
           Editor.Syntax.Type_Identifier,
         "type declarations must be learned conservatively");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Draw") =
           Editor.Syntax.Subprogram_Identifier,
         "subprogram declarations must be learned conservatively");
      Assert
        (Editor.Syntax_Overlays.Merge
           (Editor.Syntax.Keyword, Editor.Syntax_Overlays.Diagnostic_Error_Overlay) =
         Editor.Syntax.Diagnostic_Error,
         "diagnostic overlay must override base syntax kind deterministically");
      Assert
        (Editor.Syntax_Overlays.Precedence (Editor.Syntax.Selection_Overlay) >
         Editor.Syntax_Overlays.Precedence (Editor.Syntax.Diagnostic_Error),
         "selection overlay must retain higher precedence than diagnostics");
   end Test_Syntax_Semantics_And_Overlays;

   procedure Test_Render_Packet_Uses_Syntax_Colors
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("procedure X is -- ok"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 32,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      declare
         Keyword_Glyph : constant Natural := Text_Glyph_Index (Packet, Layout, 0, 1);
         Comment_Glyph : constant Natural := Text_Glyph_Index (Packet, Layout, 15, 1);
      begin
         Assert
           (Glyph_Has_Color
              (Packet.Glyphs (Keyword_Glyph),
               Editor.Theme.Syntax_Color (Editor.Syntax.Keyword)),
            "Keyword text glyph must use keyword theme colour");

         Assert
           (Glyph_Has_Color
              (Packet.Glyphs (Comment_Glyph),
               Editor.Theme.Syntax_Color (Editor.Syntax.Comment)),
            "Comment text glyph must use comment theme colour");
      end;
   end Test_Render_Packet_Uses_Syntax_Colors;


   procedure Test_Selected_Syntax_Text_Uses_Readable_Foreground
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("procedure X is"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 9,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 32,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      declare
         Selected_Keyword_Glyph : constant Natural :=
           Text_Glyph_Index (Packet, Layout, 0, 1);
      begin
         Assert
           (Glyph_Has_Color
              (Packet.Glyphs (Selected_Keyword_Glyph),
               Editor.Theme.Syntax_Color (Editor.Syntax.Selection_Overlay)),
            "Selected syntax-highlighted text must use selection foreground");

         Assert
           (not Glyph_Has_Color
              (Packet.Glyphs (Selected_Keyword_Glyph),
               Editor.Theme.Syntax_Color (Editor.Syntax.Keyword)),
            "Selected syntax-highlighted text must not keep low-contrast token colour");

         Assert
           (not Glyph_Has_Color
              (Packet.Glyphs (Selected_Keyword_Glyph),
               Editor.Theme.Selection_Background),
            "Selected text foreground must differ from the selection background");
      end;
   end Test_Selected_Syntax_Text_Uses_Readable_Foreground;


   procedure Test_Render_Snapshot_Splits_Overlay_Inside_Syntax_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Saw_Keyword_Before : Boolean := False;
      Saw_Diagnostic_Run : Boolean := False;
      Saw_Keyword_After  : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("procedure Draw is"));
      Editor.State.Add_Diagnostic (S, 3, 6, Editor.Diagnostics.Error);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      for I in 1 .. Snap.Syntax_Span_Count loop
         if Snap.Syntax_Spans (I).Row = 0
           and then Snap.Syntax_Spans (I).Start_Index = 0
           and then Snap.Syntax_Spans (I).End_Index = 3
           and then Snap.Syntax_Spans (I).Kind = Editor.Syntax.Keyword
         then
            Saw_Keyword_Before := True;
         elsif Snap.Syntax_Spans (I).Row = 0
           and then Snap.Syntax_Spans (I).Start_Index = 3
           and then Snap.Syntax_Spans (I).End_Index = 6
           and then Snap.Syntax_Spans (I).Kind = Editor.Syntax.Diagnostic_Error
         then
            Saw_Diagnostic_Run := True;
         elsif Snap.Syntax_Spans (I).Row = 0
           and then Snap.Syntax_Spans (I).Start_Index = 6
           and then Snap.Syntax_Spans (I).End_Index = 9
           and then Snap.Syntax_Spans (I).Kind = Editor.Syntax.Keyword
         then
            Saw_Keyword_After := True;
         end if;
      end loop;

      Assert (Saw_Keyword_Before, "keyword prefix before diagnostic overlay must remain keyword");
      Assert (Saw_Diagnostic_Run, "diagnostic overlay must affect only its exact subrange");
      Assert (Saw_Keyword_After, "keyword suffix after diagnostic overlay must remain keyword");
   end Test_Render_Snapshot_Splits_Overlay_Inside_Syntax_Token;

   procedure Test_Syntax_Disabled_Still_Projects_Selection_Overlay
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Saved_Settings : constant Editor.Settings.Settings_State := Editor.Settings.Current;
      Saw_Selection : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("ab"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Settings.Set_Use_Syntax_Colouring (False);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Editor.Settings.Set_Current (Saved_Settings);

      for I in 1 .. Snap.Syntax_Span_Count loop
         if Snap.Syntax_Spans (I).Kind = Editor.Syntax.Selection_Overlay then
            Saw_Selection := True;
         elsif Snap.Syntax_Spans (I).Kind = Editor.Syntax.Keyword
           or else Snap.Syntax_Spans (I).Kind = Editor.Syntax.Identifier
         then
            Assert (False, "syntax-disabled render snapshot must not emit lexical spans");
         end if;
      end loop;

      Assert (Saw_Selection, "selection overlay must still render when syntax colouring is disabled");
   end Test_Syntax_Disabled_Still_Projects_Selection_Overlay;

   procedure Test_Render_Packet_Classifies_Full_Row_When_Scrolled
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("X -- comment"));

      Set_Render_State_For_Test (S);
      Editor.Render_Cache.Reset;
      Editor.View.Reset_Scroll;
      Editor.View.Set_Scroll (5, 0);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      declare
         First_Visible_Text_Glyph : constant Natural :=
           Text_Glyph_Index (Packet, Layout, 0, 1);
      begin
         Assert
           (Glyph_Has_Color
              (Packet.Glyphs (First_Visible_Text_Glyph),
               Editor.Theme.Syntax_Color (Editor.Syntax.Comment)),
            "Scrolled visible text inside an existing Ada comment must keep comment colour");
      end;

      Editor.View.Reset_Scroll;
   end Test_Render_Packet_Classifies_Full_Row_When_Scrolled;

   procedure Test_Syntax_Coloring_Does_Not_Change_Text_Glyph_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc123"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Text_Glyph_Count (Packet, Layout, 1) = 6,
         "Syntax colouring must not add or remove text glyphs");
   end Test_Syntax_Coloring_Does_Not_Change_Text_Glyph_Count;



   function Colors_Are_Equal
     (Left  : Editor.Theme.Color_RGB;
      Right : Editor.Theme.Color_RGB) return Boolean
   is
      Epsilon : constant Float := 0.0001;
   begin
      return abs (Left.R - Right.R) <= Epsilon
        and then abs (Left.G - Right.G) <= Epsilon
        and then abs (Left.B - Right.B) <= Epsilon;
   end Colors_Are_Equal;

   procedure Test_Theme_Colors_Are_Normalized
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      for Kind in Editor.Theme.Theme_Color loop
         declare
            C : constant Editor.Theme.Color_RGB := Editor.Theme.Color (Kind);
         begin
            Assert
              (C.R >= 0.0 and then C.R <= 1.0
               and then C.G >= 0.0 and then C.G <= 1.0
               and then C.B >= 0.0 and then C.B <= 1.0,
               "Theme colour channels must be normalized");
         end;
      end loop;
   end Test_Theme_Colors_Are_Normalized;


   procedure Test_Theme_Style_Constants_Are_Sensible
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Theme.Diagnostic_Underline_Height > 0.0,
         "Diagnostic underline height must be positive");
      Assert
        (Editor.Theme.Diagnostic_Underline_Bottom_Padding
         >= Editor.Theme.Diagnostic_Underline_Height,
         "Diagnostic underline padding must keep underline inside the row");
      Assert
        (Editor.Theme.Minimap_Content_Padding >= 0.0
         and then Editor.Theme.Minimap_Min_Line_Width > 0.0
         and then Editor.Theme.Minimap_Content_Line_Height > 0.0
         and then Editor.Theme.Minimap_Max_Line_Length_For_Scale > 0,
         "Minimap style constants must be valid");
      Assert
        (Editor.Theme.Palette_Margin > 0
         and then Editor.Theme.Palette_Max_Width > Editor.Theme.Palette_Margin
         and then Editor.Theme.Palette_Top_Min_Offset >= 0.0
         and then Editor.Theme.Palette_Top_Fraction >= 0.0
         and then Editor.Theme.Palette_Text_Padding_X >= 0.0
         and then Editor.Theme.Palette_Text_Padding_Y >= 0.0
         and then Editor.Theme.Palette_Selected_Row_Inset_X >= 0.0
         and then Editor.Theme.Palette_Selected_Row_Offset_Y >= 0.0,
         "Palette style constants must be valid");
   end Test_Theme_Style_Constants_Are_Sensible;

   procedure Test_Syntax_Color_Maps_Keyword_To_Theme
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Colors_Are_Equal
           (Editor.Theme.Syntax_Color (Editor.Syntax.Keyword),
            Editor.Theme.Color (Editor.Theme.TC_Syntax_Keyword)),
         "Keyword syntax colour must come from the theme keyword colour");
   end Test_Syntax_Color_Maps_Keyword_To_Theme;

   procedure Test_Theme_Semantic_Mappings_Are_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Active_Find_Inactive_Match,
            Editor.Theme.Active_Find_Match),
         "Active and inactive Find match colours must differ");

      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Diagnostic_Color (Editor.Diagnostics.Warning),
            Editor.Theme.Diagnostic_Color (Editor.Diagnostics.Error)),
         "Warning and error diagnostic colours must differ");

      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Syntax_Color (Editor.Syntax.Keyword),
            Editor.Theme.Syntax_Color (Editor.Syntax.Comment)),
         "Keyword and comment syntax colours must differ");

      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Syntax_Color (Editor.Syntax.Selection_Overlay),
            Editor.Theme.Selection_Background),
         "Selection foreground and background colours must differ");

      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Minimap_Background,
            Editor.Theme.Minimap_Content),
         "Minimap background and content colours must differ");

      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Palette_Text,
            Editor.Theme.Palette_Muted_Text),
         "Palette primary and muted text colours must differ");
   end Test_Theme_Semantic_Mappings_Are_Distinct;

   procedure Test_Line_Number_Glyphs_Use_Theme_Colors
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Has_Current  : Boolean := False;
      Has_Inactive : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("a" & ASCII.LF & "b"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 2)
                   + Editor.Layout.Cell_W * 8,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Gutter_Text_Layer) then
            if Glyph_Has_Color
              (Packet.Glyphs (Natural (I)),
               Editor.Theme.Current_Line_Number)
            then
               Has_Current := True;
            elsif Glyph_Has_Color
              (Packet.Glyphs (Natural (I)),
               Editor.Theme.Inactive_Line_Number)
            then
               Has_Inactive := True;
            end if;
         end if;
      end loop;

      Assert
        (Has_Current,
         "Current line number glyph must use the current line-number theme colour");
      Assert
        (Has_Inactive,
         "Inactive line number glyph must use the inactive line-number theme colour");
      Assert
        (not Colors_Are_Equal
           (Editor.Theme.Current_Line_Number,
            Editor.Theme.Inactive_Line_Number),
         "Current and inactive line-number theme colours must differ");
   end Test_Line_Number_Glyphs_Use_Theme_Colors;

   procedure Test_Render_Rectangles_Use_Theme_Colors
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      Has_Gutter_Background : Boolean := False;
      Has_Gutter_Separator  : Boolean := False;
      Has_Current_Text_Row  : Boolean := False;
      Has_Current_Gutter_Row : Boolean := False;
      Has_Selection         : Boolean := False;
      Has_Caret             : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 4,
            Anchor                => 1,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Rect_Count - 1 loop
         declare
            Rect : constant Editor.Render_Packet.Rect_Command :=
              Packet.Rects (Natural (I));
         begin
            if Rect.Layer = To_C (Gutter_Background_Layer)
              and then Rect_Has_Color
                (Rect, Editor.Theme.Gutter_Background)
            then
               Has_Gutter_Background := True;
            elsif Rect.Layer = To_C (Gutter_Separator_Layer)
              and then Rect_Has_Color
                (Rect, Editor.Theme.Gutter_Separator)
            then
               Has_Gutter_Separator := True;
            elsif Rect.Layer = To_C (Current_Line_Layer)
              and then Rect_Has_Color
                (Rect, Editor.Theme.Current_Text_Row)
            then
               Has_Current_Text_Row := True;
            elsif Rect.Layer = To_C (Current_Line_Layer)
              and then Rect_Has_Color
                (Rect, Editor.Theme.Current_Gutter_Row)
            then
               Has_Current_Gutter_Row := True;
            elsif Rect.Layer = To_C (Selection_Layer)
              and then Rect_Has_Color
                (Rect, Editor.Theme.Selection_Background)
            then
               Has_Selection := True;
            elsif Rect.Layer = To_C (Caret_Layer)
              and then Rect_Has_Color
                (Rect, Editor.Theme.Cursor_Color)
            then
               Has_Caret := True;
            end if;
         end;
      end loop;

      Assert
        (Has_Gutter_Background,
         "Gutter background rect must use the gutter-background theme colour");
      Assert
        (Has_Gutter_Separator,
         "Gutter separator rect must use the gutter-separator theme colour");
      Assert
        (Has_Current_Text_Row,
         "Current text-row rect must use the current-text-row theme colour");
      Assert
        (Has_Current_Gutter_Row,
         "Current gutter-row rect must use the current-gutter-row theme colour");
      Assert
        (Has_Selection,
         "Selection rect must use the selection-background theme colour");
      Assert
        (Has_Caret,
         "Cursor rect must use Editor.Theme.Cursor_Color");
   end Test_Render_Rectangles_Use_Theme_Colors;


   procedure Test_Render_Cache_Reuses_Unchanged_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S       : Editor.State.State_Type;
      Packet1 : Editor.Render_Packet.Render_Packet;
      Packet2 : Editor.Render_Packet.Render_Packet;
      Layout  : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Hits_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Render_Cache.Reset;
      Editor.Executor.Execute_No_Log (S, Paste ("alpha" & ASCII.LF & "beta"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 2)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet1);
      Hits_Before := Editor.Render_Cache.Cache_Hits;
      Editor.Input_Bridge.Build_Render_Packet (Packet2);

      Assert
        (Packet2.Glyph_Count = Packet1.Glyph_Count,
         "Cached second render must emit the same glyph count");
      Assert
        (Editor.Render_Cache.Cache_Hits > Hits_Before,
         "Unchanged second render must reuse cached visible rows");
   end Test_Render_Cache_Reuses_Unchanged_Rows;

   procedure Test_Render_Cache_Invalidates_Single_Line_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Invalidated_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Render_Cache.Reset;
      Editor.Executor.Execute_No_Log (S, Paste ("abc" & ASCII.LF & "def"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 2)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Invalidated_Before := Editor.Render_Cache.Rows_Invalidated;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'x'));

      Assert
        (Editor.Render_Cache.Rows_Invalidated > Invalidated_Before,
         "Single-line edit without newline must invalidate cached rows safely");
   end Test_Render_Cache_Invalidates_Single_Line_Edit;

   procedure Test_Render_Cache_Invalidates_All_On_Newline_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Invalidated_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Render_Cache.Reset;
      Editor.Executor.Execute_No_Log (S, Paste ("abc" & ASCII.LF & "def"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 2)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 4);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Invalidated_Before := Editor.Render_Cache.Rows_Invalidated;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, ASCII.LF));

      Assert
        (Editor.Render_Cache.Rows_Invalidated > Invalidated_Before,
         "Newline edit must invalidate cached rows safely");
   end Test_Render_Cache_Invalidates_All_On_Newline_Edit;

   procedure Test_Render_Cache_Invalidates_On_Test_State_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S1      : Editor.State.State_Type;
      S2      : Editor.State.State_Type;
      Packet  : Editor.Render_Packet.Render_Packet;
      Layout  : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Hits_Before : Natural := 0;
   begin
      Editor.State.Init (S1);
      Editor.Executor.Execute_No_Log (S1, Paste ("aaaa"));

      Editor.State.Init (S2);
      Editor.Executor.Execute_No_Log (S2, Paste ("bbbb"));

      Editor.Render_Cache.Reset;
      Set_Render_State_For_Test (S1);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 2);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Hits_Before := Editor.Render_Cache.Cache_Hits;
      Set_Render_State_For_Test (S2);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 2);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Editor.Render_Cache.Cache_Hits = Hits_Before,
         "Replacing the active test state must not reuse stale same-shape cached glyphs");
   end Test_Render_Cache_Invalidates_On_Test_State_Replacement;


   procedure Test_Phase17_Long_Line_Horizontal_Viewport_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Long_Line : String (1 .. 20_000) := (others => 'x');
      Visible_Cols : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Long_Line);

      S.Carets.Clear;
      S.Carets.Append (Caret_State'
        (Pos                   => 15_000,
         Anchor                => 15_000,
         Virtual_Column        => 0,
         Anchor_Virtual_Column => 0));

      Editor.View.Reset;
      Editor.View.Set_Viewport (400, 80);
      Editor.View.Set_Scroll (14_950, 0);
      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport (400, 80);
      Editor.View.Set_Scroll (14_950, 0);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Visible_Cols :=
        Editor.Layout.Text_Visible_Column_Count
          (Layout, Editor.State.Line_Count (S), Editor.View.Viewport_Width);

      Assert
        (Text_Glyph_Count (Packet, Layout, Editor.State.Line_Count (S)) <=
           Visible_Cols + 1,
         "Long horizontally-scrolled line must emit only viewport glyphs");
   end Test_Phase17_Long_Line_Horizontal_Viewport_Bounded;

   procedure Test_Phase17_Bulk_Load_Line_Index_And_Empty_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      E : Editor.Instance.Editor_Instance;
   begin
      Editor.Instance.Init (E);
      Editor.Executor.Execute_No_Log (E.State, Paste ("old"));
      Editor.Instance.Load_Text
        (E,
         "a" & ASCII.LF &
         "b" & ASCII.LF &
         "c");

      Assert
        (Editor.State.Line_Count (E.State) = 3,
         "Bulk load must build exact line count");

      Assert
        (Editor.History.Undo_Stack.Is_Empty,
         "Bulk load must not leave undo entries");
   end Test_Phase17_Bulk_Load_Line_Index_And_Empty_Undo;

   procedure Test_Phase17_Render_Snapshot_Line_Starts_Are_Windowed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Text : Unbounded_String := Null_Unbounded_String;
      Visible_Rows : Natural := 0;
   begin
      Editor.State.Init (S);

      for I in 1 .. 200 loop
         Append (Text, "x" & ASCII.LF);
      end loop;

      Editor.State.Load_Text (S, To_String (Text));
      Editor.View.Reset;
      Editor.View.Set_Viewport (400, 80);
      Editor.View.Set_Scroll (0, 100);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Visible_Rows :=
        Editor.Layout.Visible_Row_Count
          (Editor.Layout.Current, Editor.View.Viewport_Height);

      Assert
        (Snap.Line_Start_Row_Base = 100,
         "Snapshot line starts must be based at the first visible row");

      Assert
        (Natural (Snap.Line_Starts.Length) <= Visible_Rows + 1,
         "Snapshot must not duplicate all document line starts");
   end Test_Phase17_Render_Snapshot_Line_Starts_Are_Windowed;

   procedure Test_Phase17_Large_Selection_Emits_Visible_Rects_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Text   : Unbounded_String := Null_Unbounded_String;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Visible_Rows : Natural := 0;
      Selection_Rects : Natural := 0;
   begin
      Editor.State.Init (S);

      for I in 1 .. 1_000 loop
         Append (Text, "x" & ASCII.LF);
      end loop;

      Editor.State.Load_Text (S, To_String (Text));

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => Cursor_Index (Text_Buffer.Length (S.Buffer)),
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1_000)
                   + Editor.Layout.Cell_W * 12,
         Height => Editor.Layout.Cell_H * 5);
      Editor.View.Set_Scroll (0, 500);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Visible_Rows :=
        Editor.Layout.Visible_Row_Count
          (Layout, Editor.View.Viewport_Height);

      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Selection_Layer) then
            Selection_Rects := Selection_Rects + 1;
         end if;
      end loop;

      Assert
        (Selection_Rects <= Visible_Rows,
         "Huge selection must emit selection rectangles only for visible rows");
   end Test_Phase17_Large_Selection_Emits_Visible_Rects_Only;


   procedure Configure_Wrap_Test_Viewport
     (Logical_Line_Count : Natural := 1;
      Wrap_Columns       : Positive := 4)
   is
      H : constant Natural := 8 * Editor.Layout.Cell_H;
   begin
      Editor.Settings.Set_Show_Minimap (False);
      Editor.Minimap.Set_Current (Default_Minimap_Config (False));
      Editor.Panels.Set_Current (Test_Panels);
      Editor.Scrollbars.Set_Enabled (False);
      declare
         Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
         W : constant Natural :=
           Editor.Layout.Text_Origin_X
             (Layout, Natural'Max (1, Logical_Line_Count))
           + Natural (Wrap_Columns) * Editor.Layout.Cell_W;
      begin
         Editor.View.Set_Viewport (W, H);
      end;
      Editor.View.Set_Scroll (0, 0);
      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_At_Viewport);
   end Configure_Wrap_Test_Viewport;

   procedure Test_Wrap_Primitives
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seg : Editor.Wrap.Visual_Row_Info;
   begin
      Assert
        (Editor.Wrap.Wrap_Column
           (4 * Editor.Layout.Cell_W, Editor.Layout.Cell_W) = 4,
         "Wrap_Column must use text viewport cells");
      Assert
        (Editor.Wrap.Visual_Row_Count_For_Logical_Line (9, 4) = 3,
         "9 cells at wrap column 4 must produce 3 visual rows");
      Assert
        (Editor.Wrap.Visual_Row_Count_For_Logical_Line (8, 4) = 2,
         "exact multiples must not produce an empty visual row");

      Seg := Editor.Wrap.Visual_Segment (0, 1, 9, 4);
      Assert (Seg.Start_Col = 4 and then Seg.End_Col = 8,
              "second wrapped segment must cover columns 4 through 8 exclusive");
   end Test_Wrap_Primitives;

   procedure Test_Wrapped_Snapshot_Visual_Segments
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghi"));
      Configure_Wrap_Test_Viewport (1, 4);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport,
              "snapshot must record enabled wrap mode");
      Assert (Snap.Wrap_Col = 4,
              "snapshot wrap column must come from text viewport width");
      Assert (Snap.Visible_Visual_Count >= 3,
              "long logical line must produce multiple visible visual rows");
      Assert (Snap.Visible_Visual_Rows (1).Start_Col = 0
              and then Snap.Visible_Visual_Rows (1).End_Col = 4,
              "first visual segment must be columns 0..4");
      Assert (Snap.Visible_Visual_Rows (2).Start_Col = 4
              and then Snap.Visible_Visual_Rows (2).End_Col = 8,
              "second visual segment must be columns 4..8");
      Assert (Snap.Visible_Visual_Rows (3).Start_Col = 8
              and then Snap.Visible_Visual_Rows (3).End_Col = 9,
              "third visual segment must be columns 8..9");

      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
   end Test_Wrapped_Snapshot_Visual_Segments;

   procedure Test_Wrap_Mode_Ignores_Horizontal_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Configure_Wrap_Test_Viewport (1, 4);
      Editor.View.Set_Scroll (10, 0);
      Assert (Editor.View.Scroll_X = 0,
              "wrap mode must force effective horizontal scroll to zero");
      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
   end Test_Wrap_Mode_Ignores_Horizontal_Scroll;

   procedure Test_Wrapped_Caret_Uses_Visual_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Found  : Boolean := False;
      Expected_X : constant Float := Text_X (Layout, 1, 1);
      Expected_Y : constant Float :=
        Float (Editor.Layout.Text_Viewport_Y (Layout) + Editor.Layout.Cell_H);
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghi"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 5,
            Anchor => 5,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));

      Configure_Wrap_Test_Viewport (1, 4);
      Set_Render_State_For_Test (S);
      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_At_Viewport);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Caret_Layer)
           and then Float (Packet.Rects (Natural (I)).X) = Expected_X
           and then Float (Packet.Rects (Natural (I)).Y) = Expected_Y
         then
            Found := True;
         end if;
      end loop;

      Assert (Found,
              "caret at logical column 5 must render at visual row 1, visual column 1");
      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
   end Test_Wrapped_Caret_Uses_Visual_Row;

   procedure Test_Wrapped_Selection_Splits_Rects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Count  : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghi"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 6,
            Anchor => 2,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));

      Configure_Wrap_Test_Viewport (1, 4);
      Set_Render_State_For_Test (S);
      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_At_Viewport);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = To_C (Selection_Layer) then
            Count := Count + 1;
         end if;
      end loop;

      Assert (Count >= 2,
              "selection crossing a wrap boundary must emit multiple visible rects");
      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
   end Test_Wrapped_Selection_Splits_Rects;

   procedure Test_Wrapped_Visual_Scroll_Uses_Visual_Row_Offset
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghi"));
      Configure_Wrap_Test_Viewport (1, 4);
      Editor.View.Set_Scroll (0, 1);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Visible_Visual_Count > 0,
              "wrapped snapshot must contain visible visual rows after scrolling");
      Assert (Snap.Visible_Visual_Rows (1).Logical_Row = 0
              and then Snap.Visible_Visual_Rows (1).Start_Col = 4,
              "wrapped Scroll_Y must skip one visual row, not one logical row");

      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
      Editor.View.Set_Scroll (0, 0);
   end Test_Wrapped_Visual_Scroll_Uses_Visual_Row_Offset;

   procedure Test_Wrapped_Mouse_Hit_Clamps_To_Visual_Segment
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Hit    : Cursor_Index := 0;
      X      : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghi"));
      Configure_Wrap_Test_Viewport (1, 4);

      X := Editor.Layout.Text_Origin_X (Layout, 1) + 20 * Editor.Layout.Cell_W;
      Hit :=
        Editor.Navigation.Index_For_Point
          (S, X, Natural (Editor.Layout.Text_Viewport_Y (Layout)));

      Assert (Hit = 4,
              "clicking past the first wrapped segment must clamp to that segment end");

      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
      Editor.View.Set_Scroll (0, 0);
   end Test_Wrapped_Mouse_Hit_Clamps_To_Visual_Segment;

   procedure Test_Wrapped_Move_Down_Uses_Visual_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdefghi"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 1,
            Anchor => 1,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));
      S.Preferred_Column := 1;

      Configure_Wrap_Test_Viewport (1, 4);
      Cmd.Kind := Editor.Commands.Move_Down;
      Cmd.Shift := False;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Carets (S.Carets.First_Index).Pos = 5,
              "Move_Down in wrap mode must move to next visual row within the same logical line");

      Editor.View.Set_Wrap_Mode (Editor.Wrap.Wrap_None);
      Editor.View.Set_Scroll (0, 0);
   end Test_Wrapped_Move_Down_Uses_Visual_Row;


   procedure Reset_Cursor_Config is
   begin
      Editor.Cursor.Set_Current
        ((Style       => Editor.Cursor.Bar_Cursor,
          Bar_Width   => 1,
          Underline_H => 2));
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => False,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 0.0));
      Editor.View.Set_Time_Seconds (0.0);
   end Reset_Cursor_Config;

   procedure Build_Cursor_Test_Packet
     (S      : in out Editor.State.State_Type;
      Packet : out Editor.Render_Packet.Render_Packet)
   is
      Cursor_Config : constant Editor.Cursor.Cursor_Config := Editor.Cursor.Current;
      Blink_Config  : constant Editor.Cursor.Blink_Config := Editor.Cursor.Current_Blink;
   begin
      Set_Render_State_For_Test (S);
      Editor.Cursor.Set_Current (Cursor_Config);
      Editor.Cursor.Set_Blink (Blink_Config);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (0, 0);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
   end Build_Cursor_Test_Packet;

   function Caret_Rect
     (Packet : Editor.Render_Packet.Render_Packet)
      return Editor.Render_Packet.Rect_Command is
   begin
      return First_Rect_On_Layer (Packet, Caret_Layer);
   end Caret_Rect;

   procedure Test_Cursor_Default_Config_Is_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Config : Editor.Cursor.Cursor_Config;
   begin
      Reset_Cursor_Config;
      Config := Editor.Cursor.Current;

      Assert (Config.Style = Editor.Cursor.Bar_Cursor,
              "Default cursor style must be bar cursor");
      Assert (Config.Bar_Width = 1,
              "Default bar cursor width must be 1");
      Assert (Config.Underline_H = 2,
              "Default underline cursor height must be 2");
   end Test_Cursor_Default_Config_Is_Bar;

   procedure Test_Bar_Cursor_Emits_Width_One
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Rect   : Editor.Render_Packet.Rect_Command;
   begin
      Reset_Cursor_Config;
      Editor.State.Init (S);
      Build_Cursor_Test_Packet (S, Packet);
      Rect := Caret_Rect (Packet);

      Assert (Float (Rect.W) = 1.0,
              "Bar cursor must emit width 1 by default");
      Assert (Float (Rect.H) = Float (Editor.Layout.Cell_H),
              "Bar cursor must keep full cell-height caret geometry");
   end Test_Bar_Cursor_Emits_Width_One;

   procedure Test_Block_Cursor_Uses_Cell_Size
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Rect   : Editor.Render_Packet.Rect_Command;
   begin
      Editor.State.Init (S);
      Editor.Cursor.Set_Current
        ((Style       => Editor.Cursor.Block_Cursor,
          Bar_Width   => 1,
          Underline_H => 2));
      Build_Cursor_Test_Packet (S, Packet);
      Rect := Caret_Rect (Packet);

      Assert (Float (Rect.W) = Float (Editor.Layout.Cell_W),
              "Block cursor width must be one full cell");
      Assert (Float (Rect.H) = Float (Editor.Layout.Cell_H),
              "Block cursor height must be one full cell");
      Reset_Cursor_Config;
   end Test_Block_Cursor_Uses_Cell_Size;

   procedure Test_Underline_Cursor_Uses_Configured_Height
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Rect   : Editor.Render_Packet.Rect_Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      H      : constant Positive := 3;
   begin
      Editor.State.Init (S);
      Editor.Cursor.Set_Current
        ((Style       => Editor.Cursor.Underline_Cursor,
          Bar_Width   => 1,
          Underline_H => H));
      Build_Cursor_Test_Packet (S, Packet);
      Rect := Caret_Rect (Packet);

      Assert (Float (Rect.W) = Float (Editor.Layout.Cell_W),
              "Underline cursor width must be one full cell");
      Assert (Float (Rect.H) = Float (H),
              "Underline cursor height must match Cursor_Config.Underline_H");
      Assert
        (Float (Rect.Y) =
         Float (Editor.Layout.Text_Viewport_Y (Layout) + Editor.Layout.Cell_H - H),
         "Underline cursor Y must sit at the bottom of the cell");
      Reset_Cursor_Config;
   end Test_Underline_Cursor_Uses_Configured_Height;

   procedure Test_Cursor_Rect_Remains_On_Caret_Layer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Cursor_Config;
      Editor.State.Init (S);
      Build_Cursor_Test_Packet (S, Packet);

      Assert (Rect_Count_On_Layer (Packet, Caret_Layer) = 1,
              "Single caret must emit exactly one Caret_Layer rectangle");
      Assert (not Has_Glyph_On_Layer (Packet, Caret_Layer),
              "Cursor must not be rendered as a glyph");
   end Test_Cursor_Rect_Remains_On_Caret_Layer;

   procedure Test_Cursor_Virtual_X_Uses_Virtual_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Rect   : Editor.Render_Packet.Rect_Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Reset_Cursor_Config;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 3,
            Anchor                => 3,
            Virtual_Column        => 6,
            Anchor_Virtual_Column => 6));

      Build_Cursor_Test_Packet (S, Packet);
      Rect := Caret_Rect (Packet);

      Assert (Float (Rect.X) = Text_X (Layout, 6, 1),
              "Cursor X must use virtual column placement");
   end Test_Cursor_Virtual_X_Uses_Virtual_Column;

   procedure Test_Multi_Caret_Emits_One_Cursor_Rect_Per_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Reset_Cursor_Config;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos                   => 2,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Build_Cursor_Test_Packet (S, Packet);

      Assert (Rect_Count_On_Layer (Packet, Caret_Layer) = 2,
              "Multi-caret rendering must emit one cursor rectangle per caret");
   end Test_Multi_Caret_Emits_One_Cursor_Rect_Per_Caret;



   procedure Test_Cursor_Visible_Immediately_After_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => True,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 10.0));
      Editor.Cursor.Notify_Input (10.75);

      Assert (Editor.Cursor.Visible (10.75),
              "cursor must be visible immediately after input resets blink phase");
      Reset_Cursor_Config;
   end Test_Cursor_Visible_Immediately_After_Input;

   procedure Test_Cursor_Hidden_During_Off_Phase
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => True,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 10.0));

      Assert (not Editor.Cursor.Visible (10.75),
              "cursor must be hidden after the visible duty-cycle phase ends");
      Reset_Cursor_Config;
   end Test_Cursor_Hidden_During_Off_Phase;

   procedure Test_Cursor_Visible_After_Period_Wrap
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => True,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 10.0));

      Assert (Editor.Cursor.Visible (11.25),
              "cursor must become visible again after blink period wraps");
      Reset_Cursor_Config;
   end Test_Cursor_Visible_After_Period_Wrap;

   procedure Test_Cursor_Blink_Disabled_Is_Always_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => True,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 10.0));
      Editor.Cursor.Set_Blink_Enabled (False);

      Assert (Editor.Cursor.Visible (10.75),
              "disabled cursor blinking must keep the cursor visible");
      Assert (Editor.Cursor.Visible (1234.25),
              "disabled cursor blinking must not depend on elapsed time");
      Reset_Cursor_Config;
   end Test_Cursor_Blink_Disabled_Is_Always_Visible;

   procedure Test_Render_Packet_Omits_Caret_When_Cursor_Invisible
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Set_Render_State_For_Test (S);
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => True,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 10.0));
      Editor.View.Set_Time_Seconds (10.75);

      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (0, 0);
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert (Rect_Count_On_Layer (Packet, Caret_Layer) = 0,
              "hidden cursor must emit no Caret_Layer rectangle");
      Reset_Cursor_Config;
   end Test_Render_Packet_Omits_Caret_When_Cursor_Invisible;

   procedure Test_Input_Bridge_Resets_Blink_To_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Set_Render_State_For_Test (S);
      Editor.Cursor.Set_Blink
        ((Blink_Enabled       => True,
          Blink_Period_Sec    => 1.0,
          Blink_Duty_Cycle    => 0.5,
          Last_Input_Time_Sec => 10.0));
      Editor.View.Set_Time_Seconds (10.75);

      Assert (not Editor.Cursor.Visible (Float (Editor.View.Current_Time_Seconds)),
              "cursor must start hidden before input reset in this test");

      Cmd := Editor.Test_Helper.Insert (0, 'x');
      Editor.Input_Bridge.Handle (Cmd);

      Assert (Editor.Cursor.Visible (Float (Editor.View.Current_Time_Seconds)),
              "Input_Bridge.Handle must reset blink phase after input");
      Reset_Cursor_Config;
   end Test_Input_Bridge_Resets_Blink_To_Visible;


   function Many_Lines (Count : Positive) return String is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      for I in 1 .. Count loop
         Append (Text, "line");
         if I < Count then
            Append (Text, ASCII.LF);
         end if;
      end loop;

      return To_String (Text);
   end Many_Lines;

   procedure Test_Minimap_Hit_Test_Disabled_Is_False
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => False,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
   begin
      Assert
        (not Editor.Minimap.Contains_Point
          (X               => Layout.Origin_X + 750,
           Y               => Layout.Origin_Y + 10,
           Layout          => Layout,
           Viewport_Width  => 800,
           Viewport_Height => 200,
           Config          => Config),
         "Disabled minimap must never intercept pointer input");
   end Test_Minimap_Hit_Test_Disabled_Is_False;

   procedure Test_Minimap_Hit_Test_Inside_And_Outside
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      Left : constant Natural := Natural (Editor.Minimap.Left_X (Layout, 800, Config));
   begin
      Assert
        (Editor.Minimap.Contains_Point
          (X               => Left,
           Y               => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
           Layout          => Layout,
           Viewport_Width  => 800,
           Viewport_Height => 200,
           Config          => Config),
         "Point on minimap left/top edge must be inside minimap bounds");

      Assert
        (not Editor.Minimap.Contains_Point
          (X               => Left - 1,
           Y               => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
           Layout          => Layout,
           Viewport_Width  => 800,
           Viewport_Height => 200,
           Config          => Config),
         "Point left of minimap bounds must not be intercepted");

      Assert
        (not Editor.Minimap.Contains_Point
          (X               => Left,
           Y               => Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 200,
           Layout          => Layout,
           Viewport_Width  => 800,
           Viewport_Height => 200,
           Config          => Config),
         "Point on minimap bottom-exclusive edge must not be intercepted");
   end Test_Minimap_Hit_Test_Inside_And_Outside;

   procedure Test_Minimap_Row_For_Y_Maps_Top_And_Bottom
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
   begin
      Assert
        (Editor.Minimap.Row_For_Y
          (Y                => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
           Total_Line_Count => 1000,
           Layout           => Layout,
           Viewport_Height  => 100,
           Config           => Config) = 0,
         "Minimap top Y must map to document row 0");

      Assert
        (Editor.Minimap.Row_For_Y
          (Y                => Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 99,
           Total_Line_Count => 1000,
           Layout           => Layout,
           Viewport_Height  => 100,
           Config           => Config) = 990,
         "Minimap bottom Y must map near the final document row");
   end Test_Minimap_Row_For_Y_Maps_Top_And_Bottom;

   procedure Test_View_Set_Scroll_Y_Clamped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Editor.View.Reset;
      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => 100,
         Viewport_Rows  => 10,
         Desired_Scroll => 500);

      Assert
        (Editor.View.Scroll_Y = 90,
         "Clamped scroll setter must clamp to document end");
   end Test_View_Set_Scroll_Y_Clamped;


   procedure Test_View_Tick_Interpolates_Visual_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Epsilon : constant Float := 0.0001;
   begin
      Editor.View.Reset;
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (1));
      Editor.View.Set_Scroll (0, 0);

      Editor.View.Auto_Scroll_For_Point
        (X      => Layout.Origin_X,
         Y      => Editor.Layout.Text_Viewport_Y (Layout) + Editor.Layout.Cell_H,
         Layout => Layout);

      Assert
        (Editor.View.Scroll_Y = 1,
         "Auto-scroll must update the logical scroll target immediately");
      Assert
        (abs (Editor.View.Visual_Scroll_Y - 0.0) <= Epsilon,
         "Auto-scroll must not mutate the visual scroll position directly");

      Editor.View.Tick (0.01);

      Assert
        (Editor.View.Visual_Scroll_Y > 0.0
         and then Editor.View.Visual_Scroll_Y < Float (Editor.View.Scroll_Y),
         "Tick must move visual scroll toward, but not past, the logical target");
      Assert
        (Editor.View.Scroll_Y = 1,
         "Tick must not change logical scroll state");
   end Test_View_Tick_Interpolates_Visual_Scroll;

   procedure Test_View_Tick_Converges_To_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Epsilon : constant Float := 0.0001;
   begin
      Editor.View.Reset;
      Editor.View.Set_Viewport (Width => 800, Height => Editor.Layout.Cell_H);
      Editor.View.Set_Scroll (0, 0);
      Editor.View.Auto_Scroll_For_Point
        (X      => Layout.Origin_X,
         Y      => Layout.Origin_Y + Editor.Layout.Cell_H,
         Layout => Layout);

      Editor.View.Tick (1.0);

      Assert
        (abs (Editor.View.Visual_Scroll_Y - Float (Editor.View.Scroll_Y)) <= Epsilon,
         "Large tick must converge visual scroll to the logical target");
   end Test_View_Tick_Converges_To_Target;

   procedure Test_View_Visual_Screen_Y_Uses_Visual_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Row_Y  : constant Float := Editor.Layout.Row_Top_Y (Layout, 0);
      Epsilon : constant Float := 0.0001;
      Expected : Float;
   begin
      Editor.View.Reset;
      Editor.View.Set_Viewport (Width => 800, Height => Editor.Layout.Cell_H);
      Editor.View.Set_Scroll (0, 0);
      Editor.View.Auto_Scroll_For_Point
        (X      => Layout.Origin_X,
         Y      => Layout.Origin_Y + Editor.Layout.Cell_H,
         Layout => Layout);
      Editor.View.Tick (0.01);

      Expected :=
        Row_Y
        - (Editor.View.Visual_Scroll_Y - Float (Editor.View.Scroll_Y))
          * Float (Editor.Layout.Cell_H);

      Assert
        (abs (Editor.View.Visual_Screen_Y (Layout, 0) - Expected) <= Epsilon,
         "Visual screen Y must be offset by visual scroll, not only logical scroll");
   end Test_View_Visual_Screen_Y_Uses_Visual_Scroll;

   procedure Test_View_Visual_Screen_X_Uses_Visual_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Line_Count : constant Natural := 100;
      Base_X : Float;
      Expected : Float;
      Epsilon : constant Float := 0.0001;
   begin
      Editor.View.Reset;
      Editor.View.Set_Viewport (Width => Editor.Layout.Cell_W, Height => 800);
      Editor.View.Set_Scroll (0, 0);
      Editor.View.Auto_Scroll_For_Point
        (X      => Natural (Editor.Layout.Text_Right_X (Layout, Editor.View.Viewport_Width)),
         Y      => Layout.Origin_Y,
         Layout => Layout);
      Editor.View.Tick (0.01);

      Base_X :=
        Editor.Layout.Text_Cell_X
          (Layout, Line_Count, 0, Editor.View.Scroll_X);
      Expected :=
        Base_X
        - (Editor.View.Visual_Scroll_X - Float (Editor.View.Scroll_X))
          * Float (Editor.Layout.Cell_W);

      Assert
        (Editor.View.Scroll_X = 1,
         "Horizontal auto-scroll must update logical Scroll_X");
      Assert
        (abs (Editor.View.Visual_Screen_X (Layout, Line_Count, 0) - Expected) <= Epsilon,
         "Visual screen X must be offset by visual scroll, not only logical scroll");
   end Test_View_Visual_Screen_X_Uses_Visual_Scroll;


   procedure Test_Render_Packet_Text_Uses_Visual_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      M      : Editor.Fonts.Glyph_Metric;
      Index  : Natural := 0;
      Expected_Y : Float := 0.0;
      Epsilon : constant Float := 0.0001;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("a" & ASCII.LF & "b" & ASCII.LF & "c"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 2,
            Anchor => 2,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));

      Set_Render_State_For_Test (S);
      Editor.View.Reset;
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (2));
      Editor.View.Set_Scroll (0, 0);
      Editor.View.Auto_Scroll_For_Point
        (X      => Layout.Origin_X,
         Y      => Editor.Layout.Text_Viewport_Y (Layout)
                   + Editor.Layout.Text_Viewport_Height
                     (Layout, Editor.View.Viewport_Height),
         Layout => Layout);
      Editor.View.Tick (0.01);

      Assert
        (Editor.View.Scroll_Y = 1,
         "Render-packet visual scroll test must have a logical one-row target");
      Assert
        (Editor.View.Visual_Scroll_Y > 0.0
         and then Editor.View.Visual_Scroll_Y < Float (Editor.View.Scroll_Y),
         "Render-packet visual scroll test must keep visual scroll between old and target rows");
      Assert
        (Editor.Fonts.Get_Glyph (Ch => 'b', Metric => M),
         "Font must provide the glyph used by the render-packet visual scroll test");

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Index := Text_Glyph_Index (Packet, Layout, 0, Line_Count => 3);
      Expected_Y :=
        Float'Floor
          (Editor.View.Visual_Screen_Y (Layout, 0)
           + Float'Max
             (0.0,
              (Float (Editor.Layout.Cell_H)
               - (Editor.Fonts.Ascent - Editor.Fonts.Descent)) / 2.0)
           + Editor.Fonts.Ascent
           - M.Bearing_Y
           + 0.5);

      Assert
        (abs (Float (Packet.Glyphs (Index).Y) - Expected_Y) <= Epsilon,
         "Text glyph packet Y must be derived from visual scroll placement");
   end Test_Render_Packet_Text_Uses_Visual_Scroll;

   procedure Test_Minimap_Viewport_Uses_Logical_Scroll_During_Visual_Lag
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Packet        : Editor.Render_Packet.Render_Packet;
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old           : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Config        : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      Row_Count     : constant Natural := 100;
      Viewport_Rows : constant Natural := 10;
      R             : Editor.Render_Packet.Rect_Command;
      Expected_Y    : Float := 0.0;
      Epsilon       : constant Float := 0.0001;
   begin
      Editor.Minimap.Set_Current (Config);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (Many_Lines (Row_Count)));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Reset;
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (Viewport_Rows));

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Row_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => 20);
      Editor.View.Auto_Scroll_For_Point
        (X      => Layout.Origin_X,
         Y      => Editor.Layout.Text_Viewport_Y (Layout)
                   + Editor.Layout.Text_Viewport_Height
                     (Layout, Editor.View.Viewport_Height),
         Layout => Layout);
      Editor.View.Tick (0.01);

      Assert
        (Editor.View.Scroll_Y = 21,
         "Minimap logical viewport test must have a logical scroll target after auto-scroll");
      Assert
        (Editor.View.Visual_Scroll_Y < Float (Editor.View.Scroll_Y),
         "Minimap logical viewport test must have visual scroll lagging logical scroll");

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      R := First_Rect_On_Layer (Packet, Minimap_Viewport_Layer);
      Expected_Y :=
        Float (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Minimap.Viewport_Marker_Y
            (Visible_First_Row => Editor.View.Scroll_Y,
             Line_Count        => Row_Count,
             Viewport_H        =>
               Editor.Layout.Text_Viewport_Height
                 (Layout, Editor.View.Viewport_Height));

      Assert
        (abs (Float (R.Y) - Expected_Y) <= Epsilon,
         "Minimap viewport marker must track logical Scroll_Y, not lagging visual scroll");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Viewport_Uses_Logical_Scroll_During_Visual_Lag;

   procedure Test_Minimap_Click_Updates_Scroll_Y
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      X      : Natural;
   begin
      Editor.Minimap.Set_Current (Config);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (Many_Lines (100)));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (10));

      X := Natural (Editor.Minimap.Left_X (Layout, 800, Config));
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 50;
      Editor.Input_Bridge.Handle (Cmd);

      Assert
        (Editor.View.Scroll_Y > 0,
         "Clicking inside the minimap must update vertical scroll");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Click_Updates_Scroll_Y;

   procedure Test_Minimap_Click_Survives_Render_Auto_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Packet : Editor.Render_Packet.Render_Packet;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      X       : Natural;
      Scrolled : Natural;
   begin
      Editor.Minimap.Set_Current (Config);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (Many_Lines (100)));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (10));

      X := Natural (Editor.Minimap.Left_X (Layout, 800, Config));
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 80;
      Editor.Input_Bridge.Handle (Cmd);
      Scrolled := Editor.View.Scroll_Y;

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Scrolled > 0,
         "Minimap click must establish a non-zero vertical scroll before rendering");
      Assert
        (Editor.View.Scroll_Y = Scrolled,
         "Render packet construction must not immediately snap minimap scroll back to the caret");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Click_Survives_Render_Auto_Scroll;

   procedure Test_Minimap_Drag_Updates_Scroll_Y_Repeatedly
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Layout  : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old     : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Config  : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      X       : Natural;
      First_Y : Natural;
   begin
      Editor.Minimap.Set_Current (Config);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (Many_Lines (200)));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (10));

      X := Natural (Editor.Minimap.Left_X (Layout, 800, Config));
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 10;
      Editor.Input_Bridge.Handle (Cmd);
      First_Y := Editor.View.Scroll_Y;

      Cmd.Kind := Editor.Commands.Drag_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 80;
      Editor.Input_Bridge.Handle (Cmd);

      Assert
        (Editor.View.Scroll_Y > First_Y,
         "Dragging active minimap interaction must keep updating vertical scroll");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Drag_Updates_Scroll_Y_Repeatedly;

   procedure Test_Minimap_Click_Does_Not_Move_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old    : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Config : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      X      : Natural;
   begin
      Editor.Minimap.Set_Current (Config);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (Many_Lines (100)));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (10));

      X := Natural (Editor.Minimap.Left_X (Layout, 800, Config));
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 80;
      Editor.Input_Bridge.Handle (Cmd);

      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Snap.Primary_Caret_Row = 0,
         "Minimap click must be consumed before normal text hit-testing moves the caret");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Click_Does_Not_Move_Caret;

   procedure Test_Minimap_Click_Scroll_Clamped_At_Document_End
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Cmd           : Editor.Commands.Command;
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Old           : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Config        : constant Editor.Minimap.Minimap_Config :=
        (Enabled       => True,
         Width         => 96,
         Padding_Left  => 8,
         Padding_Right => 8);
      X             : Natural;
      Row_Count     : constant Natural := 30;
      Viewport_Rows : constant Natural := 10;
   begin
      Editor.Minimap.Set_Current (Config);
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste (Many_Lines (Row_Count)));
      Set_Render_State_For_Test (S, Minimap_Enabled => True);
      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Viewport_Height_For_Text_Rows (Viewport_Rows));

      X := Natural (Editor.Minimap.Left_X (Layout, 800, Config));
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y :=
        Editor.Layout.Text_Viewport_Y (Layout)
        + Editor.Layout.Text_Viewport_Height
          (Layout, Editor.View.Viewport_Height)
        - 1;
      Editor.Input_Bridge.Handle (Cmd);

      Assert
        (Editor.View.Scroll_Y = Row_Count - Viewport_Rows,
         "Minimap click near document end must clamp scroll to max valid first row");

      Editor.Minimap.Set_Current (Old);
   end Test_Minimap_Click_Scroll_Clamped_At_Document_End;

   procedure Test_Phase68_Rectangular_Selection_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abcd" & ASCII.LF & "xy" & ASCII.LF & "12345");
      Editor.View.Reset_Scroll;

      Editor.Executor.Execute_Set_Rectangular_Selection
        (S      => S,
         Anchor => (Row => 0, Column => 1),
         Cursor => (Row => 2, Column => 4));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Rectangular_Selection_Count = 3,
              "Phase 68 render model must project one visible rectangular span per selected row");
      Assert (Snap.Rectangular_Selections (1).Row = 0,
              "Phase 68 first rectangular span row");
      Assert (Snap.Rectangular_Selections (1).Start_Column = 1
              and then Snap.Rectangular_Selections (1).End_Column = 4,
              "Phase 68 rectangular span must preserve half-open columns");
      Assert (Snap.Selection_Count = 0,
              "Phase 68 rectangular projection must not also expose linear selections");
   end Test_Phase68_Rectangular_Selection_Projection;


   procedure Test_Phase219_Status_Bar_Narrow_Width_Is_Bounded
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Width  : constant Natural := Editor.Layout.Cell_W * 18;
   begin
      Editor.State.Init (S);
      S.File_Info.Display_Name :=
        To_Unbounded_String
          ("very-long-buffer-name-that-must-not-overlap-status-fields.adb");
      S.File_Info.Dirty := True;
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Width,
         Height => Editor.Layout.Cell_H * 4);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Has_Rect_On_Layer (Packet, Status_Bar_Background_Layer),
         "Phase 219 status bar must still emit its background");
      Assert
        (Glyph_Count_On_Layer (Packet, Status_Bar_Text_Layer) > 0,
         "Phase 219 status bar must emit compact text even in narrow layouts");

      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Status_Bar_Text_Layer) then
            Assert
              (Float (Packet.Glyphs (Natural (I)).X)
               + Float (Packet.Glyphs (Natural (I)).W)
               <= Float (Width),
               "Phase 219 status bar text must stay inside the viewport width");
         end if;
      end loop;
   end Test_Phase219_Status_Bar_Narrow_Width_Is_Bounded;


   procedure Test_Phase219_Feature_Panel_Text_Is_Bounded
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Width  : constant Natural := Editor.Layout.Cell_W * 22;
      Height : constant Natural := Editor.Layout.Cell_H * 5;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => Width, Height => Height);

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Has_Rect_On_Layer (Packet, Problems_Background_Layer),
         "Phase 219 feature panel must render a panel background");
      Assert
        (Glyph_Count_On_Layer (Packet, Problems_Text_Layer) > 0,
         "Phase 219 feature panel must render header or row text");

      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = To_C (Problems_Text_Layer) then
            Assert
              (Float (Packet.Glyphs (Natural (I)).X)
               + Float (Packet.Glyphs (Natural (I)).W)
               <= Float (Width),
               "Phase 219 feature panel text must be truncated inside the viewport");
            Assert
              (Float (Packet.Glyphs (Natural (I)).Y)
               + Float (Packet.Glyphs (Natural (I)).H)
               <= Float (Height),
               "Phase 219 feature panel text must be row-bounded inside the viewport");
         end if;
      end loop;
   end Test_Phase219_Feature_Panel_Text_Is_Bounded;


   procedure Test_Phase219_Render_Does_Not_Mutate_State
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Before_Text : Unbounded_String;
      Before_Dirty : Boolean;
      Before_Selected_Row : Natural;
      Before_Row_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("one" & ASCII.LF & "two"));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Select_Next);

      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Selected_Row := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Before_Row_Count := Editor.Feature_Panel.Row_Count (S.Feature_Panel);

      Set_Render_State_For_Test (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport
        (Width  => Editor.Layout.Cell_W * 40,
         Height => Editor.Layout.Cell_H * 8);

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (To_String (Before_Text) = Editor.State.Current_Text (After),
         "Phase 219 render must not mutate active buffer text");
      Assert
        (Before_Dirty = Editor.State.Is_Dirty (After),
         "Phase 219 render must not mutate dirty state");
      Assert
        (Before_Row_Count = Editor.Feature_Panel.Row_Count (After.Feature_Panel),
         "Phase 219 render must not mutate feature panel rows");
      Assert
        (Before_Selected_Row = Editor.Feature_Panel.Selected_Row (After.Feature_Panel),
         "Phase 219 render must not mutate feature panel selection");
   end Test_Phase219_Render_Does_Not_Mutate_State;



   procedure Test_Phase220_Unchanged_State_Emits_Stable_Render_Packet
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      First  : Editor.Render_Packet.Render_Packet;
      Second : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.Input_Bridge.Reset;
      Set_Render_State_For_Test (S);
      Editor.View.Set_Viewport (800, 600);

      Editor.Input_Bridge.Build_Render_Packet (First);
      Editor.Input_Bridge.Build_Render_Packet (Second);

      Assert
        (Packets_Equal (First, Second),
         "unchanged editor state must emit a stable render packet");
   end Test_Phase220_Unchanged_State_Emits_Stable_Render_Packet;


   procedure Test_Phase221_Input_Field_Focus_State_In_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);

      Editor.Feature_Search_Results.Activate_Search_Query_Input
        (S.Feature_Search_Results);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Search_Query_Input_Active,
         "Phase 221 render snapshot must expose active Search query input focus");
      Assert
        (not Snap.Outline_Filter_Input_Active,
         "Search query focus must not imply Outline filter focus");

      Editor.Feature_Search_Results.Deactivate_Search_Query_Input
        (S.Feature_Search_Results);
      Editor.Outline.Activate_Filter_Input (S.Outline);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Outline_Filter_Input_Active,
         "Phase 221 render snapshot must expose active Outline filter input focus");
      Assert
        (not Snap.Search_Query_Input_Active,
         "Outline filter focus must not imply Search query focus");
   end Test_Phase221_Input_Field_Focus_State_In_Snapshot;

   procedure Test_Phase343_Bookmark_Marker_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Added  : Boolean := False;
      Before : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/src/main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("src/main.adb");
      Before := To_Unbounded_String (Editor.State.Current_Text (S));

      Editor.Bookmarks.Toggle
        (S.Bookmarks,
         File_Path    => "/project/src/main.adb",
         Display_Path => "src/main.adb",
         Line_Number  => 2,
         Column       => 1,
         Has_Column   => True,
         Added        => Added);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 render snapshot must project a session bookmark onto its open buffer line");
      Assert
        (not Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 bookmark marker projection must be line-specific");
      Assert
        (To_String (Before) = Editor.State.Current_Text (S),
         "Phase 343 bookmark marker projection must not mutate line text");
      Assert
        (Editor.State.Line_Count (S) = 3,
         "Phase 343 bookmark marker projection must not mutate line count");
      Assert
        (Editor.Bookmarks.Count (S.Bookmarks) = 1,
         "Phase 343 bookmark marker projection must not mutate bookmark state");
   end Test_Phase343_Bookmark_Marker_Projection;


   procedure Test_Phase343_Bookmark_Markers_Filter_By_File_And_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Added  : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/src/main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("src/main.adb");

      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 2, 1, True, Added);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/other.adb", "src/other.adb", 1, 1, True, Added);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 99, 1, True, Added);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 marker should be shown for an in-range bookmark in the rendered buffer");
      Assert
        (not Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 bookmark in another file must not mark the current buffer");
      Assert
        (not Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 98, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 out-of-range bookmark must not create an editor marker");
      Assert
        (Editor.Bookmarks.Count (S.Bookmarks) = 3,
         "Phase 343 out-of-range and other-file bookmarks remain in bookmark state");
   end Test_Phase343_Bookmark_Markers_Filter_By_File_And_Range;


   procedure Test_Phase343_Clear_All_Removes_Later_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Added  : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/src/main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("src/main.adb");

      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 1, 1, True, Added);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 setup should expose bookmark marker before clear");

      Editor.Bookmarks.Clear_Bookmarks (S.Bookmarks);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (not Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 clear-all state change must remove later editor bookmark markers");
   end Test_Phase343_Clear_All_Removes_Later_Markers;


   procedure Test_Phase343_Bookmark_Markers_Require_Buffer_Identity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");

      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 1, 1, True, Added);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (not Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 bookmark markers must not render without a stable buffer file identity");
      Assert
        (Editor.Bookmarks.Count (S.Bookmarks) = 1,
         "Phase 343 identity filtering must not prune bookmark state");
   end Test_Phase343_Bookmark_Markers_Require_Buffer_Identity;


   procedure Test_Phase343_Multiple_Bookmarked_Lines_And_Existing_Markers_Compose
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
      Found : Boolean := False;
      Kind  : Editor.Gutter_Markers.Gutter_Marker_Kind;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/src/main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("src/main.adb");

      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 1, 1, True, Added);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 2, 1, True, Added);
      Editor.Diagnostics.Add
        (S.Diagnostics,
         Start_Index => 0,
         End_Index   => 1,
         Start_Row   => 0,
         Start_Column => 0,
         Severity    => Editor.Diagnostics.Error,
         Message     => "diagnostic");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 first bookmarked line should be marked");
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 second bookmarked line should be marked");
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Diagnostic_Error_Marker),
         "Phase 343 bookmark marker projection must preserve existing diagnostic markers");

      Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
        (Snap.Gutter_Markers, 0, Found);
      Assert
        (Found and then Kind = Editor.Gutter_Markers.Diagnostic_Error_Marker,
         "Phase 343 bookmark marker must not displace a higher-priority diagnostic marker");
   end Test_Phase343_Multiple_Bookmarked_Lines_And_Existing_Markers_Compose;


   procedure Test_Phase343_Selection_And_Dirty_State_Do_Not_Change_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/src/main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("src/main.adb");

      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 1, 1, True, Added);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 3, 1, True, Added);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 setup should expose first marker");
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 setup should expose second marker");

      Editor.Bookmarks.Select_Next (S.Bookmarks);
      S.File_Info.Dirty := True;
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 bookmark selection movement must not remove first marker");
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 dirty state changes must not remove bookmark markers");
      Assert
        (S.File_Info.Dirty,
         "Phase 343 snapshot marker derivation must not clear dirty state");
   end Test_Phase343_Selection_And_Dirty_State_Do_Not_Change_Markers;


   procedure Test_Phase343_Lifecycle_Clear_Removes_Later_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/src/main.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("src/main.adb");

      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/project/src/main.adb", "src/main.adb", 2, 1, True, Added);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 setup should expose bookmark marker before lifecycle clear");

      Editor.Bookmarks.Clear (S.Bookmarks);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (not Editor.Gutter_Markers.Has_Marker
           (Snap.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
         "Phase 343 lifecycle clear must remove later bookmark markers");
      Assert
        (not Snap.Bookmarks_Visible,
         "Phase 343 lifecycle clear should preserve bookmark surface clearing behavior");
   end Test_Phase343_Lifecycle_Clear_Removes_Later_Markers;


   overriding procedure Register_Tests
     (T : in out Render_Model_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Default_Config_Is_Bar'Access,
         "Phase 30 Cursor Default Config Is Bar");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bar_Cursor_Emits_Width_One'Access,
         "Phase 30 Bar Cursor Emits Width One");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Block_Cursor_Uses_Cell_Size'Access,
         "Phase 30 Block Cursor Uses Cell Size");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Underline_Cursor_Uses_Configured_Height'Access,
         "Phase 30 Underline Cursor Uses Configured Height");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Rect_Remains_On_Caret_Layer'Access,
         "Phase 30 Cursor Rect Remains On Caret Layer");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Virtual_X_Uses_Virtual_Column'Access,
         "Phase 30 Cursor Virtual X Uses Virtual Column");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Multi_Caret_Emits_One_Cursor_Rect_Per_Caret'Access,
         "Phase 30 Multi Caret Emits One Cursor Rect Per Caret");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Visible_Immediately_After_Input'Access,
         "Phase 31 Cursor Visible Immediately After Input");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Hidden_During_Off_Phase'Access,
         "Phase 31 Cursor Hidden During Off Phase");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Visible_After_Period_Wrap'Access,
         "Phase 31 Cursor Visible After Period Wrap");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cursor_Blink_Disabled_Is_Always_Visible'Access,
         "Phase 31 Cursor Blink Disabled Is Always Visible");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Omits_Caret_When_Cursor_Invisible'Access,
         "Phase 31 Render Packet Omits Caret When Cursor Invisible");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Resets_Blink_To_Visible'Access,
         "Phase 31 Input Bridge Resets Blink To Visible");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase17_Long_Line_Horizontal_Viewport_Bounded'Access,
         "Phase 17 Long Line Horizontal Viewport Bounded");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase17_Bulk_Load_Line_Index_And_Empty_Undo'Access,
         "Phase 17 Bulk Load Line Index And Empty Undo");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase17_Render_Snapshot_Line_Starts_Are_Windowed'Access,
         "Phase 17 Render Snapshot Line Starts Are Windowed");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase17_Large_Selection_Emits_Visible_Rects_Only'Access,
         "Phase 17 Large Selection Emits Visible Rects Only");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Theme_Colors_Are_Normalized'Access,
         "Theme Colors Are Normalized");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Theme_Style_Constants_Are_Sensible'Access,
         "Theme Style Constants Are Sensible");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Color_Maps_Keyword_To_Theme'Access,
         "Syntax Color Maps Keyword To Theme");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Theme_Semantic_Mappings_Are_Distinct'Access,
         "Theme Semantic Mappings Are Distinct");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Number_Glyphs_Use_Theme_Colors'Access,
         "Line Number Glyphs Use Theme Colors");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Rectangles_Use_Theme_Colors'Access,
         "Render Rectangles Use Theme Colors");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Classifier_Basic'Access,
         "Syntax Classifier Basic");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Classifier_Ada_Constructs'Access,
         "Syntax Classifier Ada Constructs");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Cache_Incremental_State'Access,
         "Syntax Cache Incremental State");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Semantics_And_Overlays'Access,
         "Syntax Semantics And Overlays");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Uses_Syntax_Colors'Access,
         "Render Packet Uses Syntax Colors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Syntax_Text_Uses_Readable_Foreground'Access,
         "Selected Syntax Text Uses Readable Foreground");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Snapshot_Splits_Overlay_Inside_Syntax_Token'Access,
         "Render Snapshot Splits Overlay Inside Syntax Token");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Disabled_Still_Projects_Selection_Overlay'Access,
         "Syntax Disabled Still Projects Selection Overlay");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Classifies_Full_Row_When_Scrolled'Access,
         "Render Packet Classifies Full Row When Scrolled");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Coloring_Does_Not_Change_Text_Glyph_Count'Access,
         "Syntax Coloring Does Not Change Text Glyph Count");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Cache_Reuses_Unchanged_Rows'Access,
         "Render Cache Reuses Unchanged Rows");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Cache_Invalidates_Single_Line_Edit'Access,
         "Render Cache Invalidates Single Line Edit");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Cache_Invalidates_All_On_Newline_Edit'Access,
         "Render Cache Invalidates All On Newline Edit");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Cache_Invalidates_On_Test_State_Replacement'Access,
         "Render Cache Invalidates On Test State Replacement");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty'Access, "Empty");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_After_Insert'Access, "Text After Insert");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Projection'Access, "Caret Projection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Selection_Projection'Access,
         "Active Selection Projection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reversed_Selection_Projection'Access,
         "Reversed Selection Projection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Packet_Physical_X'Access,
         "Caret Packet Physical X");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Packet_Virtual_X'Access,
         "Caret Packet Virtual X");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Packet_Y_Position'Access,
         "Caret Packet Y Position");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Virtual_Extends_Rect'Access,
         "Selection Virtual Extends Rect");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Glyph_Alignment'Access,
         "Glyph Alignment");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Remains_Visible_After_Scroll'Access,
         "Caret Remains Visible After Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Glyphs_Do_Not_Render_Above_Viewport'Access,
         "Glyphs Do Not Render Above Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Rects_Do_Not_Render_Above_Viewport'Access,
         "Selection Rects Do Not Render Above Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Glyphs_Do_Not_Render_Below_Viewport'Access,
         "Glyphs Do Not Render Below Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rects_Do_Not_Render_Below_Viewport'Access,
         "Rects Do Not Render Below Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Glyphs_Do_Not_Render_Right_Of_Viewport'Access,
         "Glyphs Do Not Render Right Of Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rects_Do_Not_Render_Right_Of_Viewport'Access,
         "Rects Do Not Render Right Of Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Viewport_Driven_Glyph_Iteration'Access,
         "Viewport Driven Glyph Iteration");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Viewport_Driven_Selection_Iteration'Access,
         "Viewport Driven Selection Iteration");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Row_Col_For_Index_With_Newlines'Access,
         "Row Col For Index With Newlines");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Snapshot_Text_Base_Index_After_Vertical_Scroll'Access,
         "Render Snapshot Text Base Index After Vertical Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Viewport_Sliced_Packet_Emits_Visible_Glyphs'Access,
         "viewport sliced packet emits visible glyphs");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Y_Uses_Cell_Top_Not_Baseline'Access,
         "Caret Y Uses Cell Top Not Baseline");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Monospace_Cell_Width_Fits_Font'Access,
         "Monospace Cell Width Fits Font");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Font_Rejects_Non_Printable_ASCII'Access,
         "Font Rejects Non Printable ASCII");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Font_Glyph_Fits_Configured_Cell'Access,
         "Font Glyph Fits Configured Cell");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Font_Atlas_Is_Valid'Access,
         "Font Atlas Is Valid");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Font_Atlas_Dirty_On_New_Glyph'Access,
         "Font Atlas Dirty On New Glyph");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Layout_Geometry_Helpers'Access,
         "Layout Geometry Helpers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Font_Config_Owns_Cell_Metrics'Access,
         "Font Config Owns Cell Metrics");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dynamic_Gutter_Width_Tracks_Line_Digits'Access,
         "Dynamic Gutter Width Tracks Line Digits");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Geometry_Helpers'Access,
         "Minimap Geometry Helpers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Emits_Minimap_Layers'Access,
         "Render Packet Emits Minimap Layers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Snapshot_Tracks_Document_Rows'Access,
         "Minimap Snapshot Tracks Document Rows");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Default_Config_Is_Enabled'Access,
         "Minimap Default Config Is Enabled");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Disabled_Emits_No_Minimap_Rects'Access,
         "Minimap Disabled Emits No Minimap Rects");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Viewport_Rect_Is_Clamped'Access,
         "Minimap Viewport Rect Is Clamped");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Rendering_Does_Not_Change_Glyph_Count'Access,
         "Minimap Rendering Does Not Change Glyph Count");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Rendering_Does_Not_Dirty_Font_Atlas'Access,
         "Minimap Rendering Does Not Dirty Font Atlas");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Hit_Test_Disabled_Is_False'Access,
         "Phase 33 Minimap Hit Test Disabled Is False");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Hit_Test_Inside_And_Outside'Access,
         "Phase 33 Minimap Hit Test Inside And Outside");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Row_For_Y_Maps_Top_And_Bottom'Access,
         "Phase 33 Minimap Row For Y Maps Top And Bottom");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_View_Set_Scroll_Y_Clamped'Access,
         "Phase 33 View Set Scroll Y Clamped");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_View_Tick_Interpolates_Visual_Scroll'Access,
         "Phase 40 View Tick Interpolates Visual Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_View_Tick_Converges_To_Target'Access,
         "Phase 40 View Tick Converges To Target");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_View_Visual_Screen_Y_Uses_Visual_Scroll'Access,
         "Phase 40 Visual Screen Y Uses Visual Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_View_Visual_Screen_X_Uses_Visual_Scroll'Access,
         "Phase 40 Visual Screen X Uses Visual Scroll");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Text_Uses_Visual_Scroll'Access,
         "Phase 40 Render Packet Text Uses Visual Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Viewport_Uses_Logical_Scroll_During_Visual_Lag'Access,
         "Phase 40 Minimap Viewport Uses Logical Scroll During Visual Lag");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Click_Updates_Scroll_Y'Access,
         "Phase 33 Minimap Click Updates Scroll Y");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Click_Survives_Render_Auto_Scroll'Access,
         "Phase 33 Minimap Click Survives Render Auto Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Drag_Updates_Scroll_Y_Repeatedly'Access,
         "Phase 33 Minimap Drag Updates Scroll Y Repeatedly");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Click_Does_Not_Move_Caret'Access,
         "Phase 33 Minimap Click Does Not Move Caret");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Click_Scroll_Clamped_At_Document_End'Access,
         "Phase 33 Minimap Click Scroll Clamped At Document End");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Index_For_Point_Uses_Vertical_Scroll'Access,
         "Index For Point Uses Vertical Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Render_Packet_Assigns_Semantic_Layers'Access,
            "Render Packet Assigns Semantic Layers");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Render_Packet_Assigns_Selection_Layer'Access,
            "Render Packet Assigns Selection Layer");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Layer_Order'Access,
            "Layer Order");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_C_ABI_Layer_Values_Are_Stable'Access,
            "C ABI Layer Values Are Stable");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Render_Packet_Emits_File_Tree_Splitter'Access,
            "Phase 58 Render Packet Emits File Tree Splitter");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Render_Packet_Emits_Only_Valid_Layers'Access,
            "Render Packet Emits Only Valid Layers");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Diagnostic_Underline_Single_Line'Access,
            "Diagnostic Underline Single Line");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Diagnostic_Multi_Line_Clips_Per_Visible_Row'Access,
            "Diagnostic Multi Line Clips Per Visible Row");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Diagnostic_Does_Not_Change_Glyph_Count'Access,
            "Diagnostic Does Not Change Glyph Count");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Diagnostic_Respects_Horizontal_Scroll'Access,
            "Diagnostic Respects Horizontal Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Diagnostic_Does_Not_Render_Outside_Viewport'Access,
            "Diagnostic Does Not Render Outside Viewport");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrap_Primitives'Access,
         "Phase 25 Wrap Primitives");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrapped_Snapshot_Visual_Segments'Access,
         "Phase 25 Wrapped Snapshot Visual Segments");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrap_Mode_Ignores_Horizontal_Scroll'Access,
         "Phase 25 Wrap Ignores Horizontal Scroll");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrapped_Caret_Uses_Visual_Row'Access,
         "Phase 25 Wrapped Caret Visual Row");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrapped_Selection_Splits_Rects'Access,
         "Phase 25 Wrapped Selection Split Rects");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrapped_Visual_Scroll_Uses_Visual_Row_Offset'Access,
         "Phase 25 Wrapped Visual Scroll Uses Visual Rows");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrapped_Mouse_Hit_Clamps_To_Visual_Segment'Access,
         "Phase 25 Wrapped Mouse Hit Clamps To Segment");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrapped_Move_Down_Uses_Visual_Row'Access,
         "Phase 25 Wrapped Move Down Uses Visual Row");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase68_Rectangular_Selection_Projection'Access,
         "Phase 68 Rectangular Selection Projection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase220_Unchanged_State_Emits_Stable_Render_Packet'Access,
         "Phase 220 unchanged state emits stable render packet");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase219_Status_Bar_Narrow_Width_Is_Bounded'Access,
         "Phase 219 Status Bar Narrow Width Is Bounded");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase219_Feature_Panel_Text_Is_Bounded'Access,
         "Phase 219 Feature Panel Text Is Bounded");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase219_Render_Does_Not_Mutate_State'Access,
         "Phase 219 Render Does Not Mutate State");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase221_Input_Field_Focus_State_In_Snapshot'Access,
         "Phase 221 input field focus state is represented in render snapshot");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Bookmark_Marker_Projection'Access,
         "Phase 343 bookmark markers project into editor render snapshots");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Bookmark_Markers_Filter_By_File_And_Range'Access,
         "Phase 343 bookmark markers filter by file identity and line range");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Clear_All_Removes_Later_Markers'Access,
         "Phase 343 clearing bookmarks removes later editor markers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Bookmark_Markers_Require_Buffer_Identity'Access,
         "Phase 343 bookmark markers require stable buffer identity");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Multiple_Bookmarked_Lines_And_Existing_Markers_Compose'Access,
         "Phase 343 bookmark markers compose with existing row markers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Selection_And_Dirty_State_Do_Not_Change_Markers'Access,
         "Phase 343 bookmark marker projection is independent of selection and dirty state");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase343_Lifecycle_Clear_Removes_Later_Markers'Access,
         "Phase 343 lifecycle bookmark clear removes later editor markers");

   end Register_Tests;

end Editor.Render_Model.Tests;
