with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Predicate_Invariant_Propagation_Legality_Pass1139 is

   package PIL renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   use type PIL.Propagation_Row_Id;
   use type PIL.Propagation_Context_Kind;
   use type PIL.Propagation_Obligation_Kind;
   use type PIL.Propagation_Status;
   use type PIL.Propagation_Context_Info;
   use type PIL.Propagation_Info;
   use type PIL.Propagation_Context_Model;
   use type PIL.Propagation_Set;
   use type PIL.Propagation_Model;
   package PIU renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   use type PIU.Predicate_Policy;
   use type PIU.Static_Legality_Status;
   use type PIU.Assignment_Legality_Status;
   use type PIU.Return_Legality_Status;
   use type PIU.Semantic_Legality_Status;
   use type PIU.Overload_Legality_Status;
   use type PIU.Instance_Legality_Status;
   use type PIU.Predicate_Use_Context_Id;
   use type PIU.Predicate_Use_Legality_Id;
   use type PIU.Predicate_Use_Context_Kind;
   use type PIU.Invariant_Policy;
   use type PIU.Use_Site_Check_Point;
   use type PIU.Predicate_Use_Legality_Status;
   use type PIU.Predicate_Use_Context_Info;
   use type PIU.Predicate_Use_Legality_Info;
   use type PIU.Predicate_Use_Context_Model;
   use type PIU.Predicate_Use_Result_Set;
   use type PIU.Predicate_Use_Legality_Model;
   package FEG renames Editor.Ada_Flow_Effect_Graph_Legality;
   use type FEG.Flow_Edge_Id;
   use type FEG.Flow_Graph_Context_Kind;
   use type FEG.Flow_Edge_Kind;
   use type FEG.Flow_Effect_Graph_Status;
   use type FEG.Flow_Effect_Context_Info;
   use type FEG.Flow_Effect_Info;
   use type FEG.Flow_Effect_Context_Model;
   use type FEG.Flow_Effect_Set;
   use type FEG.Flow_Effect_Graph_Model;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Gates.Enforcement_Row_Id;
   use type Gates.Widened_Legality_Engine;
   use type Gates.Enforcement_Status;
   use type Gates.Enforcement_Context_Info;
   use type Gates.Enforcement_Info;
   use type Gates.Enforcement_Context_Model;
   use type Gates.Enforcement_Set;
   use type Gates.Enforcement_Model;
   package SRP renames Editor.Ada_Staticness_Range_Predicate_Legality;
   use type SRP.Assignment_Legality_Id;
   use type SRP.Assignment_Legality_Status;
   use type SRP.Return_Legality_Id;
   use type SRP.Return_Legality_Status;
   use type SRP.Semantic_Legality_Id;
   use type SRP.Semantic_Legality_Status;
   use type SRP.Overload_Legality_Id;
   use type SRP.Overload_Legality_Status;
   use type SRP.Static_Context_Id;
   use type SRP.Static_Legality_Id;
   use type SRP.Static_Context_Kind;
   use type SRP.Predicate_Policy;
   use type SRP.Static_Legality_Status;
   use type SRP.Static_Legality_Context_Info;
   use type SRP.Static_Legality_Info;
   use type SRP.Static_Legality_Context_Model;
   use type SRP.Static_Legality_Result_Set;
   use type SRP.Static_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Predicate_Invariant_Propagation_Legality_Pass1139");
   end Name;

   function Sample_Context_Model return PIL.Propagation_Context_Model is
      Contexts : PIL.Propagation_Context_Model;
      C        : PIL.Propagation_Context_Info;
   begin
      C.Id := 1;
      C.Kind := PIL.Propagation_Context_Call_Source;
      C.Obligation := PIL.Obligation_Dynamic_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113901);
      C.Subtype_Name := To_Unbounded_String ("Positive_Count");
      C.Caller_Name := To_Unbounded_String ("Caller");
      C.Callee_Name := To_Unbounded_String ("Callee");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check;
      C.Requires_Check := True;
      C.Check_Propagated := True;
      C.Dynamic_Check := True;
      C.Source_Fingerprint := 901;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := PIL.Propagation_Context_Call_Result;
      C.Obligation := PIL.Obligation_Dynamic_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113902);
      C.Subtype_Name := To_Unbounded_String ("Positive_Count");
      C.Caller_Name := To_Unbounded_String ("Caller");
      C.Callee_Name := To_Unbounded_String ("Unchecked_Callee");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check;
      C.Requires_Check := True;
      C.Check_Propagated := False;
      C.Dynamic_Check := True;
      C.Source_Fingerprint := 902;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := PIL.Propagation_Context_Generic_Instance;
      C.Obligation := PIL.Obligation_Generic_Actual_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113903);
      C.Generic_Formal_Name := To_Unbounded_String ("Formal_Index");
      C.Generic_Actual_Name := To_Unbounded_String ("Actual_Index");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Linked_Generic_Actual;
      C.Requires_Check := True;
      C.Check_Propagated := True;
      C.Generic_Substitution_Preserves_Check := False;
      C.Source_Fingerprint := 903;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := PIL.Propagation_Context_Derived_Type;
      C.Obligation := PIL.Obligation_Derived_Type_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113904);
      C.Subtype_Name := To_Unbounded_String ("Child_T");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Invariant_Preserved;
      C.Requires_Check := True;
      C.Check_Propagated := True;
      C.Derived_View_Preserves_Invariant := False;
      C.Source_Fingerprint := 904;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := PIL.Propagation_Context_Visible_State_Update;
      C.Obligation := PIL.Obligation_State_Update_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113905);
      C.Object_Name := To_Unbounded_String ("Visible_State");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Invariant_Preserved;
      C.Flow_Status := FEG.Flow_Graph_Legal_Write_Edge;
      C.Requires_Check := True;
      C.Check_Propagated := False;
      C.State_Was_Updated := True;
      C.State_Covered_By_Flow := True;
      C.Source_Fingerprint := 905;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := PIL.Propagation_Context_Flow_Effect;
      C.Obligation := PIL.Obligation_State_Update_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113906);
      C.Object_Name := To_Unbounded_String ("Uncovered_State");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Invariant_Preserved;
      C.Flow_Status := FEG.Flow_Graph_Write_Not_In_Global;
      C.Requires_Check := True;
      C.Check_Propagated := False;
      C.State_Was_Updated := True;
      C.State_Covered_By_Flow := False;
      C.Source_Fingerprint := 906;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := PIL.Propagation_Context_Private_View;
      C.Obligation := PIL.Obligation_Private_View_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113907);
      C.Subtype_Name := To_Unbounded_String ("Private_T");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Invariant_Preserved;
      C.Requires_Check := True;
      C.Check_Propagated := True;
      C.Private_View_Resolved := False;
      C.Source_Fingerprint := 907;
      PIL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := PIL.Propagation_Context_Assignment;
      C.Obligation := PIL.Obligation_Static_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113908);
      C.Subtype_Name := To_Unbounded_String ("Small_Range");
      C.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Static_Predicate;
      C.Requires_Check := True;
      C.Check_Propagated := True;
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 908;
      PIL.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Predicate_Invariant_Checks_Propagate_Through_Semantic_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant PIL.Propagation_Model := PIL.Build (Sample_Context_Model);
      Call_Ok : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113901));
      Call_Missing : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113902));
      Generic_Missing : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113903));
      Derived_Missing : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113904));
      State_Update : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113905));
      Flow_Missing : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113906));
      Private_Barrier : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113907));
      Gate_Blocker : constant PIL.Propagation_Info :=
        PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113908));
   begin
      Assert (PIL.Row_Count (Model) = 8,
              "all predicate/invariant propagation contexts should be analyzed");
      Assert (Call_Ok.Status = PIL.Propagation_Legal_Dynamic_Predicate_Propagated,
              "dynamic predicate checks should propagate across call edges");
      Assert (Call_Missing.Status = PIL.Propagation_Call_Chain_Check_Missing,
              "missing call-chain propagation should be rejected");
      Assert (Generic_Missing.Status = PIL.Propagation_Generic_Actual_Check_Missing,
              "generic actual substitution must preserve predicate checks");
      Assert (Derived_Missing.Status = PIL.Propagation_Derived_Type_Invariant_Missing,
              "derived types must preserve inherited invariant obligations");
      Assert (State_Update.Status = PIL.Propagation_Invariant_Violated_After_State_Update,
              "visible state update must recheck the invariant");
      Assert (Flow_Missing.Status = PIL.Propagation_Linked_Flow_Effect_Error,
              "illegal flow-effect rows should remain linked blockers");
      Assert (Private_Barrier.Status = PIL.Propagation_Private_View_Barrier,
              "private-view barriers should block invariant propagation proof");
      Assert (Gate_Blocker.Status = PIL.Propagation_Coverage_Gate_Blocker,
              "coverage gates should block confident predicate propagation");
      Assert (PIL.Legal_Count (Model) = 1,
              "only the call-source dynamic predicate row should remain legal");
      Assert (PIL.Predicate_Error_Count (Model) = 2,
              "call-chain and generic predicate propagation errors should be counted");
      Assert (PIL.Invariant_Error_Count (Model) = 3,
              "derived, state-update, and private-view invariant errors should be counted");
      Assert (PIL.Flow_Error_Count (Model) = 1,
              "linked flow-effect error should be counted");
      Assert (PIL.Coverage_Gate_Error_Count (Model) = 1,
              "coverage gate blocker should be counted");
      Assert (PIL.Fingerprint (Model) /= 0,
              "propagation model should have a deterministic non-zero fingerprint");
   end Predicate_Invariant_Checks_Propagate_Through_Semantic_Edges;

   procedure Predicate_Use_Rows_Are_Converted_To_Propagation_Contexts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : PIU.Predicate_Use_Context_Model;
      C        : PIU.Predicate_Use_Context_Info;
   begin
      C.Id := 1;
      C.Kind := PIU.Predicate_Use_Call_Actual;
      C.Check_Point := PIU.Check_Point_Call_Entry;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113921);
      C.Subtype_Name := To_Unbounded_String ("Positive_Count");
      C.Predicate := SRP.Predicate_Dynamic;
      C.Requires_Predicate_Check := True;
      C.Check_Is_Inserted := True;
      PIU.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := PIU.Predicate_Use_Generic_Actual;
      C.Check_Point := PIU.Check_Point_Generic_Instantiation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113922);
      C.Subtype_Name := To_Unbounded_String ("Small_Range");
      C.Predicate := SRP.Predicate_Static_Known_True;
      C.Requires_Static_Predicate := True;
      C.Check_Is_Inserted := True;
      PIU.Add_Context (Contexts, C);

      declare
         Use_Model : constant PIU.Predicate_Use_Legality_Model := PIU.Build (Contexts);
         Model     : constant PIL.Propagation_Model := PIL.Build_From_Predicate_Uses (Use_Model);
         Call_Row  : constant PIL.Propagation_Info :=
           PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113921));
         Gen_Row   : constant PIL.Propagation_Info :=
           PIL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113922));
      begin
         Assert (PIL.Row_Count (Model) = 2,
                 "predicate use-site rows should become propagation rows");
         Assert (Call_Row.Kind = PIL.Propagation_Context_Call_Source,
                 "call actual use-site should map to a call-source propagation context");
         Assert (Gen_Row.Kind = PIL.Propagation_Context_Generic_Instance,
                 "generic actual use-site should map to generic propagation context");
         Assert (PIL.Legal_Count (Model) = 2,
                 "converted legal use-site rows should preserve propagated checks");
      end;
   end Predicate_Use_Rows_Are_Converted_To_Propagation_Contexts;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Predicate_Invariant_Checks_Propagate_Through_Semantic_Edges'Access,
         "predicate/invariant checks propagate through calls, generics, views, and flow effects");
      Register_Routine
        (T,
         Predicate_Use_Rows_Are_Converted_To_Propagation_Contexts'Access,
         "Pass1124 predicate use-site rows are converted into propagation contexts");
   end Register_Tests;

end Test_Ada_Predicate_Invariant_Propagation_Legality_Pass1139;
