with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Renaming_Separate_Exception_AST_Repair_Legality is

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
   package RSE_AST renames Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Row_Id;
   use type RSE_AST.Renaming_Separate_Exception_AST_Construct_Kind;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Status;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Info;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Info;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Model;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Model;
   use type RSE_AST.Renaming_Separate_Exception_AST_Repair_Result_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Renaming_Separate_Exception_AST_Repair_Legality");
   end Name;

   function Complete_Context
     (Id        : RSE_AST.Renaming_Separate_Exception_AST_Repair_Row_Id;
      Construct : RSE_AST.Renaming_Separate_Exception_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Info is
      C : RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Expression_Types;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Renaming_Separate_Exception");
      C.Normalized_Construct_Name := To_Unbounded_String ("renaming_separate_exception");
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
      C.Source_Fingerprint := Natural (Id) * 1187;
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
      C.Construct_Name := To_Unbounded_String ("Renaming_Separate_Exception");
      C.Normalized_Construct_Name := To_Unbounded_String ("renaming_separate_exception");
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

   procedure Complete_Renaming_Separate_Exception_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Model;
   begin
      RSE_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            RSE_AST.Renaming_Separate_Exception_AST_Renaming_Declaration,
            Editor.Ada_Syntax_Tree.Node_Id (118701)));
      RSE_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            RSE_AST.Renaming_Separate_Exception_AST_Separate_Body,
            Editor.Ada_Syntax_Tree.Node_Id (118702)));
      RSE_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            RSE_AST.Renaming_Separate_Exception_AST_Body_Stub,
            Editor.Ada_Syntax_Tree.Node_Id (118703)));
      RSE_AST.Add_Context
        (Contexts,
         Complete_Context
           (4,
            RSE_AST.Renaming_Separate_Exception_AST_Exception_Handler,
            Editor.Ada_Syntax_Tree.Node_Id (118704)));
      RSE_AST.Add_Context
        (Contexts,
         Complete_Context
           (5,
            RSE_AST.Renaming_Separate_Exception_AST_Raise_Expression,
            Editor.Ada_Syntax_Tree.Node_Id (118705)));

      declare
         Model : constant RSE_AST.Renaming_Separate_Exception_AST_Repair_Model :=
           RSE_AST.Build (Contexts);
      begin
         Assert (RSE_AST.Row_Count (Model) = 5,
                 "five renaming/separate/exception construct AST repair rows expected");
         Assert (RSE_AST.Accepted_Count (Model) = 5,
                 "complete renaming/separate/exception construct repairs should be accepted");
         Assert (RSE_AST.Blocker_Count (Model) = 0,
                 "complete renaming/separate/exception construct repairs should not block");
         Assert
           (RSE_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118701)).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Legal_Renaming_Declaration_Repaired,
            "renaming declaration repair should be accepted");
         Assert
           (RSE_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118704)).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Legal_Exception_Handler_Repaired,
            "exception handler repair should be accepted");
         Assert
           (RSE_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118705)).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Legal_Raise_Expression_Repaired,
            "raise expression repair should be accepted");
         Assert (RSE_AST.Fingerprint (Model) /= 0,
                 "renaming/separate/exception construct AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Renaming_Separate_Exception_Repairs_Are_Accepted;

   procedure Required_Expression_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Model;
      Renaming_Decl : RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           RSE_AST.Renaming_Separate_Exception_AST_Renaming_Declaration,
           Editor.Ada_Syntax_Tree.Node_Id (118721));
      Body_Stub : RSE_AST.Renaming_Separate_Exception_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           RSE_AST.Renaming_Separate_Exception_AST_Body_Stub,
           Editor.Ada_Syntax_Tree.Node_Id (118722));
   begin
      Renaming_Decl.Staticness_Metadata_Repaired := False;
      Body_Stub.Contract_Metadata_Repaired := False;
      RSE_AST.Add_Context (Contexts, Renaming_Decl);
      RSE_AST.Add_Context (Contexts, Body_Stub);

      declare
         Model : constant RSE_AST.Renaming_Separate_Exception_AST_Repair_Model :=
           RSE_AST.Build (Contexts);
      begin
         Assert
           (RSE_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118721)).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Staticness_Metadata_Still_Missing,
            "renaming declaration repair should require staticness metadata");
         Assert
           (RSE_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118722)).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Contract_Metadata_Still_Missing,
            "body stub repair should require contract metadata");
         Assert (RSE_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain renaming/separate/exception construct blockers");
      end;
   end Required_Expression_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Renaming_Separate_Exception_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (118741);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (118742);
      Construct : constant Audit.Ada_Construct_Kind :=
        Audit.Construct_Renaming_Declaration;
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
         Model : constant RSE_AST.Renaming_Separate_Exception_AST_Repair_Model :=
           RSE_AST.Build_From_Repairs (Repairs);
      begin
         Assert (RSE_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by renaming/separate/exception construct node");
         Assert
           (RSE_AST.First_For_Node (Model, Complete_Node).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Legal_Renaming_Declaration_Repaired,
            "complete renaming/separate/exception construct repairs should clear the AST gate");
         Assert
           (RSE_AST.First_For_Node (Model, Blocked_Node).Status =
            RSE_AST.Renaming_Separate_Exception_AST_Multiple_Repair_Blockers,
            "partial renaming/separate/exception construct repairs should remain blocked");
         Assert (RSE_AST.Accepted_Count (Model) = 1,
                 "one aggregated renaming/separate/exception construct repair should be accepted");
         Assert (RSE_AST.Blocker_Count (Model) = 1,
                 "one aggregated renaming/separate/exception construct repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Renaming_Separate_Exception_Node;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Renaming_Separate_Exception_Repairs_Are_Accepted'Access,
         "complete renaming/separate/exception construct repairs are accepted");
      Register_Routine
        (T,
         Required_Expression_Metadata_Remains_Blocker'Access,
         "required renaming/separate/exception construct metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Renaming_Separate_Exception_Node'Access,
         "repair rows aggregate into concrete renaming/separate/exception construct AST repair facts");
   end Register_Tests;

end Test_Ada_Renaming_Separate_Exception_AST_Repair_Legality;
