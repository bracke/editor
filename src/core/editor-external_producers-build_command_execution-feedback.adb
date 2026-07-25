with Ada.Calendar;
with Ada.Directories;
with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Hostkit.Process;
with Editor.Image_Helpers;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.Build_Runner_Policy;
with Editor.State;
with Editor.External_Producers.Diagnostics;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Request_Policies;
with Editor.External_Producers.Source_Metadata;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Command_Execution.Output_Capture; use Editor.External_Producers.Build_Command_Execution.Output_Capture;
with Editor.External_Producers.Build_Command_Execution.Diagnostics; use Editor.External_Producers.Build_Command_Execution.Diagnostics;
with Editor.External_Producers.Build_Command_Execution.Preflight; use Editor.External_Producers.Build_Command_Execution.Preflight;
with Editor.External_Producers.Build_Command_Execution.Fixture_Gates; use Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
with Editor.External_Producers.Build_Command_Execution.Real_Process; use Editor.External_Producers.Build_Command_Execution.Real_Process;
with Editor.External_Producers.Build_Command_Execution.Results; use Editor.External_Producers.Build_Command_Execution.Results;

package body Editor.External_Producers.Build_Command_Execution.Feedback is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

   function Build_Status_Label (Status : Build_Run_Status) return String is
   begin
      case Status is
         when Build_Run_Succeeded =>
            return "Build: succeeded";
         when Build_Run_Failed =>
            return "Build: failed";
         when Build_Run_Not_Available =>
            return "Build: not available";
         when Build_Run_Rejected =>
            return "Build: rejected";
         when Build_Run_Execution_Error =>
            return "Build: execution error";
         when Build_Run_Timed_Out =>
            return "Build: timed out";
         when Build_Run_Cancelled =>
            return "Build: cancelled";
         when Build_Run_Cancellation_Unsupported =>
            return "Build: cancellation unsupported";
         when Build_Run_Output_Truncated =>
            return "Build: output truncated";
      end case;
   end Build_Status_Label;

   function Real_Build_Tool_Fixture_Rejection_Feedback
     (Status : Real_Build_Tool_Fixture_Validation_Status) return String is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return "Build: build fixture accepted";
         when Real_Build_Fixture_Rejected_Disabled =>
            return "Build: real build fixture disabled";
         when Real_Build_Fixture_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when Real_Build_Fixture_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when Real_Build_Fixture_Rejected_Shell =>
            return "Build: shell execution disabled";
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Real_Build_Fixture_Not_Available =>
            return "Build: build fixture unavailable";
         when Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Custom_Tool
            | Real_Build_Fixture_Rejected_Ambiguous_Gate =>
            return "Build: build fixture rejected";
      end case;
   end Real_Build_Tool_Fixture_Rejection_Feedback;

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
      Accepted : constant Natural :=
        Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Rejected : constant Natural :=
        Diagnostic_Result.Ingestion.Parse_Rejected_Malformed_Count;
      Ignored : constant Natural :=
        Diagnostic_Result.Ingestion.Parse_Ignored_Blank_Count
        + Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count;
      Message : Unbounded_String :=
        To_Unbounded_String
          (case Build_Result.Status is
              when Build_Run_Timed_Out =>
                 "Build failed: timed out",
              when Build_Run_Cancelled =>
                 "Build cancelled",
              when Build_Run_Cancellation_Unsupported =>
                 "Build unavailable: cancellation unsupported",
              when others =>
                 Build_Status_Label (Build_Result.Status));
   begin
      if Accepted > 0
        and then Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed | Build_Run_Execution_Error
      then
         Append
           (Source => Message,
            New_Item => To_Unbounded_String
              (", ingested "
               & Editor.Image_Helpers.Trim_Image (Accepted)
               & " diagnostics"));
      elsif Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed
        and then Diagnostic_Result.Ingestion.Parse_Input_Count > 0
      then
         Append
           (Source => Message,
            New_Item => To_Unbounded_String (", no diagnostics parsed"));
         if Ignored > 0 then
            Append
              (Source => Message,
               New_Item => To_Unbounded_String
                 (", ignored "
                  & Editor.Image_Helpers.Trim_Image (Ignored)
                  & " lines"));
         end if;
      end if;

      if Accepted = 0 and then Rejected > 0 then
         Append
           (Source => Message,
            New_Item => To_Unbounded_String
              (", rejected "
               & Editor.Image_Helpers.Trim_Image (Rejected)
               & " malformed lines"));
      end if;

      return To_String (Message);
   end Build_Build_Command_Feedback;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                  : Build_Run_Result;
      Diagnostic_Result             : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used    : Boolean;
      Diagnostics_Ingestion_Allowed : Boolean) return String
   is
      Message : Unbounded_String :=
        To_Unbounded_String
          (Build_Build_Command_Feedback (Build_Result, Diagnostic_Result));
   begin
      if not Diagnostics_Ingestion_Allowed then
         if Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed then
            return Build_Status_Label (Build_Result.Status)
              & ", diagnostics ingestion disabled";
         else
            return "Build: diagnostics ingestion disabled";
         end if;
      end if;

      if Build_Result.Status = Build_Run_Not_Available
        and then Diagnostic_Result.Ingestion.Parse_Input_Count = 0
      then
         return "Build: real execution unavailable";
      end if;

      return To_String (Message);
   end Build_Gated_Build_Command_Feedback;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         if Result.Build_Request_Status = Build_Request_Rejected_Provenance
           or else Result.Build_Request_Status = Build_Request_Rejected_Unknown_Provenance
         then
            return "Build: user opt-in required";
         else
            return Build_Request_Rejection_Feedback (Result.Build_Request_Status);
         end if;
      elsif Result.Process_Request_Status /= Process_Request_Valid then
         if Result.Process_Request_Status = Process_Request_Rejected_Execution_Disabled then
            return "Build: real build execution disabled";
         else
            return Process_Request_Rejection_Feedback
              (Result.Process_Request_Status);
         end if;
      else
         return "Build: accepted";
      end if;
   end Build_User_Opt_In_Build_Feedback;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
   begin
      case Status is
         when User_Build_Context_Valid =>
            case Result.Build_Result.Status is
               when Build_Run_Succeeded =>
                  if Ingested > 0 then
                     return "Build: succeeded, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: succeeded";
                  end if;
               when Build_Run_Failed =>
                  if Ingested > 0 then
                     return "Build: failed, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: failed";
                  end if;
               when Build_Run_Not_Available =>
                  return "Build: real execution unavailable";
               when Build_Run_Rejected =>
                  return "Build: rejected";
               when Build_Run_Execution_Error =>
                  return "Build: execution error";
               when Build_Run_Timed_Out =>
                  return "Build failed: timed out";
               when Build_Run_Cancelled =>
                  return "Build cancelled";
               when Build_Run_Cancellation_Unsupported =>
                  return "Build unavailable: cancellation unsupported";
               when Build_Run_Output_Truncated =>
                  return "Build: output truncated";
            end case;
         when User_Build_Context_Rejected_Missing_Context
            | User_Build_Context_Rejected_Missing_Request
            | User_Build_Context_Rejected_Provenance =>
            return "Build: user opt-in required";
         when User_Build_Context_Rejected_Missing_Gate =>
            return "Build: real build execution disabled";
         when User_Build_Context_Rejected_Missing_Consent =>
            return "Build: execution consent required";
         when User_Build_Context_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when User_Build_Context_Rejected_Custom_Tool =>
            return "Build: custom build tool not supported";
         when User_Build_Context_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when User_Build_Context_Rejected_Shell =>
            return "Build: shell execution disabled";
         when User_Build_Context_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when User_Build_Context_Rejected_Ambiguous_Execution_Path =>
            return "Build: invalid build command context";
      end case;
   end Build_User_Opt_In_Command_Feedback;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
   begin
      if Build_Result.Status = Build_Run_Not_Available then
         return "Build: build fixture unavailable";
      elsif Build_Result.Status = Build_Run_Rejected then
         return "Build: build fixture rejected";
      elsif Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed
        and then Diagnostic_Result.Ingestion.Parse_Input_Count > 0
        and then Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0
      then
         return Build_Status_Label (Build_Result.Status)
           & ", no diagnostics parsed";
      else
         return Build_Build_Command_Feedback (Build_Result, Diagnostic_Result);
      end if;
   end Build_Real_Build_Tool_Fixture_Feedback;

   function Process_Fixture_Rejection_Feedback
     (Status : Process_Fixture_Validation_Status) return String
   is
   begin
      case Status is
         when Fixture_Request_Valid =>
            return "Build: fixture accepted";
         when Fixture_Request_Rejected_Disabled =>
            return "Build: fixture execution disabled";
         when Fixture_Request_Not_Available =>
            return "Build: fixture unavailable";
         when Fixture_Request_Rejected_Unknown_Fixture
            | Fixture_Request_Rejected_Shell
            | Fixture_Request_Rejected_Opaque_Arguments
            | Fixture_Request_Rejected_Invalid_Argument
            | Fixture_Request_Rejected_Output_Limit =>
            return "Build: fixture rejected";
      end case;
   end Process_Fixture_Rejection_Feedback;


end Editor.External_Producers.Build_Command_Execution.Feedback;
