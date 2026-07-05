with Editor.State;

package Editor.Executor.Project_File_Index_Commands is

   procedure Execute_Refresh_File_Tree (S : in out Editor.State.State_Type);
   procedure Execute_Refresh_Project_Files (S : in out Editor.State.State_Type);
   procedure Execute_Project_Files_Summary (S : in out Editor.State.State_Type);
   procedure Execute_Reveal_Active_File_In_Tree (S : in out Editor.State.State_Type);

end Editor.Executor.Project_File_Index_Commands;
