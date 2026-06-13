with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use Ada.Containers;
with Text_Buffer;
with Editor.Layout;
with Editor.View;
with Editor.Cursors; use Editor.Cursors;
with Editor.Commands;
with Editor.UTF8;
with Editor.Folding;

package body Editor.Rectangle_Selection is

   function Line_Length
     (S   : Editor.State.State_Type;
      Row : Natural) return Natural
   is
      Start : Natural := 0;
      Stop  : Natural := 0;
   begin
      if Row >= Editor.State.Line_Count (S) then
         return 0;
      end if;

      Start := Natural (Editor.State.Line_Start (S, Row));
      Stop  := Natural (Editor.State.Line_End (S, Row));

      if Stop < Start then
         return 0;
      end if;

      return Stop - Start;
   end Line_Length;

   function Index_For_Row_Col
     (S   : Editor.State.State_Type;
      Row : Natural;
      Col : Natural) return Cursor_Index
   is
      Len : Natural := 0;
   begin
      if Row >= Editor.State.Line_Count (S) then
         return Cursor_Index (Text_Buffer.Length (S.Buffer));
      end if;

      Len := Line_Length (S, Row);
      return Cursor_Index (Natural (Editor.State.Line_Start (S, Row)) + Natural'Min (Col, Len));
   end Index_For_Row_Col;

   function Normalize
     (Anchor_Row : Natural;
      Anchor_Col : Natural;
      Cursor_Row : Natural;
      Cursor_Col : Natural) return Rectangle_Range is
   begin
      return
        (First_Row => Natural'Min (Anchor_Row, Cursor_Row),
         Last_Row  => Natural'Max (Anchor_Row, Cursor_Row),
         First_Col => Natural'Min (Anchor_Col, Cursor_Col),
         Last_Col  => Natural'Max (Anchor_Col, Cursor_Col));
   end Normalize;

   procedure Point_To_Row_Col
     (S   : Editor.State.State_Type;
      X   : Natural;
      Y   : Natural;
      Row : out Natural;
      Col : out Natural)
   is
      Layout     : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Line_Count : constant Natural := Natural'Max (1, Editor.State.Line_Count (S));
   begin
      Col := Editor.Layout.Text_Column_For_X
        (Layout, Line_Count, X, Editor.View.Scroll_X);

      Row := Editor.Layout.Row_For_Y (Layout, Y, Editor.View.Scroll_Y);

      if Editor.State.Line_Count (S) = 0 then
         Row := 0;
      else
         declare
            Visible_Count : constant Natural :=
              Natural'Max
                (1, Editor.Folding.Visible_Row_Count
                      (S.Folding, Editor.State.Line_Count (S)));
            Visible_Row : constant Natural := Natural'Min (Row, Visible_Count - 1);
         begin
            Row := Editor.Folding.Visible_Row_To_Document_Row
              (S.Folding, Visible_Row);
            if Row >= Editor.State.Line_Count (S) then
               Row := Editor.State.Line_Count (S) - 1;
            end if;
         end;
      end if;
   end Point_To_Row_Col;

   procedure Build_Carets
     (S     : in out Editor.State.State_Type;
      Selection_Range : Rectangle_Range)
   is
      Line_Len  : Natural := 0;
      Start_Pos : Cursor_Index := 0;
      End_Pos   : Cursor_Index := 0;
      Start_VC  : Natural := 0;
      End_VC    : Natural := 0;
   begin
      S.Carets.Clear;

      if Editor.State.Line_Count (S) = 0 then
         S.Carets.Append
           (Caret_State'
              (Pos                   => 0,
               Anchor                => 0,
               Virtual_Column        => 0,
               Anchor_Virtual_Column => 0));
         return;
      end if;

      for Row in Selection_Range.First_Row .. Natural'Min (Selection_Range.Last_Row, Editor.State.Line_Count (S) - 1) loop
         Line_Len := Line_Length (S, Row);

         Start_Pos := Index_For_Row_Col (S, Row, Selection_Range.First_Col);
         End_Pos   := Index_For_Row_Col (S, Row, Selection_Range.Last_Col);

         if Selection_Range.First_Col > Line_Len then
            Start_VC := Selection_Range.First_Col;
         else
            Start_VC := 0;
         end if;

         if Selection_Range.Last_Col > Line_Len then
            End_VC := Selection_Range.Last_Col;
         else
            End_VC := 0;
         end if;

         S.Carets.Append
           (Caret_State'
              (Pos                   => End_Pos,
               Anchor                => Start_Pos,
               Virtual_Column        => End_VC,
               Anchor_Virtual_Column => Start_VC));
      end loop;

      if S.Carets.Length = 0 then
         S.Carets.Append
           (Caret_State'
              (Pos                   => 0,
               Anchor                => 0,
               Virtual_Column        => 0,
               Anchor_Virtual_Column => 0));
      end if;

      Editor.State.Normalize_Carets (S);
   end Build_Carets;

   function Has_Selection
     (C : Editor.Cursors.Caret_State) return Boolean is
   begin
      return C.Pos /= C.Anchor
        or else
          (C.Anchor_Virtual_Column > 0
           and then C.Virtual_Column /= C.Anchor_Virtual_Column);
   end Has_Selection;

   function Has_Rectangle_Span
     (C : Editor.Cursors.Caret_State) return Boolean is
   begin
      return C.Pos /= C.Anchor
        or else C.Virtual_Column /= C.Anchor_Virtual_Column;
   end Has_Rectangle_Span;

   function Has_Rectangular_Selection
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      if not S.Rect_Select_Active then
         return False;
      end if;

      for C of S.Carets loop
         if Has_Rectangle_Span (C) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Rectangular_Selection;

   function Column_For
     (S          : Editor.State.State_Type;
      Pos        : Cursor_Index;
      Virtual_Col : Natural) return Natural
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if Virtual_Col > 0 then
         return Virtual_Col;
      end if;

      Editor.State.Row_Col_For_Index (S, Pos, Row, Col);
      return Col;
   end Column_For;

   function Selection_Left_Column
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Natural
   is
      A : constant Natural := Column_For (S, C.Anchor, C.Anchor_Virtual_Column);
      P : constant Natural := Column_For (S, C.Pos, C.Virtual_Column);
   begin
      return Natural'Min (A, P);
   end Selection_Left_Column;

   function Selection_Right_Column
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Natural
   is
      A : constant Natural := Column_For (S, C.Anchor, C.Anchor_Virtual_Column);
      P : constant Natural := Column_For (S, C.Pos, C.Virtual_Column);
   begin
      return Natural'Max (A, P);
   end Selection_Right_Column;

   function Selection_Start_Position
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Editor.Cursors.Cursor_Index
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Editor.State.Row_Col_For_Index (S, C.Pos, Row, Col);
      return Index_For_Row_Col (S, Row, Selection_Left_Column (S, C));
   end Selection_Start_Position;

   function Selection_End_Position
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Editor.Cursors.Cursor_Index
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Editor.State.Row_Col_For_Index (S, C.Pos, Row, Col);
      return Index_For_Row_Col (S, Row, Selection_Right_Column (S, C));
   end Selection_End_Position;

   function Rectangular_Copy_Text
     (S : Editor.State.State_Type) return Ada.Strings.Unbounded.Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;
      First  : Boolean := True;
   begin
      for C of S.Carets loop
         if Has_Rectangle_Span (C) then
            declare
               Row       : Natural := 0;
               Dummy_Col : Natural := 0;
               Left_Col  : constant Natural := Selection_Left_Column (S, C);
               Right_Col : constant Natural := Selection_Right_Column (S, C);
               Line_Len  : Natural := 0;
               Start     : Natural := 0;
            begin
               Editor.State.Row_Col_For_Index (S, C.Pos, Row, Dummy_Col);
               Line_Len := Line_Length (S, Row);
               Start := Natural (Editor.State.Line_Start (S, Row));

               if not First then
                  Append (Result, ASCII.LF);
               end if;

               if Left_Col < Right_Col then
                  for Col in Left_Col .. Right_Col - 1 loop
                     if Col < Line_Len then
                        Append (Result, Editor.UTF8.Encode_UTF8 (Text_Buffer.Code_Point_At (S.Buffer, Start + Col)));
                     else
                        Append (Result, ' ');
                     end if;
                  end loop;
               end if;

               First := False;
            end;
         end if;
      end loop;

      return Result;
   end Rectangular_Copy_Text;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;

   procedure Build_Delete_Command
     (S   : Editor.State.State_Type;
      Cmd : out Editor.Commands.Command)
   is
      L : Cursor_Index := 0;
      H : Cursor_Index := 0;
   begin
      Cmd.Kind := Editor.Commands.Apply_Replace_Batch;
      Cmd.Positions.Clear;
      Cmd.Delete_Counts.Clear;
      Cmd.Insert_Texts.Clear;

      for C of S.Carets loop
         if Has_Rectangle_Span (C) then
            L := Selection_Start_Position (S, C);
            H := Selection_End_Position (S, C);

            if H > L then
               Append_Replace_Op
                 (Cmd,
                  L,
                  Natural (H - L),
                  Null_Unbounded_String);
            end if;
         end if;
      end loop;
   end Build_Delete_Command;

   procedure Collapse_After_Delete
     (S           : in out Editor.State.State_Type;
      Old_Carets  : Editor.Cursors.Cursors_Vector.Vector;
      New_Caret   : out Editor.Cursors.Cursor_Index)
   is
      New_Carets : Editor.Cursors.Cursors_Vector.Vector;
      Offset     : Natural := 0;
      Target_Pos : Cursor_Index := 0;
      New_Pos    : Cursor_Index := 0;
      Row        : Natural := 0;
      Col        : Natural := 0;
      Left_Col   : Natural := 0;
      Len        : Natural := 0;
      Deleted    : Natural := 0;
      VC         : Natural := 0;
   begin
      for C of Old_Carets loop
         if Has_Rectangle_Span (C) then
            Editor.State.Row_Col_For_Index (S, C.Pos, Row, Col);
            Left_Col := Selection_Left_Column (S, C);
            Len := Line_Length (S, Row);
            Target_Pos := Index_For_Row_Col (S, Row, Left_Col);
            Deleted := Natural (Selection_End_Position (S, C) - Selection_Start_Position (S, C));

            if Natural (Target_Pos) >= Offset then
               New_Pos := Cursor_Index (Natural (Target_Pos) - Offset);
            else
               New_Pos := 0;
            end if;

            if Left_Col > Len then
               VC := Left_Col;
            else
               VC := 0;
            end if;

            New_Carets.Append
              (Caret_State'
                 (Pos                   => New_Pos,
                  Anchor                => New_Pos,
                  Virtual_Column        => VC,
                  Anchor_Virtual_Column => VC));

            Offset := Offset + Deleted;
         end if;
      end loop;

      if New_Carets.Length = 0 then
         New_Carets.Append
           (Caret_State'
              (Pos                   => 0,
               Anchor                => 0,
               Virtual_Column        => 0,
               Anchor_Virtual_Column => 0));
      end if;

      S.Carets := New_Carets;
      S.Rect_Select_Active := False;
      Editor.State.Normalize_Carets (S);
      New_Caret := S.Carets (S.Carets.First_Index).Pos;
   end Collapse_After_Delete;

end Editor.Rectangle_Selection;
