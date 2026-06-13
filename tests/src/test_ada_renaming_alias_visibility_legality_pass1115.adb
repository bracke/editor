with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package body Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115 is

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
   package OVL renames Editor.Ada_Overload_Resolution_Legality;
   use type OVL.Overload_Context_Id;
   use type OVL.Overload_Legality_Id;
   use type OVL.Overload_Context_Kind;
   use type OVL.Overload_Legality_Status;
   use type OVL.Overload_Context_Info;
   use type OVL.Overload_Legality_Info;
   use type OVL.Overload_Context_Model;
   use type OVL.Overload_Legality_Result_Set;
   use type OVL.Overload_Legality_Model;
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
      return AUnit.Format ("Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115");
   end Name;

   procedure Builds_Wide_Renaming_Alias_Visibility_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : RAV.Renaming_Context_Model;
      C        : RAV.Renaming_Context_Info;
   begin
      C.Id := 1;
      C.Kind := RAV.Renaming_Context_Object;
      C.Renamed_Kind := RAV.Renamed_Entity_Object;
      C.Visibility := RAV.Visibility_Local_Direct;
      C.Alias := RAV.Alias_Object_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111501);
      C.Name := To_Unbounded_String ("Alias_X");
      C.Normalized_Name := To_Unbounded_String ("alias_x");
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := RAV.Renaming_Context_Subprogram;
      C.Renamed_Kind := RAV.Renamed_Entity_Subprogram;
      C.Profile_Mismatch := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111502);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := RAV.Renaming_Context_Package;
      C.Renamed_Kind := RAV.Renamed_Entity_Package;
      C.Target_Present := False;
      C.Visibility := RAV.Visibility_Missing;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111503);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := RAV.Renaming_Context_Package;
      C.Renamed_Kind := RAV.Renamed_Entity_Package;
      C.Target_Ambiguous := True;
      C.Visibility := RAV.Visibility_Ambiguous;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111504);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := RAV.Renaming_Context_Generic_Subprogram;
      C.Renamed_Kind := RAV.Renamed_Entity_Generic_Subprogram;
      C.Generic_Profile_Mismatch := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111505);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := RAV.Renaming_Context_Object;
      C.Renamed_Kind := RAV.Renamed_Entity_Constant;
      C.Renames_Constant_As_Variable := True;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111506);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := RAV.Renaming_Context_Object;
      C.Renamed_Kind := RAV.Renamed_Entity_Object;
      C.Alias := RAV.Alias_Self_Rename;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111507);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := RAV.Renaming_Context_Object;
      C.Renamed_Kind := RAV.Renamed_Entity_Object;
      C.Alias := RAV.Alias_Circular_Rename;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111508);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := RAV.Renaming_Context_Alias_View;
      C.Renamed_Kind := RAV.Renamed_Entity_Selected_Component;
      C.Requires_Aliased_Target := True;
      C.Target_Is_Aliased := False;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111509);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := RAV.Renaming_Context_Use_Package;
      C.Renamed_Kind := RAV.Renamed_Entity_Type;
      C.Use_State := RAV.Use_Clause_Non_Package_Target;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111510);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := RAV.Renaming_Context_Use_Type;
      C.Renamed_Kind := RAV.Renamed_Entity_Type;
      C.Use_State := RAV.Use_Clause_Duplicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111511);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := RAV.Renaming_Context_Selected_Name;
      C.Visibility := RAV.Visibility_Hidden_By_Homograph;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111512);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := RAV.Renaming_Context_Selected_Name;
      C.Visibility := RAV.Visibility_Limited_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111513);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := RAV.Renaming_Context_Object;
      C.Accessibility_Status := AAL.Accessibility_Legality_Level_Too_Deep;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111514);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := RAV.Renaming_Context_Subprogram;
      C.Overload_Status := OVL.Overload_Legality_Ambiguous_After_Preference;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111515);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 16;
      C.Kind := RAV.Renaming_Context_Package;
      C.Cross_Unit_Status := CUS.Cross_Unit_Semantic_Missing_Dependency;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111516);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 17;
      C.Kind := RAV.Renaming_Context_Package;
      C.Completion_Status := UCL.Completion_Legality_Use_Before_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111517);
      RAV.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 18;
      C.Kind := RAV.Renaming_Context_Unknown;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111518);
      RAV.Add_Context (Contexts, C);

      declare
         Model : constant RAV.Renaming_Legality_Model := RAV.Build (Contexts);
         Object_Rows : constant RAV.Renaming_Result_Set :=
           RAV.Rows_For_Kind (Model, RAV.Renaming_Context_Object);
         Limited_Rows : constant RAV.Renaming_Result_Set :=
           RAV.Rows_For_Visibility (Model, RAV.Visibility_Limited_View);
         Use_Rows : constant RAV.Renaming_Result_Set :=
           RAV.Rows_For_Use_State (Model, RAV.Use_Clause_Duplicate);
      begin
         Assert (RAV.Legality_Count (Model) = 18,
                 "all renaming/alias/visibility contexts should produce rows");
         Assert (RAV.Legal_Count (Model) = 1,
                 "only direct object renaming is legal in this negative fixture");
         Assert (RAV.Error_Count (Model) = 17,
                 "remaining contexts should expose legality errors");
         Assert (RAV.Profile_Error_Count (Model) = 2,
                 "subprogram and generic profile mismatches should be counted");
         Assert (RAV.Visibility_Error_Count (Model) = 3,
                 "missing, ambiguous, and hidden visibility errors should be counted");
         Assert (RAV.Alias_Error_Count (Model) = 4,
                 "constant, self, circular, and non-aliased alias errors should be counted");
         Assert (RAV.Use_Clause_Error_Count (Model) = 2,
                 "non-package and duplicate use clauses should be counted");
         Assert (RAV.View_Barrier_Count (Model) = 1,
                 "limited view barriers should be counted");
         Assert (RAV.Linked_Error_Count (Model) = 4,
                 "accessibility, overload, cross-unit, and completion linked blockers should be counted");
         Assert (RAV.Indeterminate_Count (Model) = 1,
                 "unknown context should remain indeterminate");
         Assert (RAV.Count_Status (Model, RAV.Renaming_Legality_Missing_Target) = 1,
                 "missing target should be classified directly");
         Assert (RAV.Count_Renamed_Kind (Model, RAV.Renamed_Entity_Package) = 3,
                 "package target kinds should be counted");
         Assert (RAV.Result_Count (Object_Rows) = 5,
                 "object renaming lookup should include object contexts");
         Assert (RAV.Result_Count (Limited_Rows) = 1,
                 "visibility lookup should return limited-view row");
         Assert (RAV.Result_Count (Use_Rows) = 1,
                 "use-state lookup should return duplicate use clause row");
         Assert (RAV.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111507)).Status =
                 RAV.Renaming_Legality_Self_Renaming,
                 "node lookup should preserve self-renaming classification");
         Assert (RAV.Fingerprint (Model) /= 0,
                 "renaming/alias/visibility legality fingerprint should be deterministic and non-zero");
      end;
   end Builds_Wide_Renaming_Alias_Visibility_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Renaming_Alias_Visibility_Legality'Access,
         "builds wide renaming/alias/visibility legality");
   end Register_Tests;

end Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115;
