with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration is

   package D renames Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
   use type D.Dataflow_RM_Completion_Row_Id;
   use type D.Dataflow_RM_Completion_Kind;
   use type D.Dataflow_RM_Completion_Blocker_Family;
   use type D.Dataflow_RM_Completion_Status;
   use type D.Dataflow_RM_Completion_Context;
   use type D.Dataflow_RM_Completion_Row;
   use type D.Dataflow_RM_Completion_Context_Model;
   use type D.Dataflow_RM_Completion_Model;
   use type D.Query_Result;
   package I renames Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
   use type I.RM_Completion_Diagnostic_Id;
   use type I.RM_Completion_Diagnostic_Family;
   use type I.RM_Completion_Diagnostic_Severity;
   use type I.RM_Completion_Diagnostic_Status;
   use type I.RM_Completion_Diagnostic_Row;
   use type I.RM_Completion_Diagnostic_Set;
   use type I.RM_Completion_Diagnostic_Model;
   package Prior renames D.Prior_Dataflow;
   package Cross_RM renames D.Cross_RM;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state RM completion diagnostic integration");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : D.Dataflow_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return D.Dataflow_RM_Completion_Context is
      Result : D.Dataflow_RM_Completion_Context;
   begin
      Result.Id := D.Dataflow_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Prior_Dataflow_Row := Prior.Dataflow_Generic_Final_Row_Id (Id);
      Result.Prior_Dataflow_Status := Prior.Dataflow_Generic_Final_Legal_Variant_Component_Accepted;
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Source_Fingerprint := 1256 * Id;
      Result.Expected_Source_Fingerprint := 1256 * Id;
      Result.Substitution_Fingerprint := 6521 * Id;
      Result.Expected_Substitution_Fingerprint := 6521 * Id;
      return Result;
   end Complete_Context;

   function Build_Dataflow_Model return D.Dataflow_RM_Completion_Model is
      Contexts : D.Dataflow_RM_Completion_Context_Model;
      Accepted : D.Dataflow_RM_Completion_Context :=
        Complete_Context (1, D.Dataflow_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (125601));
      Cross_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (2, D.Dataflow_RM_Completion_Read_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (125602));
      Representation_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (3, D.Dataflow_RM_Completion_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125603));
      Local_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (4, D.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (125604));
   begin
      Cross_Blocker.Cross_RM_Row := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Representation_Blocker.Requires_Representation_RM := True;
      Local_Blocker.Read_Before_Write_Blocker := True;
      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Cross_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Local_Blocker);
      return D.Build (Contexts);
   end Build_Dataflow_Model;

   procedure Accepted_Rows_Are_Withheld_As_Current_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant I.RM_Completion_Diagnostic_Model :=
        I.Build (Build_Dataflow_Model);
   begin
      Assert (I.Row_Count (Diagnostics) = 4, "four RM-completion diagnostic-boundary rows expected");
      Assert (I.Withheld_Current_Count (Diagnostics) = 1,
              "accepted RM-completed row should be withheld as current evidence");
      Assert (I.Emitted_Count (Diagnostics) = 3,
              "only blocking RM-completion rows should be emitted");
      Assert
        (I.Count_Status (Diagnostics, I.RM_Completion_Diagnostic_Withheld_Accepted_Current) = 1,
         "accepted current status should be preserved");
   end Accepted_Rows_Are_Withheld_As_Current_Evidence;

   procedure Blocker_Families_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant I.RM_Completion_Diagnostic_Model :=
        I.Build (Build_Dataflow_Model);
   begin
      Assert
        (I.Count_Family (Diagnostics, I.RM_Completion_Diagnostic_Cross_Unit_RM_Completion) = 1,
         "cross-unit RM-completion blocker family should be preserved");
      Assert
        (I.Count_Family (Diagnostics, I.RM_Completion_Diagnostic_Representation_RM_Completion) = 1,
         "representation/freezing RM-completion blocker family should be preserved");
      Assert
        (I.Count_Family (Diagnostics, I.RM_Completion_Diagnostic_Dataflow_Read_Before_Write) = 1,
         "local dataflow blocker family should be preserved");
      Assert (I.Error_Count (Diagnostics) = 3,
              "three blocking RM-completion rows should be errors");
   end Blocker_Families_Are_Preserved;

   procedure Query_Surface_Preserves_Node_And_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant I.RM_Completion_Diagnostic_Model := I.Build (Build_Dataflow_Model);
      Row : constant I.RM_Completion_Diagnostic_Row := I.Row_At (Diagnostics, 2);
   begin
      Assert (I.Query_Count (I.Query_Node (Diagnostics, Row.Node)) = 1,
              "node query should find RM-completion diagnostic row");
      Assert (I.Query_Count (I.Query_Source_Fingerprint (Diagnostics, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should find RM-completion diagnostic row");
      Assert (I.Fingerprint (Diagnostics) /= 0,
              "RM-completion diagnostic fingerprint should be deterministic");
   end Query_Surface_Preserves_Node_And_Fingerprint;

   procedure Feed_Integration_Emits_Only_Blockers_And_Rejects_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Diagnostics : constant I.RM_Completion_Diagnostic_Model := I.Build (Build_Dataflow_Model);
      Current_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Generic_Shared_State_RM_Completion_Diagnostics
          (Guarded, Diagnostics, True, 0);
      Stale_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Generic_Shared_State_RM_Completion_Diagnostics
          (Guarded, Diagnostics, False, 11);
   begin
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Current (Current_Feed),
              "current feed should remain current");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Current_Feed) = I.Emitted_Count (Diagnostics),
              "feed should emit exactly the RM-completion diagnostic blockers");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Current_Feed) = 3,
              "three RM-completion blockers should enter the feed as errors");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Stale_Feed),
              "stale RM-completion diagnostics should reject the feed");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Stale_Feed) = 11,
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
         "blocker families are preserved");
      Register_Routine
        (T, Query_Surface_Preserves_Node_And_Fingerprint'Access,
         "query surface preserves node and fingerprint");
      Register_Routine
        (T, Feed_Integration_Emits_Only_Blockers_And_Rejects_Stale'Access,
         "feed integration emits blockers and rejects stale input");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
