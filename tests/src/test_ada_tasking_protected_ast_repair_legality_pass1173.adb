with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_AST_Repair_Legality;

package body Test_Ada_Tasking_Protected_AST_Repair_Legality_Pass1173 is

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
   package Task_AST renames Editor.Ada_Tasking_Protected_AST_Repair_Legality;
   use type Task_AST.Tasking_AST_Repair_Row_Id;
   use type Task_AST.Tasking_AST_Construct_Kind;
   use type Task_AST.Tasking_AST_Repair_Status;
   use type Task_AST.Tasking_AST_Repair_Context_Info;
   use type Task_AST.Tasking_AST_Repair_Info;
   use type Task_AST.Tasking_AST_Repair_Context_Model;
   use type Task_AST.Tasking_AST_Repair_Model;
   use type Task_AST.Tasking_AST_Repair_Result_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Protected_AST_Repair_Legality_Pass1173");
   end Name;

   function Complete_Context
     (Id        : Task_AST.Tasking_AST_Repair_Row_Id;
      Construct : Task_AST.Tasking_AST_Construct_Kind;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Task_AST.Tasking_AST_Repair_Context_Info is
      C : Task_AST.Tasking_AST_Repair_Context_Info;
   begin
      C.Id := Id;
      C.Construct := Construct;
      C.Consumer := Audit.Consumer_Tasking_Protected;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Tasking_Construct");
      C.Normalized_Construct_Name := To_Unbounded_String ("tasking_construct");
      C.Parser_Node_Repaired := True;
      C.Structural_AST_Repaired := True;
      C.Source_Span_Repaired := True;
      C.Contract_Metadata_Repaired := True;
      C.Flow_Metadata_Repaired := True;
      C.Representation_Metadata_Repaired := True;
      C.Cross_Unit_Metadata_Repaired := True;
      C.Consumer_Repaired := True;
      C.Consumer_Integrated := True;
      C.Token_Only_Replaced := True;
      C.Degradation_Replaced := True;
      C.Source_Fingerprint := Natural (Id) * 1173;
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
      C.Consumer := Audit.Consumer_Tasking_Protected;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String ("Tasking_Construct");
      C.Normalized_Construct_Name := To_Unbounded_String ("tasking_construct");
      C.Before_Coverage := Audit.Coverage_Parser_Node_Missing;
      C.Before_Gate := Gates.Gate_Parser_Node_Missing;
      C.Parser_Node_Repaired := Complete;
      C.Structural_AST_Repaired := Complete;
      C.Source_Span_Repaired := Complete;
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

   procedure Complete_Task_Protected_Select_Repairs_Are_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Task_AST.Tasking_AST_Repair_Context_Model;
   begin
      Task_AST.Add_Context
        (Contexts,
         Complete_Context
           (1,
            Task_AST.Tasking_AST_Task_Type,
            Editor.Ada_Syntax_Tree.Node_Id (117301)));
      Task_AST.Add_Context
        (Contexts,
         Complete_Context
           (2,
            Task_AST.Tasking_AST_Protected_Body,
            Editor.Ada_Syntax_Tree.Node_Id (117302)));
      Task_AST.Add_Context
        (Contexts,
         Complete_Context
           (3,
            Task_AST.Tasking_AST_Select_Statement,
            Editor.Ada_Syntax_Tree.Node_Id (117303)));

      declare
         Model : constant Task_AST.Tasking_AST_Repair_Model :=
           Task_AST.Build (Contexts);
      begin
         Assert (Task_AST.Row_Count (Model) = 3,
                 "three tasking AST repair rows expected");
         Assert (Task_AST.Accepted_Count (Model) = 3,
                 "complete task/protected/select repairs should be accepted");
         Assert (Task_AST.Blocker_Count (Model) = 0,
                 "complete task/protected/select repairs should not block");
         Assert
           (Task_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117301)).Status =
            Task_AST.Tasking_AST_Legal_Task_Type_Repaired,
            "task type repair should be accepted");
         Assert
           (Task_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117302)).Status =
            Task_AST.Tasking_AST_Legal_Protected_Body_Repaired,
            "protected body repair should be accepted");
         Assert
           (Task_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117303)).Status =
            Task_AST.Tasking_AST_Legal_Select_Statement_Repaired,
            "select statement repair should be accepted");
         Assert (Task_AST.Fingerprint (Model) /= 0,
                 "tasking AST repair model must have a deterministic fingerprint");
      end;
   end Complete_Task_Protected_Select_Repairs_Are_Accepted;

   procedure Missing_Metadata_Remains_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Task_AST.Tasking_AST_Repair_Context_Model;
      Entry_Body : Task_AST.Tasking_AST_Repair_Context_Info :=
        Complete_Context
          (1,
           Task_AST.Tasking_AST_Entry_Body,
           Editor.Ada_Syntax_Tree.Node_Id (117321));
      Protected_Type : Task_AST.Tasking_AST_Repair_Context_Info :=
        Complete_Context
          (2,
           Task_AST.Tasking_AST_Protected_Type,
           Editor.Ada_Syntax_Tree.Node_Id (117322));
   begin
      Entry_Body.Contract_Metadata_Repaired := False;
      Protected_Type.Representation_Metadata_Repaired := False;
      Task_AST.Add_Context (Contexts, Entry_Body);
      Task_AST.Add_Context (Contexts, Protected_Type);

      declare
         Model : constant Task_AST.Tasking_AST_Repair_Model :=
           Task_AST.Build (Contexts);
      begin
         Assert
           (Task_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117321)).Status =
            Task_AST.Tasking_AST_Contract_Metadata_Still_Missing,
            "entry body repair should require contract metadata");
         Assert
           (Task_AST.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (117322)).Status =
            Task_AST.Tasking_AST_Representation_Metadata_Still_Missing,
            "protected type repair should require representation metadata");
         Assert (Task_AST.Blocker_Count (Model) = 2,
                 "metadata gaps should remain blockers");
      end;
   end Missing_Metadata_Remains_Blocker;

   procedure Repair_Model_Is_Aggregated_By_Construct_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Repair_Contexts : Repair.Repair_Context_Model;
      Complete_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117341);
      Blocked_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node_Id (117342);
   begin
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Structural_AST);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Source_Span);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Contract_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Flow_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Cross_Unit_Metadata);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Semantic_Consumer);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Consumer_Integration);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Token_Only_Replacement);
      Add_Repair (Repair_Contexts, Complete_Node, Audit.Construct_Accept_Statement, Repair.Repair_Degradation_Replacement);

      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Select_Statement, Repair.Repair_Parser_Node);
      Add_Repair (Repair_Contexts, Blocked_Node, Audit.Construct_Select_Statement, Repair.Repair_Structural_AST, False);

      declare
         Repairs : constant Repair.Repair_Model := Repair.Build (Repair_Contexts);
         Model : constant Task_AST.Tasking_AST_Repair_Model :=
           Task_AST.Build_From_Repairs (Repairs);
      begin
         Assert (Task_AST.Row_Count (Model) = 2,
                 "repair rows should be aggregated by tasking construct node");
         Assert
           (Task_AST.First_For_Node (Model, Complete_Node).Status =
            Task_AST.Tasking_AST_Legal_Accept_Statement_Repaired,
            "complete accept-statement repairs should clear the AST gate");
         Assert
           (Task_AST.First_For_Node (Model, Blocked_Node).Status =
            Task_AST.Tasking_AST_Multiple_Repair_Blockers,
            "partial select-statement repairs should remain blocked");
         Assert (Task_AST.Accepted_Count (Model) = 1,
                 "one aggregated repair should be accepted");
         Assert (Task_AST.Blocker_Count (Model) = 1,
                 "one aggregated repair should remain blocked");
      end;
   end Repair_Model_Is_Aggregated_By_Construct_Node;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Complete_Task_Protected_Select_Repairs_Are_Accepted'Access,
         "complete task/protected/select repairs are accepted");
      Register_Routine
        (T,
         Missing_Metadata_Remains_Blocker'Access,
         "missing required tasking metadata remains a blocker");
      Register_Routine
        (T,
         Repair_Model_Is_Aggregated_By_Construct_Node'Access,
         "repair rows aggregate into concrete tasking AST repair facts");
   end Register_Tests;

end Test_Ada_Tasking_Protected_AST_Repair_Legality_Pass1173;
