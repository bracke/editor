with Editor.Command_Kinds; use Editor.Command_Kinds;
with Editor.Commands.Payloads;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Commands; use Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor.Format_Commands;
with Editor.Executor.Indentation_Commands;
with Editor.Executor.Line_Edit_Commands;
with Editor.Executor.Text_Delete_Commands;
with Editor.Executor.Text_Entry_Commands;
with Editor.State;

package body Editor.Executor.Edits is

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Payloads.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;

   procedure Execute
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Had_Selection   : Boolean;
      Sel_Start       : Cursor_Index;
      Sel_End         : Cursor_Index;
      Old_Caret       : Cursor_Index;
      New_Caret       : out Cursor_Index;
      Forward_Cmd     : out Editor.Commands.Payloads.Command;
      Should_Log_Edit : out Boolean;
      Line_Status     : out Line_Edit_Status)
   is
   begin
      New_Caret := Old_Caret;
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Should_Log_Edit := False;
      Line_Status := Line_Edit_None;

      case Cmd.Kind is

         when Insert_Text_Input
            | Delete_Char
            | Forward_Delete_Char
            | Delete_Selection_Range
            | Editor.Command_Kinds.Paste_Text =>
            Editor.Executor.Text_Entry_Commands.Execute_Text_Entry_Command
              (S               => S,
               Cmd             => Cmd,
               Had_Selection   => Had_Selection,
               Sel_Start       => Sel_Start,
               Sel_End         => Sel_End,
               Old_Caret       => Old_Caret,
               New_Caret       => New_Caret,
               Forward_Cmd     => Forward_Cmd,
               Should_Log_Edit => Should_Log_Edit,
               Line_Status     => Line_Status);

         when Delete_Current_Line =>
            Editor.Executor.Line_Edit_Commands.Perform_Delete_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Duplicate_Current_Line =>
            Editor.Executor.Line_Edit_Commands.Perform_Duplicate_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Move_Current_Line_Up =>
            Editor.Executor.Line_Edit_Commands.Perform_Move_Current_Line
              (S, -1, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Move_Current_Line_Down =>
            Editor.Executor.Line_Edit_Commands.Perform_Move_Current_Line
              (S, 1, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Indent_Current_Line =>
            Editor.Executor.Indentation_Commands.Perform_Indent_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Outdent_Current_Line =>
            Editor.Executor.Indentation_Commands.Perform_Outdent_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Comment_Current_Line =>
            Editor.Executor.Indentation_Commands.Perform_Comment_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Uncomment_Current_Line =>
            Editor.Executor.Indentation_Commands.Perform_Uncomment_Current_Line
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Toggle_Current_Line_Comment =>
            Editor.Executor.Indentation_Commands.Perform_Toggle_Current_Line_Comment
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Join_Current_Line_With_Next =>
            Editor.Executor.Line_Edit_Commands.Perform_Join_Current_Line_With_Next
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Split_Current_Line_At_Caret =>
            Editor.Executor.Line_Edit_Commands.Perform_Split_Current_Line_At_Caret
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Trim_Trailing_Whitespace =>
            Editor.Executor.Format_Commands.Perform_Trim_Trailing_Whitespace
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Previous_Character =>
            Editor.Executor.Text_Delete_Commands.Perform_Delete_Previous_Character
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Next_Character =>
            Editor.Executor.Text_Delete_Commands.Perform_Delete_Next_Character
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Previous_Word =>
            Editor.Executor.Text_Delete_Commands.Perform_Delete_Previous_Word
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when Delete_Next_Word =>
            Editor.Executor.Text_Delete_Commands.Perform_Delete_Next_Word
              (S, New_Caret, Forward_Cmd, Should_Log_Edit, Line_Status);

         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.Edits;
