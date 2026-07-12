with Editor.Command_Execution;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Edits;
with Editor.State;

package Editor.Executor.Line_Edit_Commands is

   function Line_Edit_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Line_Edit_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Perform_Delete_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Duplicate_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Move_Current_Line
     (S           : in out Editor.State.State_Type;
      Direction   : Integer;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Join_Current_Line_With_Next
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

   procedure Perform_Split_Current_Line_At_Caret
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Editor.Cursors.Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Editor.Executor.Edits.Line_Edit_Status);

end Editor.Executor.Line_Edit_Commands;
