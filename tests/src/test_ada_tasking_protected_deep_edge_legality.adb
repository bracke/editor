with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;

package body Test_Ada_Tasking_Protected_Deep_Edge_Legality is

   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   use type Cross_Final.Cross_Unit_Final_Row_Id;
   use type Cross_Final.Cross_Unit_Final_Context_Kind;
   use type Cross_Final.Cross_Unit_Dependency_State;
   use type Cross_Final.Cross_Unit_Final_Status;
   use type Cross_Final.Cross_Unit_Final_Context_Info;
   use type Cross_Final.Cross_Unit_Final_Info;
   use type Cross_Final.Cross_Unit_Final_Context_Model;
   use type Cross_Final.Cross_Unit_Final_Set;
   use type Cross_Final.Cross_Unit_Final_Model;
   package Deep renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
   use type Deep.Deep_Tasking_Row_Id;
   use type Deep.Deep_Tasking_Context_Kind;
   use type Deep.Deep_Tasking_Status;
   use type Deep.Deep_Tasking_Context_Info;
   use type Deep.Deep_Tasking_Info;
   use type Deep.Deep_Tasking_Context_Model;
   use type Deep.Deep_Tasking_Set;
   use type Deep.Deep_Tasking_Model;
   package Flow_Proof renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   use type Flow_Proof.Flow_Contract_Proof_Row_Id;
   use type Flow_Proof.Flow_Contract_Proof_Context_Kind;
   use type Flow_Proof.Flow_Contract_Proof_Status;
   use type Flow_Proof.Flow_Contract_Proof_Context_Info;
   use type Flow_Proof.Flow_Contract_Proof_Info;
   use type Flow_Proof.Flow_Contract_Proof_Context_Model;
   use type Flow_Proof.Flow_Contract_Proof_Set;
   use type Flow_Proof.Flow_Contract_Proof_Model;
   package Tasking_Final renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;
   use type Tasking_Final.Final_Tasking_Row_Id;
   use type Tasking_Final.Final_Tasking_Context_Kind;
   use type Tasking_Final.Final_Tasking_Status;
   use type Tasking_Final.Final_Tasking_Context_Info;
   use type Tasking_Final.Final_Tasking_Info;
   use type Tasking_Final.Final_Tasking_Context_Model;
   use type Tasking_Final.Final_Tasking_Set;
   use type Tasking_Final.Final_Tasking_Model;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Tasking_Protected_Deep_Edge_Legality");
   end Name;

   function Complete_Context
     (Id   : Deep.Deep_Tasking_Row_Id;
      Kind : Deep.Deep_Tasking_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Deep.Deep_Tasking_Context_Info is
      C : Deep.Deep_Tasking_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Task_Node := Editor.Ada_Syntax_Tree.Node_Id (Natural (Node) + 1);
      C.Protected_Node := Editor.Ada_Syntax_Tree.Node_Id (Natural (Node) + 2);
      C.Entry_Node := Editor.Ada_Syntax_Tree.Node_Id (Natural (Node) + 3);
      C.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Natural (Id)));
      C.Entry_Name := To_Unbounded_String ("Feed_Item" & Natural'Image (Natural (Id)));
      C.Final_Tasking_Row := Tasking_Final.Final_Tasking_Row_Id (Natural (Id));
      C.Final_Tasking_Status := Tasking_Final.Final_Tasking_Legal_Protected_Reentrancy_Accepted;
      C.Final_Tasking_Matches := 1;
      C.Flow_Proof_Row := Flow_Proof.Flow_Contract_Proof_Row_Id (Natural (Id));
      C.Flow_Proof_Status := Flow_Proof.Flow_Contract_Proof_Legal_Task_Protected_State_Accepted;
      C.Flow_Proof_Matches := 1;
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Tasking_Protected_Accepted;
      C.Cross_Unit_Matches := 1;
      C.Requires_Final_Tasking := True;
      C.Requires_Flow_Proof := True;
      C.Requires_Cross_Unit := True;
      C.Source_Fingerprint := Natural (Id) * 1193;
      C.Expected_Source_Fingerprint := Natural (Id) * 1193;
      return C;
   end Complete_Context;

   procedure Accepted_Deep_Tasking_Edges_Require_Final_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Deep.Deep_Tasking_Context_Model;
      Reentrancy : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (1,
           Deep.Deep_Tasking_Protected_Reentrancy_Path,
           Editor.Ada_Syntax_Tree.Node_Id (119301));
      Queue : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (2,
           Deep.Deep_Tasking_Entry_Family_Queue,
           Editor.Ada_Syntax_Tree.Node_Id (119302));
      Abort_Finalization : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (3,
           Deep.Deep_Tasking_Abort_Deferred_Finalization,
           Editor.Ada_Syntax_Tree.Node_Id (119303));
   begin
      Queue.Final_Tasking_Status := Tasking_Final.Final_Tasking_Legal_Entry_Queue_Accepted;
      Abort_Finalization.Final_Tasking_Status := Tasking_Final.Final_Tasking_Legal_Abortable_Part_Accepted;

      Deep.Add_Context (Contexts, Reentrancy);
      Deep.Add_Context (Contexts, Queue);
      Deep.Add_Context (Contexts, Abort_Finalization);

      declare
         Model : constant Deep.Deep_Tasking_Model := Deep.Build (Contexts);
      begin
         Assert (Deep.Row_Count (Model) = 3, "three deep tasking rows expected");
         Assert (Deep.Legal_Count (Model) = 3, "complete final evidence should accept rows");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119301)).Status =
            Deep.Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted,
            "protected reentrancy path should be accepted");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119302)).Status =
            Deep.Deep_Tasking_Legal_Entry_Family_Queue_Accepted,
            "entry family queue should be accepted");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119303)).Status =
            Deep.Deep_Tasking_Legal_Abort_Deferred_Finalization_Accepted,
            "abort deferred finalization path should be accepted");
         Assert (Deep.Fingerprint (Model) /= 0, "model fingerprint must be deterministic");
      end;
   end Accepted_Deep_Tasking_Edges_Require_Final_Evidence;

   procedure Missing_Dependent_Evidence_Blocks_Deep_Tasking_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Deep.Deep_Tasking_Context_Model;
      Missing_Final : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (1,
           Deep.Deep_Tasking_Protected_Indirect_Call,
           Editor.Ada_Syntax_Tree.Node_Id (119321));
      Missing_Flow : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (2,
           Deep.Deep_Tasking_Terminate_Alternative_Graph,
           Editor.Ada_Syntax_Tree.Node_Id (119322));
      Missing_Cross : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (3,
           Deep.Deep_Tasking_Select_Entry_Family,
           Editor.Ada_Syntax_Tree.Node_Id (119323));
   begin
      Missing_Final.Final_Tasking_Matches := 0;
      Missing_Final.Final_Tasking_Status := Tasking_Final.Final_Tasking_Not_Checked;
      Missing_Flow.Flow_Proof_Matches := 0;
      Missing_Flow.Flow_Proof_Status := Flow_Proof.Flow_Contract_Proof_Not_Checked;
      Missing_Cross.Cross_Unit_Matches := 0;
      Missing_Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Not_Checked;

      Deep.Add_Context (Contexts, Missing_Final);
      Deep.Add_Context (Contexts, Missing_Flow);
      Deep.Add_Context (Contexts, Missing_Cross);

      declare
         Model : constant Deep.Deep_Tasking_Model := Deep.Build (Contexts);
      begin
         Assert (Deep.Legal_Count (Model) = 0, "missing evidence should block all rows");
         Assert (Deep.Final_Tasking_Error_Count (Model) = 1, "final tasking blocker should be counted");
         Assert (Deep.Flow_Proof_Error_Count (Model) = 1, "flow proof blocker should be counted");
         Assert (Deep.Cross_Unit_Error_Count (Model) = 1, "cross-unit blocker should be counted");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119321)).Status =
            Deep.Deep_Tasking_Missing_Final_Tasking_Row,
            "final tasking evidence should be required");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119322)).Status =
            Deep.Deep_Tasking_Missing_Flow_Proof_Row,
            "flow proof evidence should be required");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119323)).Status =
            Deep.Deep_Tasking_Missing_Cross_Unit_Row,
            "cross-unit final closure should be required");
      end;
   end Missing_Dependent_Evidence_Blocks_Deep_Tasking_Edges;

   procedure Deep_Edge_Blockers_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Deep.Deep_Tasking_Context_Model;
      Reentrant : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (1,
           Deep.Deep_Tasking_Protected_Indirect_Call,
           Editor.Ada_Syntax_Tree.Node_Id (119341));
      Family : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (2,
           Deep.Deep_Tasking_Entry_Family_Index,
           Editor.Ada_Syntax_Tree.Node_Id (119342));
      Terminate_Context : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (3,
           Deep.Deep_Tasking_Terminate_Alternative_Graph,
           Editor.Ada_Syntax_Tree.Node_Id (119343));
      Abort_Select : Deep.Deep_Tasking_Context_Info :=
        Complete_Context
          (4,
           Deep.Deep_Tasking_Abortable_Select_Finalization,
           Editor.Ada_Syntax_Tree.Node_Id (119344));
   begin
      Reentrant.Indirect_Reentrancy := True;
      Family.Entry_Family_Index_Error := True;
      Terminate_Context.Terminate_Cycle := True;
      Abort_Select.Abortable_Select_Finalization_Error := True;

      Deep.Add_Context (Contexts, Reentrant);
      Deep.Add_Context (Contexts, Family);
      Deep.Add_Context (Contexts, Terminate_Context);
      Deep.Add_Context (Contexts, Abort_Select);

      declare
         Model : constant Deep.Deep_Tasking_Model := Deep.Build (Contexts);
      begin
         Assert (Deep.Legal_Count (Model) = 0, "deep edge blockers should prevent legal rows");
         Assert (Deep.Tasking_Edge_Error_Count (Model) = 4, "four tasking edge blockers expected");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119341)).Status =
            Deep.Deep_Tasking_Indirect_Reentrancy_Blocker,
            "indirect reentrancy blocker should be preserved");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119342)).Status =
            Deep.Deep_Tasking_Entry_Family_Index_Blocker,
            "entry family index blocker should be preserved");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119343)).Status =
            Deep.Deep_Tasking_Terminate_Dependency_Cycle,
            "terminate dependency cycle should be preserved");
         Assert
           (Deep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119344)).Status =
            Deep.Deep_Tasking_Abortable_Select_Finalization_Blocker,
            "abortable-select finalization blocker should be preserved");
      end;
   end Deep_Edge_Blockers_Are_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Deep_Tasking_Edges_Require_Final_Evidence'Access,
         "accepted deep tasking edges require final evidence");
      Register_Routine
        (T,
         Missing_Dependent_Evidence_Blocks_Deep_Tasking_Edges'Access,
         "missing dependent evidence blocks deep tasking edges");
      Register_Routine
        (T,
         Deep_Edge_Blockers_Are_Preserved'Access,
         "deep edge blockers are preserved");
   end Register_Tests;

end Test_Ada_Tasking_Protected_Deep_Edge_Legality;
