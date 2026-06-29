with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Semantic_Coverage_Gates is

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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Semantic_Coverage_Gates");
   end Name;

   procedure Coverage_Gaps_Gate_Unsafe_Semantic_Conclusions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit_In : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 1;
      C.Construct := AUD.Construct_Assignment;
      C.Consumer := AUD.Consumer_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113401);
      C.Construct_Name := To_Unbounded_String ("assignment");
      C.Normalized_Construct_Name := To_Unbounded_String ("assignment");
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 2;
      C.Construct := AUD.Construct_Container_Aggregate;
      C.Consumer := AUD.Consumer_Conversion_Access_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113402);
      C.Construct_Name := To_Unbounded_String ("container aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("container aggregate");
      C.Token_Only_Parse := True;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 3;
      C.Construct := AUD.Construct_Call;
      C.Consumer := AUD.Consumer_Overload_Preference;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113403);
      C.Construct_Name := To_Unbounded_String ("call");
      C.Normalized_Construct_Name := To_Unbounded_String ("call");
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 4;
      C.Construct := AUD.Construct_Separate_Body;
      C.Consumer := AUD.Consumer_Cross_Unit_Closure;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113404);
      C.Construct_Name := To_Unbounded_String ("separate body");
      C.Normalized_Construct_Name := To_Unbounded_String ("separate body");
      C.Cross_Unit_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 5;
      C.Construct := AUD.Construct_Reduction_Expression;
      C.Consumer := AUD.Consumer_Expression_Types;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113405);
      C.Construct_Name := To_Unbounded_String ("reduction expression");
      C.Normalized_Construct_Name := To_Unbounded_String ("reduction expression");
      C.Graceful_Degradation_Only := True;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 6;
      C.Construct := AUD.Construct_Pragma;
      C.Consumer := AUD.Consumer_None;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113406);
      C.Construct_Name := To_Unbounded_String ("pragma");
      C.Normalized_Construct_Name := To_Unbounded_String ("pragma");
      AUD.Add_Context (Audit_In, C);

      declare
         Audit_Model : constant AUD.Coverage_Model := AUD.Build (Audit_In);
         Model       : constant Gates.Gate_Model :=
           Gates.Build_From_Coverage
             (Audit_Model, Gates.Conclusion_Integrated_Closure);
         Aggregate_Row : constant Gates.Gate_Info :=
           Gates.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113402));
         Call_Row : constant Gates.Gate_Info :=
           Gates.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113403));
         XUnit_Row : constant Gates.Gate_Info :=
           Gates.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113404));
         Degraded_Row : constant Gates.Gate_Info :=
           Gates.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113405));
      begin
         Assert (Gates.Gate_Count (Model) = 6,
                 "all coverage rows should produce semantic coverage gates");
         Assert (Gates.Open_Count (Model) = 1,
                 "complete coverage should allow one confident result");
         Assert (Aggregate_Row.Action = Gates.Gate_Require_Parser_AST_Repair,
                 "token-only aggregate must require parser/AST repair");
         Assert (Call_Row.Action = Gates.Gate_Require_Metadata_Repair,
                 "missing type metadata must require semantic metadata repair");
         Assert (XUnit_Row.Action = Gates.Gate_Require_Cross_Unit_Closure,
                 "cross-unit metadata gap must require cross-unit closure");
         Assert (Degraded_Row.Action = Gates.Gate_Suppress_Legal_Result,
                 "graceful-degradation-only coverage must suppress legal results");
         Assert (Gates.Degraded_Count (Model) = 1,
                 "unknown consumer coverage should degrade to indeterminate");
         Assert (Gates.Repair_Required_Count (Model) = 2,
                 "parser and metadata repairs should both be counted");
         Assert (Gates.Cross_Unit_Required_Count (Model) = 1,
                 "cross-unit-required gates should be counted");
         Assert (Gates.Suppressed_Count (Model) = 1,
                 "suppressed legal result gates should be counted");
         Assert (Gates.Unsafe_Blocker_Count (Model) = 5,
                 "all non-open gates should be unsafe blockers");
         Assert (Gates.Fingerprint (Model) /= 0,
                 "semantic coverage gate fingerprint should be deterministic and non-zero");
      end;
   end Coverage_Gaps_Gate_Unsafe_Semantic_Conclusions;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Coverage_Gaps_Gate_Unsafe_Semantic_Conclusions'Access,
         "coverage gaps gate unsafe semantic conclusions");
   end Register_Tests;

end Test_Ada_Semantic_Coverage_Gates;
