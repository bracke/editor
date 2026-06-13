with Editor.State;
with Editor.Commands;
with Editor.Cursors;

package Editor.Executor.Navigation is

   procedure Execute
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      Had_Selection        : Boolean;
      Sel_Start            : Editor.Cursors.Cursor_Index;
      Old_Caret            : Editor.Cursors.Cursor_Index;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural);

   procedure Select_Line_Range
     (S                    : in out Editor.State.State_Type;
      Anchor_Row           : Natural;
      Target_Row           : Natural;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural);

end Editor.Executor.Navigation;