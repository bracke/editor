with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Access_Definition_AST_Repair_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Access_Definition_AST_Repair_Legality is

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
   package Access_AST renames Editor.Ada_Access_Definition_AST_Repair_Legality;
   use type Access_AST.Access_Definition_AST_Repair_Row_Id;
   use type Access_AST.Access_Definition_AST_Construct_Kind;
   use type Access_AST.Access_Definition_AST_Repair_Status;
   use type Access_AST.Access_Definition_AST_Repair_Context_Info;
   use type Access_AST.Access_Definition_AST_Repair_Info;
   use type Access_AST.Access_Definition_AST_Repair_Context_Model;
   use type Access_AST.Access_Definition_AST_Repair_Model;
   use type Access_AST.Access_Definition_AST_Repair_Result_Set;

   use type Access_AST.Access_Definition_AST_Repair_Status;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Access_Definition_AST_Repair_Legality");
   end Name;

   function Complete_Context
     (Id        : Access_AST.Access_Definition_AST_Repair_Row_Id;
      Construct : Access_AST.Access_Definition_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Access_AST.Access_Definition_AST_Repair_Context_Info is
      C : Access_AST.Access_Definition_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Accessibility_Lifetime;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Access_Definition");
      C.Normalized_Construct_Name := To_Unbounded_String ("access_definition");
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
      C.Source_Fingerprint := Natural (Id) * 1175;
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
      C.Consumer := Audit.Consumer_Accessibility_Lifetime;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Access_Definition");
      C.Normalized_Construct_Name := To_Unbounded_String ("access_definition");
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

   procedure Complete_Access_Definition_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Access_AST.Access_Definition_AST_Repair_Context_Model;
   begin
      Access_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            Access_AST.Access_Definition_AST_Object_Access,
            Editor.Ada_Syntax_Tree.Node_Id (117501)));
      Access_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            Access_AST.Access_Definition_AST_Access_Parameter,
            Editor.Ada_Syntax_Tree.Node_Id (117502)));
      Access_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            Access_AST.Access_Definition_AST_Subprogram_Access,
            Editor.Ada_Syntax_Tree.Node_Id (117503)));
      Access_AST.Add_Context
        (Contexts,
         Complete_Context
           (4,
            Access_AST.Access_Definition_AST_Access_Discriminant,
            Editor.Ada_Syntax_Tree.Node_Id (117504)));

      declare
         Model : constant Access_AST.Access_Definition_AST_Repair_Model :=
           Access_AST.Build (Contexts);
      begin
         Assert (Access_AST.Row_Count (Model) = 4,
                 "four access definition AST repair rows expected");
         Assert (Access_AST.Accepted_Count (Model) = 4,
                 "complete access definition repairs should be accepted");
         Assert (Access_AST.Blocker_Count (Model) = 0,
                 "complete access definition repairs should not block");
         Assert
           (Access_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117501)).Status =
            Access_AST.Access_Definition_AST_Legal_Object_Access_Repaired,
            "object access repair should be accepted");
         Assert
           (Access_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117504)).Status =
            Access_AST.Access_Definition_AST_Legal_Access_Discriminant_Repaired,
            "access discriminant repair should be accepted");
         Assert (Access_AST.Fingerprint (Model) /= 0,
                 "access definition AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Access_Definition_Repairs_Are_Accepted;

   procedure Required_Access_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Access_AST.Access_Definition_AST_Repair_Context_Model;
      Object_Access : Access_AST.Access_Definition_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Access_AST.Access_Definition_AST_Object_Access,
           Editor.Ada_Syntax_Tree.Node_Id (117521));
      Subprogram_Access : Access_AST.Access_Definition_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           Access_AST.Access_Definition_AST_Subprogram_Access,
           Editor.Ada_Syntax_Tree.Node_Id (117522));
   begin
      Object_Access.Staticness_Metadata_Repaired := False;
      Subprogram_Access.Contract_Metadata_Repaired := False;
      Access_AST.Add_Context (Contexts, Object_Access);
      Access_AST.Add_Context (Contexts, Subprogram_Access);

      declare
         Model : constant Access_AST.Access_Definition_AST_Repair_Model :=
           Access_AST.Build (Contexts);
      begin
         Assert
           (Access_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117521)).Status =
            Access_AST.Access_Definition_AST_Staticness_Metadata_Still_Missing,
            "object access repair should require staticness metadata");
         Assert
           (Access_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117522)).Status =
            Access_AST.Access_Definition_AST_Contract_Metadata_Still_Missing,
            "access-to-subprogram repair should require contract metadata");
         Assert (Access_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain access definition blockers");
      end;
   end Required_Access_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Access_Definition_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117541);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117542);
   begin
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Structural_AST);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Source_Span);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Name_Binding_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Type_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Staticness_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Contract_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Flow_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Representation_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Cross_Unit_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Semantic_Consumer);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Consumer_Integration);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Token_Only_Replacement);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Access_Definition, Repair.Repair_Degradation_Replacement);

      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Access_Definition, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Access_Definition, Repair.Repair_Structural_AST, False);

      declare
         Repairs : constant Repair.Repair_Model := Repair.Build (Repair_Contexts);
         Model : constant Access_AST.Access_Definition_AST_Repair_Model :=
           Access_AST.Build_From_Repairs (Repairs);
      begin
         Assert (Access_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by access definition node");
         Assert
           (Access_AST.First_For_Node (Model, Complete_Node).Status =
            Access_AST.Access_Definition_AST_Legal_Object_Access_Repaired,
            "complete access-definition repairs should clear the AST gate");
         Assert
           (Access_AST.First_For_Node (Model, Blocked_Node).Status =
            Access_AST.Access_Definition_AST_Multiple_Repair_Blockers,
            "partial access-definition repairs should remain blocked");
         Assert (Access_AST.Accepted_Count (Model) = 1,
                 "one aggregated access definition repair should be accepted");
         Assert (Access_AST.Blocker_Count (Model) = 1,
                 "one aggregated access definition repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Access_Definition_Node;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Access_Definition_Repairs_Are_Accepted'Access,
         "complete access definition repairs are accepted");
      Register_Routine
        (T,
         Required_Access_Metadata_Remains_Blocker'Access,
         "required access definition metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Access_Definition_Node'Access,
         "repair rows aggregate into concrete access definition AST repair facts");
   end Register_Tests;

end Test_Ada_Access_Definition_AST_Repair_Legality;
