with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;
with Editor.Workspace_Persistence;

package Editor.Executor.Workspace_Commands is

   function Workspace_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Restore_Summary_Message
     (Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Partial : Boolean) return String;

   procedure Report_Workspace_Load_Status
     (S      : in out Editor.State.State_Type;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status);

   procedure Mark_Restore_Summary_Current
     (S       : in out Editor.State.State_Type;
      Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary);

   procedure Report_Restore_Success
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Restore_Warning
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status);

   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : out Editor.Workspace_Persistence.Workspace_Restore_Summary);

   procedure Execute_Save_Workspace_State
     (S : in out Editor.State.State_Type);

   procedure Execute_Restore_Workspace_State
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Workspace_State
     (S : in out Editor.State.State_Type);

   function Execute_Workspace_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Workspace_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

end Editor.Executor.Workspace_Commands;
