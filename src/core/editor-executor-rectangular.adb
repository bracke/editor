with Editor.State;
with Editor.Commands;   use Editor.Commands;
with Editor.Cursors;    use Editor.Cursors;
with Editor.Rectangle_Selection;
with Ada.Containers;    use Ada.Containers;

package body Editor.Executor.Rectangular is

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

   procedure Start_Rectangle
     (S                    : in out Editor.State.State_Type;
      X                    : Natural;
      Y                    : Natural;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Row : Natural := 0;
      Col : Natural := 0;
      R   : Editor.Rectangle_Selection.Rectangle_Range;
   begin
      Editor.Rectangle_Selection.Point_To_Row_Col (S, X, Y, Row, Col);

      S.Rect_Select_Active := True;
      S.Rect_Anchor_Row := Row;
      S.Rect_Anchor_Col := Col;

      R := Editor.Rectangle_Selection.Normalize (Row, Col, Row, Col);
      Editor.Rectangle_Selection.Build_Carets (S, R);

      New_Caret := Safe_Caret (S);
      New_Preferred_Column := Col;
   end Start_Rectangle;

   procedure Start_Rectangle_At_Caret
     (S                    : in out Editor.State.State_Type;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Row : Natural := 0;
      Col : Natural := 0;
      R   : Editor.Rectangle_Selection.Rectangle_Range;
   begin
      if S.Carets.Length > 0 then
         Editor.State.Row_Col_For_Index
           (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
         if S.Carets (S.Carets.First_Index).Virtual_Column > 0 then
            Col := S.Carets (S.Carets.First_Index).Virtual_Column;
         end if;
      end if;

      S.Rect_Select_Active := True;
      S.Rect_Anchor_Row := Row;
      S.Rect_Anchor_Col := Col;

      --  The initial command establishes rectangular mode without selecting
      --  text. Extending or dragging updates the cursor and produces spans.
      R := Editor.Rectangle_Selection.Normalize (Row, Col, Row, Col);
      Editor.Rectangle_Selection.Build_Carets (S, R);

      New_Caret := Safe_Caret (S);
      New_Preferred_Column := Col;
   end Start_Rectangle_At_Caret;

   procedure Drag_Rectangle
     (S                    : in out Editor.State.State_Type;
      X                    : Natural;
      Y                    : Natural;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Current_Row : Natural := 0;
      Current_Col : Natural := 0;
      R           : Editor.Rectangle_Selection.Rectangle_Range;
   begin
      if not S.Rect_Select_Active then
         Start_Rectangle
           (S                    => S,
            X                    => X,
            Y                    => Y,
            New_Caret            => New_Caret,
            New_Preferred_Column => New_Preferred_Column);
         return;
      end if;

      Editor.Rectangle_Selection.Point_To_Row_Col
        (S, X, Y, Current_Row, Current_Col);

      R := Editor.Rectangle_Selection.Normalize
        (S.Rect_Anchor_Row,
         S.Rect_Anchor_Col,
         Current_Row,
         Current_Col);

      Editor.Rectangle_Selection.Build_Carets (S, R);

      New_Caret := Safe_Caret (S);
      New_Preferred_Column := Current_Col;
   end Drag_Rectangle;

   procedure Execute
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural) is
   begin
      New_Caret := Safe_Caret (S);
      New_Preferred_Column := S.Preferred_Column;

      case Cmd.Kind is
         when Editor.Commands.Start_Rectangle_Selection =>
            Start_Rectangle
              (S                    => S,
               X                    => Cmd.Click_X,
               Y                    => Cmd.Click_Y,
               New_Caret            => New_Caret,
               New_Preferred_Column => New_Preferred_Column);

         when Editor.Commands.Start_Rectangle_At_Caret =>
            Start_Rectangle_At_Caret
              (S                    => S,
               New_Caret            => New_Caret,
               New_Preferred_Column => New_Preferred_Column);

         when Editor.Commands.Drag_Rectangle_To_Point =>
            Drag_Rectangle
              (S                    => S,
               X                    => Cmd.Click_X,
               Y                    => Cmd.Click_Y,
               New_Caret            => New_Caret,
               New_Preferred_Column => New_Preferred_Column);

         when Editor.Commands.Clear_Rectangle_Selection =>
            S.Rect_Select_Active := False;
            if S.Carets.Length > 0 then
               declare
                  P : constant Cursor_Index := S.Carets (S.Carets.First_Index).Pos;
               begin
                  S.Carets.Clear;
                  S.Carets.Append
                    (Caret_State'
                       (Pos                   => P,
                        Anchor                => P,
                        Virtual_Column        => 0,
                        Anchor_Virtual_Column => 0));
                  New_Caret := P;
               end;
            end if;

         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.Rectangular;
