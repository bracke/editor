with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
with Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
with Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_Final_Recheck_Application_Legality is

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
   package Diag renames Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Id;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Family;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Severity;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Status;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Row;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Set;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Model;
   package W renames Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
   use type W.Generic_Shared_State_Final_Worklist_Id;
   use type W.Generic_Shared_State_Final_Worklist_Family;
   use type W.Generic_Shared_State_Final_Worklist_Diagnostic_Status;
   use type W.Generic_Shared_State_Final_Worklist_Action;
   use type W.Generic_Shared_State_Final_Worklist_Priority;
   use type W.Generic_Shared_State_Final_Worklist_Item;
   use type W.Generic_Shared_State_Final_Worklist_Model;
   use type W.Generic_Shared_State_Final_Worklist_Set;
   package R renames Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
   use type R.Generic_Shared_State_Final_Recheck_Family;
   use type R.Generic_Shared_State_Final_Recheck_Work_Action;
   use type R.Generic_Shared_State_Final_Recheck_Work_Priority;
   use type R.Generic_Shared_State_Final_Recheck_Id;
   use type R.Generic_Shared_State_Final_Recheck_Status;
   use type R.Generic_Shared_State_Final_Recheck_Action;
   use type R.Generic_Shared_State_Final_Recheck_Row;
   use type R.Generic_Shared_State_Final_Recheck_Model;
   use type R.Generic_Shared_State_Final_Recheck_Set;
   package A renames Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality;
   use type A.Generic_Shared_State_Final_Application_Family;
   use type A.Generic_Shared_State_Final_Eligibility_Status;
   use type A.Generic_Shared_State_Final_Eligibility_Action;
   use type A.Generic_Shared_State_Final_Application_Id;
   use type A.Generic_Shared_State_Final_Application_Status;
   use type A.Generic_Shared_State_Final_Application_Action;
   use type A.Generic_Shared_State_Final_Application_Row;
   use type A.Generic_Shared_State_Final_Application_Model;
   use type A.Generic_Shared_State_Final_Application_Set;
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
      return AUnit.Format ("Ada generic shared-state final recheck application legality");
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
      Result.Source_Fingerprint := 1242 * Id;
      Result.Expected_Source_Fingerprint := 1242 * Id;
      Result.Substitution_Fingerprint := 4212 * Id;
      Result.Expected_Substitution_Fingerprint := 4212 * Id;
      return Result;
   end Complete_Context;

   function Build_Worklist return W.Generic_Shared_State_Final_Worklist_Model is
      Contexts : D.Dataflow_Generic_Final_Context_Model;
      Accepted : D.Dataflow_Generic_Final_Context :=
        Complete_Context (1, D.Dataflow_Generic_Final_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124101));
      Generic_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (2, D.Dataflow_Generic_Final_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (124102));
      Shared_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (3, D.Dataflow_Generic_Final_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124103));
      Representation_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (4, D.Dataflow_Generic_Final_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (124104));
      Predicate_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (5, D.Dataflow_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (124105));
      Fingerprint_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (6, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (124106));
      Local_Dataflow_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (7, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (124107));
   begin
      Accepted.Requires_Generic_Replay := True;
      Accepted.Requires_Stabilized_Closure := True;

      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Source_Fingerprint_Mismatch;

      Shared_Blocker.Requires_Stabilized_Closure := True;
      Shared_Blocker.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Blocker_Abstract_State;

      Representation_Blocker.Requires_Representation_Generic := True;
      Representation_Blocker.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Private_View_Freezing_Blocker;

      Predicate_Blocker.Requires_Predicate_Generic := True;
      Predicate_Blocker.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Source_Fingerprint_Mismatch;

      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      Local_Dataflow_Blocker.Read_Before_Write_Blocker := True;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Generic_Blocker);
      D.Add_Context (Contexts, Shared_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Predicate_Blocker);
      D.Add_Context (Contexts, Fingerprint_Blocker);
      D.Add_Context (Contexts, Local_Dataflow_Blocker);
      return W.Build (Diag.Build (D.Build (Contexts)));
   end Build_Worklist;



   function Build_Application return A.Generic_Shared_State_Final_Application_Model is
      Work : constant W.Generic_Shared_State_Final_Worklist_Model := Build_Worklist;
      Elig : constant R.Generic_Shared_State_Final_Recheck_Model := R.Build (Work);
   begin
      return A.Build (Elig);
   end Build_Application;

   procedure Eligibility_Is_Applied_To_Current_And_Withheld_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.Generic_Shared_State_Final_Application_Model := Build_Application;
      Row   : constant A.Generic_Shared_State_Final_Application_Row := A.Row_At (Model, 1);
   begin
      Assert (A.Count (Model) = 7, "seven generic/shared-state application rows expected");
      Assert (A.Current_Count (Model) = 1, "accepted current evidence should remain current");
      Assert (A.Accepted_Count (Model) = 0, "not-required current evidence is not a fresh accepted recheck");
      Assert (A.Withheld_Count (Model) = 6, "blocked prerequisites should be withheld at application");
      Assert
        (Row.Status = A.Generic_Shared_State_Final_Application_Current_Non_Diagnostic_Evidence,
         "current generic/shared-state evidence should stay non-diagnostic current evidence");
      Assert
        (Row.Action = A.Generic_Shared_State_Final_Application_Action_Keep_Non_Diagnostic_Evidence,
         "current evidence should be kept without a diagnostic re-emission");
   end Eligibility_Is_Applied_To_Current_And_Withheld_Rows;

   procedure Application_Preserves_Prerequisite_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.Generic_Shared_State_Final_Application_Model := Build_Application;
   begin
      Assert
        (A.Count_By_Status (Model, A.Generic_Shared_State_Final_Application_Withheld_Generic_Replay) = 1,
         "generic replay blocker should withhold application distinctly");
      Assert
        (A.Count_By_Status (Model, A.Generic_Shared_State_Final_Application_Withheld_Abstract_Or_Shared_State) = 1,
         "stabilized shared-state blocker should withhold application distinctly");
      Assert
        (A.Count_By_Status (Model, A.Generic_Shared_State_Final_Application_Withheld_Representation) = 1,
         "representation/freezing blocker should withhold application distinctly");
      Assert
        (A.Count_By_Status (Model, A.Generic_Shared_State_Final_Application_Withheld_Predicate_Invariant) = 1,
         "predicate/invariant blocker should withhold application distinctly");
      Assert
        (A.Count_By_Status (Model, A.Generic_Shared_State_Final_Application_Withheld_Stale_Or_Fingerprint) = 1,
         "source/substitution fingerprint blocker should withhold application distinctly");
      Assert
        (A.Count_By_Status (Model, A.Generic_Shared_State_Final_Application_Withheld_Dataflow) = 1,
         "dataflow blocker should withhold application distinctly");
   end Application_Preserves_Prerequisite_Blocker_Families;

   procedure Application_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.Generic_Shared_State_Final_Application_Model := Build_Application;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (124106);
   begin
      Assert
        (A.Query_Count (A.Find_By_Node (Model, Node)) = 1,
         "node lookup should find the fingerprint blocker row");
      Assert
        (A.Query_Count (A.Find_By_Source_Fingerprint (Model, 1242 * 6)) = 1,
         "source fingerprint lookup should find the fingerprint blocker row");
      Assert
        (A.Query_Count (A.Find_By_Substitution_Fingerprint (Model, 4212 * 6)) = 1,
         "substitution fingerprint lookup should find the fingerprint blocker row");
      Assert
        (A.Count_By_Family
           (Model,
            Diag.Generic_Shared_State_Final_Diagnostic_Fingerprint) = 1,
         "blocker-family query should preserve fingerprint family identity");
      Assert (A.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate application rows");
      Assert (A.Stable_Fingerprint (Model) /= 0, "application stable fingerprint should be non-zero");
   end Application_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Eligibility_Is_Applied_To_Current_And_Withheld_Rows'Access,
         "generic/shared-state eligibility is applied to current and withheld rows");
      Register_Routine
        (T, Application_Preserves_Prerequisite_Blocker_Families'Access,
         "generic/shared-state application preserves prerequisite blocker families");
      Register_Routine
        (T, Application_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "generic/shared-state application lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_Final_Recheck_Application_Legality;
