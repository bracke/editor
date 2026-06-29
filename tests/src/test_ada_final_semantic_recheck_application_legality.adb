with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
with Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
with Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
with Editor.Ada_Final_Semantic_Recheck_Application_Legality;

package body Test_Ada_Final_Semantic_Recheck_Application_Legality is

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

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Recheck_Application_Legality");
   end Name;

   procedure Empty_Recheck_Model_Produces_Empty_Application_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Eligibility : constant Recheck.Final_Recheck_Eligibility_Model :=
        Recheck.Build (Work);
      Model : Apply.Final_Recheck_Application_Model := Apply.Build (Eligibility);
   begin
      Assert (Apply.Row_Count (Model) = 0,
              "empty recheck eligibility should not create application rows");
      Assert (Apply.Fingerprint (Model) = 0,
              "empty recheck application fingerprint should be stable zero");
      Apply.Clear (Model);
      Assert (Apply.Row_Count (Model) = 0,
              "clear preserves empty recheck application state");
   end Empty_Recheck_Model_Produces_Empty_Application_Model;

   procedure Empty_Application_Queries_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Eligibility : constant Recheck.Final_Recheck_Eligibility_Model :=
        Recheck.Build (Work);
      Model : constant Apply.Final_Recheck_Application_Model := Apply.Build (Eligibility);
   begin
      Assert
        (Apply.Query_Count
           (Apply.Query_Status
              (Model,
               Apply.Final_Recheck_Application_Withheld_AST_Coverage)) = 0,
         "empty recheck application model should have no AST-withheld rows");
      Assert
        (Apply.Count_Action
           (Model,
            Apply.Final_Recheck_Application_Action_Withhold_For_Cross_Unit) = 0,
         "empty recheck application model should have no cross-unit wait actions");
      Assert
        (Apply.Count_Blocker
           (Model,
            Final_Prov.Final_Blocker_Representation_Freezing) = 0,
         "empty recheck application model should have no representation blockers");
      Assert (Apply.Current_Count (Model) = 0, "no current rows expected");
      Assert (Apply.Withheld_Count (Model) = 0, "no withheld rows expected");
      Assert (Apply.Stale_Withheld_Count (Model) = 0, "no stale withheld rows expected");
      Assert (Apply.AST_Withheld_Count (Model) = 0, "no AST withheld rows expected");
      Assert (Apply.Cross_Unit_Withheld_Count (Model) = 0, "no cross-unit withheld rows expected");
      Assert (Apply.Generic_Withheld_Count (Model) = 0, "no generic withheld rows expected");
      Assert (Apply.Overload_Withheld_Count (Model) = 0, "no overload withheld rows expected");
      Assert (Apply.Representation_Withheld_Count (Model) = 0, "no representation withheld rows expected");
      Assert (Apply.Flow_Withheld_Count (Model) = 0, "no flow withheld rows expected");
      Assert (Apply.Tasking_Withheld_Count (Model) = 0, "no tasking withheld rows expected");
      Assert (Apply.Elaboration_Withheld_Count (Model) = 0, "no elaboration withheld rows expected");
      Assert (Apply.Accessibility_Withheld_Count (Model) = 0, "no accessibility withheld rows expected");
      Assert (Apply.Discriminant_Withheld_Count (Model) = 0, "no discriminant withheld rows expected");
      Assert (Apply.Preserved_Error_Count (Model) = 0, "no preserved errors expected");
      Assert (Apply.Multiple_Prerequisite_Count (Model) = 0, "no multiple prerequisites expected");
      Assert (Apply.Indeterminate_Count (Model) = 0, "no indeterminate rows expected");
   end Empty_Application_Queries_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Empty_Recheck_Model_Produces_Empty_Application_Model'Access,
         "empty final recheck eligibility produces empty application model");
      Register_Routine
        (T,
         Empty_Application_Queries_Are_Deterministic'Access,
         "empty final recheck application queries and counters remain deterministic");
   end Register_Tests;

end Test_Ada_Final_Semantic_Recheck_Application_Legality;
