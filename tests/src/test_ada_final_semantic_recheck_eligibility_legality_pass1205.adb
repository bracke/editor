with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
with Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
with Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;

package body Test_Ada_Final_Semantic_Recheck_Eligibility_Legality_Pass1205 is

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

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Recheck_Eligibility_Legality_Pass1205");
   end Name;

   procedure Empty_Worklist_Produces_Empty_Recheck_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Model : Recheck.Final_Recheck_Eligibility_Model := Recheck.Build (Work);
   begin
      Assert (Recheck.Row_Count (Model) = 0,
              "empty remediation worklist should not create recheck eligibility rows");
      Assert (Recheck.Fingerprint (Model) = 0,
              "empty recheck eligibility fingerprint should be stable zero");
      Recheck.Clear (Model);
      Assert (Recheck.Row_Count (Model) = 0,
              "clear preserves empty recheck eligibility state");
   end Empty_Worklist_Produces_Empty_Recheck_Model;

   procedure Empty_Recheck_Queries_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Provenance : constant Remed_Prov.Final_Remediation_Provenance_Model :=
        Remed_Prov.Build (Diagnostics);
      Work : constant Worklist.Final_Remediation_Worklist_Model :=
        Worklist.Build (Provenance);
      Model : constant Recheck.Final_Recheck_Eligibility_Model := Recheck.Build (Work);
   begin
      Assert
        (Recheck.Query_Count
           (Recheck.Query_Status
              (Model,
               Recheck.Final_Recheck_Blocked_By_AST_Coverage)) = 0,
         "empty recheck model should have no AST-blocked rows");
      Assert
        (Recheck.Count_Action
           (Model,
            Recheck.Final_Recheck_Action_Wait_For_Cross_Unit) = 0,
         "empty recheck model should have no cross-unit wait actions");
      Assert
        (Recheck.Count_Blocker
           (Model,
            Final_Prov.Final_Blocker_Representation_Freezing) = 0,
         "empty recheck model should have no representation blockers");
      Assert (Recheck.Eligible_Count (Model) = 0, "no eligible rechecks expected");
      Assert (Recheck.Blocked_Count (Model) = 0, "no blocked rechecks expected");
      Assert (Recheck.Stale_Blocked_Count (Model) = 0, "no stale blockers expected");
      Assert (Recheck.AST_Blocked_Count (Model) = 0, "no AST blockers expected");
      Assert (Recheck.Cross_Unit_Blocked_Count (Model) = 0, "no cross-unit blockers expected");
      Assert (Recheck.Generic_Blocked_Count (Model) = 0, "no generic blockers expected");
      Assert (Recheck.Overload_Blocked_Count (Model) = 0, "no overload blockers expected");
      Assert (Recheck.Representation_Blocked_Count (Model) = 0, "no representation blockers expected");
      Assert (Recheck.Flow_Blocked_Count (Model) = 0, "no flow blockers expected");
      Assert (Recheck.Tasking_Blocked_Count (Model) = 0, "no tasking blockers expected");
      Assert (Recheck.Elaboration_Blocked_Count (Model) = 0, "no elaboration blockers expected");
      Assert (Recheck.Accessibility_Blocked_Count (Model) = 0, "no accessibility blockers expected");
      Assert (Recheck.Discriminant_Blocked_Count (Model) = 0, "no discriminant blockers expected");
      Assert (Recheck.Multiple_Prerequisite_Count (Model) = 0, "no multiple blockers expected");
      Assert (Recheck.Indeterminate_Count (Model) = 0, "no indeterminate blockers expected");
   end Empty_Recheck_Queries_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Empty_Worklist_Produces_Empty_Recheck_Model'Access,
         "empty final remediation worklist produces empty recheck eligibility");
      Register_Routine
        (T,
         Empty_Recheck_Queries_Are_Deterministic'Access,
         "empty final recheck eligibility queries and counters remain deterministic");
   end Register_Tests;

end Test_Ada_Final_Semantic_Recheck_Eligibility_Legality_Pass1205;
