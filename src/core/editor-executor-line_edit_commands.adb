with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Buffers;
with Editor.Commands;
with Editor.Executor.Edits;
with Editor.Executor.History;
with Editor.Executor.Shared_Services;
with Editor.Cursors;
use Editor.Cursors;
with Editor.Navigation; use Editor.Navigation;
with Editor.Messages;
with Editor.Rectangle_Selection;
with Editor.Render_Cache;
with Editor.Selection;
with Editor.State;
with Editor.Unicode;
with Editor.UTF8;

package body Editor.Executor.Line_Edit_Commands is

   use Editor.Commands;
   use Editor.Executor.Edits;
   use type Editor.Commands.Command_Id;
   use type Editor.Messages.Message_Severity;
   use type Editor.Selection.Selection_Validation_Status;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Report_Error
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Error;

   function Has_Buffer (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.State.Has_Active_Buffer (S);
   end Has_Buffer;

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

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index
   is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets.Element (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

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

   function Missing_Active_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return not Editor.State.Has_Active_Buffer (S);
   end Missing_Active_Buffer;

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

      if Result.Row + 1 >= Line_Count
        or else not Has_Following_Terminator (S, Result.Current_End)
      then
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
      end if;

      Populate_For_Row (Result.Row, Result.Column);
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
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
   end Set_Single_Caret;

   function Canonical_Line_Join_Separator return Unbounded_String is
   begin
      return To_Unbounded_String (" ");
   end Canonical_Line_Join_Separator;

   function Join_Separator_For_Line_Texts
     (Left_Text  : Unbounded_String;
      Right_Text : Unbounded_String) return Unbounded_String
   is
   begin
      if Length (Left_Text) = 0 or else Length (Right_Text) = 0 then
         return Null_Unbounded_String;
      else
         return Canonical_Line_Join_Separator;
      end if;
   end Join_Separator_For_Line_Texts;

   function Canonical_Line_Split_Boundary return Unbounded_String is
   begin
      return To_Unbounded_String (String'(1 => ASCII.LF));
   end Canonical_Line_Split_Boundary;

   function Result_After_Command
     (S       : Editor.State.State_Type;
      Before  : Natural;
      Command : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      if Editor.Messages.Count (S.Messages) > Before then
         Msg := Editor.Messages.Active_Message (S.Messages, Found);
         if Found then
            if Editor.Messages.Severity (Msg) = Editor.Messages.Error_Message then
               return Editor.Command_Execution.Failed (Command);
            elsif Editor.Messages.Severity (Msg) =
              Editor.Messages.Warning_Message
            then
               return Editor.Command_Execution.Unavailable (Command);
            end if;
         end if;
      end if;

      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   procedure Report_Line_Edit_Status
     (S       : in out Editor.State.State_Type;
      Command : Editor.Commands.Command_Id;
      Status  : Editor.Executor.Edits.Line_Edit_Status)
   is
   begin
      case Status is
         when Editor.Executor.Edits.Line_Deleted =>
            Report_Success (S, "Deleted line");
         when Editor.Executor.Edits.Line_Duplicated =>
            Report_Success (S, "Duplicated line");
         when Editor.Executor.Edits.Line_Moved_Up =>
            Report_Success (S, "Moved line up");
         when Editor.Executor.Edits.Line_Moved_Down =>
            Report_Success (S, "Moved line down");
         when Editor.Executor.Edits.Line_Indented =>
            Report_Success (S, "Indented line");
         when Editor.Executor.Edits.Line_Outdented =>
            Report_Success (S, "Outdented line");
         when Editor.Executor.Edits.Line_Commented =>
            Report_Success (S, "Commented line");
         when Editor.Executor.Edits.Line_Uncommented =>
            Report_Success (S, "Uncommented line");
         when Editor.Executor.Edits.Line_Joined =>
            Report_Success (S, "Joined line");
         when Editor.Executor.Edits.Line_Split =>
            Report_Success (S, "Split line");
         when Editor.Executor.Edits.Trailing_Whitespace_Trimmed =>
            Report_Success (S, "Trimmed trailing whitespace");
         when Editor.Executor.Edits.Text_Inserted =>
            Report_Success (S, "Inserted text");
         when Editor.Executor.Edits.Selection_Replaced =>
            Report_Success (S, "Replaced selection");
         when Editor.Executor.Edits.Previous_Character_Deleted =>
            Report_Success (S, "Deleted previous character");
         when Editor.Executor.Edits.Next_Character_Deleted =>
            Report_Success (S, "Deleted next character");
         when Editor.Executor.Edits.Previous_Word_Deleted =>
            Report_Success (S, "Deleted previous word");
         when Editor.Executor.Edits.Next_Word_Deleted =>
            Report_Success (S, "Deleted next word");
         when Editor.Executor.Edits.Selection_Deleted =>
            Report_Success (S, "Deleted selection");
         when Editor.Executor.Edits.Nothing_Selected =>
            Report_Info (S, "Nothing selected");
         when Editor.Executor.Edits.Invalid_Selection =>
            Report_Error (S, "Invalid selection");
         when Editor.Executor.Edits.Selection_Delete_Failed =>
            Report_Error (S, "Could not delete selection");
         when Editor.Executor.Edits.No_Active_Buffer =>
            Report_Info (S, "No active buffer.");
         when Editor.Executor.Edits.Nothing_To_Insert =>
            Report_Info (S, "Nothing to insert");
         when Editor.Executor.Edits.Invalid_Text_Input =>
            Report_Error (S, "Invalid text input");
         when Editor.Executor.Edits.Text_Insert_Failed =>
            Report_Error (S, "Could not insert text");
         when Editor.Executor.Edits.Line_Already_Commented =>
            Report_Info (S, "Line already commented");
         when Editor.Executor.Edits.Nothing_To_Delete =>
            Report_Info (S, "Nothing to delete");
         when Editor.Executor.Edits.Nothing_To_Duplicate =>
            Report_Info (S, "Nothing to duplicate");
         when Editor.Executor.Edits.Nothing_To_Indent =>
            Report_Info (S, "Nothing to indent");
         when Editor.Executor.Edits.Nothing_To_Outdent =>
            Report_Info (S, "Nothing to outdent");
         when Editor.Executor.Edits.Nothing_To_Comment =>
            Report_Info (S, "Nothing to comment");
         when Editor.Executor.Edits.Nothing_To_Uncomment =>
            Report_Info (S, "Nothing to uncomment");
         when Editor.Executor.Edits.Nothing_To_Join =>
            Report_Info (S, "Nothing to join");
         when Editor.Executor.Edits.Nothing_To_Split =>
            Report_Info (S, "Nothing to split");
         when Editor.Executor.Edits.Nothing_To_Trim =>
            Report_Info (S, "Nothing to trim");
         when Editor.Executor.Edits.Comment_Failed =>
            Report_Error (S, "Could not comment line");
         when Editor.Executor.Edits.Uncomment_Failed =>
            Report_Error (S, "Could not uncomment line");
         when Editor.Executor.Edits.Line_Join_Failed =>
            Report_Error (S, "Could not join line");
         when Editor.Executor.Edits.Line_Split_Failed =>
            Report_Error (S, "Could not split line");
         when Editor.Executor.Edits.Trim_Trailing_Whitespace_Failed =>
            Report_Error (S, "Could not trim trailing whitespace");
         when Editor.Executor.Edits.Delete_Previous_Character_Failed =>
            Report_Error (S, "Could not delete previous character");
         when Editor.Executor.Edits.Delete_Next_Character_Failed =>
            Report_Error (S, "Could not delete next character");
         when Editor.Executor.Edits.Delete_Previous_Word_Failed =>
            Report_Error (S, "Could not delete previous word");
         when Editor.Executor.Edits.Delete_Next_Word_Failed =>
            Report_Error (S, "Could not delete next word");
         when Editor.Executor.Edits.Already_First_Line =>
            Report_Info (S, "Already at first line");
         when Editor.Executor.Edits.Already_Last_Line =>
            Report_Info (S, "Already at last line");
         when Editor.Executor.Edits.No_Caret_Location =>
            Report_Info (S, "No caret location");
         when Editor.Executor.Edits.Line_Edit_Failed =>
            case Command is
               when Editor.Commands.Command_Line_Delete =>
                  Report_Error (S, "Could not delete line");
               when Editor.Commands.Command_Line_Duplicate =>
                  Report_Error (S, "Could not duplicate line");
               when Editor.Commands.Command_Line_Move_Up =>
                  Report_Error (S, "Could not move line up");
               when Editor.Commands.Command_Line_Move_Down =>
                  Report_Error (S, "Could not move line down");
               when Editor.Commands.Command_Indent_Increase =>
                  Report_Error (S, "Could not indent line");
               when Editor.Commands.Command_Indent_Decrease =>
                  Report_Error (S, "Could not outdent line");
               when Editor.Commands.Command_Comment_Line
                  | Editor.Commands.Command_Toggle_Line_Comment =>
                  Report_Error (S, "Could not comment line");
               when Editor.Commands.Command_Uncomment_Line =>
                  Report_Error (S, "Could not uncomment line");
               when Editor.Commands.Command_Line_Join_Next =>
                  Report_Error (S, "Could not join line");
               when Editor.Commands.Command_Line_Split_At_Caret =>
                  Report_Error (S, "Could not split line");
               when others =>
                  Report_Error (S, "Could not edit line");
            end case;
         when Editor.Executor.Edits.Line_Edit_None =>
            null;
      end case;
   end Report_Line_Edit_Status;

   procedure Perform_Delete_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status)
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
      Status      : out Editor.Executor.Edits.Line_Edit_Status)
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
      Status      : out Editor.Executor.Edits.Line_Edit_Status)
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
         Replacement :=
           This_Text & To_Unbounded_String (String'(1 => ASCII.LF)) & Other_Text;
      else
         First_Start := Start_Pos;
         Second_Start := Index_For_Line_Column (S, Other_Row, 0);
         Second_End := Second_Start + Line_Length (S, Other_Row);
         Replacement :=
           Other_Text & To_Unbounded_String (String'(1 => ASCII.LF)) & This_Text;
      end if;

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

   procedure Perform_Join_Current_Line_With_Next
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status)
   is
      Selection_Range : Line_Join_Boundary_Range;
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

   procedure Perform_Split_Current_Line_At_Caret
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status)
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
      pragma Unreferenced (Column);
      declare
         Selection_Range : Editor.Selection.Active_Selection_Range;
         Selection_Status : constant Editor.Selection.Selection_Validation_Status :=
           Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
         Leading : constant Natural :=
           Canonical_Leading_Whitespace_Length (S, Start_Pos, End_Pos);
         Split_Pos : Natural := Pos;
      begin
         if Selection_Status = Editor.Selection.Selection_Ok
           and then Leading > 0
           and then Natural (Selection_Range.Low) = Start_Pos + Leading
           and then Pos > Start_Pos
         then
            Split_Pos := Pos - 1;
         end if;

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
      end;

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

   function Line_Edit_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      if not Has_Buffer (S) then
         return Editor.Commands.Unavailable ("No active buffer.");
      elsif S.Carets.Length = 0 then
         return Editor.Commands.Unavailable ("No caret location");
      end if;

      case Id is
         when Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret =>
            return Editor.Commands.Available;
         when others =>
            return Editor.Commands.Unavailable ("Not a line edit command");
      end case;
   end Line_Edit_Command_Availability;

   function Execute_Line_Edit_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
      Cmd             : Editor.Commands.Command;
      Line_Status     : Editor.Executor.Edits.Line_Edit_Status;
   begin
      case Id is
         when Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Executor.Execute_No_Log_With_Status
              (S, Cmd, Line_Status);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            Report_Line_Edit_Status (S, Id, Line_Status);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (S, Before_Messages, Id);
         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;
   end Execute_Line_Edit_Command;

end Editor.Executor.Line_Edit_Commands;
