with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C;
with Editor.Commands;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Navigation;
with Editor.Cursors;
with Editor.Render_Layers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Scrollbars;
with Editor.State;
with Editor.View;

package body Editor.Folding.Tests is

   use type Interfaces.C.int;

   overriding function Name
     (T : Folding_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Folding");
   end Name;

   procedure Prepare_Folded_State
     (Collapsed : Boolean := True)
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c" & ASCII.LF & "d");
      Editor.Folding.Add_Fold (S.Folding, 1, 2);
      if Collapsed then
         Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      end if;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 160);
      Editor.Scrollbars.Reset;
   end Prepare_Folded_State;

   function Rect_Count_On_Layer
     (Packet : Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Natural (Packet.Rect_Count) - 1 loop
         if Packet.Rects (Natural (I)).Layer = Editor.Render_Layers.To_C (Layer) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Rect_Count_On_Layer;

   procedure Test_Collapsed_Fold_Hides_Interior
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Folding.Folding_State;
   begin
      Editor.Folding.Add_Fold (State, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (State, 1);
      Assert (not Editor.Folding.Is_Row_Hidden (State, 1),
              "Fold start row must remain visible");
      Assert (Editor.Folding.Is_Row_Hidden (State, 2),
              "Collapsed fold must hide interior row");
      Assert (Editor.Folding.Is_Row_Hidden (State, 3),
              "Collapsed fold must hide inclusive end row");
   end Test_Collapsed_Fold_Hides_Interior;

   procedure Test_Visible_Row_Count_Changes_After_Collapse
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Folding.Folding_State;
   begin
      Editor.Folding.Add_Fold (State, 1, 3);
      Assert (Editor.Folding.Visible_Row_Count (State, 5) = 5,
              "Expanded fold must not change visible row count");
      Editor.Folding.Toggle_Fold_At_Row (State, 1);
      Assert (Editor.Folding.Visible_Row_Count (State, 5) = 3,
              "Collapsed 1..3 fold in five rows must expose three rows");
   end Test_Visible_Row_Count_Changes_After_Collapse;

   procedure Test_Visible_Row_Maps_After_Folded_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Folding.Folding_State;
      Found : Boolean := False;
      Visible : Natural := 0;
   begin
      Editor.Folding.Add_Fold (State, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (State, 1);
      Assert (Editor.Folding.Visible_Row_To_Document_Row (State, 2) = 4,
              "Visible row after collapsed fold must map to the next document row");
      Visible := Editor.Folding.Document_Row_To_Visible_Row (State, 4, Found);
      Assert (Found and then Visible = 2,
              "Document row after collapsed fold must map back to visible row");
      Visible := Editor.Folding.Document_Row_To_Visible_Row (State, 2, Found);
      Assert ((not Found) and then Visible = 0,
              "Hidden document row must not have a visible-row mapping");
   end Test_Visible_Row_Maps_After_Folded_Range;

   procedure Test_Render_Model_Skips_Hidden_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Folded_State;
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Visible_Line_Count = 3,
              "Render snapshot visible line count must exclude folded interior rows");
      Assert (Snap.Visible_Visual_Count >= 3,
              "Render snapshot must expose visible rows");
      Assert (Snap.Visible_Visual_Rows (1).Logical_Row = 0,
              "First visible row must remain document row 0");
      Assert (Snap.Visible_Visual_Rows (2).Logical_Row = 1,
              "Fold start row must remain visible as document row 1");
      Assert (Snap.Visible_Visual_Rows (3).Logical_Row = 3,
              "Row after folded interior must keep its document row number");
   end Test_Render_Model_Skips_Hidden_Row;

   procedure Test_Render_Packet_Emits_Fold_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Folded_State;
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Rect_Count_On_Layer (Packet, Editor.Render_Layers.Fold_Marker_Layer) > 0,
         "Fold start row must emit a fold marker rectangle");
   end Test_Render_Packet_Emits_Fold_Marker;

   procedure Test_Fold_Marker_Click_Toggles_Before_Text_Hit_Test
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Cmd : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Prepare_Folded_State;
      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := Editor.Layout.Gutter_Fold_X (Layout) + Editor.Layout.Cell_W / 2;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + Editor.Layout.Cell_H;
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (not Editor.Folding.Is_Fold_Collapsed (Snap.Folding, 1),
              "Clicking fold marker must toggle fold state before caret placement");
   end Test_Fold_Marker_Click_Toggles_Before_Text_Hit_Test;


   procedure Test_Vertical_Navigation_Skips_Hidden_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Editor.Cursors.Cursor_Index := 0;
      Virtual_Column : Natural := 0;
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3");
      Editor.Folding.Add_Fold (S.Folding, 1, 2);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);

      Editor.Navigation.Vertical_Target_Info
        (S                => S,
         Old_Caret        => Editor.Cursors.Cursor_Index
                               (Editor.Navigation.Index_For_Line_Column (S, 1, 0)),
         Delta_Rows       => 1,
         Preferred_Column => 0,
         Target           => Target,
         Virtual_Column   => Virtual_Column);

      Editor.Navigation.Line_Column_For_Index (S, Natural (Target), Row, Col);
      Assert (Row = 3 and then Col = 0,
              "Moving down from a collapsed fold start must skip hidden rows");
      Assert (Virtual_Column = 0,
              "Fold-skipping vertical movement must not create a virtual column");
   end Test_Vertical_Navigation_Skips_Hidden_Rows;


   procedure Test_Horizontal_Scrollbar_Ignores_Hidden_Long_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Long_Line : constant String :=
        "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
        & "abcdefghijklmnopqrstuvwxyz";
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "x" & ASCII.LF & Long_Line & ASCII.LF & "y");
      Editor.Folding.Add_Fold (S.Folding, 0, 1);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (240, 400);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Rect_Count_On_Layer
           (Packet, Editor.Render_Layers.Scrollbar_Thumb_Layer) = 0,
         "Horizontal scrollbar must not be sized from a hidden folded row");
   end Test_Horizontal_Scrollbar_Ignores_Hidden_Long_Row;

   procedure Test_Minimap_Click_Uses_Document_Row_Then_Visible_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3"
            & ASCII.LF & "4");
      Editor.Folding.Add_Fold (S.Folding, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, Editor.Layout.Cell_H);
      Editor.Scrollbars.Reset;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Click_X := 760;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + Editor.Layout.Cell_H - 1;
      Editor.Input_Bridge.Handle (Cmd);

      Assert
        (Editor.View.Scroll_Y = 2,
         "Minimap click near document end must scroll to the visible row for document row 4");
   end Test_Minimap_Click_Uses_Document_Row_Then_Visible_Scroll;

   procedure Test_Scroll_Bounds_Use_Visible_Row_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3" & ASCII.LF & "4");
      Editor.Folding.Add_Fold (S.Folding, 1, 4);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, Editor.Layout.Cell_H * 2);
      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Editor.Folding.Visible_Row_Count (S.Folding, Editor.State.Line_Count (S)),
         Viewport_Rows  => 2,
         Desired_Scroll => 99);
      Assert (Editor.View.Scroll_Y = 0,
              "Collapsed document with two visible rows and two viewport rows must clamp vertical scroll to zero");
   end Test_Scroll_Bounds_Use_Visible_Row_Count;


   procedure Test_Expand_To_Reveal_Row_Expands_Only_Containing_Folds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      F : Editor.Folding.Folding_State;
   begin
      Editor.Folding.Add_Fold (F, 1, 4);
      Editor.Folding.Add_Fold (F, 6, 8);
      Editor.Folding.Toggle_Fold_At_Row (F, 1);
      Editor.Folding.Toggle_Fold_At_Row (F, 6);

      Editor.Folding.Expand_To_Reveal_Row (F, 3);

      Assert
        (not Editor.Folding.Is_Fold_Collapsed (F, 1),
         "Expand_To_Reveal_Row must expand the fold hiding the target row");
      Assert
        (Editor.Folding.Is_Fold_Collapsed (F, 6),
         "Expand_To_Reveal_Row must preserve unrelated collapsed folds");
      Assert
        (not Editor.Folding.Is_Row_Hidden (F, 3),
         "expanded target row must become visible");
   end Test_Expand_To_Reveal_Row_Expands_Only_Containing_Folds;

   overriding procedure Register_Tests
     (T : in out Folding_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Collapsed_Fold_Hides_Interior'Access,
         "Collapsed Fold Hides Interior");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Visible_Row_Count_Changes_After_Collapse'Access,
         "Visible Row Count Changes After Collapse");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Visible_Row_Maps_After_Folded_Range'Access,
         "Visible Row Maps After Folded Source_Span");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Model_Skips_Hidden_Row'Access,
         "Render Model Skips Hidden Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Emits_Fold_Marker'Access,
         "Render Packet Emits Fold Marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Fold_Marker_Click_Toggles_Before_Text_Hit_Test'Access,
         "Fold Marker Click Toggles Before Text Hit Test");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Vertical_Navigation_Skips_Hidden_Rows'Access,
         "Vertical Navigation Skips Hidden Rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scroll_Bounds_Use_Visible_Row_Count'Access,
         "Scroll Bounds Use Visible Row Count");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Horizontal_Scrollbar_Ignores_Hidden_Long_Row'Access,
         "Horizontal Scrollbar Ignores Hidden Long Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimap_Click_Uses_Document_Row_Then_Visible_Scroll'Access,
         "Minimap Click Uses Document Row Then Visible Scroll");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Expand_To_Reveal_Row_Expands_Only_Containing_Folds'Access,
         "Expand To Reveal Row Expands Containing Folds Only");

   end Register_Tests;

end Editor.Folding.Tests;
