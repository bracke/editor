with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package body Test_Ada_Exception_Finalization_Legality_Pass1116 is

   package EFL renames Editor.Ada_Exception_Finalization_Legality;
   use type EFL.Accessibility_Legality_Status;
   use type EFL.Contract_Legality_Status;
   use type EFL.Flow_Legality_Status;
   use type EFL.Elaboration_Legality_Status;
   use type EFL.Renaming_Legality_Status;
   use type EFL.Completion_Legality_Status;
   use type EFL.Exception_Context_Id;
   use type EFL.Exception_Legality_Id;
   use type EFL.Exception_Context_Kind;
   use type EFL.Exception_Target_State;
   use type EFL.Handler_State;
   use type EFL.Finalization_State;
   use type EFL.No_Return_State;
   use type EFL.Exception_Legality_Status;
   use type EFL.Exception_Context_Info;
   use type EFL.Exception_Legality_Info;
   use type EFL.Exception_Context_Model;
   use type EFL.Exception_Result_Set;
   use type EFL.Exception_Legality_Model;
   package AAL renames Editor.Ada_Accessibility_Lifetime_Legality;
   use type AAL.Assignment_Legality_Id;
   use type AAL.Assignment_Legality_Status;
   use type AAL.Return_Legality_Id;
   use type AAL.Return_Legality_Status;
   use type AAL.Semantic_Legality_Id;
   use type AAL.Semantic_Legality_Status;
   use type AAL.Static_Legality_Id;
   use type AAL.Static_Legality_Status;
   use type AAL.Accessibility_Context_Id;
   use type AAL.Accessibility_Legality_Id;
   use type AAL.Access_Context_Kind;
   use type AAL.Access_Target_Kind;
   use type AAL.Accessibility_Level;
   use type AAL.Alias_Requirement;
   use type AAL.Accessibility_Legality_Status;
   use type AAL.Accessibility_Context_Info;
   use type AAL.Accessibility_Legality_Info;
   use type AAL.Accessibility_Context_Model;
   use type AAL.Accessibility_Result_Set;
   use type AAL.Accessibility_Legality_Model;
   package CAL renames Editor.Ada_Contract_Aspect_Legality;
   use type CAL.Assignment_Legality_Status;
   use type CAL.Return_Legality_Status;
   use type CAL.Static_Legality_Status;
   use type CAL.Accessibility_Legality_Status;
   use type CAL.Overload_Legality_Status;
   use type CAL.Cross_Unit_Semantic_Status;
   use type CAL.Contract_Context_Id;
   use type CAL.Contract_Legality_Id;
   use type CAL.Contract_Context_Kind;
   use type CAL.Contract_Subject_Kind;
   use type CAL.Boolean_Expression_State;
   use type CAL.Aspect_Placement;
   use type CAL.Flow_Contract_State;
   use type CAL.Contract_Legality_Status;
   use type CAL.Contract_Context_Info;
   use type CAL.Contract_Legality_Info;
   use type CAL.Contract_Context_Model;
   use type CAL.Contract_Result_Set;
   use type CAL.Contract_Legality_Model;
   package CFL renames Editor.Ada_Control_Flow_Legality;
   use type CFL.Flow_Context_Id;
   use type CFL.Flow_Legality_Id;
   use type CFL.Flow_Context_Kind;
   use type CFL.Flow_Legality_Status;
   use type CFL.Flow_Context_Info;
   use type CFL.Flow_Legality_Info;
   use type CFL.Flow_Context_Model;
   use type CFL.Flow_Legality_Result_Set;
   use type CFL.Flow_Legality_Model;
   package EDL renames Editor.Ada_Elaboration_Dependence_Legality;
   use type EDL.Cross_Unit_Semantic_Status;
   use type EDL.Contract_Legality_Status;
   use type EDL.Overload_Legality_Status;
   use type EDL.Elaboration_Context_Id;
   use type EDL.Elaboration_Legality_Id;
   use type EDL.Elaboration_Context_Kind;
   use type EDL.Elaboration_Dependence_Kind;
   use type EDL.Elaboration_Pragma_State;
   use type EDL.Elaboration_Order_State;
   use type EDL.Elaboration_Policy_State;
   use type EDL.Elaboration_Legality_Status;
   use type EDL.Elaboration_Context_Info;
   use type EDL.Elaboration_Legality_Info;
   use type EDL.Elaboration_Context_Model;
   use type EDL.Elaboration_Result_Set;
   use type EDL.Elaboration_Legality_Model;
   package RAV renames Editor.Ada_Renaming_Alias_Visibility_Legality;
   use type RAV.Accessibility_Legality_Status;
   use type RAV.Cross_Unit_Semantic_Status;
   use type RAV.Overload_Legality_Status;
   use type RAV.Completion_Legality_Status;
   use type RAV.Renaming_Context_Id;
   use type RAV.Renaming_Legality_Id;
   use type RAV.Renaming_Context_Kind;
   use type RAV.Renamed_Entity_Kind;
   use type RAV.Visibility_State;
   use type RAV.Alias_State;
   use type RAV.Use_Clause_State;
   use type RAV.Renaming_Legality_Status;
   use type RAV.Renaming_Context_Info;
   use type RAV.Renaming_Legality_Info;
   use type RAV.Renaming_Context_Model;
   use type RAV.Renaming_Result_Set;
   use type RAV.Renaming_Legality_Model;
   package UCL renames Editor.Ada_Unit_Completion_Order_Legality;
   use type UCL.Cross_Unit_Semantic_Status;
   use type UCL.Contract_Legality_Status;
   use type UCL.Elaboration_Legality_Status;
   use type UCL.Instance_Legality_Status;
   use type UCL.Accessibility_Legality_Status;
   use type UCL.Completion_Context_Id;
   use type UCL.Completion_Legality_Id;
   use type UCL.Unit_Completion_Kind;
   use type UCL.Completion_Subject_Kind;
   use type UCL.Completion_Relation_State;
   use type UCL.Completion_Order_State;
   use type UCL.Completion_Visibility_State;
   use type UCL.Completion_Legality_Status;
   use type UCL.Completion_Context_Info;
   use type UCL.Completion_Legality_Info;
   use type UCL.Completion_Context_Model;
   use type UCL.Completion_Result_Set;
   use type UCL.Completion_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Exception_Finalization_Legality_Pass1116");
   end Name;

   procedure Builds_Wide_Exception_Finalization_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : EFL.Exception_Context_Model;
      C        : EFL.Exception_Context_Info;
   begin
      C.Id := 1;
      C.Kind := EFL.Exception_Context_Raise_Statement;
      C.Target_State := EFL.Exception_Target_Resolved_Exception;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111601);
      C.Name := To_Unbounded_String ("raise Constraint_Error");
      C.Normalized_Name := To_Unbounded_String ("raise constraint_error");
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := EFL.Exception_Context_Raise_Statement;
      C.Target_State := EFL.Exception_Target_Unresolved;
      C.Exception_Target_Resolved := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111602);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := EFL.Exception_Context_Raise_Statement;
      C.Target_State := EFL.Exception_Target_Ambiguous;
      C.Exception_Target_Ambiguous := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111603);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := EFL.Exception_Context_Raise_Statement;
      C.Target_State := EFL.Exception_Target_Resolved_Non_Exception;
      C.Target_Is_Exception := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111604);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := EFL.Exception_Context_Reraise;
      C.Reraise_In_Handler := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111605);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := EFL.Exception_Context_Handler;
      C.Handler := EFL.Handler_Normal;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111606);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := EFL.Exception_Context_Handler;
      C.Handler := EFL.Handler_Duplicate_Choice;
      C.Handler_Choice_Duplicate := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111607);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := EFL.Exception_Context_Handler;
      C.Handler := EFL.Handler_Others_Not_Last;
      C.Handler_Others_Last := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111608);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := EFL.Exception_Context_Raise_Expression;
      C.Raise_Expression_Type_Resolved := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111609);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := EFL.Exception_Context_Controlled_Finalize;
      C.Finalization := EFL.Finalization_Controlled_Primitive_Missing;
      C.Finalization_Primitive_Present := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111610);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := EFL.Exception_Context_Controlled_Finalize;
      C.Finalization := EFL.Finalization_Profile_Mismatch;
      C.Finalization_Profile_Compatible := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111611);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := EFL.Exception_Context_Master_Finalization;
      C.Finalization := EFL.Finalization_Order_Error;
      C.Finalization_Order_Compatible := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111612);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := EFL.Exception_Context_Cleanup_Action;
      C.Finalization := EFL.Finalization_Exception_Propagates;
      C.Finalization_Can_Propagate_Exception := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111613);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := EFL.Exception_Context_No_Return_Subprogram;
      C.No_Return := EFL.No_Return_Raises_Or_Does_Not_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111614);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := EFL.Exception_Context_No_Return_Subprogram;
      C.No_Return := EFL.No_Return_Returns_Normally;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111615);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 16;
      C.Kind := EFL.Exception_Context_Raise_Statement;
      C.Target_State := EFL.Exception_Target_Private_View;
      C.Private_View_Barrier := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111616);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 17;
      C.Kind := EFL.Exception_Context_Raise_Statement;
      C.Target_State := EFL.Exception_Target_Limited_View;
      C.Limited_View_Barrier := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111617);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 18;
      C.Kind := EFL.Exception_Context_Handler;
      C.Flow_Status := CFL.Flow_Legality_Exception_Choice_Unresolved;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111618);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 19;
      C.Kind := EFL.Exception_Context_Cleanup_Action;
      C.Accessibility_Status := AAL.Accessibility_Legality_Level_Too_Deep;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111619);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 20;
      C.Kind := EFL.Exception_Context_No_Return_Subprogram;
      C.Contract_Status := CAL.Contract_Legality_Non_Boolean_Condition;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111620);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 21;
      C.Kind := EFL.Exception_Context_Propagation;
      C.Elaboration_Status := EDL.Elaboration_Legality_Call_Before_Body_Elaboration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111621);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 22;
      C.Kind := EFL.Exception_Context_Exception_Renaming;
      C.Renaming_Status := RAV.Renaming_Legality_Missing_Target;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111622);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 23;
      C.Kind := EFL.Exception_Context_Master_Finalization;
      C.Completion_Status := UCL.Completion_Legality_Use_Before_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111623);
      EFL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 24;
      C.Kind := EFL.Exception_Context_Unknown;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111624);
      EFL.Add_Context (Contexts, C);

      declare
         Model : constant EFL.Exception_Legality_Model := EFL.Build (Contexts);
         Raise_Rows : constant EFL.Exception_Result_Set :=
           EFL.Rows_For_Kind (Model, EFL.Exception_Context_Raise_Statement);
         Handler_Rows : constant EFL.Exception_Result_Set :=
           EFL.Rows_For_Handler (Model, EFL.Handler_Duplicate_Choice);
         No_Return_Rows : constant EFL.Exception_Result_Set :=
           EFL.Rows_For_No_Return (Model, EFL.No_Return_Returns_Normally);
      begin
         Assert (EFL.Legality_Count (Model) = 24,
                 "all exception/finalization contexts should produce rows");
         Assert (EFL.Legal_Count (Model) = 3,
                 "legal raise, handler, and No_Return contexts should be counted");
         Assert (EFL.Error_Count (Model) = 20,
                 "negative fixtures should expose exception/finalization errors");
         Assert (EFL.Raise_Error_Count (Model) = 4,
                 "raise target/reraise/raise-expression errors should be counted");
         Assert (EFL.Handler_Error_Count (Model) = 2,
                 "handler duplicate and others ordering errors should be counted");
         Assert (EFL.Finalization_Error_Count (Model) = 4,
                 "finalization primitive/profile/order/propagation errors should be counted");
         Assert (EFL.No_Return_Error_Count (Model) = 1,
                 "No_Return normal-return error should be counted");
         Assert (EFL.View_Barrier_Count (Model) = 2,
                 "private and limited view barriers should be counted");
         Assert (EFL.Linked_Error_Count (Model) = 6,
                 "linked control/access/contract/elaboration/renaming/completion errors should be counted");
         Assert (EFL.Indeterminate_Count (Model) = 1,
                 "unknown context should remain indeterminate");
         Assert (EFL.Count_Status (Model, EFL.Exception_Legality_Raise_Target_Not_Exception) = 1,
                 "non-exception raise target should be classified directly");
         Assert (EFL.Result_Count (Raise_Rows) = 6,
                 "raise statement lookup should include raise contexts");
         Assert (EFL.Result_Count (Handler_Rows) = 1,
                 "handler state lookup should find duplicate choice row");
         Assert (EFL.Result_Count (No_Return_Rows) = 1,
                 "No_Return lookup should find normal-return row");
         Assert (EFL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111615)).Status =
                 EFL.Exception_Legality_No_Return_Returns_Normally,
                 "node lookup should preserve No_Return classification");
         Assert (EFL.Fingerprint (Model) /= 0,
                 "exception/finalization legality fingerprint should be deterministic and non-zero");
      end;
   end Builds_Wide_Exception_Finalization_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Exception_Finalization_Legality'Access,
         "builds wide exception/finalization legality");
   end Register_Tests;

end Test_Ada_Exception_Finalization_Legality_Pass1116;
