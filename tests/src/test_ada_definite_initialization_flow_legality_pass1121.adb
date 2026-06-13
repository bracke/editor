with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Definite_Initialization_Flow_Legality_Pass1121 is

   package DIF renames Editor.Ada_Definite_Initialization_Flow_Legality;
   use type DIF.Assignment_Legality_Id;
   use type DIF.Assignment_Legality_Status;
   use type DIF.Return_Legality_Id;
   use type DIF.Return_Legality_Status;
   use type DIF.Control_Flow_Legality_Id;
   use type DIF.Control_Flow_Legality_Status;
   use type DIF.Exception_Finalization_Legality_Id;
   use type DIF.Exception_Finalization_Legality_Status;
   use type DIF.Integrated_Closure_Id;
   use type DIF.Integrated_Closure_Status;
   use type DIF.Initialization_Context_Id;
   use type DIF.Initialization_Legality_Id;
   use type DIF.Initialization_Context_Kind;
   use type DIF.Object_State;
   use type DIF.Flow_State;
   use type DIF.Initialization_Legality_Status;
   use type DIF.Initialization_Context_Info;
   use type DIF.Initialization_Legality_Info;
   use type DIF.Initialization_Context_Model;
   use type DIF.Initialization_Legality_Model;
   package AL renames Editor.Ada_Assignment_Legality;
   use type AL.Expression_Type_Id;
   use type AL.Assignment_Context_Id;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Context_Kind;
   use type AL.Assignment_Target_Mode;
   use type AL.Assignment_Legality_Status;
   use type AL.Assignment_Context_Info;
   use type AL.Assignment_Legality_Info;
   use type AL.Assignment_Context_Model;
   use type AL.Assignment_Legality_Result_Set;
   use type AL.Assignment_Legality_Model;
   package RL renames Editor.Ada_Return_Legality;
   use type RL.Assignment_Context_Id;
   use type RL.Assignment_Legality_Status;
   use type RL.Return_Context_Id;
   use type RL.Return_Legality_Id;
   use type RL.Return_Context_Kind;
   use type RL.Return_Legality_Status;
   use type RL.Return_Context_Info;
   use type RL.Return_Legality_Info;
   use type RL.Return_Context_Model;
   use type RL.Return_Legality_Result_Set;
   use type RL.Return_Legality_Model;
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
   package ISC renames Editor.Ada_Integrated_Semantic_Closure;
   use type ISC.Wide_Diagnostic_Status;
   use type ISC.Overload_Status;
   use type ISC.Static_Status;
   use type ISC.Accessibility_Status;
   use type ISC.Contract_Status;
   use type ISC.Elaboration_Status;
   use type ISC.Completion_Status;
   use type ISC.Renaming_Status;
   use type ISC.Exception_Status;
   use type ISC.Representation_Status;
   use type ISC.Refined_Global_Depends_Status;
   use type ISC.Integrated_Closure_Context_Id;
   use type ISC.Integrated_Closure_Id;
   use type ISC.Integrated_Closure_Context_Kind;
   use type ISC.Closure_Dependency_State;
   use type ISC.Closure_Blocker_Family;
   use type ISC.Integrated_Closure_Status;
   use type ISC.Integrated_Closure_Context_Info;
   use type ISC.Integrated_Closure_Info;
   use type ISC.Integrated_Closure_Context_Model;
   use type ISC.Integrated_Closure_Result_Set;
   use type ISC.Integrated_Closure_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Definite_Initialization_Flow_Legality_Pass1121");
   end Name;

   procedure Builds_Definite_Initialization_Flow_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : DIF.Initialization_Context_Model;
      C        : DIF.Initialization_Context_Info;
      Model    : DIF.Initialization_Legality_Model;
      Row      : DIF.Initialization_Legality_Info;
   begin
      C.Id := 1;
      C.Kind := DIF.Initialization_Context_Object_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112101);
      C.Object_Name := To_Unbounded_String ("A");
      C.Has_Explicit_Init := True;
      C.After_State := DIF.Object_State_Definitely_Initialized;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := DIF.Initialization_Context_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112102);
      C.Object_Name := To_Unbounded_String ("B");
      C.Reads_Object := True;
      C.Requires_Definite_Init := True;
      C.Before_State := DIF.Object_State_Uninitialized;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := DIF.Initialization_Context_Component;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112103);
      C.Component_Node := Editor.Ada_Syntax_Tree.Node_Id (112130);
      C.Object_Name := To_Unbounded_String ("R.F");
      C.Component_Covered := False;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := DIF.Initialization_Context_Parameter_Out;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112104);
      C.Object_Name := To_Unbounded_String ("Out_Value");
      C.Must_Assign_Out := True;
      C.Writes_Object := False;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := DIF.Initialization_Context_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112105);
      C.Object_Name := To_Unbounded_String ("Result");
      C.After_State := DIF.Object_State_Uninitialized;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := DIF.Initialization_Context_Branch_Merge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112106);
      C.Flow := DIF.Flow_State_Branch_Merge;
      C.After_State := DIF.Object_State_Conditionally_Initialized;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := DIF.Initialization_Context_Finalization_Path;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112107);
      C.Flow := DIF.Flow_State_Finalization;
      C.Before_State := DIF.Object_State_Uninitialized;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := DIF.Initialization_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112108);
      C.Assignment := AL.Assignment_Legality_Id (8);
      C.Assignment_Status := AL.Assignment_Legality_Static_Range_Violation;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := DIF.Initialization_Context_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112109);
      C.Return_Item := RL.Return_Legality_Id (9);
      C.Return_Status := RL.Return_Legality_Result_Source_Unresolved;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := DIF.Initialization_Context_Loop_Merge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112110);
      C.Control_Item := CFL.Flow_Legality_Id (10);
      C.Control_Status := CFL.Flow_Legality_Missing_Return_Path;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := DIF.Initialization_Context_Exception_Path;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112111);
      C.Exception_Item := EFL.Exception_Legality_Id (11);
      C.Exception_Status := EFL.Exception_Legality_Finalization_Primitive_Missing;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := DIF.Initialization_Context_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112112);
      C.Closure_Item := ISC.Integrated_Closure_Id (12);
      C.Closure_Status := ISC.Integrated_Closure_Missing_Dependency;
      DIF.Add_Context (Contexts, C);

      Model := DIF.Build (Contexts);

      Assert (DIF.Context_Count (Contexts) = 12, "all initialization contexts recorded");
      Assert (DIF.Row_Count (Model) = 12, "all initialization rows emitted");
      Assert (DIF.Legal_Row_Count (Model) = 1, "one legal initialization row");
      Assert (DIF.Error_Row_Count (Model) = 11, "eleven failing rows");
      Assert (DIF.Linked_Error_Count (Model) = 5, "linked semantic blockers counted");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Legality_Read_Before_Write) = 1,
              "read-before-write counted");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Legality_Out_Parameter_Not_Assigned) = 1,
              "out parameter not assigned counted");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Legality_Linked_Closure_Error) = 1,
              "closure blocker counted");
      Assert (DIF.Count_Kind (Model, DIF.Initialization_Context_Return) = 2,
              "return contexts counted");
      Assert (DIF.Row_Count (DIF.Rows_For_Status (Model, DIF.Initialization_Legality_Linked_Assignment_Error)) = 1,
              "status lookup filters linked assignment");
      Assert (DIF.Row_Count (DIF.Rows_For_Kind (Model, DIF.Initialization_Context_Read)) = 2,
              "kind lookup filters reads");
      Assert (DIF.Row_Count (DIF.Rows_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112108))) = 1,
              "node lookup filters assignment row");

      Row := DIF.First_For_Object (Model, "B");
      Assert (Row.Status = DIF.Initialization_Legality_Read_Before_Write,
              "object-name lookup returns first matching row");
      Assert (DIF.Fingerprint (Contexts) /= 0, "context fingerprint is deterministic");
      Assert (DIF.Fingerprint (Model) /= 0, "model fingerprint is deterministic");
   end Builds_Definite_Initialization_Flow_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Builds_Definite_Initialization_Flow_Legality'Access,
         "builds definite-initialization and flow legality");
   end Register_Tests;

end Test_Ada_Definite_Initialization_Flow_Legality_Pass1121;
