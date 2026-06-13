with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.State;

package Editor.Configuration_Audit is

   type Configuration_Audit_Status is
     (Configuration_Audit_Ok,
      Configuration_Audit_Failed);

   type Configuration_Domain is
     (Settings_Domain,
      Keybindings_Domain,
      Workspace_Domain,
      Recent_Projects_Domain,
      Runtime_State_Domain);

   type Configuration_Audit_Result is private;


   type Buffer_Boundary_Audit_Summary is record
      Buffer_Metadata_Coherent       : Boolean := True;
      Active_Buffer_Valid            : Boolean := True;
      Selected_Buffer_Valid          : Boolean := True;
      Buffer_List_Selected_Row_Valid : Boolean := True;
      Buffer_List_Selected_Row_Is_Buffer : Boolean := True;
      Buffer_List_Selected_Runtime_Id_Registered : Boolean := True;
      Buffer_List_Selection_Cleared_When_No_Rows : Boolean := True;
      Buffer_List_Selection_Index_Clamped_To_Rows : Boolean := True;
      Buffer_List_Selection_Is_Transient : Boolean := True;
      Pending_Runtime_Buffer_Id_Transient : Boolean := True;
      Pending_File_Conflict_Token_Transient : Boolean := True;
      Pending_Buffer_Id_Not_Persisted : Boolean := True;
      Pending_Buffer_Id_Not_Command_Payload : Boolean := True;
      Pending_Buffer_Id_Not_Keybinding_Payload : Boolean := True;
      Pending_Buffer_Id_Not_Render_Payload : Boolean := True;
      Pending_File_Token_Not_Persisted : Boolean := True;
      Pending_File_Token_Not_Rendered : Boolean := True;
      Pending_Target_Revalidated_Before_Mutation : Boolean := True;
      Pending_Transition_Boundary_Safe : Boolean := True;
      File_Conflict_Prompt_Transient : Boolean := True;
      File_Conflict_Prompt_Buffer_Id_Not_Persisted : Boolean := True;
      File_Conflict_Prompt_Buffer_Id_Not_Command_Payload : Boolean := True;
      File_Conflict_Prompt_Buffer_Id_Not_Keybinding_Payload : Boolean := True;
      File_Conflict_Prompt_Buffer_Id_Not_Render_Payload : Boolean := True;
      File_Conflict_Prompt_Token_Not_Persisted : Boolean := True;
      File_Conflict_Prompt_Token_Not_Rendered : Boolean := True;
      File_Conflict_Prompt_Display_Hides_Runtime_Buffer_Id : Boolean := True;
      File_Conflict_Prompt_Display_Hides_File_Token : Boolean := True;
      File_Conflict_Prompt_Revalidated_Before_Mutation : Boolean := True;
      File_Conflict_Prompt_Boundary_Safe : Boolean := True;
      Workspace_Persistence_Safe     : Boolean := True;
      Command_Keybinding_Payloads_Clear : Boolean := True;
      Render_Boundary_Safe           : Boolean := True;
      Render_Uses_Metadata_Snapshots_Only : Boolean := True;
      Render_Does_Not_Switch_Buffers : Boolean := True;
      Render_Does_Not_Close_Buffers  : Boolean := True;
      Render_Does_Not_Save_Reload_Revert : Boolean := True;
      Render_Does_Not_Probe_Filesystem : Boolean := True;
      Render_Does_Not_Classify_By_Mutation : Boolean := True;
      Render_Does_Not_Expose_Runtime_Buffer_Ids : Boolean := True;
      Render_Buffer_List_Metadata_Projection_Only : Boolean := True;
      Render_Active_Buffer_Metadata_Projection_Only : Boolean := True;
      Audit_Side_Effect_Free         : Boolean := True;
      Runtime_Buffer_Id_Persisted    : Boolean := False;
      Active_Runtime_Id_Persisted    : Boolean := False;
      Selected_Runtime_Id_Persisted  : Boolean := False;
      Buffer_List_State_Persisted    : Boolean := False;
      Dirty_Text_Persisted           : Boolean := False;
      Scratch_Text_Persisted         : Boolean := False;
      Conflict_Token_Persisted       : Boolean := False;
      Close_Prompt_State_Persisted   : Boolean := False;
      Undo_Redo_Clipboard_Persisted  : Boolean := False;
      Buffer_Count                   : Natural := 0;
      Workspace_Persistable_Count    : Natural := 0;
      Workspace_Not_Persistable_Count : Natural := 0;
      Dirty_Project_File_Count       : Natural := 0;
      Dirty_Outside_Project_Count    : Natural := 0;
      Dirty_Scratch_Count            : Natural := 0;
      Dirty_Conflicted_Count         : Natural := 0;
      Dirty_Unwritable_Count         : Natural := 0;
   end record;

   type Configuration_State_Summary is record
      Theme_Id                         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Line_Number_Mode                 : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Cursor_Blink_Enabled             : Boolean := True;
      Active_Keybinding_Count          : Natural := 0;
      Save_File_Chord                  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Command_Palette_Chord            : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Command_Palette_Show_Keybindings : Boolean := True;
      Has_Project                      : Boolean := False;
      Recent_Project_Count             : Natural := 0;
      Dirty_Buffer_Count               : Natural := 0;
      Has_Pending_Transition           : Boolean := False;
      Message_Count                    : Natural := 0;
   end record;

   --  Reset Result to the successful, empty-failure state.
   --  @param Result audit result to clear
   procedure Clear
     (Result : in out Configuration_Audit_Result);

   --  Append a deterministic domain-qualified failure message.
   --  This mutates only Result and never inspects or mutates editor state.
   --  @param Result audit result to update
   --  @param Domain configuration domain associated with the failure
   --  @param Message failure text to append
   procedure Add_Failure
     (Result  : in out Configuration_Audit_Result;
      Domain  : Configuration_Domain;
      Message : String);

   --  Return the aggregate audit status.
   --  @param Result audit result to inspect
   --  @return Configuration_Audit_Failed when at least one failure is present
   function Status
     (Result : Configuration_Audit_Result)
      return Configuration_Audit_Status;

   --  Return the number of recorded audit failures.
   --  @param Result audit result to inspect
   --  @return failure count
   function Failure_Count
     (Result : Configuration_Audit_Result) return Natural;

   --  Return a one-based failure message.
   --  @param Result audit result to inspect
   --  @param Index one-based failure index
   --  @return failure message, or the empty string when Index is out of range
   function Failure
     (Result : Configuration_Audit_Result;
      Index  : Positive) return String;

   --  Return a compact human-readable result summary.
   --  @param Result audit result to summarize
   --  @return deterministic audit summary text
   function Summary
     (Result : Configuration_Audit_Result) return String;


   --  Phase 577 configuration-audit integration for buffer metadata and
   --  lifecycle boundaries.  This projects the buffer-local audit, the actual
   --  serialized workspace text audit, and the no-payload route boundary into
   --  the configuration audit result surface.  It is observational only: it
   --  never executes commands, mutates buffers, saves files, reloads files, or
   --  persists audit results.
   function Buffer_Boundary_Audit_For
     (State                : Editor.State.State_Type;
      Serialized_Workspace : String := "") return Buffer_Boundary_Audit_Summary;

   procedure Audit_Buffer_Metadata_Lifecycle_Boundaries
     (Result               : in out Configuration_Audit_Result;
      State                : Editor.State.State_Type;
      Serialized_Workspace : String := "");

   --  Return True only when the complete Phase 577 buffer metadata,
   --  lifecycle, persistence, route, pending-transition, prompt, render,
   --  and audit side-effect boundaries are simultaneously satisfied.  This
   --  is a single milestone assertion for tests and release verification; it
   --  is observational only and never repairs state or executes commands.
   function Phase_577_Buffer_Metadata_Lifecycle_Complete
     (State                : Editor.State.State_Type;
      Serialized_Workspace : String := "") return Boolean;

   --  Build a side-effect-free summary of global configuration state.
   --  The summary is intended for lifecycle/configuration regression tests.
   --  It does not load files, normalize state, execute commands, or repair
   --  invalid configuration.
   --  @param State Editor state to inspect.
   --  @return Configuration-relevant state summary.
   function Configuration_State_Summary_For
     (State : Editor.State.State_Type) return Configuration_State_Summary;

   --  Compare fields that configuration commands must not mutate except by
   --  their own domain. Message count is intentionally excluded because a
   --  command may legitimately emit one primary outcome message.
   --  @param Result audit result to update
   --  @param Before expected summary
   --  @param After observed summary
   --  @param Context failure-message prefix
   procedure Expect_No_Runtime_Or_Lifecycle_Mutation
     (Result  : in out Configuration_Audit_Result;
      Before  : Configuration_State_Summary;
      After   : Configuration_State_Summary;
      Context : String);

private
   package Failure_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   type Configuration_Audit_Result is record
      Failures : Failure_Vectors.Vector;
   end record;

end Editor.Configuration_Audit;
