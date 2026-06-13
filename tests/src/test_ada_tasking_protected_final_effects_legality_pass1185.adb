with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Tasking_Protected_Effects_Legality;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;

package body Test_Ada_Tasking_Protected_Final_Effects_Legality_Pass1185 is

   package Final renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;
   use type Final.Final_Tasking_Row_Id;
   use type Final.Final_Tasking_Context_Kind;
   use type Final.Final_Tasking_Status;
   use type Final.Final_Tasking_Context_Info;
   use type Final.Final_Tasking_Info;
   use type Final.Final_Tasking_Context_Model;
   use type Final.Final_Tasking_Set;
   use type Final.Final_Tasking_Model;
   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Access_Final.Master_Scope_Final_Context_Kind;
   use type Access_Final.Master_Scope_Final_Status;
   use type Access_Final.Master_Scope_Final_Context_Info;
   use type Access_Final.Master_Scope_Final_Info;
   use type Access_Final.Master_Scope_Final_Context_Model;
   use type Access_Final.Master_Scope_Final_Set;
   use type Access_Final.Master_Scope_Final_Model;
   package Disc renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   use type Disc.Discriminant_Consumer_Row_Id;
   use type Disc.Discriminant_Consumer_Context_Kind;
   use type Disc.Discriminant_Consumer_Status;
   use type Disc.Discriminant_Consumer_Context_Info;
   use type Disc.Discriminant_Consumer_Info;
   use type Disc.Discriminant_Consumer_Context_Model;
   use type Disc.Discriminant_Consumer_Set;
   use type Disc.Discriminant_Consumer_Model;
   package Elab renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   use type Elab.Final_Elaboration_Row_Id;
   use type Elab.Final_Elaboration_Context_Kind;
   use type Elab.Final_Elaboration_Status;
   use type Elab.Final_Elaboration_Context_Info;
   use type Elab.Final_Elaboration_Info;
   use type Elab.Final_Elaboration_Context_Model;
   use type Elab.Final_Elaboration_Set;
   use type Elab.Final_Elaboration_Model;
   package Rep renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep.Representation_Tasking_CPD_Row_Id;
   use type Rep.Representation_Tasking_CPD_Context_Kind;
   use type Rep.Representation_Tasking_CPD_Status;
   use type Rep.Representation_Tasking_CPD_Context_Info;
   use type Rep.Representation_Tasking_CPD_Info;
   use type Rep.Representation_Tasking_CPD_Context_Model;
   use type Rep.Representation_Tasking_CPD_Set;
   use type Rep.Representation_Tasking_CPD_Model;
   package Task_CPD renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Task_CPD.Tasking_Contract_Predicate_Row_Id;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Kind;
   use type Task_CPD.Tasking_Contract_Predicate_Status;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Info;
   use type Task_CPD.Tasking_Contract_Predicate_Info;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Model;
   use type Task_CPD.Tasking_Contract_Predicate_Set;
   use type Task_CPD.Tasking_Contract_Predicate_Model;
   package Effects renames Editor.Ada_Tasking_Protected_Effects_Legality;
   use type Effects.Tasking_Effect_Id;
   use type Effects.Tasking_Effect_Context_Kind;
   use type Effects.Tasking_Effect_Status;
   use type Effects.Tasking_Effect_Context_Info;
   use type Effects.Tasking_Effect_Info;
   use type Effects.Tasking_Effect_Context_Model;
   use type Effects.Tasking_Effect_Set;
   use type Effects.Tasking_Effect_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Protected_Final_Effects_Legality_Pass1185");
   end Name;

   procedure Fill_Common (C : in out Final.Final_Tasking_Context_Info; Id : Natural) is
   begin
      C.Id := Final.Final_Tasking_Row_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118500 + Id);
      C.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      C.Entry_Name := To_Unbounded_String ("Feed_Item" & Natural'Image (Id));
      C.Tasking_Effect_Row := Effects.Tasking_Effect_Id (Id);
      C.Tasking_Effect_Status := Effects.Tasking_Effect_Legal_Task_Activation;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (Id);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Legal_Task_Activation_Accepted;
      C.Tasking_CPD_Matches := 1;
      C.Elaboration_Row := Elab.Final_Elaboration_Row_Id (Id);
      C.Elaboration_Status := Elab.Final_Elaboration_Legal_Task_Activation_Accepted;
      C.Elaboration_Matches := 1;
      C.Representation_Row := Rep.Representation_Tasking_CPD_Row_Id (Id);
      C.Representation_Status := Rep.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted;
      C.Representation_Matches := 1;
      C.Accessibility_Row := Access_Final.Master_Scope_Final_Row_Id (Id);
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Return_Access_Accepted;
      C.Accessibility_Matches := 1;
      C.Discriminant_Row := Disc.Discriminant_Consumer_Row_Id (Id);
      C.Discriminant_Status := Disc.Discriminant_Consumer_Legal_Access_Discriminant_Accepted;
      C.Discriminant_Matches := 1;
      C.Source_Fingerprint := 1_185_000 + Id;
      C.Consumer_Fingerprint := 1_186_000 + Id;
   end Fill_Common;

   function Sample_Context_Model return Final.Final_Tasking_Context_Model is
      Contexts : Final.Final_Tasking_Context_Model;
      C        : Final.Final_Tasking_Context_Info;
   begin
      Fill_Common (C, 1);
      C.Kind := Final.Final_Tasking_Task_Activation;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 2);
      C.Kind := Final.Final_Tasking_Protected_Function_Call;
      C.Protected_Function_Writes_State := True;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 3);
      C.Kind := Final.Final_Tasking_Barrier_Side_Effect;
      C.Barrier_Has_Side_Effect := True;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Kind := Final.Final_Tasking_Requeue_With_Abort;
      C.Requeue_With_Abort := True;
      C.Requeue_Abort_Safe := False;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Kind := Final.Final_Tasking_Terminate_Alternative;
      C.Terminate_Allowed := False;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Kind := Final.Final_Tasking_Protected_Entry_Call;
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Read_Before_Write_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Kind := Final.Final_Tasking_Task_Termination;
      C.Elaboration_Status := Elab.Final_Elaboration_Representation_Freezing_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Kind := Final.Final_Tasking_Select_Guard;
      C.Tasking_Effect_Status := Effects.Tasking_Effect_Select_Guard_Not_Boolean;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 9);
      C.Kind := Final.Final_Tasking_Accept_Body;
      C.Requires_Accessibility := True;
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Return_Access_Master_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 10);
      C.Kind := Final.Final_Tasking_Protected_Read;
      C.Requires_Discriminant := True;
      C.Discriminant_Status := Disc.Discriminant_Consumer_Variant_Coverage_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 11);
      C.Kind := Final.Final_Tasking_Protected_Write;
      C.Tasking_CPD_Row := Task_CPD.No_Tasking_Contract_Predicate_Row;
      C.Tasking_CPD_Matches := 0;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 12);
      C.Kind := Final.Final_Tasking_Abortable_Part;
      C.Elaboration_Status := Elab.Final_Elaboration_Indeterminate;
      Final.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final.Final_Tasking_Model := Final.Build (Sample_Context_Model);
   begin
      Assert (Final.Row_Count (Model) = 12, "expected twelve final tasking rows");
      Assert (Final.Legal_Count (Model) = 1, "only complete task activation should remain legal");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Protected_State_Mutation_Blocker) = 1,
              "protected functions that mutate visible state must be blocked");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Barrier_Side_Effect_Blocker) = 1,
              "barrier side effects must be rejected");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Requeue_With_Abort_Unsafe) = 1,
              "unsafe requeue with abort must be rejected");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Terminate_Alternative_Blocker) = 1,
              "illegal terminate alternatives must be preserved");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Initialization_Blocker) = 1,
              "initialization blockers must propagate through tasking CPD evidence");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Representation_Blocker) = 1,
              "elaboration representation/freezing blockers must be preserved");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Barrier_Not_Boolean_Blocker) = 1,
              "non-Boolean select guards must block final tasking effects");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Accessibility_Blocker) = 1,
              "accessibility blockers must be preserved");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Discriminant_Blocker) = 1,
              "discriminant/variant blockers must be preserved");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Missing_Tasking_CPD_Row) = 1,
              "missing tasking CPD evidence must block confident effects");
      Assert (Final.Count_Status (Model, Final.Final_Tasking_Indeterminate) = 1,
              "indeterminate elaboration evidence must remain indeterminate");
      Assert (Final.Base_Effect_Error_Count (Model) = 5, "expected final direct tasking blockers");
      Assert (Final.Elaboration_Error_Count (Model) = 2, "expected elaboration/object-state blockers");
      Assert (Final.Representation_Error_Count (Model) = 1, "expected representation blocker");
      Assert (Final.Accessibility_Error_Count (Model) = 1, "expected accessibility blocker");
      Assert (Final.Discriminant_Error_Count (Model) = 1, "expected discriminant blocker");
      Assert (Final.Indeterminate_Count (Model) = 1, "expected one indeterminate row");
      Assert (Final.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model   : constant Final.Final_Tasking_Model := Final.Build (Sample_Context_Model);
      Row     : constant Final.Final_Tasking_Info :=
        Final.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118503));
      By_Name : constant Final.Final_Tasking_Set := Final.Rows_For_Object_Name (Model, "Obj 3");
      By_Kind : constant Final.Final_Tasking_Set :=
        Final.Rows_For_Kind (Model, Final.Final_Tasking_Protected_Function_Call);
   begin
      Assert (Row.Status = Final.Final_Tasking_Barrier_Side_Effect_Blocker,
              "node lookup must preserve barrier side-effect blocker");
      Assert (Final.Set_Count (By_Name) = 1, "object-name lookup must be deterministic");
      Assert (Final.Set_Count (By_Kind) = 1, "one protected function call context expected");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "final tasking effect blockers");
      Register_Routine (T, Test_Queries'Access, "final tasking effect lookups");
   end Register_Tests;

end Test_Ada_Tasking_Protected_Final_Effects_Legality_Pass1185;
