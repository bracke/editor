with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Expression_Construct_AST_Repair_Legality;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Overload_RM_Edge_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Overload_Type_Edge_Precision_Legality_Pass1179 is

   package Expr_AST renames Editor.Ada_Expression_Construct_AST_Repair_Legality;
   use type Expr_AST.Expression_Construct_AST_Repair_Row_Id;
   use type Expr_AST.Expression_Construct_AST_Construct_Kind;
   use type Expr_AST.Expression_Construct_AST_Repair_Status;
   use type Expr_AST.Expression_Construct_AST_Repair_Context_Info;
   use type Expr_AST.Expression_Construct_AST_Repair_Info;
   use type Expr_AST.Expression_Construct_AST_Repair_Context_Model;
   use type Expr_AST.Expression_Construct_AST_Repair_Model;
   use type Expr_AST.Expression_Construct_AST_Repair_Result_Set;
   package Replay_CPD renames Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Replay_CPD.Generic_Replay_Representation_Row_Id;
   use type Replay_CPD.Generic_Replay_Representation_Context_Kind;
   use type Replay_CPD.Generic_Replay_Representation_Status;
   use type Replay_CPD.Generic_Replay_Representation_Context_Info;
   use type Replay_CPD.Generic_Replay_Representation_Info;
   use type Replay_CPD.Generic_Replay_Representation_Context_Model;
   use type Replay_CPD.Generic_Replay_Representation_Set;
   use type Replay_CPD.Generic_Replay_Representation_Model;
   package RM_Edge renames Editor.Ada_Overload_RM_Edge_Legality;
   use type RM_Edge.RM_Edge_Context_Id;
   use type RM_Edge.RM_Edge_Legality_Id;
   use type RM_Edge.RM_Edge_Context_Kind;
   use type RM_Edge.RM_Edge_Legality_Status;
   use type RM_Edge.RM_Edge_Context_Info;
   use type RM_Edge.RM_Edge_Legality_Info;
   use type RM_Edge.RM_Edge_Context_Model;
   use type RM_Edge.RM_Edge_Result_Set;
   use type RM_Edge.RM_Edge_Legality_Model;
   package OTE renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   use type OTE.Overload_Type_Edge_Row_Id;
   use type OTE.Overload_Type_Edge_Context_Kind;
   use type OTE.Overload_Type_Edge_Status;
   use type OTE.Overload_Type_Edge_Context_Info;
   use type OTE.Overload_Type_Edge_Info;
   use type OTE.Overload_Type_Edge_Context_Model;
   use type OTE.Overload_Type_Edge_Result_Set;
   use type OTE.Overload_Type_Edge_Model;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Overload_Type_Edge_Precision_Legality_Pass1179");
   end Name;

   function Complete_Context
     (Id   : OTE.Overload_Type_Edge_Row_Id;
      Kind : OTE.Overload_Type_Edge_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return OTE.Overload_Type_Edge_Context_Info is
      C : OTE.Overload_Type_Edge_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Designator := To_Unbounded_String ("Op");
      C.Target_Type_Name := To_Unbounded_String ("Target_Type");
      C.Expected_Type_Name := To_Unbounded_String ("Expected_Type");
      C.RM_Edge_Row := RM_Edge.RM_Edge_Legality_Id (Natural (Id));
      C.RM_Edge_Status := RM_Edge.RM_Edge_Legality_Legal_Access_Subprogram_Profile;
      C.Expression_AST_Row := Expr_AST.Expression_Construct_AST_Repair_Row_Id (Natural (Id));
      C.Expression_AST_Status := Expr_AST.Expression_Construct_AST_Legal_Reduction_Expression_Repaired;
      C.Generic_Replay_CPD_Row := Replay_CPD.Generic_Replay_Representation_Row_Id (Natural (Id));
      C.Generic_Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Legal_Body_Expression_Accepted;
      C.Candidate_Count := 1;
      C.Selected_Candidate_Count := 1;
      C.Source_Fingerprint := Natural (Id) * 1179;
      return C;
   end Complete_Context;

   procedure Accepted_Edges_Remain_Legal_With_Repair_And_Replay_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : OTE.Overload_Type_Edge_Context_Model;
      Access_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (1,
           OTE.Overload_Type_Edge_Access_To_Subprogram,
           Editor.Ada_Syntax_Tree.Node_Id (117901));
      Root_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (2,
           OTE.Overload_Type_Edge_Root_Numeric,
           Editor.Ada_Syntax_Tree.Node_Id (117902));
      Generic_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (3,
           OTE.Overload_Type_Edge_Generic_Formal_Subprogram,
           Editor.Ada_Syntax_Tree.Node_Id (117903));
   begin
      Root_Context.RM_Edge_Status := RM_Edge.RM_Edge_Legality_Legal_Root_Numeric_Preferred;
      Generic_Context.RM_Edge_Status := RM_Edge.RM_Edge_Legality_Legal_Generic_Formal_Subprogram;

      OTE.Add_Context (Contexts, Access_Context);
      OTE.Add_Context (Contexts, Root_Context);
      OTE.Add_Context (Contexts, Generic_Context);

      declare
         Model : constant OTE.Overload_Type_Edge_Model := OTE.Build (Contexts);
      begin
         Assert (OTE.Row_Count (Model) = 3, "three overload/type edge rows expected");
         Assert (OTE.Legal_Count (Model) = 3, "accepted overload/type edge rows should remain legal");
         Assert (OTE.Error_Count (Model) = 0, "accepted overload/type edge rows should not emit errors");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117901)).Status =
            OTE.Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted,
            "access-to-subprogram edge should remain accepted");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117902)).Status =
            OTE.Overload_Type_Edge_Legal_Root_Numeric_Preferred,
            "root numeric edge should remain accepted");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117903)).Status =
            OTE.Overload_Type_Edge_Legal_Generic_Formal_Subprogram_Accepted,
            "generic formal subprogram edge should remain accepted");
         Assert (OTE.Fingerprint (Model) /= 0, "model must expose deterministic fingerprint");
      end;
   end Accepted_Edges_Remain_Legal_With_Repair_And_Replay_Evidence;

   procedure RM_Ambiguities_Are_Preserved_As_Type_Edge_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : OTE.Overload_Type_Edge_Context_Model;
      Fixed_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (1,
           OTE.Overload_Type_Edge_Universal_Fixed,
           Editor.Ada_Syntax_Tree.Node_Id (117921));
      Dispatch_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (2,
           OTE.Overload_Type_Edge_Dispatching_Operation,
           Editor.Ada_Syntax_Tree.Node_Id (117922));
   begin
      Fixed_Context.RM_Edge_Status := RM_Edge.RM_Edge_Legality_Universal_Fixed_Ambiguous;
      Dispatch_Context.RM_Edge_Status := RM_Edge.RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous;

      OTE.Add_Context (Contexts, Fixed_Context);
      OTE.Add_Context (Contexts, Dispatch_Context);

      declare
         Model : constant OTE.Overload_Type_Edge_Model := OTE.Build (Contexts);
      begin
         Assert (OTE.Ambiguous_Count (Model) = 2, "RM ambiguity blockers should be counted");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117921)).Status =
            OTE.Overload_Type_Edge_Universal_Fixed_Ambiguous,
            "universal fixed ambiguity should be preserved");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117922)).Status =
            OTE.Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous,
            "dispatching/nondispatching ambiguity should be preserved");
      end;
   end RM_Ambiguities_Are_Preserved_As_Type_Edge_Errors;

   procedure Missing_Repair_And_Replay_Evidence_Block_Confident_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : OTE.Overload_Type_Edge_Context_Model;
      AST_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (1,
           OTE.Overload_Type_Edge_Access_To_Subprogram,
           Editor.Ada_Syntax_Tree.Node_Id (117941));
      Replay_Context : OTE.Overload_Type_Edge_Context_Info :=
        Complete_Context
          (2,
           OTE.Overload_Type_Edge_Generic_Formal_Subprogram,
           Editor.Ada_Syntax_Tree.Node_Id (117942));
   begin
      AST_Context.Expression_AST_Status := Expr_AST.Expression_Construct_AST_Not_Checked;
      Replay_Context.Generic_Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Not_Checked;
      Replay_Context.RM_Edge_Status := RM_Edge.RM_Edge_Legality_Legal_Generic_Formal_Subprogram;

      OTE.Add_Context (Contexts, AST_Context);
      OTE.Add_Context (Contexts, Replay_Context);

      declare
         Model : constant OTE.Overload_Type_Edge_Model := OTE.Build (Contexts);
      begin
         Assert (OTE.Legal_Count (Model) = 0, "missing evidence should block confident legal edges");
         Assert (OTE.AST_Blocker_Count (Model) = 1, "missing expression AST repair should be counted");
         Assert (OTE.Generic_Replay_Blocker_Count (Model) = 1, "missing generic replay CPD should be counted");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117941)).Status =
            OTE.Overload_Type_Edge_Missing_Expression_AST_Repair,
            "expression AST repair should be required");
         Assert
           (OTE.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117942)).Status =
            OTE.Overload_Type_Edge_Missing_Generic_Replay_CPD_Row,
            "generic replay CPD evidence should be required");
      end;
   end Missing_Repair_And_Replay_Evidence_Block_Confident_Edges;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Edges_Remain_Legal_With_Repair_And_Replay_Evidence'Access,
         "accepted overload/type edges require repaired expression and replay evidence");
      Register_Routine
        (T,
         RM_Ambiguities_Are_Preserved_As_Type_Edge_Errors'Access,
         "RM overload ambiguities are preserved as type-edge errors");
      Register_Routine
        (T,
         Missing_Repair_And_Replay_Evidence_Block_Confident_Edges'Access,
         "missing expression repair or generic replay evidence blocks confident edges");
   end Register_Tests;

end Test_Ada_Overload_Type_Edge_Precision_Legality_Pass1179;
