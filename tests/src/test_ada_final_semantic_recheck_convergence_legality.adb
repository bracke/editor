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

package body Test_Ada_Final_Semantic_Recheck_Convergence_Legality is

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

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Recheck_Convergence_Legality");
   end Name;

   function Empty_Application return Apply.Final_Recheck_Application_Model is
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Eligibility : constant Recheck.Final_Recheck_Eligibility_Model :=
        Recheck.Build (Work);
   begin
      return Apply.Build (Eligibility);
   end Empty_Application;

   procedure Empty_Application_Produces_Empty_Convergence_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Application : constant Apply.Final_Recheck_Application_Model := Empty_Application;
      Model : Conv.Final_Recheck_Convergence_Model := Conv.Build (Application);
   begin
      Assert (Conv.Row_Count (Model) = 0,
              "empty application rows should not create convergence rows");
      Assert (Conv.Fingerprint (Model) = 0,
              "empty convergence fingerprint should be stable zero");
      Conv.Clear (Model);
      Assert (Conv.Row_Count (Model) = 0,
              "clear preserves empty convergence state");
   end Empty_Application_Produces_Empty_Convergence_Model;

   procedure Empty_Convergence_Queries_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Application : constant Apply.Final_Recheck_Application_Model := Empty_Application;
      Model : constant Conv.Final_Recheck_Convergence_Model := Conv.Build (Application);
   begin
      Assert
        (Conv.Query_Count
           (Conv.Query_Status
              (Model,
               Conv.Final_Recheck_Stable_Withheld_AST_Coverage)) = 0,
         "empty convergence model should have no AST stable rows");
      Assert
        (Conv.Count_Action
           (Model,
            Conv.Final_Recheck_Convergence_Action_Recheck_Again) = 0,
         "empty convergence model should have no changed recheck actions");
      Assert
        (Conv.Count_Blocker
           (Model,
            Final_Prov.Final_Blocker_Representation_Freezing) = 0,
         "empty convergence model should have no representation blockers");
      Assert (Conv.Converged_Count (Model) = 0, "no converged rows expected");
      Assert (Conv.Stable_Withheld_Count (Model) = 0, "no stable withheld rows expected");
      Assert (Conv.Changed_Count (Model) = 0, "no changed rows expected");
      Assert (Conv.Stale_Stable_Count (Model) = 0, "no stale stable rows expected");
      Assert (Conv.AST_Stable_Count (Model) = 0, "no AST stable rows expected");
      Assert (Conv.Cross_Unit_Stable_Count (Model) = 0, "no cross-unit stable rows expected");
      Assert (Conv.Generic_Stable_Count (Model) = 0, "no generic stable rows expected");
      Assert (Conv.Overload_Stable_Count (Model) = 0, "no overload stable rows expected");
      Assert (Conv.Representation_Stable_Count (Model) = 0, "no representation stable rows expected");
      Assert (Conv.Flow_Stable_Count (Model) = 0, "no flow stable rows expected");
      Assert (Conv.Tasking_Stable_Count (Model) = 0, "no tasking stable rows expected");
      Assert (Conv.Elaboration_Stable_Count (Model) = 0, "no elaboration stable rows expected");
      Assert (Conv.Accessibility_Stable_Count (Model) = 0, "no accessibility stable rows expected");
      Assert (Conv.Discriminant_Stable_Count (Model) = 0, "no discriminant stable rows expected");
      Assert (Conv.Preserved_Error_Count (Model) = 0, "no preserved errors expected");
      Assert (Conv.Multiple_Prerequisite_Count (Model) = 0, "no multiple prerequisites expected");
      Assert (Conv.Indeterminate_Count (Model) = 0, "no indeterminate rows expected");
   end Empty_Convergence_Queries_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Empty_Application_Produces_Empty_Convergence_Model'Access,
         "empty final recheck application produces empty convergence model");
      Register_Routine
        (T,
         Empty_Convergence_Queries_Are_Deterministic'Access,
         "empty final recheck convergence queries and counters remain deterministic");
   end Register_Tests;

end Test_Ada_Final_Semantic_Recheck_Convergence_Legality;
