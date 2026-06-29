with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Lookup_Integration;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Expression_Types;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;

package body Test_Ada_Cross_Unit_Semantic_Closure is

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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Cross_Unit_Semantic_Closure");
   end Name;

   function Empty_Model (Contexts : CU.Cross_Unit_Semantic_Context_Model)
      return CU.Cross_Unit_Semantic_Model
   is
      Closure     : CL.Cross_Unit_Closure_Model;
      Lookup      : LU.Cross_Unit_Lookup_Model;
      Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Flow        : FL.Flow_Legality_Model;
      Tasking     : TL.Tasking_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model;
      Instances   : GI.Instance_Legality_Model;
   begin
      return CU.Build
        (Contexts, Closure, Lookup, Assignments, Returns, Expressions,
         Flow, Tasking, Tagged_Model, Instances);
   end Empty_Model;

   procedure Test_Dependency_Lookup_And_View_Classification
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CU.Cross_Unit_Semantic_Context_Model;
      Context  : CU.Cross_Unit_Semantic_Context_Info;
   begin
      Context.Id := 1;
      Context.Kind := CU.Cross_Unit_Semantic_Visibility;
      Context.Source_Unit_Name := To_Unbounded_String ("Client");
      Context.Target_Unit_Name := To_Unbounded_String ("Pkg");
      Context.Requires_Cross_Unit_Dependency := True;
      Context.Dependency_Status := CL.Cross_Unit_Link_Resolved;
      CU.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 2;
      Context.Kind := CU.Cross_Unit_Semantic_Assignment;
      Context.Source_Unit_Name := To_Unbounded_String ("Client");
      Context.Target_Unit_Name := To_Unbounded_String ("Missing.Pkg");
      Context.Requires_Cross_Unit_Dependency := True;
      Context.Dependency_Status := CL.Cross_Unit_Link_Missing;
      CU.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 3;
      Context.Kind := CU.Cross_Unit_Semantic_Expression;
      Context.Source_Unit_Name := To_Unbounded_String ("Client");
      Context.Lookup_Name := To_Unbounded_String ("Hidden_T");
      Context.Requires_Cross_Unit_Lookup := True;
      Context.Lookup_Status := LU.Cross_Unit_Lookup_Private_View;
      CU.Add_Context (Contexts, Context);

      declare
         Model : constant CU.Cross_Unit_Semantic_Model := Empty_Model (Contexts);
         Source_Rows : constant CU.Cross_Unit_Semantic_Result_Set :=
           CU.Rows_For_Source_Unit (Model, To_Unbounded_String ("client"));
         Lookup_Rows : constant CU.Cross_Unit_Semantic_Result_Set :=
           CU.Rows_For_Lookup_Name (Model, To_Unbounded_String ("hidden_t"));
      begin
         Assert (CU.Semantic_Count (Model) = 3,
                 "three cross-unit semantic rows expected");
         Assert (CU.Closed_Count (Model) = 1,
                 "resolved dependency should be closed");
         Assert (CU.Dependency_Error_Count (Model) = 1,
                 "missing dependency should be counted");
         Assert (CU.Private_View_Barrier_Count (Model) = 1,
                 "private lookup barrier should be counted");
         Assert (CU.Result_Count (Source_Rows) = 3,
                 "source unit lookup should normalize names");
         Assert (CU.Result_Count (Lookup_Rows) = 1,
                 "lookup-name helper should normalize names");
         Assert (CU.First_For_Context (Model, 2).Status =
                   CU.Cross_Unit_Semantic_Missing_Dependency,
                 "missing dependency should classify before linked checks");
         Assert (CU.Fingerprint (Model) /= 0,
                 "model fingerprint should be deterministic and non-zero");
      end;
   end Test_Dependency_Lookup_And_View_Classification;

   procedure Test_Linked_Semantic_Layer_Classification
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Assignment_Contexts : AL.Assignment_Context_Model;
      Assignment_Context  : AL.Assignment_Context_Info;
      Expressions_For_Assignment : ET.Expression_Type_Model;
      Assignments : AL.Assignment_Legality_Model;
      Contexts : CU.Cross_Unit_Semantic_Context_Model;
      Context  : CU.Cross_Unit_Semantic_Context_Info;
      Closure     : CL.Cross_Unit_Closure_Model;
      Lookup      : LU.Cross_Unit_Lookup_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Flow        : FL.Flow_Legality_Model;
      Tasking     : TL.Tasking_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model;
      Instances   : GI.Instance_Legality_Model;
   begin
      Assignment_Context.Id := 7;
      Assignment_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Assignment_Context.Target_Mode := AL.Assignment_Target_Constant;
      Assignment_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Source_Subtype := To_Unbounded_String ("Integer");
      AL.Add_Context (Assignment_Contexts, Assignment_Context);
      Assignments := AL.Build (Assignment_Contexts, Expressions_For_Assignment);

      Context.Id := 10;
      Context.Kind := CU.Cross_Unit_Semantic_Assignment;
      Context.Source_Unit_Name := To_Unbounded_String ("Client");
      Context.Target_Unit_Name := To_Unbounded_String ("Pkg");
      Context.Requires_Cross_Unit_Dependency := True;
      Context.Dependency_Status := CL.Cross_Unit_Link_Resolved;
      Context.Linked_Assignment := 7;
      CU.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 20;
      Context.Kind := CU.Cross_Unit_Semantic_Visibility;
      Context.Source_Unit_Name := To_Unbounded_String ("Client");
      Context.Lookup_Name := To_Unbounded_String ("Visible_Op");
      Context.Requires_Cross_Unit_Lookup := True;
      Context.Lookup_Status := LU.Cross_Unit_Lookup_With_Visible;
      CU.Add_Context (Contexts, Context);

      declare
         Model : constant CU.Cross_Unit_Semantic_Model :=
           CU.Build
             (Contexts, Closure, Lookup, Assignments, Returns, Expressions,
              Flow, Tasking, Tagged_Model, Instances);
      begin
         Assert (CU.Semantic_Count (Model) = 2,
                 "two cross-unit semantic rows expected");
         Assert (CU.Linked_Semantic_Error_Count (Model) = 1,
                 "assignment legality error should block closure");
         Assert (CU.Cross_Unit_Visible_Count (Model) = 1,
                 "with-visible lookup should be counted");
         Assert (CU.First_For_Context (Model, 10).Status =
                   CU.Cross_Unit_Semantic_Assignment_Error,
                 "linked assignment error should be classified");
         Assert (CU.First_For_Context (Model, 10).Linked_Assignment_Status =
                   AL.Assignment_Legality_Assignment_To_Constant,
                 "linked assignment status should be preserved");
         Assert (CU.Count_Status
                   (Model, CU.Cross_Unit_Semantic_With_Visible) = 1,
                 "visible lookup status should be countable");
      end;
   end Test_Linked_Semantic_Layer_Classification;

   procedure Test_Local_Context_Collector_From_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Assignment_Contexts : AL.Assignment_Context_Model;
      Assignment_Context  : AL.Assignment_Context_Info;
      Expressions_For_Assignment : ET.Expression_Type_Model;
      Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Flow        : FL.Flow_Legality_Model;
      Tasking     : TL.Tasking_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model;
      Instances   : GI.Instance_Legality_Model;
      Closure     : CL.Cross_Unit_Closure_Model;
      Lookup      : LU.Cross_Unit_Lookup_Model;
   begin
      Assignment_Context.Id := 11;
      Assignment_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Assignment_Context.Target_Mode := AL.Assignment_Target_Constant;
      Assignment_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Source_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Start_Line := 7;
      Assignment_Context.End_Line := 7;
      AL.Add_Context (Assignment_Contexts, Assignment_Context);
      Assignments := AL.Build (Assignment_Contexts, Expressions_For_Assignment);

      declare
         Contexts : constant CU.Cross_Unit_Semantic_Context_Model :=
           CU.Build_Local_Contexts_From_Legality
             ("client.adb", Assignments, Returns, Expressions, Flow, Tasking,
              Tagged_Model, Instances);
         Model : constant CU.Cross_Unit_Semantic_Model :=
           CU.Build
             (Contexts, Closure, Lookup, Assignments, Returns, Expressions,
              Flow, Tasking, Tagged_Model, Instances);
         Rows : constant CU.Cross_Unit_Semantic_Result_Set :=
           CU.Rows_For_Source_Unit (Model, To_Unbounded_String ("CLIENT.ADB"));
         First : constant CU.Cross_Unit_Semantic_Info :=
           CU.Semantic_At (Model, 1);
      begin
         Assert (CU.Context_Count (Contexts) = 1,
                 "local collector should project assignment legality rows");
         Assert (CU.Result_Count (Rows) = 1,
                 "local collector should preserve normalized source unit names");
         Assert (First.Kind = CU.Cross_Unit_Semantic_Assignment
                 and then First.Status = CU.Cross_Unit_Semantic_Assignment_Error
                 and then First.Linked_Assignment_Status =
                   AL.Assignment_Legality_Assignment_To_Constant
                 and then First.Start_Line = 7,
                 "local collector should preserve linked assignment status and span");
         Assert (CU.Fingerprint (Model) /= 0,
                 "local collector output should fingerprint through semantic closure");
      end;
   end Test_Local_Context_Collector_From_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Dependency_Lookup_And_View_Classification'Access,
         "cross-unit dependency lookup and view classification");
      Register_Routine
        (T, Test_Linked_Semantic_Layer_Classification'Access,
         "linked semantic legality classification");
      Register_Routine
        (T, Test_Local_Context_Collector_From_Legality'Access,
         "local semantic legality collector");
   end Register_Tests;

end Test_Ada_Cross_Unit_Semantic_Closure;
