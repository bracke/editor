with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Discriminant_Variant_AST_Repair_Legality is

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
   package Disc_AST renames Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Row_Id;
   use type Disc_AST.Discriminant_Variant_AST_Construct_Kind;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Status;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Context_Info;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Info;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Context_Model;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Model;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Result_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Discriminant_Variant_AST_Repair_Legality");
   end Name;

   function Complete_Context
     (Id        : Disc_AST.Discriminant_Variant_AST_Repair_Row_Id;
      Construct : Disc_AST.Discriminant_Variant_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Disc_AST.Discriminant_Variant_AST_Repair_Context_Info is
      C : Disc_AST.Discriminant_Variant_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Record_Variant_Aggregate;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Discriminant_Variant");
      C.Normalized_Construct_Name := To_Unbounded_String ("discriminant_variant");
      C.Parser_Node_Repaired := True;
      C.Structural_AST_Repaired := True;
      C.Source_Span_Repaired := True;
      C.Name_Binding_Repaired := True;
      C.Type_Metadata_Repaired := True;
      C.Staticness_Metadata_Repaired := True;
      C.Contract_Metadata_Repaired := True;
      C.Flow_Metadata_Repaired := True;
      C.Representation_Metadata_Repaired := True;
      C.Cross_Unit_Metadata_Repaired := True;
      C.Consumer_Repaired := True;
      C.Consumer_Integrated := True;
      C.Token_Only_Replaced := True;
      C.Degradation_Replaced := True;
      C.Source_Fingerprint := Natural (Id) * 1177;
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
      C.Consumer := Audit.Consumer_Record_Variant_Aggregate;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Discriminant_Variant");
      C.Normalized_Construct_Name := To_Unbounded_String ("discriminant_variant");
      C.Before_Coverage := Audit.Coverage_Parser_Node_Missing;
      C.Before_Gate := Gates.Gate_Parser_Node_Missing;
      C.Parser_Node_Repaired := Complete;
      C.Structural_AST_Repaired := Complete;
      C.Source_Span_Repaired := Complete;
      C.Name_Binding_Repaired := Complete;
      C.Type_Metadata_Repaired := Complete;
      C.Staticness_Metadata_Repaired := Complete;
      C.Contract_Metadata_Repaired := Complete;
      C.Flow_Metadata_Repaired := Complete;
      C.Representation_Metadata_Repaired := Complete;
      C.Cross_Unit_Metadata_Repaired := Complete;
      C.Consumer_Repaired := Complete;
      C.Consumer_Integrated := Complete;
      C.Token_Only_Replaced := Complete;
      C.Degradation_Replaced := Complete;
      C.Source_Fingerprint := Natural (Node) + Repair.Repair_Kind'Pos (Kind);
      Repair.Add_Context (Contexts, C);
   end Add_Repair;

   procedure Complete_Discriminant_Variant_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Disc_AST.Discriminant_Variant_AST_Repair_Context_Model;
   begin
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            Disc_AST.Discriminant_Variant_AST_Discriminant_Specification,
            Editor.Ada_Syntax_Tree.Node_Id (117701)));
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            Disc_AST.Discriminant_Variant_AST_Variant_Part,
            Editor.Ada_Syntax_Tree.Node_Id (117702)));
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            Disc_AST.Discriminant_Variant_AST_Discriminant_Dependent_Aggregate,
            Editor.Ada_Syntax_Tree.Node_Id (117703)));
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (4,
            Disc_AST.Discriminant_Variant_AST_Private_Full_View,
            Editor.Ada_Syntax_Tree.Node_Id (117704)));

      declare
         Model : constant Disc_AST.Discriminant_Variant_AST_Repair_Model :=
           Disc_AST.Build (Contexts);
      begin
         Assert (Disc_AST.Row_Count (Model) = 4,
                 "four discriminant/variant AST repair rows expected");
         Assert (Disc_AST.Accepted_Count (Model) = 4,
                 "complete discriminant/variant repairs should be accepted");
         Assert (Disc_AST.Blocker_Count (Model) = 0,
                 "complete discriminant/variant repairs should not block");
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117701)).Status =
            Disc_AST.Discriminant_Variant_AST_Legal_Discriminant_Specification_Repaired,
            "discriminant specification repair should be accepted");
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117704)).Status =
            Disc_AST.Discriminant_Variant_AST_Legal_Private_Full_View_Repaired,
            "private/full-view repair should be accepted");
         Assert (Disc_AST.Fingerprint (Model) /= 0,
                 "discriminant/variant AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Discriminant_Variant_Repairs_Are_Accepted;

   procedure Required_Discriminant_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Disc_AST.Discriminant_Variant_AST_Repair_Context_Model;
      Discriminant_Specification : Disc_AST.Discriminant_Variant_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Disc_AST.Discriminant_Variant_AST_Discriminant_Specification,
           Editor.Ada_Syntax_Tree.Node_Id (117721));
      Dependent_Aggregate : Disc_AST.Discriminant_Variant_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           Disc_AST.Discriminant_Variant_AST_Discriminant_Dependent_Aggregate,
           Editor.Ada_Syntax_Tree.Node_Id (117722));
   begin
      Discriminant_Specification.Staticness_Metadata_Repaired := False;
      Dependent_Aggregate.Contract_Metadata_Repaired := False;
      Disc_AST.Add_Context (Contexts, Discriminant_Specification);
      Disc_AST.Add_Context (Contexts, Dependent_Aggregate);

      declare
         Model : constant Disc_AST.Discriminant_Variant_AST_Repair_Model :=
           Disc_AST.Build (Contexts);
      begin
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117721)).Status =
            Disc_AST.Discriminant_Variant_AST_Staticness_Metadata_Still_Missing,
            "discriminant specification repair should require staticness metadata");
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117722)).Status =
            Disc_AST.Discriminant_Variant_AST_Contract_Metadata_Still_Missing,
            "discriminant-dependent aggregate repair should require contract metadata");
         Assert (Disc_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain discriminant/variant blockers");
      end;
   end Required_Discriminant_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Discriminant_Variant_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117741);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117742);
      Construct : constant Audit.Ada_Construct_Kind :=
        Audit.Construct_Discriminant_Specification;
   begin
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Structural_AST);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Source_Span);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Name_Binding_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Type_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Staticness_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Contract_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Flow_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Representation_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Cross_Unit_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Semantic_Consumer);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Consumer_Integration);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Token_Only_Replacement);
      Add_Repair (Repair_Contexts, Complete_Node, Construct, Repair.Repair_Degradation_Replacement);

      Add_Repair (Repair_Contexts, Blocked_Node, Construct, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Blocked_Node, Construct, Repair.Repair_Structural_AST, False);

      declare
         Repairs : constant Repair.Repair_Model := Repair.Build (Repair_Contexts);
         Model : constant Disc_AST.Discriminant_Variant_AST_Repair_Model :=
           Disc_AST.Build_From_Repairs (Repairs);
      begin
         Assert (Disc_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by discriminant/variant node");
         Assert
           (Disc_AST.First_For_Node (Model, Complete_Node).Status =
            Disc_AST.Discriminant_Variant_AST_Legal_Discriminant_Specification_Repaired,
            "complete discriminant/variant repairs should clear the AST gate");
         Assert
           (Disc_AST.First_For_Node (Model, Blocked_Node).Status =
            Disc_AST.Discriminant_Variant_AST_Multiple_Repair_Blockers,
            "partial discriminant/variant repairs should remain blocked");
         Assert (Disc_AST.Accepted_Count (Model) = 1,
                 "one aggregated discriminant/variant repair should be accepted");
         Assert (Disc_AST.Blocker_Count (Model) = 1,
                 "one aggregated discriminant/variant repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Discriminant_Variant_Node;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Discriminant_Variant_Repairs_Are_Accepted'Access,
         "complete discriminant/variant repairs are accepted");
      Register_Routine
        (T,
         Required_Discriminant_Metadata_Remains_Blocker'Access,
         "required discriminant/variant metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Discriminant_Variant_Node'Access,
         "repair rows aggregate into concrete discriminant/variant AST repair facts");
   end Register_Tests;

end Test_Ada_Discriminant_Variant_AST_Repair_Legality;
