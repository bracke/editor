with Editor.Commands.Payloads;
with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Edits;
with Editor.State;

package Editor.Executor.Text_Entry_Commands is

   procedure Execute_Text_Entry_Command
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Had_Selection   : Boolean;
      Sel_Start       : Editor.Cursors.Cursor_Index;
      Sel_End         : Editor.Cursors.Cursor_Index;
      Old_Caret       : Editor.Cursors.Cursor_Index;
      New_Caret       : out Editor.Cursors.Cursor_Index;
      Forward_Cmd     : out Editor.Commands.Payloads.Command;
      Should_Log_Edit : out Boolean;
      Line_Status     : out Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Text_Entry_Commands;
