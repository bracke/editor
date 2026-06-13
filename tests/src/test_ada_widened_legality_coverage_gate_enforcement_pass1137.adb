with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Coverage_Gated_Semantic_Results;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Widened_Legality_Coverage_Gate_Enforcement_Pass1137 is

   package AUD renames Editor.Ada_AST_Semantic_Coverage_Audit;
   use type AUD.Coverage_Item_Id;
   use type AUD.Ada_Construct_Kind;
   use type AUD.Semantic_Consumer_Family;
   use type AUD.Coverage_Status;
   use type AUD.Coverage_Context_Info;
   use type AUD.Coverage_Info;
   use type AUD.Coverage_Context_Model;
   use type AUD.Coverage_Result_Set;
   use type AUD.Coverage_Model;
   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   use type Gates.Gate_Item_Id;
   use type Gates.Semantic_Conclusion_Kind;
   use type Gates.Gate_Action;
   use type Gates.Gate_Status;
   use type Gates.Gate_Context_Info;
   use type Gates.Gate_Info;
   use type Gates.Gate_Context_Model;
   use type Gates.Gate_Result_Set;
   use type Gates.Gate_Model;
   package Gated renames Editor.Ada_Coverage_Gated_Semantic_Results;
   use type Gated.Gated_Result_Id;
   use type Gated.Original_Result_State;
   use type Gated.Gated_Result_Status;
   use type Gated.Gated_Result_Context_Info;
   use type Gated.Gated_Result_Info;
   use type Gated.Gated_Result_Context_Model;
   use type Gated.Gated_Result_Set;
   use type Gated.Gated_Result_Model;
   package Enforce renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Enforce.Enforcement_Row_Id;
   use type Enforce.Widened_Legality_Engine;
   use type Enforce.Enforcement_Status;
   use type Enforce.Enforcement_Context_Info;
   use type Enforce.Enforcement_Info;
   use type Enforce.Enforcement_Context_Model;
   use type Enforce.Enforcement_Set;
   use type Enforce.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Widened_Legality_Coverage_Gate_Enforcement_Pass1137");
   end Name;

   procedure Coverage_Gates_Are_Enforced_Per_Widened_Legality_Engine
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit_In : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 1;
      C.Construct := AUD.Construct_Assignment;
      C.Consumer := AUD.Consumer_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113701);
      C.Construct_Name := To_Unbounded_String ("assignment");
      C.Normalized_Construct_Name := To_Unbounded_String ("assignment");
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 2;
      C.Construct := AUD.Construct_Return_Statement;
      C.Consumer := AUD.Consumer_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113702);
      C.Construct_Name := To_Unbounded_String ("return");
      C.Normalized_Construct_Name := To_Unbounded_String ("return");
      C.Structural_AST_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 3;
      C.Construct := AUD.Construct_Record_Aggregate;
      C.Consumer := AUD.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113703);
      C.Construct_Name := To_Unbounded_String ("record aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("record aggregate");
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 4;
      C.Construct := AUD.Construct_Generic_Instantiation;
      C.Consumer := AUD.Consumer_Generic_Instance_Body_Expansion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113704);
      C.Construct_Name := To_Unbounded_String ("generic instantiation");
      C.Normalized_Construct_Name := To_Unbounded_String ("generic instantiation");
      C.Cross_Unit_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 5;
      C.Construct := AUD.Construct_Protected_Body;
      C.Consumer := AUD.Consumer_Tasking_Protected_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113705);
      C.Construct_Name := To_Unbounded_String ("protected body");
      C.Normalized_Construct_Name := To_Unbounded_String ("protected body");
      C.Consumer_Integrated := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 6;
      C.Construct := AUD.Construct_Representation_Clause;
      C.Consumer := AUD.Consumer_Representation_Freezing_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113706);
      C.Construct_Name := To_Unbounded_String ("representation clause");
      C.Normalized_Construct_Name := To_Unbounded_String ("representation clause");
      C.Graceful_Degradation_Only := True;
      AUD.Add_Context (Audit_In, C);

      declare
         Audit_Model : constant AUD.Coverage_Model := AUD.Build (Audit_In);
         Assignment_Gates : constant Gates.Gate_Model :=
           Gates.Build_From_Coverage (Audit_Model, Gates.Conclusion_Unknown);
         Assignment_Gated : constant Gated.Gated_Result_Model :=
           Gated.Build_From_Gates (Assignment_Gates, Gated.Original_Result_Legal);
         Model : constant Enforce.Enforcement_Model :=
           Enforce.Build_From_Gated_Results (Assignment_Gated);
         Assignment_Row : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113701));
         Return_Row : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113702));
         Aggregate_Row : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113703));
         Generic_Row : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113704));
         Tasking_Row : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113705));
         Representation_Row : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113706));
      begin
         Assert (Enforce.Row_Count (Model) = 6,
                 "all gated semantic results should be enforced");
         Assert (Assignment_Row.Status = Enforce.Enforcement_Confident_Result_Allowed,
                 "complete coverage should allow a confident assignment result");
         Assert (Assignment_Row.Engine = Enforce.Engine_Assignment,
                 "assignment conclusion should map to assignment engine");
         Assert (Return_Row.Status = Enforce.Enforcement_Parser_AST_Blocker,
                 "missing structural AST should block return legality at the engine");
         Assert (Aggregate_Row.Status = Enforce.Enforcement_Metadata_Blocker,
                 "missing type metadata should block aggregate legality at the engine");
         Assert (Generic_Row.Status = Enforce.Enforcement_Cross_Unit_Closure_Required,
                 "cross-unit coverage gaps should require closure before generic legality");
         Assert (Tasking_Row.Status = Enforce.Enforcement_Consumer_Integration_Blocker,
                 "non-integrated consumers should block tasking/protected precision legality");
         Assert (Representation_Row.Status = Enforce.Enforcement_Legal_Result_Suppressed,
                 "graceful degradation should suppress representation/freezing legal results");
         Assert (Enforce.Confident_Count (Model) = 1,
                 "one widened legality result should remain confident");
         Assert (Enforce.Repair_Blocker_Count (Model) = 3,
                 "three rows should require parser/metadata/consumer repair");
         Assert (Enforce.Cross_Unit_Required_Count (Model) = 1,
                 "one row should require cross-unit closure");
         Assert (Enforce.Suppressed_Count (Model) = 1,
                 "one legal result should be suppressed");
         Assert (Enforce.Unsafe_Blocker_Count (Model) = 4,
                 "suppressed and repair-required rows are unsafe blockers");
         Assert (Enforce.Count_Conclusion (Model, Gates.Conclusion_Unknown) = 6,
                 "enforcement preserves source semantic conclusion family");
         Assert (Enforce.Fingerprint (Model) /= 0,
                 "enforcement model should have deterministic non-zero fingerprint");
      end;
   end Coverage_Gates_Are_Enforced_Per_Widened_Legality_Engine;

   procedure Original_Errors_Are_Preserved_Not_Suppressed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit_In : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 7;
      C.Construct := AUD.Construct_Call;
      C.Consumer := AUD.Consumer_Overload_Preference;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113707);
      C.Construct_Name := To_Unbounded_String ("call");
      C.Normalized_Construct_Name := To_Unbounded_String ("call");
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      declare
         Audit_Model : constant AUD.Coverage_Model := AUD.Build (Audit_In);
         Gate_Model  : constant Gates.Gate_Model :=
           Gates.Build_From_Coverage (Audit_Model, Gates.Conclusion_Overload);
         Gated_Model : constant Gated.Gated_Result_Model :=
           Gated.Build_From_Gates (Gate_Model, Gated.Original_Result_Error);
         Model       : constant Enforce.Enforcement_Model :=
           Enforce.Build_From_Gated_Results (Gated_Model);
         Row         : constant Enforce.Enforcement_Info :=
           Enforce.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113707));
      begin
         Assert (Row.Engine = Enforce.Engine_Call_Overload,
                 "overload result should map to call/overload engine");
         Assert (Row.Status = Enforce.Enforcement_Original_Error_Preserved,
                 "original semantic errors should be preserved rather than suppressed");
         Assert (Enforce.Preserved_Error_Count (Model) = 1,
                 "preserved original errors should be counted distinctly");
         Assert (Enforce.Unsafe_Blocker_Count (Model) = 0,
                 "preserved errors are not unsafe legal conclusions");
      end;
   end Original_Errors_Are_Preserved_Not_Suppressed;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Coverage_Gates_Are_Enforced_Per_Widened_Legality_Engine'Access,
         "coverage gates enforced per widened legality engine");
      Register_Routine
        (T, Original_Errors_Are_Preserved_Not_Suppressed'Access,
         "original semantic errors are preserved by enforcement");
   end Register_Tests;

end Test_Ada_Widened_Legality_Coverage_Gate_Enforcement_Pass1137;
