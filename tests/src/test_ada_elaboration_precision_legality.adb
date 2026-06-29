with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Precision_Legality is

   package EPL renames Editor.Ada_Elaboration_Precision_Legality;
   use type EPL.Elaboration_Legality_Status;
   use type EPL.Elaboration_Order_State;
   use type EPL.Elaboration_Policy_State;
   use type EPL.Dataflow_Legality_Status;
   use type EPL.Generic_Body_Expansion_Status;
   use type EPL.Preference_Legality_Status;
   use type EPL.Accessibility_Precision_Status;
   use type EPL.Elaboration_Precision_Context_Id;
   use type EPL.Elaboration_Precision_Legality_Id;
   use type EPL.Elaboration_Precision_Context_Kind;
   use type EPL.Elaboration_Precision_Status;
   use type EPL.Elaboration_Precision_Context_Info;
   use type EPL.Elaboration_Precision_Legality_Info;
   use type EPL.Elaboration_Precision_Context_Model;
   use type EPL.Elaboration_Precision_Result_Set;
   use type EPL.Elaboration_Precision_Legality_Model;
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
   package DFL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   use type DFL.Contract_Legality_Status;
   use type DFL.Flow_Contract_State;
   use type DFL.Initialization_Legality_Status;
   use type DFL.Object_State;
   use type DFL.Dataflow_Context_Id;
   use type DFL.Dataflow_Legality_Id;
   use type DFL.Dataflow_Context_Kind;
   use type DFL.Dataflow_Effect_Kind;
   use type DFL.Global_Mode;
   use type DFL.Dependency_State;
   use type DFL.Dataflow_Legality_Status;
   use type DFL.Dataflow_Context_Info;
   use type DFL.Dataflow_Legality_Info;
   use type DFL.Dataflow_Context_Model;
   use type DFL.Dataflow_Result_Set;
   use type DFL.Dataflow_Legality_Model;
   package GBE renames Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
   use type GBE.Instantiated_Body_Status;
   use type GBE.Overload_Legality_Status;
   use type GBE.Accessibility_Legality_Status;
   use type GBE.Contract_Legality_Status;
   use type GBE.Dataflow_Legality_Status;
   use type GBE.Initialization_Legality_Status;
   use type GBE.Predicate_Use_Legality_Status;
   use type GBE.Representation_Integration_Status;
   use type GBE.Generic_Body_Expansion_Context_Id;
   use type GBE.Generic_Body_Expansion_Id;
   use type GBE.Generic_Body_Expansion_Context_Kind;
   use type GBE.Generic_Body_Expansion_Status;
   use type GBE.Generic_Body_Expansion_Context_Info;
   use type GBE.Generic_Body_Expansion_Info;
   use type GBE.Generic_Body_Expansion_Context_Model;
   use type GBE.Generic_Body_Expansion_Result_Set;
   use type GBE.Generic_Body_Expansion_Model;
   package OPL renames Editor.Ada_Overload_Preference_Legality;
   use type OPL.Preference_Context_Id;
   use type OPL.Preference_Legality_Id;
   use type OPL.Preference_Context_Kind;
   use type OPL.Preference_Legality_Status;
   use type OPL.Preference_Context_Info;
   use type OPL.Preference_Legality_Info;
   use type OPL.Preference_Context_Model;
   use type OPL.Preference_Legality_Result_Set;
   use type OPL.Preference_Legality_Model;
   package APL renames Editor.Ada_Accessibility_Precision_Legality;
   use type APL.Accessibility_Legality_Status;
   use type APL.Accessibility_Level;
   use type APL.Access_Context_Kind;
   use type APL.Record_Aggregate_Legality_Status;
   use type APL.Generic_Body_Expansion_Status;
   use type APL.Accessibility_Precision_Context_Id;
   use type APL.Accessibility_Precision_Legality_Id;
   use type APL.Accessibility_Precision_Context_Kind;
   use type APL.Accessibility_Precision_Status;
   use type APL.Accessibility_Precision_Context_Info;
   use type APL.Accessibility_Precision_Legality_Info;
   use type APL.Accessibility_Precision_Context_Model;
   use type APL.Accessibility_Precision_Result_Set;
   use type APL.Accessibility_Precision_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Elaboration_Precision_Legality");
   end Name;

   procedure Builds_Elaboration_Precision_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : EPL.Elaboration_Precision_Context_Model;
      C        : EPL.Elaboration_Precision_Context_Info;
   begin
      C.Id := 1;
      C.Kind := EPL.Elaboration_Precision_Context_Dependency_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112901);
      C.Unit_Name := To_Unbounded_String ("Root");
      C.Order_State := EDL.Elaboration_Order_Known_Before;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := EPL.Elaboration_Precision_Context_Call_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112902);
      C.Unit_Name := To_Unbounded_String ("Root");
      C.Call_During_Elaboration := True;
      C.Body_Elaborated := False;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := EPL.Elaboration_Precision_Context_Access_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112903);
      C.Access_During_Elaboration := True;
      C.Order_State := EDL.Elaboration_Order_Known_After;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := EPL.Elaboration_Precision_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112904);
      C.Generic_Instance := True;
      C.Generic_Body_Elaborated := False;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := EPL.Elaboration_Precision_Context_Dependency_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112905);
      C.Requires_Elaborate_All := True;
      C.Has_Elaborate_All := False;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := EPL.Elaboration_Precision_Context_Elaboration_Graph;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112906);
      C.Graph_Cycle := True;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := EPL.Elaboration_Precision_Context_Preelaborated_Unit;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112907);
      C.Illegal_Preelaborate_Call := True;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := EPL.Elaboration_Precision_Context_Pure_Unit;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112908);
      C.Illegal_Pure_State := True;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := EPL.Elaboration_Precision_Context_Dependency_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112909);
      C.Dataflow_Status := DFL.Dataflow_Legality_Read_Before_Write;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := EPL.Elaboration_Precision_Context_Call_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112910);
      C.Call_During_Elaboration := True;
      C.Preference_Status := OPL.Preference_Legality_Ambiguous_After_RM_Preferences;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := EPL.Elaboration_Precision_Context_Access_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112911);
      C.Access_During_Elaboration := True;
      C.Accessibility_Status := APL.Accessibility_Precision_Return_Access_Too_Short_Lived;
      EPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := EPL.Elaboration_Precision_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112912);
      C.Generic_Status := GBE.Generic_Body_Expansion_Dataflow_Error;
      EPL.Add_Context (Contexts, C);

      declare
         Model : constant EPL.Elaboration_Precision_Legality_Model := EPL.Build (Contexts);
         Root_Rows : constant EPL.Elaboration_Precision_Result_Set :=
           EPL.Rows_For_Unit (Model, "Root");
         Call_Rows : constant EPL.Elaboration_Precision_Result_Set :=
           EPL.Rows_For_Kind (Model, EPL.Elaboration_Precision_Context_Call_Edge);
      begin
         Assert (EPL.Legality_Count (Model) = 12,
                 "all elaboration precision contexts should produce rows");
         Assert (EPL.Legal_Count (Model) = 1,
                 "only the known-before dependency should be legal");
         Assert (EPL.Error_Count (Model) = 11,
                 "remaining rows should be precision errors");
         Assert (EPL.Graph_Error_Count (Model) = 4,
                 "call/access order, missing Elaborate_All, and cycle are graph errors");
         Assert (EPL.Policy_Error_Count (Model) = 2,
                 "preelaborate and pure policy errors should be counted");
         Assert (EPL.Generic_Error_Count (Model) = 2,
                 "generic instance body and linked generic body errors should be counted");
         Assert (EPL.Dataflow_Error_Count (Model) = 1,
                 "dataflow read-before-write should be counted");
         Assert (EPL.Call_Error_Count (Model) = 2,
                 "call-before-body and overload preference failures should be call errors");
         Assert (EPL.Accessibility_Error_Count (Model) = 2,
                 "access-before-elaboration and accessibility risk should be counted");
         Assert (EPL.Linked_Error_Count (Model) = 1,
                 "linked generic body error should be counted separately");
         Assert (EPL.Result_Count (Root_Rows) = 2,
                 "unit lookup should preserve root rows");
         Assert (EPL.Result_Count (Call_Rows) = 2,
                 "kind lookup should preserve call-edge rows");
         Assert (EPL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (112902)).Status =
                 EPL.Elaboration_Precision_Body_Elaborated_After_Call,
                 "node lookup should preserve call-before-body classification");
         Assert (EPL.Count_Status
                   (Model, EPL.Elaboration_Precision_Missing_Elaborate_All) = 1,
                 "missing Elaborate_All should be classified directly");
         Assert (EPL.Fingerprint (Model) /= 0,
                 "elaboration precision legality fingerprint should be deterministic and non-zero");
      end;
   end Builds_Elaboration_Precision_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Elaboration_Precision_Closure'Access,
         "builds elaboration precision legality closure");
   end Register_Tests;

end Test_Ada_Elaboration_Precision_Legality;
