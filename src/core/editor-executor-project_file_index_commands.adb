with Editor.Executor.File_Tree_Commands;
with Editor.State;

package body Editor.Executor.Project_File_Index_Commands is

   procedure Execute_Refresh_File_Tree
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Tree_Commands.Execute_Refresh_File_Tree;
   procedure Execute_Refresh_Project_Files
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Tree_Commands.Execute_Refresh_Project_Files;
   procedure Execute_Project_Files_Summary
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Tree_Commands.Execute_Project_Files_Summary;
   procedure Execute_Reveal_Active_File_In_Tree
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Tree_Commands.Execute_Reveal_Active_File_In_Tree;

end Editor.Executor.Project_File_Index_Commands;
