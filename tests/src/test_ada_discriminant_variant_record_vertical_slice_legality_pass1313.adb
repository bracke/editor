with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Discriminant_Variant_Record_Vertical_Slice_Legality_Pass1313 is

   package DV renames Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality;
   use type DV.Record_Id;
   use type DV.Result_Id;
   use type DV.Record_Construct_Kind;
   use type DV.Record_View_Kind;
   use type DV.Discriminant_Kind;
   use type DV.Variant_Coverage_Kind;
   use type DV.Legality_Status;
   use type DV.Record_Info;
   use type DV.Result_Info;
   use type DV.Record_Model;
   use type DV.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Discriminant_Variant_Record_Vertical_Slice_Legality_Pass1313");
   end Name;

   procedure Add_Record
     (Model : in out DV.Record_Model;
      Id    : Natural;
      Kind  : DV.Record_Construct_Kind;
      Text  : String;
      AST : Boolean := True;
      Context : Boolean := True;
      View : DV.Record_View_Kind := DV.View_Full_Record;
      Discriminant : DV.Discriminant_Kind := DV.Discriminant_None;
      Coverage : DV.Variant_Coverage_Kind := DV.Coverage_None;
      Required_Discriminants : Natural := 0;
      Supplied_Discriminants : Natural := 0;
      Discriminant_Type_OK : Boolean := True;
      Discriminant_Default_OK : Boolean := True;
      Discriminant_Constraint_OK : Boolean := True;
      Discriminant_Dependent_Component_OK : Boolean := True;
      Variant_Has_Governing_Discriminant : Boolean := True;
      Selected_Variant_Active : Boolean := True;
      Runtime_Variant_Check : Boolean := False;
      Components : Natural := 0;
      Required_Components : Natural := 0;
      Duplicate_Component : Boolean := False;
      Component_Type_OK : Boolean := True;
      Named_Positional_Mix : Boolean := False;
      Has_Delta_Target : Boolean := True;
      Delta_Component_OK : Boolean := True;
      Private_View : Boolean := True;
      Limited_View : Boolean := True;
      Tagged_Extension_OK : Boolean := True;
      Representation_Layout_OK : Boolean := True;
      Controlled_Finalization_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Initialization_OK : Boolean := True;
      Subtype_Range_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Overload_OK : Boolean := True;
      Source_FP : Natural := 131300;
      AST_FP : Natural := 231300;
      Type_FP : Natural := 331300;
      Layout_FP : Natural := 431300;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Layout_FP : Natural := 0)
   is
      I : DV.Record_Info;
   begin
      I.Id := DV.Record_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131300 + Id);
      I.Kind := Kind;
      I.Source_Name := To_Unbounded_String (Text);
      I.Has_AST_Coverage := AST;
      I.Has_Context := Context;
      I.View := View;
      I.Discriminant := Discriminant;
      I.Coverage := Coverage;
      I.Required_Discriminant_Count := Required_Discriminants;
      I.Supplied_Discriminant_Count := Supplied_Discriminants;
      I.Discriminant_Type_Compatible := Discriminant_Type_OK;
      I.Discriminant_Default_Compatible := Discriminant_Default_OK;
      I.Discriminant_Constraint_Compatible := Discriminant_Constraint_OK;
      I.Discriminant_Dependent_Component_Legal := Discriminant_Dependent_Component_OK;
      I.Variant_Has_Governing_Discriminant := Variant_Has_Governing_Discriminant;
      I.Selected_Variant_Active := Selected_Variant_Active;
      I.Runtime_Variant_Check_Required := Runtime_Variant_Check;
      I.Aggregate_Component_Count := Components;
      I.Required_Component_Count := Required_Components;
      I.Has_Duplicate_Component := Duplicate_Component;
      I.Component_Type_Compatible := Component_Type_OK;
      I.Mixes_Named_And_Positional := Named_Positional_Mix;
      I.Has_Delta_Update_Target := Has_Delta_Target;
      I.Delta_Update_Component_Compatible := Delta_Component_OK;
      I.Private_View_Available := Private_View;
      I.Limited_View_Available := Limited_View;
      I.Tagged_Extension_Legal := Tagged_Extension_OK;
      I.Representation_Layout_Legal := Representation_Layout_OK;
      I.Controlled_Finalization_Legal := Controlled_Finalization_OK;
      I.Accessibility_Legal := Accessibility_OK;
      I.Initialization_Legal := Initialization_OK;
      I.Subtype_Range_Legal := Subtype_Range_OK;
      I.Predicate_Legal := Predicate_OK;
      I.Overload_Legal := Overload_OK;
      I.Source_Fingerprint := Source_FP + Id;
      I.AST_Fingerprint := AST_FP + Id;
      I.Type_Fingerprint := Type_FP + Id;
      I.Layout_Fingerprint := Layout_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      I.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      I.Expected_Layout_Fingerprint :=
        (if Expected_Layout_FP = 0 then Layout_FP + Id else Expected_Layout_FP);
      DV.Add_Record (Model, I);
   end Add_Record;

   procedure Accepts_Source_Shaped_Record_Discriminant_And_Variant_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : DV.Record_Model;
      Results : DV.Result_Model;
   begin
      Add_Record (Model, 1, DV.Record_Type_Declaration,
                  "type R (D : Boolean) is record ... end record",
                  Discriminant => DV.Discriminant_Known_Static,
                  Required_Discriminants => 1,
                  Supplied_Discriminants => 1);
      Add_Record (Model, 2, DV.Variant_Part,
                  "case D is when True => A : Integer; when False => B : Integer; end case",
                  Discriminant => DV.Discriminant_Known_Static,
                  Coverage => DV.Coverage_Complete,
                  Required_Discriminants => 1,
                  Supplied_Discriminants => 1);
      Add_Record (Model, 3, DV.Record_Aggregate,
                  "R'(D => True, A => 1)",
                  Discriminant => DV.Discriminant_Known_Static,
                  Required_Discriminants => 1,
                  Supplied_Discriminants => 1,
                  Components => 1,
                  Required_Components => 1);
      Add_Record (Model, 4, DV.Component_Selection,
                  "Obj.A under dynamic variant check",
                  Discriminant => DV.Discriminant_Known_Dynamic,
                  Selected_Variant_Active => False,
                  Runtime_Variant_Check => True);

      Results := DV.Build (Model);

      Assert (DV.Result_Count (Results) = 4, "expected four record rows");
      Assert (DV.Count_Status (Results, DV.Legality_Legal) = 3,
              "static record/discriminant/variant rows should be legal");
      Assert (DV.Count_Status (Results, DV.Legality_Legal_With_Runtime_Check) = 1,
              "dynamic variant component selection should be legal with runtime check");
      Assert (DV.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Source_Shaped_Record_Discriminant_And_Variant_Cases;

   procedure Rejects_Discriminant_And_Variant_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : DV.Record_Model;
      Results : DV.Result_Model;
   begin
      Add_Record (Model, 1, DV.Discriminant_Constraint,
                  "R without required discriminant",
                  Discriminant => DV.Discriminant_Unconstrained,
                  Required_Discriminants => 1,
                  Supplied_Discriminants => 0);
      Add_Record (Model, 2, DV.Discriminant_Constraint,
                  "R (D => Wrong_Type)",
                  Discriminant_Type_OK => False);
      Add_Record (Model, 3, DV.Discriminant_Part,
                  "D : Positive := -1",
                  Discriminant_Default_OK => False);
      Add_Record (Model, 4, DV.Variant_Part,
                  "case Missing_Discriminant is ...",
                  Coverage => DV.Coverage_Complete,
                  Variant_Has_Governing_Discriminant => False);
      Add_Record (Model, 5, DV.Variant_Part,
                  "variant missing one Boolean alternative",
                  Coverage => DV.Coverage_Missing_Alternative);
      Add_Record (Model, 6, DV.Variant_Alternative,
                  "overlapping variant choices",
                  Coverage => DV.Coverage_Overlapping_Choices);
      Add_Record (Model, 7, DV.Variant_Alternative,
                  "non-static variant choice",
                  Coverage => DV.Coverage_Non_Static_Choice);

      Results := DV.Build (Model);

      Assert (DV.Count_Status (Results, DV.Legality_Discriminant_Missing) = 1,
              "missing discriminant should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Discriminant_Type_Mismatch) = 1,
              "wrong discriminant type should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Discriminant_Default_Mismatch) = 1,
              "bad discriminant default should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Variant_Part_Missing_Discriminant) = 1,
              "variant part without governing discriminant should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Variant_Coverage_Incomplete) = 1,
              "missing variant alternative should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Variant_Choice_Overlap) = 1,
              "overlapping variant choices should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Variant_Choice_Not_Static) = 1,
              "non-static variant choice should be rejected");
   end Rejects_Discriminant_And_Variant_Errors;

   procedure Rejects_Aggregate_Delta_And_Layout_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : DV.Record_Model;
      Results : DV.Result_Model;
   begin
      Add_Record (Model, 1, DV.Record_Aggregate,
                  "R'(A => 1) missing discriminant",
                  Discriminant => DV.Discriminant_Unconstrained,
                  Required_Discriminants => 1,
                  Supplied_Discriminants => 0);
      Add_Record (Model, 2, DV.Record_Aggregate,
                  "R'(D => True) missing active component",
                  Components => 0,
                  Required_Components => 1);
      Add_Record (Model, 3, DV.Record_Aggregate,
                  "R'(D => True, A => 1, A => 2)",
                  Components => 2,
                  Required_Components => 1,
                  Duplicate_Component => True);
      Add_Record (Model, 4, DV.Record_Aggregate,
                  "R'(D => True, A => Wrong_Type)",
                  Components => 1,
                  Required_Components => 1,
                  Component_Type_OK => False);
      Add_Record (Model, 5, DV.Record_Delta_Aggregate,
                  "R with delta Missing => 1",
                  Has_Delta_Target => False);
      Add_Record (Model, 6, DV.Record_Delta_Aggregate,
                  "R with delta A => Wrong_Type",
                  Delta_Component_OK => False);
      Add_Record (Model, 7, DV.Representation_Component_Clause,
                  "for R use record A at 0 range 0 .. D end record",
                  Representation_Layout_OK => False);

      Results := DV.Build (Model);

      Assert (DV.Count_Status (Results, DV.Legality_Record_Aggregate_Discriminant_Missing) = 1,
              "aggregate missing discriminant should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Record_Aggregate_Component_Missing) = 1,
              "aggregate missing component should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Record_Aggregate_Component_Duplicate) = 1,
              "duplicate aggregate component should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Record_Aggregate_Component_Type_Mismatch) = 1,
              "component type mismatch should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Delta_Update_Target_Missing) = 1,
              "missing delta target should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Delta_Update_Component_Mismatch) = 1,
              "delta component mismatch should be rejected");
      Assert (DV.Count_Status (Results, DV.Legality_Representation_Layout_Conflict) = 1,
              "representation layout conflict should be rejected");
   end Rejects_Aggregate_Delta_And_Layout_Errors;

   procedure Preserves_Cross_Consumer_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : DV.Record_Model;
      Results : DV.Result_Model;
   begin
      Add_Record (Model, 1, DV.Record_Aggregate,
                  "private record before full view",
                  View => DV.View_Private_Record,
                  Private_View => False);
      Add_Record (Model, 2, DV.Record_Aggregate,
                  "limited view record aggregate",
                  View => DV.View_Limited_Record,
                  Limited_View => False);
      Add_Record (Model, 3, DV.Record_Extension_Declaration,
                  "type Child is new Parent with record ...",
                  View => DV.View_Record_Extension,
                  Tagged_Extension_OK => False);
      Add_Record (Model, 4, DV.Component_Declaration,
                  "controlled component with bad finalization evidence",
                  Controlled_Finalization_OK => False);
      Add_Record (Model, 5, DV.Component_Declaration,
                  "access discriminant component escapes master",
                  Accessibility_OK => False);
      Add_Record (Model, 6, DV.Record_Aggregate,
                  "aggregate blocked by initialization",
                  Initialization_OK => False);
      Add_Record (Model, 7, DV.Record_Aggregate,
                  "stale layout fingerprint",
                  Expected_Layout_FP => 999999);

      Results := DV.Build (Model);

      Assert (DV.Count_Status (Results, DV.Legality_Private_View_Barrier) = 1,
              "private view barrier should be preserved");
      Assert (DV.Count_Status (Results, DV.Legality_Limited_View_Barrier) = 1,
              "limited view barrier should be preserved");
      Assert (DV.Count_Status (Results, DV.Legality_Tagged_Extension_Blocked) = 1,
              "tagged extension blocker should be preserved");
      Assert (DV.Count_Status (Results, DV.Legality_Controlled_Finalization_Blocked) = 1,
              "controlled/finalization blocker should be preserved");
      Assert (DV.Count_Status (Results, DV.Legality_Accessibility_Blocked) = 1,
              "accessibility blocker should be preserved");
      Assert (DV.Count_Status (Results, DV.Legality_Initialization_Blocked) = 1,
              "initialization blocker should be preserved");
      Assert (DV.Count_Status (Results, DV.Legality_Layout_Fingerprint_Mismatch) = 1,
              "layout fingerprint mismatch should be preserved");
   end Preserves_Cross_Consumer_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Record_Discriminant_And_Variant_Cases'Access,
         "accepts source-shaped record/discriminant/variant cases");
      Register_Routine
        (T, Rejects_Discriminant_And_Variant_Errors'Access,
         "rejects discriminant and variant errors");
      Register_Routine
        (T, Rejects_Aggregate_Delta_And_Layout_Errors'Access,
         "rejects aggregate/delta/layout errors");
      Register_Routine
        (T, Preserves_Cross_Consumer_And_Fingerprint_Blockers'Access,
         "preserves cross-consumer and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Discriminant_Variant_Record_Vertical_Slice_Legality_Pass1313;
