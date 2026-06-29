with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package body Test_Ada_Unit_Completion_Order_Legality is

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
   package GIF renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
   use type GIF.Instance_Context_Id;
   use type GIF.Instance_Legality_Id;
   use type GIF.Instance_Context_Kind;
   use type GIF.Instance_Legality_Status;
   use type GIF.Instance_Context_Info;
   use type GIF.Instance_Legality_Info;
   use type GIF.Instance_Context_Model;
   use type GIF.Instance_Result_Set;
   use type GIF.Instance_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Unit_Completion_Order_Legality");
   end Name;

   procedure Builds_Wide_Completion_Order_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : UCL.Completion_Context_Model;
      C        : UCL.Completion_Context_Info;
   begin
      C.Id := 1;
      C.Kind := UCL.Completion_Context_Package_Body;
      C.Subject := UCL.Completion_Subject_Package;
      C.Relation := UCL.Completion_Relation_Matched;
      C.Order := UCL.Completion_Order_Known_After;
      C.Visibility := UCL.Completion_Visibility_Spec_Visible;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111401);
      C.Name := To_Unbounded_String ("Pkg");
      C.Normalized_Name := To_Unbounded_String ("pkg");
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := UCL.Completion_Context_Subprogram_Body;
      C.Subject := UCL.Completion_Subject_Subprogram;
      C.Requires_Body := True;
      C.Body_Present := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111402);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := UCL.Completion_Context_Subprogram_Body;
      C.Subject := UCL.Completion_Subject_Subprogram;
      C.Duplicate_Body := True;
      C.Relation := UCL.Completion_Relation_Duplicate_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111403);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := UCL.Completion_Context_Subprogram_Body;
      C.Subject := UCL.Completion_Subject_Subprogram;
      C.Profile_Mismatch := True;
      C.Relation := UCL.Completion_Relation_Profile_Mismatch;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111404);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := UCL.Completion_Context_Private_Type_Completion;
      C.Subject := UCL.Completion_Subject_Type;
      C.Private_Type := True;
      C.Requires_Completion := True;
      C.Completion_Present := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111405);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := UCL.Completion_Context_Deferred_Constant_Completion;
      C.Subject := UCL.Completion_Subject_Object;
      C.Deferred_Constant := True;
      C.Requires_Completion := True;
      C.Completion_Present := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111406);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := UCL.Completion_Context_Declaration_Before_Use;
      C.Subject := UCL.Completion_Subject_Declaration;
      C.Order := UCL.Completion_Order_Use_Before_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111407);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := UCL.Completion_Context_Private_Part_Ordering;
      C.Subject := UCL.Completion_Subject_Type;
      C.Order := UCL.Completion_Order_Full_View_Before_Private_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111408);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := UCL.Completion_Context_Incomplete_Type_Completion;
      C.Subject := UCL.Completion_Subject_Type;
      C.Incomplete_Type := True;
      C.Frozen_Before_Completion := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111409);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := UCL.Completion_Context_Separate_Body_Completion;
      C.Subject := UCL.Completion_Subject_Separate;
      C.Separate_Body := True;
      C.Relation := UCL.Completion_Relation_Separate_Parent_Missing;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111410);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := UCL.Completion_Context_Package_Body;
      C.Subject := UCL.Completion_Subject_Package;
      C.Visibility := UCL.Completion_Visibility_Limited_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111411);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := UCL.Completion_Context_Package_Body;
      C.Subject := UCL.Completion_Subject_Package;
      C.Cross_Unit_Status := CUS.Cross_Unit_Semantic_Missing_Dependency;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111412);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := UCL.Completion_Context_Package_Body;
      C.Subject := UCL.Completion_Subject_Package;
      C.Contract_Status := CAL.Contract_Legality_Non_Boolean_Condition;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111413);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := UCL.Completion_Context_Package_Body;
      C.Subject := UCL.Completion_Subject_Package;
      C.Elaboration_Status := EDL.Elaboration_Legality_Call_Before_Body_Elaboration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111414);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := UCL.Completion_Context_Generic_Body;
      C.Subject := UCL.Completion_Subject_Generic;
      C.Instance_Status := GIF.Instance_Legality_Missing_Body_Contract;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111415);
      UCL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 16;
      C.Kind := UCL.Completion_Context_Body_Declaration_Order;
      C.Subject := UCL.Completion_Subject_Declaration;
      C.Accessibility_Status := AAL.Accessibility_Legality_Level_Too_Deep;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111416);
      UCL.Add_Context (Contexts, C);

      declare
         Model : constant UCL.Completion_Legality_Model := UCL.Build (Contexts);
         Body_Rows : constant UCL.Completion_Result_Set :=
           UCL.Rows_For_Subject (Model, UCL.Completion_Subject_Subprogram);
         Order_Rows : constant UCL.Completion_Result_Set :=
           UCL.Rows_For_Order (Model, UCL.Completion_Order_Use_Before_Declaration);
         Limited_Rows : constant UCL.Completion_Result_Set :=
           UCL.Rows_For_Visibility (Model, UCL.Completion_Visibility_Limited_View);
      begin
         Assert (UCL.Legality_Count (Model) = 16,
                 "all completion/order contexts should produce legality rows");
         Assert (UCL.Legal_Count (Model) = 1,
                 "only the matched package body should be legal in this fixture");
         Assert (UCL.Error_Count (Model) = 15,
                 "remaining contexts should expose compiler-grade completion errors");
         Assert (UCL.Body_Error_Count (Model) = 4,
                 "missing, duplicate, profile mismatch, and separate parent errors are body errors");
         Assert (UCL.Completion_Error_Count (Model) = 3,
                 "private type, deferred constant, and frozen-before-completion are completion errors");
         Assert (UCL.Order_Error_Count (Model) = 3,
                 "use-before-declaration, private ordering, and frozen-before-completion are order errors");
         Assert (UCL.View_Barrier_Count (Model) = 1,
                 "limited view barrier should be counted");
         Assert (UCL.Linked_Error_Count (Model) = 5,
                 "cross-unit, contract, elaboration, generic, and accessibility linked errors should be counted");
         Assert (UCL.Count_Status (Model, UCL.Completion_Legality_Missing_Body) = 1,
                 "missing body should be classified directly");
         Assert (UCL.Count_Kind (Model, UCL.Completion_Context_Package_Body) = 5,
                 "package body contexts should be counted");
         Assert (UCL.Result_Count (Body_Rows) = 3,
                 "subject lookup should return subprogram body rows");
         Assert (UCL.Result_Count (Order_Rows) = 1,
                 "order lookup should return use-before-declaration rows");
         Assert (UCL.Result_Count (Limited_Rows) = 1,
                 "visibility lookup should return limited-view rows");
         Assert (UCL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111407)).Status =
                 UCL.Completion_Legality_Use_Before_Declaration,
                 "node lookup should preserve declaration-order classification");
         Assert (UCL.Fingerprint (Model) /= 0,
                 "unit completion/order legality fingerprint should be deterministic and non-zero");
      end;
   end Builds_Wide_Completion_Order_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Completion_Order_Legality'Access,
         "builds wide unit completion/order legality");
   end Register_Tests;

end Test_Ada_Unit_Completion_Order_Legality;
