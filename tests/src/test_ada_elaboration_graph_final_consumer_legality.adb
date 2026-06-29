with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;

package body Test_Ada_Elaboration_Graph_Final_Consumer_Legality is

   package Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   use type Final.Final_Elaboration_Row_Id;
   use type Final.Final_Elaboration_Context_Kind;
   use type Final.Final_Elaboration_Status;
   use type Final.Final_Elaboration_Context_Info;
   use type Final.Final_Elaboration_Info;
   use type Final.Final_Elaboration_Context_Model;
   use type Final.Final_Elaboration_Set;
   use type Final.Final_Elaboration_Model;
   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Access_Final.Master_Scope_Final_Context_Kind;
   use type Access_Final.Master_Scope_Final_Status;
   use type Access_Final.Master_Scope_Final_Context_Info;
   use type Access_Final.Master_Scope_Final_Info;
   use type Access_Final.Master_Scope_Final_Context_Model;
   use type Access_Final.Master_Scope_Final_Set;
   use type Access_Final.Master_Scope_Final_Model;
   package Elab renames Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Elab.Elaboration_Contract_Predicate_Row_Id;
   use type Elab.Elaboration_Contract_Predicate_Context_Kind;
   use type Elab.Elaboration_Contract_Predicate_Status;
   use type Elab.Elaboration_Contract_Predicate_Context_Info;
   use type Elab.Elaboration_Contract_Predicate_Info;
   use type Elab.Elaboration_Contract_Predicate_Context_Model;
   use type Elab.Elaboration_Contract_Predicate_Set;
   use type Elab.Elaboration_Contract_Predicate_Model;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;
   package Overload renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   use type Overload.Overload_Type_Edge_Row_Id;
   use type Overload.Overload_Type_Edge_Context_Kind;
   use type Overload.Overload_Type_Edge_Status;
   use type Overload.Overload_Type_Edge_Context_Info;
   use type Overload.Overload_Type_Edge_Info;
   use type Overload.Overload_Type_Edge_Context_Model;
   use type Overload.Overload_Type_Edge_Result_Set;
   use type Overload.Overload_Type_Edge_Model;
   package Rep renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep.Representation_Tasking_CPD_Row_Id;
   use type Rep.Representation_Tasking_CPD_Context_Kind;
   use type Rep.Representation_Tasking_CPD_Status;
   use type Rep.Representation_Tasking_CPD_Context_Info;
   use type Rep.Representation_Tasking_CPD_Info;
   use type Rep.Representation_Tasking_CPD_Context_Model;
   use type Rep.Representation_Tasking_CPD_Set;
   use type Rep.Representation_Tasking_CPD_Model;
   package Tasking renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Tasking.Tasking_Contract_Predicate_Row_Id;
   use type Tasking.Tasking_Contract_Predicate_Context_Kind;
   use type Tasking.Tasking_Contract_Predicate_Status;
   use type Tasking.Tasking_Contract_Predicate_Context_Info;
   use type Tasking.Tasking_Contract_Predicate_Info;
   use type Tasking.Tasking_Contract_Predicate_Context_Model;
   use type Tasking.Tasking_Contract_Predicate_Set;
   use type Tasking.Tasking_Contract_Predicate_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Elaboration_Graph_Final_Consumer_Legality");
   end Name;

   procedure Fill_Common (C : in out Final.Final_Elaboration_Context_Info; Id : Natural) is
   begin
      C.Id := Final.Final_Elaboration_Row_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118400 + Id);
      C.Context_Name := To_Unbounded_String ("Ctx" & Natural'Image (Id));
      C.Source_Unit_Name := To_Unbounded_String ("Source");
      C.Target_Unit_Name := To_Unbounded_String ("Target");
      C.Elaboration_Row := Elab.Elaboration_Contract_Predicate_Row_Id (Id);
      C.Elaboration_Status := Elab.Elaboration_Contract_Predicate_Legal_Call_Accepted;
      C.Elaboration_Matches := 1;
      C.Overload_Row := Overload.Overload_Type_Edge_Row_Id (Id);
      C.Overload_Status := Overload.Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted;
      C.Overload_Matches := 1;
      C.Representation_Row := Rep.Representation_Tasking_CPD_Row_Id (Id);
      C.Representation_Status := Rep.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted;
      C.Representation_Matches := 1;
      C.Tasking_Row := Tasking.Tasking_Contract_Predicate_Row_Id (Id);
      C.Tasking_Status := Tasking.Tasking_Contract_Predicate_Legal_Task_Activation_Accepted;
      C.Tasking_Matches := 1;
      C.Generic_Backmap_Row := Backmap.Generic_Backmap_Row_Id (Id);
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Legal_Call_Backmapped;
      C.Generic_Backmap_Matches := 1;
      C.Accessibility_Row := Access_Final.Master_Scope_Final_Row_Id (Id);
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Return_Access_Accepted;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1_184_000 + Id;
      C.Consumer_Fingerprint := 1_185_000 + Id;
   end Fill_Common;

   function Sample_Context_Model return Final.Final_Elaboration_Context_Model is
      Contexts : Final.Final_Elaboration_Context_Model;
      C        : Final.Final_Elaboration_Context_Info;
   begin
      Fill_Common (C, 1);
      C.Kind := Final.Final_Elaboration_Direct_Call;
      C.Requires_Overload := True;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 2);
      C.Kind := Final.Final_Elaboration_Default_Expression;
      C.Elaboration_Status := Elab.Elaboration_Contract_Predicate_Read_Before_Write_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 3);
      C.Kind := Final.Final_Elaboration_Representation_Item;
      C.Requires_Representation := True;
      C.Representation_Status := Rep.Representation_Tasking_CPD_Representation_Freezing_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Kind := Final.Final_Elaboration_Task_Activation;
      C.Requires_Tasking := True;
      C.Tasking_Status := Tasking.Tasking_Contract_Predicate_Lifetime_Accessibility_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Kind := Final.Final_Elaboration_Generic_Replay;
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Missing_Formal_Actual_Map;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Kind := Final.Final_Elaboration_Indirect_Call;
      C.Requires_Overload := True;
      C.Overload_Status := Overload.Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Kind := Final.Final_Elaboration_Aspect_Expression;
      C.Elaboration_Row := Elab.No_Elaboration_Contract_Predicate_Row;
      C.Elaboration_Matches := 0;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Kind := Final.Final_Elaboration_Generic_Instance;
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Matches := 2;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 9);
      C.Kind := Final.Final_Elaboration_Preelaboration_Policy;
      C.Requires_Accessibility := True;
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Return_Access_Master_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 10);
      C.Kind := Final.Final_Elaboration_Pure_Policy;
      C.Elaboration_Status := Elab.Elaboration_Contract_Predicate_Contract_Predicate_Indeterminate;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 11);
      C.Kind := Final.Final_Elaboration_Task_Termination;
      C.Requires_Tasking := True;
      C.Tasking_Row := Tasking.No_Tasking_Contract_Predicate_Row;
      C.Tasking_Matches := 0;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 12);
      C.Kind := Final.Final_Elaboration_Representation_Item;
      C.Requires_Representation := True;
      C.Representation_Row := Rep.No_Representation_Tasking_CPD_Row;
      C.Representation_Matches := 0;
      Final.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final.Final_Elaboration_Model := Final.Build (Sample_Context_Model);
   begin
      Assert (Final.Row_Count (Model) = 12, "expected twelve final elaboration rows");
      Assert (Final.Legal_Count (Model) = 1, "only complete call elaboration evidence should remain legal");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Read_Before_Write_Blocker) = 1,
              "default-expression read-before-write must block final elaboration consumption");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Lifetime_Accessibility_Blocker) = 1,
              "tasking lifetime evidence must block task activation consumers");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Generic_Backmap_Blocker) = 1,
              "generic replay backmapping failures must be preserved");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Overload_Type_Ambiguous) = 1,
              "overload/type ambiguities must block elaboration-time calls");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Missing_Elaboration_Row) = 1,
              "missing elaboration rows must block consumers");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Multiple_Matching_Blockers) = 1,
              "duplicate dependent rows must block confident consumption");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Accessibility_Blocker) = 1,
              "accessibility blockers must be preserved for policy contexts");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Indeterminate) = 1,
              "indeterminate elaboration evidence must remain indeterminate");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Missing_Tasking_Row) = 1,
              "missing tasking evidence must block task termination consumers");
      Assert (Final.Count_Status (Model, Final.Final_Elaboration_Missing_Representation_Row) = 1,
              "missing representation evidence must block representation-item consumers");
      Assert (Final.Elaboration_Error_Count (Model) = 4, "expected elaboration-family blockers");
      Assert (Final.Overload_Error_Count (Model) = 1, "expected one overload-family blocker");
      Assert (Final.Representation_Error_Count (Model) = 1, "expected representation-family blocker");
      Assert (Final.Tasking_Error_Count (Model) = 2, "expected two direct tasking consumer blockers");
      Assert (Final.Generic_Backmap_Error_Count (Model) = 1, "expected one generic backmapping blocker");
      Assert (Final.Accessibility_Error_Count (Model) = 2, "expected tasking lifetime and policy accessibility blockers");
      Assert (Final.Indeterminate_Count (Model) = 1, "expected one indeterminate row");
      Assert (Final.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model   : constant Final.Final_Elaboration_Model := Final.Build (Sample_Context_Model);
      Row     : constant Final.Final_Elaboration_Info :=
        Final.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118405));
      By_Name : constant Final.Final_Elaboration_Set := Final.Rows_For_Context_Name (Model, "Ctx 5");
      By_Kind : constant Final.Final_Elaboration_Set :=
        Final.Rows_For_Kind (Model, Final.Final_Elaboration_Representation_Item);
   begin
      Assert (Row.Status = Final.Final_Elaboration_Generic_Backmap_Blocker,
              "node lookup must preserve generic backmap blocker");
      Assert (Final.Set_Count (By_Name) = 1, "context-name lookup must be deterministic");
      Assert (Final.Set_Count (By_Kind) = 2, "two representation item contexts expected");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "final elaboration consumer blockers");
      Register_Routine (T, Test_Queries'Access, "final elaboration consumer lookups");
   end Register_Tests;

end Test_Ada_Elaboration_Graph_Final_Consumer_Legality;
