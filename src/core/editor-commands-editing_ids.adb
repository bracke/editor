package body Editor.Commands.Editing_Ids is

   function Is_Editing_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Insert_Newline
            | Command_Undo
            | Command_Redo
            | Command_Edit_History_Clear
            | Command_Copy
            | Command_Cut
            | Command_Paste
            | Command_Clipboard_Clear
            | Command_Select_All
            | Command_Selection_Clear
            | Command_Selection_Delete
            | Command_Replace_Current
            | Command_Replace_All
            | Command_Line_Delete
            | Command_Line_Duplicate
            | Command_Line_Move_Up
            | Command_Line_Move_Down
            | Command_Indent_Increase
            | Command_Indent_Decrease
            | Command_Comment_Line
            | Command_Uncomment_Line
            | Command_Toggle_Line_Comment
            | Command_Line_Join_Next
            | Command_Line_Split_At_Caret
            | Command_Trim_Trailing_Whitespace
            | Command_Format_Buffer
            | Command_Format_Selected_Text
            | Command_Char_Delete_Previous
            | Command_Char_Delete_Next
            | Command_Word_Delete_Previous
            | Command_Word_Delete_Next =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Editing_Command;

end Editor.Commands.Editing_Ids;
