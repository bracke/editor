with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Commands;
with Editor.Folding;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Navigation;
with Editor.Render_Model;
with Editor.Scrollbars;
with Editor.State;
with Editor.View;

package body Editor.Gutter.Tests is

   overriding function Name
     (T : Gutter_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Gutter");
   end Name;

   procedure Prepare_Text
     (Text : String := "a" & ASCII.LF & "bb" & ASCII.LF & "ccc" & ASCII.LF & "dddd")
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Text);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;
   end Prepare_Text;

   function Line_Number_X return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Lines  : constant Natural := 4;
      Right  : constant Natural :=
        Natural (Editor.Layout.Gutter_Right (Layout, Lines));
      X      : constant Natural :=
        Editor.Layout.Gutter_Fold_X (Layout) + Editor.Layout.Gutter_Fold_Width;
   begin
      if X < Right then
         return X;
      else
         return Right - 1;
      end if;
   end Line_Number_X;

   function Fold_Marker_X return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      return Editor.Layout.Gutter_Fold_X (Layout) + Editor.Layout.Gutter_Fold_Width / 2;
   end Fold_Marker_X;

   function Row_Y (Visible_Row : Natural) return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      return Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Visible_Row * Editor.Layout.Cell_H
        + Editor.Layout.Cell_H / 2;
   end Row_Y;

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

   procedure Drag
     (X : Natural;
      Y : Natural)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Drag_To_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Y;
      Editor.Input_Bridge.Handle (Cmd);
   end Drag;


   procedure Triple_Click
     (X : Natural;
      Y : Natural)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Select_Line_At_Point;
      Cmd.Click_X := X;
      Cmd.Click_Y := Y;
      Editor.Input_Bridge.Handle (Cmd);
   end Triple_Click;

   procedure Assert_Selection
     (Start_Index : Natural;
      End_Index   : Natural;
      Message     : String)
   is
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Selection_Count = 1, Message & ": expected exactly one selection");
      Assert
        (Natural (Snap.Sel_Start (1)) = Start_Index,
         Message & ": selection start mismatch");
      Assert
        (Natural (Snap.Sel_End (1)) = End_Index,
         Message & ": selection end mismatch");
   end Assert_Selection;

   procedure Test_Hit_Test_Outside_Gutter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Assert
        (Editor.Gutter.Hit_Test
           (X => Editor.Layout.Text_Origin_X (Layout, 10),
            Y => Row_Y (0),
            Layout => Layout,
            Line_Count => 10,
            Viewport_Height => 200) = Editor.Gutter.Outside_Gutter,
         "Text area X coordinate must be outside the gutter");
   end Test_Hit_Test_Outside_Gutter;

   procedure Test_Hit_Test_Line_Number_Zone
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Assert
        (Editor.Gutter.Hit_Test
           (X => Line_Number_X,
            Y => Row_Y (0),
            Layout => Layout,
            Line_Count => 4,
            Viewport_Height => 200) = Editor.Gutter.Line_Number_Zone,
         "X coordinate after fold-marker cell must hit line-number zone");
   end Test_Hit_Test_Line_Number_Zone;

   procedure Test_Hit_Test_Fold_Marker_Zone
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Assert
        (Editor.Gutter.Hit_Test
           (X => Fold_Marker_X,
            Y => Row_Y (0),
            Layout => Layout,
            Line_Count => 4,
            Viewport_Height => 200) = Editor.Gutter.Fold_Marker_Zone,
         "Fold marker cell must hit fold-marker zone before line-number zone");
   end Test_Hit_Test_Fold_Marker_Zone;

   procedure Test_Fold_Marker_Zone_Has_Priority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
   begin
      Test_Hit_Test_Fold_Marker_Zone (T);
   end Test_Fold_Marker_Zone_Has_Priority;

   procedure Test_Click_Line_Number_Selects_Full_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Prepare_Text;
      Click (Line_Number_X, Row_Y (1));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "bb" & ASCII.LF & "ccc" & ASCII.LF & "dddd");
      Assert_Selection
        (Natural (Editor.State.Line_Start (S, 1)),
         Natural (Editor.State.Line_Start (S, 2)),
         "Line-number click must select full logical line including following newline");
   end Test_Click_Line_Number_Selects_Full_Line;

   procedure Test_Triple_Click_Line_Number_Selects_Full_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Prepare_Text;
      Triple_Click (Line_Number_X, Row_Y (1));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "bb" & ASCII.LF & "ccc" & ASCII.LF & "dddd");
      Assert_Selection
        (Natural (Editor.State.Line_Start (S, 1)),
         Natural (Editor.State.Line_Start (S, 2)),
         "Triple-click in the line-number zone must preserve gutter line selection");
   end Test_Triple_Click_Line_Number_Selects_Full_Line;

   procedure Test_Drag_Gutter_Down_Selects_Line_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Prepare_Text;
      Click (Line_Number_X, Row_Y (1));
      Drag (Line_Number_X, Row_Y (3));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "bb" & ASCII.LF & "ccc" & ASCII.LF & "dddd");
      Assert_Selection
        (Natural (Editor.State.Line_Start (S, 1)),
         Editor.Navigation.Buffer_Length (S),
         "Dragging gutter downward must select full lines 2 through 4");
   end Test_Drag_Gutter_Down_Selects_Line_Range;

   procedure Test_Drag_Gutter_Up_Normalizes_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Prepare_Text;
      Click (Line_Number_X, Row_Y (3));
      Drag (Line_Number_X, Row_Y (1));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "bb" & ASCII.LF & "ccc" & ASCII.LF & "dddd");
      Assert_Selection
        (Natural (Editor.State.Line_Start (S, 1)),
         Editor.Navigation.Buffer_Length (S),
         "Dragging gutter upward must normalize selected line range");
   end Test_Drag_Gutter_Up_Normalizes_Selection;

   procedure Test_Gutter_Click_Does_Not_Move_Caret_As_Text_Click
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Prepare_Text;
      Click (Line_Number_X, Row_Y (1));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Snap.Caret_Count = 1 and then Snap.Selection_Count = 1,
         "Gutter click must produce a line selection, not a collapsed text caret");
   end Test_Gutter_Click_Does_Not_Move_Caret_As_Text_Click;

   procedure Test_Fold_Marker_Click_Toggles_But_Does_Not_Select
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Folding.Add_Fold (S.Folding, 0, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (800, 200);
      Editor.Scrollbars.Reset;

      Click (Fold_Marker_X, Row_Y (0));
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert
        (Editor.Folding.Is_Fold_Collapsed (Snap.Folding, 0),
         "Fold-marker click must toggle the fold");
      Assert
        (Snap.Selection_Count = 0,
         "Fold-marker click must not also create a line selection");
   end Test_Fold_Marker_Click_Toggles_But_Does_Not_Select;

   procedure Test_Relative_Line_Number_Mode_Does_Not_Affect_Hit_Test
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Before : Editor.Gutter.Gutter_Zone;
      After  : Editor.Gutter.Gutter_Zone;
   begin
      Editor.Line_Numbers.Set_Current
        ((Mode => Editor.Line_Numbers.Absolute_Line_Numbers));
      Before := Editor.Gutter.Hit_Test
        (Line_Number_X, Row_Y (0), Layout, 4, 200);
      Editor.Line_Numbers.Set_Current
        ((Mode => Editor.Line_Numbers.Relative_Line_Numbers));
      After := Editor.Gutter.Hit_Test
        (Line_Number_X, Row_Y (0), Layout, 4, 200);
      Assert
        (Before = After,
         "Changing displayed line-number mode must not affect gutter hit-testing");
   end Test_Relative_Line_Number_Mode_Does_Not_Affect_Hit_Test;

   procedure Test_Folded_Row_Maps_Visible_Row_To_Document_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Row    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3");
      Editor.Folding.Add_Fold (S.Folding, 1, 2);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Row := Editor.Gutter.Document_Row_For_Y
        (Y             => Row_Y (2),
         Layout        => Layout,
         Scroll_Y      => 0,
         Folding       => S.Folding,
         Document_Rows => Editor.State.Line_Count (S));
      Assert
        (Row = 3,
         "Visible row after collapsed fold must map to the correct document row");
   end Test_Folded_Row_Maps_Visible_Row_To_Document_Row;

   overriding procedure Register_Tests
     (T : in out Gutter_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hit_Test_Outside_Gutter'Access,
         "Gutter Hit Test Outside");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hit_Test_Line_Number_Zone'Access,
         "Gutter Hit Test Line Number Zone");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hit_Test_Fold_Marker_Zone'Access,
         "Gutter Hit Test Fold Marker Zone");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Fold_Marker_Zone_Has_Priority'Access,
         "Gutter Fold Marker Priority");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Click_Line_Number_Selects_Full_Line'Access,
         "Gutter Click Selects Full Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Triple_Click_Line_Number_Selects_Full_Line'Access,
         "Triple-click Line Number Selects Full Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Drag_Gutter_Down_Selects_Line_Range'Access,
         "Gutter Drag Down Selects Line Source_Span");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Drag_Gutter_Up_Normalizes_Selection'Access,
         "Gutter Drag Up Normalizes Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Gutter_Click_Does_Not_Move_Caret_As_Text_Click'Access,
         "Gutter Click Does Not Text Hit Test");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Fold_Marker_Click_Toggles_But_Does_Not_Select'Access,
         "Fold Marker Click Does Not Select Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Relative_Line_Number_Mode_Does_Not_Affect_Hit_Test'Access,
         "Relative Line Number Mode Does Not Affect Gutter Hit Test");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Folded_Row_Maps_Visible_Row_To_Document_Row'Access,
         "Folded Rows Map Visible Row To Document Row");
   end Register_Tests;

end Editor.Gutter.Tests;
