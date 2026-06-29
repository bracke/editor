with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Generic_Formal_AST_Repair_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Formal_AST_Repair_Legality is

   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;
   use type Audit.Coverage_Item_Id;
   use type Audit.Ada_Construct_Kind;
   use type Audit.Semantic_Consumer_Family;
   use type Audit.Coverage_Status;
   use type Audit.Coverage_Context_Info;
   use type Audit.Coverage_Info;
   use type Audit.Coverage_Context_Model;
   use type Audit.Coverage_Result_Set;
   use type Audit.Coverage_Model;
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
   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   use type Repair.Repair_Item_Id;
   use type Repair.Repair_Kind;
   use type Repair.Repair_Status;
   use type Repair.Repair_Context_Info;
   use type Repair.Repair_Info;
   use type Repair.Repair_Context_Model;
   use type Repair.Repair_Model;
   use type Repair.Repair_Result_Set;
   package Formal_AST renames Editor.Ada_Generic_Formal_AST_Repair_Legality;
   use type Formal_AST.Generic_Formal_AST_Repair_Row_Id;
   use type Formal_AST.Generic_Formal_AST_Construct_Kind;
   use type Formal_AST.Generic_Formal_AST_Repair_Status;
   use type Formal_AST.Generic_Formal_AST_Repair_Context_Info;
   use type Formal_AST.Generic_Formal_AST_Repair_Info;
   use type Formal_AST.Generic_Formal_AST_Repair_Context_Model;
   use type Formal_AST.Generic_Formal_AST_Repair_Model;
   use type Formal_AST.Generic_Formal_AST_Repair_Result_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Generic_Formal_AST_Repair_Legality");
   end Name;

   function Complete_Context
     (Id        : Formal_AST.Generic_Formal_AST_Repair_Row_Id;
      Construct : Formal_AST.Generic_Formal_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Formal_AST.Generic_Formal_AST_Repair_Context_Info is
      C : Formal_AST.Generic_Formal_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Generic_Contracts;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Generic_Formal");
      C.Normalized_Construct_Name := To_Unbounded_String ("generic_formal");
      C.Parser_Node_Repaired := True;
      C.Structural_AST_Repaired := True;
      C.Source_Span_Repaired := True;
      C.Name_Binding_Repaired := True;
      C.Type_Metadata_Repaired := True;
      C.Staticness_Metadata_Repaired := True;
      C.Contract_Metadata_Repaired := True;
      C.Cross_Unit_Metadata_Repaired := True;
      C.Consumer_Repaired := True;
      C.Consumer_Integrated := True;
      C.Token_Only_Replaced := True;
      C.Degradation_Replaced := True;
      C.Source_Fingerprint := Natural (Id) * 1174;
      return C;
   end Complete_Context;

   procedure Add_Repair
     (Contexts  : in out Repair.Repair_Context_Model;
      Node      : Editor.Ada_Syntax_Tree.Node_Id;
      Construct : Audit.Ada_Construct_Kind;
      Kind      : Repair.Repair_Kind;
      Complete  : Boolean := True) is
      C : Repair.Repair_Context_Info;
   begin
      C.Kind := Kind;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Generic_Contracts;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Generic_Formal");
      C.Normalized_Construct_Name := To_Unbounded_String ("generic_formal");
      C.Before_Coverage := Audit.Coverage_Parser_Node_Missing;
      C.Before_Gate := Gates.Gate_Parser_Node_Missing;
      C.Parser_Node_Repaired := Complete;
      C.Structural_AST_Repaired := Complete;
      C.Source_Span_Repaired := Complete;
      C.Name_Binding_Repaired := Complete;
      C.Type_Metadata_Repaired := Complete;
      C.Staticness_Metadata_Repaired := Complete;
      C.Contract_Metadata_Repaired := Complete;
      C.Cross_Unit_Metadata_Repaired := Complete;
      C.Consumer_Repaired := Complete;
      C.Consumer_Integrated := Complete;
      C.Token_Only_Replaced := Complete;
      C.Degradation_Replaced := Complete;
      C.Source_Fingerprint := Natural (Node) + Repair.Repair_Kind'Pos (Kind);
      Repair.Add_Context (Contexts, C);
   end Add_Repair;

   procedure Complete_Generic_Formal_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Formal_AST.Generic_Formal_AST_Repair_Context_Model;
   begin
      Formal_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            Formal_AST.Generic_Formal_AST_Object,
            Editor.Ada_Syntax_Tree.Node_Id (117401)));
      Formal_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            Formal_AST.Generic_Formal_AST_Type,
            Editor.Ada_Syntax_Tree.Node_Id (117402)));
      Formal_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            Formal_AST.Generic_Formal_AST_Subprogram,
            Editor.Ada_Syntax_Tree.Node_Id (117403)));
      Formal_AST.Add_Context
        (Contexts,
         Complete_Context
           (4,
            Formal_AST.Generic_Formal_AST_Package,
            Editor.Ada_Syntax_Tree.Node_Id (117404)));

      declare
         Model : constant Formal_AST.Generic_Formal_AST_Repair_Model :=
           Formal_AST.Build (Contexts);
      begin
         Assert (Formal_AST.Row_Count (Model) = 4,
                 "four generic formal AST repair rows expected");
         Assert (Formal_AST.Accepted_Count (Model) = 4,
                 "complete generic formal repairs should be accepted");
         Assert (Formal_AST.Blocker_Count (Model) = 0,
                 "complete generic formal repairs should not block");
         Assert
           (Formal_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117401)).Status =
            Formal_AST.Generic_Formal_AST_Legal_Object_Repaired,
            "formal object repair should be accepted");
         Assert
           (Formal_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117404)).Status =
            Formal_AST.Generic_Formal_AST_Legal_Package_Repaired,
            "formal package repair should be accepted");
         Assert (Formal_AST.Fingerprint (Model) /= 0,
                 "generic formal AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Generic_Formal_Repairs_Are_Accepted;

   procedure Required_Generic_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Formal_AST.Generic_Formal_AST_Repair_Context_Model;
      Formal_Object : Formal_AST.Generic_Formal_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Formal_AST.Generic_Formal_AST_Object,
           Editor.Ada_Syntax_Tree.Node_Id (117421));
      Formal_Subprogram : Formal_AST.Generic_Formal_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           Formal_AST.Generic_Formal_AST_Subprogram,
           Editor.Ada_Syntax_Tree.Node_Id (117422));
   begin
      Formal_Object.Staticness_Metadata_Repaired := False;
      Formal_Subprogram.Contract_Metadata_Repaired := False;
      Formal_AST.Add_Context (Contexts, Formal_Object);
      Formal_AST.Add_Context (Contexts, Formal_Subprogram);

      declare
         Model : constant Formal_AST.Generic_Formal_AST_Repair_Model :=
           Formal_AST.Build (Contexts);
      begin
         Assert
           (Formal_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117421)).Status =
            Formal_AST.Generic_Formal_AST_Staticness_Metadata_Still_Missing,
            "formal object repair should require staticness metadata");
         Assert
           (Formal_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117422)).Status =
            Formal_AST.Generic_Formal_AST_Contract_Metadata_Still_Missing,
            "formal subprogram repair should require contract metadata");
         Assert (Formal_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain generic formal blockers");
      end;
   end Required_Generic_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Generic_Formal_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117441);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117442);
   begin
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Structural_AST);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Source_Span);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Name_Binding_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Type_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Contract_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Cross_Unit_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Semantic_Consumer);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Consumer_Integration);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Token_Only_Replacement);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Generic_Formal_Subprogram, Repair.Repair_Degradation_Replacement);

      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Generic_Formal_Type, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Generic_Formal_Type, Repair.Repair_Structural_AST, False);

      declare
         Repairs : constant Repair.Repair_Model := Repair.Build (Repair_Contexts);
         Model : constant Formal_AST.Generic_Formal_AST_Repair_Model :=
           Formal_AST.Build_From_Repairs (Repairs);
      begin
         Assert (Formal_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by generic formal node");
         Assert
           (Formal_AST.First_For_Node (Model, Complete_Node).Status =
            Formal_AST.Generic_Formal_AST_Legal_Subprogram_Repaired,
            "complete formal-subprogram repairs should clear the AST gate");
         Assert
           (Formal_AST.First_For_Node (Model, Blocked_Node).Status =
            Formal_AST.Generic_Formal_AST_Multiple_Repair_Blockers,
            "partial formal-type repairs should remain blocked");
         Assert (Formal_AST.Accepted_Count (Model) = 1,
                 "one aggregated generic formal repair should be accepted");
         Assert (Formal_AST.Blocker_Count (Model) = 1,
                 "one aggregated generic formal repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Generic_Formal_Node;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Generic_Formal_Repairs_Are_Accepted'Access,
         "complete generic formal repairs are accepted");
      Register_Routine
        (T,
         Required_Generic_Metadata_Remains_Blocker'Access,
         "required generic formal metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Generic_Formal_Node'Access,
         "repair rows aggregate into concrete generic formal AST repair facts");
   end Register_Tests;

end Test_Ada_Generic_Formal_AST_Repair_Legality;
