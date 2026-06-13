with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration_Pass1273 is

   package P renames Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
   use type P.Predicate_RM_Closure_Consumer_Id;
   use type P.Predicate_RM_Kind;
   use type P.Predicate_RM_Closure_Consumer_Status;
   use type P.Predicate_RM_Closure_Consumer_Family;
   use type P.Predicate_RM_Closure_Consumer_Context;
   use type P.Predicate_RM_Closure_Consumer_Row;
   use type P.Predicate_RM_Closure_Consumer_Context_Model;
   use type P.Predicate_RM_Closure_Consumer_Model;
   use type P.Predicate_RM_Closure_Consumer_Set;
   package D renames Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
   use type D.RM_Closure_Consumer_Diagnostic_Id;
   use type D.RM_Closure_Consumer_Diagnostic_Family;
   use type D.RM_Closure_Consumer_Diagnostic_Severity;
   use type D.RM_Closure_Consumer_Diagnostic_Status;
   use type D.RM_Closure_Consumer_Diagnostic_Row;
   use type D.RM_Closure_Consumer_Diagnostic_Set;
   use type D.RM_Closure_Consumer_Diagnostic_Model;
   package Prior renames P.Prior;
   package Closure renames P.Closure;
   package Cross_Unit renames P.Cross_Unit;
   package Elaboration renames P.Elaboration;
   package Accessibility renames P.Accessibility;
   package Exception_Finalization renames P.Exception_Finalization;
   package Overload renames P.Overload;
   package Representation renames P.Representation;
   package Tasking renames P.Tasking;
   package Dataflow renames P.Dataflow;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada RM-completion closure consumer diagnostic integration pass1273");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : P.Predicate_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return P.Predicate_RM_Closure_Consumer_Context is
      Result : P.Predicate_RM_Closure_Consumer_Context;
   begin
      Result.Id := P.Predicate_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Predicate_RM_Row := Prior.Predicate_RM_Completion_Row_Id (Id);
      Result.Predicate_RM_Status := Prior.Predicate_RM_Completion_Legal_Assignment_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Current;
      Result.Cross_Unit_Consumer_Row := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Id (Id);
      Result.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Accepted;
      Result.Elaboration_Consumer_Row := Elaboration.Elaboration_RM_Closure_Consumer_Id (Id);
      Result.Elaboration_Consumer_Status := Elaboration.Elaboration_RM_Closure_Consumer_Accepted;
      Result.Accessibility_Consumer_Row := Accessibility.Accessibility_RM_Closure_Consumer_Id (Id);
      Result.Accessibility_Consumer_Status := Accessibility.Accessibility_RM_Closure_Consumer_Accepted;
      Result.Exception_Finalization_Consumer_Row := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Id (Id);
      Result.Exception_Finalization_Consumer_Status := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Accepted;
      Result.Overload_Consumer_Row := Overload.Overload_RM_Closure_Consumer_Id (Id);
      Result.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Accepted;
      Result.Representation_Consumer_Row := Representation.Representation_RM_Closure_Consumer_Id (Id);
      Result.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Accepted;
      Result.Tasking_Consumer_Row := Tasking.Tasking_RM_Closure_Consumer_Id (Id);
      Result.Tasking_Consumer_Status := Tasking.Tasking_RM_Closure_Consumer_Accepted;
      Result.Dataflow_Consumer_Row := Dataflow.Dataflow_RM_Closure_Consumer_Id (Id);
      Result.Dataflow_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Accepted;
      Result.Source_Fingerprint := 1273 * Id;
      Result.Expected_Source_Fingerprint := 1273 * Id;
      Result.Substitution_Fingerprint := 731 * Id;
      Result.Expected_Substitution_Fingerprint := 731 * Id;
      return Result;
   end Complete_Context;

   function Build_Predicate_Model return P.Predicate_RM_Closure_Consumer_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (127301));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127302));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (127303));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (127304));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (127305));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127306));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127307));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127308));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (127309));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (127310));
   begin
      Cross_Blocker.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Private_View_Barrier;
      Elaboration_Blocker.Elaboration_Consumer_Status := Elaboration.Elaboration_RM_Closure_Consumer_Closure_Elaboration;
      Accessibility_Blocker.Accessibility_Consumer_Status := Accessibility.Accessibility_RM_Closure_Consumer_Closure_Accessibility;
      Exception_Blocker.Exception_Finalization_Consumer_Status := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Closure_Exception_Finalization;
      Overload_Blocker.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Closure_Overload_Type;
      Representation_Blocker.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Closure_Representation;
      Tasking_Blocker.Tasking_Consumer_Status := Tasking.Tasking_RM_Closure_Consumer_Closure_Tasking_Protected;
      Dataflow_Blocker.Dataflow_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Closure_Dataflow;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      P.Add_Context (Contexts, Accepted);
      P.Add_Context (Contexts, Cross_Blocker);
      P.Add_Context (Contexts, Elaboration_Blocker);
      P.Add_Context (Contexts, Accessibility_Blocker);
      P.Add_Context (Contexts, Exception_Blocker);
      P.Add_Context (Contexts, Overload_Blocker);
      P.Add_Context (Contexts, Representation_Blocker);
      P.Add_Context (Contexts, Tasking_Blocker);
      P.Add_Context (Contexts, Dataflow_Blocker);
      P.Add_Context (Contexts, Fingerprint_Blocker);
      return P.Build (Contexts);
   end Build_Predicate_Model;

   procedure Accepted_Rows_Are_Withheld_As_Current_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Diagnostic_Model :=
        D.Build (Build_Predicate_Model);
   begin
      Assert (D.Row_Count (Diagnostics) = 10,
              "ten direct RM-closure consumer diagnostic rows expected");
      Assert (D.Withheld_Current_Count (Diagnostics) = 1,
              "accepted direct consumer row should be withheld as current evidence");
      Assert (D.Emitted_Count (Diagnostics) = 9,
              "only blocking direct-consumer rows should be emitted");
      Assert
        (D.Count_Status (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Withheld_Accepted_Current) = 1,
         "accepted current status should be preserved");
   end Accepted_Rows_Are_Withheld_As_Current_Evidence;

   procedure Blocker_Families_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Diagnostic_Model :=
        D.Build (Build_Predicate_Model);
   begin
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Cross_Unit) = 1,
              "cross-unit direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Elaboration) = 1,
              "elaboration direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Accessibility) = 1,
              "accessibility direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Exception_Finalization) = 1,
              "exception/finalization direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Overload_Type) = 1,
              "overload/type direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Representation) = 1,
              "representation/freezing direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Tasking_Protected) = 1,
              "tasking/protected direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Dataflow) = 1,
              "dataflow direct-consumer blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Diagnostic_Source_Fingerprint) = 1,
              "source fingerprint blocker should be preserved");
      Assert (D.Error_Count (Diagnostics) = 8,
              "eight semantic prerequisite blockers should be errors");
      Assert (D.Warning_Count (Diagnostics) = 1,
              "fingerprint blocker should remain a warning");
   end Blocker_Families_Are_Preserved;

   procedure Query_Surface_Preserves_Node_And_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Diagnostic_Model := D.Build (Build_Predicate_Model);
      Row : constant D.RM_Closure_Consumer_Diagnostic_Row := D.Row_At (Diagnostics, 10);
   begin
      Assert (D.Query_Count (D.Query_Node (Diagnostics, Row.Node)) = 1,
              "node query should find direct RM-closure consumer diagnostic row");
      Assert (D.Query_Count (D.Query_Source_Fingerprint (Diagnostics, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should find direct RM-closure consumer diagnostic row");
      Assert (D.Fingerprint (Diagnostics) /= 0,
              "direct RM-closure consumer diagnostic fingerprint should be deterministic");
   end Query_Surface_Preserves_Node_And_Fingerprint;

   procedure Feed_Integration_Emits_Only_Blockers_And_Rejects_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Diagnostics : constant D.RM_Closure_Consumer_Diagnostic_Model := D.Build (Build_Predicate_Model);
      Current_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_RM_Completion_Closure_Consumer_Diagnostics
          (Guarded, Diagnostics, True, 0);
      Stale_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_RM_Completion_Closure_Consumer_Diagnostics
          (Guarded, Diagnostics, False, 13);
   begin
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Current (Current_Feed),
              "current feed should remain current");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Current_Feed) = D.Emitted_Count (Diagnostics),
              "feed should emit exactly direct RM-closure consumer blockers");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Current_Feed) = 8,
              "eight direct RM-closure consumer blockers should enter feed as errors");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Warning_Count (Current_Feed) = 1,
              "fingerprint direct-consumer blocker should enter feed as warning");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Stale_Feed),
              "stale direct-consumer diagnostics should reject the feed");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Stale_Feed) = 13,
              "stale rejection count should be preserved");
   end Feed_Integration_Emits_Only_Blockers_And_Rejects_Stale;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Rows_Are_Withheld_As_Current_Evidence'Access,
         "accepted rows are withheld as current evidence");
      Register_Routine
        (T, Blocker_Families_Are_Preserved'Access,
         "direct RM-closure consumer blocker families are preserved");
      Register_Routine
        (T, Query_Surface_Preserves_Node_And_Fingerprint'Access,
         "query surface preserves node and fingerprint");
      Register_Routine
        (T, Feed_Integration_Emits_Only_Blockers_And_Rejects_Stale'Access,
         "feed integration emits blockers and rejects stale input");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration_Pass1273;
