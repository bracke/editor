with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Edits;
with Editor.State;

package Editor.Executor.Indentation_Commands is

   procedure Perform_Indent_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Outdent_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Comment_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Uncomment_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Toggle_Current_Line_Comment
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Indentation_Commands;
