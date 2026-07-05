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

package body Editor.Executor.Format_Commands is

   use type Editor.Executor_Edit_Status.Line_Edit_Status;
   use type Editor.Selection.Selection_Validation_Status;
   use Cursors_Vector;

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

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Old_Caret;
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Len = 0 then
         Status := Nothing_To_Trim;
         New_Caret := Old_Caret;
         return;
      end if;

      --  completeness: a linear active selection narrows the
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

end Editor.Executor.Format_Commands;
