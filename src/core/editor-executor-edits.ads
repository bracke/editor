with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;
with Editor.Commands;
with Editor.Cursors; use Editor.Cursors;

package Editor.Executor.Edits is

   type Line_Edit_Status is
     (Line_Edit_None,
      Line_Deleted,
      Line_Duplicated,
      Line_Moved_Up,
      Line_Moved_Down,
      Line_Indented,
      Line_Outdented,
      Line_Commented,
      Line_Uncommented,
      Line_Joined,
      Line_Split,
      Trailing_Whitespace_Trimmed,
      Text_Inserted,
      Selection_Replaced,
      Previous_Character_Deleted,
      Next_Character_Deleted,
      Previous_Word_Deleted,
      Next_Word_Deleted,
      Selection_Deleted,
      Nothing_Selected,
      Invalid_Selection,
      Selection_Delete_Failed,
      No_Active_Buffer,
      Nothing_To_Insert,
      Invalid_Text_Input,
      Text_Insert_Failed,
      Line_Already_Commented,
      Nothing_To_Delete,
      Nothing_To_Duplicate,
      Nothing_To_Indent,
      Nothing_To_Outdent,
      Nothing_To_Comment,
      Nothing_To_Uncomment,
      Nothing_To_Join,
      Nothing_To_Split,
      Nothing_To_Trim,
      Comment_Failed,
      Uncomment_Failed,
      Line_Join_Failed,
      Line_Split_Failed,
      Trim_Trailing_Whitespace_Failed,
      Delete_Previous_Character_Failed,
      Delete_Next_Character_Failed,
      Delete_Previous_Word_Failed,
      Delete_Next_Word_Failed,
      Already_First_Line,
      Already_Last_Line,
      No_Caret_Location,
      Line_Edit_Failed);

   procedure Execute
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Had_Selection   : Boolean;
      Sel_Start       : Editor.Cursors.Cursor_Index;
      Sel_End         : Editor.Cursors.Cursor_Index;
      Old_Caret       : Editor.Cursors.Cursor_Index;
      New_Caret       : out Editor.Cursors.Cursor_Index;
      Forward_Cmd     : out Editor.Commands.Command;
      Should_Log_Edit : out Boolean;
      Line_Status     : out Line_Edit_Status);

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String);

end Editor.Executor.Edits;