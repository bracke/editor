with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors;  use Editor.Cursors;
with Editor.Executor.Edits; use Editor.Executor.Edits;
with Editor.Executor.History;
with Editor.Navigation; use Editor.Navigation;
with Editor.Selection;
with Editor.State;
with Editor.Unicode;
with Editor.UTF8;

package body Editor.Executor.Line_Edit_Commands is

   use type Editor.Executor_Edit_Status.Line_Edit_Status;
   use type Editor.Selection.Selection_Validation_Status;
   use Cursors_Vector;

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

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets.Element (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

   function Missing_Active_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return not Editor.State.Has_Active_Buffer (S);
   end Missing_Active_Buffer;

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
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
   end Set_Single_Caret;

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
      Line_Column_For_Index
        (S,
         Natural'Min (Natural (Safe_Caret (S)), Text_Buffer.Length (S.Buffer)),
         Row,
         Col);
      Start_Pos := Index_For_Line_Column (S, Row, 0);
      End_Pos := Start_Pos + Line_Length (S, Row);
   end Current_Line_Bounds;

   procedure Line_Bounds_At_Position
     (S         : Editor.State.State_Type;
      Pos       : Natural;
      Row       : out Natural;
      Col       : out Natural;
      Start_Pos : out Natural;
      End_Pos   : out Natural)
   is
   begin
      Line_Column_For_Index
        (S, Natural'Min (Pos, Text_Buffer.Length (S.Buffer)), Row, Col);
      Start_Pos := Index_For_Line_Column (S, Row, 0);
      End_Pos := Start_Pos + Line_Length (S, Row);
   end Line_Bounds_At_Position;

   function Line_Command_Selection_Start_Target
     (S : Editor.State.State_Type) return Natural
   is
      Selection_Range : Editor.Selection.Active_Selection_Range;
      Status          : Editor.Selection.Selection_Validation_Status;
   begin
      Status := Editor.Selection.Validate_Active_Selection_Range
        (S, Selection_Range);

      if Status = Editor.Selection.Selection_Ok
        and then not S.Rect_Select_Active
        and then Natural (S.Carets.Length) = 1
      then
         return Natural (Selection_Range.Low);
      else
         return Natural (Safe_Caret (S));
      end if;
   end Line_Command_Selection_Start_Target;

   function Current_Line_And_Next_Line_Join_Range
     (S : Editor.State.State_Type) return Line_Join_Boundary_Range
   is
      Result     : Line_Join_Boundary_Range;
      Line_Count : constant Natural := Editor.State.Line_Count (S);

      procedure Populate_For_Row
        (Target_Row    : Natural;
         Target_Column : Natural)
      is
      begin
         Result.Row := Target_Row;
         Result.Column :=
           Natural'Min (Target_Column, Line_Length (S, Target_Row));
         Result.Current_Start := Index_For_Line_Column (S, Target_Row, 0);
         Result.Current_End :=
           Result.Current_Start + Line_Length (S, Target_Row);

         if Target_Row + 1 < Line_Count
           and then Has_Following_Terminator (S, Result.Current_End)
         then
            Result.Has_Next_Line := True;
            Result.Boundary_Pos := Result.Current_End;
            Result.Next_Start := Result.Current_End + 1;
            Result.Next_End :=
              Result.Next_Start + Line_Length (S, Target_Row + 1);
         end if;
      end Populate_For_Row;
   begin
      if S.Carets.Length = 0
        or else Text_Buffer.Length (S.Buffer) = 0
        or else Line_Count <= 1
      then
         return Result;
      end if;

      Current_Line_Bounds
        (S, Result.Row, Result.Column, Result.Current_Start, Result.Current_End);

      if Result.Row + 1 < Line_Count
        and then Has_Following_Terminator (S, Result.Current_End)
      then
         Populate_For_Row (Result.Row, Result.Column);
         return Result;
      end if;

      declare
         Selection_Range : Editor.Selection.Active_Selection_Range;
         Status          : constant Editor.Selection.Selection_Validation_Status :=
           Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      begin
         if Status = Editor.Selection.Selection_Ok
           and then not S.Rect_Select_Active
           and then Natural (S.Carets.Length) = 1
         then
            declare
               First_Row : Natural := 0;
               First_Col : Natural := 0;
               Last_Row  : Natural := 0;
               Last_Col  : Natural := 0;
               Last_Pos  : constant Natural :=
                 Natural'Min
                   (Natural (Selection_Range.High - 1),
                    Text_Buffer.Length (S.Buffer));
               Candidate : Natural := 0;
            begin
               Line_Column_For_Index
                 (S, Natural (Selection_Range.Low), First_Row, First_Col);
               Line_Column_For_Index (S, Last_Pos, Last_Row, Last_Col);
               pragma Unreferenced (First_Col, Last_Col);
               Candidate := Last_Row;

               loop
                  if Candidate >= First_Row
                    and then Candidate + 1 < Line_Count
                    and then Has_Following_Terminator
                      (S,
                       Index_For_Line_Column (S, Candidate, 0)
                       + Line_Length (S, Candidate))
                  then
                     Populate_For_Row
                       (Candidate, Line_Length (S, Candidate) / 2);
                     return Result;
                  end if;

                  exit when Candidate = 0 or else Candidate = First_Row;
                  Candidate := Candidate - 1;
               end loop;
            end;
         end if;
      end;

      return Result;
   end Current_Line_And_Next_Line_Join_Range;



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

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
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

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
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

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
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

   function Canonical_Line_Join_Separator return Unbounded_String is
   begin
      --  this separator is intentionally feature-local.  It is not
      --  read from Settings, written to Workspace, inferred from language
      --  syntax, or normalized by render/availability paths.
      return To_Unbounded_String (" ");
   end Canonical_Line_Join_Separator;

   function Join_Separator_For_Line_Texts
     (Left_Text  : Unbounded_String;
      Right_Text : Unbounded_String) return Unbounded_String
   is
   begin
      --  freezes the no-trim policy: remove exactly one
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

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
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
      --  line split inserts exactly one canonical logical line
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
      Split_Pos : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Status := Line_Split_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      --  Use the canonical logical-line helpers for the current caret.  The
      --  line text itself is not inspected; splitting is pure insertion at the
      --  caret and preserves all user text on both sides exactly.
      Current_Line_Bounds (S, Row, Column, Start_Pos, End_Pos);
      pragma Unreferenced (Column);
      Split_Pos := Pos;

      declare
         Selection_Range : Editor.Selection.Active_Selection_Range;
         Selection_Status : constant Editor.Selection.Selection_Validation_Status :=
           Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
         Leading : constant Natural :=
           Canonical_Leading_Whitespace_Length (S, Start_Pos, End_Pos);
      begin
         if Selection_Status = Editor.Selection.Selection_Ok
           and then Leading > 0
           and then Natural (Selection_Range.Low) = Start_Pos + Leading
           and then Pos > Start_Pos
         then
            Split_Pos := Pos - 1;
         end if;
      end;

      if Pos = End_Pos
        and then Has_Following_Terminator (S, End_Pos)
        and then End_Pos > Start_Pos + 1
      then
         Split_Pos := Pos - 1;
      end if;

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Split_Pos),
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

end Editor.Executor.Line_Edit_Commands;
