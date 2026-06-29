with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Expression_Construct_AST_Repair_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Expression_Construct_AST_Repair_Legality is

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
   package Disc_AST renames Editor.Ada_Expression_Construct_AST_Repair_Legality;
   use type Disc_AST.Expression_Construct_AST_Repair_Row_Id;
   use type Disc_AST.Expression_Construct_AST_Construct_Kind;
   use type Disc_AST.Expression_Construct_AST_Repair_Status;
   use type Disc_AST.Expression_Construct_AST_Repair_Context_Info;
   use type Disc_AST.Expression_Construct_AST_Repair_Info;
   use type Disc_AST.Expression_Construct_AST_Repair_Context_Model;
   use type Disc_AST.Expression_Construct_AST_Repair_Model;
   use type Disc_AST.Expression_Construct_AST_Repair_Result_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Expression_Construct_AST_Repair_Legality");
   end Name;

   function Complete_Context
     (Id        : Disc_AST.Expression_Construct_AST_Repair_Row_Id;
      Construct : Disc_AST.Expression_Construct_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Disc_AST.Expression_Construct_AST_Repair_Context_Info is
      C : Disc_AST.Expression_Construct_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Expression_Types;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Expression_Construct");
      C.Normalized_Construct_Name := To_Unbounded_String ("expression_construct");
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
      C.Source_Fingerprint := Natural (Id) * 1178;
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
      C.Consumer := Audit.Consumer_Expression_Types;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Expression_Construct");
      C.Normalized_Construct_Name := To_Unbounded_String ("expression_construct");
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

   procedure Complete_Expression_Construct_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Disc_AST.Expression_Construct_AST_Repair_Context_Model;
   begin
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            Disc_AST.Expression_Construct_AST_Container_Aggregate,
            Editor.Ada_Syntax_Tree.Node_Id (117801)));
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            Disc_AST.Expression_Construct_AST_Delta_Aggregate,
            Editor.Ada_Syntax_Tree.Node_Id (117802)));
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            Disc_AST.Expression_Construct_AST_Reduction_Expression,
            Editor.Ada_Syntax_Tree.Node_Id (117803)));
      Disc_AST.Add_Context
        (Contexts,
         Complete_Context
           (4,
            Disc_AST.Expression_Construct_AST_Quantified_Expression,
            Editor.Ada_Syntax_Tree.Node_Id (117804)));

      declare
         Model : constant Disc_AST.Expression_Construct_AST_Repair_Model :=
           Disc_AST.Build (Contexts);
      begin
         Assert (Disc_AST.Row_Count (Model) = 4,
                 "four expression construct AST repair rows expected");
         Assert (Disc_AST.Accepted_Count (Model) = 4,
                 "complete expression construct repairs should be accepted");
         Assert (Disc_AST.Blocker_Count (Model) = 0,
                 "complete expression construct repairs should not block");
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117801)).Status =
            Disc_AST.Expression_Construct_AST_Legal_Container_Aggregate_Repaired,
            "container aggregate repair should be accepted");
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117804)).Status =
            Disc_AST.Expression_Construct_AST_Legal_Quantified_Expression_Repaired,
            "quantified expression repair should be accepted");
         Assert (Disc_AST.Fingerprint (Model) /= 0,
                 "expression construct AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Expression_Construct_Repairs_Are_Accepted;

   procedure Required_Expression_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Disc_AST.Expression_Construct_AST_Repair_Context_Model;
      Container_Aggregate : Disc_AST.Expression_Construct_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Disc_AST.Expression_Construct_AST_Container_Aggregate,
           Editor.Ada_Syntax_Tree.Node_Id (117821));
      Reduction_Expression : Disc_AST.Expression_Construct_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           Disc_AST.Expression_Construct_AST_Reduction_Expression,
           Editor.Ada_Syntax_Tree.Node_Id (117822));
   begin
      Container_Aggregate.Staticness_Metadata_Repaired := False;
      Reduction_Expression.Contract_Metadata_Repaired := False;
      Disc_AST.Add_Context (Contexts, Container_Aggregate);
      Disc_AST.Add_Context (Contexts, Reduction_Expression);

      declare
         Model : constant Disc_AST.Expression_Construct_AST_Repair_Model :=
           Disc_AST.Build (Contexts);
      begin
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117821)).Status =
            Disc_AST.Expression_Construct_AST_Staticness_Metadata_Still_Missing,
            "container aggregate repair should require staticness metadata");
         Assert
           (Disc_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117822)).Status =
            Disc_AST.Expression_Construct_AST_Contract_Metadata_Still_Missing,
            "reduction expression repair should require contract metadata");
         Assert (Disc_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain expression construct blockers");
      end;
   end Required_Expression_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Expression_Construct_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117841);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117842);
      Construct : constant Audit.Ada_Construct_Kind :=
        Audit.Construct_Container_Aggregate;
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
         Model : constant Disc_AST.Expression_Construct_AST_Repair_Model :=
           Disc_AST.Build_From_Repairs (Repairs);
      begin
         Assert (Disc_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by expression construct node");
         Assert
           (Disc_AST.First_For_Node (Model, Complete_Node).Status =
            Disc_AST.Expression_Construct_AST_Legal_Container_Aggregate_Repaired,
            "complete expression construct repairs should clear the AST gate");
         Assert
           (Disc_AST.First_For_Node (Model, Blocked_Node).Status =
            Disc_AST.Expression_Construct_AST_Multiple_Repair_Blockers,
            "partial expression construct repairs should remain blocked");
         Assert (Disc_AST.Accepted_Count (Model) = 1,
                 "one aggregated expression construct repair should be accepted");
         Assert (Disc_AST.Blocker_Count (Model) = 1,
                 "one aggregated expression construct repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Expression_Construct_Node;

   procedure Consumer_Integration_Blocker_Preserves_Consumer_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Disc_AST.Expression_Construct_AST_Repair_Context_Model;
      Missing_Integration : Disc_AST.Expression_Construct_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Disc_AST.Expression_Construct_AST_Reduction_Expression,
           Editor.Ada_Syntax_Tree.Node_Id (117861));
   begin
      Missing_Integration.Consumer := Audit.Consumer_Overload;
      Missing_Integration.Consumer_Integrated := False;
      Disc_AST.Add_Context (Contexts, Missing_Integration);

      declare
         Model : constant Disc_AST.Expression_Construct_AST_Repair_Model :=
           Disc_AST.Build (Contexts);
         Row : constant Disc_AST.Expression_Construct_AST_Repair_Info :=
           Disc_AST.First_For_Node
             (Model, Editor.Ada_Syntax_Tree.Node_Id (117861));
      begin
         Assert
           (Row.Status =
            Disc_AST.Expression_Construct_AST_Consumer_Still_Not_Integrated,
            "missing expression construct consumer integration should be a dedicated blocker");
         Assert
           (Ada.Strings.Fixed.Index
              (To_String (Row.Detail),
               Audit.Semantic_Consumer_Family'Image
                 (Audit.Consumer_Overload)) > 0,
            "expression construct repair detail should preserve the blocking consumer family");
      end;
   end Consumer_Integration_Blocker_Preserves_Consumer_Family;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Expression_Construct_Repairs_Are_Accepted'Access,
         "complete expression construct repairs are accepted");
      Register_Routine
        (T,
         Required_Expression_Metadata_Remains_Blocker'Access,
         "required expression construct metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Expression_Construct_Node'Access,
         "repair rows aggregate into concrete expression construct AST repair facts");
      Register_Routine
        (T,
         Consumer_Integration_Blocker_Preserves_Consumer_Family'Access,
         "expression construct consumer integration blockers preserve consumer family");
   end Register_Tests;

end Test_Ada_Expression_Construct_AST_Repair_Legality;
