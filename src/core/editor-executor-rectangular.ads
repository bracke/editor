with Editor.State;
with Editor.Commands;
with Editor.Cursors;

package Editor.Executor.Rectangular is

   procedure Execute
     (S                    : in out Editor.State.State_Type;
      Cmd                  : Editor.Commands.Command;
      New_Caret            : out Editor.Cursors.Cursor_Index;
      New_Preferred_Column : out Natural);

end Editor.Executor.Rectangular;