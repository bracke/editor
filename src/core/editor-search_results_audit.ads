with Editor.State;

package Editor.Search_Results_Audit is

   type Search_Results_Contract_Review is record
      Active_Buffer_Only            : Boolean := False;
      Search_Command_Owned          : Boolean := False;
      Matching_Deterministic        : Boolean := False;
      Query_Input_Non_Mutating      : Boolean := False;
      Results_Transient             : Boolean := False;
      Projection_Side_Effect_Free   : Boolean := False;
      Selection_Stable              : Boolean := False;
      Targets_Validated             : Boolean := False;
      Query_History_Bounded         : Boolean := False;
      Lifecycle_Reset_Stable        : Boolean := False;
      Persistence_Clean             : Boolean := False;
      Feature_Panel_Intact          : Boolean := False;
      Command_Surface_Intact        : Boolean := False;
      Public_Build_Guardrail_Intact : Boolean := False;
      Review_Passed                 : Boolean := False;
   end record;

   --  Compact Phase 205 review of the active-buffer Search Results contract.
   --  The helper observes editor state and exercises only local copies for
   --  matching, query input, projection, selection, target validation, and
   --  lifecycle checks. It does not run a live search command, edit query text
   --  in live state, mutate buffer content, change selection, switch Feature
   --  Panel features, post messages, call Executor, parse project files, call
   --  process runners, inspect filesystem metadata, or persist audit results.
   function Review_Search_Results_Contract
     (State : Editor.State.State_Type) return Search_Results_Contract_Review;

   --  Deterministic audit/test feedback. The returned text contains no argv,
   --  shell syntax, environment, PATH lookup detail, filesystem paths, run ids,
   --  projection generations, or serialized result dumps.
   function Build_Search_Results_Contract_Review_Feedback
     (Review : Search_Results_Contract_Review) return String;

end Editor.Search_Results_Audit;
