with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

package body Test_Ada_Abstract_State_Refined_State_Legality is

   package States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   use type States.Abstract_State_Row_Id;
   use type States.Abstract_State_Context_Kind;
   use type States.Abstract_State_Status;
   use type States.Abstract_State_Context_Info;
   use type States.Abstract_State_Info;
   use type States.Abstract_State_Context_Model;
   use type States.Abstract_State_Model;
   use type States.Abstract_State_Set;
   package Flow renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   use type Flow.Flow_Contract_Proof_Row_Id;
   use type Flow.Flow_Contract_Proof_Context_Kind;
   use type Flow.Flow_Contract_Proof_Status;
   use type Flow.Flow_Contract_Proof_Context_Info;
   use type Flow.Flow_Contract_Proof_Info;
   use type Flow.Flow_Contract_Proof_Context_Model;
   use type Flow.Flow_Contract_Proof_Set;
   use type Flow.Flow_Contract_Proof_Model;
   package Stabilized renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   use type Stabilized.Final_Blocker_Family;
   use type Stabilized.Final_Stabilization_Gate_Status;
   use type Stabilized.Final_Stabilization_Gate_Action;
   use type Stabilized.Final_Stabilized_Closure_Id;
   use type Stabilized.Final_Stabilized_Closure_Status;
   use type Stabilized.Final_Stabilized_Closure_Action;
   use type Stabilized.Final_Stabilized_Closure_Row;
   use type Stabilized.Final_Stabilized_Closure_Model;
   use type Stabilized.Final_Stabilized_Closure_Set;
   package Tasking renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
   use type Tasking.Deep_Tasking_Row_Id;
   use type Tasking.Deep_Tasking_Context_Kind;
   use type Tasking.Deep_Tasking_Status;
   use type Tasking.Deep_Tasking_Context_Info;
   use type Tasking.Deep_Tasking_Info;
   use type Tasking.Deep_Tasking_Context_Model;
   use type Tasking.Deep_Tasking_Set;
   use type Tasking.Deep_Tasking_Model;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Abstract_State_Refined_State_Legality");
   end Name;

   function Complete_Context
     (Id   : States.Abstract_State_Row_Id;
      Kind : States.Abstract_State_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return States.Abstract_State_Context_Info is
      C : States.Abstract_State_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.State_Node := Node;
      C.Unit_Node := Editor.Ada_Syntax_Tree.Node_Id (121100 + Natural (Id));
      C.State_Name := To_Unbounded_String ("State" & Natural'Image (Natural (Id)));
      C.Constituent_Name := To_Unbounded_String ("Impl" & Natural'Image (Natural (Id)));
      C.Unit_Name := To_Unbounded_String ("Pkg");
      C.Flow_Proof_Row := Flow.Flow_Contract_Proof_Row_Id (Id);
      C.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Abstract_State_Accepted;
      C.Tasking_Row := Tasking.Deep_Tasking_Row_Id (Id);
      C.Tasking_Status := Tasking.Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted;
      C.Stabilized_Row := Stabilized.Final_Stabilized_Closure_Id (Id);
      C.Stabilized_Status := Stabilized.Final_Stabilized_Closure_Accepted_Current;
      C.Requires_Flow_Proof := True;
      C.Requires_Tasking := False;
      C.Requires_Stabilized_Closure := True;
      C.Source_Fingerprint := Natural (Id) * 1211;
      C.Expected_Source_Fingerprint := Natural (Id) * 1211;
      return C;
   end Complete_Context;

   procedure Accepted_Abstract_And_Refined_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : States.Abstract_State_Context_Model;
      Decl : States.Abstract_State_Context_Info :=
        Complete_Context
          (1,
           States.Abstract_State_Declaration,
           Editor.Ada_Syntax_Tree.Node_Id (121101));
      Refined : States.Abstract_State_Context_Info :=
        Complete_Context
          (2,
           States.Abstract_State_Refined_State_Aspect,
           Editor.Ada_Syntax_Tree.Node_Id (121102));
      Constituent : States.Abstract_State_Context_Info :=
        Complete_Context
          (3,
           States.Abstract_State_Constituent_Mapping,
           Editor.Ada_Syntax_Tree.Node_Id (121103));
   begin
      Refined.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Refined_State_Accepted;
      Constituent.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Refined_Global_Accepted;

      States.Add_Context (Contexts, Decl);
      States.Add_Context (Contexts, Refined);
      States.Add_Context (Contexts, Constituent);

      declare
         Model : constant States.Abstract_State_Model := States.Build (Contexts);
      begin
         Assert (States.Row_Count (Model) = 3, "three state rows expected");
         Assert (States.Legal_Count (Model) = 3, "complete state evidence should remain legal");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121101)).Status =
            States.Abstract_State_Legal_Declaration_Accepted,
            "abstract state declaration should be accepted");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121102)).Status =
            States.Abstract_State_Legal_Refined_State_Accepted,
            "refined state aspect should be accepted");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121103)).Status =
            States.Abstract_State_Legal_Constituent_Mapping_Accepted,
            "constituent mapping should be accepted");
         Assert (States.Fingerprint (Model) /= 0, "model fingerprint should be deterministic");
      end;
   end Accepted_Abstract_And_Refined_State_Evidence;

   procedure Missing_Dependent_Evidence_Blocks_State_Proof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : States.Abstract_State_Context_Model;
      Missing_Flow : States.Abstract_State_Context_Info :=
        Complete_Context
          (1,
           States.Abstract_State_Global_Use,
           Editor.Ada_Syntax_Tree.Node_Id (121121));
      Missing_Tasking : States.Abstract_State_Context_Info :=
        Complete_Context
          (2,
           States.Abstract_State_Task_Protected_Shared_State,
           Editor.Ada_Syntax_Tree.Node_Id (121122));
      Missing_Closure : States.Abstract_State_Context_Info :=
        Complete_Context
          (3,
           States.Abstract_State_Cross_Unit_View,
           Editor.Ada_Syntax_Tree.Node_Id (121123));
   begin
      Missing_Flow.Flow_Proof_Status := Flow.Flow_Contract_Proof_Not_Checked;
      Missing_Tasking.Requires_Tasking := True;
      Missing_Tasking.Tasking_Status := Tasking.Deep_Tasking_Not_Checked;
      Missing_Closure.Stabilized_Status := Stabilized.Final_Stabilized_Closure_Not_Checked;

      States.Add_Context (Contexts, Missing_Flow);
      States.Add_Context (Contexts, Missing_Tasking);
      States.Add_Context (Contexts, Missing_Closure);

      declare
         Model : constant States.Abstract_State_Model := States.Build (Contexts);
      begin
         Assert (States.Legal_Count (Model) = 0, "missing evidence must block abstract state proof");
         Assert (States.Flow_Error_Count (Model) = 1, "missing flow proof should be counted");
         Assert (States.Tasking_Error_Count (Model) = 1, "missing tasking proof should be counted");
         Assert (States.Closure_Error_Count (Model) = 1, "missing stabilized closure should be counted");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121121)).Status =
            States.Abstract_State_Missing_Flow_Proof_Row,
            "flow proof evidence should be required");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121122)).Status =
            States.Abstract_State_Missing_Tasking_Row,
            "task/protected evidence should be required for shared state");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121123)).Status =
            States.Abstract_State_Missing_Stabilized_Closure_Row,
            "stabilized closure evidence should be required");
      end;
   end Missing_Dependent_Evidence_Blocks_State_Proof;

   procedure Refinement_And_State_Effect_Blockers_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : States.Abstract_State_Context_Model;
      Missing_Constituent : States.Abstract_State_Context_Info :=
        Complete_Context
          (1,
           States.Abstract_State_Refined_State_Aspect,
           Editor.Ada_Syntax_Tree.Node_Id (121141));
      Depends_Blocker : States.Abstract_State_Context_Info :=
        Complete_Context
          (2,
           States.Abstract_State_Depends_Source,
           Editor.Ada_Syntax_Tree.Node_Id (121142));
      Volatile_Blocker : States.Abstract_State_Context_Info :=
        Complete_Context
          (3,
           States.Abstract_State_Volatile_State,
           Editor.Ada_Syntax_Tree.Node_Id (121143));
      Atomic_Blocker : States.Abstract_State_Context_Info :=
        Complete_Context
          (4,
           States.Abstract_State_Atomic_State,
           Editor.Ada_Syntax_Tree.Node_Id (121144));
   begin
      Missing_Constituent.Missing_Constituent := True;
      Depends_Blocker.Depends_Missing_Edge := True;
      Volatile_Blocker.Volatile_Effect_Error := True;
      Atomic_Blocker.Atomic_Effect_Error := True;

      States.Add_Context (Contexts, Missing_Constituent);
      States.Add_Context (Contexts, Depends_Blocker);
      States.Add_Context (Contexts, Volatile_Blocker);
      States.Add_Context (Contexts, Atomic_Blocker);

      declare
         Model : constant States.Abstract_State_Model := States.Build (Contexts);
      begin
         Assert (States.Legal_Count (Model) = 0, "state blockers must not remain legal");
         Assert (States.Refinement_Error_Count (Model) = 2, "refinement blockers should be counted");
         Assert (States.State_Effect_Error_Count (Model) = 2, "state effect blockers should be counted");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121141)).Status =
            States.Abstract_State_Missing_Constituent,
            "missing refined-state constituent should be preserved");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121142)).Status =
            States.Abstract_State_Abstract_Depends_Missing_Edge,
            "abstract Depends missing edge should be preserved");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121143)).Status =
            States.Abstract_State_Volatile_Effect_Blocker,
            "volatile state effect blocker should be preserved");
         Assert
           (States.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121144)).Status =
            States.Abstract_State_Atomic_Effect_Blocker,
            "atomic state effect blocker should be preserved");
      end;
   end Refinement_And_State_Effect_Blockers_Are_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Abstract_And_Refined_State_Evidence'Access,
         "accepted abstract and refined state evidence");
      Register_Routine
        (T,
         Missing_Dependent_Evidence_Blocks_State_Proof'Access,
         "missing dependent evidence blocks state proof");
      Register_Routine
        (T,
         Refinement_And_State_Effect_Blockers_Are_Preserved'Access,
         "refinement and state effect blockers are preserved");
   end Register_Tests;

end Test_Ada_Abstract_State_Refined_State_Legality;
