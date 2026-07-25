with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Service;
with Editor.Build_Candidates;
with Editor.Build_Diagnostics;
with Editor.Build_Public_Request;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Build_UI;
with Editor.External_Producers;
with Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Requests;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Execution_Policy;
with Editor.Project;
with Editor.View;

package body Editor.Build_Command.Projections is

   use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.External_Producers.Build_Types.Build_Request_Validation_Status;
   use type Editor.External_Producers.Build_Requests.Build_Run_Status;

   function Summary_Kind_For
     (Status : Editor.External_Producers.Build_Requests.Build_Run_Status)
      return Editor.Build_Result_Summary.Build_Result_Summary_Kind
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Types.Build_Run_Succeeded =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Succeeded;
         when Editor.External_Producers.Build_Types.Build_Run_Failed
            | Editor.External_Producers.Build_Types.Build_Run_Rejected
            | Editor.External_Producers.Build_Types.Build_Run_Execution_Error =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Failed;
         when Editor.External_Producers.Build_Types.Build_Run_Not_Available
            | Editor.External_Producers.Build_Types.Build_Run_Cancellation_Unsupported =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Unavailable;
         when Editor.External_Producers.Build_Types.Build_Run_Timed_Out =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out;
         when Editor.External_Producers.Build_Types.Build_Run_Cancelled =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Cancelled;
         when Editor.External_Producers.Build_Types.Build_Run_Output_Truncated =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Output_Truncated;
      end case;
   end Summary_Kind_For;

   function Summary_Tool_For
     (Tool : Editor.External_Producers.Build_Requests.Build_Tool_Kind)
      return Editor.Build_Result_Summary.Build_Result_Tool_Kind
   is
   begin
      case Tool is
         when Editor.External_Producers.Build_Types.GPRbuild_Tool =>
            return Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool;
         when Editor.External_Producers.Build_Types.Alire_Build_Tool =>
            return Editor.Build_Result_Summary.Build_Result_Alire_Tool;
         when Editor.External_Producers.Build_Types.Custom_Build_Tool =>
            return Editor.Build_Result_Summary.Build_Result_Custom_Tool;
         when Editor.External_Producers.Build_Types.No_Build_Tool =>
            return Editor.Build_Result_Summary.Build_Result_No_Tool;
      end case;
   end Summary_Tool_For;

   function Compiler_Tool_Name
     (Tool : Editor.External_Producers.Build_Requests.Build_Tool_Kind) return String
   is
   begin
      case Tool is
         when Editor.External_Producers.Build_Types.GPRbuild_Tool =>
            return "gprbuild";
         when Editor.External_Producers.Build_Types.Alire_Build_Tool =>
            return "alr";
         when Editor.External_Producers.Build_Types.Custom_Build_Tool =>
            return "custom-build";
         when Editor.External_Producers.Build_Types.No_Build_Tool =>
            return "build";
      end case;
   end Compiler_Tool_Name;

   function Build_Run_Fingerprint
     (Result : Editor.External_Producers.Build_Requests.Build_Run_Result) return Natural
   is
      Exit_Code_Part : Natural := 0;
   begin
      if Result.Exit_Code < 0 then
         if Result.Exit_Code = Integer'First then
            Exit_Code_Part := Natural (Integer'Last);
         else
            Exit_Code_Part := Natural (-Result.Exit_Code);
         end if;
      else
         Exit_Code_Part := Natural (Result.Exit_Code);
      end if;

      return
        Editor.External_Producers.Build_Requests.Build_Run_Status'Pos (Result.Status)
        + Exit_Code_Part;
   end Build_Run_Fingerprint;

   procedure Feed_Language_Service_Compiler_Backend
     (State   : in out Editor.State.State_Type;
      Request : Editor.External_Producers.Build_Requests.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Requests.Build_Run_Result)
   is
      Lines : constant
        Editor.External_Producers.Build_Requests.Diagnostic_Text_Line_Array :=
          Editor.External_Producers.Build_Requests
            .Extract_Diagnostic_Lines_From_Build_Result (Result);
   begin
      State.Language_Service :=
        Editor.Ada_Language_Service.From_Index (State.Language_Index);
      Editor.Ada_Language_Service.Put_Compiler_Diagnostic_Lines
        (State.Language_Service,
         Lines,
         Tool_Name       => Compiler_Tool_Name (Request.Tool),
         Run_Fingerprint => Build_Run_Fingerprint (Result));
   end Feed_Language_Service_Compiler_Backend;

   function Summary_Mode_For
     (Request : Editor.External_Producers.Build_Requests.Build_Run_Request)
      return Editor.Build_Result_Summary.Build_Result_Request_Mode
   is
   begin
      if Length (Request.Command_Label) > 0 then
         return Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived;
      end if;

      case Request.Provenance is
         when Editor.External_Producers.Build_Types.Build_Request_From_User_Opt_In =>
            return Editor.Build_Result_Summary.Build_Result_Request_Manual;
         when Editor.External_Producers.Build_Types.Build_Request_From_Implicit_Source =>
            return Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived;
         when Editor.External_Producers.Build_Types.Build_Request_From_Test
            | Editor.External_Producers.Build_Types.Build_Request_From_Fixture
            | Editor.External_Producers.Build_Types.Build_Request_From_Internal_Command =>
            return Editor.Build_Result_Summary.Build_Result_Request_Test_Or_Internal;
         when Editor.External_Producers.Build_Types.Build_Request_Unknown =>
            return Editor.Build_Result_Summary.Build_Result_Request_None;
      end case;
   end Summary_Mode_For;

   function Summary_Diagnostics_For
     (Result : Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result;
      Allowed : Boolean)
      return Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status
   is
   begin
      if not Allowed then
         return Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled;
      end if;

      case Result.Outcome is
         when Editor.External_Producers.Diagnostic_Line_Parsing.Diagnostic_Line_Command_Succeeded =>
            if Result.Ingestion.Ingestion_Result.Accepted_Count > 0 then
               if Result.Ingestion.Parse_Rejected_Malformed_Count > 0 then
                  return Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial;
               else
                  return Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded;
               end if;
            else
               return Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics;
            end if;
         when Editor.External_Producers.Diagnostic_Line_Parsing.Diagnostic_Line_Command_No_Input
            | Editor.External_Producers.Diagnostic_Line_Parsing.Diagnostic_Line_Command_No_Diagnostics =>
            return Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics;
         when Editor.External_Producers.Diagnostic_Line_Parsing.Diagnostic_Line_Command_Malformed_Only =>
            return Editor.Build_Result_Summary.Diagnostics_Ingestion_Failed;
      end case;
   end Summary_Diagnostics_For;

   function Runner_Status_Label
     (Status : Editor.External_Producers.Build_Requests.Build_Run_Status) return String
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Types.Build_Run_Succeeded => return "succeeded";
         when Editor.External_Producers.Build_Types.Build_Run_Failed => return "failed";
         when Editor.External_Producers.Build_Types.Build_Run_Not_Available => return "not available";
         when Editor.External_Producers.Build_Types.Build_Run_Rejected => return "rejected";
         when Editor.External_Producers.Build_Types.Build_Run_Execution_Error => return "execution error";
         when Editor.External_Producers.Build_Types.Build_Run_Timed_Out => return "timed out";
         when Editor.External_Producers.Build_Types.Build_Run_Cancelled => return "cancelled";
         when Editor.External_Producers.Build_Types.Build_Run_Cancellation_Unsupported => return "cancellation unsupported";
         when Editor.External_Producers.Build_Types.Build_Run_Output_Truncated => return "output truncated";
      end case;
   end Runner_Status_Label;

   function Output_Runner_Status_For
     (Status : Editor.External_Producers.Build_Requests.Build_Run_Status)
      return Editor.Build_Output_Details.Build_Output_Runner_Status
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Types.Build_Run_Succeeded =>
            return Editor.Build_Output_Details.Build_Output_Runner_Succeeded;
         when Editor.External_Producers.Build_Types.Build_Run_Failed =>
            return Editor.Build_Output_Details.Build_Output_Runner_Failed;
         when Editor.External_Producers.Build_Types.Build_Run_Not_Available =>
            return Editor.Build_Output_Details.Build_Output_Runner_Not_Available;
         when Editor.External_Producers.Build_Types.Build_Run_Rejected =>
            return Editor.Build_Output_Details.Build_Output_Runner_Rejected;
         when Editor.External_Producers.Build_Types.Build_Run_Execution_Error =>
            return Editor.Build_Output_Details.Build_Output_Runner_Execution_Error;
         when Editor.External_Producers.Build_Types.Build_Run_Timed_Out =>
            return Editor.Build_Output_Details.Build_Output_Runner_Timed_Out;
         when Editor.External_Producers.Build_Types.Build_Run_Cancelled =>
            return Editor.Build_Output_Details.Build_Output_Runner_Cancelled;
         when Editor.External_Producers.Build_Types.Build_Run_Cancellation_Unsupported =>
            return Editor.Build_Output_Details.Build_Output_Runner_Cancellation_Unsupported;
         when Editor.External_Producers.Build_Types.Build_Run_Output_Truncated =>
            return Editor.Build_Output_Details.Build_Output_Runner_Output_Truncated;
      end case;
   end Output_Runner_Status_For;

   function Output_Details_From_Result
     (Build : Editor.External_Producers.Build_Requests.Build_Run_Result)
      return Editor.Build_Output_Details.Latest_Build_Output_Details
   is
   begin
      return Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
        (Runner_Status => Output_Runner_Status_For (Build.Status),
         Stdout_Text => Build.Stdout_Text,
         Stderr_Text => Build.Stderr_Text,
         Stdout_Truncated => Build.Stdout_Truncated,
         Stderr_Truncated => Build.Stderr_Truncated,
         Output_Partial => Build.Output_Partial,
         Exit_Code => Build.Exit_Code,
         Has_Exit_Code => Build.Has_Exit_Code,
         Output_Stream =>
           (case Editor.External_Producers.Execution_Policy.Build_Result_Output_Stream (Build) is
              when Editor.External_Producers.Build_Types.Process_Output_Stdout =>
                 Editor.Build_Output_Details.Build_Output_Stream_Stdout,
              when Editor.External_Producers.Build_Types.Process_Output_Stderr =>
                 Editor.Build_Output_Details.Build_Output_Stream_Stderr,
              when Editor.External_Producers.Build_Types.Process_Output_Merged =>
                 Editor.Build_Output_Details.Build_Output_Stream_Merged));
   end Output_Details_From_Result;

   function Public_Build_Duration_Milliseconds
     (State : Editor.State.State_Type) return Natural
   is
      Now : constant Duration := Editor.View.Current_Time_Seconds;
      Elapsed : Duration := 0.0;
   begin
      if not State.Public_Build_Job_Has_Start_Time then
         return 0;
      elsif Now > State.Public_Build_Job_Started_At then
         Elapsed := Now - State.Public_Build_Job_Started_At;
      end if;

      if Elapsed >= Duration (Natural'Last / 1000) then
         return Natural'Last;
      end if;
      return Natural (Elapsed * 1000.0);
   end Public_Build_Duration_Milliseconds;

   function Summary_From_Result
     (Request : Editor.External_Producers.Build_Requests.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Diagnostics_Allowed : Boolean;
      Duration_Milliseconds : Natural := 0;
      Has_Duration : Boolean := False)
      return Editor.Build_Result_Summary.Latest_Build_Result_Summary
   is
      Build : constant Editor.External_Producers.Build_Requests.Build_Run_Result := Result.Build_Result;
      Count : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Diagnostics_Status : constant
        Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status :=
          Summary_Diagnostics_For
            (Result.Diagnostic_Result, Diagnostics_Allowed);
      Has_Count : constant Boolean :=
        Diagnostics_Status in
          Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded |
          Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial |
          Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics;
   begin
      return Editor.Build_Result_Summary.Build_Summary
        (Kind => Summary_Kind_For (Build.Status),
         Invocation_Label => "build.run",
         Tool_Kind => Summary_Tool_For (Request.Tool),
         Request_Mode => Summary_Mode_For (Request),
         Working_Context_Label => To_String (Request.Working_Label),
         Runner_Status_Label => Runner_Status_Label (Build.Status),
         Primary_Message => To_String (Result.Command_Message),
         Exit_Code => Build.Exit_Code,
         Has_Exit_Code => Build.Has_Exit_Code,
         Timed_Out => Build.Status = Editor.External_Producers.Build_Types.Build_Run_Timed_Out,
         Cancelled => Build.Status = Editor.External_Producers.Build_Types.Build_Run_Cancelled,
         Cancellation_Unsupported =>
           Build.Status = Editor.External_Producers.Build_Types.Build_Run_Cancellation_Unsupported,
         Stdout_Truncated => Build.Stdout_Truncated,
         Stderr_Truncated => Build.Stderr_Truncated,
         Output_Partial => Build.Output_Partial,
         Diagnostics_Ingestion_Status => Diagnostics_Status,
         Diagnostics_Count => Count,
         Has_Diagnostics_Count => Has_Count,
         Diagnostics_Error_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Error_Count,
         Diagnostics_Warning_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Warning_Count,
         Diagnostics_Info_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Info_Count,
         Diagnostics_Note_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Note_Count,
         Diagnostics_Unknown_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Unknown_Count,
         Has_Diagnostics_Severity_Counts => Count > 0,
         Duration_Milliseconds => Duration_Milliseconds,
         Has_Duration => Has_Duration);
   end Summary_From_Result;

   function Selected_Candidate_Preflight_Status
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
   is
      Selected_Id : constant String := To_String (State.Build_UI.Selected_Build_Candidate_Id);
      Found       : Boolean := False;
   begin
      if Selected_Id'Length = 0 then
         return Build_Run_Readiness_No_Candidate_Selected;
      end if;

      for Candidate of State.Build_UI.Build_Candidates loop
         if To_String (Candidate.Candidate_Id) = Selected_Id then
            Found := True;
            declare
               Status : constant Editor.Build_Candidates.Build_Candidate_Validation_Status :=
                 Editor.Build_Candidates.Validate_Candidate (Candidate);
            begin
               case Status is
                  when Editor.Build_Candidates.Build_Candidate_Valid =>
                     return Build_Run_Readiness_Ready;
                  when Editor.Build_Candidates.Build_Candidate_Unavailable =>
                     return Build_Run_Readiness_Candidate_File_Missing;
                  when others =>
                     return Build_Run_Readiness_Selected_Candidate_Stale;
               end case;
            end;
         end if;
      end loop;

      if not Found then
         return Build_Run_Readiness_Selected_Candidate_Stale;
      end if;

      return Build_Run_Readiness_Selected_Candidate_Stale;
   end Selected_Candidate_Preflight_Status;

   function Map_UI_Status
     (Status : Editor.Build_UI.Public_Build_UI_Validation_Status)
      return Build_Run_Readiness_Status
   is
   begin
      case Status is
         when Editor.Build_UI.Build_UI_Valid =>
            return Build_Run_Readiness_Ready;
         when Editor.Build_UI.Build_UI_Rejected_Not_Visible =>
            return Build_Run_Readiness_Request_Incomplete;
         when Editor.Build_UI.Build_UI_Rejected_No_Tool
            | Editor.Build_UI.Build_UI_Rejected_Custom_Tool =>
            return Build_Run_Readiness_Tool_Required;
         when Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected =>
            return Build_Run_Readiness_No_Candidate_Selected;
         when Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale =>
            return Build_Run_Readiness_Selected_Candidate_Stale;
         when Editor.Build_UI.Build_UI_Rejected_Unsafe_Arguments =>
            return Build_Run_Readiness_Arguments_Invalid;
         when Editor.Build_UI.Build_UI_Rejected_Unsupported_Request_Option =>
            return Build_Run_Readiness_Request_Incomplete;
         when Editor.Build_UI.Build_UI_Rejected_Working_Context_Required =>
            return Build_Run_Readiness_Working_Context_Required;
         when Editor.Build_UI.Build_UI_Rejected_Working_Context_Unavailable =>
            return Build_Run_Readiness_Working_Context_Unavailable;
         when Editor.Build_UI.Build_UI_Rejected_Unsafe_Working_Context =>
            return Build_Run_Readiness_Working_Context_Invalid;
         when Editor.Build_UI.Build_UI_Rejected_Missing_Consent =>
            return Build_Run_Readiness_Consent_Required;
         when Editor.Build_UI.Build_UI_Rejected_Stale_Consent =>
            return Build_Run_Readiness_Consent_Stale;
         when Editor.Build_UI.Build_UI_Rejected_Execution_Backend_Disabled =>
            return Build_Run_Readiness_Execution_Backend_Disabled;
      end case;
   end Map_UI_Status;

end Editor.Build_Command.Projections;
