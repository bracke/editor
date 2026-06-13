with Text_Buffer;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use Ada.Containers;
with Editor.State;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors;  use Editor.Cursors;
with Editor.Navigation; use Editor.Navigation;
with Editor.Executor;
with Editor.Executor.History;
with Editor.Rectangle_Selection;
with Editor.Selection;
with Editor.Unicode;
with Editor.UTF8;

package body Editor.Executor.Edits is

   use type Editor.Selection.Selection_Validation_Status;

   use Cursors_Vector;

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index;

   function Empty_Text return Unbounded_String;

   function One_Line_Vector
     (Text : Unbounded_String) return Editor.Commands.Text_Vectors.Vector;

   function Any_Selection
     (S : Editor.State.State_Type) return Boolean;

   procedure Replace_Selected_Carets
     (S           : in out Editor.State.State_Type;
      Lines       : Editor.Commands.Text_Vectors.Vector;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command);

   procedure Collapse_To_One_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index);

   function Text_Range
     (S     : Editor.State.State_Type;
      First : Natural;
      Last  : Natural) return Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Visit
        (Index : Natural;
         Code  : Editor.Unicode.Code_Point)
      is
         pragma Unreferenced (Index);
      begin
         Append (Result, Editor.UTF8.Encode_UTF8 (Code));
      end Visit;
   begin
      if Last <= First then
         return Result;
      end if;

      Text_Buffer.For_Each_Code_Point_Range
        (S.Buffer, First, Last, Visit'Access);
      return Result;
   end Text_Range;

   function Has_Following_Terminator
     (S       : Editor.State.State_Type;
      End_Pos : Natural) return Boolean
   is
   begin
      return End_Pos < Text_Buffer.Length (S.Buffer)
        and then Text_Buffer.Character_At (S.Buffer, End_Pos) = ASCII.LF;
   end Has_Following_Terminator;



   type Canonical_Selection_Delete_Range is record
      Has_Range : Boolean := False;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   end record;

   function Active_Selection_Delete_Range
     (S      : Editor.State.State_Type;
      Status : out Editor.Selection.Selection_Validation_Status)
      return Canonical_Selection_Delete_Range
   is
      Selection_Range : Editor.Selection.Active_Selection_Range;
      Result          : Canonical_Selection_Delete_Range;
   begin
      Status := Editor.Selection.Validate_Active_Selection_Range
        (S, Selection_Range);

      if Status /= Editor.Selection.Selection_Ok then
         return Result;
      end if;

      --  Selection Delete is a linear active-buffer command.  Do not
      --  reinterpret rectangular or multi-caret projections as one rendered
      --  text span; those features have their own command domains and must
      --  not leak visual selection state into selected-text deletion.
      if S.Rect_Select_Active or else Natural (S.Carets.Length) /= 1 then
         Status := Editor.Selection.Selection_Invalid;
         return Result;
      end if;

      Result.Has_Range := True;
      Result.Start_Pos := Natural (Selection_Range.Low);
      Result.End_Pos := Natural (Selection_Range.High);

      return Result;
   end Active_Selection_Delete_Range;

   function Valid_Canonical_Selection_Delete_Range
     (S     : Editor.State.State_Type;
      Selection_Range : Canonical_Selection_Delete_Range) return Boolean
   is
      Len : constant Natural := Text_Buffer.Length (S.Buffer);
   begin
      return Selection_Range.Has_Range
        and then Selection_Range.Start_Pos < Selection_Range.End_Pos
        and then Selection_Range.End_Pos <= Len;
   end Valid_Canonical_Selection_Delete_Range;

   procedure Apply_Canonical_Range_Delete_As_Undoable_Mutation
     (S           : in out Editor.State.State_Type;
      Start_Pos   : Cursor_Index;
      End_Pos     : Cursor_Index;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
      L    : constant Cursor_Index := Cursor_Index'Min (Start_Pos, End_Pos);
      H    : constant Cursor_Index := Cursor_Index'Max (Start_Pos, End_Pos);
      Span : constant Natural := Natural (H - L);
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Append_Replace_Op (Forward_Cmd, L, Span, Empty_Text);

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      Collapse_To_One_Caret (S, L);
      New_Caret := Safe_Caret (S);
   end Apply_Canonical_Range_Delete_As_Undoable_Mutation;

   procedure Apply_Selection_Delete_As_Undoable_Mutation
     (S           : in out Editor.State.State_Type;
      Selection_Range       : Canonical_Selection_Delete_Range;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
   begin
      Apply_Canonical_Range_Delete_As_Undoable_Mutation
        (S           => S,
         Start_Pos   => Cursor_Index (Selection_Range.Start_Pos),
         End_Pos     => Cursor_Index (Selection_Range.End_Pos),
         New_Caret   => New_Caret,
         Forward_Cmd => Forward_Cmd);
   end Apply_Selection_Delete_As_Undoable_Mutation;


   type Canonical_Word_Delete_Range is record
      Has_Range : Boolean := False;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   end record;

   type Canonical_Word_Delete_Char_Class is (Word_Delete_Word, Word_Delete_Whitespace, Word_Delete_Other);

   function Is_Canonical_Word_Delete_Word_Character
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
   end Is_Canonical_Word_Delete_Word_Character;

   function Is_Canonical_Word_Delete_Whitespace_Character
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
         return Ch = ' ' or else Ch = ASCII.HT or else Ch = ASCII.LF or else Ch = ASCII.CR;
      end;
   end Is_Canonical_Word_Delete_Whitespace_Character;

   function Canonical_Word_Delete_Character_Class
     (S     : Editor.State.State_Type;
      Index : Natural) return Canonical_Word_Delete_Char_Class
   is
      Code : constant Editor.Unicode.Code_Point :=
        Text_Buffer.Code_Point_At (S.Buffer, Index);
   begin
      if Is_Canonical_Word_Delete_Word_Character (Code) then
         return Word_Delete_Word;
      elsif Is_Canonical_Word_Delete_Whitespace_Character (Code) then
         return Word_Delete_Whitespace;
      else
         return Word_Delete_Other;
      end if;
   end Canonical_Word_Delete_Character_Class;

   function Previous_Word_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Word_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      I      : Natural := Natural'Min (Caret, Len);
      Result : Canonical_Word_Delete_Range;
      Target : Canonical_Word_Delete_Char_Class := Word_Delete_Other;
   begin
      Result.End_Pos := I;

      if I = 0 or else Len = 0 then
         return Result;
      end if;

      if Canonical_Word_Delete_Character_Class (S, I - 1) = Word_Delete_Whitespace then
         while I > 0 and then Canonical_Word_Delete_Character_Class (S, I - 1) = Word_Delete_Whitespace loop
            I := I - 1;
         end loop;

         while I > 0 and then Canonical_Word_Delete_Character_Class (S, I - 1) = Word_Delete_Word loop
            I := I - 1;
         end loop;
      else
         Target := Canonical_Word_Delete_Character_Class (S, I - 1);
         while I > 0 and then Canonical_Word_Delete_Character_Class (S, I - 1) = Target loop
            I := I - 1;
         end loop;
      end if;

      if I < Result.End_Pos then
         Result.Has_Range := True;
         Result.Start_Pos := I;
      end if;

      return Result;
   end Previous_Word_Delete_Range;

   function Next_Word_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Word_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      I      : Natural := Natural'Min (Caret, Len);
      Result : Canonical_Word_Delete_Range;
      Target : Canonical_Word_Delete_Char_Class := Word_Delete_Other;
   begin
      Result.Start_Pos := I;
      Result.End_Pos := I;

      if I >= Len or else Len = 0 then
         return Result;
      end if;

      if Canonical_Word_Delete_Character_Class (S, I) = Word_Delete_Whitespace then
         while I < Len and then Canonical_Word_Delete_Character_Class (S, I) = Word_Delete_Whitespace loop
            I := I + 1;
         end loop;

         while I < Len and then Canonical_Word_Delete_Character_Class (S, I) = Word_Delete_Word loop
            I := I + 1;
         end loop;
      else
         Target := Canonical_Word_Delete_Character_Class (S, I);
         while I < Len and then Canonical_Word_Delete_Character_Class (S, I) = Target loop
            I := I + 1;
         end loop;
      end if;

      if I > Result.Start_Pos then
         Result.Has_Range := True;
         Result.End_Pos := I;
      end if;

      return Result;
   end Next_Word_Delete_Range;

   function Valid_Canonical_Word_Delete_Range
     (S     : Editor.State.State_Type;
      Selection_Range : Canonical_Word_Delete_Range) return Boolean
   is
      Len : constant Natural := Text_Buffer.Length (S.Buffer);
   begin
      return Selection_Range.Has_Range
        and then Selection_Range.Start_Pos < Selection_Range.End_Pos
        and then Selection_Range.End_Pos <= Len;
   end Valid_Canonical_Word_Delete_Range;

   procedure Apply_Word_Delete_As_Undoable_Mutation
     (S           : in out Editor.State.State_Type;
      Selection_Range       : Canonical_Word_Delete_Range;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Selection_Range.Start_Pos),
         Selection_Range.End_Pos - Selection_Range.Start_Pos,
         Empty_Text);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      --  Both delete-previous and delete-next normalize to the deletion start.
      --  The command-level Undo/Redo capture, redo invalidation, dirty tracking,
      --  and Find/Replace invalidation remain owned by the canonical Executor
      --  edit pipeline around this mutation helper.
      Collapse_To_One_Caret (S, Cursor_Index (Selection_Range.Start_Pos));
      New_Caret := Safe_Caret (S);
   end Apply_Word_Delete_As_Undoable_Mutation;



   type Canonical_Character_Delete_Range is record
      Has_Range : Boolean := False;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   end record;

   --  Phase 406 reliability: a character delete range is exactly one
   --  canonical buffer text unit adjacent to the caret.  This deliberately
   --  uses Text_Buffer positions only; rendering, visual wrapping, glyph
   --  shaping, settings, syntax, Clipboard state, and Word/Line command
   --  helpers are outside the Character Delete boundary.
   function Previous_Character_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Character_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      Pos    : constant Natural := Natural'Min (Caret, Len);
      Result : Canonical_Character_Delete_Range;
   begin
      if Pos = 0 or else Len = 0 then
         return Result;
      end if;

      Result.Has_Range := True;
      Result.Start_Pos := Pos - 1;
      Result.End_Pos := Pos;
      return Result;
   end Previous_Character_Delete_Range;

   function Next_Character_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Character_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      Pos    : constant Natural := Natural'Min (Caret, Len);
      Result : Canonical_Character_Delete_Range;
   begin
      if Pos >= Len or else Len = 0 then
         return Result;
      end if;

      Result.Has_Range := True;
      Result.Start_Pos := Pos;
      Result.End_Pos := Pos + 1;
      return Result;
   end Next_Character_Delete_Range;

   function Valid_Canonical_Character_Delete_Range
     (S     : Editor.State.State_Type;
      Selection_Range : Canonical_Character_Delete_Range) return Boolean
   is
      Len : constant Natural := Text_Buffer.Length (S.Buffer);
   begin
      return Selection_Range.Has_Range
        and then Selection_Range.Start_Pos < Selection_Range.End_Pos
        and then Selection_Range.End_Pos <= Len;
   end Valid_Canonical_Character_Delete_Range;

   procedure Apply_Character_Delete_As_Undoable_Mutation
     (S           : in out Editor.State.State_Type;
      Selection_Range       : Canonical_Character_Delete_Range;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Selection_Range.Start_Pos),
         Selection_Range.End_Pos - Selection_Range.Start_Pos,
         Empty_Text);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      Collapse_To_One_Caret (S, Cursor_Index (Selection_Range.Start_Pos));
      New_Caret := Safe_Caret (S);
   end Apply_Character_Delete_As_Undoable_Mutation;

   type Line_Join_Boundary_Range is record
      Has_Next_Line : Boolean := False;
      Row           : Natural := 0;
      Column        : Natural := 0;
      Current_Start : Natural := 0;
      Current_End   : Natural := 0;
      Next_Start    : Natural := 0;
      Next_End      : Natural := 0;
      Boundary_Pos  : Natural := 0;
   end record;

   procedure Current_Line_Bounds
     (S         : Editor.State.State_Type;
      Row       : out Natural;
      Col       : out Natural;
      Start_Pos : out Natural;
      End_Pos   : out Natural)
   is
   begin
      Line_Column_For_Index (S, Natural (Safe_Caret (S)), Row, Col);
      Start_Pos := Index_For_Line_Column (S, Row, 0);
      End_Pos := Start_Pos + Line_Length (S, Row);
   end Current_Line_Bounds;

   function Current_Line_And_Next_Line_Join_Range
     (S : Editor.State.State_Type) return Line_Join_Boundary_Range
   is
      Result     : Line_Join_Boundary_Range;
      Line_Count : constant Natural := Editor.State.Line_Count (S);
   begin
      if S.Carets.Length = 0
        or else Text_Buffer.Length (S.Buffer) = 0
        or else Line_Count <= 1
      then
         return Result;
      end if;

      Current_Line_Bounds
        (S, Result.Row, Result.Column, Result.Current_Start, Result.Current_End);

      if Result.Row + 1 >= Line_Count
        or else not Has_Following_Terminator (S, Result.Current_End)
      then
         return Result;
      end if;

      Result.Has_Next_Line := True;
      Result.Boundary_Pos := Result.Current_End;
      Result.Next_Start := Result.Current_End + 1;
      Result.Next_End := Result.Next_Start + Line_Length (S, Result.Row + 1);
      return Result;
   end Current_Line_And_Next_Line_Join_Range;

   procedure Set_Single_Caret
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural)
   is
      Safe_Row : Natural := Row;
      Line_Len : Natural := 0;
      Pos      : Cursor_Index := 0;
   begin
      if Editor.State.Line_Count (S) = 0 then
         Safe_Row := 0;
      else
         Safe_Row := Natural'Min (Safe_Row, Editor.State.Line_Count (S) - 1);
      end if;

      Line_Len := Line_Length (S, Safe_Row);
      Pos := Cursor_Index
        (Index_For_Line_Column (S, Safe_Row, Natural'Min (Column, Line_Len)));
      Collapse_To_One_Caret (S, Pos);
   end Set_Single_Caret;

   procedure Perform_Delete_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Del_Start : Natural := 0;
      Del_End   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);

      if Has_Following_Terminator (S, End_Pos) then
         Del_Start := Start_Pos;
         Del_End := End_Pos + 1;
      elsif Start_Pos > 0 and then Row > 0 then
         Del_Start := Start_Pos - 1;
         Del_End := End_Pos;
      else
         Del_Start := Start_Pos;
         Del_End := End_Pos;
      end if;

      if Del_End <= Del_Start then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Append_Replace_Op
        (Forward_Cmd, Cursor_Index (Del_Start), Del_End - Del_Start,
         Null_Unbounded_String);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
      Set_Single_Caret
        (S,
         Natural'Min
           (Row,
            (if Editor.State.Line_Count (S) = 0
             then 0
             else Editor.State.Line_Count (S) - 1)),
         Col);
      New_Caret := Safe_Caret (S);
      Status := Line_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Current_Line;

   procedure Perform_Duplicate_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Insert_At : Natural := 0;
      Line_Text : Unbounded_String := Null_Unbounded_String;
      Insert_Text : Unbounded_String := Null_Unbounded_String;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Duplicate;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      Line_Text := Text_Range (S, Start_Pos, End_Pos);

      if Has_Following_Terminator (S, End_Pos) then
         Insert_At := End_Pos + 1;
         Insert_Text := Line_Text & To_Unbounded_String (String'(1 => ASCII.LF));
      else
         Insert_At := End_Pos;
         Insert_Text := To_Unbounded_String (String'(1 => ASCII.LF)) & Line_Text;
      end if;

      Append_Replace_Op
        (Forward_Cmd, Cursor_Index (Insert_At), 0, Insert_Text);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
      Set_Single_Caret (S, Row + 1, Col);
      New_Caret := Safe_Caret (S);
      Status := Line_Duplicated;
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Duplicate_Current_Line;

   procedure Perform_Move_Current_Line
     (S           : in out Editor.State.State_Type;
      Direction   : Integer;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Other_Row : Natural := 0;
      This_Text : Unbounded_String := Null_Unbounded_String;
      Other_Text : Unbounded_String := Null_Unbounded_String;
      First_Start : Natural := 0;
      Second_Start : Natural := 0;
      Second_End   : Natural := 0;
      Replacement  : Unbounded_String := Null_Unbounded_String;
      Line_Count   : Natural := Editor.State.Line_Count (S);
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 or else Line_Count <= 1 then
         if Direction < 0 then
            Status := Already_First_Line;
         else
            Status := Already_Last_Line;
         end if;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);

      if Direction < 0 then
         if Row = 0 then
            Status := Already_First_Line;
            New_Caret := Safe_Caret (S);
            return;
         end if;
         Other_Row := Row - 1;
      else
         if Row + 1 >= Line_Count then
            Status := Already_Last_Line;
            New_Caret := Safe_Caret (S);
            return;
         end if;
         Other_Row := Row + 1;
      end if;

      This_Text := Text_Range (S, Start_Pos, End_Pos);
      Other_Text := Text_Range
        (S, Index_For_Line_Column (S, Other_Row, 0),
         Index_For_Line_Column (S, Other_Row, 0) + Line_Length (S, Other_Row));

      if Direction < 0 then
         First_Start := Index_For_Line_Column (S, Other_Row, 0);
         Second_Start := Start_Pos;
         Second_End := End_Pos;
         Replacement := This_Text & To_Unbounded_String (String'(1 => ASCII.LF)) & Other_Text;
      else
         First_Start := Start_Pos;
         Second_Start := Index_For_Line_Column (S, Other_Row, 0);
         Second_End := Second_Start + Line_Length (S, Other_Row);
         Replacement := Other_Text & To_Unbounded_String (String'(1 => ASCII.LF)) & This_Text;
      end if;

      --  Adjacent logical lines are separated by exactly the canonical LF
      --  terminator represented by the active buffer model.  Replace the
      --  combined span once so undo/redo sees exactly one logical edit.
      Append_Replace_Op
        (Forward_Cmd, Cursor_Index (First_Start), Second_End - First_Start,
         Replacement);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
      Set_Single_Caret (S, Natural (Integer (Row) + Direction), Col);
      New_Caret := Safe_Caret (S);
      Status :=
        (if Direction < 0 then Line_Moved_Up else Line_Moved_Down);
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Move_Current_Line;

   function Canonical_Indentation_Unit return String is
   begin
      --  Phase 386: the indentation unit is intentionally local and
      --  hardcoded.  It is not a setting, workspace value, language policy,
      --  tab-width interpretation, or persistence domain.
      return "  ";
   end Canonical_Indentation_Unit;

   function Removable_Indentation_Prefix
     (S         : Editor.State.State_Type;
      Start_Pos : Natural;
      End_Pos   : Natural) return Natural
   is
      Unit : constant String := Canonical_Indentation_Unit;
      Available_Spaces : Natural := 0;
   begin
      if Start_Pos >= End_Pos then
         return 0;
      end if;

      if Text_Buffer.Character_At (S.Buffer, Start_Pos) = ASCII.HT then
         return 1;
      end if;

      while Start_Pos + Available_Spaces < End_Pos
        and then Text_Buffer.Character_At
          (S.Buffer, Start_Pos + Available_Spaces) = ' '
      loop
         Available_Spaces := Available_Spaces + 1;
      end loop;

      if Available_Spaces >= Unit'Length then
         return Unit'Length;
      else
         return Available_Spaces;
      end if;
   end Removable_Indentation_Prefix;

   procedure Perform_Indent_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Unit      : constant String := Canonical_Indentation_Unit;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Indent;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      Append_Replace_Op
        (Forward_Cmd, Cursor_Index (Start_Pos), 0, To_Unbounded_String (Unit));
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
      Set_Single_Caret (S, Row, Col + Unit'Length);
      New_Caret := Safe_Caret (S);
      Status := Line_Indented;
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Indent_Current_Line;

   procedure Perform_Outdent_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Remove    : Natural := 0;
      New_Col   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Outdent;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      Remove := Removable_Indentation_Prefix (S, Start_Pos, End_Pos);

      if Remove = 0 then
         Status := Nothing_To_Outdent;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Append_Replace_Op
        (Forward_Cmd, Cursor_Index (Start_Pos), Remove, Null_Unbounded_String);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      if Col > Remove then
         New_Col := Col - Remove;
      else
         New_Col := 0;
      end if;

      Set_Single_Caret (S, Row, New_Col);
      New_Caret := Safe_Caret (S);
      Status := Line_Outdented;
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Outdent_Current_Line;

   Canonical_Line_Comment_Insert_Marker : constant String := "-- ";
   Canonical_Line_Comment_Bare_Marker   : constant String := "--";

   function Canonical_Line_Comment_Marker return String is
   begin
      --  Phase 392: this remains the single production line-comment marker
      --  source.  It is intentionally hardcoded and isolated from settings,
      --  workspace values, file-extension policy, language services, render
      --  state, and persistence domains.
      return Canonical_Line_Comment_Insert_Marker;
   end Canonical_Line_Comment_Marker;

   function Canonical_Leading_Whitespace_Length
     (S         : Editor.State.State_Type;
      Start_Pos : Natural;
      End_Pos   : Natural) return Natural
   is
      Len : Natural := 0;
      Ch  : Character := ASCII.NUL;
   begin
      while Start_Pos + Len < End_Pos loop
         Ch := Text_Buffer.Character_At (S.Buffer, Start_Pos + Len);
         exit when Ch /= ' ' and then Ch /= ASCII.HT;
         Len := Len + 1;
      end loop;

      return Len;
   end Canonical_Leading_Whitespace_Length;

   type Line_Comment_State is (Line_Comment_Absent, Line_Comment_Present);

   function Line_Comment_Marker_Position
     (S         : Editor.State.State_Type;
      Start_Pos : Natural;
      End_Pos   : Natural) return Natural
   is
   begin
      --  Phase 390: all line-comment commands share the same canonical
      --  post-indentation marker position.  This deliberately ignores the
      --  caret column, selected text, rendered rows, visual wraps, syntax
      --  tokens, and language services.
      return Start_Pos
        + Canonical_Leading_Whitespace_Length (S, Start_Pos, End_Pos);
   end Line_Comment_Marker_Position;

   function Removable_Line_Comment_Marker_Length
     (S          : Editor.State.State_Type;
      Marker_Pos : Natural;
      End_Pos    : Natural) return Natural
   is
   begin
      --  Recognized removable markers are exactly the canonical inserted
      --  marker and the canonical bare marker at the already-computed
      --  post-leading-whitespace prefix position.  Callers are responsible
      --  for passing only that canonical position; internal markers elsewhere
      --  in the line are intentionally ignored.
      if Marker_Pos + Canonical_Line_Comment_Bare_Marker'Length > End_Pos then
         return 0;
      end if;

      for I in Canonical_Line_Comment_Bare_Marker'Range loop
         if Text_Buffer.Character_At
           (S.Buffer, Marker_Pos + I - Canonical_Line_Comment_Bare_Marker'First)
           /= Canonical_Line_Comment_Bare_Marker (I)
         then
            return 0;
         end if;
      end loop;

      if Marker_Pos + Canonical_Line_Comment_Insert_Marker'Length <= End_Pos
      then
         declare
            Full_Marker_Matches : Boolean := True;
         begin
            for I in Canonical_Line_Comment_Insert_Marker'Range loop
               if Text_Buffer.Character_At
                 (S.Buffer,
                  Marker_Pos + I - Canonical_Line_Comment_Insert_Marker'First)
                 /= Canonical_Line_Comment_Insert_Marker (I)
               then
                  Full_Marker_Matches := False;
               end if;
            end loop;

            if Full_Marker_Matches then
               return Canonical_Line_Comment_Insert_Marker'Length;
            end if;
         end;
      end if;

      return Canonical_Line_Comment_Bare_Marker'Length;
   end Removable_Line_Comment_Marker_Length;

   function Classify_Current_Line_Comment_State
     (S             : Editor.State.State_Type;
      Start_Pos     : Natural;
      End_Pos       : Natural;
      Marker_Pos    : out Natural;
      Marker_Length : out Natural) return Line_Comment_State
   is
   begin
      Marker_Pos := Line_Comment_Marker_Position (S, Start_Pos, End_Pos);
      Marker_Length :=
        Removable_Line_Comment_Marker_Length (S, Marker_Pos, End_Pos);

      if Marker_Length > 0 then
         return Line_Comment_Present;
      else
         return Line_Comment_Absent;
      end if;
   end Classify_Current_Line_Comment_State;

   procedure Perform_Comment_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Lead      : Natural := 0;
      Insert_At : Natural := 0;
      Existing  : Natural := 0;
      Marker    : constant String := Canonical_Line_Comment_Marker;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Comment;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      Insert_At := Line_Comment_Marker_Position (S, Start_Pos, End_Pos);
      Lead := Insert_At - Start_Pos;

      if Classify_Current_Line_Comment_State
        (S, Start_Pos, End_Pos, Insert_At, Existing) = Line_Comment_Present
      then
         Status := Line_Already_Commented;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Insert_At),
         0,
         To_Unbounded_String (Marker));
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      if Col >= Lead then
         Set_Single_Caret (S, Row, Col + Marker'Length);
      else
         Set_Single_Caret (S, Row, Col);
      end if;

      New_Caret := Safe_Caret (S);
      Status := Line_Commented;
      Changed := True;
   exception
      when others =>
         Status := Comment_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Comment_Current_Line;

   procedure Perform_Uncomment_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Lead      : Natural := 0;
      Marker_At : Natural := 0;
      Remove    : Natural := 0;
      New_Col   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Uncomment;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      if Classify_Current_Line_Comment_State
        (S, Start_Pos, End_Pos, Marker_At, Remove) = Line_Comment_Absent
      then
         Status := Nothing_To_Uncomment;
         New_Caret := Safe_Caret (S);
         return;
      end if;
      Lead := Marker_At - Start_Pos;

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Marker_At),
         Remove,
         Null_Unbounded_String);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      if Col > Lead + Remove then
         New_Col := Col - Remove;
      elsif Col >= Lead then
         New_Col := Lead;
      else
         New_Col := Col;
      end if;

      Set_Single_Caret (S, Row, New_Col);
      New_Caret := Safe_Caret (S);
      Status := Line_Uncommented;
      Changed := True;
   exception
      when others =>
         Status := Uncomment_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Uncomment_Current_Line;

   procedure Perform_Toggle_Current_Line_Comment
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Marker_At : Natural := 0;
      Remove    : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         Changed := False;
         Status := No_Caret_Location;
         New_Caret := 0;
         Forward_Cmd.Kind := Apply_Replace_Batch;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Changed := False;
         Status := Nothing_To_Comment;
         New_Caret := Safe_Caret (S);
         Forward_Cmd.Kind := Apply_Replace_Batch;
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      pragma Unreferenced (Row, Col);

      if Classify_Current_Line_Comment_State
        (S, Start_Pos, End_Pos, Marker_At, Remove) = Line_Comment_Present
      then
         Perform_Uncomment_Current_Line
           (S, New_Caret, Forward_Cmd, Changed, Status);
      else
         Perform_Comment_Current_Line
           (S, New_Caret, Forward_Cmd, Changed, Status);
      end if;
   exception
      when others =>
         Status := Comment_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
         Forward_Cmd.Kind := Apply_Replace_Batch;
   end Perform_Toggle_Current_Line_Comment;



   function Canonical_Line_Join_Separator return Unbounded_String is
   begin
      --  Phase 394: this separator is intentionally feature-local.  It is not
      --  read from Settings, written to Workspace, inferred from language
      --  syntax, or normalized by render/availability paths.
      return To_Unbounded_String (" ");
   end Canonical_Line_Join_Separator;

   function Join_Separator_For_Line_Texts
     (Left_Text  : Unbounded_String;
      Right_Text : Unbounded_String) return Unbounded_String
   is
   begin
      --  Phase 394 freezes the Phase 393 no-trim policy: remove exactly one
      --  logical line boundary and insert one ASCII space only when both
      --  logical line texts are non-empty.  Existing leading/trailing spaces
      --  and tabs remain user text and are preserved exactly.
      if Length (Left_Text) = 0 or else Length (Right_Text) = 0 then
         return Null_Unbounded_String;
      else
         return Canonical_Line_Join_Separator;
      end if;
   end Join_Separator_For_Line_Texts;

   procedure Perform_Join_Current_Line_With_Next
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range      : Line_Join_Boundary_Range;
      Left_Text  : Unbounded_String := Null_Unbounded_String;
      Right_Text : Unbounded_String := Null_Unbounded_String;
      Separator  : Unbounded_String := Null_Unbounded_String;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Join;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Current_Line_And_Next_Line_Join_Range (S);

      if not Selection_Range.Has_Next_Line then
         Status := Already_Last_Line;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Left_Text := Text_Range (S, Selection_Range.Current_Start, Selection_Range.Current_End);
      Right_Text := Text_Range (S, Selection_Range.Next_Start, Selection_Range.Next_End);
      Separator := Join_Separator_For_Line_Texts (Left_Text, Right_Text);

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Selection_Range.Boundary_Pos),
         1,
         Separator);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
      Set_Single_Caret (S, Selection_Range.Row, Selection_Range.Column);
      New_Caret := Safe_Caret (S);
      Status := Line_Joined;
      Changed := True;
   exception
      when others =>
         Status := Line_Join_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Join_Current_Line_With_Next;


   function Canonical_Line_Split_Boundary return Unbounded_String is
   begin
      --  Phase 397: line split inserts exactly one canonical logical line
      --  boundary.  This policy is feature-local and is not read from
      --  Settings, inferred from syntax, copied from indentation, or
      --  normalized by render/availability paths.
      return To_Unbounded_String (String'(1 => ASCII.LF));
   end Canonical_Line_Split_Boundary;

   procedure Perform_Split_Current_Line_At_Caret
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Column    : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Pos       : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         --  Phase 398 reliability: an injected/stale caret beyond EOF must
         --  not become an insertion point.  Fail without text/history changes,
         --  but leave the primary caret clamped to canonical EOF so later
         --  render/selection consumers do not observe an out-of-range caret.
         Collapse_To_One_Caret
           (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
         Status := Line_Split_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      --  Use the canonical logical-line helpers for the current caret.  The
      --  line text itself is not inspected; splitting is pure insertion at the
      --  caret and preserves all user text on both sides exactly.
      Current_Line_Bounds (S, Row, Column, Start_Pos, End_Pos);
      pragma Unreferenced (Column, Start_Pos, End_Pos);

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Pos),
         0,
         Canonical_Line_Split_Boundary);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      Set_Single_Caret (S, Row + 1, 0);
      New_Caret := Safe_Caret (S);
      Status := Line_Split;
      Changed := True;
   exception
      when others =>
         Status := Line_Split_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Split_Current_Line_At_Caret;





   function Is_Trailing_Whitespace_Character
     (Ch : Character) return Boolean
   is
   begin
      return Ch = ' ' or else Ch = ASCII.HT;
   end Is_Trailing_Whitespace_Character;

   procedure Perform_Trim_Trailing_Whitespace
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Len              : constant Natural := Text_Buffer.Length (S.Buffer);
      Line_Start       : Natural := 0;
      I                : Natural := 0;
      Line_End         : Natural := 0;
      Trim_Start       : Natural := 0;
      Old_Caret        : constant Cursor_Index := Safe_Caret (S);
      Row              : Natural := 0;
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Selection_Status : Editor.Selection.Selection_Validation_Status;
      First_Row        : Natural := 0;
      First_Col        : Natural := 0;
      Last_Row         : Natural := 0;
      Last_Col         : Natural := 0;
      Trim_Selected    : Boolean := False;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Len = 0 then
         Status := Nothing_To_Trim;
         New_Caret := Old_Caret;
         return;
      end if;

      --  Phase 540 completeness: a linear active selection narrows the
      --  command to the selected logical lines.  Empty selections keep the
      --  command as an active-buffer cleanup.  Rectangular and multi-caret
      --  selections are deliberately not reinterpreted as one linear trim
      --  region; those remain separate visual-selection command domains.
      Selection_Status := Editor.Selection.Validate_Active_Selection_Range
        (S, Selection_Range);
      if Selection_Status = Editor.Selection.Selection_Ok
        and then not S.Rect_Select_Active
        and then Natural (S.Carets.Length) = 1
      then
         Line_Column_For_Index
           (S, Natural (Selection_Range.Low), First_Row, First_Col);
         Line_Column_For_Index
           (S, Natural (Selection_Range.High - 1), Last_Row, Last_Col);
         Trim_Selected := True;
      end if;

      while Line_Start <= Len loop
         I := Line_Start;

         while I < Len and then Text_Buffer.Character_At (S.Buffer, I) /= ASCII.LF loop
            I := I + 1;
         end loop;

         Line_End := I;

         if not Trim_Selected or else (Row >= First_Row and then Row <= Last_Row) then
            Trim_Start := Line_End;

            while Trim_Start > Line_Start
              and then Is_Trailing_Whitespace_Character
                (Text_Buffer.Character_At (S.Buffer, Trim_Start - 1))
            loop
               Trim_Start := Trim_Start - 1;
            end loop;

            if Trim_Start < Line_End then
               Append_Replace_Op
                 (Forward_Cmd,
                  Cursor_Index (Trim_Start),
                  Line_End - Trim_Start,
                  Null_Unbounded_String);
               Changed := True;
            end if;
         end if;

         exit when I >= Len;
         Line_Start := I + 1;
         Row := Row + 1;
      end loop;

      if not Changed then
         Status := Nothing_To_Trim;
         New_Caret := Old_Caret;
         return;
      end if;

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
      Collapse_To_One_Caret
        (S, Cursor_Index'Min (Old_Caret, Cursor_Index (Text_Buffer.Length (S.Buffer))));
      New_Caret := Safe_Caret (S);
      Status := Trailing_Whitespace_Trimmed;
   exception
      when others =>
         Status := Trim_Trailing_Whitespace_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Trim_Trailing_Whitespace;

   function Validate_Text_Insert_Payload
     (Text : Unbounded_String) return Boolean
   is
      Payload : constant String := To_String (Text);
   begin
      if Payload'Length = 0 then
         return False;
      end if;

      for Ch of Payload loop
         --  Phase 414 reliability policy: ordinary text insertion accepts
         --  printable UTF-8 bytes, literal tab, and the canonical LF line
         --  boundary.  It rejects NUL, CR, and other non-text control bytes
         --  before any editor state is mutated.
         if Ch = ASCII.NUL
           or else Ch = ASCII.CR
           or else (Ch < ' ' and then Ch /= ASCII.HT and then Ch /= ASCII.LF)
         then
            return False;
         end if;
      end loop;

      return True;
   end Validate_Text_Insert_Payload;

   function Canonical_Text_Insert_Position
     (S      : Editor.State.State_Type;
      Status : out Line_Edit_Status) return Cursor_Index
   is
      Pos : constant Cursor_Index := Safe_Caret (S);
   begin
      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         return 0;
      elsif S.Rect_Select_Active or else Natural (S.Carets.Length) /= 1 then
         --  Text Insert has exactly one active-buffer editor text-entry
         --  model.  Rectangular and multi-caret insertion remain non-goals
         --  and must not be silently repaired into ordinary insertion.
         Status := Invalid_Selection;
         return Pos;
      elsif Natural (Pos) > Text_Buffer.Length (S.Buffer) then
         --  The insertion position is derived from canonical caret state
         --  only.  Stale carets fail before mutation instead of being
         --  clamped from render/availability/text-entry paths.
         Status := Text_Insert_Failed;
         return Pos;
      else
         Status := Line_Edit_None;
         return Pos;
      end if;
   end Canonical_Text_Insert_Position;

   function Canonical_Text_Insert_Replacement_Range
     (S      : Editor.State.State_Type;
      Selection_Range  : out Canonical_Selection_Delete_Range;
      Status : out Line_Edit_Status) return Boolean
   is
      Sel_Stat : Editor.Selection.Selection_Validation_Status;
   begin
      Selection_Range := Active_Selection_Delete_Range (S, Sel_Stat);

      case Sel_Stat is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Status := No_Active_Buffer;
            return False;
         when Editor.Selection.Selection_No_Caret =>
            Status := No_Caret_Location;
            return False;
         when Editor.Selection.Selection_Invalid =>
            Status := Invalid_Selection;
            return False;
         when Editor.Selection.Selection_Empty =>
            Status := Line_Edit_None;
            return False;
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      if not Valid_Canonical_Selection_Delete_Range (S, Selection_Range) then
         Status := Invalid_Selection;
         return False;
      end if;

      Status := Line_Edit_None;
      return True;
   end Canonical_Text_Insert_Replacement_Range;

   procedure Apply_Text_Insert_As_Undoable_Mutation
     (S            : in out Editor.State.State_Type;
      Insert_At    : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String;
      New_Caret    : out Cursor_Index;
      Forward_Cmd  : out Editor.Commands.Command)
   is
      Insert_Len : constant Natural :=
        Text_Buffer.UTF8_Code_Point_Count (To_String (Insert_Text));
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Append_Replace_Op
        (Forward_Cmd,
         Insert_At,
         Delete_Count,
         Insert_Text);

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      New_Caret := Cursor_Index (Natural (Insert_At) + Insert_Len);
      Collapse_To_One_Caret (S, New_Caret);
   end Apply_Text_Insert_As_Undoable_Mutation;

   procedure Perform_Insert_Text_Input
     (S                    : in out Editor.State.State_Type;
      Payload              : Unbounded_String;
      Command_Pos          : Cursor_Index;
      Command_Has_Position : Boolean;
      New_Caret            : out Cursor_Index;
      Forward_Cmd          : out Editor.Commands.Command;
      Changed              : out Boolean;
      Status               : out Line_Edit_Status)
   is
      Selection_Range             : Canonical_Selection_Delete_Range;
      Position_Status   : Line_Edit_Status := Line_Edit_None;
      Range_Status      : Line_Edit_Status := Line_Edit_None;
      Insert_Pos        : Cursor_Index := 0;
      Has_Replacement   : Boolean := False;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Length (Payload) = 0 then
         Status := Nothing_To_Insert;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Validate_Text_Insert_Payload (Payload) then
         Status := Invalid_Text_Input;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      if S.Rect_Select_Active
        or else
          (Any_Selection (S)
           and then (S.Rect_Select_Active or else S.Carets.Length > 1))
      then
         Replace_Selected_Carets
           (S           => S,
            Lines       => One_Line_Vector (Payload),
            New_Caret   => New_Caret,
            Forward_Cmd => Forward_Cmd);
         Status := Selection_Replaced;
         Changed := True;
         return;
      elsif S.Carets.Length > 1 then
         Collapse_To_One_Caret
           (S, Cursor_Index'Min
                 (Safe_Caret (S),
                  Cursor_Index (Text_Buffer.Length (S.Buffer))));
         Status := Invalid_Selection;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Insert_Pos := Canonical_Text_Insert_Position (S, Position_Status);
      if Position_Status /= Line_Edit_None then
         Status := Position_Status;
         New_Caret := Insert_Pos;
         return;
      end if;

      if Command_Has_Position
        and then S.Carets (S.Carets.First_Index).Virtual_Column = 0
      then
         Insert_Pos := Cursor_Index'Min
           (Command_Pos, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      end if;

      Has_Replacement :=
        Canonical_Text_Insert_Replacement_Range
          (S      => S,
           Selection_Range  => Selection_Range,
           Status => Range_Status);

      if Range_Status /= Line_Edit_None then
         Status := Range_Status;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      if Has_Replacement then
         Apply_Text_Insert_As_Undoable_Mutation
           (S            => S,
            Insert_At    => Cursor_Index (Selection_Range.Start_Pos),
            Delete_Count => Selection_Range.End_Pos - Selection_Range.Start_Pos,
            Insert_Text  => Payload,
            New_Caret    => New_Caret,
            Forward_Cmd  => Forward_Cmd);
         Status := Selection_Replaced;
         Changed := True;
      else
         Apply_Text_Insert_As_Undoable_Mutation
           (S            => S,
            Insert_At    => Insert_Pos,
            Delete_Count => 0,
            Insert_Text  => Payload,
            New_Caret    => New_Caret,
            Forward_Cmd  => Forward_Cmd);
         Status := Text_Inserted;
         Changed := True;
      end if;
   exception
      when others =>
         Status := Text_Insert_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Insert_Text_Input;


   procedure Perform_Delete_Selection
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range             : Canonical_Selection_Delete_Range;
      Selection_Status  : Editor.Selection.Selection_Validation_Status;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      Selection_Range := Active_Selection_Delete_Range (S, Selection_Status);

      case Selection_Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Status := Selection_Delete_Failed;
            New_Caret := Safe_Caret (S);
            return;
         when Editor.Selection.Selection_No_Caret =>
            Status := No_Caret_Location;
            New_Caret := 0;
            return;
         when Editor.Selection.Selection_Empty =>
            Status := Nothing_Selected;
            New_Caret := Safe_Caret (S);
            return;
         when Editor.Selection.Selection_Invalid =>
            Status := Invalid_Selection;
            Collapse_To_One_Caret
              (S, Cursor_Index'Min
                    (Safe_Caret (S),
                     Cursor_Index (Text_Buffer.Length (S.Buffer))));
            New_Caret := Safe_Caret (S);
            return;
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      if not Selection_Range.Has_Range then
         Status := Nothing_Selected;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Selection_Delete_Range (S, Selection_Range) then
         Status := Invalid_Selection;
         Collapse_To_One_Caret
           (S, Cursor_Index'Min
                 (Safe_Caret (S),
                  Cursor_Index (Text_Buffer.Length (S.Buffer))));
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Selection_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Selection_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Selection_Delete_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Selection;


   procedure Perform_Delete_Previous_Character
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Character_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Collapse_To_One_Caret
           (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
         Status := Delete_Previous_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Previous_Character_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Character_Delete_Range (S, Selection_Range) then
         Status := Delete_Previous_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Character_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Previous_Character_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Previous_Character_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Previous_Character;

   procedure Perform_Delete_Next_Character
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Character_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Collapse_To_One_Caret
           (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
         Status := Delete_Next_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Next_Character_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Character_Delete_Range (S, Selection_Range) then
         Status := Delete_Next_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Character_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Next_Character_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Next_Character_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Next_Character;

   procedure Perform_Delete_Previous_Word
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Word_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Collapse_To_One_Caret
           (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
         Status := Delete_Previous_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Previous_Word_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Word_Delete_Range (S, Selection_Range) then
         Status := Delete_Previous_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Word_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Previous_Word_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Previous_Word_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Previous_Word;

   procedure Perform_Delete_Next_Word
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Word_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Collapse_To_One_Caret
           (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
         Status := Delete_Next_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Next_Word_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Word_Delete_Range (S, Selection_Range) then
         Status := Delete_Next_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Word_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Next_Word_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Next_Word_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Next_Word;

   function Padding_For
   (S : Editor.State.State_Type;
      C : Caret_State) return Unbounded_String
   is
      Row : Natural := 0;
      Col : Natural := 0;
      Pad : Natural := 0;

      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if C.Virtual_Column = 0 then
         return Result;
      end if;

      Line_Column_For_Index (S, Natural (C.Pos), Row, Col);

      if C.Virtual_Column > Col then
         Pad := C.Virtual_Column - Col;

         for I in 1 .. Pad loop
            Append (Result, ' ');
         end loop;
      end if;

      return Result;
   end Padding_For;
   procedure Materialize_Virtual_Caret
   (S : in out Editor.State.State_Type;
      C : in out Caret_State)
   is
      Row : Natural := 0;
      Col : Natural := 0;
      Pad_Count : Natural := 0;
      Start_Pos : Natural := 0;
   begin
      if C.Virtual_Column = 0 then
         return;
      end if;

      Line_Column_For_Index (S, Natural (C.Pos), Row, Col);

      if C.Virtual_Column > Col then
         Pad_Count := C.Virtual_Column - Col;
         Start_Pos := Natural (C.Pos);

         for I in 1 .. Pad_Count loop
            Text_Buffer.Insert (S.Buffer, Natural (C.Pos), Character'Val (32));
            C.Pos := C.Pos + 1;
            C.Anchor := C.Pos;
         end loop;
      end if;

      C.Virtual_Column := 0;
      if Pad_Count > 0 then
         Editor.State.Rebuild_After_Buffer_Change
         (S,
            (Start_Index => Start_Pos,
            Old_Length  => 0,
            New_Length  => Pad_Count)
         );
      else
         Editor.State.Normalize_Carets (S);
      end if;
   end Materialize_Virtual_Caret;

   procedure Replace_All_Selections
   (S           : in out Editor.State.State_Type;
      Insert_Text : Unbounded_String;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
      Old_Carets : constant Cursors_Vector.Vector := S.Carets;
      New_Carets : Cursors_Vector.Vector;
      D          : Integer := 0;
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;

      for C of Old_Carets loop
         declare
            L    : constant Cursor_Index := Cursor_Index'Min (C.Anchor, C.Pos);
            H    : constant Cursor_Index := Cursor_Index'Max (C.Anchor, C.Pos);
            Span : constant Natural := Natural (H - L);
         begin
            Append_Replace_Op
            (Forward_Cmd,
               L,
               Span,
               Insert_Text);
         end;
      end loop;

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      for C of Old_Carets loop
         declare
            L        : constant Cursor_Index := Cursor_Index'Min (C.Anchor, C.Pos);
            H        : constant Cursor_Index := Cursor_Index'Max (C.Anchor, C.Pos);
            Span     : constant Natural := Natural (H - L);
            Ins_Len  : constant Natural := Text_Buffer.UTF8_Code_Point_Count (To_String (Insert_Text));
            New_Pos  : constant Cursor_Index :=
            Cursor_Index (Integer (L) + D + Integer (Ins_Len));
         begin
            New_Carets.Append (Caret_State'(
               Pos => New_Pos,
               Anchor => New_Pos,
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0
            ));
            D := D + Integer (Ins_Len) - Integer (Span);
         end;
      end loop;

      S.Carets := New_Carets;
      Editor.State.Normalize_Carets (S);

      New_Caret := Editor.Executor.Safe_Caret (S);
   end Replace_All_Selections;
   function Normalize_Paste_Text
     (Text : Unbounded_String) return Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;
      I      : Natural := 1;
   begin
      while I <= Length (Text) loop
         declare
            Ch : constant Character := Element (Text, I);
         begin
            if Ch = ASCII.CR then
               Append (Result, ASCII.LF);
               if I < Length (Text)
                 and then Element (Text, I + 1) = ASCII.LF
               then
                  I := I + 1;
               end if;
            else
               Append (Result, Ch);
            end if;
         end;

         I := I + 1;
      end loop;

      return Result;
   end Normalize_Paste_Text;

   function Split_Lines
   (Text : Unbounded_String)
      return Editor.Commands.Text_Vectors.Vector
   is
      use Editor.Commands;

      Result : Text_Vectors.Vector;
      Line   : Unbounded_String := Null_Unbounded_String;
   begin
      for I in 1 .. Length (Text) loop
         declare
            Ch : constant Character := Element (Text, I);
         begin
            if Ch = ASCII.LF then
               Result.Append (Line);
               Line := Null_Unbounded_String;
            else
               Append (Line, Ch);
            end if;
         end;
      end loop;

      Result.Append (Line);
      return Result;
   end Split_Lines;


   function One_Line_Vector
     (Text : Unbounded_String) return Editor.Commands.Text_Vectors.Vector
   is
      Result : Editor.Commands.Text_Vectors.Vector;
   begin
      Result.Append (Text);
      return Result;
   end One_Line_Vector;

   function Caret_Has_Editable_Selection
     (S : Editor.State.State_Type;
      C : Caret_State) return Boolean
   is
   begin
      if S.Rect_Select_Active then
         return C.Pos /= C.Anchor
           or else C.Virtual_Column /= C.Anchor_Virtual_Column;
      else
         return Editor.Rectangle_Selection.Has_Selection (C);
      end if;
   end Caret_Has_Editable_Selection;

   function Any_Selection
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for C of S.Carets loop
         if Caret_Has_Editable_Selection (S, C) then
            return True;
         end if;
      end loop;

      return False;
   end Any_Selection;

   procedure Replace_Selected_Carets
     (S           : in out Editor.State.State_Type;
      Lines       : Editor.Commands.Text_Vectors.Vector;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
      Old_State  : constant Editor.State.State_Type := S;
      Old_Carets : constant Cursors_Vector.Vector := S.Carets;
      New_Carets : Cursors_Vector.Vector;
      Offset     : Integer := 0;
      Line_I     : Natural := Lines.First_Index;
      Last_Line  : constant Natural := Lines.Last_Index;
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;

      for C of Old_Carets loop
         declare
            Use_Line   : constant Natural := Natural'Min (Line_I, Last_Line);
            Has_Insert : constant Boolean :=
              Text_Buffer.UTF8_Code_Point_Count
                (To_String (Lines (Use_Line))) > 0;
            Is_Target  : constant Boolean :=
              Caret_Has_Editable_Selection (Old_State, C)
              or else (Old_State.Rect_Select_Active and then Has_Insert);
         begin
            if Is_Target then
               declare
                  L        : constant Cursor_Index :=
                    Editor.Rectangle_Selection.Selection_Start_Position (S, C);
                  H        : constant Cursor_Index :=
                    Editor.Rectangle_Selection.Selection_End_Position (S, C);
                  Left_Col : constant Natural :=
                    Editor.Rectangle_Selection.Selection_Left_Column (S, C);
                  Row      : Natural := 0;
                  Col      : Natural := 0;
                  Start_C  : Caret_State;
                  Pad      : Unbounded_String := Null_Unbounded_String;
                  Ins      : Unbounded_String := Null_Unbounded_String;
               begin
                  Editor.State.Row_Col_For_Index (S, L, Row, Col);

                  Start_C :=
                    (Pos                   => L,
                     Anchor                => L,
                     Virtual_Column        => (if Left_Col > Col then Left_Col else 0),
                     Anchor_Virtual_Column => (if Left_Col > Col then Left_Col else 0));

                  --  Deleting a purely virtual span must not materialize spaces.
                  --  Padding is only part of an insertion/replacement payload.
                  if Has_Insert then
                     Pad := Padding_For (S, Start_C);
                  end if;

                  Ins := Pad & Lines (Use_Line);

                  Append_Replace_Op
                    (Forward_Cmd,
                     L,
                     Natural (H - L),
                     Ins);

                  if Line_I < Last_Line then
                     Line_I := Line_I + 1;
                  end if;
               end;
            end if;
         end;
      end loop;

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      Line_I := Lines.First_Index;
      for C of Old_Carets loop
         declare
            Use_Line   : constant Natural := Natural'Min (Line_I, Last_Line);
            Has_Insert : constant Boolean :=
              Text_Buffer.UTF8_Code_Point_Count
                (To_String (Lines (Use_Line))) > 0;
            Is_Target  : constant Boolean :=
              Caret_Has_Editable_Selection (Old_State, C)
              or else (Old_State.Rect_Select_Active and then Has_Insert);
         begin
            if Is_Target then
               declare
                  L        : constant Cursor_Index :=
                    Editor.Rectangle_Selection.Selection_Start_Position (Old_State, C);
                  H        : constant Cursor_Index :=
                    Editor.Rectangle_Selection.Selection_End_Position (Old_State, C);
                  Left_Col : constant Natural :=
                    Editor.Rectangle_Selection.Selection_Left_Column (Old_State, C);
                  Row      : Natural := 0;
                  Col      : Natural := 0;
                  Start_C  : Caret_State;
                  Pad_Len  : Natural := 0;
                  Ins_Len  : Natural := 0;
                  New_Pos  : Natural := 0;
                  New_VC   : Natural := 0;
               begin
                  Editor.State.Row_Col_For_Index (Old_State, L, Row, Col);

                  Start_C :=
                    (Pos                   => L,
                     Anchor                => L,
                     Virtual_Column        => (if Left_Col > Col then Left_Col else 0),
                     Anchor_Virtual_Column => (if Left_Col > Col then Left_Col else 0));

                  if Has_Insert then
                     Pad_Len := Text_Buffer.UTF8_Code_Point_Count
                       (To_String (Padding_For (Old_State, Start_C)));
                  end if;

                  Ins_Len := Pad_Len +
                    Text_Buffer.UTF8_Code_Point_Count (To_String (Lines (Use_Line)));
                  New_Pos := Natural (Integer (L) + Offset + Integer (Ins_Len));

                  if Ins_Len = 0 and then H = L and then Left_Col > Col then
                     New_VC := Left_Col;
                  end if;

                  New_Carets.Append
                    (Caret_State'
                       (Pos                   => Cursor_Index (New_Pos),
                        Anchor                => Cursor_Index (New_Pos),
                        Virtual_Column        => New_VC,
                        Anchor_Virtual_Column => New_VC));

                  Offset := Offset + Integer (Ins_Len) - Integer (H - L);

                  if Line_I < Last_Line then
                     Line_I := Line_I + 1;
                  end if;
               end;
            end if;
         end;
      end loop;

      S.Carets := New_Carets;
      S.Rect_Select_Active := False;
      Editor.State.Normalize_Carets (S);
      New_Caret := Safe_Caret (S);
   end Replace_Selected_Carets;

   function Build_Column_Paste_Targets
   (S     : Editor.State.State_Type;
      Lines : Editor.Commands.Text_Vectors.Vector)
      return Cursors_Vector.Vector
   is
      Result : Cursors_Vector.Vector;

      First_Caret : Caret_State;
      Base_Row    : Natural := 0;
      Base_Col    : Natural := 0;
      Target_Col  : Natural := 0;

      Row      : Natural := 0;
      Line_Len : Natural := 0;
      Pos      : Cursor_Index := 0;
      VC       : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         return Result;
      end if;

      if Lines.Length = 0 then
         return Result;
      end if;

      ------------------------------------------------------------------
      -- Case 1:
      -- pasted lines <= existing carets
      --
      -- Use the existing carets. The caller will clamp the line index to
      -- the last pasted line.
      ------------------------------------------------------------------
      if Lines.Length <= S.Carets.Length then
         return S.Carets;
      end if;

      ------------------------------------------------------------------
      -- Case 2:
      -- pasted lines > existing carets
      --
      -- Expand downward from the first caret, preserving its visual column.
      -- This first version only expands across rows that already exist.
      ------------------------------------------------------------------
      First_Caret := S.Carets (S.Carets.First_Index);

      Line_Column_For_Index
      (S,
         Natural (First_Caret.Pos),
         Base_Row,
         Base_Col);

      if First_Caret.Virtual_Column > 0 then
         Target_Col := First_Caret.Virtual_Column;
      else
         Target_Col := Base_Col;
      end if;

      for I in 0 .. Natural (Lines.Length) - 1 loop
         Row := Base_Row + I;

         declare
            Last_Row : Natural := 0;
            Dummy_Col : Natural := 0;
         begin
            Line_Column_For_Index
            (S,
               Text_Buffer.Length (S.Buffer),
               Last_Row,
               Dummy_Col);

            if Row > Last_Row then
               Result.Clear;
               return Result;
            end if;
         end;

         Line_Len := Line_Length (S, Row);

         if Target_Col <= Line_Len then
            Pos :=
            Cursor_Index
               (Index_For_Line_Column (S, Row, Target_Col));
            VC := 0;
         else
            Pos :=
            Cursor_Index
               (Index_For_Line_Column (S, Row, Line_Len));
            VC := Target_Col;
         end if;

         Result.Append
         (Caret_State'(
            Pos                   => Pos,
            Anchor                => Pos,
            Virtual_Column        => VC,
            Anchor_Virtual_Column => VC));
      end loop;

      return Result;
   end Build_Column_Paste_Targets;
   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets.Element (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

   function One_Char_Text (Ch : Character) return Unbounded_String is
   begin
      return To_Unbounded_String (String'(1 => Ch));
   end One_Char_Text;

   function One_Code_Point_Text
     (Code : Editor.Unicode.Code_Point) return Unbounded_String is
   begin
      return To_Unbounded_String (Editor.UTF8.Encode_UTF8 (Code));
   end One_Code_Point_Text;

   function Empty_Text return Unbounded_String is
   begin
      return Null_Unbounded_String;
   end Empty_Text;

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

   procedure Collapse_All_Selections
     (S : in out Editor.State.State_Type)
   is
      C : Caret_State;
   begin
      for I in S.Carets.First_Index .. S.Carets.Last_Index loop
         C := S.Carets (I);
         C.Anchor := C.Pos;
         S.Carets.Replace_Element (I, C);
      end loop;
   end Collapse_All_Selections;

   procedure Collapse_To_One_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index) is
   begin
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
   end Collapse_To_One_Caret;

   procedure Insert_At_All_Carets
     (S           : in out Editor.State.State_Type;
      Code        : Editor.Unicode.Code_Point;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
      New_Carets : Cursors_Vector.Vector;
      Offset     : Natural := 0;
      Pos        : Natural := 0;
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;

      for C of S.Carets loop
         declare
            Pad : constant Unbounded_String := Padding_For (S, C);
            Ins : constant Unbounded_String := Pad & One_Code_Point_Text (Code);
         begin
            Append_Replace_Op
            (Forward_Cmd,
               C.Pos,
               0,
               Ins);
         end;
      end loop;

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      for C of S.Carets loop
         declare
            Pad : constant Unbounded_String := Padding_For (S, C);
            Ins_Len : constant Natural := Text_Buffer.UTF8_Code_Point_Count
              (To_String (Pad & One_Code_Point_Text (Code)));
         begin
            Pos := Natural (C.Pos) + Offset + Ins_Len;

            New_Carets.Append
            (Caret_State'(
               Pos            => Cursor_Index (Pos),
               Anchor         => Cursor_Index (Pos),
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0
            ));

            Offset := Offset + Ins_Len;
         end;
      end loop;
      S.Carets := New_Carets;
      Editor.State.Normalize_Carets (S);

      New_Caret := Safe_Caret (S);
      Collapse_All_Selections (S);
   end Insert_At_All_Carets;

   procedure Backspace_All_Carets
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
      New_Carets : Cursors_Vector.Vector;
      Offset     : Natural := 0;
      Delete_Pos : Natural := 0;
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;

      for C of S.Carets loop
         if C.Pos > 0 then
            Append_Replace_Op
              (Forward_Cmd,
               C.Pos - 1,
               1,
               Empty_Text);
         end if;
      end loop;

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      for C of S.Carets loop
         if C.Pos = 0 then
            New_Carets.Append (Caret_State'(others => <>));
         else
            Delete_Pos := Natural (C.Pos) - 1 - Offset;
            New_Carets.Append
              (Caret_State'(
               Pos => Cursor_Index (Delete_Pos),
               Anchor => Cursor_Index (Delete_Pos),
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0
            ));
            Offset := Offset + 1;
         end if;
      end loop;

      S.Carets := New_Carets;
      Editor.State.Normalize_Carets (S);

      New_Caret := Safe_Caret (S);
      Collapse_All_Selections (S);
   end Backspace_All_Carets;

   procedure Delete_All_Carets
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
      New_Carets   : Cursors_Vector.Vector;
      Old_Carets   : constant Cursors_Vector.Vector := S.Carets;
      Old_Len      : constant Natural := Text_Buffer.Length (S.Buffer);
      Offset       : Natural := 0;
      Deleted_Here : Natural := 0;
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;

      for C of Old_Carets loop
         if Natural (C.Pos) < Old_Len then
            Append_Replace_Op
              (Forward_Cmd,
               C.Pos,
               1,
               Empty_Text);
         end if;
      end loop;

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      for C of Old_Carets loop
         Deleted_Here := 0;

         if Natural (C.Pos) < Old_Len then
            Deleted_Here := 1;
         end if;

         New_Carets.Append
           (Caret_State'(
               Pos => Cursor_Index (Natural (C.Pos) - Offset),
               Anchor => Cursor_Index (Natural (C.Pos) - Offset),
               Virtual_Column => 0,
               Anchor_Virtual_Column => 0
            ));

         Offset := Offset + Deleted_Here;
      end loop;

      S.Carets := New_Carets;
      Editor.State.Normalize_Carets (S);

      New_Caret := Safe_Caret (S);
      Collapse_All_Selections (S);
   end Delete_All_Carets;

   --  Phase 404 removed the old all-caret word-delete helpers.  Word Delete
   --  is now a single-caret active-buffer command path with canonical range
   --  computation and canonical undoable mutation.

   procedure Execute
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Had_Selection   : Boolean;
      Sel_Start       : Cursor_Index;
      Sel_End         : Cursor_Index;
      Old_Caret       : Cursor_Index;
      New_Caret       : out Cursor_Index;
      Forward_Cmd     : out Editor.Commands.Command;
      Should_Log_Edit : out Boolean;
      Line_Status     : out Line_Edit_Status)
   is
   begin
      New_Caret := Old_Caret;
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Should_Log_Edit := False;
      Line_Status := Line_Edit_None;

      case Cmd.Kind is

         when Insert_Text_Input =>
            --  Phase 413 insertion cleanup: Insert_Text_Input is the only
            --  active-buffer insertion command kind.  Character and newline
            --  sources must populate Cmd.Text before reaching Executor.Edits;
            --  this package no longer falls back to Ch/Code insertion.
            Perform_Insert_Text_Input
              (S                    => S,
               Payload              => Cmd.Text,
               Command_Pos          => Cmd.Pos,
               Command_Has_Position => Cmd.Has_Position,
               New_Caret            => New_Caret,
               Forward_Cmd          => Forward_Cmd,
               Changed              => Should_Log_Edit,
               Status               => Line_Status);

         when Delete_Char =>
            if Any_Selection (S)
              and then (S.Rect_Select_Active or else S.Carets.Length > 1)
            then
               Replace_Selected_Carets
                 (S           => S,
                  Lines       => One_Line_Vector (Empty_Text),
                  New_Caret   => New_Caret,
                  Forward_Cmd => Forward_Cmd);

               Should_Log_Edit := True;

            elsif Had_Selection then
               Apply_Canonical_Range_Delete_As_Undoable_Mutation
                 (S, Sel_Start, Sel_End, New_Caret, Forward_Cmd);
               Should_Log_Edit := True;

            elsif S.Carets.Length > 1 then
               Backspace_All_Carets (S, New_Caret, Forward_Cmd);
               Should_Log_Edit := True;

            else
               if Old_Caret > 0 then
                  Forward_Cmd.Kind := Apply_Replace_Batch;
                  Append_Replace_Op
                    (Forward_Cmd,
                     Cursor_Index (Natural (Old_Caret) - 1),
                     1,
                     Empty_Text);

                  Text_Buffer.Delete
                    (S.Buffer,
                     Natural (Old_Caret) - 1);

                  New_Caret := Cursor_Index (Natural (Old_Caret) - 1);
                  Collapse_To_One_Caret (S, New_Caret);
                  Should_Log_Edit := True;
                  Editor.State.Rebuild_After_Buffer_Change
                  (S,
                     (Start_Index => Natural (Old_Caret) - 1,
                     Old_Length  => 1,
                     New_Length  => 0)
                  );
               end if;
            end if;

         when Forward_Delete_Char =>
            if Any_Selection (S)
              and then (S.Rect_Select_Active or else S.Carets.Length > 1)
            then
               Replace_Selected_Carets
                 (S           => S,
                  Lines       => One_Line_Vector (Empty_Text),
                  New_Caret   => New_Caret,
                  Forward_Cmd => Forward_Cmd);

               Should_Log_Edit := True;

            elsif Had_Selection then
               Apply_Canonical_Range_Delete_As_Undoable_Mutation
                 (S, Sel_Start, Sel_End, New_Caret, Forward_Cmd);
               Should_Log_Edit := True;

            elsif S.Carets.Length > 1 then
               Delete_All_Carets (S, New_Caret, Forward_Cmd);
               Should_Log_Edit := True;

            else
               if Natural (Old_Caret) < Buffer_Length (S) then
                  Forward_Cmd.Kind := Apply_Replace_Batch;
                  Append_Replace_Op
                    (Forward_Cmd,
                     Old_Caret,
                     1,
                     Empty_Text);

                  Text_Buffer.Delete
                    (S.Buffer,
                     Natural (Old_Caret));

                  New_Caret := Old_Caret;
                  Collapse_To_One_Caret (S, New_Caret);
                  Should_Log_Edit := True;
                  Editor.State.Rebuild_After_Buffer_Change
                  (S,
                     (Start_Index => Natural (Old_Caret),
                     Old_Length  => 1,
                     New_Length  => 0)
                  );
               end if;
            end if;

         when Delete_Current_Line =>
            Perform_Delete_Current_Line (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Duplicate_Current_Line =>
            Perform_Duplicate_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Move_Current_Line_Up =>
            Perform_Move_Current_Line
              (S, -1, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Move_Current_Line_Down =>
            Perform_Move_Current_Line
              (S, 1, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Indent_Current_Line =>
            Perform_Indent_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Outdent_Current_Line =>
            Perform_Outdent_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Comment_Current_Line =>
            Perform_Comment_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Uncomment_Current_Line =>
            Perform_Uncomment_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Toggle_Current_Line_Comment =>
            Perform_Toggle_Current_Line_Comment
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Join_Current_Line_With_Next =>
            Perform_Join_Current_Line_With_Next
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Split_Current_Line_At_Caret =>
            Perform_Split_Current_Line_At_Caret
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Trim_Trailing_Whitespace =>
            Perform_Trim_Trailing_Whitespace
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Previous_Character =>
            Perform_Delete_Previous_Character
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Next_Character =>
            Perform_Delete_Next_Character
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Previous_Word =>
            Perform_Delete_Previous_Word
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Next_Word =>
            Perform_Delete_Next_Word
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Selection_Range =>
            Perform_Delete_Selection
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

       when Editor.Commands.Paste_Text =>
         declare
            use Ada.Strings.Unbounded;

            Paste_Text : constant Unbounded_String :=
              Normalize_Paste_Text (Cmd.Text);

            Lines : constant Editor.Commands.Text_Vectors.Vector :=
              Split_Lines (Paste_Text);

            Targets : constant Cursors_Vector.Vector :=
              Build_Column_Paste_Targets (S, Lines);
         begin
            ------------------------------------------------------------------
            -- Empty paste is not a buffer edit.  In particular, do not
            -- replace a selection with nothing, dirty a clean buffer, bump
            -- the buffer revision, or log an undo entry for an empty
            -- clipboard/text payload.
            ------------------------------------------------------------------
            if Length (Paste_Text) = 0 then
               null;

            ------------------------------------------------------------------
            -- Rectangle/multi-caret selection paste
            ------------------------------------------------------------------
            elsif Any_Selection (S)
              and then (S.Rect_Select_Active or else S.Carets.Length > 1)
            then
               Replace_Selected_Carets
                 (S           => S,
                  Lines       => Lines,
                  New_Caret   => New_Caret,
                  Forward_Cmd => Forward_Cmd);

               Should_Log_Edit := True;

            ------------------------------------------------------------------
            -- Ordinary single-selection paste replaces the selected range
            -- before considering multiline/column paste semantics.
            ------------------------------------------------------------------
            elsif Had_Selection then
               declare
                  L  : constant Cursor_Index :=
                    Cursor_Index'Min (Sel_Start, Sel_End);
                  H  : constant Cursor_Index :=
                    Cursor_Index'Max (Sel_Start, Sel_End);
                  Sp : constant Natural := Natural (H - L);
                  Ins_Len : constant Natural :=
                    Text_Buffer.UTF8_Code_Point_Count (To_String (Paste_Text));
               begin
                  Forward_Cmd.Kind := Apply_Replace_Batch;
                  Append_Replace_Op
                    (Forward_Cmd,
                     L,
                     Sp,
                     Paste_Text);

                  Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

                  New_Caret := Cursor_Index (Natural (L) + Ins_Len);
                  Collapse_To_One_Caret (S, New_Caret);
                  Should_Log_Edit := True;
               end;

            ------------------------------------------------------------------
            -- Column-aligned paste (handles 1 or many carets)
            ------------------------------------------------------------------
            elsif Lines.Length > 1 and then Targets.Length > 0 then
               Forward_Cmd.Kind := Apply_Replace_Batch;

               ------------------------------------------------------------------
               -- Build replace ops
               ------------------------------------------------------------------
               declare
                  Line_I    : Natural := Lines.First_Index;
                  Last_Line : constant Natural := Lines.Last_Index;
               begin
                  for C of Targets loop
                     declare
                        Use_Line : constant Natural :=
                        Natural'Min (Line_I, Last_Line);

                        Pad : constant Unbounded_String :=
                        Padding_For (S, C);

                        Ins : constant Unbounded_String :=
                        Pad & Lines (Use_Line);
                     begin
                        Append_Replace_Op
                        (Forward_Cmd,
                           C.Pos,
                           0,
                           Ins);

                        if Line_I < Last_Line then
                           Line_I := Line_I + 1;
                        end if;
                     end;
                  end loop;
               end;

               Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

               ------------------------------------------------------------------
               -- Update carets
               ------------------------------------------------------------------
               declare
                  New_Carets : Cursors_Vector.Vector;
                  Offset     : Natural := 0;

                  Line_I    : Natural := Lines.First_Index;
                  Last_Line : constant Natural := Lines.Last_Index;
               begin
                  for C of Targets loop
                     declare
                        Use_Line : constant Natural :=
                        Natural'Min (Line_I, Last_Line);

                        Pad     : constant Unbounded_String :=
                        Padding_For (S, C);

                        Ins_Len : constant Natural :=
                        Text_Buffer.UTF8_Code_Point_Count (To_String (Pad & Lines (Use_Line)));

                        New_Pos : constant Natural :=
                        Natural (C.Pos) + Offset + Ins_Len;
                     begin
                        New_Carets.Append
                        (Caret_State'(
                           Pos                   => Cursor_Index (New_Pos),
                           Anchor                => Cursor_Index (New_Pos),
                           Virtual_Column        => 0,
                           Anchor_Virtual_Column => 0));

                        Offset := Offset + Ins_Len;

                        if Line_I < Last_Line then
                           Line_I := Line_I + 1;
                        end if;
                     end;
                  end loop;

                  S.Carets := New_Carets;
                  Editor.State.Normalize_Carets (S);
               end;

               New_Caret := Safe_Caret (S);
               Should_Log_Edit := True;

            ------------------------------------------------------------------
            -- Multi-caret identical paste fallback
            ------------------------------------------------------------------
            elsif S.Carets.Length > 1 then
               Forward_Cmd.Kind := Apply_Replace_Batch;

               for C of S.Carets loop
                  declare
                     Pad : constant Unbounded_String := Padding_For (S, C);
                     Ins : constant Unbounded_String := Pad & Paste_Text;
                  begin
                     Append_Replace_Op
                     (Forward_Cmd,
                        C.Pos,
                        0,
                        Ins);
                  end;
               end loop;

               Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

               declare
                  New_Carets : Cursors_Vector.Vector;
                  Offset     : Natural := 0;
                  Pos        : Natural := 0;
               begin
                  for C of S.Carets loop
                     declare
                        Pad     : constant Unbounded_String := Padding_For (S, C);
                        Ins_Len : constant Natural := Text_Buffer.UTF8_Code_Point_Count (To_String (Pad & Paste_Text));
                     begin
                        Pos := Natural (C.Pos) + Offset + Ins_Len;

                        New_Carets.Append
                        (Caret_State'(
                           Pos                   => Cursor_Index (Pos),
                           Anchor                => Cursor_Index (Pos),
                           Virtual_Column        => 0,
                           Anchor_Virtual_Column => 0));

                        Offset := Offset + Ins_Len;
                     end;
                  end loop;

                  S.Carets := New_Carets;
                  Editor.State.Normalize_Carets (S);
               end;

               New_Caret := Safe_Caret (S);
               Should_Log_Edit := True;

            ------------------------------------------------------------------
            -- Single-caret paste
            ------------------------------------------------------------------
            else
               declare
                  C   : constant Caret_State := S.Carets (S.Carets.First_Index);
                  Pad : constant Unbounded_String := Padding_For (S, C);
                  Ins : constant Unbounded_String := Pad & Paste_Text;

                  New_Pos : constant Cursor_Index :=
                  Cursor_Index (Natural (C.Pos) + Text_Buffer.UTF8_Code_Point_Count (To_String (Ins)));
               begin
                  Forward_Cmd.Kind := Apply_Replace_Batch;

                  Append_Replace_Op
                  (Forward_Cmd,
                     C.Pos,
                     0,
                     Ins);

                  Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

                  S.Carets.Clear;
                  S.Carets.Append
                  (Caret_State'(Pos                   => New_Pos,
                     Anchor                => New_Pos,
                     Virtual_Column        => 0,
                     Anchor_Virtual_Column => 0));

                  New_Caret := New_Pos;
                  Should_Log_Edit := True;
               end;
            end if;
         end;
         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.Edits;