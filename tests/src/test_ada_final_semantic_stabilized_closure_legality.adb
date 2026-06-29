with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
with Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
with Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
with Editor.Ada_Final_Semantic_Recheck_Application_Legality;
with Editor.Ada_Final_Semantic_Recheck_Convergence_Legality;
with Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;

package body Test_Ada_Final_Semantic_Stabilized_Closure_Legality is

   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;
   use type Final_Prov.Final_Provenance_Id;
   use type Final_Prov.Final_Provenance_Status;
   use type Final_Prov.Final_Provenance_Stage;
   use type Final_Prov.Final_Blocker_Family;
   use type Final_Prov.Final_Provenance_Info;
   use type Final_Prov.Final_Provenance_Model;
   use type Final_Prov.Final_Provenance_Set;
   package Remed_Diag renames Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
   use type Remed_Diag.Final_Blocker_Family;
   use type Remed_Diag.Final_Remediation_Closure_Id;
   use type Remed_Diag.Final_Remediation_Closure_Status;
   use type Remed_Diag.Final_Remediation_Diagnostic_Id;
   use type Remed_Diag.Final_Remediation_Diagnostic_Family;
   use type Remed_Diag.Final_Remediation_Diagnostic_Severity;
   use type Remed_Diag.Final_Remediation_Diagnostic_Status;
   use type Remed_Diag.Final_Remediation_Diagnostic_Row;
   use type Remed_Diag.Final_Remediation_Diagnostic_Set;
   use type Remed_Diag.Final_Remediation_Diagnostic_Model;
   package Remed_Prov renames Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
   use type Remed_Prov.Final_Blocker_Family;
   use type Remed_Prov.Final_Remediation_Diagnostic_Status;
   use type Remed_Prov.Final_Remediation_Diagnostic_Family;
   use type Remed_Prov.Final_Remediation_Closure_Status;
   use type Remed_Prov.Final_Gate_Status;
   use type Remed_Prov.Final_Gate_Action;
   use type Remed_Prov.Final_Trace_Root;
   use type Remed_Prov.Final_Remediation_Provenance_Id;
   use type Remed_Prov.Final_Remediation_Provenance_Status;
   use type Remed_Prov.Final_Remediation_Provenance_Stage;
   use type Remed_Prov.Final_Remediation_Provenance_Info;
   use type Remed_Prov.Final_Remediation_Provenance_Model;
   use type Remed_Prov.Final_Remediation_Provenance_Set;
   package Worklist renames Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
   use type Worklist.Final_Blocker_Family;
   use type Worklist.Final_Remediation_Provenance_Status;
   use type Worklist.Final_Remediation_Provenance_Stage;
   use type Worklist.Final_Remediation_Work_Id;
   use type Worklist.Final_Remediation_Work_Status;
   use type Worklist.Final_Remediation_Work_Action;
   use type Worklist.Final_Remediation_Work_Phase;
   use type Worklist.Final_Remediation_Work_Row;
   use type Worklist.Final_Remediation_Worklist_Model;
   use type Worklist.Final_Remediation_Worklist_Set;
   package Recheck renames Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
   use type Recheck.Final_Blocker_Family;
   use type Recheck.Final_Remediation_Work_Status;
   use type Recheck.Final_Remediation_Work_Action;
   use type Recheck.Final_Remediation_Work_Phase;
   use type Recheck.Final_Recheck_Eligibility_Id;
   use type Recheck.Final_Recheck_Eligibility_Status;
   use type Recheck.Final_Recheck_Action;
   use type Recheck.Final_Recheck_Eligibility_Row;
   use type Recheck.Final_Recheck_Eligibility_Model;
   use type Recheck.Final_Recheck_Eligibility_Set;
   package Apply renames Editor.Ada_Final_Semantic_Recheck_Application_Legality;
   use type Apply.Final_Blocker_Family;
   use type Apply.Final_Recheck_Eligibility_Status;
   use type Apply.Final_Recheck_Action;
   use type Apply.Final_Recheck_Application_Id;
   use type Apply.Final_Recheck_Application_Status;
   use type Apply.Final_Recheck_Application_Action;
   use type Apply.Final_Recheck_Application_Row;
   use type Apply.Final_Recheck_Application_Model;
   use type Apply.Final_Recheck_Application_Set;
   package Conv renames Editor.Ada_Final_Semantic_Recheck_Convergence_Legality;
   use type Conv.Final_Blocker_Family;
   use type Conv.Final_Recheck_Application_Status;
   use type Conv.Final_Recheck_Application_Action;
   use type Conv.Final_Recheck_Convergence_Id;
   use type Conv.Final_Recheck_Convergence_Status;
   use type Conv.Final_Recheck_Convergence_Action;
   use type Conv.Final_Recheck_Convergence_Row;
   use type Conv.Final_Recheck_Convergence_Model;
   use type Conv.Final_Recheck_Convergence_Set;
   package Stabilization renames Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;
   use type Stabilization.Final_Blocker_Family;
   use type Stabilization.Final_Recheck_Convergence_Status;
   use type Stabilization.Final_Recheck_Convergence_Action;
   use type Stabilization.Final_Stabilization_Gate_Id;
   use type Stabilization.Final_Stabilization_Gate_Status;
   use type Stabilization.Final_Stabilization_Gate_Action;
   use type Stabilization.Final_Stabilization_Gate_Row;
   use type Stabilization.Final_Stabilization_Gate_Model;
   use type Stabilization.Final_Stabilization_Gate_Set;
   package Closure renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   use type Closure.Final_Blocker_Family;
   use type Closure.Final_Stabilization_Gate_Status;
   use type Closure.Final_Stabilization_Gate_Action;
   use type Closure.Final_Stabilized_Closure_Id;
   use type Closure.Final_Stabilized_Closure_Status;
   use type Closure.Final_Stabilized_Closure_Action;
   use type Closure.Final_Stabilized_Closure_Row;
   use type Closure.Final_Stabilized_Closure_Model;
   use type Closure.Final_Stabilized_Closure_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Stabilized_Closure_Legality");
   end Name;

   function Empty_Stabilization return Stabilization.Final_Stabilization_Gate_Model is
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Eligibility : constant Recheck.Final_Recheck_Eligibility_Model :=
        Recheck.Build (Work);
      Application : constant Apply.Final_Recheck_Application_Model :=
        Apply.Build (Eligibility);
      Convergence : constant Conv.Final_Recheck_Convergence_Model :=
        Conv.Build (Application);
   begin
      return Stabilization.Build (Convergence);
   end Empty_Stabilization;

   procedure Empty_Stabilization_Produces_Empty_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Gate_Model : constant Stabilization.Final_Stabilization_Gate_Model := Empty_Stabilization;
      Model : Closure.Final_Stabilized_Closure_Model := Closure.Build (Gate_Model);
   begin
      Assert (Closure.Row_Count (Model) = 0,
              "empty stabilization rows should not create stabilized closure rows");
      Assert (Closure.Fingerprint (Model) = 0,
              "empty stabilized closure fingerprint should be stable zero");
      Closure.Clear (Model);
      Assert (Closure.Row_Count (Model) = 0,
              "clear preserves empty stabilized closure state");
   end Empty_Stabilization_Produces_Empty_Closure;

   procedure Empty_Stabilized_Closure_Queries_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Gate_Model : constant Stabilization.Final_Stabilization_Gate_Model := Empty_Stabilization;
      Model : constant Closure.Final_Stabilized_Closure_Model := Closure.Build (Gate_Model);
   begin
      Assert
        (Closure.Query_Count
           (Closure.Query_Status
              (Model,
               Closure.Final_Stabilized_Closure_Blocker_AST_Coverage)) = 0,
         "empty stabilized closure model should have no AST blockers");
      Assert
        (Closure.Count_Action
           (Model,
            Closure.Final_Stabilized_Closure_Action_Recheck) = 0,
         "empty stabilized closure model should have no recheck actions");
      Assert
        (Closure.Count_Blocker
           (Model,
            Final_Prov.Final_Blocker_Representation_Freezing) = 0,
         "empty stabilized closure model should have no representation blockers");
      Assert (Closure.Accepted_Count (Model) = 0, "no accepted rows expected");
      Assert (Closure.Blocked_Count (Model) = 0, "no blocked rows expected");
      Assert (Closure.Recheck_Required_Count (Model) = 0, "no recheck rows expected");
      Assert (Closure.Preserved_Error_Count (Model) = 0, "no preserved errors expected");
      Assert (Closure.Indeterminate_Count (Model) = 0, "no indeterminate rows expected");
      Assert (Closure.Stale_Count (Model) = 0, "no stale rows expected");
      Assert (Closure.AST_Count (Model) = 0, "no AST rows expected");
      Assert (Closure.Cross_Unit_Count (Model) = 0, "no cross-unit rows expected");
      Assert (Closure.Generic_Count (Model) = 0, "no generic rows expected");
      Assert (Closure.Overload_Count (Model) = 0, "no overload rows expected");
      Assert (Closure.Representation_Count (Model) = 0, "no representation rows expected");
      Assert (Closure.Flow_Count (Model) = 0, "no flow rows expected");
      Assert (Closure.Tasking_Count (Model) = 0, "no tasking rows expected");
      Assert (Closure.Elaboration_Count (Model) = 0, "no elaboration rows expected");
      Assert (Closure.Accessibility_Count (Model) = 0, "no accessibility rows expected");
      Assert (Closure.Discriminant_Count (Model) = 0, "no discriminant rows expected");
   end Empty_Stabilized_Closure_Queries_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Empty_Stabilization_Produces_Empty_Closure'Access,
         "empty final stabilization produces empty stabilized closure model");
      Register_Routine
        (T,
         Empty_Stabilized_Closure_Queries_Are_Deterministic'Access,
         "empty final stabilized closure queries and counters remain deterministic");
   end Register_Tests;

end Test_Ada_Final_Semantic_Stabilized_Closure_Legality;
