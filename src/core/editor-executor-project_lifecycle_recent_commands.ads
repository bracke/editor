with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Project_Lifecycle_Recent_Commands is

   procedure Execute_Select_Next_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Previous_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Show_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Remove_Selected_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Remove_Missing_Recent_Projects
     (S : in out Editor.State.State_Type);

   function Execute_Project_Lifecycle_Recent_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Project_Lifecycle_Recent_Commands;
