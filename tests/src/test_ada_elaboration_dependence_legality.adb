with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Dependence_Legality is

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
   package CUS renames Editor.Ada_Cross_Unit_Semantic_Closure;
   use type CUS.Cross_Unit_Semantic_Context_Id;
   use type CUS.Cross_Unit_Semantic_Id;
   use type CUS.Cross_Unit_Semantic_Context_Kind;
   use type CUS.Cross_Unit_Semantic_Status;
   use type CUS.Cross_Unit_Semantic_Context_Info;
   use type CUS.Cross_Unit_Semantic_Info;
   use type CUS.Cross_Unit_Semantic_Context_Model;
   use type CUS.Cross_Unit_Semantic_Result_Set;
   use type CUS.Cross_Unit_Semantic_Model;
   package ORL renames Editor.Ada_Overload_Resolution_Legality;
   use type ORL.Overload_Context_Id;
   use type ORL.Overload_Legality_Id;
   use type ORL.Overload_Context_Kind;
   use type ORL.Overload_Legality_Status;
   use type ORL.Overload_Context_Info;
   use type ORL.Overload_Legality_Info;
   use type ORL.Overload_Context_Model;
   use type ORL.Overload_Legality_Result_Set;
   use type ORL.Overload_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Elaboration_Dependence_Legality");
   end Name;

   procedure Builds_Wide_Elaboration_Dependence_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : EDL.Elaboration_Context_Model;
      C        : EDL.Elaboration_Context_Info;
   begin
      C.Id := 1;
      C.Kind := EDL.Elaboration_Context_With_Dependency;
      C.Dependence := EDL.Elaboration_Dependence_With;
      C.Order_State := EDL.Elaboration_Order_Known_Before;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111301);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := EDL.Elaboration_Context_Elaborate_All_Pragma;
      C.Dependence := EDL.Elaboration_Dependence_With;
      C.Pragma_State := EDL.Elaboration_Pragma_Elaborate_All;
      C.Order_State := EDL.Elaboration_Order_Known_Before;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111302);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := EDL.Elaboration_Context_Call_During_Elaboration;
      C.Dependence := EDL.Elaboration_Dependence_Subprogram_Call;
      C.Order_State := EDL.Elaboration_Order_Known_After;
      C.Call_During_Elaboration := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111303);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := EDL.Elaboration_Context_With_Dependency;
      C.Dependence := EDL.Elaboration_Dependence_With;
      C.Requires_Elaborate_All := True;
      C.Has_Elaborate_All := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111304);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := EDL.Elaboration_Context_Elaborate_Pragma;
      C.Dependence := EDL.Elaboration_Dependence_With;
      C.Pragma_State := EDL.Elaboration_Pragma_Duplicate;
      C.Duplicate_Pragma := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111305);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := EDL.Elaboration_Context_Circular_Dependence;
      C.Dependence := EDL.Elaboration_Dependence_Body;
      C.Order_State := EDL.Elaboration_Order_Circular;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111306);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := EDL.Elaboration_Context_Preelaborate_Unit;
      C.Dependence := EDL.Elaboration_Dependence_Default_Expression;
      C.Policy_State := EDL.Elaboration_Policy_Preelaborated;
      C.Illegal_Preelaborate_Construct := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111307);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := EDL.Elaboration_Context_Pure_Unit;
      C.Policy_State := EDL.Elaboration_Policy_Pure;
      C.Illegal_Pure_State := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111308);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := EDL.Elaboration_Context_Body_Before_Use;
      C.Dependence := EDL.Elaboration_Dependence_Body;
      C.Requires_Body := True;
      C.Body_Available := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111309);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := EDL.Elaboration_Context_Generic_Instance;
      C.Dependence := EDL.Elaboration_Dependence_Generic_Instance;
      C.Order_State := EDL.Elaboration_Order_Known_Before;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111310);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := EDL.Elaboration_Context_With_Dependency;
      C.Dependence := EDL.Elaboration_Dependence_With;
      C.Cross_Unit_Status := CUS.Cross_Unit_Semantic_Missing_Dependency;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111311);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := EDL.Elaboration_Context_Call_During_Elaboration;
      C.Dependence := EDL.Elaboration_Dependence_Subprogram_Call;
      C.Contract_Status := CAL.Contract_Legality_Non_Boolean_Condition;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111312);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := EDL.Elaboration_Context_Call_During_Elaboration;
      C.Dependence := EDL.Elaboration_Dependence_Subprogram_Call;
      C.Overload_Status := ORL.Overload_Legality_Ambiguous_After_Preference;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111313);
      EDL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := EDL.Elaboration_Context_Remote_Types_Unit;
      C.Policy_State := EDL.Elaboration_Policy_Remote_Types;
      C.Illegal_Remote_Types_Dependency := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111314);
      EDL.Add_Context (Contexts, C);

      declare
         Model : constant EDL.Elaboration_Legality_Model := EDL.Build (Contexts);
         Call_Rows : constant EDL.Elaboration_Result_Set :=
           EDL.Rows_For_Dependence (Model, EDL.Elaboration_Dependence_Subprogram_Call);
         Pragma_Rows : constant EDL.Elaboration_Result_Set :=
           EDL.Rows_For_Pragma_State (Model, EDL.Elaboration_Pragma_Elaborate_All);
         Policy_Rows : constant EDL.Elaboration_Result_Set :=
           EDL.Rows_For_Policy_State (Model, EDL.Elaboration_Policy_Preelaborated);
      begin
         Assert (EDL.Legality_Count (Model) = 14,
                 "all elaboration contexts should produce legality rows");
         Assert (EDL.Legal_Count (Model) = 3,
                 "ordinary dependency, Elaborate_All pragma, and generic instance should be legal");
         Assert (EDL.Error_Count (Model) = 11,
                 "remaining elaboration contexts should expose errors");
         Assert (EDL.Pragma_Error_Count (Model) = 2,
                 "duplicate pragma and missing Elaborate_All should be pragma errors");
         Assert (EDL.Order_Error_Count (Model) = 2,
                 "call-before-body and circular dependency should be order errors");
         Assert (EDL.Policy_Error_Count (Model) = 3,
                 "preelaborate, pure, and remote-types policy errors should be counted");
         Assert (EDL.Body_Error_Count (Model) = 2,
                 "call-before-body and missing body should be body errors");
         Assert (EDL.Linked_Error_Count (Model) = 3,
                 "cross-unit, contract, and overload linked errors should be counted");
         Assert (EDL.Count_Status
                   (Model, EDL.Elaboration_Legality_Missing_Elaborate_All) = 1,
                 "missing Elaborate_All should be classified directly");
         Assert (EDL.Count_Kind (Model, EDL.Elaboration_Context_Call_During_Elaboration) = 3,
                 "kind counter should preserve call-during-elaboration rows");
         Assert (EDL.Result_Count (Call_Rows) = 3,
                 "dependence lookup should return call rows");
         Assert (EDL.Result_Count (Pragma_Rows) = 1,
                 "pragma-state lookup should return Elaborate_All rows");
         Assert (EDL.Result_Count (Policy_Rows) = 1,
                 "policy lookup should return preelaborate rows");
         Assert (EDL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111303)).Status =
                 EDL.Elaboration_Legality_Call_Before_Body_Elaboration,
                 "node lookup should preserve call-before-body classification");
         Assert (EDL.Fingerprint (Model) /= 0,
                 "elaboration/dependence legality fingerprint should be deterministic and non-zero");
      end;
   end Builds_Wide_Elaboration_Dependence_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Elaboration_Dependence_Legality'Access,
         "builds wide elaboration/dependence legality");
   end Register_Tests;

end Test_Ada_Elaboration_Dependence_Legality;
