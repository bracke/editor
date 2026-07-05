with Editor.State;

package Editor.Executor.Project_Search_Replace_Commands is

   procedure Execute_Project_Search_Replace_Preview (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Toggle_Selected (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Include_Selected (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Exclude_Selected (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Include_File (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Exclude_File (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Include_All (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Exclude_All (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Selected (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_All_Included (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Replace_Clear_Preview (S : in out Editor.State.State_Type);

end Editor.Executor.Project_Search_Replace_Commands;
