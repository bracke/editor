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

package body Test_Ada_Final_Semantic_Stabilization_Gate_Legality_Pass1208 is

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
   package Gate renames Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;
   use type Gate.Final_Blocker_Family;
   use type Gate.Final_Recheck_Convergence_Status;
   use type Gate.Final_Recheck_Convergence_Action;
   use type Gate.Final_Stabilization_Gate_Id;
   use type Gate.Final_Stabilization_Gate_Status;
   use type Gate.Final_Stabilization_Gate_Action;
   use type Gate.Final_Stabilization_Gate_Row;
   use type Gate.Final_Stabilization_Gate_Model;
   use type Gate.Final_Stabilization_Gate_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Stabilization_Gate_Legality_Pass1208");
   end Name;

   function Empty_Convergence return Conv.Final_Recheck_Convergence_Model is
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Eligibility : constant Recheck.Final_Recheck_Eligibility_Model :=
        Recheck.Build (Work);
      Application : constant Apply.Final_Recheck_Application_Model :=
        Apply.Build (Eligibility);
   begin
      return Conv.Build (Application);
   end Empty_Convergence;

   procedure Empty_Convergence_Produces_Empty_Stabilization_Gate
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Convergence : constant Conv.Final_Recheck_Convergence_Model := Empty_Convergence;
      Model : Gate.Final_Stabilization_Gate_Model := Gate.Build (Convergence);
   begin
      Assert (Gate.Row_Count (Model) = 0,
              "empty convergence rows should not create stabilization gate rows");
      Assert (Gate.Fingerprint (Model) = 0,
              "empty stabilization fingerprint should be stable zero");
      Gate.Clear (Model);
      Assert (Gate.Row_Count (Model) = 0,
              "clear preserves empty stabilization gate state");
   end Empty_Convergence_Produces_Empty_Stabilization_Gate;

   procedure Empty_Stabilization_Gate_Queries_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Convergence : constant Conv.Final_Recheck_Convergence_Model := Empty_Convergence;
      Model : constant Gate.Final_Stabilization_Gate_Model := Gate.Build (Convergence);
   begin
      Assert
        (Gate.Query_Count
           (Gate.Query_Status
              (Model,
               Gate.Final_Stabilization_Gate_Withheld_AST_Coverage)) = 0,
         "empty stabilization gate model should have no AST withheld rows");
      Assert
        (Gate.Count_Action
           (Model,
            Gate.Final_Stabilization_Gate_Action_Recheck) = 0,
         "empty stabilization gate model should have no recheck actions");
      Assert
        (Gate.Count_Blocker
           (Model,
            Final_Prov.Final_Blocker_Representation_Freezing) = 0,
         "empty stabilization gate model should have no representation blockers");
      Assert (Gate.Promoted_Count (Model) = 0, "no promoted rows expected");
      Assert (Gate.Withheld_Count (Model) = 0, "no withheld rows expected");
      Assert (Gate.Recheck_Required_Count (Model) = 0, "no recheck rows expected");
      Assert (Gate.Preserved_Error_Count (Model) = 0, "no preserved errors expected");
      Assert (Gate.Indeterminate_Count (Model) = 0, "no indeterminate rows expected");
      Assert (Gate.Stale_Count (Model) = 0, "no stale rows expected");
      Assert (Gate.AST_Count (Model) = 0, "no AST rows expected");
      Assert (Gate.Cross_Unit_Count (Model) = 0, "no cross-unit rows expected");
      Assert (Gate.Generic_Count (Model) = 0, "no generic rows expected");
      Assert (Gate.Overload_Count (Model) = 0, "no overload rows expected");
      Assert (Gate.Representation_Count (Model) = 0, "no representation rows expected");
      Assert (Gate.Flow_Count (Model) = 0, "no flow rows expected");
      Assert (Gate.Tasking_Count (Model) = 0, "no tasking rows expected");
      Assert (Gate.Elaboration_Count (Model) = 0, "no elaboration rows expected");
      Assert (Gate.Accessibility_Count (Model) = 0, "no accessibility rows expected");
      Assert (Gate.Discriminant_Count (Model) = 0, "no discriminant rows expected");
   end Empty_Stabilization_Gate_Queries_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Empty_Convergence_Produces_Empty_Stabilization_Gate'Access,
         "empty final convergence produces empty stabilization gate model");
      Register_Routine
        (T,
         Empty_Stabilization_Gate_Queries_Are_Deterministic'Access,
         "empty final stabilization gate queries and counters remain deterministic");
   end Register_Tests;

end Test_Ada_Final_Semantic_Stabilization_Gate_Legality_Pass1208;
