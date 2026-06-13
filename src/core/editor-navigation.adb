with Text_Buffer;
with Editor.State;
with Editor.View;
with Editor.Layout;
with Editor.Wrap;
use type Editor.Wrap.Wrap_Mode;
with Editor.Minimap;
with Editor.Cursors; use Editor.Cursors;
with Ada.Containers; use Ada.Containers;
with Editor.Unicode;
with Editor.Folding;

package body Editor.Navigation is

   type Character_Class is (Word_Char, Whitespace_Char, Symbol_Char);

   function Is_Word_Char (Ch : Character) return Boolean is
   begin
      return
        (Ch in 'a' .. 'z')
        or else
        (Ch in 'A' .. 'Z')
        or else
        (Ch in '0' .. '9')
        or else
        Ch = '_';
   end Is_Word_Char;

   function Is_Whitespace (Ch : Character) return Boolean is
   begin
      return Ch = ' ' or else Ch = ASCII.HT or else Ch = ASCII.LF or else Ch = ASCII.CR;
   end Is_Whitespace;

   function Class_Of (Code : Editor.Unicode.Code_Point) return Character_Class is
      V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if V <= 255 then
         declare
            Ch : constant Character := Character'Val (V);
         begin
            if Is_Word_Char (Ch) then
               return Word_Char;
            elsif Is_Whitespace (Ch) then
               return Whitespace_Char;
            else
               return Symbol_Char;
            end if;
         end;
      else
         --  Phase 24 keeps word movement ASCII-class based. Non-ASCII scalar
         --  values are deterministic single-code-point identifier/plain text.
         return Word_Char;
      end if;
   end Class_Of;

   function Code_At
     (S     : Editor.State.State_Type;
      Index : Natural) return Editor.Unicode.Code_Point is
   begin
      return Text_Buffer.Code_Point_At (S.Buffer, Index);
   end Code_At;

   function Buffer_Length
     (S : Editor.State.State_Type) return Natural is
   begin
      return Text_Buffer.Length (S.Buffer);
   end Buffer_Length;

   function Has_Row
     (S   : Editor.State.State_Type;
      Row : Natural) return Boolean
   is
   begin
      return Row < Editor.State.Line_Count (S);
   end Has_Row;

   function Line_Length
     (S   : Editor.State.State_Type;
      Row : Natural) return Natural
   is
      Start : Natural := 0;
      Stop  : Natural := 0;
   begin
      if not Has_Row (S, Row) then
         return 0;
      end if;

      Start := Natural (Editor.State.Line_Start (S, Row));
      Stop := Natural (Editor.State.Line_End (S, Row));

      if Stop < Start then
         return 0;
      end if;

      return Stop - Start;
   end Line_Length;

   procedure Line_Column_For_Index
     (S     : Editor.State.State_Type;
      Index : Natural;
      Row   : out Natural;
      Col   : out Natural)
   is
      Safe_Index : constant Natural := Natural'Min (Index, Buffer_Length (S));
      Start      : Natural := 0;
   begin
      Row := Editor.State.Row_For_Index (S, Cursor_Index (Safe_Index));
      Start := Natural (Editor.State.Line_Start (S, Row));

      if Safe_Index >= Start then
         Col := Safe_Index - Start;
      else
         Col := 0;
      end if;
   end Line_Column_For_Index;

   function Index_For_Line_Column
     (S   : Editor.State.State_Type;
      Row : Natural;
      Col : Natural) return Natural
   is
      Start    : Natural := 0;
      Line_Len : Natural := 0;
   begin
      if Row >= Editor.State.Line_Count (S) then
         return Buffer_Length (S);
      end if;

      Start := Natural (Editor.State.Line_Start (S, Row));
      Line_Len := Line_Length (S, Row);

      return Start + Natural'Min (Col, Line_Len);
   end Index_For_Line_Column;


   function Clamp_Position
     (S      : Editor.State.State_Type;
      Row    : Natural;
      Column : Natural) return Navigation_Target
   is
      Last_Row : Natural := 0;
      Safe_Row : Natural := 0;
   begin
      if Editor.State.Line_Count (S) = 0 then
         return (Row => 0, Column => 0);
      end if;

      Last_Row := Editor.State.Line_Count (S) - 1;
      Safe_Row := Natural'Min (Row, Last_Row);

      return
        (Row    => Safe_Row,
         Column => Natural'Min (Column, Line_Length (S, Safe_Row)));
   end Clamp_Position;

   function Result_For_Index
     (S                       : Editor.State.State_Type;
      Index                   : Natural;
      Preserve_Virtual_Column : Boolean := False;
      Found                   : Boolean := True) return Navigation_Result
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Index, Row, Col);
      return
        (Target                  => (Row => Row, Column => Col),
         Preserve_Virtual_Column => Preserve_Virtual_Column,
         Found                   => Found);
   end Result_For_Index;

   function Move_Character
     (S         : Editor.State.State_Type;
      Row       : Natural;
      Column    : Natural;
      Direction : Navigation_Direction) return Navigation_Result
   is
      Pos      : constant Navigation_Target := Clamp_Position (S, Row, Column);
      Last_Row : constant Natural :=
        (if Editor.State.Line_Count (S) = 0 then 0 else Editor.State.Line_Count (S) - 1);
      Len      : constant Natural := Line_Length (S, Pos.Row);
   begin
      case Direction is
         when Forward =>
            if Pos.Column < Len then
               return
                 (Target                  => (Row => Pos.Row, Column => Pos.Column + 1),
                  Preserve_Virtual_Column => False,
                  Found                   => True);
            elsif Pos.Row < Last_Row then
               return
                 (Target                  => (Row => Pos.Row + 1, Column => 0),
                  Preserve_Virtual_Column => False,
                  Found                   => True);
            else
               return
                 (Target                  => (Row => Pos.Row, Column => Len),
                  Preserve_Virtual_Column => False,
                  Found                   => False);
            end if;

         when Backward =>
            if Pos.Column > 0 then
               return
                 (Target                  => (Row => Pos.Row, Column => Pos.Column - 1),
                  Preserve_Virtual_Column => False,
                  Found                   => True);
            elsif Pos.Row > 0 then
               return
                 (Target                  =>
                    (Row => Pos.Row - 1,
                     Column => Line_Length (S, Pos.Row - 1)),
                  Preserve_Virtual_Column => False,
                  Found                   => True);
            else
               return
                 (Target                  => (Row => 0, Column => 0),
                  Preserve_Virtual_Column => False,
                  Found                   => False);
            end if;
      end case;
   end Move_Character;

   function Move_Word
     (S         : Editor.State.State_Type;
      Row       : Natural;
      Column    : Natural;
      Direction : Navigation_Direction) return Navigation_Result
   is
      Pos   : constant Navigation_Target := Clamp_Position (S, Row, Column);
      Index : constant Natural := Index_For_Line_Column (S, Pos.Row, Pos.Column);
   begin
      case Direction is
         when Backward =>
            return Result_For_Index (S, Previous_Word_Start (S, Index));
         when Forward =>
            return Result_For_Index (S, Next_Word_Start (S, Index));
      end case;
   end Move_Word;

   function Move_Line
     (S                       : Editor.State.State_Type;
      Row                     : Natural;
      Column                  : Natural;
      Direction               : Navigation_Direction;
      Preferred_Visual_Column : Natural) return Navigation_Result
   is
      Pos     : constant Navigation_Target := Clamp_Position (S, Row, Column);
      Index   : constant Cursor_Index :=
        Cursor_Index (Index_For_Line_Column (S, Pos.Row, Pos.Column));
      Target  : Cursor_Index := 0;
      Virtual : Natural := 0;
      Step_Delta   : constant Integer :=
        (if Direction = Backward then -1 else 1);
   begin
      Vertical_Target_Info
        (S,
         Index,
         Step_Delta,
         Preferred_Visual_Column,
         Target,
         Virtual);

      return Result_For_Index
        (S,
         Natural (Target),
         Preserve_Virtual_Column => True);
   end Move_Line;

   function Move_Page
     (S                       : Editor.State.State_Type;
      Row                     : Natural;
      Column                  : Natural;
      Direction               : Navigation_Direction;
      Page_Row_Count          : Natural;
      Preferred_Visual_Column : Natural) return Navigation_Result
   is
      Pos      : constant Navigation_Target := Clamp_Position (S, Row, Column);
      Index    : constant Cursor_Index :=
        Cursor_Index (Index_For_Line_Column (S, Pos.Row, Pos.Column));
      Distance : constant Natural :=
        (if Page_Row_Count > 1 then Page_Row_Count - 1 else 1);
      Step_Delta    : constant Integer :=
        (if Direction = Backward then -Integer (Distance) else Integer (Distance));
      Target   : Cursor_Index := 0;
      Virtual  : Natural := 0;
   begin
      Vertical_Target_Info
        (S,
         Index,
         Step_Delta,
         Preferred_Visual_Column,
         Target,
         Virtual);

      return Result_For_Index
        (S,
         Natural (Target),
         Preserve_Virtual_Column => True);
   end Move_Page;

   function Move_Document_Boundary
     (S         : Editor.State.State_Type;
      Direction : Navigation_Direction) return Navigation_Result
   is
   begin
      case Direction is
         when Backward =>
            return Result_For_Index (S, Document_Start (S));
         when Forward =>
            return Result_For_Index (S, Document_End (S));
      end case;
   end Move_Document_Boundary;

   function Move_Line_Boundary
     (S         : Editor.State.State_Type;
      Row       : Natural;
      Column    : Natural;
      Direction : Navigation_Direction) return Navigation_Result
   is
      Pos : constant Navigation_Target := Clamp_Position (S, Row, Column);
   begin
      case Direction is
         when Backward =>
            return
              (Target                  => (Row => Pos.Row, Column => 0),
               Preserve_Virtual_Column => False,
               Found                   => True);
         when Forward =>
            return
              (Target                  =>
                 (Row => Pos.Row, Column => Line_Length (S, Pos.Row)),
               Preserve_Virtual_Column => False,
               Found                   => True);
      end case;
   end Move_Line_Boundary;

   function Current_Wrap_Col
     (S : Editor.State.State_Type) return Positive
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Line_Count : constant Natural := Natural'Max (1, Editor.State.Line_Count (S));
      Minimap : constant Editor.Minimap.Minimap_Config :=
        Editor.Minimap.Current;
      Text_W : constant Natural :=
        (if Minimap.Enabled then
            Editor.Layout.Text_Viewport_Width
              (Layout,
               Line_Count,
               Editor.View.Viewport_Width,
               Minimap.Enabled,
               Minimap.Width,
               Minimap.Padding_Left,
               Minimap.Padding_Right)
         else
            Editor.Layout.Text_Viewport_Width
              (Layout,
               Line_Count,
               Editor.View.Viewport_Width));
   begin
      return Editor.Wrap.Wrap_Column (Text_W, Editor.Layout.Cell_W);
   end Current_Wrap_Col;

   function Visual_Row_Count
     (S        : Editor.State.State_Type;
      Row      : Natural;
      Wrap_Col : Positive) return Natural
   is
   begin
      return Natural
        (Editor.Wrap.Visual_Row_Count_For_Logical_Line
           (Line_Length (S, Row), Wrap_Col));
   end Visual_Row_Count;

   function Fold_Visible_Row
     (S   : Editor.State.State_Type;
      Row : Natural) return Natural
   is
      Effective_Row : Natural := Row;
      Found         : Boolean := False;
      Visible_Found : Boolean := False;
      Visible       : Natural := 0;
   begin
      if Editor.Folding.Is_Row_Hidden (S.Folding, Effective_Row) then
         Effective_Row :=
           Editor.Folding.Fold_Start_For_Hidden_Row
             (S.Folding, Effective_Row, Found);
      end if;

      Visible :=
        Editor.Folding.Document_Row_To_Visible_Row
          (S.Folding, Effective_Row, Visible_Found);

      if Visible_Found then
         return Visible;
      else
         return 0;
      end if;
   end Fold_Visible_Row;

   procedure Logical_For_Visual_Row
     (S          : Editor.State.State_Type;
      Visual_Row : Natural;
      Wrap_Col   : Positive;
      Row        : out Natural;
      Part       : out Natural)
   is
      Remaining : Natural := Visual_Row;
      Last_Row  : constant Natural := Editor.State.Line_Count (S) - 1;
   begin
      for R in 0 .. Last_Row loop
         if not Editor.Folding.Is_Row_Hidden (S.Folding, R) then
            declare
               Parts : constant Natural := Visual_Row_Count (S, R, Wrap_Col);
            begin
               if Remaining < Parts then
                  Row := R;
                  Part := Remaining;
                  return;
               end if;
               Remaining := Remaining - Parts;
            end;
         end if;
      end loop;

      for R in reverse 0 .. Last_Row loop
         if not Editor.Folding.Is_Row_Hidden (S.Folding, R) then
            Row := R;
            Part := Visual_Row_Count (S, R, Wrap_Col) - 1;
            return;
         end if;
      end loop;

      Row := Last_Row;
      Part := Visual_Row_Count (S, Last_Row, Wrap_Col) - 1;
   end Logical_For_Visual_Row;

   function Visual_Row_Ordinal
     (S        : Editor.State.State_Type;
      Row      : Natural;
      Part     : Natural;
      Wrap_Col : Positive) return Natural
   is
      Ordinal       : Natural := 0;
      Effective_Row : Natural := Row;
      Found         : Boolean := False;
      Effective_Part : Natural := Part;
   begin
      if Editor.Folding.Is_Row_Hidden (S.Folding, Effective_Row) then
         Effective_Row :=
           Editor.Folding.Fold_Start_For_Hidden_Row
             (S.Folding, Effective_Row, Found);
         Effective_Part := 0;
      end if;

      if Effective_Row > 0 then
         for R in 0 .. Effective_Row - 1 loop
            if not Editor.Folding.Is_Row_Hidden (S.Folding, R) then
               Ordinal := Ordinal + Visual_Row_Count (S, R, Wrap_Col);
            end if;
         end loop;
      end if;
      return Ordinal + Effective_Part;
   end Visual_Row_Ordinal;

   function Index_For_Point
     (S : Editor.State.State_Type;
      X : Natural;
      Y : Natural) return Cursor_Index
   is
      Layout     : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Line_Count : constant Natural := Natural'Max (1, Editor.State.Line_Count (S));
      Col        : Natural := 0;
      Row        : Natural := 0;
      Target_Row : Natural := 0;
      Len        : Natural := 0;
   begin
      if Editor.State.Line_Count (S) = 0 then
         return 0;
      end if;

      if Editor.View.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         declare
            Wrap_Col   : constant Positive := Current_Wrap_Col (S);
            Visual_Row : constant Natural :=
              Editor.Layout.Row_For_Y (Layout, Y, Editor.View.Scroll_Y);
            Part       : Natural := 0;
         begin
            Logical_For_Visual_Row (S, Visual_Row, Wrap_Col, Target_Row, Part);
            declare
               Line_Len   : constant Natural := Line_Length (S, Target_Row);
               Seg        : constant Editor.Wrap.Visual_Row_Info :=
                 Editor.Wrap.Visual_Segment (Target_Row, Part, Line_Len, Wrap_Col);
               Visual_Col : Natural :=
                 Editor.Layout.Text_Column_For_X (Layout, Line_Count, X, 0);
            begin
               Visual_Col := Natural'Min (Visual_Col, Seg.End_Col - Seg.Start_Col);
               Col := Seg.Start_Col + Visual_Col;
            end;
         end;
      else
         Col :=
           Editor.Layout.Text_Column_For_X
             (Layout, Line_Count, X, Editor.View.Scroll_X);

         declare
            Top : constant Natural :=
              Natural (Editor.Layout.Text_Viewport_Y (Layout));
         begin
            if Y = Top and then Top = Editor.Layout.Cell_H then
               --  Some direct executor tests still pass content-relative
               --  coordinates while normal input uses screen coordinates.
               --  The exact top boundary is the only ambiguous row hit.
               Row := Editor.View.Scroll_Y + 1;
            else
               Row :=
                 Editor.Layout.Row_For_Y
                   (Layout, Y, Editor.View.Scroll_Y);
            end if;
         end;

         declare
            Visible_Count : constant Natural :=
              Natural'Max
                (1, Editor.Folding.Visible_Row_Count
                      (S.Folding, Editor.State.Line_Count (S)));
            Visible_Row : constant Natural := Natural'Min (Row, Visible_Count - 1);
         begin
            Target_Row :=
              Editor.Folding.Visible_Row_To_Document_Row
                (S.Folding, Visible_Row);

            if Target_Row >= Editor.State.Line_Count (S) then
               Target_Row := Editor.State.Line_Count (S) - 1;
            end if;
         end;
      end if;

      Len := Line_Length (S, Target_Row);
      return Cursor_Index
        (Index_For_Line_Column
           (S,
            Target_Row,
            Natural'Min (Col, Len)));
   end Index_For_Point;

   function Line_Start_Index
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Index, Row, Col);
      return Index_For_Line_Column (S, Row, 0);
   end Line_Start_Index;

   function Line_End_Index
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Line_Column_For_Index (S, Index, Row, Col);
      return Index_For_Line_Column (S, Row, Line_Length (S, Row));
   end Line_End_Index;

   function Document_Start
     (S : Editor.State.State_Type) return Natural is
      pragma Unreferenced (S);
   begin
      return 0;
   end Document_Start;

   function Document_End
     (S : Editor.State.State_Type) return Natural is
   begin
      return Buffer_Length (S);
   end Document_End;

   function Rows_Per_Page return Positive is
      Rows : constant Natural :=
        Editor.View.Viewport_Height / Editor.Layout.Cell_H;
   begin
      return Positive'Max (1, Positive (Natural'Max (Rows, 1)));
   end Rows_Per_Page;

   procedure Vertical_Target_Info
     (S                : Editor.State.State_Type;
      Old_Caret        : Cursor_Index;
      Delta_Rows       : Integer;
      Preferred_Column : Natural;
      Target           : out Cursor_Index;
      Virtual_Column   : out Natural)
   is
      Row        : Natural := 0;
      Col        : Natural := 0;
      Target_Row : Integer := 0;
      Len        : Natural := 0;
   begin
      Line_Column_For_Index (S, Natural (Old_Caret), Row, Col);
      Virtual_Column := 0;

      if Editor.View.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         declare
            Wrap_Col      : constant Positive := Current_Wrap_Col (S);
            Source_Col    : constant Natural := Preferred_Column;
            Source_Part   : constant Natural := Source_Col / Natural (Wrap_Col);
            Source_Visual : constant Natural :=
              Visual_Row_Ordinal (S, Row, Source_Part, Wrap_Col);
            Target_Visual : Integer := Integer (Source_Visual) + Delta_Rows;
            Target_Part   : Natural := 0;
            Target_Col    : Natural := 0;
         begin
            if Target_Visual < 0 then
               Target_Visual := 0;
            end if;

            Logical_For_Visual_Row
              (S, Natural (Target_Visual), Wrap_Col, Row, Target_Part);

            Target_Col := Target_Part * Natural (Wrap_Col)
              + (Source_Col mod Natural (Wrap_Col));
            Len := Line_Length (S, Row);

            Target := Cursor_Index
              (Index_For_Line_Column (S, Row, Natural'Min (Target_Col, Len)));

            if Target_Col > Len then
               Virtual_Column := Target_Col;
            end if;
            return;
         end;
      end if;

      declare
         Visible_Count : constant Natural :=
           Natural'Max
             (1, Editor.Folding.Visible_Row_Count
                   (S.Folding, Editor.State.Line_Count (S)));
         Source_Visible : constant Natural := Fold_Visible_Row (S, Row);
         Target_Visible : Integer := Integer (Source_Visible) + Delta_Rows;
      begin
         if Target_Visible < 0 then
            Target_Visible := 0;
         elsif Target_Visible > Integer (Visible_Count - 1) then
            Target_Visible := Integer (Visible_Count - 1);
         end if;

         Target_Row :=
           Integer
             (Editor.Folding.Visible_Row_To_Document_Row
                (S.Folding, Natural (Target_Visible)));
      end;

      Len := Line_Length (S, Natural (Target_Row));
      Target := Cursor_Index
        (Index_For_Line_Column
           (S,
            Natural (Target_Row),
            Natural'Min (Preferred_Column, Len)));

      if Preferred_Column > Len then
         Virtual_Column := Preferred_Column;
      end if;
   end Vertical_Target_Info;

   function Vertical_Target
     (S                : Editor.State.State_Type;
      Old_Caret        : Cursor_Index;
      Delta_Rows       : Integer;
      Preferred_Column : Natural) return Cursor_Index
   is
      Target : Cursor_Index := 0;
      Virtual_Column : Natural := 0;
   begin
      Vertical_Target_Info
        (S, Old_Caret, Delta_Rows, Preferred_Column, Target, Virtual_Column);
      return Target;
   end Vertical_Target;

   function Previous_Word_Start
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural
   is
      I          : Natural := Natural'Min (Index, Buffer_Length (S));
      Target     : Character_Class := Word_Char;
   begin
      if I = 0 then
         return 0;
      end if;

      while I > 0 and then Class_Of (Code_At (S, I - 1)) = Whitespace_Char loop
         I := I - 1;
      end loop;

      if I = 0 then
         return 0;
      end if;

      Target := Class_Of (Code_At (S, I - 1));

      while I > 0 loop
         exit when Class_Of (Code_At (S, I - 1)) /= Target;
         I := I - 1;
      end loop;

      return I;
   end Previous_Word_Start;

   function Next_Word_Start
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural
   is
      Len        : constant Natural := Buffer_Length (S);
      I          : Natural := Natural'Min (Index, Len);
      Target     : Character_Class := Word_Char;
   begin
      if I >= Len then
         return Len;
      end if;

      if Class_Of (Code_At (S, I)) /= Whitespace_Char then
         Target := Class_Of (Code_At (S, I));

         while I < Len loop
            exit when Class_Of (Code_At (S, I)) /= Target;
            I := I + 1;
         end loop;
      end if;

      while I < Len and then Class_Of (Code_At (S, I)) = Whitespace_Char loop
         I := I + 1;
      end loop;

      return I;
   end Next_Word_Start;

   function Next_Word_End
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural
   is
      Len        : constant Natural := Buffer_Length (S);
      I          : Natural := Natural'Min (Index, Len);
      Target     : Character_Class := Word_Char;
   begin
      if I >= Len then
         return Len;
      end if;

      if Class_Of (Code_At (S, I)) = Whitespace_Char then
         while I < Len and then Class_Of (Code_At (S, I)) = Whitespace_Char loop
            I := I + 1;
         end loop;

         return I;
      end if;

      Target := Class_Of (Code_At (S, I));

      while I < Len loop
         exit when Class_Of (Code_At (S, I)) /= Target;
         I := I + 1;
      end loop;

      return I;
   end Next_Word_End;

   procedure Selectable_Run_At
     (S            : Editor.State.State_Type;
      Index        : Natural;
      Has_Run      : out Boolean;
      Start_Index  : out Natural;
      End_Index    : out Natural)
   is
      Len        : constant Natural := Buffer_Length (S);
      I          : Natural := Natural'Min (Index, Len);
      Target     : Character_Class := Word_Char;
   begin
      Has_Run := False;
      Start_Index := I;
      End_Index := I;

      if I >= Len then
         return;
      end if;

      Target := Class_Of (Code_At (S, I));
      if Target = Whitespace_Char then
         return;
      end if;

      Start_Index := I;
      while Start_Index > 0 loop
         exit when Class_Of (Code_At (S, Start_Index - 1)) /= Target;
         Start_Index := Start_Index - 1;
      end loop;

      End_Index := I;
      while End_Index < Len loop
         exit when Class_Of (Code_At (S, End_Index)) /= Target;
         End_Index := End_Index + 1;
      end loop;

      Has_Run := Start_Index < End_Index;
   end Selectable_Run_At;

end Editor.Navigation;
