with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Aggregate_Legality_Vertical_Slice;

package body Test_Ada_Aggregate_Legality_Vertical_Slice is

   package AL renames Editor.Ada_Aggregate_Legality_Vertical_Slice;
   use type AL.Aggregate_Id;
   use type AL.Type_Id;
   use type AL.Result_Id;
   use type AL.Aggregate_Kind;
   use type AL.Expected_Type_Kind;
   use type AL.Aggregate_View_Kind;
   use type AL.Association_Form;
   use type AL.Aggregate_Status;
   use type AL.Expected_Type_Info;
   use type AL.Aggregate_Info;
   use type AL.Result_Info;
   use type AL.Aggregate_Model;
   use type AL.Expected_Type_Model;
   use type AL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Aggregate_Legality_Vertical_Slice");
   end Name;

   procedure Add_Type
     (Model : in out AL.Expected_Type_Model;
      Id : Natural;
      Name : String;
      Kind : AL.Expected_Type_Kind;
      View : AL.Aggregate_View_Kind := AL.View_Full;
      Required : Natural := 0;
      Defaults : Boolean := False;
      Null_OK : Boolean := False;
      Discriminants_OK : Boolean := True;
      Variants_OK : Boolean := True;
      Components_OK : Boolean := True;
      Container_OK : Boolean := True;
      Controlled_Finalized : Boolean := False;
      Source_FP : Natural := 132600;
      Type_FP : Natural := 232600;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      T : AL.Expected_Type_Info;
   begin
      T.Id := AL.Type_Id (Id);
      T.Name := To_Unbounded_String (Name);
      T.Kind := Kind;
      T.View := View;
      T.Required_Component_Count := Required;
      T.Allows_Defaulted_Components := Defaults;
      T.Allows_Null_Aggregate := Null_OK;
      T.Discriminants_Conformant := Discriminants_OK;
      T.Variants_Conformant := Variants_OK;
      T.Component_Types_Conformant := Components_OK;
      T.Container_Profile_Conformant := Container_OK;
      T.Controlled_Or_Finalized_Component := Controlled_Finalized;
      T.Source_Fingerprint := Source_FP + Id;
      T.Type_Fingerprint := Type_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      AL.Add_Expected_Type (Model, T);
   end Add_Type;

   procedure Add_Aggregate
     (Model : in out AL.Aggregate_Model;
      Id : Natural;
      Name : String;
      Kind : AL.Aggregate_Kind;
      Expected : Natural;
      View : AL.Aggregate_View_Kind := AL.View_Full;
      Form : AL.Association_Form := AL.Associations_Named;
      Count : Natural := 0;
      Named : Natural := 0;
      Positional : Natural := 0;
      Duplicates : Natural := 0;
      Extras : Natural := 0;
      Missing : Natural := 0;
      Type_Mismatches : Natural := 0;
      Static_Required : Boolean := False;
      Static_Present : Boolean := True;
      Overlaps : Natural := 0;
      Discriminants_OK : Boolean := True;
      Variants_OK : Boolean := True;
      Ancestor_OK : Boolean := True;
      Delta_OK : Boolean := True;
      Container_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Defaulted : Natural := 0;
      Source_FP : Natural := 332600;
      AST_FP : Natural := 432600;
      Type_FP : Natural := 532600;
      Static_FP : Natural := 632600;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Static_FP : Natural := 0)
   is
      A : AL.Aggregate_Info;
   begin
      A.Id := AL.Aggregate_Id (Id);
      A.Name := To_Unbounded_String (Name);
      A.Node := Editor.Ada_Syntax_Tree.Node_Id (132600 + Id);
      A.Kind := Kind;
      A.Expected_Type := AL.Type_Id (Expected);
      A.View := View;
      A.Associations := Form;
      A.Association_Count := Count;
      A.Named_Association_Count := Named;
      A.Positional_Association_Count := Positional;
      A.Duplicate_Associations := Duplicates;
      A.Extra_Associations := Extras;
      A.Missing_Associations := Missing;
      A.Component_Type_Mismatches := Type_Mismatches;
      A.Static_Choices_Required := Static_Required;
      A.Static_Choices_Present := Static_Present;
      A.Choice_Overlaps := Overlaps;
      A.Discriminants_OK := Discriminants_OK;
      A.Variants_OK := Variants_OK;
      A.Extension_Ancestor_OK := Ancestor_OK;
      A.Delta_Target_OK := Delta_OK;
      A.Container_Profile_OK := Container_OK;
      A.Accessibility_OK := Accessibility_OK;
      A.Predicate_OK := Predicate_OK;
      A.Runtime_Check_Required := Runtime_Check;
      A.Defaulted_Component_Count := Defaulted;
      A.Source_Fingerprint := Source_FP + Id;
      A.AST_Fingerprint := AST_FP + Id;
      A.Type_Fingerprint := Type_FP + Id;
      A.Static_Fingerprint := Static_FP + Id;
      A.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      A.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      A.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      A.Expected_Static_Fingerprint :=
        (if Expected_Static_FP = 0 then Static_FP + Id else Expected_Static_FP);
      AL.Add_Aggregate (Model, A);
   end Add_Aggregate;

   procedure Test_Record_Aggregate_Defaulted_Components

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Aggregates : AL.Aggregate_Model;
      Types : AL.Expected_Type_Model;
      Results : AL.Result_Model;
   begin
      Add_Type (Types, 1, "R", AL.Expected_Record, Required => 3, Defaults => True);
      Add_Aggregate (Aggregates, 1, "(A => 1, B => 2)", AL.Aggregate_Record, 1,
                     Count => 2, Named => 2);
      Results := AL.Build (Aggregates, Types);
      Assert (AL.Result_Count (Results) = 1, "one aggregate result expected");
      Assert (AL.Result_At (Results, 1).Status = AL.Aggregate_Legal_With_Defaulted_Components,
              "record aggregate may use defaulted component associations");
      Assert (AL.Legal_Count (Results) = 1, "defaulted aggregate is legal");
   end Test_Record_Aggregate_Defaulted_Components;

   procedure Test_Array_Aggregate_Static_Choice_And_Overlap

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Aggregates : AL.Aggregate_Model;
      Types : AL.Expected_Type_Model;
      Results : AL.Result_Model;
   begin
      Add_Type (Types, 1, "Vector", AL.Expected_Array, Required => 3);
      Add_Aggregate (Aggregates, 1, "(1 .. N => 0, 2 => 1)", AL.Aggregate_Array, 1,
                     Count => 3, Named => 3, Static_Required => True,
                     Static_Present => False, Overlaps => 1);
      Results := AL.Build (Aggregates, Types);
      Assert (AL.Result_At (Results, 1).Status = AL.Aggregate_Multiple_Blockers,
              "array choices preserve staticness and overlap blockers");
      Assert (AL.Error_Count (Results) = 1, "array aggregate rejected");
   end Test_Array_Aggregate_Static_Choice_And_Overlap;

   procedure Test_Record_Discriminant_Variant_Component_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Aggregates : AL.Aggregate_Model;
      Types : AL.Expected_Type_Model;
      Results : AL.Result_Model;
   begin
      Add_Type (Types, 1, "Variant_Record", AL.Expected_Record, Required => 2,
                Discriminants_OK => False, Variants_OK => False, Components_OK => False);
      Add_Aggregate (Aggregates, 1, "(D => True, X => 1)", AL.Aggregate_Record, 1,
                     Count => 2, Named => 2, Type_Mismatches => 1);
      Results := AL.Build (Aggregates, Types);
      Assert (AL.Result_At (Results, 1).Status = AL.Aggregate_Multiple_Blockers,
              "discriminant, variant, and component-type blockers compose");
   end Test_Record_Discriminant_Variant_Component_Blockers;

   procedure Test_Extension_Delta_Container_And_Null_Aggregates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Aggregates : AL.Aggregate_Model;
      Types : AL.Expected_Type_Model;
      Results : AL.Result_Model;
   begin
      Add_Type (Types, 1, "T", AL.Expected_Tagged_Record, Required => 1);
      Add_Type (Types, 2, "R", AL.Expected_Record, Required => 1);
      Add_Type (Types, 3, "Map", AL.Expected_Container, Container_OK => False);
      Add_Type (Types, 4, "Non_Null_Record", AL.Expected_Record, Required => 0, Null_OK => False);
      Add_Aggregate (Aggregates, 1, "(Parent with C => 1)", AL.Aggregate_Extension, 1,
                     Count => 1, Ancestor_OK => False);
      Add_Aggregate (Aggregates, 2, "(Obj with delta C => 2)", AL.Aggregate_Delta, 2,
                     Count => 1, Delta_OK => False);
      Add_Aggregate (Aggregates, 3, "[1, 2, 3]", AL.Aggregate_Container, 3,
                     Count => 3, Container_OK => False);
      Add_Aggregate (Aggregates, 4, "(null record)", AL.Aggregate_Null, 4,
                     Form => AL.Associations_None, Count => 0);
      Results := AL.Build (Aggregates, Types);
      Assert (AL.Result_Count (Results) = 4, "four aggregate forms checked");
      Assert (AL.Count_Status (Results, AL.Aggregate_Extension_Ancestor_Mismatch) = 1,
              "extension ancestor mismatch detected");
      Assert (AL.Count_Status (Results, AL.Aggregate_Delta_Target_Mismatch) = 1,
              "delta target mismatch detected");
      Assert (AL.Count_Status (Results, AL.Aggregate_Container_Profile_Mismatch) = 1,
              "container aggregate profile mismatch detected");
      Assert (AL.Count_Status (Results, AL.Aggregate_Null_Not_Allowed) = 1,
              "null aggregate rejected where not allowed");
   end Test_Extension_Delta_Container_And_Null_Aggregates;

   procedure Test_View_Accessibility_Predicate_And_Runtime_Check

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Aggregates : AL.Aggregate_Model;
      Types : AL.Expected_Type_Model;
      Results : AL.Result_Model;
   begin
      Add_Type (Types, 1, "Private_Record", AL.Expected_Record, View => AL.View_Private,
                Required => 1);
      Add_Type (Types, 2, "Access_Record", AL.Expected_Record, Required => 1);
      Add_Type (Types, 3, "Predicate_Record", AL.Expected_Record, Required => 1);
      Add_Aggregate (Aggregates, 1, "(C => 1)", AL.Aggregate_Record, 1, Count => 1,
                     Named => 1);
      Add_Aggregate (Aggregates, 2, "(Ptr => Local'Access)", AL.Aggregate_Record, 2,
                     Count => 1, Named => 1, Accessibility_OK => False);
      Add_Aggregate (Aggregates, 3, "(C => Possibly_Invalid)", AL.Aggregate_Record, 3,
                     Count => 1, Named => 1, Predicate_OK => True, Runtime_Check => True);
      Results := AL.Build (Aggregates, Types);
      Assert (AL.Count_Status (Results, AL.Aggregate_Private_View_Barrier) = 1,
              "private aggregate view barrier detected");
      Assert (AL.Count_Status (Results, AL.Aggregate_Accessibility_Blocker) = 1,
              "accessibility blocker detected");
      Assert (AL.Count_Status (Results, AL.Aggregate_Legal_With_Runtime_Check) = 1,
              "runtime predicate check remains legal");
   end Test_View_Accessibility_Predicate_And_Runtime_Check;

   procedure Test_Stale_Fingerprint_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Aggregates : AL.Aggregate_Model;
      Types : AL.Expected_Type_Model;
      Results : AL.Result_Model;
   begin
      Add_Type (Types, 1, "R", AL.Expected_Record, Required => 1, Expected_Type_FP => 999);
      Add_Aggregate (Aggregates, 1, "(C => 1)", AL.Aggregate_Record, 1,
                     Count => 1, Named => 1, Expected_Source_FP => 888,
                     Expected_AST_FP => 777, Expected_Static_FP => 666);
      Results := AL.Build (Aggregates, Types);
      Assert (AL.Result_At (Results, 1).Status = AL.Aggregate_Multiple_Blockers,
              "source/AST/type/static freshness blockers are preserved");
   end Test_Stale_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Record_Aggregate_Defaulted_Components'Access,
                        "record aggregate defaulted components");
      Register_Routine (T, Test_Array_Aggregate_Static_Choice_And_Overlap'Access,
                        "array aggregate static choices and overlap");
      Register_Routine (T, Test_Record_Discriminant_Variant_Component_Blockers'Access,
                        "record discriminant variant component blockers");
      Register_Routine (T, Test_Extension_Delta_Container_And_Null_Aggregates'Access,
                        "extension delta container null aggregates");
      Register_Routine (T, Test_View_Accessibility_Predicate_And_Runtime_Check'Access,
                        "view accessibility predicate runtime check");
      Register_Routine (T, Test_Stale_Fingerprint_Blockers'Access,
                        "stale aggregate fingerprints");
   end Register_Tests;

end Test_Ada_Aggregate_Legality_Vertical_Slice;
