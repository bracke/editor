with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_Final_Diagnostic_Integration_Pass1239 is

   package D renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
   use type D.Dataflow_Generic_Final_Row_Id;
   use type D.Dataflow_Generic_Final_Kind;
   use type D.Dataflow_Generic_Final_Blocker_Family;
   use type D.Dataflow_Generic_Final_Status;
   use type D.Dataflow_Generic_Final_Context;
   use type D.Dataflow_Generic_Final_Row;
   use type D.Dataflow_Generic_Final_Context_Model;
   use type D.Dataflow_Generic_Final_Model;
   use type D.Dataflow_Generic_Final_Set;
   package I renames Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
   use type I.Generic_Shared_State_Final_Diagnostic_Id;
   use type I.Generic_Shared_State_Final_Diagnostic_Family;
   use type I.Generic_Shared_State_Final_Diagnostic_Severity;
   use type I.Generic_Shared_State_Final_Diagnostic_Status;
   use type I.Generic_Shared_State_Final_Diagnostic_Row;
   use type I.Generic_Shared_State_Final_Diagnostic_Set;
   use type I.Generic_Shared_State_Final_Diagnostic_Model;
   package Init renames D.Init;
   package Dataflow_Init renames D.Dataflow_Init;
   package Predicate_Dataflow renames D.Predicate_Dataflow;
   package Predicate_Generic renames D.Predicate_Generic;
   package Generic_Replay renames D.Generic_Replay;
   package Closure renames D.Closure;
   package Rep_Generic renames D.Rep_Generic;
   package Tasking_Generic renames D.Tasking_Generic;
   package Access_Generic renames D.Access_Generic;
   package Disc_Generic renames D.Disc_Generic;
   package Exception_Generic renames D.Exception_Generic;
   package Renaming_Generic renames D.Renaming_Generic;
   package Volatile_Rep renames D.Volatile_Rep;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state final diagnostic integration pass1239");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : D.Dataflow_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return D.Dataflow_Generic_Final_Context is
      Result : D.Dataflow_Generic_Final_Context;
   begin
      Result.Id := D.Dataflow_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Component_Name := To_Unbounded_String ("Component" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Initialization_Row := Init.Initialization_Legality_Id (Id);
      Result.Initialization_Status := Init.Initialization_Legality_Definitely_Initialized;
      Result.Dataflow_Init_Row := Dataflow_Init.Dataflow_Init_Row_Id (Id);
      Result.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Legal_Read_Write_Accepted;
      Result.Predicate_Dataflow_Row := Predicate_Dataflow.Predicate_Dataflow_Row_Id (Id);
      Result.Predicate_Dataflow_Status := Predicate_Dataflow.Predicate_Dataflow_Legal_Flow_Effect_Accepted;
      Result.Predicate_Generic_Row := Predicate_Generic.Predicate_Generic_Final_Row_Id (Id);
      Result.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Legal_Dispatching_Call_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Variant_Record_Layout_Accepted;
      Result.Tasking_Generic_Row := Tasking_Generic.Tasking_Generic_Final_Row_Id (Id);
      Result.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Legal_Generic_Protected_Body_Accepted;
      Result.Accessibility_Generic_Row := Access_Generic.Accessibility_Generic_Final_Row_Id (Id);
      Result.Accessibility_Generic_Status := Access_Generic.Accessibility_Generic_Final_Legal_Controlled_Finalization_Accepted;
      Result.Discriminant_Generic_Row := Disc_Generic.Discriminant_Generic_Final_Row_Id (Id);
      Result.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Final_Legal_Variant_Record_Layout_Accepted;
      Result.Exception_Generic_Row := Exception_Generic.Exception_Generic_Final_Row_Id (Id);
      Result.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Legal_Controlled_Finalize_Accepted;
      Result.Renaming_Generic_Row := Renaming_Generic.Renaming_Generic_Final_Row_Id (Id);
      Result.Renaming_Generic_Status := Renaming_Generic.Renaming_Generic_Final_Legal_Selected_Alias_Accepted;
      Result.Volatile_Representation_Row := Volatile_Rep.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Legal_Record_Layout_Accepted;
      Result.Source_Fingerprint := 1239 * Id;
      Result.Expected_Source_Fingerprint := 1239 * Id;
      Result.Substitution_Fingerprint := 9321 * Id;
      Result.Expected_Substitution_Fingerprint := 9321 * Id;
      return Result;
   end Complete_Context;

   function Build_Dataflow_Model return D.Dataflow_Generic_Final_Model is
      Contexts : D.Dataflow_Generic_Final_Context_Model;
      Accepted : D.Dataflow_Generic_Final_Context :=
        Complete_Context (1, D.Dataflow_Generic_Final_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (123901));
      Generic_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (2, D.Dataflow_Generic_Final_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (123902));
      Representation_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (3, D.Dataflow_Generic_Final_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (123903));
      Local_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (4, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (123904));
   begin
      Accepted.Requires_Generic_Replay := True;
      Accepted.Requires_Stabilized_Closure := True;

      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Source_Fingerprint_Mismatch;

      Representation_Blocker.Requires_Representation_Generic := True;
      Representation_Blocker.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Private_View_Freezing_Blocker;

      Local_Blocker.Read_Before_Write_Blocker := True;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Generic_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Local_Blocker);
      return D.Build (Contexts);
   end Build_Dataflow_Model;

   procedure Accepted_Rows_Are_Withheld_As_Current_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant I.Generic_Shared_State_Final_Diagnostic_Model :=
        I.Build (Build_Dataflow_Model);
   begin
      Assert (I.Row_Count (Diagnostics) = 4, "four diagnostic-boundary rows expected");
      Assert (I.Withheld_Current_Count (Diagnostics) = 1,
              "accepted generic/shared-state row should be withheld as current evidence");
      Assert (I.Emitted_Count (Diagnostics) = 3,
              "only blocking rows should be emitted as diagnostics");
      Assert
        (I.Count_Status (Diagnostics, I.Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current) = 1,
         "accepted current status should be preserved");
   end Accepted_Rows_Are_Withheld_As_Current_Evidence;

   procedure Blocker_Families_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant I.Generic_Shared_State_Final_Diagnostic_Model :=
        I.Build (Build_Dataflow_Model);
   begin
      Assert
        (I.Count_Family (Diagnostics, I.Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay) = 1,
         "generic abstract replay blocker family should be preserved");
      Assert
        (I.Count_Family (Diagnostics, I.Generic_Shared_State_Final_Diagnostic_Representation_Generic_Shared_State) = 1,
         "representation generic shared-state blocker family should be preserved");
      Assert
        (I.Count_Family (Diagnostics, I.Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM) = 1,
         "local dataflow RM blocker family should be preserved");
      Assert (I.Error_Count (Diagnostics) = 3, "three blocking rows should be errors");
   end Blocker_Families_Are_Preserved;

   procedure Query_Surface_Preserves_Node_And_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Dataflow : constant D.Dataflow_Generic_Final_Model := Build_Dataflow_Model;
      Diagnostics : constant I.Generic_Shared_State_Final_Diagnostic_Model := I.Build (Dataflow);
      Row : constant I.Generic_Shared_State_Final_Diagnostic_Row := I.Row_At (Diagnostics, 2);
   begin
      Assert (I.Query_Count (I.Query_Node (Diagnostics, Row.Node)) = 1,
              "node query should find diagnostic row");
      Assert (I.Query_Count (I.Query_Source_Fingerprint (Diagnostics, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should find diagnostic row");
      Assert (I.Fingerprint (Diagnostics) /= 0,
              "diagnostic integration fingerprint should be deterministic");
   end Query_Surface_Preserves_Node_And_Fingerprint;

   procedure Feed_Integration_Emits_Only_Blockers_And_Rejects_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Diagnostics : constant I.Generic_Shared_State_Final_Diagnostic_Model :=
        I.Build (Build_Dataflow_Model);
      Current_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Generic_Shared_State_Final_Diagnostics
          (Guarded, Diagnostics, True, 0);
      Stale_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Generic_Shared_State_Final_Diagnostics
          (Guarded, Diagnostics, False, 7);
   begin
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Current (Current_Feed),
              "current feed should remain current");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Current_Feed) = I.Emitted_Count (Diagnostics),
              "feed should emit exactly the diagnostic blockers");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Current_Feed) = 3,
              "three generic/shared-state blockers should enter the feed as errors");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Stale_Feed),
              "stale generic/shared-state diagnostics should reject the feed");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Stale_Feed) = 7,
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

end Test_Ada_Generic_Shared_State_Final_Diagnostic_Integration_Pass1239;
