with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Edits;
with Editor.State;

package Editor.Executor.Format_Commands is

   procedure Perform_Trim_Trailing_Whitespace
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Format_Commands;
