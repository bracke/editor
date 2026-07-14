with Editor.State;

package Editor.Executor.Project_Search_Result_Commands is

   procedure Refresh_Project_Search_After_File_Lifecycle
     (S : in out Editor.State.State_Type);

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String);
   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type);
   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type);
   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type);
   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural);
   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type);
   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type);
   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type);
   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type);
   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type);
   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type);
   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type);
   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type);

end Editor.Executor.Project_Search_Result_Commands;
