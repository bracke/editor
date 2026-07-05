with Ada.Strings.Unbounded;

package Editor.Build_Output_Details is

   --  /579 transient latest build output details.  This is a bounded
   --  display projection over captured stdout/stderr and the active build-job
   --  incremental output stream.  It is not build history, not a terminal, not
   --  a rerun payload, not Diagnostics ownership, not process ownership, and
   --  not persisted state.

   Max_Build_Output_Detail_Excerpt_Bytes : constant Natural := 8_192;

   type Build_Output_Details_Kind is
     (Build_Output_Details_None,
      Build_Output_Details_Available,
      Build_Output_Details_Unavailable,
      Build_Output_Details_Truncated,
      Build_Output_Details_Partial);

   type Build_Output_Stream_Selection is
     (Build_Output_Stream_Stdout,
      Build_Output_Stream_Stderr,
      Build_Output_Stream_Merged);

   type Build_Output_Runner_Status is
     (Build_Output_Runner_Succeeded,
      Build_Output_Runner_Failed,
      Build_Output_Runner_Not_Available,
      Build_Output_Runner_Rejected,
      Build_Output_Runner_Execution_Error,
      Build_Output_Runner_Timed_Out,
      Build_Output_Runner_Cancelled,
      Build_Output_Runner_Cancellation_Unsupported,
      Build_Output_Runner_Output_Truncated);

   type Latest_Build_Output_Details is record
      Has_Output_Details : Boolean := False;
      Kind : Build_Output_Details_Kind := Build_Output_Details_None;
      Associated_Result_Identity : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Available : Boolean := False;
      Stderr_Available : Boolean := False;
      Stdout_Excerpt : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Excerpt : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Stdout_Display_Truncated : Boolean := False;
      Stderr_Display_Truncated : Boolean := False;
      Output_Partial : Boolean := False;
      Timed_Out : Boolean := False;
      Cancelled : Boolean := False;
      Runner_Status : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Output_Limit_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Build_Output_Details_Visible : Boolean := False;
      Build_Output_Details_Focused : Boolean := False;
      Selected_Output_Stream : Build_Output_Stream_Selection :=
        Build_Output_Stream_Stderr;
   end record;


   type Build_Output_Stream_State is record
      Active : Boolean := False;
      Associated_Job_Id : Natural := 0;
      Stdout_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Chunk_Count : Natural := 0;
      Byte_Count : Natural := 0;
      Limit_Bytes : Natural := Max_Build_Output_Detail_Excerpt_Bytes;
   end record;

   type Latest_Build_Output_Details_Render_Snapshot is record
      Output_Details_Visible : Boolean := False;
      Output_Details_Focused : Boolean := False;
      Output_Details_Available : Boolean := False;
      No_Output_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Output_Details_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Output_Details_Runner_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Output_Details_Limit_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Available : Boolean := False;
      Stderr_Available : Boolean := False;
      Stdout_No_Output_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_No_Output_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Excerpt : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Excerpt : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Truncation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Truncation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Partial_Output_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected_Output_Stream : Build_Output_Stream_Selection :=
        Build_Output_Stream_Stderr;
   end record;

   function Empty_Output_Details return Latest_Build_Output_Details;

   function Empty_Build_Output_Stream return Build_Output_Stream_State;

   procedure Begin_Build_Output_Stream
     (Stream : in out Build_Output_Stream_State;
      Job_Id : Natural;
      Limit_Bytes : Natural := Max_Build_Output_Detail_Excerpt_Bytes);

   procedure Append_Build_Output_Stream_Chunk
     (Stream : in out Build_Output_Stream_State;
      Output_Stream : Build_Output_Stream_Selection;
      Text : String);

   function Build_Output_Details_From_Stream
     (Stream : Build_Output_Stream_State;
      Runner_Status : Build_Output_Runner_Status := Build_Output_Runner_Succeeded;
      Output_Partial : Boolean := True;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False)
      return Latest_Build_Output_Details;

   procedure Finish_Build_Output_Stream
     (Stream : in out Build_Output_Stream_State);

   function Assert_Build_Output_Stream_Bounded
     (Stream : Build_Output_Stream_State) return Boolean;


   function Bound_Build_Output_Excerpt
     (Text  : Ada.Strings.Unbounded.Unbounded_String;
      Limit : Natural := Max_Build_Output_Detail_Excerpt_Bytes)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Build_Output_Details_From_Captured_Output
     (Runner_Status    : Build_Output_Runner_Status;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Output_Stream    : Build_Output_Stream_Selection :=
        Build_Output_Stream_Stderr)
      return Latest_Build_Output_Details;

   function Build_Unavailable_Output_Details
     (Reason : String := "") return Latest_Build_Output_Details;

   function Canonicalize_Latest_Build_Output_Details
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details;

   function Clear_Stale_Output_Details_Fields
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details;

   function Clear_Stale_Build_Output_Details_Fields
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details;

   function Build_Output_Details_No_Output_State
     (Runner_Status : Build_Output_Runner_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False)
      return Latest_Build_Output_Details;

   function Build_Output_Details_Partial_Output_State
     (Runner_Status    : Build_Output_Runner_Status;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False)
      return Latest_Build_Output_Details;

   function Replace_Latest_Build_Output_Details
     (Current : Latest_Build_Output_Details;
      Next    : Latest_Build_Output_Details)
      return Latest_Build_Output_Details;

   function Replace_Latest_Build_Output_Details_Reliably
     (Current : Latest_Build_Output_Details;
      Next    : Latest_Build_Output_Details)
      return Latest_Build_Output_Details;

   procedure Show_Output_Details
     (Details : in out Latest_Build_Output_Details);
   procedure Focus_Output_Details
     (Details : in out Latest_Build_Output_Details);
   procedure Hide_Output_Details
     (Details : in out Latest_Build_Output_Details);
   procedure Select_Output_Stream
     (Details : in out Latest_Build_Output_Details;
      Stream  : Build_Output_Stream_Selection);

   function Status_Label (Details : Latest_Build_Output_Details) return String;
   function Stdout_Truncation_Label
     (Details : Latest_Build_Output_Details) return String;
   function Stderr_Truncation_Label
     (Details : Latest_Build_Output_Details) return String;
   function Partial_Output_Label
     (Details : Latest_Build_Output_Details) return String;
   function No_Output_Label
     (Details : Latest_Build_Output_Details) return String;

   function Render_Snapshot
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details_Render_Snapshot;

   function Has_Process_Handle_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Cancellation_Token_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Rerun_Request_Payload_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Public_Build_Request_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Consent_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Working_Context_Token_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Diagnostics_Rows_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Build_History_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Unbounded_Output_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Output_File_Path_Field
     (Details : Latest_Build_Output_Details) return Boolean;
   function Has_Persistence_Field
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Build_Output_Details_Bounded
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Transient
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Updated_By_Executor
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Build_Output_Details_Replace_Only
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean;

   function Assert_Output_Details_Replaced_Not_Appended
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean;

   function Assert_Output_Details_Stale_Fields_Cleared
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean;

   function Assert_Output_Details_Not_History
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Output_Details_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Output_Details_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Output_Details_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Output_Details_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Public_Build_Output_Details_Foundation_Coherent
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Public_Build_Output_Details_Reliability_Coherent
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Latest_Build_Output_Details_Owned_By_Executor
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Shape_Canonical
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Replace_Only
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_No_Output_Canonical
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Not_Output_Log
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Render_Cleanup
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Public_Build_Output_Details_Canonical_Coherent
     (Details : Latest_Build_Output_Details) return Boolean;


   --  final regression-freeze assertions.  These helpers are
   --  declarative guards over the frozen latest bounded output-details
   --  contract; they do not normalize, repair, persist, spawn, parse
   --  Diagnostics, or mutate runtime state.
   function Assert_Latest_Build_Output_Details_Final_Ownership_Frozen
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Shape_Frozen
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Mapping_Frozen
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_No_Output_Frozen
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Replace_Only_Frozen
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_No_History
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Not_Output_Log
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Render_Boundary
     (Details : Latest_Build_Output_Details) return Boolean;
   function Assert_Latest_Build_Output_Details_Final_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Public_Build_Output_Details_Final_Freeze_Coherent
     (Details : Latest_Build_Output_Details) return Boolean;

   function Assert_Build_Output_Details_Useful_For_Build_UI
     (Details : Latest_Build_Output_Details) return Boolean;

end Editor.Build_Output_Details;
