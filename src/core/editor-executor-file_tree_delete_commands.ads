with Editor.Commands.Payloads;
with Editor.State;

package Editor.Executor.File_Tree_Delete_Commands is

   procedure Execute_File_Tree_Delete_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command);

end Editor.Executor.File_Tree_Delete_Commands;
