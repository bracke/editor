with Editor.Executor.Search_Commands;
with Editor.State;

package body Editor.Executor.Project_Search_Replace_Commands is

   procedure Execute_Project_Search_Replace_Preview
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Preview;
   procedure Execute_Project_Search_Replace_Toggle_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Toggle_Selected;
   procedure Execute_Project_Search_Replace_Include_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Include_Selected;
   procedure Execute_Project_Search_Replace_Exclude_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Exclude_Selected;
   procedure Execute_Project_Search_Replace_Include_File
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Include_File;
   procedure Execute_Project_Search_Replace_Exclude_File
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Exclude_File;
   procedure Execute_Project_Search_Replace_Include_All
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Include_All;
   procedure Execute_Project_Search_Replace_Exclude_All
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Exclude_All;
   procedure Execute_Project_Search_Replace_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Selected;
   procedure Execute_Project_Search_Replace_All_Included
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_All_Included;
   procedure Execute_Project_Search_Replace_Clear_Preview
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Replace_Clear_Preview;

end Editor.Executor.Project_Search_Replace_Commands;
