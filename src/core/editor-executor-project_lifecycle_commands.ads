with Editor.Commands;
with Editor.Command_Execution;
with Editor.State;
with Editor.Workspace_Persistence;
with Editor.Dirty_Guards;
with Editor.Buffers;

package Editor.Executor.Project_Lifecycle_Commands is

   function Project_Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Apply_Project_Open_Workspace_Policy
     (S      : in out Editor.State.State_Type;
      Config : Editor.Workspace_Persistence.Workspace_Lifecycle_Config :=
        Editor.Workspace_Persistence.Default_Workspace_Lifecycle_Config);

   procedure Execute_Select_Next_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Previous_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Show_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Selected_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Remove_Selected_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Remove_Missing_Recent_Projects
     (S : in out Editor.State.State_Type);

   function Execute_Project_Lifecycle_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   function Project_Dirty_Buffer_Summary
     (S : Editor.State.State_Type)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Current_Project_Lifecycle_Buffer_Sets
     (S : in out Editor.State.State_Type)
      return Editor.Buffers.Buffer_Project_Lifecycle_Sets;

   procedure Execute_Guarded_Close_Project
     (S : in out Editor.State.State_Type);

   procedure Populate_Project_Known_Files_From_File_Tree
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Project
     (S                        : in out Editor.State.State_Type;
      Path                     : String;
      Refresh_Build_Candidates : Boolean := True;
      Apply_Workspace_Policy   : Boolean := True;
      Recent_Project_Open      : Boolean := False;
      Explicit_Switch          : Boolean := False);

   procedure Execute_Project_Lifecycle_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Project_Lifecycle_Commands;
