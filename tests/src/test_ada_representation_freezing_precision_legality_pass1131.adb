with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Representation_Freezing_Precision_Legality;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Precision_Legality;

package body Test_Ada_Representation_Freezing_Precision_Legality_Pass1131 is

   package RFP renames Editor.Ada_Representation_Freezing_Precision_Legality;
   use type RFP.Freezing_Status;
   use type RFP.Representation_Status;
   use type RFP.Representation_Integration_Status;
   use type RFP.Generic_Instance_Status;
   use type RFP.Elaboration_Precision_Status;
   use type RFP.Tasking_Precision_Status;
   use type RFP.Representation_Freezing_Precision_Context_Id;
   use type RFP.Representation_Freezing_Precision_Id;
   use type RFP.Representation_Freezing_Precision_Context_Kind;
   use type RFP.Freezing_Cause_Kind;
   use type RFP.Representation_Freezing_Precision_Status;
   use type RFP.Representation_Freezing_Precision_Context_Info;
   use type RFP.Representation_Freezing_Precision_Info;
   use type RFP.Representation_Freezing_Precision_Context_Model;
   use type RFP.Representation_Freezing_Precision_Result_Set;
   use type RFP.Representation_Freezing_Precision_Model;
   package FRZ renames Editor.Ada_Freezing_Points;
   use type FRZ.Freezable_Kind;
   use type FRZ.Freezing_Cause;
   use type FRZ.Freezing_Status;
   use type FRZ.Representation_Freezing_Status;
   use type FRZ.Freezable_Id;
   use type FRZ.Freezable_Info;
   use type FRZ.Representation_Freeze_Info;
   use type FRZ.Freezing_Model;
   package REP renames Editor.Ada_Representation_Legality;
   use type REP.Representation_Legality_Status;
   use type REP.Address_Value_Status;
   use type REP.Interfacing_Value_Status;
   use type REP.Stream_Subprogram_Status;
   use type REP.Operational_Value_Status;
   use type REP.Representation_Value_Status;
   use type REP.Representation_Legality_Info;
   use type REP.Record_Component_Legality_Info;
   use type REP.Enumeration_Representation_Legality_Info;
   use type REP.Representation_Legality_Model;
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
   package TPL renames Editor.Ada_Tasking_Protected_Precision_Legality;
   use type TPL.Tasking_Legality_Status;
   use type TPL.Tasking_Context_Kind;
   use type TPL.Dataflow_Legality_Status;
   use type TPL.Elaboration_Precision_Status;
   use type TPL.Accessibility_Precision_Status;
   use type TPL.Tasking_Precision_Context_Id;
   use type TPL.Tasking_Precision_Legality_Id;
   use type TPL.Tasking_Precision_Context_Kind;
   use type TPL.Tasking_Precision_Status;
   use type TPL.Tasking_Precision_Context_Info;
   use type TPL.Tasking_Precision_Legality_Info;
   use type TPL.Tasking_Precision_Context_Model;
   use type TPL.Tasking_Precision_Result_Set;
   use type TPL.Tasking_Precision_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Representation_Freezing_Precision_Legality_Pass1131");
   end Name;

   procedure Builds_Representation_Freezing_Precision
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : RFP.Representation_Freezing_Precision_Context_Model;
      C        : RFP.Representation_Freezing_Precision_Context_Info;
   begin
      C.Id := 1;
      C.Kind := RFP.Representation_Freezing_Context_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113101);
      C.Target_Name := To_Unbounded_String ("T");
      C.Normalized_Target_Name := To_Unbounded_String ("t");
      C.Representation_Line := 5;
      C.Freeze_Line := 10;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := RFP.Representation_Freezing_Context_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113102);
      C.Normalized_Target_Name := To_Unbounded_String ("late_explicit");
      C.Representation := REP.Representation_Legality_After_Freezing;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := RFP.Representation_Freezing_Context_Representation_Aspect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113103);
      C.Normalized_Target_Name := To_Unbounded_String ("late_implicit");
      C.Representation_After_Implicit_Freezing := True;
      C.Cause := RFP.Freezing_Cause_Implicit_Call_Use;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := RFP.Representation_Freezing_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113104);
      C.Normalized_Target_Name := To_Unbounded_String ("late_generic");
      C.Representation_After_Generic_Instance_Freezing := True;
      C.Cause := RFP.Freezing_Cause_Generic_Instance;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := RFP.Representation_Freezing_Context_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113105);
      C.Normalized_Target_Name := To_Unbounded_String ("private_t");
      C.Private_View_Barrier := True;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := RFP.Representation_Freezing_Context_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113106);
      C.Normalized_Target_Name := To_Unbounded_String ("missing_full");
      C.Full_View_Completed := False;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := RFP.Representation_Freezing_Context_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113107);
      C.Normalized_Target_Name := To_Unbounded_String ("ambiguous");
      C.Freezing := FRZ.Freezing_Target_Ambiguous;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := RFP.Representation_Freezing_Context_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113108);
      C.Normalized_Target_Name := To_Unbounded_String ("layout_t");
      C.Integration := RLI.Representation_Integration_Variant_Layout_Overlap;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := RFP.Representation_Freezing_Context_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113109);
      C.Normalized_Target_Name := To_Unbounded_String ("stream_t");
      C.Integration := RLI.Representation_Integration_Stream_Profile_Mismatch;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := RFP.Representation_Freezing_Context_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113110);
      C.Normalized_Target_Name := To_Unbounded_String ("static_t");
      C.Representation := REP.Representation_Legality_Static_Value_Malformed;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := RFP.Representation_Freezing_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113111);
      C.Normalized_Target_Name := To_Unbounded_String ("inst_t");
      C.Generic_Instance := GIF.Instance_Legality_Representation_After_Instance_Freezing;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := RFP.Representation_Freezing_Context_Implicit_Semantic_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113112);
      C.Normalized_Target_Name := To_Unbounded_String ("elab_t");
      C.Elaboration := EPL.Elaboration_Precision_Body_Elaborated_After_Call;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := RFP.Representation_Freezing_Context_Task_Protected_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113113);
      C.Normalized_Target_Name := To_Unbounded_String ("task_t");
      C.Tasking := TPL.Tasking_Precision_Activation_Elaboration_Error;
      RFP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := RFP.Representation_Freezing_Context_Implicit_Semantic_Use;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113114);
      C.Normalized_Target_Name := To_Unbounded_String ("implicit_ok");
      C.Implicit_Use_Freezes_Target := True;
      RFP.Add_Context (Contexts, C);

      declare
         Model : constant RFP.Representation_Freezing_Precision_Model :=
           RFP.Build (Contexts);
         Clause_Rows : constant RFP.Representation_Freezing_Precision_Result_Set :=
           RFP.Rows_For_Kind (Model, RFP.Representation_Freezing_Context_Representation_Clause);
         Target_Rows : constant RFP.Representation_Freezing_Precision_Result_Set :=
           RFP.Rows_For_Target (Model, "late_implicit");
      begin
         Assert (RFP.Legality_Count (Model) = 14,
                 "all representation/freezing precision contexts should produce rows");
         Assert (RFP.Legal_Count (Model) = 2,
                 "ordinary representation and implicit freezing rows should be legal");
         Assert (RFP.Error_Count (Model) = 12,
                 "remaining rows should expose semantic blockers");
         Assert (RFP.Freezing_Error_Count (Model) = 3,
                 "explicit, implicit, and generic late representation rows should be freezing errors");
         Assert (RFP.View_Error_Count (Model) = 2,
                 "private barrier and missing full view should be view errors");
         Assert (RFP.Representation_Error_Count (Model) = 2,
                 "ambiguous/freezing target and static value errors should be representation errors");
         Assert (RFP.Integration_Error_Count (Model) = 2,
                 "layout and stream integration errors should be counted");
         Assert (RFP.Generic_Error_Count (Model) = 1,
                 "generic instance freezing error should be counted");
         Assert (RFP.Elaboration_Tasking_Error_Count (Model) = 2,
                 "elaboration and tasking effects should be counted");
         Assert (RFP.Result_Count (Clause_Rows) = 4,
                 "kind lookup should preserve representation clauses");
         Assert (RFP.Result_Count (Target_Rows) = 1,
                 "target lookup should preserve normalized target rows");
         Assert (RFP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (113103)).Status =
                 RFP.Representation_Freezing_Precision_Representation_After_Implicit_Freezing,
                 "node lookup should preserve implicit-freezing classification");
         Assert (RFP.Count_Status
                   (Model, RFP.Representation_Freezing_Precision_Record_Layout_Error) = 1,
                 "record layout integration error should be classified directly");
         Assert (RFP.Fingerprint (Model) /= 0,
                 "representation/freezing precision fingerprint should be deterministic and non-zero");
      end;
   end Builds_Representation_Freezing_Precision;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Representation_Freezing_Precision'Access,
         "builds representation/freezing precision legality");
   end Register_Tests;

end Test_Ada_Representation_Freezing_Precision_Legality_Pass1131;
