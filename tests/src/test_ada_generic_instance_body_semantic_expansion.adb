with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Instance_Body_Semantic_Expansion is

   package AA renames Editor.Ada_Accessibility_Lifetime_Legality;
   use type AA.Assignment_Legality_Id;
   use type AA.Assignment_Legality_Status;
   use type AA.Return_Legality_Id;
   use type AA.Return_Legality_Status;
   use type AA.Semantic_Legality_Id;
   use type AA.Semantic_Legality_Status;
   use type AA.Static_Legality_Id;
   use type AA.Static_Legality_Status;
   use type AA.Accessibility_Context_Id;
   use type AA.Accessibility_Legality_Id;
   use type AA.Access_Context_Kind;
   use type AA.Access_Target_Kind;
   use type AA.Accessibility_Level;
   use type AA.Alias_Requirement;
   use type AA.Accessibility_Legality_Status;
   use type AA.Accessibility_Context_Info;
   use type AA.Accessibility_Legality_Info;
   use type AA.Accessibility_Context_Model;
   use type AA.Accessibility_Result_Set;
   use type AA.Accessibility_Legality_Model;
   package CA renames Editor.Ada_Contract_Aspect_Legality;
   use type CA.Assignment_Legality_Status;
   use type CA.Return_Legality_Status;
   use type CA.Static_Legality_Status;
   use type CA.Accessibility_Legality_Status;
   use type CA.Overload_Legality_Status;
   use type CA.Cross_Unit_Semantic_Status;
   use type CA.Contract_Context_Id;
   use type CA.Contract_Legality_Id;
   use type CA.Contract_Context_Kind;
   use type CA.Contract_Subject_Kind;
   use type CA.Boolean_Expression_State;
   use type CA.Aspect_Placement;
   use type CA.Flow_Contract_State;
   use type CA.Contract_Legality_Status;
   use type CA.Contract_Context_Info;
   use type CA.Contract_Legality_Info;
   use type CA.Contract_Context_Model;
   use type CA.Contract_Result_Set;
   use type CA.Contract_Legality_Model;
   package DA renames Editor.Ada_Dataflow_Global_Depends_Legality;
   use type DA.Contract_Legality_Status;
   use type DA.Flow_Contract_State;
   use type DA.Initialization_Legality_Status;
   use type DA.Object_State;
   use type DA.Dataflow_Context_Id;
   use type DA.Dataflow_Legality_Id;
   use type DA.Dataflow_Context_Kind;
   use type DA.Dataflow_Effect_Kind;
   use type DA.Global_Mode;
   use type DA.Dependency_State;
   use type DA.Dataflow_Legality_Status;
   use type DA.Dataflow_Context_Info;
   use type DA.Dataflow_Legality_Info;
   use type DA.Dataflow_Context_Model;
   use type DA.Dataflow_Result_Set;
   use type DA.Dataflow_Legality_Model;
   package IA renames Editor.Ada_Definite_Initialization_Flow_Legality;
   use type IA.Assignment_Legality_Id;
   use type IA.Assignment_Legality_Status;
   use type IA.Return_Legality_Id;
   use type IA.Return_Legality_Status;
   use type IA.Control_Flow_Legality_Id;
   use type IA.Control_Flow_Legality_Status;
   use type IA.Exception_Finalization_Legality_Id;
   use type IA.Exception_Finalization_Legality_Status;
   use type IA.Integrated_Closure_Id;
   use type IA.Integrated_Closure_Status;
   use type IA.Initialization_Context_Id;
   use type IA.Initialization_Legality_Id;
   use type IA.Initialization_Context_Kind;
   use type IA.Object_State;
   use type IA.Flow_State;
   use type IA.Initialization_Legality_Status;
   use type IA.Initialization_Context_Info;
   use type IA.Initialization_Legality_Info;
   use type IA.Initialization_Context_Model;
   use type IA.Initialization_Legality_Model;
   package GE renames Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
   use type GE.Instantiated_Body_Status;
   use type GE.Overload_Legality_Status;
   use type GE.Accessibility_Legality_Status;
   use type GE.Contract_Legality_Status;
   use type GE.Dataflow_Legality_Status;
   use type GE.Initialization_Legality_Status;
   use type GE.Predicate_Use_Legality_Status;
   use type GE.Representation_Integration_Status;
   use type GE.Generic_Body_Expansion_Context_Id;
   use type GE.Generic_Body_Expansion_Id;
   use type GE.Generic_Body_Expansion_Context_Kind;
   use type GE.Generic_Body_Expansion_Status;
   use type GE.Generic_Body_Expansion_Context_Info;
   use type GE.Generic_Body_Expansion_Info;
   use type GE.Generic_Body_Expansion_Context_Model;
   use type GE.Generic_Body_Expansion_Result_Set;
   use type GE.Generic_Body_Expansion_Model;
   package GA renames Editor.Ada_Generic_Instantiated_Body_Analysis;
   use type GA.Instantiated_Body_Status;
   use type GA.Instantiated_Body_Substitution_Id;
   use type GA.Instantiated_Body_Substitution_Info;
   use type GA.Instantiated_Body_Model;
   package OA renames Editor.Ada_Overload_Resolution_Legality;
   use type OA.Overload_Context_Id;
   use type OA.Overload_Legality_Id;
   use type OA.Overload_Context_Kind;
   use type OA.Overload_Legality_Status;
   use type OA.Overload_Context_Info;
   use type OA.Overload_Legality_Info;
   use type OA.Overload_Context_Model;
   use type OA.Overload_Legality_Result_Set;
   use type OA.Overload_Legality_Model;
   package PA renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   use type PA.Predicate_Policy;
   use type PA.Static_Legality_Status;
   use type PA.Assignment_Legality_Status;
   use type PA.Return_Legality_Status;
   use type PA.Semantic_Legality_Status;
   use type PA.Overload_Legality_Status;
   use type PA.Instance_Legality_Status;
   use type PA.Predicate_Use_Context_Id;
   use type PA.Predicate_Use_Legality_Id;
   use type PA.Predicate_Use_Context_Kind;
   use type PA.Invariant_Policy;
   use type PA.Use_Site_Check_Point;
   use type PA.Predicate_Use_Legality_Status;
   use type PA.Predicate_Use_Context_Info;
   use type PA.Predicate_Use_Legality_Info;
   use type PA.Predicate_Use_Context_Model;
   use type PA.Predicate_Use_Result_Set;
   use type PA.Predicate_Use_Legality_Model;
   package RA renames Editor.Ada_Representation_Layout_Stream_Integration_Legality;
   use type RA.Representation_Status;
   use type RA.Exact_Layout_Status;
   use type RA.Stream_Status;
   use type RA.Generic_Instance_Status;
   use type RA.Accessibility_Status;
   use type RA.Staticness_Status;
   use type RA.Completion_Status;
   use type RA.Contract_Status;
   use type RA.Exception_Status;
   use type RA.Representation_Integration_Context_Id;
   use type RA.Representation_Integration_Id;
   use type RA.Representation_Integration_Context_Kind;
   use type RA.Layout_State;
   use type RA.Stream_State;
   use type RA.Representation_Integration_Status;
   use type RA.Representation_Integration_Context_Info;
   use type RA.Representation_Integration_Info;
   use type RA.Representation_Integration_Context_Model;
   use type RA.Representation_Integration_Result_Set;
   use type RA.Representation_Integration_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Generic_Instance_Body_Semantic_Expansion");
   end Name;

   function Expansion_Model return GE.Generic_Body_Expansion_Model is
      Contexts : GE.Generic_Body_Expansion_Context_Model;
      C        : GE.Generic_Body_Expansion_Context_Info;
   begin
      C.Id := 1;
      C.Kind := GE.Generic_Body_Expansion_Formal_Object;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112501);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (1);
      C.Formal_Name := To_Unbounded_String ("Element");
      C.Actual_Text := To_Unbounded_String ("Integer");
      C.Body_Status := GA.Instantiated_Body_Substituted;
      C.Overload_Status := OA.Overload_Legality_Legal_Exact;
      C.Source_Fingerprint := 501;
      GE.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := GE.Generic_Body_Expansion_Body_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112502);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (2);
      C.Formal_Name := To_Unbounded_String ("Compare");
      C.Actual_Text := To_Unbounded_String ("Less_Than");
      C.Body_Status := GA.Instantiated_Body_Substituted;
      C.Overload_Status := OA.Overload_Legality_Ambiguous_After_Preference;
      C.Source_Fingerprint := 502;
      GE.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := GE.Generic_Body_Expansion_Body_Statement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112503);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (3);
      C.Formal_Name := To_Unbounded_String ("State");
      C.Actual_Text := To_Unbounded_String ("Local_State");
      C.Body_Status := GA.Instantiated_Body_Substituted;
      C.Dataflow_Status := DA.Dataflow_Legality_Write_Not_In_Global;
      C.Initialization_Status := IA.Initialization_Legality_Read_Before_Write;
      C.Source_Fingerprint := 503;
      GE.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := GE.Generic_Body_Expansion_Formal_Type;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112504);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (4);
      C.Formal_Name := To_Unbounded_String ("Private_T");
      C.Actual_Text := To_Unbounded_String ("Hidden.T");
      C.Body_Status := GA.Instantiated_Body_Private_View_Barrier;
      C.Source_Fingerprint := 504;
      GE.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := GE.Generic_Body_Expansion_Default_Actual;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112505);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (5);
      C.Formal_Name := To_Unbounded_String ("Default_Item");
      C.Actual_Text := To_Unbounded_String ("Default_Item'First");
      C.Is_Default_Substitution := True;
      C.Body_Status := GA.Instantiated_Body_Default_Substituted;
      C.Predicate_Status := PA.Predicate_Use_Legality_Legal_Static_Predicate;
      C.Contract_Status := CA.Contract_Legality_Legal_Precondition;
      C.Source_Fingerprint := 505;
      GE.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := GE.Generic_Body_Expansion_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112506);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (6);
      C.Formal_Name := To_Unbounded_String ("Rep_Target");
      C.Actual_Text := To_Unbounded_String ("Actual_Record");
      C.Body_Status := GA.Instantiated_Body_Substituted;
      C.Representation_Status := RA.Representation_Integration_After_Freezing;
      C.Source_Fingerprint := 506;
      GE.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := GE.Generic_Body_Expansion_Body_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112507);
      C.Substitution := GA.Instantiated_Body_Substitution_Id (7);
      C.Formal_Name := To_Unbounded_String ("Access_Formal");
      C.Actual_Text := To_Unbounded_String ("Local_Access");
      C.Body_Status := GA.Instantiated_Body_Substituted;
      C.Accessibility_Status := AA.Accessibility_Legality_Level_Too_Deep;
      C.Source_Fingerprint := 507;
      GE.Add_Context (Contexts, C);

      return GE.Build (Contexts);
   end Expansion_Model;

   procedure Actual_Formal_Substitutions_Feed_Wide_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant GE.Generic_Body_Expansion_Model := Expansion_Model;
      Legal : constant GE.Generic_Body_Expansion_Info :=
        GE.First_For_Substitution (Model, GA.Instantiated_Body_Substitution_Id (1));
      Overload : constant GE.Generic_Body_Expansion_Info :=
        GE.First_For_Substitution (Model, GA.Instantiated_Body_Substitution_Id (2));
      Multiple : constant GE.Generic_Body_Expansion_Info :=
        GE.First_For_Substitution (Model, GA.Instantiated_Body_Substitution_Id (3));
      View : constant GE.Generic_Body_Expansion_Info :=
        GE.First_For_Substitution (Model, GA.Instantiated_Body_Substitution_Id (4));
      Defaulted : constant GE.Generic_Body_Expansion_Info :=
        GE.First_For_Substitution (Model, GA.Instantiated_Body_Substitution_Id (5));
   begin
      Assert (GE.Row_Count (Model) = 7, "all generic body expansion contexts classified");
      Assert (Legal.Status = GE.Generic_Body_Expansion_Legal_Overload,
              "legal substituted actual may carry resolved overload legality");
      Assert (Overload.Status = GE.Generic_Body_Expansion_Overload_Error,
              "overload failures inside instantiated bodies are blockers");
      Assert (Multiple.Status = GE.Generic_Body_Expansion_Multiple_Semantic_Blockers,
              "combined dataflow and initialization failures are preserved together");
      Assert (View.Status = GE.Generic_Body_Expansion_Private_View_Barrier,
              "private view barriers survive actual/formal body expansion");
      Assert (Defaulted.Status = GE.Generic_Body_Expansion_Legal_Predicate_Invariant,
              "default substitutions keep predicate/invariant use-site legality");
      Assert (GE.Legal_Count (Model) = 2, "legal expanded body rows are counted");
      Assert (GE.Error_Count (Model) = 5, "non-legal expanded body rows are counted");
      Assert (GE.View_Barrier_Count (Model) = 1, "view barriers are counted separately");
      Assert (GE.Overload_Error_Count (Model) = 1, "overload blockers are counted");
      Assert (GE.Accessibility_Error_Count (Model) = 1, "accessibility blockers are counted");
      Assert (GE.Representation_Error_Count (Model) = 1, "representation blockers are counted");
      Assert (GE.Multiple_Blocker_Count (Model) = 1, "multi-blocker rows are counted");
      Assert (GE.Fingerprint (Model) /= 0, "model fingerprint is deterministic");
   end Actual_Formal_Substitutions_Feed_Wide_Legality;

   procedure Lookups_Are_Bounded_And_Normalized
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant GE.Generic_Body_Expansion_Model := Expansion_Model;
      Formal_Rows : constant GE.Generic_Body_Expansion_Result_Set :=
        GE.Rows_For_Formal (Model, "element");
      Rep_Rows : constant GE.Generic_Body_Expansion_Result_Set :=
        GE.Rows_For_Kind (Model, GE.Generic_Body_Expansion_Representation_Item);
      Multiple_Rows : constant GE.Generic_Body_Expansion_Result_Set :=
        GE.Rows_For_Status (Model, GE.Generic_Body_Expansion_Multiple_Semantic_Blockers);
   begin
      Assert (GE.Result_Count (Formal_Rows) = 1,
              "formal lookup is normalized and deterministic");
      Assert (GE.Result_At (Formal_Rows, 1).Status = GE.Generic_Body_Expansion_Legal_Overload,
              "formal lookup preserves expanded semantic status");
      Assert (GE.Result_Count (Rep_Rows) = 1,
              "representation rows are searchable by generic body expansion kind");
      Assert (GE.Result_At (Rep_Rows, 1).Status = GE.Generic_Body_Expansion_Representation_Error,
              "representation failure survives expansion lookup");
      Assert (GE.Result_Count (Multiple_Rows) = 1,
              "multiple semantic blockers are searchable by status");
      Assert (GE.Count_Status (Model, GE.Generic_Body_Expansion_Accessibility_Error) = 1,
              "status counters remain bounded");
   end Lookups_Are_Bounded_And_Normalized;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Actual_Formal_Substitutions_Feed_Wide_Legality'Access,
         "Actual/formal generic body substitutions feed widened legality layers");
      Register_Routine
        (T, Lookups_Are_Bounded_And_Normalized'Access,
         "Generic instance body expansion lookups remain deterministic and bounded");
   end Register_Tests;

end Test_Ada_Generic_Instance_Body_Semantic_Expansion;
