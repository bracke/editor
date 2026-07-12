with Editor.State;
with Editor.File_Tree;

package Editor.Executor.Project_File_Index_Commands is

   procedure Refresh_Project_File_State
     (S : in out Editor.State.State_Type;
      Result : out Editor.File_Tree.File_Tree_Scan_Result;
      Selection_Disappeared : out Boolean;
      Update_Known_Files : Boolean := True);

   procedure Execute_Refresh_File_Tree (S : in out Editor.State.State_Type);
   procedure Execute_Refresh_Project_Files (S : in out Editor.State.State_Type);
   procedure Execute_Project_Files_Summary (S : in out Editor.State.State_Type);
   procedure Execute_Reveal_Active_File_In_Tree (S : in out Editor.State.State_Type);

end Editor.Executor.Project_File_Index_Commands;
