with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Lookup_Integration;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Expression_Types;
with Editor.Ada_Generic_Formal_Package_Substitutions;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;

package body Test_Ada_Wide_Semantic_Legality_Diagnostics is

   package WD renames Editor.Ada_Wide_Semantic_Legality_Diagnostics;
   use type WD.Wide_Semantic_Diagnostic_Id;
   use type WD.Wide_Semantic_Diagnostic_Family;
   use type WD.Wide_Semantic_Diagnostic_Severity;
   use type WD.Wide_Semantic_Diagnostic_Kind;
   use type WD.Wide_Semantic_Diagnostic_Info;
   use type WD.Wide_Semantic_Diagnostic_Result_Set;
   use type WD.Wide_Semantic_Diagnostic_Model;
   package AL renames Editor.Ada_Assignment_Legality;
   use type AL.Expression_Type_Id;
   use type AL.Assignment_Context_Id;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Context_Kind;
   use type AL.Assignment_Target_Mode;
   use type AL.Assignment_Legality_Status;
   use type AL.Assignment_Context_Info;
   use type AL.Assignment_Legality_Info;
   use type AL.Assignment_Context_Model;
   use type AL.Assignment_Legality_Result_Set;
   use type AL.Assignment_Legality_Model;
   package RL renames Editor.Ada_Return_Legality;
   use type RL.Assignment_Context_Id;
   use type RL.Assignment_Legality_Status;
   use type RL.Return_Context_Id;
   use type RL.Return_Legality_Id;
   use type RL.Return_Context_Kind;
   use type RL.Return_Legality_Status;
   use type RL.Return_Context_Info;
   use type RL.Return_Legality_Info;
   use type RL.Return_Context_Model;
   use type RL.Return_Legality_Result_Set;
   use type RL.Return_Legality_Model;
   package EL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type EL.Semantic_Context_Id;
   use type EL.Semantic_Legality_Id;
   use type EL.Semantic_Context_Kind;
   use type EL.Access_Kind;
   use type EL.Semantic_Legality_Status;
   use type EL.Semantic_Context_Info;
   use type EL.Semantic_Legality_Info;
   use type EL.Semantic_Context_Model;
   use type EL.Semantic_Legality_Result_Set;
   use type EL.Semantic_Legality_Model;
   package FL renames Editor.Ada_Control_Flow_Legality;
   use type FL.Flow_Context_Id;
   use type FL.Flow_Legality_Id;
   use type FL.Flow_Context_Kind;
   use type FL.Flow_Legality_Status;
   use type FL.Flow_Context_Info;
   use type FL.Flow_Legality_Info;
   use type FL.Flow_Context_Model;
   use type FL.Flow_Legality_Result_Set;
   use type FL.Flow_Legality_Model;
   package TL renames Editor.Ada_Tasking_Protected_Legality;
   use type TL.Tasking_Context_Id;
   use type TL.Tasking_Legality_Id;
   use type TL.Tasking_Context_Kind;
   use type TL.Tasking_Legality_Status;
   use type TL.Tasking_Context_Info;
   use type TL.Tasking_Legality_Info;
   use type TL.Tasking_Context_Model;
   use type TL.Tasking_Result_Set;
   use type TL.Tasking_Legality_Model;
   package TD renames Editor.Ada_Tagged_Derived_Legality;
   use type TD.Tagged_Context_Id;
   use type TD.Tagged_Legality_Id;
   use type TD.Tagged_Context_Kind;
   use type TD.Tagged_Legality_Status;
   use type TD.Tagged_Context_Info;
   use type TD.Tagged_Legality_Info;
   use type TD.Tagged_Context_Model;
   use type TD.Tagged_Result_Set;
   use type TD.Tagged_Legality_Model;
   package GI renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
   use type GI.Instance_Context_Id;
   use type GI.Instance_Legality_Id;
   use type GI.Instance_Context_Kind;
   use type GI.Instance_Legality_Status;
   use type GI.Instance_Context_Info;
   use type GI.Instance_Legality_Info;
   use type GI.Instance_Context_Model;
   use type GI.Instance_Result_Set;
   use type GI.Instance_Legality_Model;
   package CU renames Editor.Ada_Cross_Unit_Semantic_Closure;
   use type CU.Cross_Unit_Semantic_Context_Id;
   use type CU.Cross_Unit_Semantic_Id;
   use type CU.Cross_Unit_Semantic_Context_Kind;
   use type CU.Cross_Unit_Semantic_Status;
   use type CU.Cross_Unit_Semantic_Context_Info;
   use type CU.Cross_Unit_Semantic_Info;
   use type CU.Cross_Unit_Semantic_Context_Model;
   use type CU.Cross_Unit_Semantic_Result_Set;
   use type CU.Cross_Unit_Semantic_Model;
   package CL renames Editor.Ada_Cross_Unit_Closure;
   use type CL.Cross_Unit_Link_Kind;
   use type CL.Cross_Unit_Link_Status;
   use type CL.Cross_Unit_Link_Info;
   use type CL.Spec_Body_Consistency_Status;
   use type CL.Spec_Body_Consistency_Info;
   use type CL.Child_Unit_Legality_Status;
   use type CL.Child_Unit_Legality_Info;
   use type CL.Separate_Body_Legality_Status;
   use type CL.Separate_Body_Legality_Info;
   use type CL.Cross_Unit_Closure_Model;
   package LU renames Editor.Ada_Cross_Unit_Lookup_Integration;
   use type LU.Cross_Unit_Lookup_Status;
   use type LU.Cross_Unit_Lookup_Id;
   use type LU.Cross_Unit_Lookup_Entry;
   use type LU.Cross_Unit_Lookup_Model;
   package ET renames Editor.Ada_Expression_Types;
   use type ET.Expected_Type_Propagation_Status;
   use type ET.Operator_Type_Inference_Status;
   use type ET.Concatenation_Type_Inference_Status;
   use type ET.Aggregate_Type_Inference_Status;
   use type ET.Conversion_Type_Inference_Status;
   use type ET.Conditional_Type_Inference_Status;
   use type ET.Membership_Range_Inference_Status;
   use type ET.Target_Name_Inference_Status;
   use type ET.Indexed_Slice_Inference_Status;
   use type ET.Boolean_Context_Inference_Status;
   use type ET.Raise_No_Return_Inference_Status;
   use type ET.Allocator_Type_Inference_Status;
   use type ET.Universal_Numeric_Resolution_Status;
   use type ET.Dispatching_Call_Inference_Status;
   use type ET.Call_Actual_Type_Resolution_Status;
   use type ET.Parameter_Association_Inference_Status;
   use type ET.Dereference_Access_Inference_Status;
   use type ET.Attribute_Type_Inference_Status;
   use type ET.Expression_Type_Status;
   use type ET.Expression_Type_Id;
   use type ET.Expression_Type_Info;
   use type ET.Expression_Type_Model;
   package SE renames Editor.Ada_Static_Expressions;
   use type SE.Static_Value_Status;
   use type SE.Static_Value_Info;
   use type SE.Static_Fixed_Type_Id;
   use type SE.Static_Fixed_Type_Info;
   use type SE.Static_Modular_Type_Id;
   use type SE.Static_Modular_Type_Info;
   use type SE.Static_Enumeration_Literal_Id;
   use type SE.Static_Enumeration_Literal_Info;
   use type SE.Static_Type_Bound_Id;
   use type SE.Static_Type_Bound_Info;
   use type SE.Static_Binding_Id;
   use type SE.Static_Binding_Kind;
   use type SE.Static_Binding_Info;
   use type SE.Static_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Wide_Semantic_Legality_Diagnostics");
   end Name;

   procedure Build_Wide_Diagnostics_From_Semantic_Legality_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Expression_Types : ET.Expression_Type_Model;

      Assignment_Contexts : AL.Assignment_Context_Model;
      Assignment_Context  : AL.Assignment_Context_Info;
      Assignments         : AL.Assignment_Legality_Model;

      Return_Contexts : RL.Return_Context_Model;
      Return_Context  : RL.Return_Context_Info;
      Returns         : RL.Return_Legality_Model;

      Expression_Contexts : EL.Semantic_Context_Model;
      Expression_Context  : EL.Semantic_Context_Info;
      Expressions         : EL.Semantic_Legality_Model;

      Flow_Contexts : FL.Flow_Context_Model;
      Flow_Context  : FL.Flow_Context_Info;
      Flow          : FL.Flow_Legality_Model;

      Tasking_Contexts : TL.Tasking_Context_Model;
      Tasking_Context  : TL.Tasking_Context_Info;
      Tasking          : TL.Tasking_Legality_Model;

      Tagged_Contexts : TD.Tagged_Context_Model;
      Tagged_Context  : TD.Tagged_Context_Info;
      Dispatching     : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model;
      Tagged_Model          : TD.Tagged_Legality_Model;

      Instance_Contexts : GI.Instance_Context_Model;
      Instance_Context  : GI.Instance_Context_Info;
      Bodies        : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model;
      Formal_Packs  : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model;
      Freezing      : Editor.Ada_Freezing_Points.Freezing_Model;
      Representation : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Instances     : GI.Instance_Legality_Model;

      Cross_Contexts : CU.Cross_Unit_Semantic_Context_Model;
      Cross_Context  : CU.Cross_Unit_Semantic_Context_Info;
      Closure        : CL.Cross_Unit_Closure_Model;
      Lookup         : LU.Cross_Unit_Lookup_Model;
      Cross_Unit     : CU.Cross_Unit_Semantic_Model;
   begin
      Assignment_Context.Id := 1;
      Assignment_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Assignment_Context.Target_Node := Editor.Ada_Syntax_Tree.Node_Id (101);
      Assignment_Context.Source_Node := Editor.Ada_Syntax_Tree.Node_Id (102);
      Assignment_Context.Target_Mode := AL.Assignment_Target_Constant;
      Assignment_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Source_Subtype := To_Unbounded_String ("Integer");
      AL.Add_Context (Assignment_Contexts, Assignment_Context);
      Assignments := AL.Build (Assignment_Contexts, Expression_Types);

      Return_Context.Id := 2;
      Return_Context.Return_Node := Editor.Ada_Syntax_Tree.Node_Id (201);
      Return_Context.Is_Function_Context := True;
      Return_Context.Has_Expression := False;
      RL.Add_Context (Return_Contexts, Return_Context);
      Returns := RL.Build (Return_Contexts, Assignments);

      Expression_Context.Id := 3;
      Expression_Context.Kind := EL.Semantic_Context_Conversion;
      Expression_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (301);
      Expression_Context.Target_Subtype := To_Unbounded_String ("Small");
      Expression_Context.Operand_Subtype := To_Unbounded_String ("Integer");
      Expression_Context.Is_Numeric_Target := True;
      Expression_Context.Is_Numeric_Operand := True;
      Expression_Context.Operand_Static_Status := SE.Static_Value_Integer;
      Expression_Context.Operand_Static_Integer_Value := 999;
      Expression_Context.Target_Has_Static_Range := True;
      Expression_Context.Target_Static_First := 1;
      Expression_Context.Target_Static_Last := 10;
      EL.Add_Context (Expression_Contexts, Expression_Context);
      Expressions := EL.Build (Expression_Contexts);

      Flow_Context.Id := 4;
      Flow_Context.Kind := FL.Flow_Context_If_Statement;
      Flow_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (401);
      Flow_Context.Condition_Subtype := To_Unbounded_String ("Integer");
      FL.Add_Context (Flow_Contexts, Flow_Context);
      Flow := FL.Build (Flow_Contexts, Returns);

      Tasking_Context.Id := 5;
      Tasking_Context.Kind := TL.Tasking_Context_Protected_Entry;
      Tasking_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (501);
      Tasking_Context.Barrier_Present := False;
      TL.Add_Context (Tasking_Contexts, Tasking_Context);
      Tasking := TL.Build (Tasking_Contexts, Flow);

      Tagged_Context.Id := 6;
      Tagged_Context.Kind := TD.Tagged_Context_Type_Derivation;
      Tagged_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (601);
      Tagged_Context.Parent_Name := To_Unbounded_String ("Root");
      Tagged_Context.Parent_Resolved := False;
      TD.Add_Context (Tagged_Contexts, Tagged_Context);
      Tagged_Model := TD.Build (Tagged_Contexts, Assignments, Returns, Dispatching);

      Instance_Context.Id := 7;
      Instance_Context.Kind := GI.Instance_Context_Formal_Package_Substitution;
      Instance_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (701);
      Instance_Context.Formal_Package_Status :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Missing;
      GI.Add_Context (Instance_Contexts, Instance_Context);
      Instances := GI.Build
        (Instance_Contexts, Bodies, Formal_Packs, Freezing, Representation,
         Assignments, Returns, Expressions, Tagged_Model);

      Cross_Context.Id := 8;
      Cross_Context.Kind := CU.Cross_Unit_Semantic_Assignment;
      Cross_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (801);
      Cross_Context.Source_Unit_Name := To_Unbounded_String ("Client");
      Cross_Context.Target_Unit_Name := To_Unbounded_String ("Missing.Unit");
      Cross_Context.Requires_Cross_Unit_Dependency := True;
      Cross_Context.Dependency_Status := CL.Cross_Unit_Link_Missing;
      CU.Add_Context (Cross_Contexts, Cross_Context);
      Cross_Unit := CU.Build
        (Cross_Contexts, Closure, Lookup, Assignments, Returns, Expressions,
         Flow, Tasking, Tagged_Model, Instances);

      declare
         Model : constant WD.Wide_Semantic_Diagnostic_Model :=
           WD.Build
             (Assignments, Returns, Expressions, Flow, Tasking, Tagged_Model,
              Instances, Cross_Unit);
         Static_Rows : constant WD.Wide_Semantic_Diagnostic_Result_Set :=
           WD.Rows_For_Kind (Model, WD.Wide_Semantic_Diagnostic_Static_Range_Error);
         Cross_Rows : constant WD.Wide_Semantic_Diagnostic_Result_Set :=
           WD.Rows_For_Family (Model, WD.Wide_Semantic_Diagnostic_Cross_Unit);
      begin
         Assert (WD.Diagnostic_Count (Model) >= 7,
                 "wide diagnostic bridge should expose all semantic legality families");
         Assert (WD.Assignment_Count (Model) = 1,
                 "assignment legality error should be surfaced");
         Assert (WD.Return_Count (Model) = 1,
                 "return legality error should be surfaced");
         Assert (WD.Expression_Count (Model) = 1,
                 "conversion/access/aggregate legality error should be surfaced");
         Assert (WD.Control_Flow_Count (Model) = 1,
                 "control-flow legality error should be surfaced");
         Assert (WD.Tasking_Protected_Count (Model) = 1,
                 "tasking/protected legality error should be surfaced");
         Assert (WD.Tagged_Derived_Count (Model) = 1,
                 "tagged/derived legality error should be surfaced");
         Assert (WD.Generic_Instance_Count (Model) >= 1,
                 "generic-instance legality error should be surfaced");
         Assert (WD.Cross_Unit_Count (Model) >= 1,
                 "cross-unit semantic closure error should be surfaced");
         Assert (WD.Result_Count (Static_Rows) >= 1,
                 "static range diagnostics should be queryable");
         Assert (WD.Result_Count (Cross_Rows) >= 1,
                 "family result sets should be queryable");
         Assert (WD.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (102)).Assignment_Status =
                   AL.Assignment_Legality_Assignment_To_Constant,
                 "node lookup should preserve assignment status");
         Assert (WD.Error_Count (Model) > 0,
                 "semantic legality failures should produce errors");
         Assert (WD.Fingerprint (Model) /= 0,
                 "wide diagnostic model should have a deterministic fingerprint");
      end;
   end Build_Wide_Diagnostics_From_Semantic_Legality_Errors;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Build_Wide_Diagnostics_From_Semantic_Legality_Errors'Access,
         "wide semantic legality diagnostics from compiler-grade legality layers");
   end Register_Tests;

end Test_Ada_Wide_Semantic_Legality_Diagnostics;
