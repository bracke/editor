with Ada.Strings.Unbounded;

package Editor.Build_Result_Summary is

   --  Phase 510 transient latest build result summary.  This is a small
   --  snapshot/projection model for the latest build.run outcome only.  It is
   --  not build history, not a command input, not persisted state, not
   --  Diagnostics row ownership, and never carries process handles, tokens, or
   --  rerun payloads.

   type Build_Result_Summary_Kind is
     (Build_Result_Summary_None,
      Build_Result_Summary_Succeeded,
      Build_Result_Summary_Failed,
      Build_Result_Summary_Unavailable,
      Build_Result_Summary_Timed_Out,
      Build_Result_Summary_Cancelled,
      Build_Result_Summary_Output_Truncated);

   type Build_Result_Request_Mode is
     (Build_Result_Request_None,
      Build_Result_Request_Manual,
      Build_Result_Request_Candidate_Derived,
      Build_Result_Request_Test_Or_Internal);

   Build_Result_Candidate_Derived : constant Build_Result_Request_Mode :=
     Build_Result_Request_Candidate_Derived;

   type Build_Result_Tool_Kind is
     (Build_Result_No_Tool,
      Build_Result_GPRbuild_Tool,
      Build_Result_Alire_Tool,
      Build_Result_Custom_Tool);

   type Diagnostics_Ingestion_Summary_Status is
     (Diagnostics_Ingestion_Not_Requested,
      Diagnostics_Ingestion_Disabled,
      Diagnostics_Ingestion_Succeeded,
      Diagnostics_Ingestion_No_Diagnostics,
      Diagnostics_Ingestion_Parse_Partial,
      Diagnostics_Ingestion_Failed);

   type Latest_Build_Result_Summary is record
      Has_Result : Boolean := False;
      Kind       : Build_Result_Summary_Kind := Build_Result_Summary_None;
      Invocation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Tool_Kind : Build_Result_Tool_Kind := Build_Result_No_Tool;
      Request_Mode : Build_Result_Request_Mode := Build_Result_Request_None;
      Working_Context_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Runner_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Exit_Code_If_Available : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Timed_Out : Boolean := False;
      Cancelled : Boolean := False;
      Cancellation_Unsupported : Boolean := False;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Diagnostics_Ingestion_Status : Diagnostics_Ingestion_Summary_Status :=
        Diagnostics_Ingestion_Not_Requested;
      Diagnostics_Count_If_Available : Natural := 0;
      Has_Diagnostics_Count : Boolean := False;
      Diagnostics_Error_Count : Natural := 0;
      Diagnostics_Warning_Count : Natural := 0;
      Diagnostics_Info_Count : Natural := 0;
      Diagnostics_Note_Count : Natural := 0;
      Diagnostics_Unknown_Count : Natural := 0;
      Has_Diagnostics_Severity_Counts : Boolean := False;
      Primary_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Latest_Build_Result_Render_Snapshot is record
      Latest_Build_Result_Visible : Boolean := False;
      Latest_Build_Result_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Tool_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Runner_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Working_Context_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Exit_Code_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Timeout_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Cancellation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Truncation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Partial_Output_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Diagnostics_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Build_Result_Primary_Message_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function Empty_Summary return Latest_Build_Result_Summary;

   --  Phase 511 policy: public build.run pre-run unavailable attempts are
   --  represented in the transient latest summary.  This keeps the result
   --  surface aligned with the one primary command outcome message while still
   --  guaranteeing that no runner output, Diagnostics rows, process state, or
   --  rerun payload is implied for unavailable results.
   function Retain_Pre_Run_Unavailable_Summary return Boolean;

   --  Phase 512 canonical cleanup: replacement always routes through the
   --  canonical latest-summary normalizer.  The result is display-only,
   --  bounded, non-executable, and contains no retained fields from Current.
   function Canonicalize_Latest_Build_Result_Summary
     (Summary : Latest_Build_Result_Summary)
      return Latest_Build_Result_Summary;

   function Clear_Stale_Build_Result_Summary_Fields
     (Summary : Latest_Build_Result_Summary)
      return Latest_Build_Result_Summary;

   function Replace_Latest_Build_Result_Summary
     (Current : Latest_Build_Result_Summary;
      Next    : Latest_Build_Result_Summary)
      return Latest_Build_Result_Summary;

   function Build_Summary
     (Kind           : Build_Result_Summary_Kind;
      Invocation_Label : String;
      Tool_Kind      : Build_Result_Tool_Kind;
      Request_Mode   : Build_Result_Request_Mode;
      Working_Context_Label : String;
      Runner_Status_Label : String;
      Primary_Message : String;
      Exit_Code       : Integer := 0;
      Has_Exit_Code   : Boolean := False;
      Timed_Out       : Boolean := False;
      Cancelled       : Boolean := False;
      Cancellation_Unsupported : Boolean := False;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Diagnostics_Ingestion_Status : Diagnostics_Ingestion_Summary_Status :=
        Diagnostics_Ingestion_Not_Requested;
      Diagnostics_Count : Natural := 0;
      Has_Diagnostics_Count : Boolean := False;
      Diagnostics_Error_Count : Natural := 0;
      Diagnostics_Warning_Count : Natural := 0;
      Diagnostics_Info_Count : Natural := 0;
      Diagnostics_Note_Count : Natural := 0;
      Diagnostics_Unknown_Count : Natural := 0;
      Has_Diagnostics_Severity_Counts : Boolean := False)
      return Latest_Build_Result_Summary;

   function Summary_From_Unavailable_Message
     (Message : String) return Latest_Build_Result_Summary;

   function Status_Label (Summary : Latest_Build_Result_Summary) return String;
   function Tool_Label (Summary : Latest_Build_Result_Summary) return String;
   function Working_Context_Label
     (Summary : Latest_Build_Result_Summary) return String;
   function Exit_Code_Label (Summary : Latest_Build_Result_Summary) return String;
   function Timeout_Label (Summary : Latest_Build_Result_Summary) return String;
   function Cancellation_Label
     (Summary : Latest_Build_Result_Summary) return String;
   function Truncation_Label
     (Summary : Latest_Build_Result_Summary) return String;
   function Partial_Output_Label
     (Summary : Latest_Build_Result_Summary) return String;
   function Diagnostics_Label
     (Summary : Latest_Build_Result_Summary) return String;

   function Render_Snapshot
     (Summary : Latest_Build_Result_Summary)
      return Latest_Build_Result_Render_Snapshot;

   function Has_Process_Handle_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Cancellation_Token_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Rerun_Request_Payload_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Diagnostics_Rows_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Unbounded_Output_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Build_History_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Consent_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Full_Stdout_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Full_Stderr_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Diagnostics_Table_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Runner_UI_Result_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Has_Persistence_Field
     (Summary : Latest_Build_Result_Summary) return Boolean;

   function Summary_Can_Be_Converted_To_Public_Build_Request
     (Summary : Latest_Build_Result_Summary) return Boolean;

   function Assert_Latest_Build_Result_Summary_Owned_By_Executor
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Shape_Canonical
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Replace_Only
     (Before : Latest_Build_Result_Summary;
      After  : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Not_Rerun_State
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Not_Output_Log
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Render_Cleanup
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Persistence_Excluded
     (Summary : Latest_Build_Result_Summary) return Boolean;

   function Assert_Summary_Is_Transient_Projection
     (Summary : Latest_Build_Result_Summary) return Boolean;

   function Assert_Public_Build_Result_Surface_Canonical_Coherent
     (Summary : Latest_Build_Result_Summary) return Boolean;

   --  Phase 513 final regression-freeze assertions.  These helpers are
   --  deliberately declarative guards over the existing transient latest-result
   --  summary contract; they do not normalize, repair, persist, or mutate
   --  runtime state.
   function Assert_Latest_Build_Result_Summary_Final_Ownership_Frozen
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Shape_Frozen
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Replace_Only_Frozen
     (Before : Latest_Build_Result_Summary;
      After  : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_No_History
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Not_Rerun_State
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Not_Process_Control
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Not_Output_Log
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Render_Boundary
     (Summary : Latest_Build_Result_Summary) return Boolean;
   function Assert_Latest_Build_Result_Summary_Final_Persistence_Excluded
     (Summary : Latest_Build_Result_Summary) return Boolean;

   function Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
     (Summary : Latest_Build_Result_Summary) return Boolean;

   --  Phase 527 result/output/diagnostics UI usability assertion.  This
   --  validates that the latest-result projection is useful in Build UI while
   --  remaining compact, scalar, transient, and non-owning.
   function Assert_Latest_Build_Result_Summary_Useful_For_Build_UI
     (Summary : Latest_Build_Result_Summary) return Boolean;

end Editor.Build_Result_Summary;
