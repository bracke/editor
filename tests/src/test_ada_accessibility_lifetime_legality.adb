with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Lifetime_Legality is

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

   use type AXL.Accessibility_Legality_Status;
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
   package SL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type SL.Semantic_Context_Id;
   use type SL.Semantic_Legality_Id;
   use type SL.Semantic_Context_Kind;
   use type SL.Access_Kind;
   use type SL.Semantic_Legality_Status;
   use type SL.Semantic_Context_Info;
   use type SL.Semantic_Legality_Info;
   use type SL.Semantic_Context_Model;
   use type SL.Semantic_Legality_Result_Set;
   use type SL.Semantic_Legality_Model;
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
      return AUnit.Format ("Test_Ada_Accessibility_Lifetime_Legality");
   end Name;

   procedure Builds_Wide_Accessibility_Lifetime_And_Aliasing_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AXL.Accessibility_Context_Model;
      C        : AXL.Accessibility_Context_Info;
   begin
      C.Id := 1;
      C.Kind := AXL.Access_Context_Object_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111101);
      C.Source_Access := AXL.Access_Target_Object;
      C.Target_Access := AXL.Access_Target_Object;
      C.Source_Level := AXL.Accessibility_Level_Master;
      C.Target_Level := AXL.Accessibility_Level_Local;
      C.Accessibility_Known_Compatible := True;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := AXL.Access_Context_Object_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111102);
      C.Source_Is_Null_Literal := True;
      C.Target_Is_Null_Excluding := True;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := AXL.Access_Context_Aliased_Object_Reference;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111103);
      C.Requires_Aliased_Target := True;
      C.Target_Is_Aliased := False;
      C.Alias_State := AXL.Alias_Required;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := AXL.Access_Context_Return_Access;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111104);
      C.Return_Object_Context := True;
      C.Escapes_Current_Master := True;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := AXL.Access_Context_Access_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111105);
      C.Source_Access := AXL.Access_Target_Object;
      C.Target_Access := AXL.Access_Target_Subprogram;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := AXL.Access_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111106);
      C.Semantic_Item := SL.Semantic_Legality_Id (6);
      C.Semantic_Status := SL.Semantic_Legality_Allocator_Designated_Subtype_Mismatch;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := AXL.Access_Context_Anonymous_Access_Parameter;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111107);
      C.Source_Level := AXL.Accessibility_Level_Unknown;
      C.Target_Level := AXL.Accessibility_Level_Unknown;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := AXL.Access_Context_Generic_Actual;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111108);
      C.Assignment := AL.Assignment_Legality_Id (8);
      C.Assignment_Status := AL.Assignment_Legality_Null_Exclusion_Violation;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := AXL.Access_Context_Return_Object;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111109);
      C.Return_Item := RL.Return_Legality_Id (9);
      C.Return_Status := RL.Return_Legality_Result_Source_Unresolved;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := AXL.Access_Context_Aggregate_Component;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111110);
      C.Static_Item := SRP.Static_Legality_Id (10);
      C.Static_Status := SRP.Static_Legality_Range_Violation;
      AXL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := AXL.Access_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111111);
      C.Source_Access := AXL.Access_Target_Object;
      C.Target_Access := AXL.Access_Target_Object;
      C.Source_Level := AXL.Accessibility_Level_Library;
      C.Target_Level := AXL.Accessibility_Level_Local;
      AXL.Add_Context (Contexts, C);

      declare
         Model : constant AXL.Accessibility_Legality_Model := AXL.Build (Contexts);
         Alias_Rows : constant AXL.Accessibility_Result_Set :=
           AXL.Rows_For_Alias_State (Model, AXL.Alias_Required);
         Unknown_Level_Rows : constant AXL.Accessibility_Result_Set :=
           AXL.Rows_For_Level (Model, AXL.Accessibility_Level_Unknown);
      begin
         Assert (AXL.Legality_Count (Model) = 11,
                 "all accessibility contexts should produce legality rows");
         Assert (AXL.Legal_Count (Model) = 2,
                 "known compatible assignment and compatible allocator should be legal");
         Assert (AXL.Error_Count (Model) = 9,
                 "accessibility, aliasing, linked, and indeterminate failures should be counted");
         Assert (AXL.Null_Exclusion_Error_Count (Model) = 1,
                 "direct null-exclusion violation should be counted");
         Assert (AXL.Aliasing_Error_Count (Model) = 1,
                 "missing aliased target should be counted");
         Assert (AXL.Lifetime_Error_Count (Model) = 2,
                 "return lifetime and anonymous access unresolved level should be counted");
         Assert (AXL.Linked_Error_Count (Model) = 3,
                 "assignment, return, and staticness linked errors should be counted");
         Assert (AXL.Count_Status
                   (Model, AXL.Accessibility_Legality_Access_Kind_Mismatch) = 1,
                 "access kind mismatch should be classified directly");
         Assert (AXL.Count_Status
                   (Model, AXL.Accessibility_Legality_Allocator_Designated_Subtype_Mismatch) = 1,
                 "allocator designated subtype mismatch should be classified directly");
         Assert (AXL.Result_Count (Alias_Rows) = 1,
                 "alias-state lookup should find required aliased target rows");
         Assert (AXL.Result_Count (Unknown_Level_Rows) = 1,
                 "level lookup should find anonymous access unresolved rows");
         Assert (AXL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111104)).Status =
                 AXL.Accessibility_Legality_Return_Object_Too_Short_Lived,
                 "node lookup should preserve return lifetime classification");
      end;
   end Builds_Wide_Accessibility_Lifetime_And_Aliasing_Legality;

   procedure Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AXL.Accessibility_Context_Model;
      Model    : constant AXL.Accessibility_Legality_Model := AXL.Build (Contexts);
   begin
      Assert (AXL.Legality_Count (Model) = 0,
              "empty accessibility context model should produce no rows");
      Assert (not AXL.Has_Legality
                (AXL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (1))),
              "absent accessibility node lookup should return no legality row");
   end Empty_Inputs_Are_Deterministic;

   procedure Builds_Contexts_From_Access_Semantic_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Semantic_Contexts : SL.Semantic_Context_Model;
      C                 : SL.Semantic_Context_Info;
   begin
      C.Id := 21;
      C.Kind := SL.Semantic_Context_Access_Parameter;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111121);
      C.Target_Node := Editor.Ada_Syntax_Tree.Node_Id (111122);
      C.Operand_Node := Editor.Ada_Syntax_Tree.Node_Id (111123);
      C.Target_Subtype := To_Unbounded_String ("access Integer");
      C.Operand_Subtype := To_Unbounded_String ("access Integer");
      C.Target_Access := SL.Access_Kind_Object;
      C.Operand_Access := SL.Access_Kind_Object;
      C.Requires_Accessibility_Check := True;
      C.Accessibility_Known_Compatible := False;
      C.Start_Line := 14;
      C.End_Line := 14;
      SL.Add_Context (Semantic_Contexts, C);

      C := (others => <>);
      C.Id := 22;
      C.Kind := SL.Semantic_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111124);
      C.Target_Subtype := To_Unbounded_String ("access Integer");
      C.Operand_Subtype := To_Unbounded_String ("access Float");
      C.Target_Access := SL.Access_Kind_Object;
      C.Operand_Access := SL.Access_Kind_Object;
      SL.Add_Context (Semantic_Contexts, C);

      declare
         Semantic_Model : constant SL.Semantic_Legality_Model :=
           SL.Build (Semantic_Contexts);
         Contexts : constant AXL.Accessibility_Context_Model :=
           AXL.Build_Contexts_From_Semantic_Legality (Semantic_Model);
         Model : constant AXL.Accessibility_Legality_Model :=
           AXL.Build (Contexts);
      begin
         Assert (AXL.Context_Count (Contexts) = 2,
                 "access semantic legality rows should become accessibility contexts");
         Assert (AXL.Count_Status
                   (Model, AXL.Accessibility_Legality_Anonymous_Access_Level_Unresolved) = 1,
                 "indeterminate access parameter should become an accessibility lifetime row");
         Assert (AXL.Count_Status
                   (Model, AXL.Accessibility_Legality_Allocator_Designated_Subtype_Mismatch) = 1,
                 "allocator subtype mismatch should be preserved as accessibility blocker");
         Assert (AXL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (111123)).Start_Line = 14,
                 "source span and operand node should be preserved");
         Assert (AXL.Fingerprint (Model) /= 0,
                 "derived accessibility legality should fingerprint deterministically");
      end;
   end Builds_Contexts_From_Access_Semantic_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Accessibility_Lifetime_And_Aliasing_Legality'Access,
         "Case 1111 classifies accessibility, lifetime, aliasing, and linked access legality");
      Register_Routine
        (T, Empty_Inputs_Are_Deterministic'Access,
         "Case 1111 keeps empty accessibility legality models deterministic");
      Register_Routine
        (T, Builds_Contexts_From_Access_Semantic_Legality'Access,
         "Case 1111 derives accessibility contexts from access semantic legality");
   end Register_Tests;

end Test_Ada_Accessibility_Lifetime_Legality;
