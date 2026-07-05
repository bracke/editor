with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Representation_Freezing_Precision_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Generic_Instance_Body_Semantic_Replay is

   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   use type Replay.Replay_Context_Id;
   use type Replay.Replay_Row_Id;
   use type Replay.Replay_Context_Kind;
   use type Replay.Replay_Status;
   use type Replay.Replay_Context_Info;
   use type Replay.Replay_Info;
   use type Replay.Replay_Context_Model;
   use type Replay.Replay_Result_Set;
   use type Replay.Replay_Model;
   package Expansion renames Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
   use type Expansion.Instantiated_Body_Status;
   use type Expansion.Overload_Legality_Status;
   use type Expansion.Accessibility_Legality_Status;
   use type Expansion.Contract_Legality_Status;
   use type Expansion.Dataflow_Legality_Status;
   use type Expansion.Initialization_Legality_Status;
   use type Expansion.Predicate_Use_Legality_Status;
   use type Expansion.Representation_Integration_Status;
   use type Expansion.Generic_Body_Expansion_Context_Id;
   use type Expansion.Generic_Body_Expansion_Id;
   use type Expansion.Generic_Body_Expansion_Context_Kind;
   use type Expansion.Generic_Body_Expansion_Status;
   use type Expansion.Generic_Body_Expansion_Context_Info;
   use type Expansion.Generic_Body_Expansion_Info;
   use type Expansion.Generic_Body_Expansion_Context_Model;
   use type Expansion.Generic_Body_Expansion_Result_Set;
   use type Expansion.Generic_Body_Expansion_Model;
   package GA renames Editor.Ada_Generic_Instantiated_Body_Analysis;
   use type GA.Instantiated_Body_Status;
   use type GA.Instantiated_Body_Substitution_Id;
   use type GA.Instantiated_Body_Substitution_Info;
   use type GA.Instantiated_Body_Model;
   package Preference renames Editor.Ada_Overload_Preference_Legality;
   use type Preference.Preference_Context_Id;
   use type Preference.Preference_Legality_Id;
   use type Preference.Preference_Context_Kind;
   use type Preference.Preference_Legality_Status;
   use type Preference.Preference_Context_Info;
   use type Preference.Preference_Legality_Info;
   use type Preference.Preference_Context_Model;
   use type Preference.Preference_Legality_Result_Set;
   use type Preference.Preference_Legality_Model;
   package Access_Precision renames Editor.Ada_Accessibility_Precision_Legality;
   use type Access_Precision.Accessibility_Legality_Status;
   use type Access_Precision.Accessibility_Level;
   use type Access_Precision.Access_Context_Kind;
   use type Access_Precision.Record_Aggregate_Legality_Status;
   use type Access_Precision.Generic_Body_Expansion_Status;
   use type Access_Precision.Accessibility_Precision_Context_Id;
   use type Access_Precision.Accessibility_Precision_Legality_Id;
   use type Access_Precision.Accessibility_Precision_Context_Kind;
   use type Access_Precision.Accessibility_Precision_Status;
   use type Access_Precision.Accessibility_Precision_Context_Info;
   use type Access_Precision.Accessibility_Precision_Legality_Info;
   use type Access_Precision.Accessibility_Precision_Context_Model;
   use type Access_Precision.Accessibility_Precision_Result_Set;
   use type Access_Precision.Accessibility_Precision_Legality_Model;
   package Flow_Graph renames Editor.Ada_Flow_Effect_Graph_Legality;
   use type Flow_Graph.Flow_Edge_Id;
   use type Flow_Graph.Flow_Graph_Context_Kind;
   use type Flow_Graph.Flow_Edge_Kind;
   use type Flow_Graph.Flow_Effect_Graph_Status;
   use type Flow_Graph.Flow_Effect_Context_Info;
   use type Flow_Graph.Flow_Effect_Info;
   use type Flow_Graph.Flow_Effect_Context_Model;
   use type Flow_Graph.Flow_Effect_Set;
   use type Flow_Graph.Flow_Effect_Graph_Model;
   package Predicate_Propagation renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   use type Predicate_Propagation.Propagation_Row_Id;
   use type Predicate_Propagation.Propagation_Context_Kind;
   use type Predicate_Propagation.Propagation_Obligation_Kind;
   use type Predicate_Propagation.Propagation_Status;
   use type Predicate_Propagation.Propagation_Context_Info;
   use type Predicate_Propagation.Propagation_Info;
   use type Predicate_Propagation.Propagation_Context_Model;
   use type Predicate_Propagation.Propagation_Set;
   use type Predicate_Propagation.Propagation_Model;
   package Representation_Freezing renames Editor.Ada_Representation_Freezing_Precision_Legality;
   use type Representation_Freezing.Freezing_Status;
   use type Representation_Freezing.Representation_Status;
   use type Representation_Freezing.Representation_Integration_Status;
   use type Representation_Freezing.Generic_Instance_Status;
   use type Representation_Freezing.Elaboration_Precision_Status;
   use type Representation_Freezing.Tasking_Precision_Status;
   use type Representation_Freezing.Representation_Freezing_Precision_Context_Id;
   use type Representation_Freezing.Representation_Freezing_Precision_Id;
   use type Representation_Freezing.Representation_Freezing_Precision_Context_Kind;
   use type Representation_Freezing.Freezing_Cause_Kind;
   use type Representation_Freezing.Representation_Freezing_Precision_Status;
   use type Representation_Freezing.Representation_Freezing_Precision_Context_Info;
   use type Representation_Freezing.Representation_Freezing_Precision_Info;
   use type Representation_Freezing.Representation_Freezing_Precision_Context_Model;
   use type Representation_Freezing.Representation_Freezing_Precision_Result_Set;
   use type Representation_Freezing.Representation_Freezing_Precision_Model;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Gates.Enforcement_Row_Id;
   use type Gates.Widened_Legality_Engine;
   use type Gates.Enforcement_Status;
   use type Gates.Enforcement_Context_Info;
   use type Gates.Enforcement_Info;
   use type Gates.Enforcement_Context_Model;
   use type Gates.Enforcement_Set;
   use type Gates.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Generic_Instance_Body_Semantic_Replay");
   end Name;

   function Sample_Context_Model return Replay.Replay_Context_Model is
      Contexts : Replay.Replay_Context_Model;
      C        : Replay.Replay_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Replay.Replay_Context_Body_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114001);
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.Node_Id (14001);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (24001);
      C.Formal_Name := To_Unbounded_String ("Element_Type");
      C.Actual_Name := To_Unbounded_String ("Integer");
      C.Generic_Unit_Name := To_Unbounded_String ("Vectors");
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Expansion_Status := Expansion.Generic_Body_Expansion_Legal_Substitution;
      C.Source_Fingerprint := 1_401;
      C.Substitution_Fingerprint := 2_401;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Replay.Replay_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114002);
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.Node_Id (14002);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (24002);
      C.Generic_Unit_Name := To_Unbounded_String ("Vectors");
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Expansion_Status := Expansion.Generic_Body_Expansion_Legal_Overload;
      C.Overload_Status := Preference.Preference_Legality_Legal_Exact_Profile;
      C.Source_Fingerprint := 1_402;
      C.Substitution_Fingerprint := 2_402;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Replay.Replay_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114003);
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.Node_Id (14003);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (24003);
      C.Generic_Unit_Name := To_Unbounded_String ("Vectors");
      C.Instance_Name := To_Unbounded_String ("Broken_Vectors");
      C.Overload_Status := Preference.Preference_Legality_Ambiguous_After_RM_Preferences;
      C.Source_Fingerprint := 1_403;
      C.Substitution_Fingerprint := 2_403;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Replay.Replay_Context_Flow_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114004);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Flow_Status := Flow_Graph.Flow_Graph_Body_Spec_Global_Mismatch;
      C.Source_Fingerprint := 1_404;
      C.Substitution_Fingerprint := 2_404;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Replay.Replay_Context_Predicate_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114005);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Predicate_Status := Predicate_Propagation.Propagation_Derived_Type_Invariant_Missing;
      C.Source_Fingerprint := 1_405;
      C.Substitution_Fingerprint := 2_405;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Replay.Replay_Context_Accessibility;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114006);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Accessibility_Status := Access_Precision.Accessibility_Precision_Generic_Actual_Too_Short_Lived;
      C.Source_Fingerprint := 1_406;
      C.Substitution_Fingerprint := 2_406;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Replay.Replay_Context_Representation_Freezing;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114007);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Representation_Status :=
        Representation_Freezing.Representation_Freezing_Precision_Representation_After_Generic_Instance_Freezing;
      C.Source_Fingerprint := 1_407;
      C.Substitution_Fingerprint := 2_407;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Replay.Replay_Context_Body_Statement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114008);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Expansion_Status := Expansion.Generic_Body_Expansion_Legal_Substitution;
      C.Source_Mapping_Present := False;
      C.Source_Fingerprint := 1_408;
      C.Substitution_Fingerprint := 2_408;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := Replay.Replay_Context_Body_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114009);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Expansion_Status := Expansion.Generic_Body_Expansion_Legal_Substitution;
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_409;
      C.Substitution_Fingerprint := 2_409;
      Replay.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := Replay.Replay_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114010);
      C.Instance_Name := To_Unbounded_String ("Integer_Vectors");
      C.Expansion_Status := Expansion.Generic_Body_Expansion_Object_Mismatch;
      C.Flow_Status := Flow_Graph.Flow_Graph_Write_Not_In_Global;
      C.Source_Fingerprint := 1_410;
      C.Substitution_Fingerprint := 2_410;
      Replay.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Replay_Rows_Preserve_Instance_And_Generic_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Replay.Replay_Model := Replay.Build (Sample_Context_Model);
      Decl_Row : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114001));
      Call_Row : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114002));
      Ambiguous_Call : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114003));
      Flow_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114004));
      Predicate_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114005));
      Access_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114006));
      Rep_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114007));
      Mapping_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114008));
      Gate_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114009));
      Multi_Error : constant Replay.Replay_Info :=
        Replay.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114010));
   begin
      Assert (Replay.Row_Count (Model) = 10,
              "all replay contexts should be analyzed");
      Assert (Decl_Row.Status = Replay.Replay_Legal_Substituted_Declaration,
              "legal substitution should replay as a substituted declaration");
      Assert (Call_Row.Status = Replay.Replay_Legal_Call,
              "legal overload preference should replay as a legal call");
      Assert (Ambiguous_Call.Status = Replay.Replay_Overload_Preference_Error,
              "overload preference ambiguity should block generic body replay");
      Assert (Flow_Error.Status = Replay.Replay_Flow_Effect_Error,
              "flow graph errors should block replay");
      Assert (Predicate_Error.Status = Replay.Replay_Predicate_Propagation_Error,
              "predicate propagation errors should block replay");
      Assert (Access_Error.Status = Replay.Replay_Accessibility_Precision_Error,
              "accessibility precision errors should block replay");
      Assert (Rep_Error.Status = Replay.Replay_Representation_Freezing_Error,
              "representation/freezing errors should block replay");
      Assert (Mapping_Error.Status = Replay.Replay_Source_Instance_Mapping_Missing,
              "generic source to instance mapping is required");
      Assert (Gate_Error.Status = Replay.Replay_Coverage_Gate_Blocker,
              "coverage gates should block replay conclusions");
      Assert (Multi_Error.Status = Replay.Replay_Multiple_Blockers,
              "multiple semantic blockers must be preserved");
      Assert (Replay.Legal_Count (Model) = 2,
              "only two replay rows should remain legal");
      Assert (Replay.Overload_Error_Count (Model) = 1,
              "overload replay error should be counted");
      Assert (Replay.Flow_Error_Count (Model) = 1,
              "flow replay error should be counted");
      Assert (Replay.Predicate_Error_Count (Model) = 1,
              "predicate replay error should be counted");
      Assert (Replay.Accessibility_Error_Count (Model) = 1,
              "accessibility replay error should be counted");
      Assert (Replay.Representation_Error_Count (Model) = 1,
              "representation/freezing replay error should be counted");
      Assert (Replay.Mapping_Error_Count (Model) = 1,
              "mapping error should be counted");
      Assert (Replay.Coverage_Gate_Error_Count (Model) = 1,
              "coverage gate error should be counted");
      Assert (Replay.Multiple_Blocker_Count (Model) = 1,
              "multiple blocker error should be counted");
      Assert (Replay.Result_Count (Replay.Rows_For_Instance (Model, "integer_vectors")) = 9,
              "instance-name lookup should be case-insensitive and deterministic");
      Assert (Replay.Fingerprint (Model) /= 0,
              "replay model should have a deterministic non-zero fingerprint");
   end Replay_Rows_Preserve_Instance_And_Generic_Blockers;

   procedure Expansion_Rows_Are_Converted_To_Replay_Contexts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Expansion.Generic_Body_Expansion_Context_Model;
      C        : Expansion.Generic_Body_Expansion_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Expansion.Generic_Body_Expansion_Formal_Object;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114020);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (114021);
      C.Body_Node := Editor.Ada_Syntax_Tree.Node_Id (114022);
      C.Formal_Name := To_Unbounded_String ("Item");
      C.Actual_Text := To_Unbounded_String ("Integer");
      C.Body_Status := GA.Instantiated_Body_Substituted;
      C.Source_Fingerprint := 3_140;
      Expansion.Add_Context (Contexts, C);

      declare
         Expansion_Model : constant Expansion.Generic_Body_Expansion_Model :=
           Expansion.Build (Contexts);
         Replay_Model : constant Replay.Replay_Model :=
           Replay.Build_From_Expansion (Expansion_Model);
         Row : constant Replay.Replay_Info :=
           Replay.First_For_Node (Replay_Model, Editor.Ada_Syntax_Tree.Node_Id (114020));
      begin
         Assert (Replay.Row_Count (Replay_Model) = 1,
                 "expansion rows should be converted into replay rows");
         Assert (Row.Status = Replay.Replay_Legal_Substituted_Declaration,
                 "legal generic body expansion should replay as a legal declaration");
         Assert (To_String (Row.Formal_Name) = "Item",
                 "formal name should be preserved for diagnostic backmapping");
         Assert (To_String (Row.Actual_Name) = "Integer",
                 "actual text should be preserved for diagnostic backmapping");
      end;
   end Expansion_Rows_Are_Converted_To_Replay_Contexts;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Replay_Rows_Preserve_Instance_And_Generic_Blockers'Access,
         "generic instance body replay preserves source/instance mapping and blockers");
      Register_Routine
        (T,
         Expansion_Rows_Are_Converted_To_Replay_Contexts'Access,
         "Case 1125 expansion rows are converted into replay contexts");
   end Register_Tests;

end Test_Ada_Generic_Instance_Body_Semantic_Replay;
