with Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_Candidate_Discovery;
with Editor.Build_UI;
with Editor.Build_Working_Context;

package Editor.Build_Candidate_Refresh is

   --  Phase 522 public build candidate refresh foundation.  Refresh is a
   --  transient UI/readiness operation over the canonical project context and
   --  the existing Phase 506 bounded discovery seam.  It does not execute,
   --  select, consent, persist, watch, recurse beyond the project root, or
   --  mutate Diagnostics/result/output state.

   subtype Build_Candidate_Refresh_Status is
     Editor.Build_UI.Build_Candidate_Refresh_Status;

   Build_Candidate_Refresh_Not_Requested : constant Build_Candidate_Refresh_Status :=
     Editor.Build_UI.Build_Candidate_Refresh_Not_Requested;
   Build_Candidate_Refresh_Succeeded : constant Build_Candidate_Refresh_Status :=
     Editor.Build_UI.Build_Candidate_Refresh_Succeeded;
   Build_Candidate_Refresh_No_Project_Context : constant Build_Candidate_Refresh_Status :=
     Editor.Build_UI.Build_Candidate_Refresh_No_Project_Context;
   Build_Candidate_Refresh_No_Candidates : constant Build_Candidate_Refresh_Status :=
     Editor.Build_UI.Build_Candidate_Refresh_No_Candidates;
   Build_Candidate_Refresh_Failed : constant Build_Candidate_Refresh_Status :=
     Editor.Build_UI.Build_Candidate_Refresh_Failed;

   type Build_Candidate_Refresh_Result is record
      Status : Build_Candidate_Refresh_Status :=
        Editor.Build_UI.Build_Candidate_Refresh_Not_Requested;
      Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Count : Natural := 0;
      Selected_Candidate_Preserved : Boolean := False;
      Selected_Candidate_Cleared : Boolean := False;
      Consent_Invalidated : Boolean := False;
      Manual_Request_Preserved : Boolean := False;
      Discovery : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result;
   end record;

   function Build_Candidate_Identity
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return String;

   function Build_Candidate_Material_Identity
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return String;

   function Candidate_Identity_Matches
     (Left  : Editor.Build_Candidates.Build_Candidate_Record;
      Right : Editor.Build_Candidates.Build_Candidate_Record) return Boolean;

   function Candidate_Material_Matches
     (Left  : Editor.Build_Candidates.Build_Candidate_Record;
      Right : Editor.Build_Candidates.Build_Candidate_Record) return Boolean;

   procedure Reconcile_Selected_Build_Candidate_After_Refresh
     (State         : in out Editor.Build_UI.Public_Build_UI_State;
      Old_State     : Editor.Build_UI.Public_Build_UI_State;
      New_Candidates : Editor.Build_Candidates.Build_Candidate_Vector;
      Result        : in out Build_Candidate_Refresh_Result);

   procedure Invalidate_Consent_On_Candidate_Refresh_Change
     (State  : in out Editor.Build_UI.Public_Build_UI_State;
      Result : in out Build_Candidate_Refresh_Result);

   function Refresh_Build_Candidates
     (State   : in out Editor.Build_UI.Public_Build_UI_State;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record)
      return Build_Candidate_Refresh_Result;


   --  Phase 528 project-lifecycle integration helpers.  These are thin
   --  lifecycle adapters around the canonical refresh/reconciliation path.
   --  Failed transitions are status-only and do not discover or fabricate
   --  candidates.  Project close clears executable candidate-derived state
   --  without touching Diagnostics/latest result/output details.

   function Refresh_Build_Candidates_After_Project_Open
     (State              : in out Editor.Build_UI.Public_Build_UI_State;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean := True)
      return Build_Candidate_Refresh_Result;

   function Refresh_Build_Candidates_After_Project_Switch
     (State              : in out Editor.Build_UI.Public_Build_UI_State;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean := True)
      return Build_Candidate_Refresh_Result;

   function Refresh_Build_Candidates_After_Project_Reset
     (State              : in out Editor.Build_UI.Public_Build_UI_State;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean := True)
      return Build_Candidate_Refresh_Result;

   function Clear_Build_Candidates_After_Project_Close
     (State : in out Editor.Build_UI.Public_Build_UI_State)
      return Build_Candidate_Refresh_Result;

   function Assert_Project_Lifecycle_Refresh_Uses_Canonical_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Project_Close_Clears_Build_Candidates
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Failed_Project_Transition_Does_Not_Fabricate_Candidates
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Project_Lifecycle_Does_Not_Auto_Select_Consent_Or_Run
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Project_Lifecycle_Candidate_State_Not_Persisted
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Bounded
     (Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Does_Not_Execute
     (Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Refresh_Request_Identity_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Deterministic
     (Left  : Build_Candidate_Refresh_Result;
      Right : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Persistence_Excluded
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Refresh_Canonical_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Identity_Canonical
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_Stale_Reconciliation_Canonical
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Refresh_Not_Diagnostics_Result_Output_Mutation
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   --  Phase 525 final regression-freeze assertions.  These keep the
   --  frozen candidate-refresh contract named directly at the boundary while
   --  delegating to the canonical Phase 522-524 helpers.

   function Assert_Build_Candidate_Refresh_Final_Canonical_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Explicit_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Lifecycle_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Bounded_Discovery
     (Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Identity_Final_Canonical
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_Material_Identity_Final_Canonical
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_Stale_Reconciliation_Final_Canonical
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_No_Auto_Select
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_No_Auto_Consent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_No_Auto_Run
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Not_Build_Run_Side_Effect
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Not_Render_Owned
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Not_Frontdoor_Payload
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Not_Diagnostics_Result_Output_Mutation
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean;

   function Assert_Build_Candidate_Refresh_Final_Persistence_Excluded
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

end Editor.Build_Candidate_Refresh;
