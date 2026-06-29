with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Record_Layout_Exact_Validation;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Stream_Attribute_Profile_Conformance;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package body Test_Ada_Representation_Layout_Stream_Integration_Legality is

   package RLI renames Editor.Ada_Representation_Layout_Stream_Integration_Legality;
   use type RLI.Representation_Status;
   use type RLI.Exact_Layout_Status;
   use type RLI.Stream_Status;
   use type RLI.Generic_Instance_Status;
   use type RLI.Accessibility_Status;
   use type RLI.Staticness_Status;
   use type RLI.Completion_Status;
   use type RLI.Contract_Status;
   use type RLI.Exception_Status;
   use type RLI.Representation_Integration_Context_Id;
   use type RLI.Representation_Integration_Id;
   use type RLI.Representation_Integration_Context_Kind;
   use type RLI.Layout_State;
   use type RLI.Stream_State;
   use type RLI.Representation_Integration_Status;
   use type RLI.Representation_Integration_Context_Info;
   use type RLI.Representation_Integration_Info;
   use type RLI.Representation_Integration_Context_Model;
   use type RLI.Representation_Integration_Result_Set;
   use type RLI.Representation_Integration_Model;
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
   package REL renames Editor.Ada_Representation_Legality;
   use type REL.Representation_Legality_Status;
   use type REL.Address_Value_Status;
   use type REL.Interfacing_Value_Status;
   use type REL.Stream_Subprogram_Status;
   use type REL.Operational_Value_Status;
   use type REL.Representation_Value_Status;
   use type REL.Representation_Legality_Info;
   use type REL.Record_Component_Legality_Info;
   use type REL.Enumeration_Representation_Legality_Info;
   use type REL.Representation_Legality_Model;
   package RLE renames Editor.Ada_Record_Layout_Exact_Validation;
   use type RLE.Exact_Record_Layout_Status;
   use type RLE.Exact_Record_Layout_Info;
   use type RLE.Exact_Record_Layout_Model;
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
   package SAP renames Editor.Ada_Stream_Attribute_Profile_Conformance;
   use type SAP.Stream_Profile_Conformance_Status;
   use type SAP.Stream_Profile_Conformance_Info;
   use type SAP.Stream_Profile_Conformance_Model;
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
      return AUnit.Format ("Test_Ada_Representation_Layout_Stream_Integration_Legality");
   end Name;

   procedure Builds_Wide_Representation_Integration_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : RLI.Representation_Integration_Context_Model;
      C        : RLI.Representation_Integration_Context_Info;
   begin
      C.Id := 1;
      C.Kind := RLI.Representation_Context_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111701);
      C.Target_Name := To_Unbounded_String ("T");
      C.Normalized_Target := To_Unbounded_String ("t");
      C.Representation := REL.Representation_Legality_Ok;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := RLI.Representation_Context_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111702);
      C.Representation := REL.Representation_Legality_After_Freezing;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := RLI.Representation_Context_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111703);
      C.Layout := RLI.Layout_Size_Exceeded;
      C.Exact_Layout := RLE.Exact_Record_Layout_Size_Clause_Exceeded;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := RLI.Representation_Context_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111704);
      C.Layout := RLI.Layout_Padded;
      C.Exact_Layout := RLE.Exact_Record_Layout_Size_Clause_Padded;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := RLI.Representation_Context_Variant_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111705);
      C.Layout := RLI.Layout_Variant_Hole;
      C.Variant_Hole := True;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := RLI.Representation_Context_Variant_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111706);
      C.Layout := RLI.Layout_Variant_Overlap;
      C.Variant_Overlap := True;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := RLI.Representation_Context_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111707);
      C.Stream := RLI.Stream_Profile_Compatible;
      C.Stream_Profile := SAP.Stream_Profile_Conformance_Compatible;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := RLI.Representation_Context_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111708);
      C.Stream := RLI.Stream_Handler_Missing;
      C.Stream_Profile := SAP.Stream_Profile_Conformance_Handler_Missing;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := RLI.Representation_Context_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111709);
      C.Stream_Profile := SAP.Stream_Profile_Conformance_Result_Mismatch;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := RLI.Representation_Context_Generic_Instance_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111710);
      C.Generic_Instance := GIF.Instance_Legality_Representation_After_Instance_Freezing;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := RLI.Representation_Context_Address_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111711);
      C.Representation := REL.Representation_Legality_Address_Value_Not_Static_Address;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := RLI.Representation_Context_Size_Alignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111712);
      C.Staticness := SRP.Static_Legality_Range_Violation;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := RLI.Representation_Context_Address_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111713);
      C.Accessibility := AAL.Accessibility_Legality_Level_Too_Deep;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := RLI.Representation_Context_Aspect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111714);
      C.Contract := CAL.Contract_Legality_Duplicate_Aspect;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := RLI.Representation_Context_Controlled_Finalization_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111715);
      C.Exception_Finalization := EFL.Exception_Legality_Finalization_Order_Error;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 16;
      C.Kind := RLI.Representation_Context_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111716);
      C.Completion := UCL.Completion_Legality_Use_Before_Full_View;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 17;
      C.Kind := RLI.Representation_Context_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111717);
      C.Private_View_Barrier := True;
      RLI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 18;
      C.Kind := RLI.Representation_Context_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111718);
      C.Cross_Unit_Unresolved := True;
      RLI.Add_Context (Contexts, C);

      declare
         Model : constant RLI.Representation_Integration_Model := RLI.Build (Contexts);
      begin
         Assert (RLI.Legality_Count (Model) = 18, "all contexts projected");
         Assert (RLI.Legal_Count (Model) = 2, "legal representation and stream rows counted");
         Assert (RLI.Count_Status (Model, RLI.Representation_Integration_After_Freezing) = 1,
                 "freezing error classified");
         Assert (RLI.Layout_Error_Count (Model) = 3, "layout errors counted");
         Assert (RLI.Stream_Error_Count (Model) = 2, "stream errors counted");
         Assert (RLI.Linked_Error_Count (Model) = 6, "linked semantic errors counted");
         Assert (RLI.View_Barrier_Count (Model) = 2, "view/cross-unit barriers counted");
         Assert (RLI.Result_Count (RLI.Rows_For_Kind (Model, RLI.Representation_Context_Stream_Attribute)) = 3,
                 "stream lookup works");
         Assert (RLI.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (111708)).Status =
                   RLI.Representation_Integration_Stream_Handler_Missing,
                 "node lookup preserves stream handler status");
         Assert (RLI.Fingerprint (Model) /= 0, "model has deterministic fingerprint");
      end;
   end Builds_Wide_Representation_Integration_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Builds_Wide_Representation_Integration_Legality'Access,
         "Pass1117 representation/layout/stream integration legality");
   end Register_Tests;

end Test_Ada_Representation_Layout_Stream_Integration_Legality;
