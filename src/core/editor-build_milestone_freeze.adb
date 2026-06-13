with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_Command;
with Editor.Build_Command_Audit;
with Editor.Build_Diagnostics;
with Editor.Build_Public_Request;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Commands;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Project;

package body Editor.Build_Milestone_Freeze is

   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Build_UI.Public_Build_Tool_Selection;
   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.Build_Working_Context.Build_Working_Context_Kind;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.External_Producers.Build_Tool_Kind;
   use type Editor.External_Producers.Process_Run_Status;
   use type Editor.External_Producers.Process_Execution_Mode;
   use type Editor.External_Producers.Process_Request_Validation_Status;
   use type Editor.External_Producers.Build_Request_Provenance;


   procedure Open_Fake_Project (State : in out Editor.State.State_Type)
   is
      Project_Result : constant Editor.Project.Project_Open_Result :=
        (Status => Editor.Project.Project_Open_Ok,
         Root_Path => To_Unbounded_String ("current-project-root"),
         Display_Name => To_Unbounded_String ("current-project-root"),
         Error_Text => Null_Unbounded_String);
   begin
      Editor.Project.Apply_Open_Result (State.Project, Project_Result);
   end Open_Fake_Project;

   function Ready_Manual_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "demo.gpr");
   begin
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Focus (S);
      Editor.Build_Candidates.Append_Unique_Candidate (Candidates, Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "bounded project-root candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S, True);
      Editor.Build_UI.Acknowledge_Consent (S);
      return S;
   end Ready_Manual_UI;

   function Ready_Candidate_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
   begin
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Focus (S);
      Editor.Build_Candidates.Append_Unique_Candidate (Candidates, Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "bounded project-root candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      return S;
   end Ready_Candidate_UI;

   function Request_From
     (State : Editor.Build_UI.Public_Build_UI_State)
      return Editor.Build_Public_Request.Public_Build_Request_Conversion_Result
   is
   begin
      return Editor.Build_Public_Request.Build_Public_Request_From_UI_State
        (State);
   end Request_From;

   function Assert_Public_Build_Manual_Request_Frozen return Boolean
   is
      S : constant Editor.Build_UI.Public_Build_UI_State := Ready_Manual_UI;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Request_From (S);
   begin
      return S.Build_UI_Visible
        and then S.Build_UI_Focused
        and then S.Candidate_Applied_To_Request
        and then S.Selected_Build_Tool = Editor.Build_UI.Build_UI_GPRbuild
        and then Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 2
        and then S.Selected_Working_Context.Kind =
          Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root
        and then S.Show_Diagnostics_On_Result
        and then S.Consent_Acknowledged
        and then Editor.Build_UI.Validate_Build_UI_State (S) =
          Editor.Build_UI.Build_UI_Valid
        and then C.Status = Editor.Build_UI.Build_UI_Valid
        and then C.Request.Tool = Editor.External_Producers.GPRbuild_Tool
        and then C.Request.Provenance =
          Editor.External_Producers.Build_Request_From_User_Opt_In
        and then To_String (C.Request.Command_Label) = "gprbuild"
        and then To_String (C.Request.Arguments)'Length = 0
        and then Editor.External_Producers.Process_Argument_Count
          (C.Request.Structured_Arguments) = 2
        and then Editor.Build_UI.Assert_Build_UI_State_Is_Transient (S);
   end Assert_Public_Build_Manual_Request_Frozen;

   function Assert_Public_Build_Candidate_Request_Frozen return Boolean
   is
      S : Editor.Build_UI.Public_Build_UI_State := Ready_Candidate_UI;
      Candidate_Id : constant String := To_String (S.Selected_Build_Candidate_Id);
      Missing_Status : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Validate_Build_UI_State (S);
      C : Editor.Build_Public_Request.Public_Build_Request_Conversion_Result;
   begin
      if Candidate_Id'Length = 0
        or else not S.Candidate_Applied_To_Request
        or else S.Consent_Acknowledged
        or else Missing_Status /= Editor.Build_UI.Build_UI_Rejected_Missing_Consent
      then
         return False;
      end if;

      Editor.Build_UI.Acknowledge_Consent (S);
      C := Request_From (S);

      return Editor.Build_UI.Candidate_Count (S) = 1
        and then S.Candidate_Applied_To_Request
        and then To_String (S.Selected_Build_Candidate_Id) = Candidate_Id
        and then S.Selected_Build_Tool = Editor.Build_UI.Build_UI_Alire
        and then Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 1
        and then To_String (S.Candidate_Request_Preview)'Length > 0
        and then C.Status = Editor.Build_UI.Build_UI_Valid
        and then C.Request.Tool = Editor.External_Producers.Alire_Build_Tool
        and then To_String (C.Request.Command_Label) = "alr"
        and then To_String (C.Request.Arguments)'Length = 0
        and then Editor.External_Producers.Process_Argument_Count
          (C.Request.Structured_Arguments) = 1
        and then not Editor.Build_UI.Command_Palette_Can_Supply_Candidate (S)
        and then not Editor.Build_UI.Keybinding_Can_Supply_Candidate (S)
        and then Editor.Build_UI.Assert_Build_UI_State_Is_Transient (S);
   end Assert_Public_Build_Candidate_Request_Frozen;

   function Assert_Public_Build_Request_Identity_Frozen return Boolean
   is
      S : Editor.Build_UI.Public_Build_UI_State := Ready_Manual_UI;
      Original : constant String := Editor.Build_UI.Current_Request_Identity (S);
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      if To_String (S.Consent_Request_Identity) /= Original then
         return False;
      end if;

      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_Alire);
      if Editor.Build_UI.Validate_Build_UI_State (S) /=
        Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected
      then
         return False;
      end if;

      S := Ready_Manual_UI;
      Editor.Build_UI.Append_Argument (Args, "-gnat2022");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      if Editor.Build_UI.Validate_Build_UI_State (S) /=
        Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected
      then
         return False;
      end if;

      S := Ready_Manual_UI;
      S.Selected_Working_Context :=
        Editor.Build_Working_Context.Current_Workspace_Root
          ("active-workspace-root");
      if Editor.Build_UI.Validate_Build_UI_State (S) /=
        Editor.Build_UI.Build_UI_Rejected_Stale_Consent
      then
         return False;
      end if;

      S := Ready_Candidate_UI;
      if S.Consent_Acknowledged then
         return False;
      end if;
      Editor.Build_UI.Acknowledge_Consent (S);
      Editor.Build_UI.Clear_Selected_Build_Candidate (S);
      return Editor.Build_UI.Validate_Build_UI_State (S) =
        Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected;
   end Assert_Public_Build_Request_Identity_Frozen;

   function Assert_Public_Build_Consent_Frozen return Boolean
   is
      S : Editor.Build_UI.Public_Build_UI_State := Ready_Manual_UI;
      State : Editor.State.State_Type;
   begin
      State.Build_UI := S;
      State.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
      Open_Fake_Project (State);

      if Editor.Build_Command.Build_Run_Readiness (State) /=
        Editor.Build_Command.Build_Run_Readiness_Ready
      then
         return False;
      end if;

      Editor.Build_UI.Clear_Consent (S);
      State.Build_UI := S;
      return Editor.Build_Command.Build_Run_Readiness (State) =
        Editor.Build_Command.Build_Run_Readiness_Consent_Required;
   end Assert_Public_Build_Consent_Frozen;

   function Assert_Public_Build_Runner_Boundary_Frozen return Boolean
   is
      S : Editor.State.State_Type;
      UI : constant Editor.Build_UI.Public_Build_UI_State := Ready_Manual_UI;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Request_From (UI);
      Gate : Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Default_Execution_Gate;
      Supplied : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True,
           Stdout_Text => "ok",
           Stderr_Text => "");
      Result : Editor.External_Producers.Build_Command_Result;
      Preflight : Editor.External_Producers.Build_Preflight_Result;
      Rejected : Editor.External_Producers.Process_Run_Result;
   begin
      Gate.Process_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Test_Fixture,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 16,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Gate.Allow_Build_Run := True;
      Gate.Consent := Editor.External_Producers.Build_Consent_Test_Only;
      Gate.Allow_Diagnostics_Ingestion := False;
      Gate.Show_Diagnostics := False;

      Preflight := Editor.External_Producers.Preflight_Build_Run_Request
        (C.Request, Gate.Process_Policy);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, C.Request, Gate, Supplied);
      Rejected := Editor.External_Producers.Enforce_Process_Output_Bounds
        (Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0,
            Has_Exit_Code => True,
            Stdout_Text => "01234567890123456789"),
         Gate.Process_Policy);

      return Preflight.Process_Request_Status =
          Editor.External_Producers.Process_Request_Valid
        and then To_String (Preflight.Process_Request.Program_Label) = "gprbuild"
        and then To_String (Preflight.Process_Request.Arguments)'Length = 0
        and then Editor.External_Producers.Process_Argument_Count
          (Preflight.Process_Request.Structured_Arguments) = 2
        and then not Gate.Process_Policy.Allow_Shell
        and then Gate.Process_Policy.Mode =
          Editor.External_Producers.Process_Execution_Test_Fixture
        and then Result.Build_Result.Status =
          Editor.External_Producers.Build_Run_Succeeded
        and then To_String (Result.Build_Result.Stdout_Text) = "ok"
        and then To_String (Result.Command_Message)'Length > 0
        and then Rejected.Status = Editor.External_Producers.Process_Run_Execution_Error;
   end Assert_Public_Build_Runner_Boundary_Frozen;

   function Assert_Public_Build_Diagnostics_Boundary_Frozen return Boolean
   is
      S : Editor.State.State_Type;
      UI : constant Editor.Build_UI.Public_Build_UI_State := Ready_Manual_UI;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Request_From (UI);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Build_Result : Editor.External_Producers.Build_Run_Result;
      Disabled : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Enabled  : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Lines.Append (To_Unbounded_String ("main.adb:1:1: error: frozen"));
      Build_Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Exit_Code => 1,
         Has_Exit_Code => True,
         Diagnostic_Lines => Lines);

      Disabled := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, C.Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Disabled,
         Request_Show_Diagnostics => True);
      if Disabled.Ingestion.Parse_Input_Count /= 0
        or else Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) /= 0
      then
         return False;
      end if;

      Enabled := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, C.Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      return Enabled.Ingestion.Parse_Input_Count = 1
        and then Enabled.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1
        and then Editor.Build_Diagnostics.Assert_Build_Diagnostics_Not_Persisted;
   end Assert_Public_Build_Diagnostics_Boundary_Frozen;

   function Assert_Public_Build_Frontdoor_Boundaries_Frozen
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command.Assert_Build_Run_Descriptor_Stable
        and then Editor.Build_Command.Assert_Build_Run_Routes_Through_Executor
          (State)
        and then Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary
          (State)
        and then Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary
        and then not Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run).Bindable
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run) = "build.run";
   end Assert_Public_Build_Frontdoor_Boundaries_Frozen;

   function Assert_Public_Build_Persistence_Excluded_Frozen
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command.Assert_Build_Run_Persistence_Excluded (State)
        and then Editor.Build_UI.Assert_Build_UI_State_Is_Transient
          (State.Build_UI)
        and then not Editor.Build_UI.Has_Remembered_Consent_Field
          (State.Build_UI)
        and then not Editor.Build_UI.Has_Candidate_Execution_Field
          (State.Build_UI)
        and then Editor.Build_Diagnostics.Assert_Build_Diagnostics_Not_Persisted;
   end Assert_Public_Build_Persistence_Excluded_Frozen;

   function Run_Public_Build_Command_Milestone_Freeze_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Milestone_Freeze
   is
      Result : Public_Build_Command_Milestone_Freeze;
      Audit_State : Editor.State.State_Type := State;
      One_Message_State : Editor.State.State_Type := State;
      One_Message_Result : Editor.External_Producers.Build_Command_Result;
      Manual : constant Editor.Build_UI.Public_Build_UI_State := Ready_Manual_UI;
   begin
      Audit_State.Build_UI := Ready_Manual_UI;
      Audit_State.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Disabled;
      declare
         Audit : constant Editor.Build_Command_Audit.Public_Build_Command_UX_Foundation_Audit :=
           Editor.Build_Command_Audit.Run_Public_Build_Command_UX_Foundation_Audit
             (Audit_State);
      begin
      Result.Manual_Request_Frozen :=
        Assert_Public_Build_Manual_Request_Frozen;
      Result.Candidate_Request_Frozen :=
        Assert_Public_Build_Candidate_Request_Frozen;
      Result.Request_Identity_And_Consent_Frozen :=
        Assert_Public_Build_Request_Identity_Frozen
        and then Assert_Public_Build_Consent_Frozen;
      Result.Working_Context_Frozen :=
        Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Structured
          (Manual.Selected_Working_Context)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Transient
          (Manual.Selected_Working_Context);
      Result.Build_Run_Route_Frozen :=
        Editor.Build_Command.Assert_Public_Build_Command_Registration_Coherent
          (Audit_State);
      Result.Runner_Boundary_Frozen :=
        Assert_Public_Build_Runner_Boundary_Frozen;
      Result.Diagnostics_Boundary_Frozen :=
        Assert_Public_Build_Diagnostics_Boundary_Frozen;
      Result.Frontdoor_Boundaries_Frozen :=
        Assert_Public_Build_Frontdoor_Boundaries_Frozen (Audit_State);
      Result.Render_And_Audit_Boundaries_Frozen :=
        Audit.Side_Effect_Free
        and then Editor.Build_Command.Assert_Build_Run_Availability_Side_Effect_Free
          (Audit_State);
      Result.Persistence_Exclusion_Frozen :=
        Assert_Public_Build_Persistence_Excluded_Frozen (Audit_State);
      Result.Behavior_Preservation_Frozen :=
        Editor.Build_Public_Request.Assert_Public_Build_Command_UX_Foundation_Coherent
          (Manual)
        and then Editor.Build_Public_Request.Assert_Public_Build_Working_Context_Foundation_Coherent
          (Manual)
        and then Editor.Build_Diagnostics.Assert_Public_Build_Diagnostics_Ingestion_Foundation_Coherent;
      One_Message_Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (One_Message_State,
         Request_From (Manual).Request,
         Editor.External_Producers.Build_Default_Execution_Gate);
      Result.One_Primary_Message_Frozen :=
        To_String (One_Message_Result.Command_Message)'Length > 0;
      end;
      Result.Coherent :=
        Result.Manual_Request_Frozen
        and then Result.Candidate_Request_Frozen
        and then Result.Request_Identity_And_Consent_Frozen
        and then Result.Working_Context_Frozen
        and then Result.Build_Run_Route_Frozen
        and then Result.Runner_Boundary_Frozen
        and then Result.Diagnostics_Boundary_Frozen
        and then Result.Frontdoor_Boundaries_Frozen
        and then Result.Render_And_Audit_Boundaries_Frozen
        and then Result.Persistence_Exclusion_Frozen
        and then Result.Behavior_Preservation_Frozen
        and then Result.One_Primary_Message_Frozen;
      return Result;
   end Run_Public_Build_Command_Milestone_Freeze_Audit;

   function Assert_Public_Build_Command_Milestone_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Run_Public_Build_Command_Milestone_Freeze_Audit (State).Coherent;
   end Assert_Public_Build_Command_Milestone_Coherent;

end Editor.Build_Milestone_Freeze;
