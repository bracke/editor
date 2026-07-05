with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Command;
with Editor.Build_Diagnostics;
with Editor.Build_Public_Request;
with Editor.Build_UI;
with Editor.Commands;

package body Editor.Build_Execution_Workflow is

   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Build_UI.Build_UI_Build_Mode;
   use type Editor.Build_UI.Build_UI_Output_Capture_Limit;
   use type Editor.External_Producers.Build_Request_Provenance;
   use type Editor.External_Producers.Build_Tool_Kind;
   use type Editor.External_Producers.Build_Execution_Consent;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.Build_Result_Summary.Build_Result_Summary_Kind;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Id;

   function Contains_Shell_Operator (Text : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, "|") /= 0
        or else Ada.Strings.Fixed.Index (Text, ";") /= 0
        or else Ada.Strings.Fixed.Index (Text, "&&") /= 0
        or else Ada.Strings.Fixed.Index (Text, "||") /= 0
        or else Ada.Strings.Fixed.Index (Text, ">") /= 0
        or else Ada.Strings.Fixed.Index (Text, "<") /= 0;
   end Contains_Shell_Operator;

   function Assert_Build_Run_Requires_Valid_Consented_Request
     (State : Editor.State.State_Type) return Boolean
   is
      Without_Consent : Editor.State.State_Type := State;
      Ready : constant Boolean :=
        Editor.Build_Command.Validate_Build_Run_Invocation (State) =
          Editor.Build_Command.Build_Run_Readiness_Ready;
   begin
      Editor.Build_UI.Clear_Consent (Without_Consent.Build_UI);
      return Editor.Build_Command.Validate_Build_Run_Invocation
          (Without_Consent) /= Editor.Build_Command.Build_Run_Readiness_Ready
        and then (if Ready then
                    State.Build_UI.Consent_Acknowledged
                    and then Editor.Build_UI.Validate_Build_UI_State
                      (State.Build_UI) = Editor.Build_UI.Build_UI_Valid
                  else True);
   end Assert_Build_Run_Requires_Valid_Consented_Request;

   function Assert_Build_Run_Uses_Structured_Tokens
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean
   is
   begin
      return Request.Tool /= Editor.External_Producers.No_Build_Tool
        and then Request.Provenance =
          Editor.External_Producers.Build_Request_From_User_Opt_In
        and then Length (Request.Arguments) = 0
        and then not Request.Structured_Arguments.Is_Empty;
   end Assert_Build_Run_Uses_Structured_Tokens;

   function Assert_Build_Run_Does_Not_Use_Shell_Text
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean
   is
   begin
      if Length (Request.Arguments) /= 0 then
         return False;
      end if;

      if Contains_Shell_Operator (To_String (Request.Command_Label)) then
         return False;
      end if;

      if not Request.Structured_Arguments.Is_Empty then
         for I in Request.Structured_Arguments.First_Index ..
           Request.Structured_Arguments.Last_Index
         loop
            if Contains_Shell_Operator
              (To_String (Request.Structured_Arguments.Element (I)))
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Assert_Build_Run_Does_Not_Use_Shell_Text;

   function Assert_Build_Output_Is_Bounded
     (Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean
   is
   begin
      return Editor.Build_Output_Details.Assert_Build_Output_Details_Bounded
          (Details)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Rerun_State
          (Details)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Process_Control
          (Details)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Output_Log
          (Details)
        and then Length (Details.Stdout_Excerpt) <=
          Editor.Build_Output_Details.Max_Build_Output_Detail_Excerpt_Bytes
        and then Length (Details.Stderr_Excerpt) <=
          Editor.Build_Output_Details.Max_Build_Output_Detail_Excerpt_Bytes;
   end Assert_Build_Output_Is_Bounded;

   function Assert_Build_Result_Summary_Reflects_Runner_Status
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean
   is
   begin
      return (if not Summary.Has_Result then
                Summary.Kind = Editor.Build_Result_Summary.Build_Result_Summary_None
              else Length (Summary.Runner_Status_Label) > 0
                and then Length (Summary.Primary_Message) > 0
                and then Editor.Build_Result_Summary.Assert_Summary_Is_Transient_Projection
                  (Summary)
                and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Rerun_State
                  (Summary)
                and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Output_Log
                  (Summary)
                and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner
                  (Summary));
   end Assert_Build_Result_Summary_Reflects_Runner_Status;

   function Assert_Build_Diagnostics_Owned_By_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Diagnostics.Assert_Build_Diagnostics_Not_Persisted
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner
          (State.Latest_Build_Result)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner
          (State.Latest_Build_Output_Details);
   end Assert_Build_Diagnostics_Owned_By_Diagnostics;

   function Assert_Build_Render_Does_Not_Run_Or_Parse
     (State : Editor.State.State_Type) return Boolean
   is
      Before_Has_Result : constant Boolean := State.Latest_Build_Result.Has_Result;
      Before_Result_Kind : constant Editor.Build_Result_Summary.Build_Result_Summary_Kind :=
        State.Latest_Build_Result.Kind;
      Before_Has_Output : constant Boolean :=
        State.Latest_Build_Output_Details.Has_Output_Details;
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI.Build_Render_Snapshot
          (State.Build_UI,
           State.Latest_Build_Result,
           State.Latest_Build_Output_Details);
   begin
      return Snapshot.Candidate_Count =
          Editor.Build_UI.Candidate_Count (State.Build_UI)
        and then State.Latest_Build_Result.Has_Result = Before_Has_Result
        and then State.Latest_Build_Result.Kind = Before_Result_Kind
        and then State.Latest_Build_Output_Details.Has_Output_Details =
          Before_Has_Output;
   end Assert_Build_Render_Does_Not_Run_Or_Parse;

   function Assert_Build_Result_Output_Not_Persisted
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command.Assert_Build_Run_Persistence_Excluded (State)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Persistence_Excluded
          (State.Latest_Build_Result)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Persistence_Excluded
          (State.Latest_Build_Output_Details);
   end Assert_Build_Result_Output_Not_Persisted;

   function Assert_Build_Keybindings_Have_No_Run_Payloads return Boolean is
   begin
      return Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary
        and then not Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run).Bindable;
   end Assert_Build_Keybindings_Have_No_Run_Payloads;

   function Assert_Build_Command_Surface_Has_No_Execution_Payloads
      return Boolean
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run);
      Name : constant String := To_String (D.Name);
      Description : constant String := To_String (D.Description);
   begin
      --  The command descriptor may identify build.run and describe the action,
      --  but it must not carry a candidate id, argv payload, result id, cwd,
      --  consent token, shell text, or rerun payload.
      return Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run) = "build.run"
        and then D.Visibility = Editor.Commands.Palette_Command
        and then not D.Bindable
        and then Ada.Strings.Fixed.Index (Name, "-P") = 0
        and then Ada.Strings.Fixed.Index (Name, "argv") = 0
        and then Ada.Strings.Fixed.Index (Name, "candidate") = 0
        and then Ada.Strings.Fixed.Index (Name, "result") = 0
        and then Ada.Strings.Fixed.Index (Description, "-P") = 0
        and then Ada.Strings.Fixed.Index (Description, "argv") = 0
        and then Ada.Strings.Fixed.Index (Description, "candidate id") = 0
        and then Ada.Strings.Fixed.Index (Description, "result id") = 0
        and then Ada.Strings.Fixed.Index (Description, "cwd") = 0
        and then Ada.Strings.Fixed.Index (Description, "rerun") = 0
        and then Ada.Strings.Fixed.Index (Description, "|") = 0
        and then Ada.Strings.Fixed.Index (Description, ";") = 0
        and then Ada.Strings.Fixed.Index (Description, ">") = 0
        and then Ada.Strings.Fixed.Index (Description, "<") = 0;
   end Assert_Build_Command_Surface_Has_No_Execution_Payloads;

   function Assert_Build_Execution_No_Transient_Persistence_Fields
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Result_Output_Not_Persisted (State)
        and then Editor.Build_UI.Assert_Build_Request_State_Not_Persisted
          (State.Build_UI)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Persistence_Excluded
          (State.Latest_Build_Result)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Persistence_Excluded
          (State.Latest_Build_Output_Details);
   end Assert_Build_Execution_No_Transient_Persistence_Fields;

   function Assert_Build_Diagnostics_Disabled_Does_Not_Ingest
     (Result : Editor.External_Producers.Build_Command_Result) return Boolean
   is
   begin
      return Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0
        and then not Result.Diagnostic_Result.Should_Show_Diagnostics;
   end Assert_Build_Diagnostics_Disabled_Does_Not_Ingest;


   function Assert_Build_Run_Unavailable_Reasons_Complete return Boolean is
   begin
      --  Exhaustively map every pre-run status that may block execution to a
      --  direct user-facing reason.  This catches future additions that would
      --  otherwise collapse into ambiguous or empty command outcomes.
      for Status in Editor.Build_Command.Build_Run_Readiness_Status loop
         declare
            Reason : constant String :=
              Editor.Build_Command.Build_Run_Unavailable_Reason (Status);
            Hint : constant String :=
              Editor.Build_Command.Build_Run_Recovery_Hint (Status);
         begin
            if Reason'Length = 0 then
               return False;
            end if;
            if Hint'Length = 0 then
               return False;
            end if;

            if Status /= Editor.Build_Command.Build_Run_Readiness_Ready
              and then Reason = "Build request ready"
            then
               return False;
            end if;
            if Status /= Editor.Build_Command.Build_Run_Readiness_Ready
              and then Hint = "Run build"
            then
               return False;
            end if;
         end;
      end loop;

      return Editor.Build_Command.Build_Run_Unavailable_Reason
          (Editor.Build_Command.Build_Run_Readiness_No_Project_Open) =
            "No project open."
        and then Editor.Build_Command.Build_Run_Unavailable_Reason
          (Editor.Build_Command.Build_Run_Readiness_No_Candidate_Selected) =
            "No build candidate selected."
        and then Editor.Build_Command.Build_Run_Recovery_Hint
          (Editor.Build_Command.Build_Run_Readiness_No_Candidate_Selected) =
            "Refresh build candidates and select one"
        and then Editor.Build_Command.Build_Run_Unavailable_Reason
          (Editor.Build_Command.Build_Run_Readiness_Selected_Candidate_Stale) =
            "Selected build candidate is stale."
        and then Editor.Build_Command.Build_Run_Unavailable_Reason
          (Editor.Build_Command.Build_Run_Readiness_Candidate_File_Missing) =
            "Build candidate file no longer exists."
        and then Editor.Build_Command.Build_Run_Unavailable_Reason
          (Editor.Build_Command.Build_Run_Readiness_Consent_Required) =
            "Consent required."
        and then Editor.Build_Command.Build_Run_Unavailable_Reason
          (Editor.Build_Command.Build_Run_Readiness_Consent_Stale) =
            "Consent stale."
        and then Editor.Build_Command.Build_Run_Recovery_Hint
          (Editor.Build_Command.Build_Run_Readiness_Job_Already_Active) =
            "Wait for the active build or cancel it";
   end Assert_Build_Run_Unavailable_Reasons_Complete;

   function Assert_Build_Latest_Result_Replaces_Attempt
     (Before : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      After  : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean
   is
   begin
      return Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Replace_Only
          (Before, After)
        and then After.Has_Result
        and then Length (After.Primary_Message) > 0
        and then Assert_Build_Result_Summary_Reflects_Runner_Status (After);
   end Assert_Build_Latest_Result_Replaces_Attempt;

   function Assert_Build_Preflight_Result_Has_No_Diagnostics
     (Result : Editor.External_Producers.Build_Command_Result) return Boolean
   is
   begin
      return Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available
        and then Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 0
        and then Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0
        and then not Result.Diagnostic_Result.Should_Show_Diagnostics;
   end Assert_Build_Preflight_Result_Has_No_Diagnostics;

   function Assert_Build_Cancel_Advertised_With_Active_Job_Model
     (State : Editor.State.State_Type) return Boolean
   is
      Found : Boolean := False;
      Id : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name ("build.cancel", Found);
      Copy : Editor.State.State_Type := State;
   begin
      if not Found or else Id /= Editor.Commands.Command_Build_Cancel then
         return False;
      end if;

      if Editor.Commands.Is_Available
        (Editor.Build_Command.Build_Cancel_Availability (Copy))
      then
         return False;
      end if;

      Editor.Build_Command.Begin_Public_Build_Job (Copy, "audit");
      return Editor.Commands.Is_Available
          (Editor.Build_Command.Build_Cancel_Availability (Copy))
        and then Editor.Build_Command.Assert_Build_Cancel_Command_Descriptor_Stable
        and then Editor.Build_Command.Assert_Build_Cancel_Requires_Active_Job
          (State);
   end Assert_Build_Cancel_Advertised_With_Active_Job_Model;

   function Assert_Build_Preflight_Preserves_Request_Surface
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      --  Pre-run failures may update latest transient result/output surfaces,
      --  but they must not refresh candidates, clear selection, auto-consent,
      --  or rewrite the structured request configuration.  The checks use the
      --  Build UI request/selection surface rather than any persisted state.
      return Editor.Build_UI.Candidate_Count (Before.Build_UI) =
          Editor.Build_UI.Candidate_Count (After.Build_UI)
        and then To_String (Before.Build_UI.Selected_Build_Candidate_Id) =
          To_String (After.Build_UI.Selected_Build_Candidate_Id)
        and then Before.Build_UI.Consent_Acknowledged =
          After.Build_UI.Consent_Acknowledged
        and then To_String (Before.Build_UI.Consent_Request_Identity) =
          To_String (After.Build_UI.Consent_Request_Identity)
        and then Before.Build_UI.Selected_Build_Mode = After.Build_UI.Selected_Build_Mode
        and then Before.Build_UI.Show_Diagnostics_On_Result =
          After.Build_UI.Show_Diagnostics_On_Result
        and then Before.Build_UI.Output_Capture_Limit =
          After.Build_UI.Output_Capture_Limit;
   end Assert_Build_Preflight_Preserves_Request_Surface;


   function Assert_Build_Run_Gate_Consent_Matches_Preflight
     (State : Editor.State.State_Type) return Boolean
   is
      Status : constant Editor.Build_Command.Build_Run_Readiness_Status :=
        Editor.Build_Command.Validate_Build_Run_Invocation (State);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.Build_Command.Build_Run_Execution_Gate (State);
   begin
      if Status = Editor.Build_Command.Build_Run_Readiness_Ready then
         return Gate.Consent = Editor.External_Producers.Build_Consent_User_Confirmed
           and then Editor.External_Producers.Validate_Build_Execution_Gate (Gate);
      else
         return Gate.Consent /= Editor.External_Producers.Build_Consent_User_Confirmed;
      end if;
   end Assert_Build_Run_Gate_Consent_Matches_Preflight;

   function Assert_Build_Preflight_Failure_Is_Non_Destructive
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result) return Boolean
   is
   begin
      return Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available
        and then Before.Buffer_Revision = After.Buffer_Revision
        and then Before.Active_Buffer_Token = After.Active_Buffer_Token
        and then not After.Latest_Build_Output_Details.Stdout_Available
        and then not After.Latest_Build_Output_Details.Stderr_Available
        and then Assert_Build_Output_Is_Bounded
          (After.Latest_Build_Output_Details)
        and then Assert_Build_Preflight_Preserves_Request_Surface (Before, After)
        and then Assert_Build_Result_Output_Not_Persisted (After);
   end Assert_Build_Preflight_Failure_Is_Non_Destructive;

   function Assert_Build_Execution_Workflow_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State
          (State.Build_UI);
      Request_Checks : constant Boolean :=
        (if Conversion.Status = Editor.Build_UI.Build_UI_Valid then
           Assert_Build_Run_Uses_Structured_Tokens (Conversion.Request)
           and then Assert_Build_Run_Does_Not_Use_Shell_Text
             (Conversion.Request)
         else True);
   begin
      return Assert_Build_Run_Requires_Valid_Consented_Request (State)
        and then Request_Checks
        and then Assert_Build_Result_Summary_Reflects_Runner_Status
          (State.Latest_Build_Result)
        and then Assert_Build_Output_Is_Bounded
          (State.Latest_Build_Output_Details)
        and then Assert_Build_Diagnostics_Owned_By_Diagnostics (State)
        and then Assert_Build_Render_Does_Not_Run_Or_Parse (State)
        and then Assert_Build_Result_Output_Not_Persisted (State)
        and then Assert_Build_Run_Gate_Consent_Matches_Preflight (State)
        and then Assert_Build_Command_Surface_Has_No_Execution_Payloads
        and then Assert_Build_Execution_No_Transient_Persistence_Fields (State)
        and then Assert_Build_Run_Unavailable_Reasons_Complete
        and then Assert_Build_Cancel_Advertised_With_Active_Job_Model (State)
        and then Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary
          (State)
        and then Assert_Build_Keybindings_Have_No_Run_Payloads;
   end Assert_Build_Execution_Workflow_Coherent;

end Editor.Build_Execution_Workflow;
