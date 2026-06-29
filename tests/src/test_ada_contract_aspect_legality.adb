with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Contract_Aspect_Legality is

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
   package AXL renames Editor.Ada_Accessibility_Lifetime_Legality;
   use type AXL.Assignment_Legality_Id;
   use type AXL.Assignment_Legality_Status;
   use type AXL.Return_Legality_Id;
   use type AXL.Return_Legality_Status;
   use type AXL.Semantic_Legality_Id;
   use type AXL.Semantic_Legality_Status;
   use type AXL.Static_Legality_Id;
   use type AXL.Static_Legality_Status;
   use type AXL.Accessibility_Context_Id;
   use type AXL.Accessibility_Legality_Id;
   use type AXL.Access_Context_Kind;
   use type AXL.Access_Target_Kind;
   use type AXL.Accessibility_Level;
   use type AXL.Alias_Requirement;
   use type AXL.Accessibility_Legality_Status;
   use type AXL.Accessibility_Context_Info;
   use type AXL.Accessibility_Legality_Info;
   use type AXL.Accessibility_Context_Model;
   use type AXL.Accessibility_Result_Set;
   use type AXL.Accessibility_Legality_Model;
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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Contract_Aspect_Legality");
   end Name;

   procedure Builds_Wide_Contract_Aspect_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CAL.Contract_Context_Model;
      C        : CAL.Contract_Context_Info;
   begin
      C.Id := 1;
      C.Kind := CAL.Contract_Context_Precondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111201);
      C.Boolean_State := CAL.Boolean_Expression_Compatible;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := CAL.Contract_Context_Postcondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111202);
      C.Boolean_State := CAL.Boolean_Expression_Non_Boolean;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := CAL.Contract_Context_Static_Predicate;
      C.Subject := CAL.Contract_Subject_Subtype;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111203);
      C.Boolean_State := CAL.Boolean_Expression_Compatible;
      C.Requires_Static := True;
      C.Static_Expression := False;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := CAL.Contract_Context_Type_Invariant;
      C.Subject := CAL.Contract_Subject_Type;
      C.Placement := CAL.Aspect_Placement_Private_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111204);
      C.Private_View_Barrier := True;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := CAL.Contract_Context_Contract_Case;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111205);
      C.Contract_Case_Overlap := True;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := CAL.Contract_Context_Global_Aspect;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111206);
      C.Flow_State := CAL.Flow_Contract_Unknown_Global;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := CAL.Contract_Context_Dynamic_Predicate;
      C.Subject := CAL.Contract_Subject_Subtype;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111207);
      C.Static_Status := SRP.Static_Legality_Range_Violation;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := CAL.Contract_Context_Assertion;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111208);
      C.Assignment_Status := AL.Assignment_Legality_Incompatible_Subtype;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := CAL.Contract_Context_Postcondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111209);
      C.Return_Status := RL.Return_Legality_Result_Incompatible_Subtype;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := CAL.Contract_Context_Precondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111210);
      C.Accessibility_Status := AXL.Accessibility_Legality_Return_Object_Too_Short_Lived;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := CAL.Contract_Context_Precondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111211);
      C.Overload_Status := ORL.Overload_Legality_Ambiguous_After_Preference;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := CAL.Contract_Context_Refined_Depends;
      C.Subject := CAL.Contract_Subject_Package;
      C.Placement := CAL.Aspect_Placement_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111212);
      C.Cross_Unit_Status := CUS.Cross_Unit_Semantic_Missing_Dependency;
      CAL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := CAL.Contract_Context_Global_Aspect;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Placement := CAL.Aspect_Placement_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111213);
      C.Flow_State := CAL.Flow_Contract_Resolved;
      CAL.Add_Context (Contexts, C);

      declare
         Model : constant CAL.Contract_Legality_Model := CAL.Build (Contexts);
         Pre_Rows : constant CAL.Contract_Result_Set :=
           CAL.Rows_For_Kind (Model, CAL.Contract_Context_Precondition);
         Body_Rows : constant CAL.Contract_Result_Set :=
           CAL.Rows_For_Placement (Model, CAL.Aspect_Placement_Body);
         Flow_Rows : constant CAL.Contract_Result_Set :=
           CAL.Rows_For_Flow_State (Model, CAL.Flow_Contract_Unknown_Global);
      begin
         Assert (CAL.Legality_Count (Model) = 13,
                 "all contract/aspect contexts should produce legality rows");
         Assert (CAL.Legal_Count (Model) = 2,
                 "legal precondition and resolved Global aspect should be accepted");
         Assert (CAL.Error_Count (Model) = 11,
                 "all non-legal contract states should be counted as errors");
         Assert (CAL.Boolean_Error_Count (Model) = 1,
                 "non-Boolean contract condition should be counted");
         Assert (CAL.Static_Error_Count (Model) = 2,
                 "non-static predicate and linked staticness error should be counted");
         Assert (CAL.Flow_Error_Count (Model) = 1,
                 "unknown Global item should be counted as a flow error");
         Assert (CAL.View_Barrier_Count (Model) = 1,
                 "private view barrier should be counted");
         Assert (CAL.Linked_Error_Count (Model) = 5,
                 "assignment, return, accessibility, overload, and cross-unit links should be counted");
         Assert (CAL.Count_Status
                   (Model, CAL.Contract_Legality_Contract_Case_Choice_Overlap) = 1,
                 "contract case overlap should be classified directly");
         Assert (CAL.Count_Subject (Model, CAL.Contract_Subject_Subprogram) = 9,
                 "subject counter should preserve subprogram contract rows");
         Assert (CAL.Result_Count (Pre_Rows) = 3,
                 "kind lookup should return precondition rows");
         Assert (CAL.Result_Count (Body_Rows) = 2,
                 "placement lookup should return body aspect rows");
         Assert (CAL.Result_Count (Flow_Rows) = 1,
                 "flow-state lookup should return unknown-global rows");
         Assert (CAL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111203)).Status =
                 CAL.Contract_Legality_Static_Predicate_Non_Static,
                 "node lookup should preserve static predicate classification");
         Assert (CAL.Fingerprint (Model) /= 0,
                 "contract/aspect legality model fingerprint should be deterministic and non-zero");
      end;
   end Builds_Wide_Contract_Aspect_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Contract_Aspect_Legality'Access,
         "builds wide contract/aspect legality");
   end Register_Tests;

end Test_Ada_Contract_Aspect_Legality;
