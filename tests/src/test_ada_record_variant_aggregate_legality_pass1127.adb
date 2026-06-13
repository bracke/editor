with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Record_Variant_Aggregate_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Record_Variant_Aggregate_Legality_Pass1127 is

   package RA renames Editor.Ada_Record_Variant_Aggregate_Legality;
   use type RA.Semantic_Legality_Status;
   use type RA.Predicate_Use_Legality_Status;
   use type RA.Representation_Integration_Status;
   use type RA.Record_Aggregate_Context_Id;
   use type RA.Record_Aggregate_Legality_Id;
   use type RA.Record_Aggregate_Context_Kind;
   use type RA.Record_Aggregate_Legality_Status;
   use type RA.Record_Aggregate_Context_Info;
   use type RA.Record_Aggregate_Legality_Info;
   use type RA.Record_Aggregate_Context_Model;
   use type RA.Record_Aggregate_Result_Set;
   use type RA.Record_Aggregate_Legality_Model;
   package CA renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type CA.Semantic_Context_Id;
   use type CA.Semantic_Legality_Id;
   use type CA.Semantic_Context_Kind;
   use type CA.Access_Kind;
   use type CA.Semantic_Legality_Status;
   use type CA.Semantic_Context_Info;
   use type CA.Semantic_Legality_Info;
   use type CA.Semantic_Context_Model;
   use type CA.Semantic_Legality_Result_Set;
   use type CA.Semantic_Legality_Model;
   package PI renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   use type PI.Predicate_Policy;
   use type PI.Static_Legality_Status;
   use type PI.Assignment_Legality_Status;
   use type PI.Return_Legality_Status;
   use type PI.Semantic_Legality_Status;
   use type PI.Overload_Legality_Status;
   use type PI.Instance_Legality_Status;
   use type PI.Predicate_Use_Context_Id;
   use type PI.Predicate_Use_Legality_Id;
   use type PI.Predicate_Use_Context_Kind;
   use type PI.Invariant_Policy;
   use type PI.Use_Site_Check_Point;
   use type PI.Predicate_Use_Legality_Status;
   use type PI.Predicate_Use_Context_Info;
   use type PI.Predicate_Use_Legality_Info;
   use type PI.Predicate_Use_Context_Model;
   use type PI.Predicate_Use_Result_Set;
   use type PI.Predicate_Use_Legality_Model;
   package RI renames Editor.Ada_Representation_Layout_Stream_Integration_Legality;
   use type RI.Representation_Status;
   use type RI.Exact_Layout_Status;
   use type RI.Stream_Status;
   use type RI.Generic_Instance_Status;
   use type RI.Accessibility_Status;
   use type RI.Staticness_Status;
   use type RI.Completion_Status;
   use type RI.Contract_Status;
   use type RI.Exception_Status;
   use type RI.Representation_Integration_Context_Id;
   use type RI.Representation_Integration_Id;
   use type RI.Representation_Integration_Context_Kind;
   use type RI.Layout_State;
   use type RI.Stream_State;
   use type RI.Representation_Integration_Status;
   use type RI.Representation_Integration_Context_Info;
   use type RI.Representation_Integration_Info;
   use type RI.Representation_Integration_Context_Model;
   use type RI.Representation_Integration_Result_Set;
   use type RI.Representation_Integration_Model;

   use type RA.Record_Aggregate_Legality_Status;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Record_Variant_Aggregate_Legality_Pass1127");
   end Name;

   procedure Build_Record_Variant_Model
     (Contexts : in out RA.Record_Aggregate_Context_Model)
   is
      C : RA.Record_Aggregate_Context_Info;
   begin
      C.Id := 1;
      C.Kind := RA.Record_Aggregate_Context_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11271);
      C.Aggregate_Node := Editor.Ada_Syntax_Tree.Node_Id (11271);
      C.Type_Name := To_Unbounded_String ("Packet_Header");
      C.Component_Count := 3;
      C.Expected_Component_Count := 3;
      C.Aggregate_Status := CA.Semantic_Legality_Legal_Aggregate;
      C.Predicate_Status := PI.Predicate_Use_Legality_Legal_Static_Range_And_Predicate;
      C.Representation_Status := RI.Representation_Integration_Legal_Record_Layout;
      RA.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := RA.Record_Aggregate_Context_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11272);
      C.Type_Name := To_Unbounded_String ("Missing_Component_Record");
      C.Component_Count := 1;
      C.Expected_Component_Count := 2;
      C.Aggregate_Status := CA.Semantic_Legality_Legal_Aggregate;
      C.Predicate_Status := PI.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check;
      C.Representation_Status := RI.Representation_Integration_Legal_Record_Layout;
      RA.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := RA.Record_Aggregate_Context_Discriminant_Constraint;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11273);
      C.Type_Name := To_Unbounded_String ("Unconstrained_Message");
      C.Type_Is_Unconstrained := True;
      C.Has_Defaulted_Discriminants := False;
      C.Discriminant_Count := 0;
      C.Expected_Discriminant_Count := 1;
      C.Aggregate_Status := CA.Semantic_Legality_Legal_Aggregate;
      C.Representation_Status := RI.Representation_Integration_Legal_Record_Layout;
      RA.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := RA.Record_Aggregate_Context_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11274);
      C.Type_Name := To_Unbounded_String ("Variant_Message");
      C.Variant_Choice_Count := 1;
      C.Expected_Variant_Choice_Count := 3;
      C.Variant_Coverage_Complete := False;
      C.Aggregate_Status := CA.Semantic_Legality_Legal_Aggregate;
      C.Representation_Status := RI.Representation_Integration_Legal_Record_Layout;
      RA.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := RA.Record_Aggregate_Context_Representation_Layout_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11275);
      C.Type_Name := To_Unbounded_String ("Wire_Record");
      C.Aggregate_Status := CA.Semantic_Legality_Legal_Aggregate;
      C.Representation_Status := RI.Representation_Integration_Variant_Layout_Overlap;
      RA.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := RA.Record_Aggregate_Context_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11276);
      C.Type_Name := To_Unbounded_String ("Invariant_Record");
      C.Component_Count := 2;
      C.Expected_Component_Count := 2;
      C.Aggregate_Status := CA.Semantic_Legality_Legal_Aggregate;
      C.Predicate_Status := PI.Predicate_Use_Legality_Invariant_Violation;
      C.Representation_Status := RI.Representation_Integration_Legal_Record_Layout;
      RA.Add_Context (Contexts, C);
   end Build_Record_Variant_Model;

   procedure Classifies_Record_Variant_Discriminant_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : RA.Record_Aggregate_Context_Model;
   begin
      Build_Record_Variant_Model (Contexts);

      declare
         Model : constant RA.Record_Aggregate_Legality_Model := RA.Build (Contexts);
      begin
         Assert (RA.Legality_Count (Model) = 6,
                 "each record/variant aggregate context should produce a legality row");
         Assert (RA.Legal_Count (Model) = 1,
                 "one complete record aggregate should be legal");
         Assert (RA.Error_Count (Model) = 5,
                 "five contexts should expose aggregate/discriminant/variant/linked errors");
         Assert (RA.Variant_Error_Count (Model) = 2,
                 "variant coverage and layout errors should be counted separately");
         Assert (RA.Discriminant_Error_Count (Model) = 1,
                 "unconstrained aggregate without discriminants should be a discriminant error");
         Assert (RA.Linked_Error_Count (Model) = 1,
                 "predicate/invariant use-site blocker should remain linked");
         Assert (RA.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11271)).Status =
                 RA.Record_Aggregate_Legality_Legal_Record_Aggregate,
                 "complete record aggregate should remain legal");
         Assert (RA.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11272)).Status =
                 RA.Record_Aggregate_Legality_Missing_Component,
                 "missing component should be detected at the aggregate closure layer");
         Assert (RA.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11273)).Status =
                 RA.Record_Aggregate_Legality_Unconstrained_Without_Discriminants,
                 "unconstrained records without discriminants should be rejected");
         Assert (RA.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11275)).Status =
                 RA.Record_Aggregate_Legality_Variant_Layout_Overlap,
                 "representation variant layout overlap should feed aggregate legality");
         Assert (RA.Count_Status
                   (Model, RA.Record_Aggregate_Legality_Linked_Predicate_Invariant_Error) = 1,
                 "predicate/invariant failures should be exposed as linked aggregate blockers");
      end;
   end Classifies_Record_Variant_Discriminant_Closure;

   procedure Lookups_And_Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty    : RA.Record_Aggregate_Context_Model;
      Contexts : RA.Record_Aggregate_Context_Model;
   begin
      declare
         Model : constant RA.Record_Aggregate_Legality_Model := RA.Build (Empty);
      begin
         Assert (RA.Legality_Count (Model) = 0,
                 "empty record aggregate closure input should produce no rows");
         Assert (not RA.Has_Legality
                   (RA.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (1))),
                 "missing node lookup should return no legality row");
      end;

      Build_Record_Variant_Model (Contexts);
      declare
         Model : constant RA.Record_Aggregate_Legality_Model := RA.Build (Contexts);
         Rows  : constant RA.Record_Aggregate_Result_Set :=
           RA.Rows_For_Type (Model, "Packet_Header");
      begin
         Assert (RA.Result_Count (Rows) = 1,
                 "type-name lookup should preserve aggregate identity");
         Assert (RA.Result_At (Rows, 1).Status =
                 RA.Record_Aggregate_Legality_Legal_Record_Aggregate,
                 "type-name lookup should return the expected legal aggregate row");
      end;
   end Lookups_And_Empty_Inputs_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Classifies_Record_Variant_Discriminant_Closure'Access,
         "Pass1127 connects record, variant, discriminant, predicate, and layout legality");
      Register_Routine
        (T, Lookups_And_Empty_Inputs_Are_Deterministic'Access,
         "Pass1127 keeps aggregate closure lookups deterministic");
   end Register_Tests;

end Test_Ada_Record_Variant_Aggregate_Legality_Pass1127;
