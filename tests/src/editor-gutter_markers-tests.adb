with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Interfaces.C; use Interfaces.C;
with Editor.Commands;
with Editor.Cursors;
with Editor.Diagnostics;
with Editor.Dirty_Lines;
with Editor.Folding;
with Editor.Gutter;
with Editor.Gutter_Markers;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Scrollbars;
with Editor.State;
with Editor.Theme;
with Editor.View;

use type Editor.Gutter.Gutter_Zone;
use type Editor.Gutter_Markers.Gutter_Marker_Action;
use type Editor.Gutter_Markers.Gutter_Marker_Kind;

package body Editor.Gutter_Markers.Tests is

   overriding function Name
     (T : Gutter_Markers_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Gutter_Markers");
   end Name;

   function Row_Y (Visible_Row : Natural) return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      return Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Visible_Row * Editor.Layout.Cell_H
        + Editor.Layout.Cell_H / 2;
   end Row_Y;

   function Marker_X return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      return Editor.Layout.Gutter_Marker_X (Layout) + Editor.Layout.Gutter_Marker_Width / 2;
   end Marker_X;

   function Line_Number_X return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Lines  : constant Natural := 3;
      Right  : constant Natural := Natural (Editor.Layout.Gutter_Right (Layout, Lines));
      X      : constant Natural :=
        Editor.Layout.Gutter_Fold_X (Layout) + Editor.Layout.Gutter_Fold_Width;
   begin
      if X < Right then
         return X;
      else
         return Right - 1;
      end if;
   end Line_Number_X;

   procedure Prepare_Text
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
   end Prepare_Text;

   procedure Click
     (X : Natural;
      Y : Natural)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Y;
      Editor.Input_Bridge.Handle (Cmd);
   end Click;

   procedure Hover
     (X : Natural;
      Y : Natural)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Pointer_Hover;
      Cmd.Click_X := X;
      Cmd.Click_Y := Y;
      Editor.Input_Bridge.Handle (Cmd);
   end Hover;

   function Count_Rects_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Rects_On_Layer;

   function First_Rect_On_Layer_Matches_Color
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Color  : Editor.Theme.Color_RGB) return Boolean
   is
   begin
      for I in 0 .. Packet.Rect_Count - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            return abs (Float (Packet.Rects (Natural (I)).R) - Color.R) < 0.0001
              and then abs (Float (Packet.Rects (Natural (I)).G) - Color.G) < 0.0001
              and then abs (Float (Packet.Rects (Natural (I)).B) - Color.B) < 0.0001;
         end if;
      end loop;

      return False;
   end First_Rect_On_Layer_Matches_Color;

   function Count_Glyphs_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Glyphs_On_Layer;

   function Glyph_X_On_Layer
     (Packet  : Editor.Render_Packet.Render_Packet;
      Layer   : Editor.Render_Layers.Render_Layer;
      Ordinal : Natural) return C_float
   is
      Seen : Natural := 0;
   begin
      for I in 0 .. Packet.Glyph_Count - 1 loop
         if Packet.Glyphs (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            if Seen = Ordinal then
               return Packet.Glyphs (Natural (I)).X;
            end if;

            Seen := Seen + 1;
         end if;
      end loop;

      return C_float (-1.0);
   end Glyph_X_On_Layer;

   procedure Test_Dominant_Marker_Priority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Gutter_Marker_State;
      Found : Boolean := False;
      Kind  : Gutter_Marker_Kind;
   begin
      Add_Marker (State, 10, Dirty_Line_Marker);
      Add_Marker (State, 10, Bookmark_Marker);
      Add_Marker (State, 10, Diagnostic_Warning_Marker);
      Add_Marker (State, 10, Diagnostic_Error_Marker);

      Kind := Dominant_Marker_For_Row (State, 10, Found);

      Assert (Found, "Expected dominant marker on row 10");
      Assert
        (Kind = Diagnostic_Error_Marker,
         "Diagnostic error marker must dominate warning/bookmark/dirty markers");
   end Test_Dominant_Marker_Priority;

   procedure Test_Diagnostic_Warning_Dominates_Bookmark_And_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Gutter_Marker_State;
      Found : Boolean := False;
      Kind  : Gutter_Marker_Kind;
   begin
      Add_Marker (State, 4, Dirty_Line_Marker);
      Add_Marker (State, 4, Bookmark_Marker);
      Add_Marker (State, 4, Diagnostic_Warning_Marker);

      Kind := Dominant_Marker_For_Row (State, 4, Found);

      Assert (Found, "Expected dominant marker on row 4");
      Assert
        (Kind = Diagnostic_Warning_Marker,
         "Diagnostic warning marker must dominate bookmark and dirty markers");
   end Test_Diagnostic_Warning_Dominates_Bookmark_And_Dirty;

   procedure Test_Bookmark_Toggle_Adds_And_Removes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Gutter_Marker_State;
   begin
      Toggle_Bookmark (State, 7);
      Assert
        (Has_Marker (State, 7, Bookmark_Marker),
         "Bookmark toggle should add bookmark marker");

      Toggle_Bookmark (State, 7);
      Assert
        (not Has_Marker (State, 7, Bookmark_Marker),
         "Second bookmark toggle should remove bookmark marker");
   end Test_Bookmark_Toggle_Adds_And_Removes;

   procedure Test_Marker_Zone_Hit_Test
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout  : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Folding : Editor.Folding.Folding_State;
      Hit     : Editor.Gutter.Gutter_Hit_Result;
   begin
      Hit := Editor.Gutter.Hit_Test_Result
        (X               => Marker_X,
         Y               => Row_Y (1),
         Layout          => Layout,
         Line_Count      => 3,
         Viewport_Height => 200,
         Scroll_Y        => 0,
         Folding         => Folding);

      Assert
        (Editor.Gutter.Hit_Test
           (X => Marker_X,
            Y => Row_Y (0),
            Layout => Layout,
            Line_Count => 3,
            Viewport_Height => 200) = Editor.Gutter.Marker_Zone,
         "Marker X coordinate must hit marker zone");

      Assert
        (Editor.Gutter.Hit_Test
           (X => Line_Number_X,
            Y => Row_Y (0),
            Layout => Layout,
            Line_Count => 3,
            Viewport_Height => 200) = Editor.Gutter.Line_Number_Zone,
         "Line-number zone must remain distinct from marker zone");

      Assert
        (Hit.Zone = Editor.Gutter.Marker_Zone and then Hit.Row = 1,
         "Gutter hit result must include both marker zone and document row");
   end Test_Marker_Zone_Hit_Test;

   procedure Test_Marker_Click_Does_Not_Select_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text;
      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Caret_Count = 1 and then Natural (Snap.Caret_Pos (1)) = 0,
         "Marker-zone click must not move the caret");

      Assert
        (Snap.Selection_Count = 0,
         "Marker-zone click must not start line selection");

      Assert
        (Has_Marker (Snap.Gutter_Markers, 1, Bookmark_Marker),
         "Marker-zone click should toggle the row bookmark marker");
   end Test_Marker_Click_Does_Not_Select_Line;

   procedure Test_Marker_Click_Toggles_Existing_Bookmark_Off
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text;

      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Has_Marker (Snap.Gutter_Markers, 1, Bookmark_Marker),
         "First marker-zone click should add the row bookmark marker");

      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (not Has_Marker (Snap.Gutter_Markers, 1, Bookmark_Marker),
         "Second marker-zone click should remove the row bookmark marker");

      Assert
        (Snap.Caret_Count = 1 and then Natural (Snap.Caret_Pos (1)) = 0,
         "Bookmark removal through marker-zone click must not move the caret");

      Assert
        (Snap.Selection_Count = 0,
         "Bookmark removal through marker-zone click must not start selection");

      Assert
        (not Snap.Gutter_Marker_Hover.Active,
         "Removing the last marker on a row must clear marker hover state");
   end Test_Marker_Click_Toggles_Existing_Bookmark_Off;

   procedure Test_Marker_On_Visible_Row_Emits_Rect
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 0, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Count_Rects_On_Layer (Packet, Editor.Render_Layers.Gutter_Marker_Layer) > 0,
         "Visible row marker must emit a gutter marker rectangle");
   end Test_Marker_On_Visible_Row_Emits_Rect;

   procedure Test_Diagnostic_Error_Marker_Derived_From_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Found  : Boolean := False;
      Kind   : Gutter_Marker_Kind;
      Target : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");

      Add_Marker (S.Gutter_Markers, 1, Dirty_Line_Marker);
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Add_Marker (S.Gutter_Markers, 1, Diagnostic_Warning_Marker);

      Target := Editor.State.Line_Start (S, 1);
      Editor.State.Add_Diagnostic
        (S,
         Start_Index => Target,
         End_Index   => Editor.State.Line_End (S, 1),
         Severity    => Editor.Diagnostics.Error);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Kind := Dominant_Marker_For_Row (Snap.Gutter_Markers, 1, Found);

      Assert (Found, "Expected derived diagnostic marker on row 1");
      Assert
        (Kind = Diagnostic_Error_Marker,
         "Derived diagnostic error marker must dominate warning/bookmark/dirty markers");
   end Test_Diagnostic_Error_Marker_Derived_From_Diagnostics;

   procedure Test_Hidden_Folded_Row_Marker_Is_Not_Emitted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Folding.Add_Fold (S.Folding, 0, 1);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 0);
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Count_Rects_On_Layer (Packet, Editor.Render_Layers.Gutter_Marker_Layer) = 0,
         "Marker on hidden folded row must not emit an individual marker rectangle");
   end Test_Hidden_Folded_Row_Marker_Is_Not_Emitted;

   procedure Test_Marker_Presence_Does_Not_Move_Line_Number_Glyphs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Without     : Editor.Render_Packet.Render_Packet;
      With_Marker : Editor.Render_Packet.Render_Packet;
      Without_Count : Natural := 0;
      With_Count    : Natural := 0;
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Origin_Before : constant Natural := Editor.Layout.Text_Origin_X (Layout, 3);
      Origin_After  : constant Natural := Editor.Layout.Text_Origin_X (Layout, 3);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Without);

      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (With_Marker);

      Without_Count := Count_Glyphs_On_Layer
        (Without, Editor.Render_Layers.Gutter_Text_Layer);
      With_Count := Count_Glyphs_On_Layer
        (With_Marker, Editor.Render_Layers.Gutter_Text_Layer);

      Assert
        (Without_Count = With_Count,
         "Adding a gutter marker must not change the line-number glyph count");
      Assert
        (Origin_Before = Origin_After,
         "Adding a gutter marker must not change the layout-derived text origin");

      for N in 0 .. Without_Count - 1 loop
         Assert
           (Glyph_X_On_Layer
              (Without, Editor.Render_Layers.Gutter_Text_Layer, N)
            = Glyph_X_On_Layer
              (With_Marker, Editor.Render_Layers.Gutter_Text_Layer, N),
            "Adding a gutter marker must not move line-number glyph X positions");
      end loop;
   end Test_Marker_Presence_Does_Not_Move_Line_Number_Glyphs;

   procedure Test_Marker_Layer_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Gutter_Background_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Gutter_Marker_Layer),
         "Gutter marker layer must be after gutter background");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Gutter_Marker_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Text_Layer),
         "Gutter marker layer must be before text");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Gutter_Marker_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Gutter_Marker_Hover_Layer),
         "Gutter marker hover layer must be after base gutter markers");
      Assert
        (Editor.Render_Layers.Order (Editor.Render_Layers.Gutter_Marker_Hover_Layer)
         < Editor.Render_Layers.Order (Editor.Render_Layers.Text_Layer),
         "Gutter marker hover layer must be before text");
   end Test_Marker_Layer_Order;

   procedure Test_Marker_Action_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Action_For_Marker (Bookmark_Marker) = Toggle_Bookmark_Action,
         "Bookmark marker must map to bookmark toggle action");
      Assert
        (Action_For_Marker (Diagnostic_Error_Marker) = Select_Diagnostic_Action,
         "Diagnostic error marker must map to diagnostic selection action");
      Assert
        (Action_For_Marker (Diagnostic_Warning_Marker) = Select_Diagnostic_Action,
         "Diagnostic warning marker must map to diagnostic selection action");
      Assert
        (Action_For_Marker (Dirty_Line_Marker) = Acknowledge_Dirty_Line_Action,
         "Dirty-line marker must map to dirty-line acknowledgement action");
      Assert
        (Action_For_Marker (Added_Line_Marker) = Acknowledge_Dirty_Line_Action,
         "Added-line marker must map to dirty-line acknowledgement action");
      Assert
        (Action_For_Marker (Modified_Line_Marker) = Acknowledge_Dirty_Line_Action,
         "Modified-line marker must map to dirty-line acknowledgement action");
   end Test_Marker_Action_Mapping;

   procedure Test_Hover_State_Set_On_Marker_Zone_Mouse_Move
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Hover (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Gutter_Marker_Hover.Active,
         "Marker-zone hover over a marked row must activate marker hover state");
      Assert
        (Snap.Gutter_Marker_Hover.Row = 1,
         "Marker hover must record the hovered document row");
      Assert
        (Snap.Gutter_Marker_Hover.Kind = Bookmark_Marker,
         "Marker hover must record the dominant marker kind");
      Assert
        (Snap.Caret_Count = 1 and then Natural (Snap.Caret_Pos (1)) = 0,
         "Marker hover must not move the caret");
      Assert
        (Snap.Selection_Count = 0,
         "Marker hover must not start selection");
   end Test_Hover_State_Set_On_Marker_Zone_Mouse_Move;

   procedure Test_Hover_State_Cleared_Outside_Marker_Zone
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Hover (Marker_X, Row_Y (1));
      Hover (Line_Number_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (not Snap.Gutter_Marker_Hover.Active,
         "Hover outside marker zone must clear marker hover state");
   end Test_Hover_State_Cleared_Outside_Marker_Zone;

   procedure Test_Hover_State_Cleared_On_Row_Without_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 0, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Hover (Marker_X, Row_Y (0));
      Hover (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (not Snap.Gutter_Marker_Hover.Active,
         "Marker-zone hover on an unmarked row must clear marker hover state");
   end Test_Hover_State_Cleared_On_Row_Without_Marker;

   procedure Test_Hover_Render_Emits_Hover_Rect
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Hover (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Count_Rects_On_Layer (Packet, Editor.Render_Layers.Gutter_Marker_Hover_Layer) > 0,
         "Hovered marker must emit a marker-hover rectangle");
   end Test_Hover_Render_Emits_Hover_Rect;

   procedure Test_Hover_Render_Inactive_Emits_No_Hover_Rect
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Packet);

      Assert
        (Count_Rects_On_Layer (Packet, Editor.Render_Layers.Gutter_Marker_Hover_Layer) = 0,
         "Inactive marker hover must not emit marker-hover rectangles");
   end Test_Hover_Render_Inactive_Emits_No_Hover_Rect;

   procedure Test_Diagnostic_Marker_Click_Jumps_To_Diagnostic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Target : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Target := Editor.State.Line_Start (S, 1);
      Editor.State.Add_Diagnostic
        (S,
         Start_Index => Target,
         End_Index   => Editor.State.Line_End (S, 1),
         Severity    => Editor.Diagnostics.Error);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Caret_Count = 1 and then Snap.Caret_Pos (1) = Target,
         "Diagnostic marker click must jump to the diagnostic start");
      Assert
        (Snap.Selection_Count = 0,
         "Diagnostic marker click must not start line selection");
      Assert
        (not Has_Marker (Snap.Gutter_Markers, 1, Bookmark_Marker),
         "Diagnostic marker click must not add a bookmark marker");
      Assert
        (Snap.Gutter_Marker_Hover.Active
         and then Snap.Gutter_Marker_Hover.Row = 1
         and then Snap.Gutter_Marker_Hover.Kind = Diagnostic_Error_Marker,
         "Diagnostic marker click should leave hover state on the diagnostic marker");
   end Test_Diagnostic_Marker_Click_Jumps_To_Diagnostic;

   procedure Test_Dirty_Marker_Click_Does_Not_Move_Caret_Or_Select
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 1, Dirty_Line_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Caret_Count = 1 and then Natural (Snap.Caret_Pos (1)) = 0,
         "Dirty marker click must not move the caret");
      Assert
        (Snap.Selection_Count = 0,
         "Dirty marker click must not start line selection");
      Assert
        (Has_Marker (Snap.Gutter_Markers, 1, Dirty_Line_Marker),
         "Dirty marker no-op action must leave dirty marker state intact");
      Assert
        (Snap.Gutter_Marker_Hover.Active
         and then Snap.Gutter_Marker_Hover.Row = 1
         and then Snap.Gutter_Marker_Hover.Kind = Dirty_Line_Marker,
         "Dirty marker click should leave hover state on the dirty marker");
   end Test_Dirty_Marker_Click_Does_Not_Move_Caret_Or_Select;

   procedure Test_Derived_Modified_Marker_Click_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Set_Baseline_Text
        (S.Dirty_Lines, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Recompute
        (S.Dirty_Lines, "a" & ASCII.LF & "changed");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Caret_Count = 1 and then Natural (Snap.Caret_Pos (1)) = 0,
         "derived modified marker click must not move the caret");
      Assert (Snap.Selection_Count = 0,
              "derived modified marker click must not start line selection");
      Assert (Has_Marker (Snap.Gutter_Markers, 1, Modified_Line_Marker),
              "derived modified marker click must not clear dirty-line projection");
      Assert (not Has_Marker (Snap.Gutter_Markers, 1, Bookmark_Marker),
              "derived modified marker click must not toggle a bookmark");
      Assert
        (Snap.Gutter_Marker_Hover.Active
         and then Snap.Gutter_Marker_Hover.Row = 1
         and then Snap.Gutter_Marker_Hover.Kind = Modified_Line_Marker,
         "derived modified marker click should leave hover on modified marker");
   end Test_Derived_Modified_Marker_Click_Is_No_Op;

   procedure Test_Derived_Added_Marker_Click_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Set_Baseline_Text (S.Dirty_Lines, "a");
      Editor.Dirty_Lines.Recompute (S.Dirty_Lines, "a" & ASCII.LF & "b");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Click (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Caret_Count = 1 and then Natural (Snap.Caret_Pos (1)) = 0,
         "derived added marker click must not move the caret");
      Assert (Snap.Selection_Count = 0,
              "derived added marker click must not start line selection");
      Assert (Has_Marker (Snap.Gutter_Markers, 1, Added_Line_Marker),
              "derived added marker click must not clear dirty-line projection");
      Assert (not Has_Marker (Snap.Gutter_Markers, 1, Bookmark_Marker),
              "derived added marker click must not toggle a bookmark");
      Assert
        (Snap.Gutter_Marker_Hover.Active
         and then Snap.Gutter_Marker_Hover.Row = 1
         and then Snap.Gutter_Marker_Hover.Kind = Added_Line_Marker,
         "derived added marker click should leave hover on added marker");
   end Test_Derived_Added_Marker_Click_Is_No_Op;

   procedure Test_Hover_Does_Not_Move_Line_Number_Glyphs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Without_Hover : Editor.Render_Packet.Render_Packet;
      With_Hover    : Editor.Render_Packet.Render_Packet;
      Without_Count : Natural := 0;
      With_Count    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Add_Marker (S.Gutter_Markers, 1, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Without_Hover);
      Hover (Marker_X, Row_Y (1));
      Editor.Input_Bridge.Build_Render_Packet (With_Hover);

      Without_Count := Count_Glyphs_On_Layer
        (Without_Hover, Editor.Render_Layers.Gutter_Text_Layer);
      With_Count := Count_Glyphs_On_Layer
        (With_Hover, Editor.Render_Layers.Gutter_Text_Layer);

      Assert
        (Without_Count = With_Count,
         "Marker hover must not change line-number glyph count");

      for N in 0 .. Without_Count - 1 loop
         Assert
           (Glyph_X_On_Layer
              (Without_Hover, Editor.Render_Layers.Gutter_Text_Layer, N)
            = Glyph_X_On_Layer
              (With_Hover, Editor.Render_Layers.Gutter_Text_Layer, N),
            "Marker hover must not move line-number glyph X positions");
      end loop;
   end Test_Hover_Does_Not_Move_Line_Number_Glyphs;


   procedure Test_Bookmark_Count_And_Order_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Gutter_Marker_State;
      Found : Boolean := False;
   begin
      Assert (Bookmark_Count (State) = 0,
              "empty marker state should have zero bookmarks");
      Assert (not Has_Bookmarks (State),
              "empty marker state should report no bookmarks");

      Add_Marker (State, 20, Bookmark_Marker);
      Add_Marker (State, 5, Bookmark_Marker);
      Add_Marker (State, 10, Bookmark_Marker);
      Add_Marker (State, 7, Dirty_Line_Marker);
      Add_Marker (State, 8, Diagnostic_Error_Marker);

      Assert (Bookmark_Count (State) = 3,
              "bookmark count should include only bookmark rows");
      Assert (Has_Bookmarks (State),
              "state with at least one bookmark should report bookmarks");
      Assert (First_Bookmark (State, Found) = 5 and then Found,
              "first bookmark should be the lowest bookmarked row");
      Assert (Last_Bookmark (State, Found) = 20 and then Found,
              "last bookmark should be the highest bookmarked row");
      Assert (Next_Bookmark_After (State, 5, True, Found) = 10 and then Found,
              "next bookmark should use ascending row order, not insertion order");
      Assert (Next_Bookmark_After (State, 20, True, Found) = 5 and then Found,
              "next bookmark should wrap to first bookmark");
      declare
         Ignored : constant Natural := Next_Bookmark_After (State, 20, False, Found);
      begin
         pragma Unreferenced (Ignored);
         Assert (not Found,
                 "next bookmark without wrap after the last bookmark should not be found");
      end;
      Assert (Previous_Bookmark_Before (State, 20, True, Found) = 10 and then Found,
              "previous bookmark should use descending row order");
      Assert (Previous_Bookmark_Before (State, 5, True, Found) = 20 and then Found,
              "previous bookmark should wrap to last bookmark");
      declare
         Ignored : constant Natural := Previous_Bookmark_Before (State, 5, False, Found);
      begin
         pragma Unreferenced (Ignored);
         Assert (not Found,
                 "previous bookmark without wrap before the first bookmark should not be found");
      end;
   end Test_Bookmark_Count_And_Order_Helpers;

   procedure Test_Clear_Bookmarks_Preserves_Other_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Gutter_Marker_State;
      Found : Boolean := False;
      Kind  : Gutter_Marker_Kind;
   begin
      Add_Marker (State, 1, Bookmark_Marker);
      Add_Marker (State, 1, Dirty_Line_Marker);
      Add_Marker (State, 2, Bookmark_Marker);
      Add_Marker (State, 2, Diagnostic_Error_Marker);
      Add_Marker (State, 3, Diagnostic_Warning_Marker);

      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Bookmark_Marker,
              "bookmark should dominate dirty-line marker before clear");
      Kind := Dominant_Marker_For_Row (State, 2, Found);
      Assert (Found and then Kind = Diagnostic_Error_Marker,
              "diagnostic error should dominate bookmark before clear");

      Clear_Bookmarks (State);

      Assert (Bookmark_Count (State) = 0,
              "clear bookmarks should remove every bookmark");
      Assert (Has_Marker (State, 1, Dirty_Line_Marker),
              "clear bookmarks must preserve dirty-line marker");
      Assert (Has_Marker (State, 2, Diagnostic_Error_Marker),
              "clear bookmarks must preserve diagnostic marker");
      Assert (Has_Marker (State, 3, Diagnostic_Warning_Marker),
              "clear bookmarks must preserve unrelated diagnostic marker");

      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Dirty_Line_Marker,
              "dominant marker should fall back to dirty-line after bookmark clear");
      Kind := Dominant_Marker_For_Row (State, 2, Found);
      Assert (Found and then Kind = Diagnostic_Error_Marker,
              "diagnostic dominance should remain after bookmark clear");
   end Test_Clear_Bookmarks_Preserves_Other_Markers;


   procedure Test_Diff_Style_Marker_Priority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Gutter_Marker_State;
      Found : Boolean := False;
      Kind  : Gutter_Marker_Kind := Dirty_Line_Marker;
   begin
      Add_Marker (State, 1, Added_Line_Marker);
      Add_Marker (State, 1, Diagnostic_Error_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Diagnostic_Error_Marker,
              "diagnostic error must dominate added-line marker");

      Clear (State);
      Add_Marker (State, 1, Modified_Line_Marker);
      Add_Marker (State, 1, Diagnostic_Warning_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Diagnostic_Warning_Marker,
              "diagnostic warning must dominate modified-line marker");

      Clear (State);
      Add_Marker (State, 1, Added_Line_Marker);
      Add_Marker (State, 1, Bookmark_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Bookmark_Marker,
              "bookmark must dominate added-line marker");

      Clear (State);
      Add_Marker (State, 1, Modified_Line_Marker);
      Add_Marker (State, 1, Bookmark_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Bookmark_Marker,
              "bookmark must dominate modified-line marker");

      Clear (State);
      Add_Marker (State, 1, Dirty_Line_Marker);
      Add_Marker (State, 1, Added_Line_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Added_Line_Marker,
              "added-line marker must dominate previous dirty marker");

      Clear (State);
      Add_Marker (State, 1, Dirty_Line_Marker);
      Add_Marker (State, 1, Modified_Line_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Modified_Line_Marker,
              "modified-line marker must dominate previous dirty marker");

      Clear (State);
      Add_Marker (State, 1, Modified_Line_Marker);
      Add_Marker (State, 1, Added_Line_Marker);
      Kind := Dominant_Marker_For_Row (State, 1, Found);
      Assert (Found and then Kind = Added_Line_Marker,
              "added vs modified tie must resolve deterministically to added");
   end Test_Diff_Style_Marker_Priority;

   procedure Test_Added_And_Modified_Render_Differently
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Added_Packet   : Editor.Render_Packet.Render_Packet;
      Modified_Packet : Editor.Render_Packet.Render_Packet;
      Added_H        : C_float := C_float (-1.0);
      Modified_H     : C_float := C_float (-1.0);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 0, Added_Line_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
      Editor.Input_Bridge.Build_Render_Packet (Added_Packet);

      Clear (S.Gutter_Markers);
      Add_Marker (S.Gutter_Markers, 0, Modified_Line_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Modified_Packet);

      Assert
        (Count_Rects_On_Layer (Added_Packet, Editor.Render_Layers.Gutter_Marker_Layer) > 0,
         "added-line marker must emit a gutter marker rect");
      Assert
        (Count_Rects_On_Layer (Modified_Packet, Editor.Render_Layers.Gutter_Marker_Layer) > 0,
         "modified-line marker must emit a gutter marker rect");

      for I in 0 .. Added_Packet.Rect_Count - 1 loop
         if Added_Packet.Rects (Natural (I)).Layer =
              Editor.Render_Layers.To_C (Editor.Render_Layers.Gutter_Marker_Layer)
         then
            Added_H := Added_Packet.Rects (Natural (I)).H;
            exit;
         end if;
      end loop;

      for I in 0 .. Modified_Packet.Rect_Count - 1 loop
         if Modified_Packet.Rects (Natural (I)).Layer =
              Editor.Render_Layers.To_C (Editor.Render_Layers.Gutter_Marker_Layer)
         then
            Modified_H := Modified_Packet.Rects (Natural (I)).H;
            exit;
         end if;
      end loop;

      Assert (Float (Added_H) > Float (Modified_H),
              "added marker should be full-height while modified marker is shorter");
   end Test_Added_And_Modified_Render_Differently;

   procedure Test_Render_Uses_Diff_Theme_Colours
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Added_Packet    : Editor.Render_Packet.Render_Packet;
      Modified_Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 0, Added_Line_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
      Editor.Input_Bridge.Build_Render_Packet (Added_Packet);

      Clear (S.Gutter_Markers);
      Add_Marker (S.Gutter_Markers, 0, Modified_Line_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Modified_Packet);

      Assert
        (First_Rect_On_Layer_Matches_Color
           (Added_Packet, Editor.Render_Layers.Gutter_Marker_Layer,
            Editor.Theme.Gutter_Added_Line),
         "added-line marker must use the added-line theme colour path");
      Assert
        (First_Rect_On_Layer_Matches_Color
           (Modified_Packet, Editor.Render_Layers.Gutter_Marker_Layer,
            Editor.Theme.Gutter_Modified_Line),
         "modified-line marker must use the modified-line theme colour path");
   end Test_Render_Uses_Diff_Theme_Colours;

   procedure Test_Render_Dominance_Hides_Dirty_Visual
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S                 : Editor.State.State_Type;
      Diagnostic_Packet : Editor.Render_Packet.Render_Packet;
      Bookmark_Packet   : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Add_Marker (S.Gutter_Markers, 0, Added_Line_Marker);
      Add_Marker (S.Gutter_Markers, 0, Diagnostic_Error_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
      Editor.Input_Bridge.Build_Render_Packet (Diagnostic_Packet);

      Clear (S.Gutter_Markers);
      Add_Marker (S.Gutter_Markers, 0, Modified_Line_Marker);
      Add_Marker (S.Gutter_Markers, 0, Bookmark_Marker);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Bookmark_Packet);

      Assert
        (First_Rect_On_Layer_Matches_Color
           (Diagnostic_Packet, Editor.Render_Layers.Gutter_Marker_Layer,
            Editor.Theme.Gutter_Diagnostic_Error),
         "diagnostic visual must dominate an added-line dirty visual on the same row");
      Assert
        (First_Rect_On_Layer_Matches_Color
           (Bookmark_Packet, Editor.Render_Layers.Gutter_Marker_Layer,
            Editor.Theme.Gutter_Bookmark),
         "bookmark visual must dominate a modified-line dirty visual on the same row");
   end Test_Render_Dominance_Hides_Dirty_Visual;

   procedure Test_Diff_Dirty_Markers_Derived_From_Dirty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Set_Baseline_Text
        (S.Dirty_Lines, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Recompute
        (S.Dirty_Lines, "a" & ASCII.LF & "changed");
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Has_Marker (Snap.Gutter_Markers, 1, Modified_Line_Marker),
              "modified dirty row should derive a modified-line marker in the render snapshot");
      Assert (not Has_Marker (S.Gutter_Markers, 1, Modified_Line_Marker),
              "derived modified-line marker should not be stored in explicit marker state");
   end Test_Diff_Dirty_Markers_Derived_From_Dirty_State;

   procedure Test_Added_Line_Marker_Derived_From_Dirty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Set_Baseline_Text (S.Dirty_Lines, "a");
      Editor.Dirty_Lines.Recompute (S.Dirty_Lines, "a" & ASCII.LF & "b");
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Has_Marker (Snap.Gutter_Markers, 1, Added_Line_Marker),
              "added dirty row should derive an added-line marker");
      Assert (not Has_Marker (Snap.Gutter_Markers, 1, Dirty_Line_Marker),
              "added dirty row should not fall back to previous dirty marker");
   end Test_Added_Line_Marker_Derived_From_Dirty_State;

   procedure Test_Dirty_Line_Derivation_Skips_Hidden_Folded_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Folding.Add_Fold (S.Folding, 0, 2);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 0);
      Editor.Dirty_Lines.Set_Baseline_Text
        (S.Dirty_Lines, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Dirty_Lines.Recompute
        (S.Dirty_Lines, "a" & ASCII.LF & "changed" & ASCII.LF & "c");
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (not Has_Marker (Snap.Gutter_Markers, 1, Modified_Line_Marker),
              "modified marker for hidden folded row should not be emitted");
   end Test_Dirty_Line_Derivation_Skips_Hidden_Folded_Row;

   procedure Test_Derived_Dirty_Line_Below_Bookmark_In_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Snap  : Editor.Render_Model.Render_Snapshot;
      Found : Boolean := False;
      Kind  : Gutter_Marker_Kind := Dirty_Line_Marker;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b");
      Toggle_Bookmark (S.Gutter_Markers, 1);
      Editor.Dirty_Lines.Set_Baseline_Text
        (S.Dirty_Lines, "a" & ASCII.LF & "b");
      Editor.Dirty_Lines.Recompute
        (S.Dirty_Lines, "a" & ASCII.LF & "changed");
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Kind := Dominant_Marker_For_Row (Snap.Gutter_Markers, 1, Found);

      Assert (Found and then Kind = Bookmark_Marker,
              "bookmark should dominate derived dirty-line marker in snapshot");
      Assert (Has_Marker (Snap.Gutter_Markers, 1, Modified_Line_Marker),
              "derived modified marker should still be present below bookmark");
   end Test_Derived_Dirty_Line_Below_Bookmark_In_Snapshot;

   procedure Test_Reset_Baseline_Removes_Derived_Dirty_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a");
      Editor.Dirty_Lines.Set_Baseline_Text (S.Dirty_Lines, "a");
      Editor.Dirty_Lines.Recompute (S.Dirty_Lines, "changed");
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Has_Marker (Snap.Gutter_Markers, 0, Modified_Line_Marker),
              "modified marker should be derived before baseline reset");

      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (not Has_Marker (Snap.Gutter_Markers, 0, Modified_Line_Marker),
              "clean baseline should stop deriving modified-line markers");
   end Test_Reset_Baseline_Removes_Derived_Dirty_Marker;

   overriding procedure Register_Tests
     (T : in out Gutter_Markers_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_Action_Mapping'Access,
         "Marker Action Mapping");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dominant_Marker_Priority'Access,
         "Dominant Marker Priority");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Toggle_Adds_And_Removes'Access,
         "Bookmark Toggle Adds And Removes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Count_And_Order_Helpers'Access,
         "bookmark count and ordered lookup helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Bookmarks_Preserves_Other_Markers'Access,
         "clear bookmarks preserves other markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Warning_Dominates_Bookmark_And_Dirty'Access,
         "Diagnostic Warning Dominates Bookmark And Dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_Zone_Hit_Test'Access,
         "Marker Zone Hit Test");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_Click_Does_Not_Select_Line'Access,
         "Marker Click Does Not Select Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_Click_Toggles_Existing_Bookmark_Off'Access,
         "Marker Click Toggles Existing Bookmark Off");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_On_Visible_Row_Emits_Rect'Access,
         "Visible Row Marker Emits Rect");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Error_Marker_Derived_From_Diagnostics'Access,
         "Diagnostic Error Marker Derived From Diagnostics");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hidden_Folded_Row_Marker_Is_Not_Emitted'Access,
         "Hidden Folded Row Marker Not Emitted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diff_Style_Marker_Priority'Access,
         "diff-style dirty marker priority");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Added_And_Modified_Render_Differently'Access,
         "added and modified markers render differently");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Uses_Diff_Theme_Colours'Access,
         "added and modified markers use theme colours");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Dominance_Hides_Dirty_Visual'Access,
         "dominant marker hides dirty visual");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diff_Dirty_Markers_Derived_From_Dirty_State'Access,
         "modified-line marker derived from dirty state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Added_Line_Marker_Derived_From_Dirty_State'Access,
         "added-line marker derived from dirty state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Line_Derivation_Skips_Hidden_Folded_Row'Access,
         "dirty-line derivation skips hidden folded row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Derived_Dirty_Line_Below_Bookmark_In_Snapshot'Access,
         "derived dirty marker remains below bookmark");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reset_Baseline_Removes_Derived_Dirty_Marker'Access,
         "reset baseline removes derived dirty marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_Presence_Does_Not_Move_Line_Number_Glyphs'Access,
         "Marker Presence Does Not Move Line Number Glyphs");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marker_Layer_Order'Access,
         "Marker Layer Order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hover_State_Set_On_Marker_Zone_Mouse_Move'Access,
         "Hover State Set On Marker Zone Mouse Move");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hover_State_Cleared_Outside_Marker_Zone'Access,
         "Hover State Cleared Outside Marker Zone");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hover_State_Cleared_On_Row_Without_Marker'Access,
         "Hover State Cleared On Row Without Marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hover_Render_Emits_Hover_Rect'Access,
         "Hover Render Emits Hover Rect");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hover_Render_Inactive_Emits_No_Hover_Rect'Access,
         "Inactive Hover Emits No Hover Rect");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Marker_Click_Jumps_To_Diagnostic'Access,
         "Diagnostic Marker Click Jumps To Diagnostic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Marker_Click_Does_Not_Move_Caret_Or_Select'Access,
         "Dirty Marker Click Does Not Move Caret Or Select");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Derived_Modified_Marker_Click_Is_No_Op'Access,
         "derived modified marker click is no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Derived_Added_Marker_Click_Is_No_Op'Access,
         "derived added marker click is no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hover_Does_Not_Move_Line_Number_Glyphs'Access,
         "Hover Does Not Move Line Number Glyphs");
   end Register_Tests;

end Editor.Gutter_Markers.Tests;
