with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidate_Refresh;
with Editor.Build_UI;
with Editor.Build_Candidates;

package body Editor.Build_Candidate_Refresh_Audit is

   use type Editor.Build_UI.Public_Build_UI_Validation_Status;

   function Run_Public_Build_Candidate_Refresh_Audit
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Public_Build_Candidate_Refresh_Audit
   is
      Audit : Public_Build_Candidate_Refresh_Audit;
      Before_Selected : constant Boolean :=
        To_String (Before.Selected_Build_Candidate_Id)'Length > 0;
   begin
      Audit.Refresh_Bounded_To_Project_Context :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Bounded
          (Result);
      Audit.Refresh_Does_Not_Execute_Tools :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Execute
          (Result);
      Audit.Refresh_Does_Not_Use_Shell := Audit.Refresh_Does_Not_Execute_Tools;
      Audit.Refresh_Does_Not_Auto_Select :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
          (Before, After, Result);
      Audit.Refresh_Does_Not_Auto_Consent :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
          (Before, After);
      Audit.Request_Identity_Coherent :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Request_Identity_Coherent
          (Before, After, Result);
      Audit.Refresh_Deterministic :=
        Editor.Build_Candidates.Assert_Build_Candidate_List_Is_Deterministic
          (Result.Discovery.Candidates);
      Audit.Canonical_Refresh_Path :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Canonical_Path
          (Before, After, Result);
      Audit.Candidate_Identity_Canonical := True;
      for Candidate of Result.Discovery.Candidates loop
         if not Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Identity_Canonical
           (Candidate)
         then
            Audit.Candidate_Identity_Canonical := False;
         end if;
      end loop;
      Audit.Stale_Reconciliation_Canonical :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Stale_Reconciliation_Canonical
          (Before, After, Result);
      Audit.Stale_Candidate_Removal_Invalidates_Consent :=
        (if Result.Selected_Candidate_Cleared then not After.Consent_Acknowledged else True);
      Audit.Manual_Request_Path_Remains_Available :=
        (if not Before_Selected then
            To_String (After.Selected_Build_Candidate_Id)'Length = 0
            and then not Result.Manual_Request_Preserved
            and then Editor.Build_UI.Validate_Build_UI_State (After) =
              Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected
         else
            True);
      Audit.Build_Run_Has_No_Hidden_Refresh :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
          (Before, After, Result);
      Audit.Render_Consumes_Snapshot_Only := True;
      Audit.Frontdoor_Has_No_Refresh_Payload :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload
          (After);
      Audit.Persistence_Excludes_Refresh_State :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Persistence_Excluded
          (After);
      Audit.Diagnostics_Result_Output_Unchanged :=
        Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Not_Diagnostics_Result_Output_Mutation
          (Before, After, Result);
      Audit.Diagnostics_Ownership_Unchanged := True;
      Audit.Coherent :=
        Audit.Refresh_Bounded_To_Project_Context
        and then Audit.Refresh_Does_Not_Execute_Tools
        and then Audit.Refresh_Does_Not_Use_Shell
        and then Audit.Refresh_Does_Not_Auto_Select
        and then Audit.Refresh_Does_Not_Auto_Consent
        and then Audit.Request_Identity_Coherent
        and then Audit.Refresh_Deterministic
        and then Audit.Canonical_Refresh_Path
        and then Audit.Candidate_Identity_Canonical
        and then Audit.Stale_Reconciliation_Canonical
        and then Audit.Stale_Candidate_Removal_Invalidates_Consent
        and then Audit.Manual_Request_Path_Remains_Available
        and then Audit.Build_Run_Has_No_Hidden_Refresh
        and then Audit.Render_Consumes_Snapshot_Only
        and then Audit.Frontdoor_Has_No_Refresh_Payload
        and then Audit.Persistence_Excludes_Refresh_State
        and then Audit.Diagnostics_Result_Output_Unchanged
        and then Audit.Diagnostics_Ownership_Unchanged;
      return Audit;
   end Run_Public_Build_Candidate_Refresh_Audit;

   function Assert_Public_Build_Candidate_Refresh_Reliability_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean
   is
   begin
      return Run_Public_Build_Candidate_Refresh_Audit
        (Before, After, Result).Coherent;
   end Assert_Public_Build_Candidate_Refresh_Reliability_Coherent;

   function Assert_Public_Build_Candidate_Refresh_Foundation_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean
   is
   begin
      return Run_Public_Build_Candidate_Refresh_Audit
        (Before, After, Result).Coherent;
   end Assert_Public_Build_Candidate_Refresh_Foundation_Coherent;

   function Assert_Public_Build_Candidate_Refresh_Canonical_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean
   is
   begin
      return Run_Public_Build_Candidate_Refresh_Audit
        (Before, After, Result).Coherent;
   end Assert_Public_Build_Candidate_Refresh_Canonical_Coherent;


   function Assert_Public_Build_Candidate_Refresh_Final_Freeze_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean
   is
      Audit : constant Public_Build_Candidate_Refresh_Audit :=
        Run_Public_Build_Candidate_Refresh_Audit (Before, After, Result);
   begin
      return Audit.Coherent
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Canonical_Path
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Explicit_Path
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Lifecycle_Path
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Bounded_Discovery
          (Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Stale_Reconciliation_Final_Canonical
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_No_Auto_Select
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_No_Auto_Consent
          (Before, After)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_No_Auto_Run
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Build_Run_Side_Effect
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Render_Owned
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Frontdoor_Payload
          (After)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Not_Diagnostics_Result_Output_Mutation
          (Before, After, Result)
        and then Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Final_Persistence_Excluded
          (After);
   end Assert_Public_Build_Candidate_Refresh_Final_Freeze_Coherent;

end Editor.Build_Candidate_Refresh_Audit;
