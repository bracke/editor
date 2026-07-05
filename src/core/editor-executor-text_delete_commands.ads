with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Edits;
with Editor.State;

package Editor.Executor.Text_Delete_Commands is

   procedure Perform_Delete_Previous_Character
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Delete_Next_Character
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Delete_Previous_Word
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Delete_Next_Word
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Text_Delete_Commands;
