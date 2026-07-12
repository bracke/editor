with Ada.Containers;

with Text_Buffer;

with Editor.Buffers;
with Editor.Clipboard;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Line_Edit_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Clipboard;
with Editor.Executor.Edits;
with Editor.Executor.History;
with Editor.History;
with Editor.Messages;
with Editor.Render_Cache;
with Editor.Selection;

package body Editor.Executor.Editing_Commands is

   use type Ada.Containers.Count_Type;
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

   procedure Report_Editing_Status
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Status : Editor.Executor.Edits.Line_Edit_Status)
   is
   begin
      case Status is
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
         when Editor.Executor.Edits.No_Caret_Location =>
            Report_Info (S, "No caret location");
         when Editor.Executor.Edits.Nothing_To_Trim =>
            Report_Info (S, "Nothing to trim");
         when Editor.Executor.Edits.Trailing_Whitespace_Trimmed =>
            Report_Success (S, "Trimmed trailing whitespace");
         when Editor.Executor.Edits.Trim_Trailing_Whitespace_Failed =>
            Report_Error (S, "Could not trim trailing whitespace");
         when Editor.Executor.Edits.Nothing_To_Delete =>
            Report_Info (S, "Nothing to delete");
         when Editor.Executor.Edits.Previous_Character_Deleted =>
            Report_Success (S, "Deleted previous character");
         when Editor.Executor.Edits.Next_Character_Deleted =>
            Report_Success (S, "Deleted next character");
         when Editor.Executor.Edits.Delete_Previous_Character_Failed =>
            Report_Error (S, "Could not delete previous character");
         when Editor.Executor.Edits.Delete_Next_Character_Failed =>
            Report_Error (S, "Could not delete next character");
         when Editor.Executor.Edits.Previous_Word_Deleted =>
            Report_Success (S, "Deleted previous word");
         when Editor.Executor.Edits.Next_Word_Deleted =>
            Report_Success (S, "Deleted next word");
         when Editor.Executor.Edits.Delete_Previous_Word_Failed =>
            Report_Error (S, "Could not delete previous word");
         when Editor.Executor.Edits.Delete_Next_Word_Failed =>
            Report_Error (S, "Could not delete next word");
         when others =>
            Report_Error (S, "Could not edit text");
      end case;
   end Report_Editing_Status;

   function Has_Buffer (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.State.Has_Active_Buffer (S);
   end Has_Buffer;

   function Is_Trailing_Whitespace_Character
     (Ch : Character) return Boolean
   is
   begin
      return Ch = ' ' or else Ch = ASCII.HT;
   end Is_Trailing_Whitespace_Character;

   function Row_For_Buffer_Index
     (S     : Editor.State.State_Type;
      Index : Editor.Cursors.Cursor_Index) return Natural
   is
      Limit : constant Natural :=
        Natural'Min (Natural (Index), Text_Buffer.Length (S.Buffer));
      Row   : Natural := 0;
   begin
      if Limit = 0 then
         return 0;
      end if;

      for Pos in 0 .. Limit - 1 loop
         if Text_Buffer.Character_At (S.Buffer, Pos) = ASCII.LF then
            Row := Row + 1;
         end if;
      end loop;

      return Row;
   end Row_For_Buffer_Index;

   function Trim_Trailing_Whitespace_Would_Change
     (S : Editor.State.State_Type) return Boolean
   is
      Len              : constant Natural := Text_Buffer.Length (S.Buffer);
      Line_Start       : Natural := 0;
      I                : Natural := 0;
      Line_End         : Natural := 0;
      Row              : Natural := 0;
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Selection_Status : Editor.Selection.Selection_Validation_Status;
      First_Row        : Natural := 0;
      Last_Row         : Natural := 0;
      Trim_Selected    : Boolean := False;
   begin
      if Len = 0 then
         return False;
      end if;

      Selection_Status := Editor.Selection.Validate_Active_Selection_Range
        (S, Selection_Range);
      if Selection_Status = Editor.Selection.Selection_Ok
        and then not S.Rect_Select_Active
        and then S.Carets.Length = 1
      then
         First_Row := Row_For_Buffer_Index (S, Selection_Range.Low);
         Last_Row := Row_For_Buffer_Index (S, Selection_Range.High - 1);
         Trim_Selected := True;
      end if;

      while Line_Start <= Len loop
         I := Line_Start;

         while I < Len
           and then Text_Buffer.Character_At (S.Buffer, I) /= ASCII.LF
         loop
            I := I + 1;
         end loop;

         Line_End := I;

         if (not Trim_Selected)
           or else (Row >= First_Row and then Row <= Last_Row)
         then
            if Line_End > Line_Start
              and then Is_Trailing_Whitespace_Character
                (Text_Buffer.Character_At (S.Buffer, Line_End - 1))
            then
               return True;
            end if;
         end if;

         exit when I >= Len;
         Line_Start := I + 1;
         Row := Row + 1;
      end loop;

      return False;
   end Trim_Trailing_Whitespace_Would_Change;

   function Editing_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Undo =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Buffers.Global_Registry_Current_For (S) then
               return Editor.Commands.Unavailable ("No edits to undo");
            elsif Editor.History.Undo_Stack.Is_Empty then
               return Editor.Commands.Unavailable ("No edits to undo");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Redo =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Buffers.Global_Registry_Current_For (S) then
               return Editor.Commands.Unavailable ("No edits to redo");
            elsif Editor.History.Redo_Stack.Is_Empty then
               return Editor.Commands.Unavailable ("No edits to redo");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Edit_History_Clear =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif Editor.History.Undo_Stack.Is_Empty
              and then Editor.History.Redo_Stack.Is_Empty
            then
               return Editor.Commands.Unavailable ("No edit history to clear");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut =>
            return Editor.Executor.Clipboard.Copy_Cut_Availability (S);

         when Editor.Commands.Command_Paste =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Clipboard.Has_Text then
               return Editor.Commands.Unavailable ("Clipboard is empty");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Clipboard_Clear =>
            if not Editor.Clipboard.Has_Text then
               return Editor.Commands.Unavailable ("Clipboard is empty");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Selection_Delete =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0 then
               return Editor.Commands.Unavailable ("No caret location");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Format_Buffer =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0 then
               return Editor.Commands.Unavailable ("No caret location");
            elsif not Trim_Trailing_Whitespace_Would_Change (S) then
               return Editor.Commands.Unavailable ("No trailing whitespace");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Format_Selected_Text =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0 then
               return Editor.Commands.Unavailable ("No caret location");
            elsif not Editor.Selection.Has_Selection (S)
              and then not S.Rect_Select_Active
            then
               return Editor.Commands.Unavailable ("No selection");
            elsif not Trim_Trailing_Whitespace_Would_Change (S) then
               return Editor.Commands.Unavailable ("No trailing whitespace");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next =>
            if not Has_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0 then
               return Editor.Commands.Unavailable ("No caret location");
            end if;
            return Editor.Commands.Available;

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
            | Editor.Commands.Command_Line_Split_At_Caret
            =>
            return Editor.Executor.Line_Edit_Commands.Line_Edit_Command_Availability
              (S, Id);

         when others =>
            return Editor.Commands.Unavailable ("Not an editing command");
      end case;
   end Editing_Command_Availability;

   procedure Report_Clipboard_Status
     (S       : in out Editor.State.State_Type;
      Command : Editor.Commands.Command_Id)
   is
      pragma Unreferenced (Command);
      Status : constant Editor.Executor.Clipboard.Clipboard_Execution_Status :=
        Editor.Executor.Clipboard.Last_Status;
   begin
      case Status is
         when Editor.Executor.Clipboard.Clipboard_Copied =>
            Report_Success (S, "Copied selection");
         when Editor.Executor.Clipboard.Clipboard_Cut =>
            Report_Success (S, "Cut selection");
         when Editor.Executor.Clipboard.Clipboard_Pasted =>
            Report_Success (S, "Pasted clipboard");
         when Editor.Executor.Clipboard.Clipboard_Cleared =>
            Report_Success (S, "Clipboard cleared");
         when Editor.Executor.Clipboard.Clipboard_No_Active_Buffer =>
            Report_Info (S, "No active buffer.");
         when Editor.Executor.Clipboard.Clipboard_No_Selected_Text =>
            Report_Info (S, "No selected text");
         when Editor.Executor.Clipboard.Clipboard_Invalid_Selection =>
            Report_Info (S, "Invalid selection");
         when Editor.Executor.Clipboard.Clipboard_Selection_Not_Supported =>
            Report_Info (S, "Clipboard selection must be single-line");
         when Editor.Executor.Clipboard.Clipboard_Text_Not_Supported =>
            Report_Info (S, "Clipboard text must be single-line");
         when Editor.Executor.Clipboard.Clipboard_No_Text =>
            Report_Info (S, "Clipboard is empty");
         when Editor.Executor.Clipboard.Clipboard_Copy_Failed =>
            Report_Error (S, "Could not copy selection");
         when Editor.Executor.Clipboard.Clipboard_Cut_Failed =>
            Report_Error (S, "Could not cut selection");
         when Editor.Executor.Clipboard.Clipboard_Paste_Failed =>
            Report_Error (S, "Could not paste clipboard");
         when Editor.Executor.Clipboard.Clipboard_Nothing_To_Clear =>
            Report_Info (S, "No clipboard to clear");
      end case;
   end Report_Clipboard_Status;

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
               when Editor.Commands.Command_Trim_Trailing_Whitespace =>
                  Report_Error (S, "Could not trim trailing whitespace");
               when Editor.Commands.Command_Format_Buffer =>
                  Report_Error (S, "Could not format buffer");
               when Editor.Commands.Command_Format_Selected_Text =>
                  Report_Error (S, "Could not format selection");
               when Editor.Commands.Command_Char_Delete_Previous =>
                  Report_Error (S, "Could not delete previous character");
               when Editor.Commands.Command_Char_Delete_Next =>
                  Report_Error (S, "Could not delete next character");
               when Editor.Commands.Command_Word_Delete_Previous =>
                  Report_Error (S, "Could not delete previous word");
               when Editor.Commands.Command_Word_Delete_Next =>
                  Report_Error (S, "Could not delete next word");
               when Editor.Commands.Command_Selection_Delete =>
                  Report_Error (S, "Could not delete selection");
               when others =>
                  Report_Error (S, "Could not edit line");
            end case;
         when Editor.Executor.Edits.Line_Edit_None =>
            null;
      end case;
   end Report_Line_Edit_Status;

   function Execute_Editing_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
      Cmd             : Editor.Commands.Command;
      Line_Status     : Editor.Executor.Edits.Line_Edit_Status;

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
         when Editor.Commands.Command_Undo =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Executor.History.Clear_Operation_Status;
            Editor.Executor.Execute_No_Log (S, Cmd);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            if Editor.Executor.History.Last_Operation_Failed then
               Report_Error (S, "Could not undo edit");
            else
               Report_Success (S, "Undid edit");
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Redo =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Executor.History.Clear_Operation_Status;
            Editor.Executor.Execute_No_Log (S, Cmd);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            if Editor.Executor.History.Last_Operation_Failed then
               Report_Error (S, "Could not redo edit");
            else
               Report_Success (S, "Redid edit");
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Edit_History_Clear =>
            Editor.History.Undo_Stack.Clear;
            Editor.History.Redo_Stack.Clear;
            Editor.Buffers.Sync_Global_Active_From_State (S);
            Report_Success (S, "Undo history cleared");
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Clipboard_Clear =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Executor.Execute_No_Log (S, Cmd);
            if Id = Editor.Commands.Command_Cut
              or else Id = Editor.Commands.Command_Paste
            then
               Editor.Buffers.Sync_Global_Active_From_State (S);
            end if;
            Report_Clipboard_Status (S, Id);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

        when Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Format_Buffer
            | Editor.Commands.Command_Format_Selected_Text
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next =>
            Cmd := Editor.Commands.Command_For_Id (Id, Shift);
            Editor.Executor.Execute_No_Log_With_Status (S, Cmd, Line_Status);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            Report_Editing_Status (S, Id, Line_Status);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

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
            return Editor.Executor.Line_Edit_Commands.Execute_Line_Edit_Command
              (S, Id, Shift);

         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;
   end Execute_Editing_Command;

end Editor.Executor.Editing_Commands;
