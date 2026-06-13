with Editor.State;
with Editor.Commands;   use Editor.Commands;
with Editor.Cursors;    use Editor.Cursors;
with Editor.Navigation; use Editor.Navigation;
with Ada.Containers; use Ada.Containers;
with Editor.Search;
with Editor.Selection;

package body Editor.Executor.Navigation is

   use Cursors_Vector;

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

   function Safe_Anchor
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets (S.Carets.First_Index).Anchor;
      end if;
   end Safe_Anchor;

   procedure Normalize (S : in out Editor.State.State_Type) is
   begin
      Editor.State.Normalize_Carets (S);
   end Normalize;

   function Preferred_Column_For_Caret
     (S : Editor.State.State_Type;
      C : Cursor_Index) return Natural is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Natural (C), Row, Col);
      return Col;
   end Preferred_Column_For_Caret;

   procedure Keep_Only_Primary_Caret
     (S : in out Editor.State.State_Type) is
      Primary : Caret_State :=
        (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0);
   begin
      if S.Carets.Length > 0 then
         Primary := S.Carets (S.Carets.First_Index);
      end if;

      S.Carets.Clear;
      S.Carets.Append (Primary);
   end Keep_Only_Primary_Caret;

   function Is_Select_Command (Kind : Editor.Commands.Command_Kind) return Boolean is
   begin
      return Kind in Select_Word_Left
                   | Select_Word_Right
                   | Extend_Selection_Line_Up
                   | Extend_Selection_Line_Down
                   | Select_Line_Start
                   | Select_Line_End
                   | Select_Document_Start
                   | Select_Document_End
                   | Select_Page_Up
                   | Select_Page_Down;
   end Is_Select_Command;

   function Extends_Selection (Cmd : Editor.Commands.Command) return Boolean is
   begin
      return Cmd.Shift or else Is_Select_Command (Cmd.Kind);
   end Extends_Selection;

   procedure Finish_Caret_Move
     (C              : in out Caret_State;
      New_Pos        : Cursor_Index;
      New_Virtual    : Natural;
      Extend         : Boolean) is
   begin
      C.Pos := New_Pos;
      C.Virtual_Column := New_Virtual;

      if Extend then
         --  Keep the existing anchor. If the caret did not already have a
         --  selection, Anchor is the old caret position, which is exactly the
         --  desired Shift-navigation anchor.
         null;
      else
         C.Anchor := C.Pos;
         C.Anchor_Virtual_Column := C.Virtual_Column;
      end if;
   end Finish_Caret_Move;

   procedure Append_Moved_Caret
     (New_Carets : in out Cursors_Vector.Vector;
      Old_Caret  : Caret_State;
      New_Pos    : Cursor_Index;
      New_Virt   : Natural;
      Extend     : Boolean)
   is
      C : Caret_State := Old_Caret;
   begin
      Finish_Caret_Move (C, New_Pos, New_Virt, Extend);
      New_Carets.Append (C);
   end Append_Moved_Caret;

   procedure Set_First_Caret_Outputs
     (S                    : Editor.State.State_Type;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural) is
   begin
      New_Caret := Safe_Caret (S);

      if S.Carets.Length > 0
        and then S.Carets (S.Carets.First_Index).Virtual_Column > 0
      then
         New_Preferred_Column :=
           S.Carets (S.Carets.First_Index).Virtual_Column;
      else
         New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);
      end if;
   end Set_First_Caret_Outputs;

   procedure Move_All_To_Physical
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      New_Carets : Cursors_Vector.Vector;
      New_Pos    : Cursor_Index := 0;
      Extend     : constant Boolean := Extends_Selection (Cmd);
      Row        : Natural := 0;
      Col        : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         S.Carets.Append
           (Caret_State'
              (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      end if;

      for C of S.Carets loop
         declare
            Appended : Boolean := False;
         begin
            case Cmd.Kind is
               when Move_Home | Move_Line_Start | Select_Line_Start =>
                  New_Pos := Cursor_Index (Line_Start_Index (S, Natural (C.Pos)));

               when Move_End | Move_Line_End | Select_Line_End =>
                  New_Pos := Cursor_Index (Line_End_Index (S, Natural (C.Pos)));

               when Move_Document_Start | Select_Document_Start =>
                  New_Pos := Cursor_Index (Document_Start (S));

               when Move_Document_End | Select_Document_End =>
                  New_Pos := Cursor_Index (Document_End (S));

               when Move_Word_Left | Select_Word_Left =>
                  New_Pos := Cursor_Index (Previous_Word_Start (S, Natural (C.Pos)));

               when Move_Word_Right | Select_Word_Right =>
                  New_Pos := Cursor_Index (Next_Word_Start (S, Natural (C.Pos)));

               when Move_Left =>
                  if C.Virtual_Column > 0 then
                     Line_Column_For_Index (S, Natural (C.Pos), Row, Col);
                     if C.Virtual_Column > Col + 1 then
                        Append_Moved_Caret
                          (New_Carets, C, C.Pos, C.Virtual_Column - 1, Extend);
                     else
                        Append_Moved_Caret (New_Carets, C, C.Pos, 0, Extend);
                     end if;
                     Appended := True;
                  elsif C.Pos > 0 then
                     New_Pos := C.Pos - 1;
                  else
                     New_Pos := C.Pos;
                  end if;

               when Move_Right =>
                  declare
                     Line_Len : Natural := 0;
                  begin
                     Line_Column_For_Index (S, Natural (C.Pos), Row, Col);
                     Line_Len := Line_Length (S, Row);

                     if C.Virtual_Column > 0 then
                        Append_Moved_Caret
                          (New_Carets, C, C.Pos, C.Virtual_Column + 1, Extend);
                        Appended := True;
                     elsif Col < Line_Len then
                        New_Pos := C.Pos + 1;
                     else
                        Append_Moved_Caret (New_Carets, C, C.Pos, Col + 1, Extend);
                        Appended := True;
                     end if;
                  end;

               when others =>
                  New_Pos := C.Pos;
            end case;

            if not Appended then
               Append_Moved_Caret (New_Carets, C, New_Pos, 0, Extend);
            end if;
         end;
      end loop;

      S.Carets := New_Carets;
      Normalize (S);
      Set_First_Caret_Outputs (S, New_Caret, New_Preferred_Column);
   end Move_All_To_Physical;

   procedure Move_All_Vertical
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      Delta_Rows           : Integer;
      New_Caret            : out Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      New_Carets : Cursors_Vector.Vector;
      Extend     : constant Boolean := Extends_Selection (Cmd);
      Row        : Natural := 0;
      Col        : Natural := 0;
      Target_Col : Natural := 0;
      New_Pos    : Cursor_Index := 0;
      New_Virt   : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         S.Carets.Append
           (Caret_State'
              (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      end if;

      for C of S.Carets loop
         Line_Column_For_Index (S, Natural (C.Pos), Row, Col);

         if C.Virtual_Column > 0 then
            Target_Col := C.Virtual_Column;
         elsif S.Carets.Length = 1 then
            Target_Col := S.Preferred_Column;
         else
            Target_Col := Col;
         end if;

         Vertical_Target_Info
           (S,
            C.Pos,
            Delta_Rows,
            Target_Col,
            New_Pos,
            New_Virt);

         Append_Moved_Caret (New_Carets, C, New_Pos, New_Virt, Extend);
      end loop;

      S.Carets := New_Carets;
      Normalize (S);
      Set_First_Caret_Outputs (S, New_Caret, New_Preferred_Column);
   end Move_All_Vertical;


   procedure Apply_Line_Target
     (S                    : in out Editor.State.State_Type;
      Target               : Editor.Selection.Selection_Target;
      Cursor_At_Start      : Boolean;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   begin
      Keep_Only_Primary_Caret (S);
      S.Rect_Select_Active := False;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Carets.Clear;

      if Target.Found then
         Start_Pos := Index_For_Line_Column
           (S,
            Target.Selection_Range.Start_Position.Row,
            Target.Selection_Range.Start_Position.Column);
         End_Pos := Index_For_Line_Column
           (S,
            Target.Selection_Range.End_Position.Row,
            Target.Selection_Range.End_Position.Column);

         if Cursor_At_Start then
            S.Carets.Append
              (Caret_State'
                 (Pos => Cursor_Index (Start_Pos),
                  Anchor => Cursor_Index (End_Pos),
                  Virtual_Column => 0,
                  Anchor_Virtual_Column => 0));
            New_Caret := Cursor_Index (Start_Pos);
         else
            S.Carets.Append
              (Caret_State'
                 (Pos => Cursor_Index (End_Pos),
                  Anchor => Cursor_Index (Start_Pos),
                  Virtual_Column => 0,
                  Anchor_Virtual_Column => 0));
            New_Caret := Cursor_Index (End_Pos);
         end if;
      else
         S.Carets.Append
           (Caret_State'
              (Pos => Safe_Caret (S),
               Anchor => Safe_Caret (S),
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0));
         New_Caret := Safe_Caret (S);
      end if;

      New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);
      Normalize (S);
   end Apply_Line_Target;

   procedure Select_Line_Range
     (S                    : in out Editor.State.State_Type;
      Anchor_Row           : Natural;
      Target_Row           : Natural;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Target : constant Editor.Selection.Selection_Target :=
        Editor.Selection.Lines_Range (S, Anchor_Row, Target_Row);
      Cursor_At_Start : constant Boolean := Target_Row < Anchor_Row;
   begin
      Apply_Line_Target
        (S                    => S,
         Target               => Target,
         Cursor_At_Start      => Cursor_At_Start,
         New_Caret            => New_Caret,
         New_Preferred_Column => New_Preferred_Column);
   end Select_Line_Range;

   procedure Apply_Word_Target
     (S                    : in out Editor.State.State_Type;
      Target               : Editor.Selection.Selection_Target;
      Fallback_Pos         : Editor.Cursors.Cursor_Index;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   begin
      Keep_Only_Primary_Caret (S);
      S.Rect_Select_Active := False;

      S.Carets.Clear;
      if Target.Found then
         Start_Pos := Index_For_Line_Column
           (S,
            Target.Selection_Range.Start_Position.Row,
            Target.Selection_Range.Start_Position.Column);
         End_Pos := Index_For_Line_Column
           (S,
            Target.Selection_Range.End_Position.Row,
            Target.Selection_Range.End_Position.Column);

         S.Carets.Append
           (Caret_State'
              (Pos => Cursor_Index (End_Pos),
               Anchor => Cursor_Index (Start_Pos),
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0));
         New_Caret := Cursor_Index (End_Pos);
      else
         S.Carets.Append
           (Caret_State'
              (Pos => Fallback_Pos,
               Anchor => Fallback_Pos,
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0));
         New_Caret := Fallback_Pos;
      end if;

      New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);
      Normalize (S);
   end Apply_Word_Target;


   function Anchor_Row_For_Line_Extension
     (S : Editor.State.State_Type) return Natural
   is
      Anchor_Row : Natural := 0;
      Anchor_Col : Natural := 0;
      Cursor_Row : Natural := 0;
      Cursor_Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Natural (Safe_Anchor (S)), Anchor_Row, Anchor_Col);
      Line_Column_For_Index (S, Natural (Safe_Caret (S)), Cursor_Row, Cursor_Col);

      --  A full-line upward extension stores the anchor at the far boundary,
      --  which is often the next row's column zero. Convert that boundary back
      --  to the selected document row before extending again; otherwise a
      --  repeated Shift-Up would grow by an extra line below the anchor.
      if Anchor_Row > Cursor_Row and then Anchor_Col = 0 and then Anchor_Row > 0 then
         return Anchor_Row - 1;
      else
         return Anchor_Row;
      end if;
   end Anchor_Row_For_Line_Extension;

   function Page_Move_Delta return Positive is
      Rows : constant Positive := Rows_Per_Page;
   begin
      if Rows > 1 then
         return Rows - 1;
      else
         return 1;
      end if;
   end Page_Move_Delta;

   function Collapses_Active_Selection
     (Cmd : Editor.Commands.Command) return Boolean is
   begin
      if Extends_Selection (Cmd) then
         return False;
      end if;

      return Cmd.Kind in Move_Left
                       | Move_Right
                       | Move_Up
                       | Move_Down
                       | Move_Home
                       | Move_End
                       | Move_Line_Start
                       | Move_Line_End
                       | Move_Document_Start
                       | Move_Document_End
                       | Move_Page_Up
                       | Move_Page_Down
                       | Move_Word_Left
                       | Move_Word_Right
                       | Move_To_Point;
   end Collapses_Active_Selection;

   procedure Collapse_Selection_For_Move
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      Sel_Start            : Editor.Cursors.Cursor_Index;
      Old_Caret            : Editor.Cursors.Cursor_Index;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural)
   is
      Low        : constant Cursor_Index := Cursor_Index'Min (Sel_Start, Old_Caret);
      High       : constant Cursor_Index := Cursor_Index'Max (Sel_Start, Old_Caret);
      Collapse_To : Cursor_Index := Old_Caret;
      Row        : Natural := 0;
      Col        : Natural := 0;
   begin
      case Cmd.Kind is
         when Move_Left | Move_Word_Left | Move_Up | Move_Page_Up =>
            Collapse_To := Low;

         when Move_Right | Move_Word_Right | Move_Down | Move_Page_Down =>
            Collapse_To := High;

         when Move_Home | Move_Line_Start =>
            Collapse_To := Cursor_Index (Line_Start_Index (S, Natural (Low)));

         when Move_End | Move_Line_End =>
            Collapse_To := Cursor_Index (Line_End_Index (S, Natural (High)));

         when Move_Document_Start =>
            Collapse_To := Cursor_Index (Document_Start (S));

         when Move_Document_End =>
            Collapse_To := Cursor_Index (Document_End (S));

         when Move_To_Point =>
            Collapse_To := Index_For_Point (S, Cmd.Click_X, Cmd.Click_Y);

         when others =>
            Collapse_To := Old_Caret;
      end case;

      Keep_Only_Primary_Caret (S);
      S.Rect_Select_Active := False;

      declare
         C : Caret_State := S.Carets (S.Carets.First_Index);
      begin
         C.Pos := Collapse_To;
         C.Anchor := Collapse_To;
         C.Virtual_Column := 0;
         C.Anchor_Virtual_Column := 0;
         S.Carets.Replace_Element (S.Carets.First_Index, C);
      end;

      Normalize (S);
      New_Caret := Safe_Caret (S);
      Line_Column_For_Index (S, Natural (New_Caret), Row, Col);
      New_Preferred_Column := Col;
   end Collapse_Selection_For_Move;

   procedure Execute
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      Had_Selection        : Boolean;
      Sel_Start            : Editor.Cursors.Cursor_Index;
      Old_Caret            : Editor.Cursors.Cursor_Index;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural)
   is
   begin
      New_Caret := Safe_Caret (S);
      New_Preferred_Column := S.Preferred_Column;
      S.Active_Find_Match := Editor.Search.No_Match;

      if Had_Selection and then Collapses_Active_Selection (Cmd) then
         Collapse_Selection_For_Move
           (S, Cmd, Sel_Start, Old_Caret, New_Caret, New_Preferred_Column);
         return;
      end if;

      case Cmd.Kind is

         when Move_Left
            | Move_Right
            | Move_Home
            | Move_End
            | Move_Line_Start
            | Move_Line_End
            | Move_Document_Start
            | Move_Document_End
            | Move_Word_Left
            | Move_Word_Right
            | Select_Word_Left
            | Select_Word_Right
            | Select_Line_Start
            | Select_Line_End
            | Select_Document_Start
            | Select_Document_End =>
            Move_All_To_Physical (S, Cmd, New_Caret, New_Preferred_Column);

         when Move_Up =>
            Move_All_Vertical (S, Cmd, -1, New_Caret, New_Preferred_Column);

         when Move_Down =>
            Move_All_Vertical (S, Cmd, 1, New_Caret, New_Preferred_Column);

         when Extend_Selection_Line_Up =>
            declare
               Row : Natural := 0;
               Col : Natural := 0;
               Anchor_Row : Natural := 0;
            begin
               Line_Column_For_Index (S, Natural (Safe_Caret (S)), Row, Col);
               Anchor_Row := Anchor_Row_For_Line_Extension (S);
               Select_Line_Range
                 (S,
                  Anchor_Row           => Anchor_Row,
                  Target_Row           => (if Row > 0 then Row - 1 else 0),
                  New_Caret            => New_Caret,
                  New_Preferred_Column => New_Preferred_Column);
            end;

         when Extend_Selection_Line_Down =>
            declare
               Row : Natural := 0;
               Col : Natural := 0;
               Anchor_Row : Natural := 0;
            begin
               Line_Column_For_Index (S, Natural (Safe_Caret (S)), Row, Col);
               Anchor_Row := Anchor_Row_For_Line_Extension (S);
               Select_Line_Range
                 (S,
                  Anchor_Row           => Anchor_Row,
                  Target_Row           => Row + 1,
                  New_Caret            => New_Caret,
                  New_Preferred_Column => New_Preferred_Column);
            end;

         when Move_Page_Up | Select_Page_Up =>
            Move_All_Vertical
              (S, Cmd, -Integer (Page_Move_Delta), New_Caret, New_Preferred_Column);

         when Move_Page_Down | Select_Page_Down =>
            Move_All_Vertical
              (S, Cmd, Integer (Page_Move_Delta), New_Caret, New_Preferred_Column);

         when Move_To_Point =>
            Keep_Only_Primary_Caret (S);
            S.Rect_Select_Active := False;

            New_Caret := Index_For_Point (S, Cmd.Click_X, Cmd.Click_Y);

            declare
               C : Caret_State := S.Carets (S.Carets.First_Index);
            begin
               Finish_Caret_Move
                 (C,
                  New_Caret,
                  0,
                  Extend => Cmd.Shift);
               S.Carets.Replace_Element (S.Carets.First_Index, C);
            end;

            New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);

         when Drag_To_Point =>
            declare
               Pos : constant Cursor_Index :=
                 Index_For_Point (S, Cmd.Click_X, Cmd.Click_Y);
               C   : Caret_State;
            begin
               if S.Carets.Length = 0 then
                  S.Carets.Append
                    (Caret_State'
                       (Pos => Pos,
                        Anchor => Pos,
                        Virtual_Column => 0,
                        Anchor_Virtual_Column => 0));
               else
                  C := S.Carets (S.Carets.First_Index);
                  C.Pos := Pos;
                  C.Virtual_Column := 0;
                  S.Carets.Replace_Element (S.Carets.First_Index, C);
               end if;

               New_Caret := Pos;
               New_Preferred_Column := Preferred_Column_For_Caret (S, New_Caret);
            end;

         when Select_Word =>
            declare
               Pos    : constant Cursor_Index := Safe_Caret (S);
               Row    : Natural := 0;
               Col    : Natural := 0;
               Target : Editor.Selection.Selection_Target;
            begin
               Line_Column_For_Index (S, Natural (Pos), Row, Col);
               Target := Editor.Selection.Word_Range_Around_Caret (S, Row, Col);
               Apply_Word_Target
                 (S                    => S,
                  Target               => Target,
                  Fallback_Pos         => Pos,
                  New_Caret            => New_Caret,
                  New_Preferred_Column => New_Preferred_Column);
            end;

         when Select_Word_At_Point =>
            declare
               Pos    : constant Cursor_Index :=
                 Index_For_Point (S, Cmd.Click_X, Cmd.Click_Y);
               Row    : Natural := 0;
               Col    : Natural := 0;
               Target : Editor.Selection.Selection_Target;
            begin
               Line_Column_For_Index (S, Natural (Pos), Row, Col);
               Target := Editor.Selection.Word_Range_At (S, Row, Col);
               Apply_Word_Target
                 (S                    => S,
                  Target               => Target,
                  Fallback_Pos         => Pos,
                  New_Caret            => New_Caret,
                  New_Preferred_Column => New_Preferred_Column);
            end;

         when Select_Line =>
            declare
               Pos    : constant Cursor_Index := Safe_Caret (S);
               Row    : Natural := 0;
               Col    : Natural := 0;
               Target : Editor.Selection.Selection_Target;
            begin
               Line_Column_For_Index (S, Natural (Pos), Row, Col);
               Target := Editor.Selection.Line_Range_At (S, Row);
               Apply_Line_Target
                 (S                    => S,
                  Target               => Target,
                  Cursor_At_Start      => False,
                  New_Caret            => New_Caret,
                  New_Preferred_Column => New_Preferred_Column);
            end;

         when Select_Line_At_Point =>
            declare
               Pos    : constant Cursor_Index :=
                 Index_For_Point (S, Cmd.Click_X, Cmd.Click_Y);
               Row    : Natural := 0;
               Col    : Natural := 0;
               Target : Editor.Selection.Selection_Target;
            begin
               Line_Column_For_Index (S, Natural (Pos), Row, Col);
               Target := Editor.Selection.Line_Range_At (S, Row);
               Apply_Line_Target
                 (S                    => S,
                  Target               => Target,
                  Cursor_At_Start      => False,
                  New_Caret            => New_Caret,
                  New_Preferred_Column => New_Preferred_Column);
            end;

         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.Navigation;
