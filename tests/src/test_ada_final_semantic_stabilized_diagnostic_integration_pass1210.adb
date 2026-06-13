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
with Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Colour_Projection;

package body Test_Ada_Final_Semantic_Stabilized_Diagnostic_Integration_Pass1210 is

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
   package Stabilized_Diag renames Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration;
   use type Stabilized_Diag.Final_Blocker_Family;
   use type Stabilized_Diag.Final_Stabilized_Closure_Id;
   use type Stabilized_Diag.Final_Stabilized_Closure_Status;
   use type Stabilized_Diag.Final_Stabilized_Closure_Action;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Id;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Family;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Severity;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Status;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Row;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Set;
   use type Stabilized_Diag.Final_Stabilized_Diagnostic_Model;
   package SC renames Editor.Ada_Semantic_Colour_Projection;
   use type SC.Semantic_Colour_Entry_Id;
   use type SC.Semantic_Colour_Source;
   use type SC.Semantic_Colour_Severity;
   use type SC.Semantic_Colour_Entry;
   use type SC.Semantic_Colour_Model;
   package SF renames Editor.Ada_Semantic_Diagnostic_Feed;
   use type SF.Semantic_Diagnostic_Feed_Id;
   use type SF.Semantic_Diagnostic_Feed_Status;
   use type SF.Semantic_Diagnostic_Feed_Severity;
   use type SF.Semantic_Diagnostic_Feed_Source;
   use type SF.Semantic_Diagnostic_Feed_Entry;
   use type SF.Semantic_Diagnostic_Feed_Model;
   package SG renames Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
   use type SG.Diagnostic_Snapshot_Key;
   use type SG.Diagnostic_Snapshot_Status;
   use type SG.Guarded_Semantic_Diagnostic_Model;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Stabilized_Diagnostic_Integration_Pass1210");
   end Name;

   function Empty_Closure return Closure.Final_Stabilized_Closure_Model is
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
      Gates : constant Stabilization.Final_Stabilization_Gate_Model :=
        Stabilization.Build (Convergence);
   begin
      return Closure.Build (Gates);
   end Empty_Closure;

   function Current_Guard return SG.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key ("final-stabilized-feed.adb", 1210, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   procedure Empty_Stabilized_Closure_Produces_Empty_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure_Model : constant Closure.Final_Stabilized_Closure_Model := Empty_Closure;
      Model : Stabilized_Diag.Final_Stabilized_Diagnostic_Model :=
        Stabilized_Diag.Build (Closure_Model);
   begin
      Assert (Stabilized_Diag.Row_Count (Model) = 0,
              "empty stabilized closure should produce no stabilized diagnostics");
      Assert (Stabilized_Diag.Fingerprint (Model) = 0,
              "empty stabilized diagnostic fingerprint should be stable zero");
      Stabilized_Diag.Clear (Model);
      Assert (Stabilized_Diag.Row_Count (Model) = 0,
              "clear preserves empty stabilized diagnostic state");
   end Empty_Stabilized_Closure_Produces_Empty_Diagnostics;

   procedure Empty_Stabilized_Diagnostic_Queries_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure_Model : constant Closure.Final_Stabilized_Closure_Model := Empty_Closure;
      Model : constant Stabilized_Diag.Final_Stabilized_Diagnostic_Model :=
        Stabilized_Diag.Build (Closure_Model);
   begin
      Assert
        (Stabilized_Diag.Query_Count
           (Stabilized_Diag.Query_Status
              (Model,
               Stabilized_Diag.Final_Stabilized_Diagnostic_AST_Coverage_Blocker)) = 0,
         "empty stabilized diagnostics should have no AST blockers");
      Assert
        (Stabilized_Diag.Count_Family
           (Model,
            Stabilized_Diag.Final_Stabilized_Diagnostic_Representation_Freezing) = 0,
         "empty stabilized diagnostics should have no representation family rows");
      Assert
        (Stabilized_Diag.Count_Blocker
           (Model,
            Final_Prov.Final_Blocker_Tasking_Protected) = 0,
         "empty stabilized diagnostics should have no tasking blockers");
      Assert (Stabilized_Diag.Error_Count (Model) = 0, "no errors expected");
      Assert (Stabilized_Diag.Warning_Count (Model) = 0, "no warnings expected");
      Assert (Stabilized_Diag.Info_Count (Model) = 0, "no info rows expected");
      Assert (Stabilized_Diag.Emitted_Count (Model) = 0, "no emitted rows expected");
      Assert (Stabilized_Diag.Withheld_Current_Count (Model) = 0,
              "no withheld current rows expected");
      Assert (Stabilized_Diag.Recheck_Required_Count (Model) = 0,
              "no recheck rows expected");
      Assert (Stabilized_Diag.Preserved_Error_Count (Model) = 0,
              "no preserved errors expected");
      Assert (Stabilized_Diag.Indeterminate_Count (Model) = 0,
              "no indeterminate rows expected");
   end Empty_Stabilized_Diagnostic_Queries_Are_Deterministic;

   procedure Empty_Stabilized_Diagnostics_Enter_Empty_Feed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure_Model : constant Closure.Final_Stabilized_Closure_Model := Empty_Closure;
      Model : constant Stabilized_Diag.Final_Stabilized_Diagnostic_Model :=
        Stabilized_Diag.Build (Closure_Model);
      Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Final_Stabilized_Diagnostics (Current_Guard, Model);
   begin
      Assert (SF.Current (Feed),
              "current empty stabilized diagnostic input should keep the feed current");
      Assert (SF.Entry_Count (Feed) = 0,
              "empty stabilized diagnostics should not emit feed rows");
      Assert (SF.Rejected_Entry_Count (Feed) = 0,
              "empty stabilized diagnostics should not reject feed rows");
   end Empty_Stabilized_Diagnostics_Enter_Empty_Feed;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Empty_Stabilized_Closure_Produces_Empty_Diagnostics'Access,
         "empty final stabilized closure produces empty stabilized diagnostics");
      Register_Routine
        (T,
         Empty_Stabilized_Diagnostic_Queries_Are_Deterministic'Access,
         "empty final stabilized diagnostic queries and counters remain deterministic");
      Register_Routine
        (T,
         Empty_Stabilized_Diagnostics_Enter_Empty_Feed'Access,
         "empty final stabilized diagnostics enter empty feed deterministically");
   end Register_Tests;

end Test_Ada_Final_Semantic_Stabilized_Diagnostic_Integration_Pass1210;
