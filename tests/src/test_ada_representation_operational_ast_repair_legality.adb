with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Representation_Operational_AST_Repair_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Representation_Operational_AST_Repair_Legality is

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
   package Rep_AST renames Editor.Ada_Representation_Operational_AST_Repair_Legality;
   use type Rep_AST.Representation_Operational_AST_Repair_Row_Id;
   use type Rep_AST.Representation_Operational_AST_Construct_Kind;
   use type Rep_AST.Representation_Operational_AST_Repair_Status;
   use type Rep_AST.Representation_Operational_AST_Repair_Context_Info;
   use type Rep_AST.Representation_Operational_AST_Repair_Info;
   use type Rep_AST.Representation_Operational_AST_Repair_Context_Model;
   use type Rep_AST.Representation_Operational_AST_Repair_Model;
   use type Rep_AST.Representation_Operational_AST_Repair_Result_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Representation_Operational_AST_Repair_Legality");
   end Name;

   function Complete_Context
     (Id        : Rep_AST.Representation_Operational_AST_Repair_Row_Id;
      Construct : Rep_AST.Representation_Operational_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Rep_AST.Representation_Operational_AST_Repair_Context_Info is
      C : Rep_AST.Representation_Operational_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Representation_Freezing_Precision;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Representation_Operational");
      C.Normalized_Construct_Name := To_Unbounded_String ("representation_operational");
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
      C.Source_Fingerprint := Natural (Id) * 1176;
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
      C.Consumer := Audit.Consumer_Representation_Freezing_Precision;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Representation_Operational");
      C.Normalized_Construct_Name := To_Unbounded_String ("representation_operational");
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

   procedure Complete_Representation_Operational_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Rep_AST.Representation_Operational_AST_Repair_Context_Model;
   begin
      Rep_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            Rep_AST.Representation_Operational_AST_Representation_Clause,
            Editor.Ada_Syntax_Tree.Node_Id (117501)));
      Rep_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            Rep_AST.Representation_Operational_AST_Operational_Attribute_Clause,
            Editor.Ada_Syntax_Tree.Node_Id (117502)));
      Rep_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            Rep_AST.Representation_Operational_AST_Aspect_Specification,
            Editor.Ada_Syntax_Tree.Node_Id (117503)));
      Rep_AST.Add_Context
        (Contexts,
         Complete_Context
           (4,
            Rep_AST.Representation_Operational_AST_Pragma,
            Editor.Ada_Syntax_Tree.Node_Id (117504)));

      declare
         Model : constant Rep_AST.Representation_Operational_AST_Repair_Model :=
           Rep_AST.Build (Contexts);
      begin
         Assert (Rep_AST.Row_Count (Model) = 4,
                 "four representation/operational clause AST repair rows expected");
         Assert (Rep_AST.Accepted_Count (Model) = 4,
                 "complete representation/operational clause repairs should be accepted");
         Assert (Rep_AST.Blocker_Count (Model) = 0,
                 "complete representation/operational clause repairs should not block");
         Assert
           (Rep_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117501)).Status =
            Rep_AST.Representation_Operational_AST_Legal_Representation_Clause_Repaired,
            "representation clause repair should be accepted");
         Assert
           (Rep_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117504)).Status =
            Rep_AST.Representation_Operational_AST_Legal_Pragma_Repaired,
            "pragma repair should be accepted");
         Assert (Rep_AST.Fingerprint (Model) /= 0,
                 "representation/operational clause AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Representation_Operational_Repairs_Are_Accepted;

   procedure Required_Representation_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Rep_AST.Representation_Operational_AST_Repair_Context_Model;
      Representation_Clause : Rep_AST.Representation_Operational_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Rep_AST.Representation_Operational_AST_Representation_Clause,
           Editor.Ada_Syntax_Tree.Node_Id (117521));
      Aspect_Specification : Rep_AST.Representation_Operational_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           Rep_AST.Representation_Operational_AST_Aspect_Specification,
           Editor.Ada_Syntax_Tree.Node_Id (117522));
   begin
      Representation_Clause.Staticness_Metadata_Repaired := False;
      Aspect_Specification.Contract_Metadata_Repaired := False;
      Rep_AST.Add_Context (Contexts, Representation_Clause);
      Rep_AST.Add_Context (Contexts, Aspect_Specification);

      declare
         Model : constant Rep_AST.Representation_Operational_AST_Repair_Model :=
           Rep_AST.Build (Contexts);
      begin
         Assert
           (Rep_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117521)).Status =
            Rep_AST.Representation_Operational_AST_Staticness_Metadata_Still_Missing,
            "representation clause repair should require staticness metadata");
         Assert
           (Rep_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117522)).Status =
            Rep_AST.Representation_Operational_AST_Contract_Metadata_Still_Missing,
            "aspect repair should require contract metadata");
         Assert (Rep_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain representation/operational clause blockers");
      end;
   end Required_Representation_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Representation_Operational_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117541);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117542);
   begin
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Structural_AST);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Source_Span);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Name_Binding_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Type_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Staticness_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Contract_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Flow_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Representation_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Cross_Unit_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Semantic_Consumer);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Consumer_Integration);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Token_Only_Replacement);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Representation_Clause, Repair.Repair_Degradation_Replacement);

      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Representation_Clause, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Representation_Clause, Repair.Repair_Structural_AST, False);

      declare
         Repairs : constant Repair.Repair_Model := Repair.Build (Repair_Contexts);
         Model : constant Rep_AST.Representation_Operational_AST_Repair_Model :=
           Rep_AST.Build_From_Repairs (Repairs);
      begin
         Assert (Rep_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by representation/operational clause node");
         Assert
           (Rep_AST.First_For_Node (Model, Complete_Node).Status =
            Rep_AST.Representation_Operational_AST_Legal_Representation_Clause_Repaired,
            "complete representation/operational repairs should clear the AST gate");
         Assert
           (Rep_AST.First_For_Node (Model, Blocked_Node).Status =
            Rep_AST.Representation_Operational_AST_Multiple_Repair_Blockers,
            "partial representation/operational repairs should remain blocked");
         Assert (Rep_AST.Accepted_Count (Model) = 1,
                 "one aggregated representation/operational clause repair should be accepted");
         Assert (Rep_AST.Blocker_Count (Model) = 1,
                 "one aggregated representation/operational clause repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Representation_Operational_Node;

   procedure Consumer_Integration_Blocker_Preserves_Consumer_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Rep_AST.Representation_Operational_AST_Repair_Context_Model;
      Missing_Integration : Rep_AST.Representation_Operational_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Rep_AST.Representation_Operational_AST_Operational_Attribute_Clause,
           Editor.Ada_Syntax_Tree.Node_Id (117561));
   begin
      Missing_Integration.Consumer := Audit.Consumer_Representation_Layout_Stream;
      Missing_Integration.Consumer_Integrated := False;
      Rep_AST.Add_Context (Contexts, Missing_Integration);

      declare
         Model : constant Rep_AST.Representation_Operational_AST_Repair_Model :=
           Rep_AST.Build (Contexts);
         Row : constant Rep_AST.Representation_Operational_AST_Repair_Info :=
           Rep_AST.First_For_Node
             (Model, Editor.Ada_Syntax_Tree.Node_Id (117561));
      begin
         Assert
           (Row.Status =
            Rep_AST.Representation_Operational_AST_Consumer_Still_Not_Integrated,
            "missing representation/operational consumer integration should be a dedicated blocker");
         Assert
           (Ada.Strings.Fixed.Index
              (To_String (Row.Detail),
               Audit.Semantic_Consumer_Family'Image
                 (Audit.Consumer_Representation_Layout_Stream)) > 0,
            "representation/operational repair detail should preserve the blocking consumer family");
      end;
   end Consumer_Integration_Blocker_Preserves_Consumer_Family;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Representation_Operational_Repairs_Are_Accepted'Access,
         "complete representation/operational clause repairs are accepted");
      Register_Routine
        (T,
         Required_Representation_Metadata_Remains_Blocker'Access,
         "required representation/operational clause metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Representation_Operational_Node'Access,
         "repair rows aggregate into concrete representation/operational clause AST repair facts");
      Register_Routine
        (T,
         Consumer_Integration_Blocker_Preserves_Consumer_Family'Access,
         "representation/operational consumer integration blockers preserve consumer family");
   end Register_Tests;

end Test_Ada_Representation_Operational_AST_Repair_Legality;
