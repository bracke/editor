with Editor.Commands.Availability_Metadata;
with Editor.Build_Command.Projections;
with Editor.Build_Candidates;
with Editor.Build_Diagnostics;
with Editor.Build_Public_Request;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.External_Producers;
with Editor.External_Producers.Build_Types;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Build_Requests;
with Editor.Project;
with Editor.State;

package body Editor.Build_Command.Readiness is

   use type Build_Run_Readiness_Status;
   use type Editor.Build_Runner_Policy.Build_Execution_Policy;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.External_Producers.Build_Types.Build_Request_Validation_Status;

   function Build_Run_Readiness
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
   is
      UI_Status : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Validate_Build_UI_State (State.Build.Build_UI);
   begin
      if State.Build.Public_Job_Active
        or else State.Build.Public_Async_Job_Queued
      then
         return Build_Run_Readiness_Job_Already_Active;
      elsif not Editor.Project.Has_Project (State.Project) then
         return Build_Run_Readiness_No_Project_Open;
      end if;

      if UI_Status /= Editor.Build_UI.Build_UI_Valid then
         return Editor.Build_Command.Projections.Map_UI_Status (UI_Status);
      end if;

      case State.Build.Public_Execution_Policy is
         when Editor.Build_Runner_Policy.Build_Execution_Disabled |
              Editor.Build_Runner_Policy.Build_Execution_Stub_Only =>
            return Build_Run_Readiness_Execution_Backend_Disabled;
         when Editor.Build_Runner_Policy.Build_Execution_Bounded_Process =>
            null;
      end case;

      declare
         Candidate_Status : constant Build_Run_Readiness_Status :=
           Editor.Build_Command.Projections.Selected_Candidate_Preflight_Status (State);
      begin
         if Candidate_Status /= Build_Run_Readiness_Ready then
            return Candidate_Status;
         end if;
      end;

      return Build_Run_Readiness_Ready;
   end Build_Run_Readiness;

   function Build_Run_Unavailable_Reason
     (Status : Build_Run_Readiness_Status) return String
   is
   begin
      case Status is
         when Build_Run_Readiness_Ready =>
            return "Build request ready";
         when Build_Run_Readiness_No_Project_Open =>
            return "No project open.";
         when Build_Run_Readiness_No_Candidate_Selected =>
            return "No build candidate selected.";
         when Build_Run_Readiness_Selected_Candidate_Stale =>
            return "Selected build candidate is stale.";
         when Build_Run_Readiness_Candidate_File_Missing =>
            return "Build candidate file no longer exists.";
         when Build_Run_Readiness_Request_Incomplete =>
            return "Build request is not ready.";
         when Build_Run_Readiness_Tool_Required =>
            return "Build unavailable: build tool required.";
         when Build_Run_Readiness_Arguments_Invalid =>
            return "Build unavailable: structured arguments invalid.";
         when Build_Run_Readiness_Working_Context_Required =>
            return "Build working directory is required.";
         when Build_Run_Readiness_Working_Context_Unavailable =>
            return "Build working directory is unavailable.";
         when Build_Run_Readiness_Working_Context_Invalid =>
            return "Build working directory is rejected.";
         when Build_Run_Readiness_Consent_Required =>
            return "Consent required.";
         when Build_Run_Readiness_Consent_Stale =>
            return "Consent stale.";
         when Build_Run_Readiness_Execution_Backend_Disabled =>
            return "Build execution backend is disabled.";
         when Build_Run_Readiness_Job_Already_Active =>
            return "Build unavailable: another build job is active.";
      end case;
   end Build_Run_Unavailable_Reason;

   function Build_Run_Recovery_Hint
     (Status : Build_Run_Readiness_Status) return String
   is
   begin
      case Status is
         when Build_Run_Readiness_Ready =>
            return "Run build";
         when Build_Run_Readiness_No_Project_Open =>
            return "Open a project first";
         when Build_Run_Readiness_No_Candidate_Selected =>
            return "Refresh build candidates and select one";
         when Build_Run_Readiness_Selected_Candidate_Stale =>
            return "Refresh build candidates";
         when Build_Run_Readiness_Candidate_File_Missing =>
            return "Refresh candidates or choose another project file";
         when Build_Run_Readiness_Request_Incomplete =>
            return "Review the Build panel request";
         when Build_Run_Readiness_Tool_Required =>
            return "Choose a supported build tool";
         when Build_Run_Readiness_Arguments_Invalid =>
            return "Use structured build arguments";
         when Build_Run_Readiness_Working_Context_Required =>
            return "Select a project working directory";
         when Build_Run_Readiness_Working_Context_Unavailable =>
            return "Refresh the project working context";
         when Build_Run_Readiness_Working_Context_Invalid =>
            return "Use the current project or workspace context";
         when Build_Run_Readiness_Consent_Required =>
            return "Review the request and acknowledge consent";
         when Build_Run_Readiness_Consent_Stale =>
            return "Review changed request and acknowledge consent again";
         when Build_Run_Readiness_Execution_Backend_Disabled =>
            return "Enable bounded build execution policy";
         when Build_Run_Readiness_Job_Already_Active =>
            return "Wait for the active build or cancel it";
      end case;
   end Build_Run_Recovery_Hint;

   function Build_Run_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Availability_Metadata.Command_Availability
   is
      Status : constant Build_Run_Readiness_Status := Build_Run_Readiness (State);
   begin
      if Status = Build_Run_Readiness_Ready then
         return Editor.Commands.Availability_Metadata.Available;
      end if;
      return Editor.Commands.Availability_Metadata.Unavailable (Build_Run_Unavailable_Reason (Status));
   end Build_Run_Availability;

   function Has_Active_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return State.Build.Public_Job_Active;
   end Has_Active_Public_Build_Job;

   function Build_Cancel_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Availability_Metadata.Command_Availability
   is
   begin
      if State.Build.Public_Job_Active then
         return Editor.Commands.Availability_Metadata.Available;
      end if;
      return Editor.Commands.Availability_Metadata.Unavailable ("No active build job.");
   end Build_Cancel_Availability;

   function Validate_Build_Run_Invocation
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build.Build_UI);
   begin
      if State.Build.Public_Job_Active
        or else State.Build.Public_Async_Job_Queued
      then
         return Build_Run_Readiness_Job_Already_Active;
      elsif not Editor.Project.Has_Project (State.Project) then
         return Build_Run_Readiness_No_Project_Open;
      end if;

      if Conversion.Status /= Editor.Build_UI.Build_UI_Valid then
         return Editor.Build_Command.Projections.Map_UI_Status (Conversion.Status);
      end if;

      case State.Build.Public_Execution_Policy is
         when Editor.Build_Runner_Policy.Build_Execution_Disabled |
              Editor.Build_Runner_Policy.Build_Execution_Stub_Only =>
            return Build_Run_Readiness_Execution_Backend_Disabled;
         when Editor.Build_Runner_Policy.Build_Execution_Bounded_Process =>
            null;
      end case;

      declare
         Candidate_Status : constant Build_Run_Readiness_Status :=
           Editor.Build_Command.Projections.Selected_Candidate_Preflight_Status (State);
      begin
         if Candidate_Status /= Build_Run_Readiness_Ready then
            return Candidate_Status;
         end if;
      end;

      if Editor.External_Producers.Build_Requests.Validate_Build_Run_Request_Status
        (Conversion.Request) /= Editor.External_Producers.Build_Types.Build_Request_Valid
      then
         return Build_Run_Readiness_Request_Incomplete;
      end if;

      return Build_Run_Readiness_Ready;
   end Validate_Build_Run_Invocation;

   function Build_Run_Execution_Gate
     (State : Editor.State.State_Type)
      return Editor.External_Producers.Build_Types.Build_Execution_Gate
   is
      Ready_To_Run : constant Boolean :=
        Validate_Build_Run_Invocation (State) = Build_Run_Readiness_Ready;
      Consent : constant Editor.External_Producers.Build_Types.Build_Execution_Consent :=
        (if Ready_To_Run
         then Editor.External_Producers.Build_Types.Build_Consent_User_Confirmed
         else Editor.External_Producers.Build_Types.Build_Consent_Not_Provided);
   begin
      case State.Build.Public_Execution_Policy is
         when Editor.Build_Runner_Policy.Build_Execution_Disabled |
              Editor.Build_Runner_Policy.Build_Execution_Stub_Only =>
            return Editor.External_Producers.Execution_Policy.Build_Default_Execution_Gate;
         when Editor.Build_Runner_Policy.Build_Execution_Bounded_Process =>
           return Editor.External_Producers.Execution_Policy.Build_Real_Execution_Gate
              (Allow_Diagnostics_Ingestion =>
                 Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Allowed
                   (Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
                    State.Build.Build_UI.Show_Diagnostics_On_Result),
               Show_Diagnostics            =>
                 Editor.Build_Diagnostics.Build_Diagnostics_Show_Diagnostics_Allowed
                   (Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
                    State.Build.Build_UI.Show_Diagnostics_On_Result),
               Require_Absolute_Program    => False,
               Max_Output_Bytes            =>
                 Editor.Build_UI.Output_Capture_Limit_Bytes
                   (State.Build.Build_UI.Output_Capture_Limit),
               Consent                     => Consent);
      end case;
   end Build_Run_Execution_Gate;

end Editor.Build_Command.Readiness;
