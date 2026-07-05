with Editor.Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.State;

package body Editor.Executor.File_Tree_Mutation_Commands is

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      renames Editor.Executor.File_Tree_Commands.Execute_File_Tree_Create_File;
   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      renames Editor.Executor.File_Tree_Commands.Execute_File_Tree_Create_Directory;
   procedure Execute_File_Tree_Rename_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      renames Editor.Executor.File_Tree_Commands.Execute_File_Tree_Rename_Selected;
   procedure Execute_File_Tree_Delete_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      renames Editor.Executor.File_Tree_Commands.Execute_File_Tree_Delete_Selected;

end Editor.Executor.File_Tree_Mutation_Commands;
