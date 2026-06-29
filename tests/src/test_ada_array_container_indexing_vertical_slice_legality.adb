with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Array_Container_Indexing_Vertical_Slice_Legality is

   package AI renames Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality;
   use type AI.Indexing_Id;
   use type AI.Result_Id;
   use type AI.Indexing_Kind;
   use type AI.Composite_Kind;
   use type AI.Index_Type_Kind;
   use type AI.Container_Profile_Kind;
   use type AI.Legality_Status;
   use type AI.Indexing_Info;
   use type AI.Result_Info;
   use type AI.Indexing_Model;
   use type AI.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Array_Container_Indexing_Vertical_Slice_Legality");
   end Name;

   procedure Add_Indexing
     (Model : in out AI.Indexing_Model;
      Id    : Natural;
      Kind  : AI.Indexing_Kind;
      Text  : String;
      AST : Boolean := True;
      Context : Boolean := True;
      Composite : AI.Composite_Kind := AI.Composite_Array;
      Index_Type : AI.Index_Type_Kind := AI.Index_Type_Discrete;
      Profile : AI.Container_Profile_Kind := AI.Container_Profile_None;
      Dimensions : Natural := 1;
      Supplied_Indexes : Natural := 1;
      Index_Range_OK : Boolean := True;
      In_Bounds : Boolean := True;
      Runtime_Bounds_Check : Boolean := False;
      Is_Constrained : Boolean := True;
      Has_Constraint : Boolean := True;
      Constraint_Conflict : Boolean := False;
      Components : Natural := 1;
      Required_Components : Natural := 1;
      Duplicate_Component : Boolean := False;
      Component_Type_OK : Boolean := True;
      Named_Positional_Mix : Boolean := False;
      Choice_Overlap : Boolean := False;
      Slice_Range_OK : Boolean := True;
      Has_Gen_Indexing_Profile : Boolean := True;
      Gen_Indexing_Profile_OK : Boolean := True;
      Has_Container_Profile : Boolean := True;
      Container_Element_OK : Boolean := True;
      Iterator_Element_OK : Boolean := True;
      Parallel_Shared_OK : Boolean := True;
      Has_Delta_Target : Boolean := True;
      Delta_Component_OK : Boolean := True;
      Private_View : Boolean := True;
      Limited_View : Boolean := True;
      Subtype_Range_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Initialization_OK : Boolean := True;
      Overload_OK : Boolean := True;
      Source_FP : Natural := 131200;
      AST_FP : Natural := 231200;
      Type_FP : Natural := 331200;
      Profile_FP : Natural := 431200;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0)
   is
      I : AI.Indexing_Info;
   begin
      I.Id := AI.Indexing_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131200 + Id);
      I.Kind := Kind;
      I.Source_Name := To_Unbounded_String (Text);
      I.Has_AST_Coverage := AST;
      I.Has_Context := Context;
      I.Composite := Composite;
      I.Index_Type := Index_Type;
      I.Container_Profile := Profile;
      I.Dimension_Count := Dimensions;
      I.Supplied_Index_Count := Supplied_Indexes;
      I.Index_Range_Compatible := Index_Range_OK;
      I.Index_Value_In_Bounds := In_Bounds;
      I.Runtime_Bounds_Check_Required := Runtime_Bounds_Check;
      I.Is_Constrained_Array := Is_Constrained;
      I.Has_Index_Constraint := Has_Constraint;
      I.Constraint_Conflicts_With_Type := Constraint_Conflict;
      I.Aggregate_Component_Count := Components;
      I.Required_Component_Count := Required_Components;
      I.Has_Duplicate_Component := Duplicate_Component;
      I.Component_Type_Compatible := Component_Type_OK;
      I.Mixes_Named_And_Positional := Named_Positional_Mix;
      I.Aggregate_Choices_Overlap := Choice_Overlap;
      I.Slice_Range_Compatible := Slice_Range_OK;
      I.Has_Generalized_Indexing_Profile := Has_Gen_Indexing_Profile;
      I.Generalized_Indexing_Profile_Compatible := Gen_Indexing_Profile_OK;
      I.Has_Container_Aggregate_Profile := Has_Container_Profile;
      I.Container_Element_Type_Compatible := Container_Element_OK;
      I.Iterator_Element_Type_Compatible := Iterator_Element_OK;
      I.Parallel_Iterator_Shared_State_Legal := Parallel_Shared_OK;
      I.Has_Delta_Update_Target := Has_Delta_Target;
      I.Delta_Update_Component_Compatible := Delta_Component_OK;
      I.Private_View_Available := Private_View;
      I.Limited_View_Available := Limited_View;
      I.Subtype_Range_Legal := Subtype_Range_OK;
      I.Predicate_Legal := Predicate_OK;
      I.Accessibility_Legal := Accessibility_OK;
      I.Initialization_Legal := Initialization_OK;
      I.Overload_Legal := Overload_OK;
      I.Source_Fingerprint := Source_FP + Id;
      I.AST_Fingerprint := AST_FP + Id;
      I.Type_Fingerprint := Type_FP + Id;
      I.Profile_Fingerprint := Profile_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      I.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      I.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      AI.Add_Indexing (Model, I);
   end Add_Indexing;

   procedure Accepts_Source_Shaped_Array_And_Container_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : AI.Indexing_Model;
      Results : AI.Result_Model;
   begin
      Add_Indexing (Model, 1, AI.Index_Array_Type_Declaration,
                    "type Vector is array (Positive range <>) of Integer",
                    Composite => AI.Composite_Unconstrained_Array,
                    Has_Constraint => True);
      Add_Indexing (Model, 2, AI.Index_Array_Aggregate,
                    "Vector'(1 => 10, 2 => 20)",
                    Composite => AI.Composite_Array,
                    Components => 2,
                    Required_Components => 2);
      Add_Indexing (Model, 3, AI.Index_Array_Slice,
                    "V (1 .. 3)",
                    Composite => AI.Composite_Constrained_Array,
                    Slice_Range_OK => True);
      Add_Indexing (Model, 4, AI.Index_Generalized_Indexing,
                    "Map (Key)",
                    Composite => AI.Composite_Container,
                    Profile => AI.Container_Profile_Constant_Indexing);
      Add_Indexing (Model, 5, AI.Index_Container_Aggregate,
                    "Map'(Empty with ""A"" => 1)",
                    Composite => AI.Composite_Container,
                    Profile => AI.Container_Profile_Aggregate_Add_Named,
                    Has_Container_Profile => True,
                    Container_Element_OK => True);
      Add_Indexing (Model, 6, AI.Index_Indexed_Component,
                    "V (I)",
                    Runtime_Bounds_Check => True,
                    In_Bounds => False);

      Results := AI.Build (Model);

      Assert (AI.Result_Count (Results) = 6, "expected six array/container rows");
      Assert (AI.Count_Status (Results, AI.Legality_Legal) = 5,
              "source-shaped array/container rows should be legal");
      Assert (AI.Count_Status (Results, AI.Legality_Legal_With_Runtime_Check) = 1,
              "runtime bounds check should remain legal-with-check");
      Assert (AI.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Source_Shaped_Array_And_Container_Cases;

   procedure Rejects_Index_Constraint_And_Aggregate_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : AI.Indexing_Model;
      Results : AI.Result_Model;
   begin
      Add_Indexing (Model, 1, AI.Index_Index_Constraint,
                    "A (Float range 1.0 .. 2.0)",
                    Index_Type => AI.Index_Type_Non_Discrete);
      Add_Indexing (Model, 2, AI.Index_Indexed_Component,
                    "Matrix (I)",
                    Composite => AI.Composite_Multidimensional_Array,
                    Dimensions => 2,
                    Supplied_Indexes => 1);
      Add_Indexing (Model, 3, AI.Index_Indexed_Component,
                    "V (0)",
                    In_Bounds => False,
                    Runtime_Bounds_Check => False);
      Add_Indexing (Model, 4, AI.Index_Array_Object_Declaration,
                    "Obj : Unconstrained_Array",
                    Composite => AI.Composite_Unconstrained_Array,
                    Has_Constraint => False);
      Add_Indexing (Model, 5, AI.Index_Array_Aggregate,
                    "Vector'(1 => 10)",
                    Components => 1,
                    Required_Components => 2);
      Add_Indexing (Model, 6, AI.Index_Array_Aggregate,
                    "Vector'(1 => 10, 1 => 20)",
                    Duplicate_Component => True);

      Results := AI.Build (Model);

      Assert (AI.Count_Status (Results, AI.Legality_Index_Type_Not_Discrete) = 1,
              "non-discrete index subtype should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Index_Count_Mismatch) = 1,
              "dimension/index-count mismatch should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Index_Out_Of_Bounds) = 1,
              "static out-of-bounds index should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Unconstrained_Array_Missing_Constraint) = 1,
              "unconstrained array object without constraint should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Aggregate_Component_Missing) = 1,
              "missing aggregate component should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Aggregate_Component_Duplicate) = 1,
              "duplicate aggregate component should be rejected");
   end Rejects_Index_Constraint_And_Aggregate_Errors;

   procedure Rejects_Container_Generalized_Indexing_And_Update_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : AI.Indexing_Model;
      Results : AI.Result_Model;
   begin
      Add_Indexing (Model, 1, AI.Index_Generalized_Indexing,
                    "Container (Key) without Constant_Indexing",
                    Composite => AI.Composite_Container,
                    Has_Gen_Indexing_Profile => False);
      Add_Indexing (Model, 2, AI.Index_Generalized_Indexing,
                    "Container (Key) with wrong indexing profile",
                    Composite => AI.Composite_Container,
                    Gen_Indexing_Profile_OK => False);
      Add_Indexing (Model, 3, AI.Index_Container_Aggregate,
                    "Container aggregate without Add_Named/Add_Unnamed",
                    Composite => AI.Composite_Container,
                    Profile => AI.Container_Profile_None,
                    Has_Container_Profile => False);
      Add_Indexing (Model, 4, AI.Index_Container_Aggregate,
                    "Container aggregate with wrong element type",
                    Composite => AI.Composite_Container,
                    Profile => AI.Container_Profile_Aggregate_Add_Unnamed,
                    Container_Element_OK => False);
      Add_Indexing (Model, 5, AI.Index_Parallel_Iterator,
                    "parallel for E of Container loop write Shared end loop",
                    Composite => AI.Composite_Container,
                    Iterator_Element_OK => True,
                    Parallel_Shared_OK => False);
      Add_Indexing (Model, 6, AI.Index_Delta_Aggregate_Update,
                    "A with delta Missing => 1",
                    Has_Delta_Target => False);
      Add_Indexing (Model, 7, AI.Index_Delta_Aggregate_Update,
                    "A with delta 1 => Wrong_Type",
                    Delta_Component_OK => False);

      Results := AI.Build (Model);

      Assert (AI.Count_Status (Results, AI.Legality_Generalized_Indexing_Profile_Missing) = 1,
              "missing generalized indexing profile should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Generalized_Indexing_Profile_Mismatch) = 1,
              "wrong generalized indexing profile should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Container_Aggregate_Profile_Missing) = 1,
              "missing container aggregate profile should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Container_Element_Type_Mismatch) = 1,
              "container element mismatch should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Parallel_Iterator_Shared_State_Blocked) = 1,
              "unsafe parallel iterator shared state should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Delta_Update_Target_Missing) = 1,
              "missing delta-update target should be rejected");
      Assert (AI.Count_Status (Results, AI.Legality_Delta_Update_Component_Mismatch) = 1,
              "delta-update component mismatch should be rejected");
   end Rejects_Container_Generalized_Indexing_And_Update_Errors;

   procedure Preserves_Cross_Consumer_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : AI.Indexing_Model;
      Results : AI.Result_Model;
   begin
      Add_Indexing (Model, 1, AI.Index_Array_Aggregate,
                    "private array aggregate before full view",
                    Composite => AI.Composite_Private_Array,
                    Private_View => False);
      Add_Indexing (Model, 2, AI.Index_Array_Aggregate,
                    "limited view array aggregate",
                    Composite => AI.Composite_Limited_View,
                    Limited_View => False);
      Add_Indexing (Model, 3, AI.Index_Array_Aggregate,
                    "aggregate blocked by subtype range",
                    Subtype_Range_OK => False);
      Add_Indexing (Model, 4, AI.Index_Array_Aggregate,
                    "aggregate blocked by predicate",
                    Predicate_OK => False);
      Add_Indexing (Model, 5, AI.Index_Array_Aggregate,
                    "aggregate blocked by initialization",
                    Initialization_OK => False);
      Add_Indexing (Model, 6, AI.Index_Generalized_Indexing,
                    "generalized indexing overload unresolved",
                    Composite => AI.Composite_Container,
                    Overload_OK => False);
      Add_Indexing (Model, 7, AI.Index_Array_Aggregate,
                    "stale type fingerprint",
                    Expected_Type_FP => 999999);

      Results := AI.Build (Model);

      Assert (AI.Count_Status (Results, AI.Legality_Private_View_Barrier) = 1,
              "private view barrier should be preserved");
      Assert
        (AI.Count_Status (Results, AI.Legality_Limited_View_Barrier) = 1,
         "limited view barrier should be preserved");
      Assert (AI.Count_Status (Results, AI.Legality_Subtype_Range_Blocked) = 1,
              "subtype/range blocker should be preserved");
      Assert (AI.Count_Status (Results, AI.Legality_Predicate_Blocked) = 1,
              "predicate blocker should be preserved");
      Assert (AI.Count_Status (Results, AI.Legality_Initialization_Blocked) = 1,
              "initialization blocker should be preserved");
      Assert (AI.Count_Status (Results, AI.Legality_Overload_Blocked) = 1,
              "overload blocker should be preserved");
      Assert (AI.Count_Status (Results, AI.Legality_Type_Fingerprint_Mismatch) = 1,
              "type fingerprint mismatch should be preserved");
   end Preserves_Cross_Consumer_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Array_And_Container_Cases'Access,
         "accepts source-shaped array/container/indexing cases");
      Register_Routine
        (T, Rejects_Index_Constraint_And_Aggregate_Errors'Access,
         "rejects index constraint and aggregate errors");
      Register_Routine
        (T, Rejects_Container_Generalized_Indexing_And_Update_Errors'Access,
         "rejects container/generalized indexing/update errors");
      Register_Routine
        (T, Preserves_Cross_Consumer_And_Fingerprint_Blockers'Access,
         "preserves cross-consumer and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Array_Container_Indexing_Vertical_Slice_Legality;
