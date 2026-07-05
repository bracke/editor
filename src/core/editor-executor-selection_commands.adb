with Ada.Containers; use Ada.Containers;

with Text_Buffer;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Navigation;
with Editor.Folding;
with Editor.Invariants;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Navigation; use Editor.Navigation;
with Editor.Rectangle_Selection;
with Editor.Render_Cache;
with Editor.Search;
with Editor.Selection;
use type Editor.Selection.Selection_Validation_Status;
with Editor.State;

package body Editor.Executor.Selection_Commands is

   function Selection_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;
   begin
      case Id is
         when Editor.Commands.Command_Select_Left
            | Editor.Commands.Command_Select_Right
            | Editor.Commands.Command_Select_Up
            | Editor.Commands.Command_Select_Down
            | Editor.Commands.Command_Select_Word_Left
            | Editor.Commands.Command_Select_Word_Right
            | Editor.Commands.Command_Select_Word
            | Editor.Commands.Command_Select_Line
            | Editor.Commands.Command_Start_Rectangular_Selection
            | Editor.Commands.Command_Clear_Rectangular_Selection
            | Editor.Commands.Command_Extend_Selection_Line_Up
            | Editor.Commands.Command_Extend_Selection_Line_Down
            | Editor.Commands.Command_Select_Line_Start
            | Editor.Commands.Command_Select_Line_End
            | Editor.Commands.Command_Select_Document_Start
            | Editor.Commands.Command_Select_Document_End
            | Editor.Commands.Command_Select_Page_Up
            | Editor.Commands.Command_Select_Page_Down
            | Editor.Commands.Command_Select_All =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Selection_Clear =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0 then
               return Editor.Commands.Unavailable ("No caret location");
            elsif not Editor.Selection.Has_Selection (S)
              and then not S.Rect_Select_Active
            then
               return Editor.Commands.Unavailable ("No selection");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a selection command");
      end case;
   end Selection_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Success;

   procedure Report_Error
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Error;

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index
      renames Editor.Executor.Safe_Caret;

   function Safe_Anchor
     (S : Editor.State.State_Type) return Cursor_Index
      renames Editor.Executor.Safe_Anchor;

   procedure Set_Primary_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index) renames Editor.Executor.Set_Primary_Caret;

   procedure Execute_No_Log
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) renames Editor.Executor.Execute_No_Log;

   procedure Execute_Select_Line
     (S : in out Editor.State.State_Type)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Select_Line;
      Execute_No_Log (S, Cmd);
   end Execute_Select_Line;

   procedure Execute_Select_Line_At
     (S   : in out Editor.State.State_Type;
      Row : Natural)
   is
      New_Caret : Cursor_Index := 0;
      New_Preferred_Column : Natural := 0;
   begin
      Editor.Executor.Navigation.Select_Line_Range
        (S                    => S,
         Anchor_Row           => Row,
         Target_Row           => Row,
         New_Caret            => New_Caret,
         New_Preferred_Column => New_Preferred_Column);
      S.Preferred_Column := New_Preferred_Column;
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   end Execute_Select_Line_At;

   procedure Execute_Extend_Selection_By_Line
     (S         : in out Editor.State.State_Type;
      Direction : Editor.Navigation.Navigation_Direction)
   is
      Current_Row : Natural := 0;
      Current_Col : Natural := 0;
      Target_Row  : Natural := 0;
   begin
      Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Current_Row, Current_Col);
      case Direction is
         when Editor.Navigation.Backward =>
            Target_Row := (if Current_Row > 0 then Current_Row - 1 else 0);
         when Editor.Navigation.Forward =>
            Target_Row := Current_Row + 1;
      end case;
      Execute_Extend_Selection_To_Line (S, Target_Row);
   end Execute_Extend_Selection_By_Line;

   procedure Execute_Extend_Selection_To_Line
     (S   : in out Editor.State.State_Type;
      Row : Natural)
   is
      Anchor_Row : Natural := 0;
      Anchor_Col : Natural := 0;
      Cursor_Row : Natural := 0;
      Cursor_Col : Natural := 0;
      New_Caret : Cursor_Index := 0;
      New_Preferred_Column : Natural := 0;
   begin
      Editor.State.Row_Col_For_Index (S, Safe_Anchor (S), Anchor_Row, Anchor_Col);
      Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Cursor_Row, Cursor_Col);

      if Anchor_Row > Cursor_Row and then Anchor_Col = 0 and then Anchor_Row > 0 then
         Anchor_Row := Anchor_Row - 1;
      end if;

      Editor.Executor.Navigation.Select_Line_Range
        (S                    => S,
         Anchor_Row           => Anchor_Row,
         Target_Row           => Row,
         New_Caret            => New_Caret,
         New_Preferred_Column => New_Preferred_Column);
      S.Preferred_Column := New_Preferred_Column;
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   end Execute_Extend_Selection_To_Line;

   procedure Execute_Select_Word
     (S : in out Editor.State.State_Type)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Select_Word;
      Execute_No_Log (S, Cmd);
   end Execute_Select_Word;

   procedure Keep_Only_Primary_Selection_Caret
     (S : in out Editor.State.State_Type)
   is
      Primary : Caret_State :=
        (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0);
      Len     : constant Cursor_Index := Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      if S.Carets.Length > 0 then
         Primary := S.Carets (S.Carets.First_Index);
      end if;

      if Primary.Pos > Len then
         Primary.Pos := Len;
      end if;

      if Primary.Anchor > Len then
         Primary.Anchor := Len;
      end if;

      S.Carets.Clear;
      S.Carets.Append (Primary);
   end Keep_Only_Primary_Selection_Caret;

   function Primary_Selection_Is_Valid
     (S : Editor.State.State_Type) return Boolean
   is
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      pragma Unreferenced (Selection_Range);
   begin
      return Status = Editor.Selection.Selection_Ok;
   end Primary_Selection_Is_Valid;

   procedure Execute_Select_All_Selection_Command
     (S : in out Editor.State.State_Type)
   is
      Selection_Range : constant Editor.Selection.Active_Selection_Range :=
        Editor.Selection.Select_All_Range_For_Buffer (S);
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, "No active buffer.");
      elsif Selection_Range.High = 0 then
         Keep_Only_Primary_Selection_Caret (S);
         Set_Primary_Caret (S, 0);
         S.Rect_Select_Active := False;
         Report_Info (S, "Nothing to select");
      else
         Keep_Only_Primary_Selection_Caret (S);
         Editor.Selection.Apply_Active_Buffer_Selection
           (S, Selection_Range.Low, Selection_Range.High);
         S.Rect_Select_Active := False;
         S.Preferred_Column := 0;
         Report_Success (S, "Selected all");
      end if;

      Editor.State.Normalize_Carets (S);
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   exception
      when others =>
         Report_Error (S, "Could not update selection");
   end Execute_Select_All_Selection_Command;

   procedure Execute_Clear_Selection_Command
     (S : in out Editor.State.State_Type)
   is
      Caret : Cursor_Index := Safe_Caret (S);
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, "No active buffer.");
      elsif S.Carets.Length = 0 then
         Report_Info (S, "No caret location");
      elsif not Primary_Selection_Is_Valid (S) and then not S.Rect_Select_Active then
         Report_Info (S, "No selection");
      else
         Caret := Safe_Caret (S);
         Keep_Only_Primary_Selection_Caret (S);
         Set_Primary_Caret (S, Caret);
         S.Rect_Select_Active := False;
         Report_Success (S, "Selection cleared");
      end if;

      Editor.State.Normalize_Carets (S);
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   exception
      when others =>
         Report_Error (S, "Could not update selection");
   end Execute_Clear_Selection_Command;

   procedure Execute_Select_Current_Word_Command
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Selection_Range : Editor.Selection.Active_Selection_Range := (Low => 0, High => 0);
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, "No active buffer.");
      elsif S.Carets.Length = 0 then
         Report_Info (S, "No caret location");
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Report_Info (S, "No selectable word at cursor");
      else
         Selection_Range := Editor.Selection.Current_Word_Range_At_Caret (S, Found);
         if not Found then
            --  Preserve an existing useful selection on contextual failure.
            Report_Info (S, "No selectable word at cursor");
            Editor.State.Normalize_Carets (S);
            Editor.Render_Cache.Invalidate_All;
            Editor.Invariants.Check (S);
            return;
         end if;

         Keep_Only_Primary_Selection_Caret (S);
         Editor.Selection.Apply_Active_Buffer_Selection
           (S, Selection_Range.Low, Selection_Range.High);
         S.Rect_Select_Active := False;
         S.Preferred_Column := Natural (Selection_Range.High - Selection_Range.Low);
         Report_Success (S, "Selected current word");
      end if;

      Editor.State.Normalize_Carets (S);
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   exception
      when others =>
      Report_Error (S, "Could not update selection");
   end Execute_Select_Current_Word_Command;

   function Execute_Selection_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);

      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result
      is
         Found : Boolean := False;
         Msg   : Editor.Messages.Editor_Message;
      begin
         if Editor.Messages.Count (S.Messages) > Before_Messages then
            Msg := Editor.Messages.Active_Message (S.Messages, Found);
            if Found then
               if Editor.Messages.Severity (Msg) =
                 Editor.Messages.Error_Message
               then
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
   begin
      case Id is
         when Editor.Commands.Command_Select_All =>
            Execute_Select_All_Selection_Command (S);

         when Editor.Commands.Command_Selection_Clear =>
            Execute_Clear_Selection_Command (S);

         when Editor.Commands.Command_Select_Word =>
            Execute_Select_Current_Word_Command (S);

         when others =>
            raise Program_Error with "unsupported selection result command";
      end case;

      Editor.Buffers.Sync_Global_Active_From_State (S);
      return Result_After_Command (Id);
   end Execute_Selection_Result_Command;

   procedure Execute_Start_Rectangular_Selection
     (S : in out Editor.State.State_Type)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Start_Rectangle_At_Caret;
      Execute_No_Log (S, Cmd);
   end Execute_Start_Rectangular_Selection;

   procedure Execute_Set_Rectangular_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Editor.Selection.Text_Position;
      Cursor : Editor.Selection.Text_Position)
   is
      R : constant Editor.Selection.Rectangular_Range :=
        Editor.Selection.Normalize_Rectangular_Range (Anchor, Cursor);
      Rectangle_Range : Editor.Rectangle_Selection.Rectangle_Range;
   begin
      S.Rect_Select_Active := True;
      S.Rect_Anchor_Row := Anchor.Row;
      S.Rect_Anchor_Col := Anchor.Column;

      Rectangle_Range :=
        (First_Row => R.Start_Row,
         Last_Row  => R.End_Row,
         First_Col => R.Start_Column,
         Last_Col  => R.End_Column);

      Editor.Rectangle_Selection.Build_Carets (S, Rectangle_Range);

      --  Build_Carets creates the single rectangular selection as a
      --  per-row caret projection. Preferred_Column tracks the command cursor
      --  column for status/navigation while render/copy use the spans.
      S.Preferred_Column := Cursor.Column;
      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Cursor.Row);
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   end Execute_Set_Rectangular_Selection;

   procedure Execute_Clear_Rectangular_Selection
     (S : in out Editor.State.State_Type)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Clear_Rectangle_Selection;
      Execute_No_Log (S, Cmd);
   end Execute_Clear_Rectangular_Selection;

   procedure Execute_Select_Rectangle_To
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural)
   is
      Anchor : Editor.Selection.Text_Position;
      Cur_Row : Natural := 0;
      Cur_Col : Natural := 0;
   begin
      if S.Rect_Select_Active then
         Anchor := (Row => S.Rect_Anchor_Row, Column => S.Rect_Anchor_Col);
      else
         Editor.State.Row_Col_For_Index (S, Safe_Caret (S), Cur_Row, Cur_Col);
         if S.Carets.Length > 0
           and then S.Carets (S.Carets.First_Index).Virtual_Column > 0
         then
            Cur_Col := S.Carets (S.Carets.First_Index).Virtual_Column;
         end if;
         Anchor := (Row => Cur_Row, Column => Cur_Col);
      end if;

      Execute_Set_Rectangular_Selection
        (S      => S,
         Anchor => Anchor,
         Cursor => (Row => Row, Column => Column));
   end Execute_Select_Rectangle_To;


   procedure Execute_Select_Word_At
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural)
   is
      Target       : constant Editor.Selection.Selection_Target :=
        Editor.Selection.Word_Range_At (S, Row, Column);
      Fallback_Pos : constant Editor.Navigation.Navigation_Target :=
        Editor.Navigation.Clamp_Position (S, Row, Column);
      Fallback     : constant Cursor_Index :=
        Cursor_Index
          (Index_For_Line_Column
             (S, Fallback_Pos.Row, Fallback_Pos.Column));
      Start_Pos    : Natural := 0;
      End_Pos      : Natural := 0;
   begin
      Keep_Only_Primary_Selection_Caret (S);
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
         S.Carets.Append
           (Editor.Cursors.Caret_State'
          (Pos                   => Cursor_Index (End_Pos),
             Anchor                => Cursor_Index (Start_Pos),
             Virtual_Column        => 0,
             Anchor_Virtual_Column => 0));
         S.Preferred_Column := Target.Selection_Range.End_Position.Column;
      else
         S.Carets.Append
           (Editor.Cursors.Caret_State'
          (Pos                   => Fallback,
             Anchor                => Fallback,
             Virtual_Column        => 0,
             Anchor_Virtual_Column => 0));
         S.Preferred_Column := Fallback_Pos.Column;
      end if;

      Editor.State.Normalize_Carets (S);
      Editor.Render_Cache.Invalidate_All;
      Editor.Invariants.Check (S);
   end Execute_Select_Word_At;

   procedure Execute_Extend_Selection_By_Word
     (S         : in out Editor.State.State_Type;
      Direction : Editor.Navigation.Navigation_Direction)
   is
      Cmd : Editor.Commands.Command;
   begin
      case Direction is
         when Editor.Navigation.Backward =>
            Cmd.Kind := Editor.Commands.Select_Word_Left;
            Cmd.Shift := True;
         when Editor.Navigation.Forward =>
            Cmd.Kind := Editor.Commands.Select_Word_Right;
            Cmd.Shift := True;
      end case;

      Execute_No_Log (S, Cmd);
   end Execute_Extend_Selection_By_Word;


end Editor.Executor.Selection_Commands;
