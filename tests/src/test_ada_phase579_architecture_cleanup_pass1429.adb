with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Architecture_Cleanup_Pass1429;

package body Test_Ada_Phase579_Architecture_Cleanup_Pass1429 is
   package Cleanup renames Editor.Ada_Phase579_Architecture_Cleanup_Pass1429;
   use type Cleanup.Architecture_Surface;
   use type Cleanup.Cleanup_Status;
   use type Cleanup.Cleanup_Result_Class;
   use type Cleanup.Cleanup_Row;
   use type Cleanup.Cleanup_Input;
   use type Cleanup.Cleanup_Entry;
   use type Cleanup.Cleanup_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Phase579_Architecture_Cleanup_Pass1429");
   end Name;

   function Base_Row
     (Id : Natural;
      Surface : Cleanup.Architecture_Surface;
      Package_Name : String;
      File_Name : String) return Cleanup.Cleanup_Row is
      Row : Cleanup.Cleanup_Row;
   begin
      Row.Id := Id;
      Row.Surface := Surface;
      Row.Source_File := To_Unbounded_String (File_Name);
      Row.Package_Name := To_Unbounded_String (Package_Name);
      Row.Canonical_Owner := To_Unbounded_String ("Editor.Phase579.Final_Architecture");
      Row.Final_Intent :=
        To_Unbounded_String
          ("canonical production surface, quarantined historical scaffold, "
           & "release document, or registered AUnit test after pass1428");
      Row.Quarantine_Reason := To_Unbounded_String ("not quarantined");
      Row.Blocker_Family := To_Unbounded_String ("Architecture.Cleanup.Pass1429");
      Row.Source_Fingerprint := Id * 10 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.API_Fingerprint := Id * 10 + 2;
      Row.Expected_API_Fingerprint := Row.API_Fingerprint;
      Row.Cleanup_Fingerprint := Id * 10 + 3;
      Row.Expected_Cleanup_Fingerprint := Row.Cleanup_Fingerprint;
      return Row;
   end Base_Row;

   function Historical_Row
     (Id : Natural;
      Package_Name : String;
      File_Name : String) return Cleanup.Cleanup_Row is
      Row : Cleanup.Cleanup_Row :=
        Base_Row (Id, Cleanup.Surface_Historical_Pass_Scaffold,
                  Package_Name, File_Name);
   begin
      Row.Is_Production_Surface := False;
      Row.Is_Historical_Pass_Scaffold := True;
      Row.Quarantined := True;
      Row.Exported_To_Production := False;
      Row.Quarantine_Reason :=
        To_Unbounded_String
          ("historical diagnostic/provenance/recheck pass scaffold kept only "
           & "for regression evidence and not as a production extension point");
      return Row;
   end Historical_Row;

   procedure Expect_Status
     (Model : Cleanup.Cleanup_Model;
      Id : Natural;
      Status : Cleanup.Cleanup_Status;
      Result_Class : Cleanup.Cleanup_Result_Class) is
      Feed_Item : constant Cleanup.Cleanup_Entry := Cleanup.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1429 cleanup status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1429 cleanup class");
      Assert (Cleanup.Class_For_Status (Status) = Result_Class,
              "status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_Final_Architecture_Cleanup

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Cleanup_Input;
      Model : Cleanup.Cleanup_Model;
      Row : Cleanup.Cleanup_Row;
   begin
      Cleanup.Add_Row
        (Input,
         Base_Row (1, Cleanup.Surface_Semantic_Engine,
                   "Editor.Ada_Language_Model",
                   "src/core/editor-ada_language_model.ads"));
      Cleanup.Add_Row
        (Input,
         Base_Row (2, Cleanup.Surface_Syntax_Parser,
                   "Editor.Ada_Declaration_Parser",
                   "src/core/editor-ada_declaration_parser.ads"));
      Cleanup.Add_Row
        (Input,
         Historical_Row
           (3,
            "Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance",
            "src/core/editor-ada_remaining_rm_edge_stabilized_closure_"
            & "diagnostic_provenance.ads"));

      Row := Base_Row
        (4, Cleanup.Surface_Release_Document,
         "docs.release.ARCHITECTURE_CLEANUP_PASS1429",
         "docs/release/ARCHITECTURE_CLEANUP_PASS1429.md");
      Row.Is_Production_Surface := False;
      Row.Is_Release_Document := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (5, Cleanup.Surface_Test_Harness,
         "Test_Ada_Phase579_Architecture_Cleanup_Pass1429",
         "tests/src/test_ada_phase579_architecture_cleanup_pass1429.ads");
      Row.Is_Production_Surface := False;
      Row.Is_Test_Surface := True;
      Cleanup.Add_Row (Input, Row);

      Model := Cleanup.Build (Input);

      Assert (Cleanup.Final_Cleanup_Achieved (Model),
              "pass1429 architecture cleanup should be closed");
      Assert (Model.Canonical_Count = 2, "canonical architecture surfaces");
      Assert (Model.Quarantined_Count = 1, "quarantined historical scaffolds");
      Assert (Model.Documented_Count = 1, "release cleanup document");
      Assert (Model.Test_Count = 1, "registered cleanup test");
      Assert (Model.Rejected_Count = 0, "no rejected cleanup rows");

      Expect_Status
        (Model, 1, Cleanup.Status_Canonical_Production_Surface,
         Cleanup.Class_Accepted);
      Expect_Status
        (Model, 3, Cleanup.Status_Quarantined_Historical_Scaffold,
         Cleanup.Class_Quarantined);
      Expect_Status
        (Model, 5, Cleanup.Status_Test_Harness_Covered,
         Cleanup.Class_Accepted);
   end Test_Final_Architecture_Cleanup;

   procedure Test_Alias_And_Mutation_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Cleanup_Input;
      Model : Cleanup.Cleanup_Model;
      Row : Cleanup.Cleanup_Row;
   begin
      Row := Base_Row (10, Cleanup.Surface_Command_Surface,
                       "Editor.Commands", "src/core/editor-commands.ads");
      Row.Has_Command_Alias := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row (11, Cleanup.Surface_Semantic_Engine,
                       "Editor.Ada_Compatibility_Spelling",
                       "src/core/editor-ada_compatibility_spelling.ads");
      Row.Has_Compatibility_Spelling := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row (12, Cleanup.Surface_Render_Surface,
                       "Editor.Render_Model", "src/core/editor-render_model.ads");
      Row.Performs_Render_Side_Parsing := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row (13, Cleanup.Surface_Semantic_Engine,
                       "Editor.Ada_Language_Model",
                       "src/core/editor-ada_language_model.ads");
      Row.Mutates_Dirty_State_During_Analysis := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row (14, Cleanup.Surface_Workspace_Surface,
                       "Editor.Workspace_Persistence",
                       "src/core/editor-workspace_persistence.ads");
      Row.Mutates_Command_Palette_Keybindings_Workspace_Or_Render := True;
      Cleanup.Add_Row (Input, Row);

      Model := Cleanup.Build (Input);

      Expect_Status
        (Model, 10, Cleanup.Status_Rejected_Command_Alias,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 11, Cleanup.Status_Rejected_Compatibility_Spelling,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 12, Cleanup.Status_Rejected_Render_Side_Parsing,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 13, Cleanup.Status_Rejected_Dirty_State_Mutation,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 14, Cleanup.Status_Rejected_Workspace_Keybinding_Render_Leak,
         Cleanup.Class_Rejected);
      Assert (Model.Rejected_Count = 5, "all cleanup leak rows rejected");
   end Test_Alias_And_Mutation_Rejections;

   procedure Test_Scaffold_And_Fingerprint_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Cleanup.Cleanup_Input;
      Model : Cleanup.Cleanup_Model;
      Row : Cleanup.Cleanup_Row;
   begin
      Row := Historical_Row
        (20, "Editor.Ada_Diagnostic_Provenance",
         "src/core/editor-ada_diagnostic_provenance.ads");
      Row.Exported_To_Production := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (21, Cleanup.Surface_Semantic_Engine,
         "Editor.Ada_RM_Remaining_Gap_Remediation_Pass1429",
         "src/core/editor-ada_rm_remaining_gap_remediation_pass1429.ads");
      Row.Reopens_Remaining_Gap := True;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (22, Cleanup.Surface_Semantic_Engine,
         "Editor.Ada_Language_Model", "src/core/editor-ada_language_model.ads");
      Row.Final_Intent_Comment_Present := False;
      Cleanup.Add_Row (Input, Row);

      Row := Base_Row
        (23, Cleanup.Surface_Project_Index,
         "Editor.Ada_Project_Index", "src/core/editor-ada_project_index.ads");
      Row.API_Fingerprint := 1;
      Row.Expected_API_Fingerprint := 2;
      Cleanup.Add_Row (Input, Row);

      Model := Cleanup.Build (Input);

      Expect_Status
        (Model, 20, Cleanup.Status_Rejected_Obsolete_Scaffold_Export,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 21, Cleanup.Status_Rejected_Reopened_Remaining_Gap,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 22, Cleanup.Status_Rejected_Pass_Churn_Intent,
         Cleanup.Class_Rejected);
      Expect_Status
        (Model, 23, Cleanup.Status_Rejected_Fingerprint_Mismatch,
         Cleanup.Class_Rejected);
   end Test_Scaffold_And_Fingerprint_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Final_Architecture_Cleanup'Access,
         "phase579 architecture cleanup closes canonical/quarantine surfaces");
      Register_Routine
        (T, Test_Alias_And_Mutation_Rejections'Access,
         "architecture cleanup rejects alias and mutation leaks");
      Register_Routine
        (T, Test_Scaffold_And_Fingerprint_Rejections'Access,
         "architecture cleanup rejects exported scaffolds and stale evidence");
   end Register_Tests;

end Test_Ada_Phase579_Architecture_Cleanup_Pass1429;
