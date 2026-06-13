with Editor.State;

package Editor.Build_Milestone_Freeze is

   --  Phase 508 public build command milestone freeze.  These helpers are
   --  regression assertions only.  They do not execute external tools, spawn
   --  processes, probe PATH, discover projects, mutate render state, or persist
   --  build state.

   type Public_Build_Command_Milestone_Freeze is record
      Manual_Request_Frozen : Boolean := False;
      Candidate_Request_Frozen : Boolean := False;
      Request_Identity_And_Consent_Frozen : Boolean := False;
      Working_Context_Frozen : Boolean := False;
      Build_Run_Route_Frozen : Boolean := False;
      Runner_Boundary_Frozen : Boolean := False;
      Diagnostics_Boundary_Frozen : Boolean := False;
      Frontdoor_Boundaries_Frozen : Boolean := False;
      Render_And_Audit_Boundaries_Frozen : Boolean := False;
      Persistence_Exclusion_Frozen : Boolean := False;
      Behavior_Preservation_Frozen : Boolean := False;
      One_Primary_Message_Frozen : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Assert_Public_Build_Manual_Request_Frozen return Boolean;
   function Assert_Public_Build_Candidate_Request_Frozen return Boolean;
   function Assert_Public_Build_Request_Identity_Frozen return Boolean;
   function Assert_Public_Build_Consent_Frozen return Boolean;
   function Assert_Public_Build_Runner_Boundary_Frozen return Boolean;
   function Assert_Public_Build_Diagnostics_Boundary_Frozen return Boolean;
   function Assert_Public_Build_Frontdoor_Boundaries_Frozen
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Public_Build_Persistence_Excluded_Frozen
     (State : Editor.State.State_Type) return Boolean;

   function Run_Public_Build_Command_Milestone_Freeze_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Milestone_Freeze;

   function Assert_Public_Build_Command_Milestone_Coherent
     (State : Editor.State.State_Type) return Boolean;

end Editor.Build_Milestone_Freeze;
