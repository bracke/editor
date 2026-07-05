with Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Files;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.State;

package Editor.Executor.File_Lifecycle_Commands is

   procedure Lifecycle_Command_Availability
     (S        : Editor.State.State_Type;
      Id       : Editor.Commands.Command_Id;
      Handled  : out Boolean;
      Result   : out Editor.Commands.Command_Availability);

   function Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Lifecycle_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Open_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   function Active_File_External_Status
     (S : Editor.State.State_Type) return Editor.Files.File_External_Change_Status;

   function External_Status_Code
     (Status : Editor.Files.File_External_Change_Status) return Natural;

   function Pending_File_State_Still_Current
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Boolean;

   procedure Execute_Save
     (S : in out Editor.State.State_Type);

   procedure Execute_Reload_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Revert_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Rename_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Delete_Buffer_File
     (S : in out Editor.State.State_Type);

   procedure Execute_Copy_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Move_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_File_Conflict_Cancel
     (S : in out Editor.State.State_Type);

   procedure Clear_File_Conflict_Prompt
     (S : in out Editor.State.State_Type);

   function File_Conflict_Prompt_Is_Valid
     (S : Editor.State.State_Type) return Boolean;

   procedure Execute_File_Conflict_Keep_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Reload_From_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Overwrite_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_All_Buffers_Confirmed
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Other_Buffers_Confirmed
     (S  : in out Editor.State.State_Type;
      Active : Editor.Buffers.Buffer_Id);

   procedure Finalize_Cleanup_Buffer_Close
     (S          : in out Editor.State.State_Type;
      Id         : Editor.Buffers.Buffer_Id;
      Was_Active : Boolean);

   function Dirty_Close_Start_Message
     (All_Buffers : Boolean;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String;

   function Dirty_Buffer_Summary_For_All_Buffers
     return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Dirty_Buffer_Summary_For_All_Buffers
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Dirty_Close_Open_Buffer_Fingerprint return Natural;

   function Dirty_Close_Dirty_Buffer_Fingerprint return Natural;

   function Dirty_Close_Open_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String;

   function Dirty_Close_Dirty_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String;

   function Dirty_Close_Current_Dirty_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_Current_Dirty_Set_Equals_Review
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_Current_Open_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_All_Buffer_Identity_Current
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_All_Buffer_Review_Current
     (S : Editor.State.State_Type) return Boolean;

   procedure Start_Dirty_Close_Prompt
     (S           : in out Editor.State.State_Type;
      Scope       : Editor.State.Dirty_Close_Scope;
      All_Buffers : Boolean;
      Buffer_Id   : Editor.Buffers.Buffer_Id;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary);

   procedure Close_Buffer_By_Discard
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean);

   procedure Execute_Close_All_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Other_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_All_Clean_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Discard_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Cancel_Close
     (S : in out Editor.State.State_Type);

   procedure Execute_Confirm_Close_Discard
     (S : in out Editor.State.State_Type);

   procedure Execute_Confirm_Close_Save
     (S : in out Editor.State.State_Type);

   procedure Execute_Retry_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Cancel_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_New_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Switch_Buffer
     (S                : in out Editor.State.State_Type;
      Id               : Editor.Buffers.Buffer_Id;
      Recent_Traversal : Boolean := False;
      Emit_Feedback    : Boolean := True);

   procedure Clear_Reopen_Candidate
     (S : in out Editor.State.State_Type);

   procedure Execute_Reopen_Closed_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Buffer
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id);

end Editor.Executor.File_Lifecycle_Commands;
