with Editor.Build_Diagnostics_Review;
with Editor.State;

package Editor.Build_Diagnostics_Review_Audit is

   --  Phase 518 side-effect-free audit helper for the build diagnostics
   --  review/navigation foundation. It observes state and delegates to review
   --  predicates only; it does not run builds, parse output, navigate targets,
   --  mutate Diagnostics, or write persistence/audit caches.

   type Build_Diagnostics_Review_Audit_Result is record
      Review : Editor.Build_Diagnostics_Review.Build_Diagnostics_Review_Result;
      Source_Labels_Practical : Boolean := False;
      Command_Frontdoors_Carry_No_Payload : Boolean := False;
      Navigation_Workflow_Coherent : Boolean := False;
      Audit_Side_Effect_Free : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Run_Build_Diagnostics_Review_Audit
     (State : Editor.State.State_Type)
      return Build_Diagnostics_Review_Audit_Result;

end Editor.Build_Diagnostics_Review_Audit;
