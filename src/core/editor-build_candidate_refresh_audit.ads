with Editor.Build_Candidate_Refresh;
with Editor.Build_UI;

package Editor.Build_Candidate_Refresh_Audit is

   type Public_Build_Candidate_Refresh_Audit is record
      Refresh_Bounded_To_Project_Context : Boolean := False;
      Refresh_Does_Not_Execute_Tools : Boolean := False;
      Refresh_Does_Not_Use_Shell : Boolean := False;
      Refresh_Does_Not_Auto_Select : Boolean := False;
      Refresh_Does_Not_Auto_Consent : Boolean := False;
      Request_Identity_Coherent : Boolean := False;
      Refresh_Deterministic : Boolean := False;
      Canonical_Refresh_Path : Boolean := False;
      Candidate_Identity_Canonical : Boolean := False;
      Stale_Reconciliation_Canonical : Boolean := False;
      Stale_Candidate_Removal_Invalidates_Consent : Boolean := False;
      Manual_Request_Path_Remains_Available : Boolean := False;
      Build_Run_Has_No_Hidden_Refresh : Boolean := False;
      Render_Consumes_Snapshot_Only : Boolean := False;
      Frontdoor_Has_No_Refresh_Payload : Boolean := False;
      Persistence_Excludes_Refresh_State : Boolean := False;
      Diagnostics_Result_Output_Unchanged : Boolean := False;
      Diagnostics_Ownership_Unchanged : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Run_Public_Build_Candidate_Refresh_Audit
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Public_Build_Candidate_Refresh_Audit;

   function Assert_Public_Build_Candidate_Refresh_Reliability_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean;

   function Assert_Public_Build_Candidate_Refresh_Foundation_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean;

   function Assert_Public_Build_Candidate_Refresh_Canonical_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean;

   function Assert_Public_Build_Candidate_Refresh_Final_Freeze_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result)
      return Boolean;

end Editor.Build_Candidate_Refresh_Audit;
