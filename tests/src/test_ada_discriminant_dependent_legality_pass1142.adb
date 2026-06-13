with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Record_Variant_Aggregate_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Discriminant_Dependent_Legality_Pass1142 is

   package D renames Editor.Ada_Discriminant_Dependent_Legality;
   use type D.Discriminant_Context_Id;
   use type D.Discriminant_Legality_Id;
   use type D.Discriminant_Context_Kind;
   use type D.Discriminant_Legality_Status;
   use type D.Discriminant_Context_Info;
   use type D.Discriminant_Legality_Info;
   use type D.Discriminant_Context_Model;
   use type D.Discriminant_Result_Set;
   use type D.Discriminant_Legality_Model;
   package Record_Agg renames Editor.Ada_Record_Variant_Aggregate_Legality;
   use type Record_Agg.Semantic_Legality_Status;
   use type Record_Agg.Predicate_Use_Legality_Status;
   use type Record_Agg.Representation_Integration_Status;
   use type Record_Agg.Record_Aggregate_Context_Id;
   use type Record_Agg.Record_Aggregate_Legality_Id;
   use type Record_Agg.Record_Aggregate_Context_Kind;
   use type Record_Agg.Record_Aggregate_Legality_Status;
   use type Record_Agg.Record_Aggregate_Context_Info;
   use type Record_Agg.Record_Aggregate_Legality_Info;
   use type Record_Agg.Record_Aggregate_Context_Model;
   use type Record_Agg.Record_Aggregate_Result_Set;
   use type Record_Agg.Record_Aggregate_Legality_Model;
   package Assignments renames Editor.Ada_Assignment_Legality;
   use type Assignments.Expression_Type_Id;
   use type Assignments.Assignment_Context_Id;
   use type Assignments.Assignment_Legality_Id;
   use type Assignments.Assignment_Context_Kind;
   use type Assignments.Assignment_Target_Mode;
   use type Assignments.Assignment_Legality_Status;
   use type Assignments.Assignment_Context_Info;
   use type Assignments.Assignment_Legality_Info;
   use type Assignments.Assignment_Context_Model;
   use type Assignments.Assignment_Legality_Result_Set;
   use type Assignments.Assignment_Legality_Model;
   package Conv renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type Conv.Semantic_Context_Id;
   use type Conv.Semantic_Legality_Id;
   use type Conv.Semantic_Context_Kind;
   use type Conv.Access_Kind;
   use type Conv.Semantic_Legality_Status;
   use type Conv.Semantic_Context_Info;
   use type Conv.Semantic_Legality_Info;
   use type Conv.Semantic_Context_Model;
   use type Conv.Semantic_Legality_Result_Set;
   use type Conv.Semantic_Legality_Model;
   package Returns renames Editor.Ada_Return_Legality;
   use type Returns.Assignment_Context_Id;
   use type Returns.Assignment_Legality_Status;
   use type Returns.Return_Context_Id;
   use type Returns.Return_Legality_Id;
   use type Returns.Return_Context_Kind;
   use type Returns.Return_Legality_Status;
   use type Returns.Return_Context_Info;
   use type Returns.Return_Legality_Info;
   use type Returns.Return_Context_Model;
   use type Returns.Return_Legality_Result_Set;
   use type Returns.Return_Legality_Model;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   use type Replay.Replay_Context_Id;
   use type Replay.Replay_Row_Id;
   use type Replay.Replay_Context_Kind;
   use type Replay.Replay_Status;
   use type Replay.Replay_Context_Info;
   use type Replay.Replay_Info;
   use type Replay.Replay_Context_Model;
   use type Replay.Replay_Result_Set;
   use type Replay.Replay_Model;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Gates.Enforcement_Row_Id;
   use type Gates.Widened_Legality_Engine;
   use type Gates.Enforcement_Status;
   use type Gates.Enforcement_Context_Info;
   use type Gates.Enforcement_Info;
   use type Gates.Enforcement_Context_Model;
   use type Gates.Enforcement_Set;
   use type Gates.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Discriminant_Dependent_Legality_Pass1142");
   end Name;

   function Sample_Contexts return D.Discriminant_Context_Model is
      Contexts : D.Discriminant_Context_Model;
      C        : D.Discriminant_Context_Info;
   begin
      C.Id := 1;
      C.Kind := D.Discriminant_Context_Record_Type;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114201);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Type_Is_Constrained := True;
      C.Discriminant_Count := 1;
      C.Expected_Discriminant_Count := 1;
      C.Source_Fingerprint := 1_142_001;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := D.Discriminant_Context_Record_Type;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114202);
      C.Type_Name := To_Unbounded_String ("Message");
      C.Type_Is_Unconstrained := True;
      C.Expected_Discriminant_Count := 1;
      C.Defaulted_Discriminant_Count := 1;
      C.Source_Fingerprint := 1_142_002;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := D.Discriminant_Context_Discriminant_Default;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114203);
      C.Type_Name := To_Unbounded_String ("Frame");
      C.Nonstatic_Default_Count := 1;
      C.Source_Fingerprint := 1_142_003;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := D.Discriminant_Context_Discriminant_Default;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114204);
      C.Type_Name := To_Unbounded_String ("Frame");
      C.Out_Of_Range_Default_Count := 1;
      C.Source_Fingerprint := 1_142_004;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := D.Discriminant_Context_Record_Type;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114205);
      C.Type_Name := To_Unbounded_String ("Open_Record");
      C.Type_Is_Unconstrained := True;
      C.Expected_Discriminant_Count := 1;
      C.Source_Fingerprint := 1_142_005;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := D.Discriminant_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114206);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Object_Name := To_Unbounded_String ("P");
      C.Object_Is_Constrained := True;
      C.Discriminant_Value_Changed := True;
      C.Source_Fingerprint := 1_142_006;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := D.Discriminant_Context_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114207);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Object_Is_Constrained := True;
      C.Discriminant_Value_Changed := True;
      C.Source_Fingerprint := 1_142_007;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := D.Discriminant_Context_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114208);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Object_Is_Constrained := True;
      C.Discriminant_Value_Changed := True;
      C.Source_Fingerprint := 1_142_008;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := D.Discriminant_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114209);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Object_Is_Constrained := True;
      C.Discriminant_Value_Changed := True;
      C.Source_Fingerprint := 1_142_009;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := D.Discriminant_Context_Generic_Actual;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114210);
      C.Type_Name := To_Unbounded_String ("Formal_Packet");
      C.Object_Is_Constrained := True;
      C.Discriminant_Value_Changed := True;
      C.Source_Fingerprint := 1_142_010;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := D.Discriminant_Context_Variant_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114211);
      C.Type_Name := To_Unbounded_String ("Variant_Record");
      C.Missing_Variant_For_Value := True;
      C.Source_Fingerprint := 1_142_011;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := D.Discriminant_Context_Variant_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114212);
      C.Type_Name := To_Unbounded_String ("Variant_Record");
      C.Forbidden_Variant_For_Value := True;
      C.Source_Fingerprint := 1_142_012;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := D.Discriminant_Context_Variant_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114213);
      C.Type_Name := To_Unbounded_String ("Variant_Record");
      C.Variant_Overlap_Count := 1;
      C.Source_Fingerprint := 1_142_013;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := D.Discriminant_Context_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114214);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Missing_Discriminant_Count := 1;
      C.Linked_Record_Status := Record_Agg.Record_Aggregate_Legality_Legal_Record_Aggregate;
      C.Source_Fingerprint := 1_142_014;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := D.Discriminant_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114215);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Linked_Assignment_Status := Assignments.Assignment_Legality_Incompatible_Subtype;
      C.Source_Fingerprint := 1_142_015;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 16;
      C.Kind := D.Discriminant_Context_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114216);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Linked_Conversion_Status := Conv.Semantic_Legality_Incompatible_Type;
      C.Source_Fingerprint := 1_142_016;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 17;
      C.Kind := D.Discriminant_Context_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114217);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Linked_Return_Status := Returns.Return_Legality_Result_Incompatible_Subtype;
      C.Source_Fingerprint := 1_142_017;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 18;
      C.Kind := D.Discriminant_Context_Generic_Actual;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114218);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Linked_Replay_Status := Replay.Replay_Formal_Actual_Mapping_Missing;
      C.Source_Fingerprint := 1_142_018;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 19;
      C.Kind := D.Discriminant_Context_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114219);
      C.Type_Name := To_Unbounded_String ("Private_Packet");
      C.Private_Full_View_Mismatch := True;
      C.Source_Fingerprint := 1_142_019;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 20;
      C.Kind := D.Discriminant_Context_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114220);
      C.Type_Name := To_Unbounded_String ("Blocked");
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_142_020;
      D.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 21;
      C.Kind := D.Discriminant_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114221);
      C.Type_Name := To_Unbounded_String ("Multi");
      C.Object_Is_Constrained := True;
      C.Discriminant_Value_Changed := True;
      C.Gate_Status := Gates.Enforcement_Parser_AST_Blocker;
      C.Source_Fingerprint := 1_142_021;
      D.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Discriminant_Use_Sites_Are_Classified
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant D.Discriminant_Legality_Model := D.Build (Sample_Contexts);
   begin
      Assert (D.Row_Count (Model) = 21,
              "all discriminant-dependent contexts should be analyzed");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114201)).Status =
              D.Discriminant_Legality_Legal_Constrained_Record,
              "constrained record should be legal");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114202)).Status =
              D.Discriminant_Legality_Legal_Unconstrained_With_Defaults,
              "unconstrained record with defaults should be legal");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114203)).Status =
              D.Discriminant_Legality_Default_Not_Static,
              "non-static discriminant default should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114204)).Status =
              D.Discriminant_Legality_Default_Out_Of_Range,
              "out-of-range default should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114205)).Status =
              D.Discriminant_Legality_Unconstrained_Record_Without_Defaults,
              "unconstrained discriminated record without defaults should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114206)).Status =
              D.Discriminant_Legality_Assignment_Discriminant_Mismatch,
              "assignment should reject changed discriminants on constrained objects");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114207)).Status =
              D.Discriminant_Legality_Conversion_Discriminant_Mismatch,
              "conversion should reject changed discriminants on constrained objects");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114208)).Status =
              D.Discriminant_Legality_Return_Discriminant_Mismatch,
              "return should reject changed discriminants on constrained result objects");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114209)).Status =
              D.Discriminant_Legality_Allocator_Discriminant_Mismatch,
              "allocator should reject incompatible discriminant values");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114210)).Status =
              D.Discriminant_Legality_Generic_Actual_Discriminant_Mismatch,
              "generic actual should reject incompatible discriminant values");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114211)).Status =
              D.Discriminant_Legality_Variant_Missing_For_Value,
              "variant missing for governing value should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114212)).Status =
              D.Discriminant_Legality_Variant_Forbidden_For_Value,
              "variant present for nonmatching value should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114213)).Status =
              D.Discriminant_Legality_Variant_Choice_Overlap,
              "overlapping variant choices should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114214)).Status =
              D.Discriminant_Legality_Missing_Discriminant_Constraint,
              "missing discriminant constraint should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114215)).Status =
              D.Discriminant_Legality_Linked_Assignment_Error,
              "linked assignment blockers should be preserved");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114216)).Status =
              D.Discriminant_Legality_Linked_Conversion_Error,
              "linked conversion blockers should be preserved");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114217)).Status =
              D.Discriminant_Legality_Linked_Return_Error,
              "linked return blockers should be preserved");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114218)).Status =
              D.Discriminant_Legality_Linked_Generic_Replay_Error,
              "linked generic replay blockers should be preserved");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114219)).Status =
              D.Discriminant_Legality_Private_Full_View_Mismatch,
              "private/full-view discriminant mismatches should be rejected");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114220)).Status =
              D.Discriminant_Legality_Coverage_Gate_Blocker,
              "coverage gates should block confident discriminant legality");
      Assert (D.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114221)).Status =
              D.Discriminant_Legality_Multiple_Blockers,
              "multiple blockers should be preserved as multiple blockers");
      Assert (D.Legal_Count (Model) = 2,
              "two sample rows should be legal");
      Assert (D.Default_Error_Count (Model) = 2,
              "default errors should be counted");
      Assert (D.Variant_Error_Count (Model) = 3,
              "variant errors should be counted");
      Assert (D.Use_Site_Error_Count (Model) = 5,
              "assignment/conversion/return/allocator/generic use-site errors should be counted");
      Assert (D.Linked_Error_Count (Model) = 5,
              "linked and multiple blockers should be counted");
      Assert (D.Coverage_Gate_Error_Count (Model) = 2,
              "coverage blockers should be counted");
      Assert (D.Result_Count (D.Rows_For_Type (Model, "packet")) >= 5,
              "type lookup should be case-insensitive");
      Assert (D.Fingerprint (Model) /= 0,
              "model fingerprint should be stable and nonzero");
   end Discriminant_Use_Sites_Are_Classified;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Discriminant_Use_Sites_Are_Classified'Access,
         "discriminant-dependent use-site legality preserves blockers");
   end Register_Tests;

end Test_Ada_Discriminant_Dependent_Legality_Pass1142;
