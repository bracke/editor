with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Record_Variant_Aggregate_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Precision_Legality_Pass1128 is

   package AP renames Editor.Ada_Accessibility_Precision_Legality;
   use type AP.Accessibility_Legality_Status;
   use type AP.Accessibility_Level;
   use type AP.Access_Context_Kind;
   use type AP.Record_Aggregate_Legality_Status;
   use type AP.Generic_Body_Expansion_Status;
   use type AP.Accessibility_Precision_Context_Id;
   use type AP.Accessibility_Precision_Legality_Id;
   use type AP.Accessibility_Precision_Context_Kind;
   use type AP.Accessibility_Precision_Status;
   use type AP.Accessibility_Precision_Context_Info;
   use type AP.Accessibility_Precision_Legality_Info;
   use type AP.Accessibility_Precision_Context_Model;
   use type AP.Accessibility_Precision_Result_Set;
   use type AP.Accessibility_Precision_Legality_Model;
   package AL renames Editor.Ada_Accessibility_Lifetime_Legality;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Legality_Status;
   use type AL.Return_Legality_Id;
   use type AL.Return_Legality_Status;
   use type AL.Semantic_Legality_Id;
   use type AL.Semantic_Legality_Status;
   use type AL.Static_Legality_Id;
   use type AL.Static_Legality_Status;
   use type AL.Accessibility_Context_Id;
   use type AL.Accessibility_Legality_Id;
   use type AL.Access_Context_Kind;
   use type AL.Access_Target_Kind;
   use type AL.Accessibility_Level;
   use type AL.Alias_Requirement;
   use type AL.Accessibility_Legality_Status;
   use type AL.Accessibility_Context_Info;
   use type AL.Accessibility_Legality_Info;
   use type AL.Accessibility_Context_Model;
   use type AL.Accessibility_Result_Set;
   use type AL.Accessibility_Legality_Model;
   package GB renames Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
   use type GB.Instantiated_Body_Status;
   use type GB.Overload_Legality_Status;
   use type GB.Accessibility_Legality_Status;
   use type GB.Contract_Legality_Status;
   use type GB.Dataflow_Legality_Status;
   use type GB.Initialization_Legality_Status;
   use type GB.Predicate_Use_Legality_Status;
   use type GB.Representation_Integration_Status;
   use type GB.Generic_Body_Expansion_Context_Id;
   use type GB.Generic_Body_Expansion_Id;
   use type GB.Generic_Body_Expansion_Context_Kind;
   use type GB.Generic_Body_Expansion_Status;
   use type GB.Generic_Body_Expansion_Context_Info;
   use type GB.Generic_Body_Expansion_Info;
   use type GB.Generic_Body_Expansion_Context_Model;
   use type GB.Generic_Body_Expansion_Result_Set;
   use type GB.Generic_Body_Expansion_Model;
   package RA renames Editor.Ada_Record_Variant_Aggregate_Legality;
   use type RA.Semantic_Legality_Status;
   use type RA.Predicate_Use_Legality_Status;
   use type RA.Representation_Integration_Status;
   use type RA.Record_Aggregate_Context_Id;
   use type RA.Record_Aggregate_Legality_Id;
   use type RA.Record_Aggregate_Context_Kind;
   use type RA.Record_Aggregate_Legality_Status;
   use type RA.Record_Aggregate_Context_Info;
   use type RA.Record_Aggregate_Legality_Info;
   use type RA.Record_Aggregate_Context_Model;
   use type RA.Record_Aggregate_Result_Set;
   use type RA.Record_Aggregate_Legality_Model;

   use type AP.Accessibility_Precision_Status;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Accessibility_Precision_Legality_Pass1128");
   end Name;

   procedure Build_Precision_Model
     (Contexts : in out AP.Accessibility_Precision_Context_Model)
   is
      C : AP.Accessibility_Precision_Context_Info;
   begin
      C.Id := 1;
      C.Kind := AP.Accessibility_Precision_Context_Anonymous_Access_Parameter;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11281);
      C.Object_Name := To_Unbounded_String ("Formal_View");
      C.Source_Level := AL.Accessibility_Level_Master;
      C.Target_Level := AL.Accessibility_Level_Local;
      C.Anonymous_Access_Parameter := True;
      C.Base_Accessibility_Status := AL.Accessibility_Legality_Static_Compatible;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := AP.Accessibility_Precision_Context_Anonymous_Access_Parameter;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11282);
      C.Object_Name := To_Unbounded_String ("Escaping_Formal");
      C.Source_Level := AL.Accessibility_Level_Local;
      C.Target_Level := AL.Accessibility_Level_Master;
      C.Anonymous_Access_Parameter := True;
      C.Access_Parameter_Escapes := True;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := AP.Accessibility_Precision_Context_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11283);
      C.Object_Name := To_Unbounded_String ("Short_Allocator");
      C.Allocator_Context := True;
      C.Allocator_Master_Level := AL.Accessibility_Level_Local;
      C.Target_Level := AL.Accessibility_Level_Master;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := AP.Accessibility_Precision_Context_Return_Access;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11284);
      C.Object_Name := To_Unbounded_String ("Returned_Access");
      C.Return_Context := True;
      C.Designated_Object_Level := AL.Accessibility_Level_Local;
      C.Return_Master_Level := AL.Accessibility_Level_Master;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := AP.Accessibility_Precision_Context_Access_Discriminant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11285);
      C.Object_Name := To_Unbounded_String ("Disc");
      C.Access_Discriminant_Context := True;
      C.Designated_Object_Level := AL.Accessibility_Level_Local;
      C.Target_Level := AL.Accessibility_Level_Master;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := AP.Accessibility_Precision_Context_Generic_Actual;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11286);
      C.Object_Name := To_Unbounded_String ("Actual_Access");
      C.Generic_Actual_Context := True;
      C.Source_Level := AL.Accessibility_Level_Local;
      C.Target_Level := AL.Accessibility_Level_Master;
      C.Generic_Status := GB.Generic_Body_Expansion_Legal_Accessibility;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := AP.Accessibility_Precision_Context_Record_Aggregate_Discriminant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11287);
      C.Object_Name := To_Unbounded_String ("Aggregate_Disc");
      C.Aggregate_Discriminant_Context := True;
      C.Designated_Object_Level := AL.Accessibility_Level_Master;
      C.Target_Level := AL.Accessibility_Level_Local;
      C.Record_Aggregate_Status := RA.Record_Aggregate_Legality_Legal_Discriminant_Constraint;
      AP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := AP.Accessibility_Precision_Context_Record_Aggregate_Discriminant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11288);
      C.Object_Name := To_Unbounded_String ("Bad_Aggregate");
      C.Aggregate_Discriminant_Context := True;
      C.Record_Aggregate_Status := RA.Record_Aggregate_Legality_Missing_Discriminant;
      AP.Add_Context (Contexts, C);
   end Build_Precision_Model;

   procedure Classifies_Nested_Accessibility_Precision
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AP.Accessibility_Precision_Context_Model;
   begin
      Build_Precision_Model (Contexts);

      declare
         Model : constant AP.Accessibility_Precision_Legality_Model := AP.Build (Contexts);
      begin
         Assert (AP.Legality_Count (Model) = 8,
                 "each accessibility precision context should produce one legality row");
         Assert (AP.Legal_Count (Model) = 2,
                 "static anonymous parameter and aggregate discriminant should be legal");
         Assert (AP.Error_Count (Model) = 6,
                 "six contexts should expose precise accessibility errors");
         Assert (AP.Anonymous_Access_Error_Count (Model) = 1,
                 "escaping anonymous access parameter should be counted");
         Assert (AP.Allocator_Error_Count (Model) = 1,
                 "short allocator master should be counted");
         Assert (AP.Return_Error_Count (Model) = 1,
                 "short-lived returned access should be counted");
         Assert (AP.Discriminant_Error_Count (Model) = 1,
                 "short access discriminant should be counted");
         Assert (AP.Generic_Error_Count (Model) = 1,
                 "generic actual lifetime mismatch should be counted");
         Assert (AP.Linked_Error_Count (Model) = 1,
                 "record aggregate blocker should remain linked");
         Assert (AP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11281)).Status =
                 AP.Accessibility_Precision_Legal_Static_Level,
                 "compatible anonymous access levels should remain legal");
         Assert (AP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11283)).Status =
                 AP.Accessibility_Precision_Allocator_Master_Too_Short,
                 "allocator master lifetime should be checked precisely");
         Assert (AP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11286)).Status =
                 AP.Accessibility_Precision_Generic_Actual_Too_Short_Lived,
                 "generic actual accessibility should be checked after substitution");
         Assert (AP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11288)).Status =
                 AP.Accessibility_Precision_Linked_Record_Aggregate_Error,
                 "aggregate discriminant errors should feed accessibility precision");
      end;
   end Classifies_Nested_Accessibility_Precision;

   procedure Lookups_And_Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty    : AP.Accessibility_Precision_Context_Model;
      Contexts : AP.Accessibility_Precision_Context_Model;
   begin
      declare
         Model : constant AP.Accessibility_Precision_Legality_Model := AP.Build (Empty);
      begin
         Assert (AP.Legality_Count (Model) = 0,
                 "empty accessibility precision input should produce no rows");
         Assert (not AP.Has_Legality
                   (AP.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (1))),
                 "missing node lookup should return no legality row");
      end;

      Build_Precision_Model (Contexts);
      declare
         Model : constant AP.Accessibility_Precision_Legality_Model := AP.Build (Contexts);
         Rows  : constant AP.Accessibility_Precision_Result_Set :=
           AP.Rows_For_Object (Model, "Actual_Access");
      begin
         Assert (AP.Result_Count (Rows) = 1,
                 "object-name lookup should preserve accessibility precision identity");
         Assert (AP.Result_At (Rows, 1).Status =
                 AP.Accessibility_Precision_Generic_Actual_Too_Short_Lived,
                 "object-name lookup should return the expected generic actual row");
      end;
   end Lookups_And_Empty_Inputs_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Classifies_Nested_Accessibility_Precision'Access,
         "Pass1128 deepens accessibility/lifetime precision across access contexts");
      Register_Routine
        (T, Lookups_And_Empty_Inputs_Are_Deterministic'Access,
         "Pass1128 keeps accessibility precision lookups deterministic");
   end Register_Tests;

end Test_Ada_Accessibility_Precision_Legality_Pass1128;
