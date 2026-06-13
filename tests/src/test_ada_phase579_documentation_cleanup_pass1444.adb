with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Documentation_Cleanup_Pass1444;

package body Test_Ada_Phase579_Documentation_Cleanup_Pass1444 is
   package Cleanup renames Editor.Ada_Phase579_Documentation_Cleanup_Pass1444;
   use type Cleanup.Document_Kind;
   use type Cleanup.Documentation_Action;
   use type Cleanup.Documentation_Status;
   use type Cleanup.Documentation_Class;
   use type Cleanup.Documentation_Row;
   use type Cleanup.Documentation_Input;
   use type Cleanup.Documentation_Entry;
   use type Cleanup.Documentation_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Documentation_Cleanup_Pass1444");
   end Name;

   function Base_Row
     (Id : Natural;
      Kind : Cleanup.Document_Kind;
      Action : Cleanup.Documentation_Action;
      Path : String;
      Owner : String;
      Summary : String) return Cleanup.Documentation_Row is
      Row : Cleanup.Documentation_Row;
   begin
      Row.Id := Id;
      Row.Kind := Kind;
      Row.Action := Action;
      Row.Path := To_Unbounded_String (Path);
      Row.Canonical_Owner := To_Unbounded_String (Owner);
      Row.Summary := To_Unbounded_String (Summary);
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.DocumentationCleanup.Pass1444");
      Row.Document_Present := True;
      Row.Source_Fingerprint := Id * 50 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Documentation_Fingerprint := Id * 50 + 2;
      Row.Expected_Documentation_Fingerprint := Row.Documentation_Fingerprint;
      Row.Suite_Fingerprint := Id * 50 + 3;
      Row.Expected_Suite_Fingerprint := Row.Suite_Fingerprint;
      return Row;
   end Base_Row;

   procedure Add_Cleanup_Ledger (Input : in out Cleanup.Documentation_Input) is
      Row : Cleanup.Documentation_Row;
   begin
      Row := Base_Row
        (1,
         Cleanup.Kind_Canonical_Architecture_Map,
         Cleanup.Action_Keep_Canonical,
         "docs/release/PHASE579_CANONICAL_ARCHITECTURE_MAP_PASS1444.md",
         "Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442",
         "canonical production API map is the single architecture entry point");
      Row.Architecture_Map_Present := True;
      Row.References_Canonical_API := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (2,
         Cleanup.Kind_Release_Gate,
         Cleanup.Action_Keep_Release_Evidence,
         "docs/release/PHASE579_PROJECT_SCALE_CLOSURE_PASS1436.md",
         "Editor.Ada_Phase579_Project_Scale_Closure_Pass1436",
         "project-scale validation closure remains release evidence");
      Row.Architecture_Map_Present := True;
      Row.References_Core_Suite_Prune := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (3,
         Cleanup.Kind_Validation_Report,
         Cleanup.Action_Keep_Release_Evidence,
         "docs/release/REAL_ADA_CORPUS_VALIDATION_PASS1430.md",
         "Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430",
         "corpus validation remains release evidence, not speculative new work");
      Row.Architecture_Map_Present := True;
      Row.References_Core_Suite_Prune := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (4,
         Cleanup.Kind_Cleanup_Ledger,
         Cleanup.Action_Keep_Release_Evidence,
         "docs/release/LEGACY_SCAFFOLD_INVENTORY_PASS1440.md",
         "Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440",
         "legacy scaffold inventory remains cleanup evidence");
      Row.Architecture_Map_Present := True;
      Row.References_Core_Suite_Prune := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (5,
         Cleanup.Kind_Cleanup_Ledger,
         Cleanup.Action_Keep_Release_Evidence,
         "docs/release/CORE_SUITE_PRUNING_PASS1443.md",
         "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "Core_Suite pruning remains cleanup evidence");
      Row.Architecture_Map_Present := True;
      Row.References_Core_Suite_Prune := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (6,
         Cleanup.Kind_Historical_Pass_Note,
         Cleanup.Action_Archive_Historical_Note,
         "README_PASS1077.txt",
         "Historical pass ledger",
         "old diagnostic projection notes are archived as historical only");
      Row.Historical_Only := True;
      Cleanup.Add_Row (Input, Row);
   end Add_Cleanup_Ledger;

   procedure Documentation_Cleanup_Accepts_Canonical_Map

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Documentation_Input;
      Model : Cleanup.Documentation_Model;
   begin
      Add_Cleanup_Ledger (Input);
      Model := Cleanup.Build (Input);
      Assert
        (Cleanup.Result_For (Model, 1).Status =
         Cleanup.Status_Canonical_Map_Accepted,
         "canonical architecture map must be accepted");
      Assert
        (Cleanup.Documentation_Cleaned (Model),
         "documentation cleanup should be complete for the canonical ledger");
      Assert
        (Cleanup.Ready_For_Final_Dead_Code_Sweep (Model),
         "documentation cleanup should enable the final dead-code sweep");
   end Documentation_Cleanup_Accepts_Canonical_Map;

   procedure Release_Evidence_Remains_Clean

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Documentation_Input;
      Model : Cleanup.Documentation_Model;
   begin
      Add_Cleanup_Ledger (Input);
      Model := Cleanup.Build (Input);
      Assert
        (Cleanup.Result_For (Model, 2).Status =
         Cleanup.Status_Release_Gate_Accepted,
         "project closure doc must remain release evidence");
      Assert
        (Cleanup.Result_For (Model, 3).Status =
         Cleanup.Status_Validation_Report_Accepted,
         "real corpus doc must remain validation evidence");
      Assert
        (Cleanup.Result_For (Model, 4).Status =
         Cleanup.Status_Cleanup_Ledger_Accepted,
         "legacy inventory doc must remain cleanup evidence");
   end Release_Evidence_Remains_Clean;

   procedure Historical_Readmes_Are_Archived

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Documentation_Input;
      Model : Cleanup.Documentation_Model;
   begin
      Add_Cleanup_Ledger (Input);
      Model := Cleanup.Build (Input);
      Assert
        (Cleanup.Result_For (Model, 6).Status =
         Cleanup.Status_Historical_Note_Archived,
         "historical pass READMEs should be archived, not canonical APIs");
      Assert
        (Model.Archived_Historical_Count = 1,
         "exactly one historical note is represented in this cleanup ledger");
   end Historical_Readmes_Are_Archived;

   procedure Reopened_Remaining_Gap_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Documentation_Input;
      Row : Cleanup.Documentation_Row;
      Model : Cleanup.Documentation_Model;
   begin
      Row := Base_Row
        (7,
         Cleanup.Kind_Validation_Report,
         Cleanup.Action_Keep_Release_Evidence,
         "docs/release/BAD_REOPENED_GAP.md",
         "bad owner",
         "bad note reopens a Remaining edge");
      Row.Architecture_Map_Present := True;
      Row.References_Core_Suite_Prune := True;
      Row.Reopens_Remaining_Gap := True;
      Cleanup.Add_Row (Input, Row);
      Model := Cleanup.Build (Input);
      Assert
        (Cleanup.Result_For (Model, 7).Status =
         Cleanup.Status_Rejected_Reopened_Remaining_Gap,
         "documentation must not reopen Remaining_* work after pass1428");
   end Reopened_Remaining_Gap_Is_Rejected;

   procedure Speculative_Edge_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Documentation_Input;
      Row : Cleanup.Documentation_Row;
      Model : Cleanup.Documentation_Model;
   begin
      Row := Base_Row
        (8,
         Cleanup.Kind_Validation_Report,
         Cleanup.Action_Keep_Release_Evidence,
         "docs/release/BAD_SPECULATIVE_EDGE.md",
         "bad owner",
         "bad note invents speculative semantic work");
      Row.Architecture_Map_Present := True;
      Row.References_Core_Suite_Prune := True;
      Row.Adds_Speculative_Semantic_Edge := True;
      Cleanup.Add_Row (Input, Row);
      Model := Cleanup.Build (Input);
      Assert
        (Cleanup.Result_For (Model, 8).Status =
         Cleanup.Status_Rejected_Speculative_Semantic_Edge,
         "documentation must not invent speculative semantic edges");
   end Speculative_Edge_Is_Rejected;

   procedure Stale_Documentation_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Documentation_Input;
      Row : Cleanup.Documentation_Row;
      Model : Cleanup.Documentation_Model;
   begin
      Row := Base_Row
        (9,
         Cleanup.Kind_Canonical_Architecture_Map,
         Cleanup.Action_Keep_Canonical,
         "docs/release/PHASE579_CANONICAL_ARCHITECTURE_MAP_PASS1444.md",
         "Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442",
         "stale canonical architecture map");
      Row.Architecture_Map_Present := True;
      Row.References_Canonical_API := True;
      Row.Expected_Documentation_Fingerprint :=
        Row.Documentation_Fingerprint + 1;
      Cleanup.Add_Row (Input, Row);
      Model := Cleanup.Build (Input);
      Assert
        (Cleanup.Result_For (Model, 9).Status =
         Cleanup.Status_Rejected_Fingerprint_Mismatch,
         "stale documentation fingerprints must be rejected");
   end Stale_Documentation_Is_Rejected;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Documentation_Cleanup_Accepts_Canonical_Map'Access,
         "documentation cleanup accepts canonical architecture map");
      Register_Routine
        (T, Release_Evidence_Remains_Clean'Access,
         "release evidence documents remain clean");
      Register_Routine
        (T, Historical_Readmes_Are_Archived'Access,
         "historical pass notes are archived");
      Register_Routine
        (T, Reopened_Remaining_Gap_Is_Rejected'Access,
         "reopened Remaining gaps are rejected");
      Register_Routine
        (T, Speculative_Edge_Is_Rejected'Access,
         "speculative semantic edges are rejected");
      Register_Routine
        (T, Stale_Documentation_Is_Rejected'Access,
         "stale documentation fingerprints are rejected");
   end Register_Tests;

end Test_Ada_Phase579_Documentation_Cleanup_Pass1444;
