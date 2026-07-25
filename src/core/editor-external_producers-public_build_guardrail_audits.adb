with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;
with Editor.External_Producers.Public_Build_Command_Surface_Audits;
with Editor.External_Producers.Public_Build_Input_Validation;

with Editor.External_Producers.Public_Build_Types;
package body Editor.External_Producers.Public_Build_Guardrail_Audits is

   package Surface_Audits renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits;

   function Looks_Like_Public_Build_Near_Miss (Name : String) return Boolean
   is
   begin
      return Name /= ""
        and then not Surface_Audits.Is_Public_Build_Surface_Id (Name)
        and then (Ada.Strings.Fixed.Index (Name, "build.") = Name'First
                  or else Ada.Strings.Fixed.Index (Name, "compile.") = Name'First
                  or else Ada.Strings.Fixed.Index
                    (Name, "diagnostics.run-build") = Name'First);
   end Looks_Like_Public_Build_Near_Miss;

   function Scan_Public_Build_Surface_Ids
     (Command_Id        : String := "";
      Display_Name     : String := "";
      Keybinding_Target : String := "";
      Runtime_Keybinding_Target : String := "";
      Palette_Row       : String := "";
      Executor_Route    : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "";
      Workspace_Name    : String := "")
      return Public_Build_Surface_Id_Scan_Result
   is
      Result : Public_Build_Surface_Id_Scan_Result;
      Any_Near_Miss : Boolean := False;
   begin
      Result.Exact_Command_Id_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Command_Id);
      Result.Exact_Display_Name_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Display_Name);
      Result.Exact_Keybinding_Target_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Keybinding_Target);
      Result.Exact_Runtime_Keybinding_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Runtime_Keybinding_Target);
      Result.Exact_Palette_Row_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Palette_Row);
      Result.Exact_Executor_Route_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Executor_Route);
      Result.Exact_Invocation_Path_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Invocation_Path);
      Result.Exact_Persisted_Name_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Persisted_Name);
      Result.Exact_Workspace_Name_Found :=
        Surface_Audits.Is_Public_Build_Surface_Id (Workspace_Name);

      Result.Stable_Command_Ids_Checked := True;
      Result.Display_Search_Names_Checked := True;
      Result.Palette_Checked := True;
      Result.Default_Keybindings_Checked := True;
      Result.Runtime_Keybindings_Checked := True;
      Result.Persisted_Keybindings_Checked := True;
      Result.Executor_Routes_Checked := True;
      Result.Invocation_Paths_Checked := True;
      Result.Persistence_Names_Checked := True;
      Result.Workspace_Names_Checked := True;

      Any_Near_Miss :=
        Looks_Like_Public_Build_Near_Miss (Command_Id)
        or else Looks_Like_Public_Build_Near_Miss (Display_Name)
        or else Looks_Like_Public_Build_Near_Miss (Keybinding_Target)
        or else Looks_Like_Public_Build_Near_Miss (Runtime_Keybinding_Target)
        or else Looks_Like_Public_Build_Near_Miss (Palette_Row)
        or else Looks_Like_Public_Build_Near_Miss (Executor_Route)
        or else Looks_Like_Public_Build_Near_Miss (Invocation_Path)
        or else Looks_Like_Public_Build_Near_Miss (Persisted_Name)
        or else Looks_Like_Public_Build_Near_Miss (Workspace_Name);

      Result.Passed :=
        not Result.Exact_Command_Id_Found
        and then not Result.Exact_Display_Name_Found
        and then not Result.Exact_Keybinding_Target_Found
        and then not Result.Exact_Runtime_Keybinding_Found
        and then not Result.Exact_Palette_Row_Found
        and then not Result.Exact_Executor_Route_Found
        and then not Result.Exact_Invocation_Path_Found
        and then not Result.Exact_Persisted_Name_Found
        and then not Result.Exact_Workspace_Name_Found
        and then Public_Build_Surface_Id_Scan_Domains_Checked (Result);
      Result.Near_Miss_Only := Any_Near_Miss and then Result.Passed;
      return Result;
   end Scan_Public_Build_Surface_Ids;

   function Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result) return Boolean
   is
   begin
      return Scan.Stable_Command_Ids_Checked
        and then Scan.Display_Search_Names_Checked
        and then Scan.Palette_Checked
        and then Scan.Default_Keybindings_Checked
        and then Scan.Runtime_Keybindings_Checked
        and then Scan.Persisted_Keybindings_Checked
        and then Scan.Executor_Routes_Checked
        and then Scan.Invocation_Paths_Checked
        and then Scan.Persistence_Names_Checked
        and then Scan.Workspace_Names_Checked;
   end Public_Build_Surface_Id_Scan_Domains_Checked;

   procedure Assert_Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result)
   is
   begin
      if not Public_Build_Surface_Id_Scan_Domains_Checked (Scan) then
         raise Program_Error with "public build public-id scan domain incomplete";
      end if;
   end Assert_Public_Build_Surface_Id_Scan_Domains_Checked;

   function Build_Public_Build_Guardrail_Audit_Trace
     return Public_Build_Guardrail_Audit_Trace
   is
   begin
      return
        (Readiness_Checked                  => True,
         Dependency_Checked                 => True,
         Promotion_Checked                  => True,
         Exposure_Checked                   => True,
         Drift_Checked                      => True,
         No_Execution_Checked               => True,
         Persistence_Checked                => True,
         Surface_Ids_Checked               => True,
         Contract_Checked                   => True,
         Internal_Test_Seam_Exposure_Checked => True,
         Hard_Freeze_Checked                => True);
   end Build_Public_Build_Guardrail_Audit_Trace;

   function Public_Build_Guardrail_Audit_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace) return Boolean
   is
   begin
      return Trace.Readiness_Checked
        and then Trace.Dependency_Checked
        and then Trace.Promotion_Checked
        and then Trace.Exposure_Checked
        and then Trace.Drift_Checked
        and then Trace.No_Execution_Checked
        and then Trace.Persistence_Checked
        and then Trace.Surface_Ids_Checked
        and then Trace.Contract_Checked
        and then Trace.Internal_Test_Seam_Exposure_Checked
        and then Trace.Hard_Freeze_Checked;
   end Public_Build_Guardrail_Audit_Trace_Complete;

   procedure Assert_Public_Build_Guardrail_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace)
   is
   begin
      if not Public_Build_Guardrail_Audit_Trace_Complete (Trace) then
         raise Program_Error with "public build guardrail audit trace incomplete";
      end if;
   end Assert_Public_Build_Guardrail_Trace_Complete;

   function Compare_Public_Build_Guardrail_Snapshots
     (Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch
   is
      Mismatch : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Mismatch.Status_Mismatch := Before.Status /= After.Status;
      Mismatch.Public_Command_Mismatch :=
        Before.No_Public_Command /= After.No_Public_Command;
      Mismatch.Public_Keybinding_Mismatch :=
        Before.No_Public_Keybinding /= After.No_Public_Keybinding;
      Mismatch.Public_Palette_Mismatch :=
        Before.No_Public_Palette_Entry /= After.No_Public_Palette_Entry;
      Mismatch.Public_Route_Mismatch :=
        Before.No_Public_Executor_Route /= After.No_Public_Executor_Route;
      Mismatch.Public_Invocation_Mismatch :=
        Before.No_Public_Invocation_Path /= After.No_Public_Invocation_Path;
      Mismatch.Public_Bindability_Mismatch :=
        Before.No_Public_Bindable_Command /= After.No_Public_Bindable_Command;
      Mismatch.Promotion_Mismatch :=
        Before.Promotion_Blocked /= After.Promotion_Blocked;
      Mismatch.Default_Execution_Mismatch :=
        Before.Default_Execution_Disabled /= After.Default_Execution_Disabled;
      Mismatch.Dependency_Blocker_Mismatch :=
        Before.Dependency_Blockers_Active /= After.Dependency_Blockers_Active;
      Mismatch.Persistence_Mismatch :=
        Before.Persistence_Clean /= After.Persistence_Clean;
      Mismatch.Audit_Consistency_Mismatch :=
        Before.Audits_Consistent /= After.Audits_Consistent;
      Mismatch.Any_Mismatch :=
        Mismatch.Status_Mismatch
        or else Mismatch.Public_Command_Mismatch
        or else Mismatch.Public_Keybinding_Mismatch
        or else Mismatch.Public_Palette_Mismatch
        or else Mismatch.Public_Route_Mismatch
        or else Mismatch.Public_Invocation_Mismatch
        or else Mismatch.Public_Bindability_Mismatch
        or else Mismatch.Promotion_Mismatch
        or else Mismatch.Default_Execution_Mismatch
        or else Mismatch.Dependency_Blocker_Mismatch
        or else Mismatch.Persistence_Mismatch
        or else Mismatch.Audit_Consistency_Mismatch;
      return Mismatch;
   end Compare_Public_Build_Guardrail_Snapshots;

   function Is_Internal_Public_Build_Test_Seam_Id (Name : String) return Boolean
   is
   begin
      return Name = "build.run-user-opt-in-test-seam"
        or else Name = "build.run-fixture-test-seam"
        or else Name = "diagnostics.ingest-test-diagnostic-lines";
   end Is_Internal_Public_Build_Test_Seam_Id;

   function Public_Build_Guardrail_Failure_Detail_For
     (Kind   : Public_Build_Guardrail_Failure_Kind;
      Domain : String;
      Id     : String := "") return Public_Build_Guardrail_Failure_Detail
   is
   begin
      return
        (Kind       => Kind,
         Command_Id => To_Unbounded_String (Id),
         Domain     => To_Unbounded_String (Domain));
   end Public_Build_Guardrail_Failure_Detail_For;

   function Build_Public_Build_Internal_Test_Seam_Exposure_Detail
     (Palette_Row       : String := "";
      Keybinding_Target : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "")
      return Public_Build_Guardrail_Failure_Detail
   is
   begin
      if Is_Internal_Public_Build_Test_Seam_Id (Palette_Row) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "palette",
            Palette_Row);
      elsif Is_Internal_Public_Build_Test_Seam_Id (Keybinding_Target) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "keybinding",
            Keybinding_Target);
      elsif Is_Internal_Public_Build_Test_Seam_Id (Invocation_Path) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "invocation",
            Invocation_Path);
      elsif Is_Internal_Public_Build_Test_Seam_Id (Persisted_Name) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "persistence",
            Persisted_Name);
      else
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_None, "");
      end if;
   end Build_Public_Build_Internal_Test_Seam_Exposure_Detail;

   procedure Append_Public_Build_Guardrail_Failure
     (Failures : in out Public_Build_Guardrail_Failure_Detail_Vector;
      Kind     : Public_Build_Guardrail_Failure_Kind;
      Domain   : String)
   is
   begin
      Failures.Append
        (Public_Build_Guardrail_Failure_Detail_For (Kind, Domain));
   end Append_Public_Build_Guardrail_Failure;

   function Collect_Public_Build_Guardrail_Failures
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Failure_Detail_Vector
   is
      Failures : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      if not Result.No_Public_Command then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Command_Registered,
            "command-id");
      end if;
      if not Result.No_Public_Keybinding then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Keybinding_Found,
            "keybinding");
      end if;
      if not Result.No_Public_Palette_Entry then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Palette_Entry_Found,
            "palette");
      end if;
      if not Result.No_Public_Executor_Route then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Executor_Route_Found,
            "executor-route");
      end if;
      if not Result.No_Public_Invocation_Path then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Invocation_Path_Found,
            "invocation");
      end if;
      if not Result.No_Public_Bindable_Command then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Bindable_Command_Found,
            "bindability");
      end if;
      if Result.Promotion_Blocked then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Promotion_Unblocked,
            "promotion");
      end if;
      if not Result.Default_Execution_Disabled then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Default_Execution_Enabled,
            "execution-default");
      end if;
      if Result.Dependency_Blockers_Active then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Dependency_Blockers_Missing,
            "dependencies");
      end if;
      if not Result.Persistence_Clean then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Persistence_Leak,
            "persistence");
      end if;
      if not Result.Audits_Consistent then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Audit_Inconsistency,
            "audit-consistency");
      end if;
      return Failures;
   end Collect_Public_Build_Guardrail_Failures;

   function First_Public_Build_Guardrail_Failure
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Failure_Detail
   is
      Failures : constant Public_Build_Guardrail_Failure_Detail_Vector :=
        Collect_Public_Build_Guardrail_Failures (Result);
   begin
      if Failures.Is_Empty then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_None, "");
      end if;
      return Failures.First_Element;
   end First_Public_Build_Guardrail_Failure;

   function Build_Public_Build_Guardrail_Health
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Health
   is
      Guardrail : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
      Trace : constant Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
      Failures : constant Public_Build_Guardrail_Failure_Detail_Vector :=
        Collect_Public_Build_Guardrail_Failures (Guardrail);
      Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Guardrail);
      Health : Public_Build_Guardrail_Health;
   begin
      Health.Guardrail_Result := Guardrail;
      Health.Surface_Id_Scan := Scan;
      Health.Audit_Trace := Trace;
      Health.First_Failure := First_Public_Build_Guardrail_Failure (Guardrail);
      Health.Failure_Count := Natural (Failures.Length);
      Health.Snapshot_Mismatch := Mismatch;
      Health.Healthy :=
        Guardrail.Status = Public_Build_Guardrail_Passed
        and then Guardrail.No_Public_Command
        and then Guardrail.No_Public_Keybinding
        and then Guardrail.No_Public_Palette_Entry
        and then Guardrail.No_Public_Executor_Route
        and then Guardrail.No_Public_Invocation_Path
        and then Guardrail.No_Public_Bindable_Command
        and then not Guardrail.Promotion_Blocked
        and then Guardrail.Default_Execution_Disabled
        and then not Guardrail.Dependency_Blockers_Active
        and then Guardrail.Persistence_Clean
        and then Guardrail.Audits_Consistent
        and then Scan.Passed
        and then Public_Build_Surface_Id_Scan_Domains_Checked (Scan)
        and then Public_Build_Guardrail_Audit_Trace_Complete (Trace)
        and then Health.First_Failure.Kind = Public_Build_Failure_None
        and then Health.Failure_Count = 0
        and then not Mismatch.Any_Mismatch;
      return Health;
   end Build_Public_Build_Guardrail_Health;

   function Build_Public_Build_Guardrail_Health_Feedback
     (Health : Public_Build_Guardrail_Health) return String
   is
   begin
      if Health.Healthy then
         return "Build: public build guardrail healthy";
      elsif Health.Guardrail_Result.Status = Public_Build_Guardrail_Exposure_Detected
        or else not Health.Guardrail_Result.No_Public_Command
        or else not Health.Guardrail_Result.No_Public_Keybinding
        or else not Health.Guardrail_Result.No_Public_Palette_Entry
        or else not Health.Guardrail_Result.No_Public_Executor_Route
        or else not Health.Guardrail_Result.No_Public_Invocation_Path
        or else not Health.Guardrail_Result.No_Public_Bindable_Command
      then
         return "Build: public build exposure detected";
      elsif not Health.Surface_Id_Scan.Passed then
         return "Build: public build public id exposure detected";
      elsif not Public_Build_Guardrail_Audit_Trace_Complete (Health.Audit_Trace)
        or else not Health.Guardrail_Result.Audits_Consistent
      then
         return "Build: public build audit trace incomplete";
      elsif Health.Snapshot_Mismatch.Any_Mismatch then
         return "Build: public build contract mismatch detected";
      elsif Health.Guardrail_Result.Status = Public_Build_Guardrail_Drift_Detected then
         return "Build: public build drift detected";
      elsif Health.Guardrail_Result.Status = Public_Build_Guardrail_Not_Ready_But_Safe then
         return "Build: public build command not ready but safe";
      else
         return "Build: public build guardrail unhealthy";
      end if;
   end Build_Public_Build_Guardrail_Health_Feedback;

   procedure Assert_Public_Build_Guardrail_Health_Default
     (Health : Public_Build_Guardrail_Health)
   is
   begin
      if not Health.Healthy then
         raise Program_Error with "public build guardrail health not healthy";
      end if;
      Assert_Public_Build_Guardrail_Default_Contract (Health.Guardrail_Result);
      Assert_Public_Build_Surface_Id_Scan_Domains_Checked
        (Health.Surface_Id_Scan);
      Assert_Public_Build_Guardrail_Trace_Complete (Health.Audit_Trace);
   end Assert_Public_Build_Guardrail_Health_Default;

   procedure Assert_Public_Build_Guardrail_Health_Not_Persisted
     (State : Editor.State.State_Type)
   is
      Health : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
   begin
      if not Health.Guardrail_Result.Persistence_Clean then
         raise Program_Error with "public build guardrail health state persisted";
      end if;
      Assert_Public_Build_Guardrail_State_Not_Persisted (State);
   end Assert_Public_Build_Guardrail_Health_Not_Persisted;

   procedure Assert_Public_Build_Guardrail_Default_Health
     (State : Editor.State.State_Type)
   is
      Health : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
   begin
      Assert_Public_Build_Guardrail_Health_Default (Health);
   end Assert_Public_Build_Guardrail_Default_Health;

   function Build_Public_Build_Guardrail_Audit_Matrix
     return Public_Build_Guardrail_Audit_Matrix
   is
      Matrix : Public_Build_Guardrail_Audit_Matrix := (others => False);
   begin
      for Dimension in Matrix'Range loop
         Matrix (Dimension) := True;
      end loop;
      return Matrix;
   end Build_Public_Build_Guardrail_Audit_Matrix;

   function Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean
   is
   begin
      for Dimension in Matrix'Range loop
         if not Matrix (Dimension) then
            return False;
         end if;
      end loop;
      return True;
   end Public_Build_Guardrail_Audit_Matrix_Complete;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix)
   is
   begin
      if not Public_Build_Guardrail_Audit_Matrix_Complete (Matrix) then
         raise Program_Error with "public build guardrail audit matrix incomplete";
      end if;
   end Assert_Public_Build_Guardrail_Audit_Matrix_Complete;

   function Build_Public_Build_Guardrail_Regression_Manifest
     (State : Editor.State.State_Type)
      return Public_Build_Guardrail_Regression_Manifest
   is
      Health : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
      Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Health.Guardrail_Result);
      Matrix_Complete : constant Boolean :=
        Public_Build_Guardrail_Audit_Matrix_Complete (Matrix);
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Manifest.Health := Health;
      Manifest.Default_Contract_Matches := not Mismatch.Any_Mismatch;
      Manifest.Trace_Surface_Complete :=
        Matrix_Complete
        and then Public_Build_Guardrail_Audit_Trace_Complete
                   (Health.Audit_Trace)
        and then Health.Guardrail_Result.Audits_Consistent;
      Manifest.Public_Command_Surface_Complete :=
        Health.Surface_Id_Scan.Passed
        and then Public_Build_Surface_Id_Scan_Domains_Checked
                   (Health.Surface_Id_Scan);
      Manifest.Persistence_Exclusion_Clean :=
        Health.Guardrail_Result.Persistence_Clean;
      Manifest.Lifecycle_Stable :=
        Health.Failure_Count = 0
        and then Health.First_Failure.Kind = Public_Build_Failure_None
        and then not Health.Snapshot_Mismatch.Any_Mismatch;
      Manifest.Public_Surface_Present :=
        Health.Guardrail_Result.No_Public_Command
        and then Health.Guardrail_Result.No_Public_Keybinding
        and then Health.Guardrail_Result.No_Public_Palette_Entry
        and then Health.Guardrail_Result.No_Public_Bindable_Command;
      Manifest.Execution_Surface_Present :=
        Health.Guardrail_Result.No_Public_Executor_Route
        and then Health.Guardrail_Result.No_Public_Invocation_Path
        and then Health.Guardrail_Result.No_Public_Bindable_Command
        and then Health.Guardrail_Result.Default_Execution_Disabled;
      Manifest.Surface_Command_Executable :=
        Public_Build_Surface_Commands_Executable;
      Manifest.Promotion_Blocked := Health.Guardrail_Result.Promotion_Blocked;
      Manifest.Dependency_Blockers_Active :=
        Health.Guardrail_Result.Dependency_Blockers_Active;
      Manifest.Manifest_Healthy :=
        Health.Healthy
        and then Manifest.Default_Contract_Matches
        and then Manifest.Trace_Surface_Complete
        and then Manifest.Public_Command_Surface_Complete
        and then Manifest.Persistence_Exclusion_Clean
        and then Manifest.Lifecycle_Stable
        and then Manifest.Public_Surface_Present
        and then Manifest.Execution_Surface_Present
        and then Manifest.Surface_Command_Executable
        and then not Manifest.Promotion_Blocked
        and then not Manifest.Dependency_Blockers_Active;
      return Manifest;
   end Build_Public_Build_Guardrail_Regression_Manifest;

   function Build_Public_Build_Guardrail_Regression_Manifest_Feedback
     (Manifest : Public_Build_Guardrail_Regression_Manifest) return String
   is
   begin
      if Manifest.Manifest_Healthy then
         return "Build: public build regression manifest healthy";
      elsif not Manifest.Health.Healthy then
         return "Build: public build guardrail health failed";
      elsif not Manifest.Default_Contract_Matches then
         return "Build: public build default contract mismatch";
      elsif not Manifest.Trace_Surface_Complete then
         return "Build: public build audit trace incomplete";
      elsif not Manifest.Public_Command_Surface_Complete then
         return "Build: public build public-id domain coverage incomplete";
      elsif not Manifest.Persistence_Exclusion_Clean then
         return "Build: public build persistence exclusion failed";
      elsif not Manifest.Lifecycle_Stable then
         return "Build: public build lifecycle stability failed";
      elsif not Manifest.Public_Surface_Present then
         return "Build: public build public surface detected";
      elsif not Manifest.Execution_Surface_Present then
         return "Build: public build execution surface detected";
      elsif not Manifest.Surface_Command_Executable then
         return "Build: public build surface entry executable";
      elsif Manifest.Promotion_Blocked then
         return "Build: public build promotion blocker failed";
      elsif Manifest.Dependency_Blockers_Active then
         return "Build: public build dependency blocker failed";
      else
         return "Build: public build audit trace incomplete";
      end if;
   end Build_Public_Build_Guardrail_Regression_Manifest_Feedback;

   procedure Assert_Public_Build_Guardrail_Regression_Manifest_Default
     (Manifest : Public_Build_Guardrail_Regression_Manifest)
   is
   begin
      if not Manifest.Manifest_Healthy then
         raise Program_Error with
           Build_Public_Build_Guardrail_Regression_Manifest_Feedback
             (Manifest);
      end if;
      Assert_Public_Build_Guardrail_Health_Default (Manifest.Health);
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete
        (Build_Public_Build_Guardrail_Audit_Matrix);
      if not Public_Build_Surface_Commands_Executable then
         raise Program_Error with "public build surface commands not executable";
      end if;
   end Assert_Public_Build_Guardrail_Regression_Manifest_Default;

   function Public_Build_Guardrail_Audit_Matrix_Anchored
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean
   is
   begin
      return Public_Build_Guardrail_Audit_Matrix_Complete (Matrix)
        and then Public_Build_Guardrail_Audit_Matrix_Dimension'Pos
                   (Public_Build_Guardrail_Audit_Matrix_Dimension'Last) + 1 = 31
        and then Matrix (Public_Build_Matrix_Normalized_Guardrail_Contract)
        and then Matrix (Public_Build_Matrix_Regression_Manifest)
        and then Matrix (Public_Build_Matrix_Audit_Trace_Completeness)
        and then Matrix (Public_Build_Matrix_Surface_Id_Domain_Coverage)
        and then Matrix (Public_Build_Matrix_Persistence_Exclusion_Scan)
        and then Matrix (Public_Build_Matrix_Lifecycle_Stability_Check)
        and then Matrix (Public_Build_Matrix_Side_Effect_Free_Audit_Check);
   end Public_Build_Guardrail_Audit_Matrix_Anchored;

   procedure Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
     (Manifest : Public_Build_Guardrail_Regression_Manifest)
   is
      Result : constant Public_Build_Guardrail_Result :=
        Manifest.Health.Guardrail_Result;
      Contract_Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Result);
   begin
      if Manifest.Health.Healthy /=
        (Result.Status = Public_Build_Guardrail_Passed
         and then Manifest.Health.Surface_Id_Scan.Passed
         and then Public_Build_Surface_Id_Scan_Domains_Checked
                    (Manifest.Health.Surface_Id_Scan)
         and then Public_Build_Guardrail_Audit_Trace_Complete
                    (Manifest.Health.Audit_Trace)
         and then Manifest.Health.First_Failure.Kind = Public_Build_Failure_None
         and then Manifest.Health.Failure_Count = 0
         and then not Manifest.Health.Snapshot_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build guardrail health lacks direct backers";
      end if;

      if Manifest.Default_Contract_Matches /=
        (not Contract_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build manifest default contract lacks direct backer";
      end if;

      if Manifest.Trace_Surface_Complete /=
        (Public_Build_Guardrail_Audit_Matrix_Complete
           (Build_Public_Build_Guardrail_Audit_Matrix)
         and then Public_Build_Guardrail_Audit_Trace_Complete
                    (Manifest.Health.Audit_Trace)
         and then Result.Audits_Consistent)
      then
         raise Program_Error with "public build manifest trace surface lacks direct backer";
      end if;

      if Manifest.Public_Command_Surface_Complete /=
        (Manifest.Health.Surface_Id_Scan.Passed
         and then Public_Build_Surface_Id_Scan_Domains_Checked
                    (Manifest.Health.Surface_Id_Scan))
      then
         raise Program_Error with "public build manifest public domains lack direct backer";
      end if;

      if Manifest.Persistence_Exclusion_Clean /= Result.Persistence_Clean then
         raise Program_Error with "public build manifest persistence lacks direct backer";
      end if;

      if Manifest.Lifecycle_Stable /=
        (Manifest.Health.Failure_Count = 0
         and then Manifest.Health.First_Failure.Kind = Public_Build_Failure_None
         and then not Manifest.Health.Snapshot_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build manifest lifecycle lacks direct backer";
      end if;

      if Manifest.Public_Surface_Present /=
        (Result.No_Public_Command
         and then Result.No_Public_Keybinding
         and then Result.No_Public_Palette_Entry
         and then Result.No_Public_Bindable_Command)
      then
         raise Program_Error with "public build manifest public surface lacks direct backer";
      end if;

      if Manifest.Execution_Surface_Present /=
        (Result.No_Public_Executor_Route
         and then Result.No_Public_Invocation_Path
         and then Result.No_Public_Bindable_Command
         and then Result.Default_Execution_Disabled)
      then
         raise Program_Error with "public build manifest execution surface lacks direct backer";
      end if;

      if Manifest.Surface_Command_Executable /= Public_Build_Surface_Commands_Executable then
         raise Program_Error with "public build manifest surface entry state lacks direct backer";
      end if;

      if Manifest.Promotion_Blocked /= Result.Promotion_Blocked then
         raise Program_Error with "public build manifest promotion lacks direct backer";
      end if;

      if Manifest.Dependency_Blockers_Active /= Result.Dependency_Blockers_Active then
         raise Program_Error with "public build manifest dependency blockers lack direct backer";
      end if;

      if Manifest.Manifest_Healthy /=
        (Manifest.Health.Healthy
         and then Manifest.Default_Contract_Matches
         and then Manifest.Trace_Surface_Complete
         and then Manifest.Public_Command_Surface_Complete
         and then Manifest.Persistence_Exclusion_Clean
         and then Manifest.Lifecycle_Stable
         and then Manifest.Public_Surface_Present
         and then Manifest.Execution_Surface_Present
         and then Manifest.Surface_Command_Executable
         and then not Manifest.Promotion_Blocked
         and then not Manifest.Dependency_Blockers_Active)
      then
         raise Program_Error with "public build manifest health is not field-derived";
      end if;
   end Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers;

   procedure Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest
   is
   begin
      if Public_Build_Guardrail_Audit_Matrix_Dimension'Pos
           (Public_Build_Guardrail_Audit_Matrix_Dimension'Last) + 1 /= 31
      then
         raise Program_Error with "public build guardrail audit matrix dimension drift";
      end if;
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete
        (Build_Public_Build_Guardrail_Audit_Matrix);
   end Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;

   procedure Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State
     (State : Editor.State.State_Type)
   is
      Result   : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
      Health   : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
      Manifest : constant Public_Build_Guardrail_Regression_Manifest :=
        Build_Public_Build_Guardrail_Regression_Manifest (State);
   begin
      if Health.Guardrail_Result /= Result then
         raise Program_Error with "public build health does not reflect direct guardrail result";
      end if;
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
        (Manifest);
      if Manifest.Health /= Health then
         raise Program_Error with "public build manifest does not embed direct health";
      end if;
      if Result.Status /= Public_Build_Guardrail_Passed then
         raise Program_Error with "public build result status changed";
      end if;
   end Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only
   is
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
   begin
      if not Public_Build_Guardrail_Audit_Matrix_Complete (Matrix) then
         raise Program_Error with "public build guardrail audit matrix coverage incomplete";
      end if;
      if not Public_Build_Guardrail_Audit_Matrix_Anchored (Matrix) then
         raise Program_Error with "public build guardrail audit matrix lost coverage-only anchor";
      end if;
   end Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only;

   function Public_Build_Surface_Commands_Executable return Boolean
   is
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Command_Surface;
   begin
      for Surface_Entry of Surface_Entries loop
         if Editor.External_Producers.Public_Build_Command_Surface_Audits.Validate_Public_Build_Command_Surface_Entry
           (Surface_Entry) /=
           Public_Build_Command_Surface_Valid
         then
            return False;
         end if;
         if not Surface_Entry.Publicly_Invokable or else not Surface_Entry.Routes_Through_Executor then
            return False;
         end if;
      end loop;
      return True;
   end Public_Build_Surface_Commands_Executable;

   function Run_Public_Build_Guardrail_Audit
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Result
   is
      Hard_Freeze : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Surface_Audits.Run_Public_Build_Command_Hard_Freeze_Audit (State);
      Readiness : constant Public_Build_Command_Readiness_Audit_Result :=
        Editor.External_Producers.Public_Build_Input_Validation
          .Run_Public_Build_Command_Readiness_Audit (State);
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Surface_Audits.Build_Public_Build_UX_Dependency_Matrix;
      Matrix_Status : constant Public_Build_Command_Promotion_Status :=
        Surface_Audits.Validate_Public_Build_UX_Dependencies (Matrix);
      Drift : constant Public_Build_Hard_Freeze_Drift_Result :=
        Surface_Audits.Detect_Public_Build_Hard_Freeze_Drift
          (State, Surface_Audits.Build_Public_Build_Hard_Freeze_Baseline);
      Trace : constant Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
      Surface_Id_Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
      Result : Public_Build_Guardrail_Result;
      Exposure_Detected : Boolean;
   begin
      Result.No_Public_Command :=
        Hard_Freeze.No_Public_Command_Registered;
      Result.No_Public_Keybinding :=
        Hard_Freeze.No_Public_Default_Keybinding;
      Result.No_Public_Palette_Entry :=
        Hard_Freeze.No_Public_Command_Palette_Entry;
      Result.No_Public_Executor_Route :=
        Hard_Freeze.No_Public_Executor_Route;
      Result.No_Public_Invocation_Path :=
        Hard_Freeze.No_Public_Invocation_Path;
      Result.No_Public_Bindable_Command :=
        Hard_Freeze.No_Public_Bindable_Command;
      Result.Promotion_Blocked :=
        Hard_Freeze.Promotion_Blocked;
      Result.Default_Execution_Disabled := Hard_Freeze.No_Default_Execution;
      Result.Dependency_Blockers_Active :=
        Matrix_Status /= Public_Build_Promotion_Command_Surface_Ready
        and then (Readiness.Implicit_Source_Blocker_Active
                  or else Readiness.Public_Executor_Route_Blocker_Active
                  or else Readiness.Consent_UX_Blocker_Active
                  or else Readiness.Working_Context_UX_Blocker_Active);
      Result.Persistence_Clean := Hard_Freeze.No_Public_Persistence_State;

      Exposure_Detected :=
        Hard_Freeze.Public_Exposure_Hard_Failure
        or else not Hard_Freeze.Exposure_Barrier_Passed
        or else not Result.No_Public_Command
        or else not Result.No_Public_Keybinding
        or else not Result.No_Public_Palette_Entry
        or else not Result.No_Public_Executor_Route
        or else not Result.No_Public_Invocation_Path
        or else not Result.No_Public_Bindable_Command;

      Result.Audits_Consistent :=
        Hard_Freeze.Passed
        and then Readiness.Passed_As_Not_Ready
        and then not Result.Promotion_Blocked
        and then Result.Default_Execution_Disabled
        and then not Result.Dependency_Blockers_Active
        and then Result.Persistence_Clean
        and then Surface_Audits.Public_Build_Surface_Ids_Not_Publicly_Projected (State)
        and then Surface_Id_Scan.Passed
        and then Public_Build_Surface_Id_Scan_Domains_Checked (Surface_Id_Scan)
        and then Public_Build_Guardrail_Audit_Trace_Complete (Trace)
        and then not Hard_Freeze.Public_Exposure_Hard_Failure;

      if Exposure_Detected then
         Result.Status := Public_Build_Guardrail_Exposure_Detected;
      elsif Drift.Any_Drift then
         Result.Status := Public_Build_Guardrail_Drift_Detected;
      elsif not Result.Audits_Consistent then
         Result.Status := Public_Build_Guardrail_Inconsistent_Audits;
      elsif Result.Dependency_Blockers_Active then
         Result.Status := Public_Build_Guardrail_Not_Ready_But_Safe;
      else
         Result.Status := Public_Build_Guardrail_Passed;
      end if;

      return Result;
   end Run_Public_Build_Guardrail_Audit;

   function Detect_Public_Build_Guardrail_Contract_Mismatch
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch
   is
      Mismatch : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Mismatch.Status_Mismatch :=
        Result.Status /= Public_Build_Guardrail_Passed;
      Mismatch.Public_Command_Mismatch := not Result.No_Public_Command;
      Mismatch.Public_Keybinding_Mismatch := not Result.No_Public_Keybinding;
      Mismatch.Public_Palette_Mismatch := not Result.No_Public_Palette_Entry;
      Mismatch.Public_Route_Mismatch := not Result.No_Public_Executor_Route;
      Mismatch.Public_Invocation_Mismatch :=
        not Result.No_Public_Invocation_Path;
      Mismatch.Public_Bindability_Mismatch :=
        not Result.No_Public_Bindable_Command;
      Mismatch.Promotion_Mismatch := Result.Promotion_Blocked;
      Mismatch.Default_Execution_Mismatch :=
        not Result.Default_Execution_Disabled;
      Mismatch.Dependency_Blocker_Mismatch :=
        Result.Dependency_Blockers_Active;
      Mismatch.Persistence_Mismatch := not Result.Persistence_Clean;
      Mismatch.Audit_Consistency_Mismatch := not Result.Audits_Consistent;

      Mismatch.Any_Mismatch :=
        Mismatch.Status_Mismatch
        or else Mismatch.Public_Command_Mismatch
        or else Mismatch.Public_Keybinding_Mismatch
        or else Mismatch.Public_Palette_Mismatch
        or else Mismatch.Public_Route_Mismatch
        or else Mismatch.Public_Invocation_Mismatch
        or else Mismatch.Public_Bindability_Mismatch
        or else Mismatch.Promotion_Mismatch
        or else Mismatch.Default_Execution_Mismatch
        or else Mismatch.Dependency_Blocker_Mismatch
        or else Mismatch.Persistence_Mismatch
        or else Mismatch.Audit_Consistency_Mismatch;
      return Mismatch;
   end Detect_Public_Build_Guardrail_Contract_Mismatch;

   procedure Assert_Public_Build_Guardrail_Default_Contract
     (Result : Public_Build_Guardrail_Result)
   is
      Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Result);
   begin
      Assert_Public_Build_Guardrail_Trace_Complete
        (Build_Public_Build_Guardrail_Audit_Trace);
      if Mismatch.Any_Mismatch then
         raise Program_Error with "public build guardrail contract mismatch";
      end if;
   end Assert_Public_Build_Guardrail_Default_Contract;

   procedure Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
     (State  : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result)
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Surface_Audits.Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      if Result.No_Public_Command
        and then not Audit.No_Public_Command_Registered
      then
         raise Program_Error with "guardrail command result disagrees with scan";
      end if;

      if Result.No_Public_Executor_Route
        and then not Audit.No_Public_Executor_Route
      then
         raise Program_Error with "guardrail route result disagrees with scan";
      end if;

      if Result.No_Public_Invocation_Path
        and then not Audit.No_Public_Invocation_Path
      then
         raise Program_Error with "guardrail invocation result disagrees with scan";
      end if;

      if Result.No_Public_Keybinding
        and then not Audit.No_Public_Default_Keybinding
      then
         raise Program_Error with "guardrail keybinding result disagrees with scan";
      end if;

      if Result.No_Public_Palette_Entry
        and then not Audit.No_Public_Command_Palette_Entry
      then
         raise Program_Error with "guardrail palette result disagrees with scan";
      end if;

      if Result.No_Public_Bindable_Command
        and then not Audit.No_Public_Bindable_Command
      then
         raise Program_Error with "guardrail bindability result disagrees with scan";
      end if;

      Editor.External_Producers.Public_Build_Command_Surface_Audits
        .Assert_No_Public_Build_Execution_Path (State);
   end Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan;

   procedure Assert_Public_Build_Guardrail_State_Not_Persisted
     (State : Editor.State.State_Type)
   is
      Result : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
   begin
      if not Result.Persistence_Clean then
         raise Program_Error with "normalized public build guardrail state persisted";
      end if;

      Editor.External_Producers.Public_Build_Command_Surface_Audits
        .Assert_Public_Build_Hard_Freeze_Not_Persisted (State);
      Surface_Audits.Assert_Public_Build_Surface_Ids_Not_Reused;
   end Assert_Public_Build_Guardrail_State_Not_Persisted;

end Editor.External_Producers.Public_Build_Guardrail_Audits;
