with Editor.Executor.Search_Commands;
with Editor.State;

package body Editor.Executor.Project_Search_Result_Commands is

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String)
      renames Editor.Executor.Search_Commands.Execute_Run_Project_Search;
   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Rerun_Project_Search;
   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_From_Selection;
   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_From_Active_Word;
   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Active_Directory;
   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Clear_Project_Search;
   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural)
      renames Editor.Executor.Search_Commands.Execute_Open_Project_Search_Result;
   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Open_Selected_Project_Search_Result;
   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Move_Project_Search_Selection_Down;
   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Move_Project_Search_Selection_Up;
   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Next_Project_Search_Result;
   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Previous_Project_Search_Result;
   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_First_Project_Search_Result;
   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Last_Project_Search_Result;
   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Reveal_Active_Project_Search_Result;

end Editor.Executor.Project_Search_Result_Commands;
