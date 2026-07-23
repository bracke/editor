with Editor.Commands;
with Editor.State;

package Editor.Executor.File_Tree_Create_Commands is

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.File_Tree_Create_Commands;
