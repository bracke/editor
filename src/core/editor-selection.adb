with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use Ada.Containers;
with Text_Buffer;
with Editor.Navigation;
with Editor.Rectangle_Selection;
with Editor.Cursors;
with Editor.UTF8;
with Editor.Unicode;

package body Editor.Selection is

   function Is_Before
     (Left  : Text_Position;
      Right : Text_Position) return Boolean is
   begin
      return Left.Row < Right.Row
        or else (Left.Row = Right.Row and then Left.Column < Right.Column);
   end Is_Before;

   function Is_Equal
     (Left  : Text_Position;
      Right : Text_Position) return Boolean is
   begin
      return Left.Row = Right.Row and then Left.Column = Right.Column;
   end Is_Equal;

   function Normalize_Range
     (Left  : Text_Position;
      Right : Text_Position) return Text_Range
   is
      Start_Pos : Text_Position := Left;
      End_Pos   : Text_Position := Right;
   begin
      if Is_Before (Right, Left) then
         Start_Pos := Right;
         End_Pos := Left;
      end if;

      return
        (Start_Position => Start_Pos,
         End_Position   => End_Pos,
         Is_Empty       => Is_Equal (Start_Pos, End_Pos));
   end Normalize_Range;


   function Normalize_Rectangular_Range
     (Anchor : Text_Position;
      Cursor : Text_Position) return Rectangular_Range
   is
      First_Row : constant Natural := Natural'Min (Anchor.Row, Cursor.Row);
      Last_Row  : constant Natural := Natural'Max (Anchor.Row, Cursor.Row);
      First_Col : constant Natural := Natural'Min (Anchor.Column, Cursor.Column);
      Last_Col  : constant Natural := Natural'Max (Anchor.Column, Cursor.Column);
      End_Col   : constant Natural :=
        (if First_Col = Last_Col then First_Col else Last_Col);
   begin
      --  The cursor column is treated as the half-open end when it is to the
      --  right of the anchor, and as the half-open start when it is to the
      --  left. Equal columns produce a zero-width empty rectangle. Callers
      --  that want a one-cell command can pass Cursor.Column = Anchor.Column + 1.
      return
        (Start_Row    => First_Row,
         End_Row      => Last_Row,
         Start_Column => First_Col,
         End_Column   => End_Col,
         Is_Empty     => First_Col = End_Col);
   end Normalize_Rectangular_Range;

   function Rectangular_Row_Span
     (Selection_Range : Rectangular_Range;
      Row   : Natural) return Rectangular_Selection_Target is
   begin
      if Selection_Range.Is_Empty or else Row < Selection_Range.Start_Row or else Row > Selection_Range.End_Row then
         return (Found => False, Selection_Range => Selection_Range);
      end if;

      return
        (Found => True,
         Selection_Range =>
           (Start_Row    => Row,
            End_Row      => Row,
            Start_Column => Selection_Range.Start_Column,
            End_Column   => Selection_Range.End_Column,
            Is_Empty     => Selection_Range.Start_Column = Selection_Range.End_Column));
   end Rectangular_Row_Span;


   function Clamped_Row
     (S   : Editor.State.State_Type;
      Row : Natural) return Natural
   is
   begin
      if Editor.State.Line_Count (S) = 0 then
         return 0;
      else
         return Natural'Min (Row, Editor.State.Line_Count (S) - 1);
      end if;
   end Clamped_Row;



   function Validate_Active_Selection_Range
     (S     : Editor.State.State_Type;
      Selection_Range : out Active_Selection_Range) return Selection_Validation_Status
   is
      Len : constant Cursor_Index := Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      Selection_Range := (Low => 0, High => 0);

      if not Editor.State.Has_Active_Buffer (S) then
         return Selection_No_Active_Buffer;
      elsif S.Carets.Length = 0 then
         return Selection_No_Caret;
      end if;

      declare
         C : constant Editor.Cursors.Caret_State := S.Carets (S.Carets.First_Index);
         L : constant Cursor_Index := Cursor_Index'Min (C.Pos, C.Anchor);
         H : constant Cursor_Index := Cursor_Index'Max (C.Pos, C.Anchor);
      begin
         if H <= L then
            return Selection_Empty;
         elsif H > Len then
            return Selection_Invalid;
         end if;

         Selection_Range := (Low => L, High => H);
         return Selection_Ok;
      end;
   end Validate_Active_Selection_Range;

   function Normalize_Active_Selection
     (S : Editor.State.State_Type) return Active_Selection_Range
   is
      Selection_Range  : Active_Selection_Range;
      Status : constant Selection_Validation_Status :=
        Validate_Active_Selection_Range (S, Selection_Range);
      pragma Unreferenced (Status);
   begin
      return Selection_Range;
   end Normalize_Active_Selection;

   function Extract_Selected_Text
     (S : Editor.State.State_Type) return Ada.Strings.Unbounded.Unbounded_String
   is
      Selection_Range  : Active_Selection_Range;
      Status : constant Selection_Validation_Status :=
        Validate_Active_Selection_Range (S, Selection_Range);
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Status /= Selection_Ok then
         return Result;
      end if;

      for I in Natural (Selection_Range.Low) .. Natural (Selection_Range.High) - 1 loop
         Append
           (Result,
            Editor.UTF8.Encode_UTF8
              (Text_Buffer.Code_Point_At (S.Buffer, I)));
      end loop;

      return Result;
   end Extract_Selected_Text;

   function Selected_Character_Count
     (S : Editor.State.State_Type) return Natural
   is
      Selection_Range  : Active_Selection_Range;
      Status : constant Selection_Validation_Status :=
        Validate_Active_Selection_Range (S, Selection_Range);
   begin
      if Status = Selection_Ok then
         return Natural (Selection_Range.High - Selection_Range.Low);
      else
         return 0;
      end if;
   end Selected_Character_Count;

   function Selected_Line_Count
     (S : Editor.State.State_Type) return Natural
   is
      Selection_Range  : Active_Selection_Range;
      Status : constant Selection_Validation_Status :=
        Validate_Active_Selection_Range (S, Selection_Range);
      Start_Row : Natural := 0;
      Start_Col : Natural := 0;
      End_Row   : Natural := 0;
      End_Col   : Natural := 0;
   begin
      if Status /= Selection_Ok then
         return 0;
      end if;

      Editor.State.Row_Col_For_Index (S, Selection_Range.Low, Start_Row, Start_Col);
      Editor.State.Row_Col_For_Index (S, Selection_Range.High, End_Row, End_Col);

      if End_Row > Start_Row and then End_Col = 0 then
         return End_Row - Start_Row;
      else
         return End_Row - Start_Row + 1;
      end if;
   end Selected_Line_Count;

   function Is_Selection_Word_Character
     (Code : Editor.Unicode.Code_Point) return Boolean
   is
      V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if V > 255 then
         return False;
      end if;

      declare
         Ch : constant Character := Character'Val (V);
      begin
         return
           (Ch in 'a' .. 'z')
           or else (Ch in 'A' .. 'Z')
           or else (Ch in '0' .. '9')
           or else Ch = '_';
      end;
   end Is_Selection_Word_Character;

   function Is_Word_Trailing_Delimiter
     (Code : Editor.Unicode.Code_Point) return Boolean
   is
      V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if V > 255 then
         return False;
      end if;

      declare
         Ch : constant Character := Character'Val (V);
      begin
         return Ch = '.' or else Ch = ' ' or else Ch = ASCII.HT or else Ch = ASCII.LF;
      end;
   end Is_Word_Trailing_Delimiter;

   function Select_All_Range_For_Buffer
     (S : Editor.State.State_Type) return Active_Selection_Range
   is
   begin
      return (Low => 0, High => Cursor_Index (Text_Buffer.Length (S.Buffer)));
   end Select_All_Range_For_Buffer;

   function Current_Word_Range_At_Caret
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Active_Selection_Range
   is
      Len         : constant Natural := Text_Buffer.Length (S.Buffer);
      Caret       : Natural := 0;
      Inspect_Pos : Natural := 0;
      First       : Natural := 0;
      Last        : Natural := 0;
   begin
      Found := False;

      if not Editor.State.Has_Active_Buffer (S)
        or else S.Carets.Length = 0
        or else Len = 0
      then
         return (Low => 0, High => 0);
      end if;

      Caret := Natural'Min (Natural (S.Carets (S.Carets.First_Index).Pos), Len);

      if Caret < Len
        and then Is_Selection_Word_Character
          (Text_Buffer.Code_Point_At (S.Buffer, Caret))
      then
         Inspect_Pos := Caret;
      elsif Caret > 0
        and then (Caret = Len
                  or else Is_Word_Trailing_Delimiter
                    (Text_Buffer.Code_Point_At (S.Buffer, Caret)))
        and then Is_Selection_Word_Character
          (Text_Buffer.Code_Point_At (S.Buffer, Caret - 1))
      then
         Inspect_Pos := Caret - 1;
      else
         return (Low => Cursor_Index (Caret), High => Cursor_Index (Caret));
      end if;

      First := Inspect_Pos;
      while First > 0
        and then Is_Selection_Word_Character
          (Text_Buffer.Code_Point_At (S.Buffer, First - 1))
      loop
         First := First - 1;
      end loop;

      Last := Inspect_Pos;
      while Last < Len
        and then Is_Selection_Word_Character
          (Text_Buffer.Code_Point_At (S.Buffer, Last))
      loop
         Last := Last + 1;
      end loop;

      Found := Last > First;
      return (Low => Cursor_Index (First), High => Cursor_Index (Last));
   end Current_Word_Range_At_Caret;

   procedure Apply_Active_Buffer_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Cursor_Index;
      Pos    : Cursor_Index)
   is
      C : Editor.Cursors.Caret_State;
   begin
      if S.Carets.Length = 0 then
         S.Carets.Append
           (Editor.Cursors.Caret_State'(Pos                   => Pos,
             Anchor                => Anchor,
             Virtual_Column        => 0,
             Anchor_Virtual_Column => 0));
      else
         C := S.Carets (S.Carets.First_Index);
         C.Pos := Pos;
         C.Anchor := Anchor;
         C.Virtual_Column := 0;
         C.Anchor_Virtual_Column := 0;
         S.Carets.Replace_Element (S.Carets.First_Index, C);
      end if;
   end Apply_Active_Buffer_Selection;

   function Line_Range
     (S   : Editor.State.State_Type;
      Row : Natural) return Selection_Target is
   begin
      return Line_Range_At (S, Row);
   end Line_Range;

   function Line_Range_At
     (S   : Editor.State.State_Type;
      Row : Natural) return Selection_Target
   is
      Safe_Row : constant Natural := Clamped_Row (S, Row);
      Last_Row : constant Natural :=
        (if Editor.State.Line_Count (S) = 0
         then 0
         else Editor.State.Line_Count (S) - 1);
      Start_Pos : constant Text_Position := (Row => Safe_Row, Column => 0);
      End_Pos   : Text_Position := Start_Pos;
   begin
      if Editor.State.Line_Count (S) = 0 then
         return
           (Found => True,
            Selection_Range => Normalize_Range (Start_Pos, End_Pos));
      end if;

      if Safe_Row < Last_Row then
         End_Pos := (Row => Safe_Row + 1, Column => 0);
      else
         End_Pos :=
           (Row    => Safe_Row,
            Column => Editor.Navigation.Line_Length (S, Safe_Row));
      end if;

      return
        (Found => True,
         Selection_Range => Normalize_Range (Start_Pos, End_Pos));
   end Line_Range_At;

   function Lines_Range
     (S         : Editor.State.State_Type;
      Start_Row : Natural;
      End_Row   : Natural) return Selection_Target
   is
      First_Row : Natural := 0;
      Last_Row  : Natural := 0;
      End_Pos   : Text_Position;
   begin
      if Editor.State.Line_Count (S) = 0 then
         return
           (Found => True,
            Selection_Range => Normalize_Range
              ((Row => 0, Column => 0), (Row => 0, Column => 0)));
      end if;

      First_Row := Clamped_Row (S, Natural'Min (Start_Row, End_Row));
      Last_Row  := Clamped_Row (S, Natural'Max (Start_Row, End_Row));

      if Last_Row + 1 < Editor.State.Line_Count (S) then
         End_Pos := (Row => Last_Row + 1, Column => 0);
      else
         End_Pos :=
           (Row    => Last_Row,
            Column => Editor.Navigation.Line_Length (S, Last_Row));
      end if;

      return
        (Found => True,
         Selection_Range => Normalize_Range
           ((Row => First_Row, Column => 0), End_Pos));
   end Lines_Range;

   function Extend_Line_Range
     (S          : Editor.State.State_Type;
      Anchor     : Text_Position;
      Target_Row : Natural) return Selection_Target
   is
      Anchor_Row : constant Natural := Clamped_Row (S, Anchor.Row);
      Target     : constant Natural := Clamped_Row (S, Target_Row);
   begin
      return Lines_Range (S, Anchor_Row, Target);
   end Extend_Line_Range;

   function Word_Range_At
     (S      : Editor.State.State_Type;
      Row    : Natural;
      Column : Natural) return Selection_Target
   is
      Pos          : constant Editor.Navigation.Navigation_Target :=
        Editor.Navigation.Clamp_Position (S, Row, Column);
      Safe_Pos     : constant Text_Position :=
        (Row => Pos.Row, Column => Pos.Column);
      Line_Len     : constant Natural :=
        Editor.Navigation.Line_Length (S, Pos.Row);
      Inspect_Col  : Natural := Pos.Column;
      Inspect_Index : Natural := 0;
      Has_Run      : Boolean := False;
      Start_Index  : Natural := 0;
      End_Index    : Natural := 0;
      Start_Row    : Natural := 0;
      Start_Col    : Natural := 0;
      End_Row      : Natural := 0;
      End_Col      : Natural := 0;
   begin
      if Line_Len = 0 then
         return (Found => False, Selection_Range => Normalize_Range (Safe_Pos, Safe_Pos));
      end if;

      if Inspect_Col >= Line_Len then
         Inspect_Col := Line_Len - 1;
      end if;

      Inspect_Index :=
        Editor.Navigation.Index_For_Line_Column (S, Pos.Row, Inspect_Col);
      Editor.Navigation.Selectable_Run_At
        (S           => S,
         Index       => Inspect_Index,
         Has_Run     => Has_Run,
         Start_Index => Start_Index,
         End_Index   => End_Index);

      if not Has_Run then
         return (Found => False, Selection_Range => Normalize_Range (Safe_Pos, Safe_Pos));
      end if;

      Editor.Navigation.Line_Column_For_Index (S, Start_Index, Start_Row, Start_Col);
      Editor.Navigation.Line_Column_For_Index (S, End_Index, End_Row, End_Col);

      --  Phase 66 word/symbol selection is deliberately line-confined.  The
      --  navigation run helper already treats newlines as whitespace; keep an
      --  explicit guard here so Selection owns the public range policy.
      if Start_Row /= Pos.Row or else End_Row /= Pos.Row then
         return (Found => False, Selection_Range => Normalize_Range (Safe_Pos, Safe_Pos));
      end if;

      return
        (Found => True,
         Selection_Range => Normalize_Range
           ((Row => Start_Row, Column => Start_Col),
            (Row => End_Row, Column => End_Col)));
   end Word_Range_At;

   function Word_Range_Around_Caret
     (S      : Editor.State.State_Type;
      Row    : Natural;
      Column : Natural) return Selection_Target is
   begin
      return Word_Range_At (S, Row, Column);
   end Word_Range_Around_Caret;

   function Has_Selection
     (S : Editor.State.State_Type) return Boolean
   is
      Selection_Range  : Active_Selection_Range;
      Status : constant Selection_Validation_Status :=
        Validate_Active_Selection_Range (S, Selection_Range);
      pragma Unreferenced (Selection_Range);
   begin
      --  Phase 380 canonicalization: active-buffer selected-text consumers,
      --  availability, and render projection must agree on the same primary
      --  active selection contract.  Rectangular/editor-mechanics selection
      --  remains explicitly queryable through Editor.Rectangle_Selection, but
      --  it must not make canonical selected-text commands appear available.
      return Status = Selection_Ok;
   end Has_Selection;

   function Is_Rectangular_Selection
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.Rectangle_Selection.Has_Rectangular_Selection (S);
   end Is_Rectangular_Selection;

   function Is_Line_Selection
     (S     : Editor.State.State_Type;
      Selection_Range : Text_Range) return Boolean
   is
      Last_Row : constant Natural :=
        (if Editor.State.Line_Count (S) = 0 then 0 else Editor.State.Line_Count (S) - 1);
   begin
      if Selection_Range.Is_Empty then
         return False;
      end if;

      if Selection_Range.Start_Position.Column /= 0 then
         return False;
      end if;

      if Selection_Range.End_Position.Row > Last_Row then
         return True;
      elsif Selection_Range.End_Position.Row > Selection_Range.Start_Position.Row
        and then Selection_Range.End_Position.Column = 0
      then
         return True;
      elsif Selection_Range.End_Position.Row = Last_Row
        and then Selection_Range.End_Position.Column = Editor.Navigation.Line_Length (S, Last_Row)
      then
         return True;
      else
         return False;
      end if;
   end Is_Line_Selection;

   function Active_Selection_Shape
     (S : Editor.State.State_Type) return Selection_Shape
   is
      Selected_Count : Natural := 0;
   begin
      if Is_Rectangular_Selection (S) then
         return Rectangular_Selection;
      end if;

      for C of S.Carets loop
         if Editor.Rectangle_Selection.Has_Selection (C) then
            Selected_Count := Selected_Count + 1;
         end if;
      end loop;

      if Selected_Count = 0 then
         return No_Selection;
      elsif Selected_Count > 1 then
         return Multi_Selection;
      else
         declare
            C : constant Editor.Cursors.Caret_State := S.Carets (S.Carets.First_Index);
            L : constant Editor.Cursors.Cursor_Index := Editor.Cursors.Cursor_Index'Min (C.Pos, C.Anchor);
            H : constant Editor.Cursors.Cursor_Index := Editor.Cursors.Cursor_Index'Max (C.Pos, C.Anchor);
            SR, SC, ER, EC : Natural := 0;
         begin
            Editor.State.Row_Col_For_Index (S, L, SR, SC);
            Editor.State.Row_Col_For_Index (S, H, ER, EC);
            if Is_Line_Selection
              (S, Normalize_Range ((Row => SR, Column => SC), (Row => ER, Column => EC)))
            then
               return Line_Selection;
            else
               return Linear_Selection;
            end if;
         end;
      end if;
   end Active_Selection_Shape;

end Editor.Selection;
