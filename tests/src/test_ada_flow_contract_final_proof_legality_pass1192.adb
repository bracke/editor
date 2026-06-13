with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Flow_Contract_Final_Proof_Legality_Pass1192 is

   package Contract_CPD renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Contract_CPD.Contract_Predicate_Row_Id;
   use type Contract_CPD.Contract_Predicate_Status;
   use type Contract_CPD.Contract_Predicate_Context_Info;
   use type Contract_CPD.Contract_Predicate_Info;
   use type Contract_CPD.Contract_Predicate_Context_Model;
   use type Contract_CPD.Contract_Predicate_Set;
   use type Contract_CPD.Contract_Predicate_Model;
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
   package Dataflow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   use type Dataflow_Init.Dataflow_Init_Row_Id;
   use type Dataflow_Init.Dataflow_Init_Status;
   use type Dataflow_Init.Dataflow_Init_Context_Info;
   use type Dataflow_Init.Dataflow_Init_Info;
   use type Dataflow_Init.Dataflow_Init_Context_Model;
   use type Dataflow_Init.Dataflow_Init_Set;
   use type Dataflow_Init.Dataflow_Init_Model;
   package Proof renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   use type Proof.Flow_Contract_Proof_Row_Id;
   use type Proof.Flow_Contract_Proof_Context_Kind;
   use type Proof.Flow_Contract_Proof_Status;
   use type Proof.Flow_Contract_Proof_Context_Info;
   use type Proof.Flow_Contract_Proof_Info;
   use type Proof.Flow_Contract_Proof_Context_Model;
   use type Proof.Flow_Contract_Proof_Set;
   use type Proof.Flow_Contract_Proof_Model;
   package Flow_Consumer renames Editor.Ada_Flow_Refinement_Consumer_Legality;
   use type Flow_Consumer.Consumer_Row_Id;
   use type Flow_Consumer.Consumer_Kind;
   use type Flow_Consumer.Consumer_Effect_Kind;
   use type Flow_Consumer.Consumer_Status;
   use type Flow_Consumer.Consumer_Context_Info;
   use type Flow_Consumer.Consumer_Info;
   use type Flow_Consumer.Consumer_Context_Model;
   use type Flow_Consumer.Consumer_Set;
   use type Flow_Consumer.Consumer_Model;
   package Refined renames Editor.Ada_Refined_Global_Depends_Conformance_Legality;
   use type Refined.Refined_Conformance_Id;
   use type Refined.Refined_Context_Kind;
   use type Refined.Refined_Effect_Kind;
   use type Refined.Refined_Conformance_Status;
   use type Refined.Refined_Context_Info;
   use type Refined.Refined_Conformance_Info;
   use type Refined.Refined_Context_Model;
   use type Refined.Refined_Conformance_Set;
   use type Refined.Refined_Conformance_Model;
   package Rep_Final renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
   use type Rep_Final.Final_Representation_Row_Id;
   use type Rep_Final.Final_Representation_Context_Kind;
   use type Rep_Final.Final_Representation_Status;
   use type Rep_Final.Final_Representation_Context_Info;
   use type Rep_Final.Final_Representation_Info;
   use type Rep_Final.Final_Representation_Context_Model;
   use type Rep_Final.Final_Representation_Model;
   use type Rep_Final.Final_Representation_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Flow_Contract_Final_Proof_Legality_Pass1192");
   end Name;

   function Complete_Context
     (Id   : Proof.Flow_Contract_Proof_Row_Id;
      Kind : Proof.Flow_Contract_Proof_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Proof.Flow_Contract_Proof_Context_Info is
      C : Proof.Flow_Contract_Proof_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Subprogram_Name := To_Unbounded_String ("P" & Natural'Image (Natural (Id)));
      C.Object_Name := To_Unbounded_String ("Obj");
      C.Source_Name := To_Unbounded_String ("S");
      C.Target_Name := To_Unbounded_String ("T");
      C.Refined_Status := Refined.Refined_Conformance_Legal_Global_Refinement;
      C.Flow_Status := Flow_Consumer.Consumer_Legal_Flow_Edge_Accepted;
      C.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Legal_Read_Write_Accepted;
      C.Contract_CPD_Status := Contract_CPD.Contract_Predicate_Legal_Global_Aspect_Accepted;
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Accepted;
      C.Representation_Status := Rep_Final.Final_Representation_Legal_Representation_Item_Accepted;
      C.Requires_Refined := True;
      C.Requires_Flow := True;
      C.Requires_Dataflow_Init := True;
      C.Requires_Contract_CPD := True;
      C.Requires_Cross_Unit := True;
      C.Requires_Representation := True;
      C.Source_Fingerprint := Natural (Id) * 1192;
      C.Expected_Source_Fingerprint := Natural (Id) * 1192;
      return C;
   end Complete_Context;

   procedure Accepted_Final_Flow_Contracts_Require_All_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Proof.Flow_Contract_Proof_Context_Model;
      Global : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (1,
           Proof.Flow_Contract_Global_Aspect,
           Editor.Ada_Syntax_Tree.Node_Id (119201));
      Depends : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (2,
           Proof.Flow_Contract_Transitive_Depends_Closure,
           Editor.Ada_Syntax_Tree.Node_Id (119202));
      Volatile_Effect : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (3,
           Proof.Flow_Contract_Volatile_Object_Effect,
           Editor.Ada_Syntax_Tree.Node_Id (119203));
   begin
      Depends.Refined_Status := Refined.Refined_Conformance_Legal_Depends_Refinement;
      Depends.Flow_Status := Flow_Consumer.Consumer_Legal_Depends_Edge_Accepted;
      Depends.Contract_CPD_Status := Contract_CPD.Contract_Predicate_Legal_Depends_Aspect_Accepted;
      Volatile_Effect.Contract_CPD_Status := Contract_CPD.Contract_Predicate_Legal_Refined_Global_Accepted;

      Proof.Add_Context (Contexts, Global);
      Proof.Add_Context (Contexts, Depends);
      Proof.Add_Context (Contexts, Volatile_Effect);

      declare
         Model : constant Proof.Flow_Contract_Proof_Model := Proof.Build (Contexts);
      begin
         Assert (Proof.Row_Count (Model) = 3, "three flow/contract proof rows expected");
         Assert (Proof.Legal_Count (Model) = 3, "complete proof evidence should keep rows legal");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119201)).Status =
            Proof.Flow_Contract_Proof_Legal_Global_Accepted,
            "Global proof should be accepted");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119202)).Status =
            Proof.Flow_Contract_Proof_Legal_Transitive_Depends_Accepted,
            "transitive Depends proof should be accepted");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119203)).Status =
            Proof.Flow_Contract_Proof_Legal_Volatile_Effect_Accepted,
            "volatile effect should be accepted when ordering evidence is present");
         Assert (Proof.Fingerprint (Model) /= 0, "model fingerprint must be deterministic");
      end;
   end Accepted_Final_Flow_Contracts_Require_All_Evidence;

   procedure Missing_Consumer_Evidence_Blocks_Final_Flow_Proof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Proof.Flow_Contract_Proof_Context_Model;
      Missing_Refined : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (1,
           Proof.Flow_Contract_Refined_Global,
           Editor.Ada_Syntax_Tree.Node_Id (119221));
      Missing_Flow : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (2,
           Proof.Flow_Contract_Depends_Aspect,
           Editor.Ada_Syntax_Tree.Node_Id (119222));
      Missing_Init : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (3,
           Proof.Flow_Contract_Global_Aspect,
           Editor.Ada_Syntax_Tree.Node_Id (119223));
      Missing_Contract : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (4,
           Proof.Flow_Contract_Refined_Depends,
           Editor.Ada_Syntax_Tree.Node_Id (119224));
   begin
      Missing_Refined.Refined_Status := Refined.Refined_Conformance_Not_Checked;
      Missing_Flow.Flow_Status := Flow_Consumer.Consumer_Not_Checked;
      Missing_Init.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Not_Checked;
      Missing_Contract.Contract_CPD_Status := Contract_CPD.Contract_Predicate_Not_Checked;

      Proof.Add_Context (Contexts, Missing_Refined);
      Proof.Add_Context (Contexts, Missing_Flow);
      Proof.Add_Context (Contexts, Missing_Init);
      Proof.Add_Context (Contexts, Missing_Contract);

      declare
         Model : constant Proof.Flow_Contract_Proof_Model := Proof.Build (Contexts);
      begin
         Assert (Proof.Legal_Count (Model) = 0, "missing consumers should block final proof");
         Assert (Proof.Refined_Error_Count (Model) = 1, "refined blocker should be counted");
         Assert (Proof.Flow_Error_Count (Model) = 1, "flow blocker should be counted");
         Assert (Proof.Dataflow_Error_Count (Model) = 1, "dataflow blocker should be counted");
         Assert (Proof.Contract_Error_Count (Model) = 1, "contract blocker should be counted");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119221)).Status =
            Proof.Flow_Contract_Proof_Missing_Refined_Conformance_Row,
            "refined conformance evidence should be required");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119222)).Status =
            Proof.Flow_Contract_Proof_Missing_Flow_Consumer_Row,
            "flow consumer evidence should be required");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119223)).Status =
            Proof.Flow_Contract_Proof_Missing_Dataflow_Init_Row,
            "definite initialization dataflow evidence should be required");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119224)).Status =
            Proof.Flow_Contract_Proof_Missing_Contract_CPD_Row,
            "contract CPD evidence should be required");
      end;
   end Missing_Consumer_Evidence_Blocks_Final_Flow_Proof;

   procedure State_And_Effect_Blockers_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Proof.Flow_Contract_Proof_Context_Model;
      Transitive : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (1,
           Proof.Flow_Contract_Transitive_Depends_Closure,
           Editor.Ada_Syntax_Tree.Node_Id (119241));
      Dispatching : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (2,
           Proof.Flow_Contract_Dispatching_Global_Refinement,
           Editor.Ada_Syntax_Tree.Node_Id (119242));
      Abstract_State : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (3,
           Proof.Flow_Contract_Abstract_State,
           Editor.Ada_Syntax_Tree.Node_Id (119243));
      Atomic_Effect : Proof.Flow_Contract_Proof_Context_Info :=
        Complete_Context
          (4,
           Proof.Flow_Contract_Atomic_Object_Effect,
           Editor.Ada_Syntax_Tree.Node_Id (119244));
   begin
      Transitive.Transitive_Depends_Missing_Edge := True;
      Dispatching.Dispatching_Global_Not_Refined := True;
      Abstract_State.Abstract_State_Mode_Mismatch := True;
      Atomic_Effect.Atomic_Read_Write_Error := True;

      Proof.Add_Context (Contexts, Transitive);
      Proof.Add_Context (Contexts, Dispatching);
      Proof.Add_Context (Contexts, Abstract_State);
      Proof.Add_Context (Contexts, Atomic_Effect);

      declare
         Model : constant Proof.Flow_Contract_Proof_Model := Proof.Build (Contexts);
      begin
         Assert (Proof.Legal_Count (Model) = 0, "state/effect blockers must not remain legal");
         Assert (Proof.State_Effect_Error_Count (Model) = 4, "state/effect blockers should be counted");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119241)).Status =
            Proof.Flow_Contract_Proof_Transitive_Depends_Missing_Edge,
            "missing transitive Depends edge should be preserved");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119242)).Status =
            Proof.Flow_Contract_Proof_Dispatching_Global_Not_Refined,
            "dispatching Global refinement blocker should be preserved");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119243)).Status =
            Proof.Flow_Contract_Proof_Abstract_State_Mode_Mismatch,
            "abstract state mode blocker should be preserved");
         Assert
           (Proof.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119244)).Status =
            Proof.Flow_Contract_Proof_Atomic_Read_Write_Blocker,
            "atomic effect blocker should be preserved");
      end;
   end State_And_Effect_Blockers_Are_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Final_Flow_Contracts_Require_All_Evidence'Access,
         "accepted final flow contracts require all evidence");
      Register_Routine
        (T,
         Missing_Consumer_Evidence_Blocks_Final_Flow_Proof'Access,
         "missing consumer evidence blocks final flow proof");
      Register_Routine
        (T,
         State_And_Effect_Blockers_Are_Preserved'Access,
         "state and effect blockers are preserved");
   end Register_Tests;

end Test_Ada_Flow_Contract_Final_Proof_Legality_Pass1192;
