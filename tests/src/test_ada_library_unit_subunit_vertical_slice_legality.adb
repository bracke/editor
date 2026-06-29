with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality;

package body Test_Ada_Library_Unit_Subunit_Vertical_Slice_Legality is

   package LUS renames Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality;
   use type LUS.Unit_Id;
   use type LUS.Stub_Id;
   use type LUS.Check_Id;
   use type LUS.Result_Id;
   use type LUS.Unit_Kind;
   use type LUS.Stub_Kind;
   use type LUS.View_Kind;
   use type LUS.Check_Kind;
   use type LUS.Legality_Status;
   use type LUS.Unit_Info;
   use type LUS.Unit_Model;
   use type LUS.Stub_Info;
   use type LUS.Stub_Model;
   use type LUS.Check_Info;
   use type LUS.Check_Model;
   use type LUS.Result_Info;
   use type LUS.Result_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada library unit subunit vertical slice legality");
   end Name;

   procedure Add_Unit
     (Model : in out LUS.Unit_Model;
      Id : Natural;
      Name_Text : String;
      Kind : LUS.Unit_Kind;
      Parent : Natural := 0;
      Spec : Natural := 0;
      Body_Id : Natural := 0;
      View : LUS.View_Kind := LUS.View_Full;
      Library : Boolean := True;
      Private_Child : Boolean := False;
      Parent_Name_OK : Boolean := True;
      Required_Body : Boolean := True;
      Body_Present : Boolean := True;
      Spec_Present : Boolean := True;
      Body_After_Spec : Boolean := True;
      Duplicate_Body : Boolean := False;
      Source_FP : Natural := 133100;
      Unit_FP : Natural := 233100;
      Body_FP : Natural := 333100;
      Closure_FP : Natural := 433100;
      Expected_Source_FP : Natural := 0;
      Expected_Unit_FP : Natural := 0;
      Expected_Body_FP : Natural := 0;
      Expected_Closure_FP : Natural := 0)
   is
      U : LUS.Unit_Info;
   begin
      U.Id := LUS.Unit_Id (Id);
      U.Name := To_Unbounded_String (Name_Text);
      U.Node := Editor.Ada_Syntax_Tree.Node_Id (133100 + Id);
      U.Kind := Kind;
      U.Parent := LUS.Unit_Id (Parent);
      U.Spec := LUS.Unit_Id (Spec);
      U.Body_Ref := LUS.Unit_Id (Body_Id);
      U.View := View;
      U.Is_Library_Unit := Library;
      U.Is_Private_Child := Private_Child;
      U.Parent_Name_Matches := Parent_Name_OK;
      U.Has_Required_Body := Required_Body;
      U.Body_Present := Body_Present;
      U.Spec_Present := Spec_Present;
      U.Body_After_Spec := Body_After_Spec;
      U.Duplicate_Body := Duplicate_Body;
      U.Source_Fingerprint := Source_FP + Id;
      U.Unit_Fingerprint := Unit_FP + Id;
      U.Body_Fingerprint := Body_FP + Id;
      U.Closure_Fingerprint := Closure_FP + Id;
      U.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      U.Expected_Unit_Fingerprint :=
        (if Expected_Unit_FP = 0 then Unit_FP + Id else Expected_Unit_FP);
      U.Expected_Body_Fingerprint :=
        (if Expected_Body_FP = 0 then Body_FP + Id else Expected_Body_FP);
      U.Expected_Closure_Fingerprint :=
        (if Expected_Closure_FP = 0 then Closure_FP + Id else Expected_Closure_FP);
      LUS.Add_Unit (Model, U);
   end Add_Unit;

   procedure Add_Stub
     (Model : in out LUS.Stub_Model;
      Id : Natural;
      Name_Text : String;
      Kind : LUS.Stub_Kind;
      Parent : Natural := 0;
      Separate_Body : Natural := 0;
      Expected_Separate : LUS.Unit_Kind := LUS.Unit_Unknown;
      Separate_Present : Boolean := True;
      Duplicate_Subunit : Boolean := False;
      Parent_Name_OK : Boolean := True;
      Source_FP : Natural := 533100;
      Stub_FP : Natural := 633100;
      Closure_FP : Natural := 733100;
      Expected_Source_FP : Natural := 0;
      Expected_Stub_FP : Natural := 0;
      Expected_Closure_FP : Natural := 0)
   is
      S : LUS.Stub_Info;
   begin
      S.Id := LUS.Stub_Id (Id);
      S.Name := To_Unbounded_String (Name_Text);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (233100 + Id);
      S.Kind := Kind;
      S.Parent_Unit := LUS.Unit_Id (Parent);
      S.Separate_Body := LUS.Unit_Id (Separate_Body);
      S.Expected_Separate_Kind := Expected_Separate;
      S.Separate_Present := Separate_Present;
      S.Duplicate_Subunit := Duplicate_Subunit;
      S.Parent_Name_Matches := Parent_Name_OK;
      S.Source_Fingerprint := Source_FP + Id;
      S.Stub_Fingerprint := Stub_FP + Id;
      S.Closure_Fingerprint := Closure_FP + Id;
      S.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      S.Expected_Stub_Fingerprint :=
        (if Expected_Stub_FP = 0 then Stub_FP + Id else Expected_Stub_FP);
      S.Expected_Closure_Fingerprint :=
        (if Expected_Closure_FP = 0 then Closure_FP + Id else Expected_Closure_FP);
      LUS.Add_Stub (Model, S);
   end Add_Stub;

   procedure Add_Check
     (Model : in out LUS.Check_Model;
      Id : Natural;
      Name_Text : String;
      Kind : LUS.Check_Kind;
      Unit : Natural := 0;
      Parent : Natural := 0;
      Child : Natural := 0;
      Spec : Natural := 0;
      Body_Id : Natural := 0;
      Stub : Natural := 0;
      Nested_Stub : Natural := 0;
      Expected_Unit : LUS.Unit_Kind := LUS.Unit_Unknown;
      Expected_Stub : LUS.Stub_Kind := LUS.Stub_Unknown;
      Parent_Name_OK : Boolean := True;
      Child_Parent_OK : Boolean := True;
      Private_Child_Visible : Boolean := True;
      Private_Child_Spec_Present : Boolean := True;
      Body_After_Spec : Boolean := True;
      Duplicate_Body : Boolean := False;
      Duplicate_Subunit : Boolean := False;
      Requires_Separate : Boolean := False;
      Separate_Present : Boolean := True;
      Nested_Parent_OK : Boolean := True;
      Library_Complete : Boolean := True;
      Source_FP : Natural := 833100;
      Unit_FP : Natural := 933100;
      Body_FP : Natural := 143100;
      Stub_FP : Natural := 243100;
      Closure_FP : Natural := 343100;
      Expected_Source_FP : Natural := 0;
      Expected_Unit_FP : Natural := 0;
      Expected_Body_FP : Natural := 0;
      Expected_Stub_FP : Natural := 0;
      Expected_Closure_FP : Natural := 0)
   is
      C : LUS.Check_Info;
   begin
      C.Id := LUS.Check_Id (Id);
      C.Name := To_Unbounded_String (Name_Text);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (333100 + Id);
      C.Kind := Kind;
      C.Unit := LUS.Unit_Id (Unit);
      C.Parent_Unit := LUS.Unit_Id (Parent);
      C.Child_Unit := LUS.Unit_Id (Child);
      C.Spec_Unit := LUS.Unit_Id (Spec);
      C.Body_Unit := LUS.Unit_Id (Body_Id);
      C.Stub := LUS.Stub_Id (Stub);
      C.Nested_Parent_Stub := LUS.Stub_Id (Nested_Stub);
      C.Expected_Unit_Kind := Expected_Unit;
      C.Expected_Stub_Kind := Expected_Stub;
      C.Parent_Name_Matches := Parent_Name_OK;
      C.Child_Parent_Present := Child_Parent_OK;
      C.Private_Child_Visible := Private_Child_Visible;
      C.Private_Child_Spec_Present := Private_Child_Spec_Present;
      C.Body_After_Spec := Body_After_Spec;
      C.Duplicate_Body := Duplicate_Body;
      C.Duplicate_Subunit := Duplicate_Subunit;
      C.Requires_Separate_Body := Requires_Separate;
      C.Separate_Body_Present := Separate_Present;
      C.Nested_Separate_Parent_Matches := Nested_Parent_OK;
      C.Library_Unit_Complete := Library_Complete;
      C.Source_Fingerprint := Source_FP + Id;
      C.Unit_Fingerprint := Unit_FP + Id;
      C.Body_Fingerprint := Body_FP + Id;
      C.Stub_Fingerprint := Stub_FP + Id;
      C.Closure_Fingerprint := Closure_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_Unit_Fingerprint :=
        (if Expected_Unit_FP = 0 then Unit_FP + Id else Expected_Unit_FP);
      C.Expected_Body_Fingerprint :=
        (if Expected_Body_FP = 0 then Body_FP + Id else Expected_Body_FP);
      C.Expected_Stub_Fingerprint :=
        (if Expected_Stub_FP = 0 then Stub_FP + Id else Expected_Stub_FP);
      C.Expected_Closure_Fingerprint :=
        (if Expected_Closure_FP = 0 then Closure_FP + Id else Expected_Closure_FP);
      LUS.Add_Check (Model, C);
   end Add_Check;

   procedure Test_Separate_Subunit_Requires_Matching_Stub

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : LUS.Unit_Model;
      Stubs : LUS.Stub_Model;
      Checks : LUS.Check_Model;
      Results : LUS.Result_Model;
   begin
      Add_Unit (Units, 1, "Pkg", LUS.Unit_Package_Body);
      Add_Unit (Units, 2, "Pkg.Worker", LUS.Unit_Subunit, Parent => 1);
      Add_Stub (Stubs, 1, "separate Worker", LUS.Stub_Subprogram_Body,
                Parent => 1, Separate_Body => 2);
      Add_Check (Checks, 1, "separate body for stub", LUS.Check_Separate_Subunit,
                 Unit => 2, Parent => 1, Stub => 1);
      Add_Check (Checks, 2, "separate without stub", LUS.Check_Separate_Subunit,
                 Unit => 2, Parent => 1);
      Results := LUS.Build (Units, Stubs, Checks);
      Assert (LUS.Result_At (Results, 1).Status = LUS.Legality_Legal,
              "separate subunit is legal when it completes a matching body stub");
      Assert (LUS.Result_At (Results, 2).Status = LUS.Legality_Separate_Without_Stub,
              "separate subunit without corresponding stub is rejected");
   end Test_Separate_Subunit_Requires_Matching_Stub;

   procedure Test_Body_Stub_And_Duplicate_Subunit_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : LUS.Unit_Model;
      Stubs : LUS.Stub_Model;
      Checks : LUS.Check_Model;
      Results : LUS.Result_Model;
   begin
      Add_Unit (Units, 1, "Pkg", LUS.Unit_Package_Body);
      Add_Stub (Stubs, 1, "body stub", LUS.Stub_Package_Body,
                Parent => 1, Separate_Present => False,
                Duplicate_Subunit => True);
      Add_Check (Checks, 1, "stub requires separate", LUS.Check_Body_Stub,
                 Parent => 1, Stub => 1, Expected_Stub => LUS.Stub_Package_Body,
                 Requires_Separate => True, Separate_Present => False);
      Add_Check (Checks, 2, "duplicate subunit", LUS.Check_Separate_Subunit,
                 Unit => 1, Parent => 1, Stub => 1, Duplicate_Subunit => True);
      Results := LUS.Build (Units, Stubs, Checks);
      Assert (LUS.Result_At (Results, 1).Status = LUS.Legality_Multiple_Blockers,
              "body stub records missing separate body and duplicate subunit evidence together");
      Assert (LUS.Result_At (Results, 1).Body_Stub_Separate_Blockers = 1,
              "body-stub separate-body blocker recorded");
      Assert (LUS.Result_At (Results, 2).Duplicate_Subunit_Blockers = 1,
              "duplicate subunit blocker recorded");
   end Test_Body_Stub_And_Duplicate_Subunit_Blockers;

   procedure Test_Library_Unit_Completion_And_Body_Spec_Order

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : LUS.Unit_Model;
      Stubs : LUS.Stub_Model;
      Checks : LUS.Check_Model;
      Results : LUS.Result_Model;
   begin
      Add_Unit (Units, 1, "Pkg", LUS.Unit_Package_Spec,
                Required_Body => True, Body_Present => True);
      Add_Unit (Units, 2, "Pkg", LUS.Unit_Package_Body, Spec => 1);
      Add_Unit (Units, 3, "Missing", LUS.Unit_Package_Spec,
                Required_Body => True, Body_Present => False);
      Add_Check (Checks, 1, "complete package", LUS.Check_Library_Unit_Completion,
                 Spec => 1, Body_Id => 2);
      Add_Check (Checks, 2, "missing body", LUS.Check_Library_Unit_Completion,
                 Spec => 3, Library_Complete => False);
      Add_Check (Checks, 3, "body before spec", LUS.Check_Library_Unit_Completion,
                 Spec => 1, Body_Id => 2, Body_After_Spec => False);
      Results := LUS.Build (Units, Stubs, Checks);
      Assert (LUS.Result_At (Results, 1).Status = LUS.Legality_Legal,
              "library package spec/body pair completes successfully");
      Assert (LUS.Result_At (Results, 2).Status = LUS.Legality_Multiple_Blockers,
              "required body absence and incomplete closure are both preserved");
      Assert (LUS.Result_At (Results, 3).Status = LUS.Legality_Body_Before_Spec,
              "body before spec placement is rejected");
   end Test_Library_Unit_Completion_And_Body_Spec_Order;

   procedure Test_Child_And_Private_Child_Visibility

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : LUS.Unit_Model;
      Stubs : LUS.Stub_Model;
      Checks : LUS.Check_Model;
      Results : LUS.Result_Model;
   begin
      Add_Unit (Units, 1, "Parent", LUS.Unit_Package_Spec);
      Add_Unit (Units, 2, "Parent.Child", LUS.Unit_Child_Spec, Parent => 1);
      Add_Unit (Units, 3, "Parent.Secret", LUS.Unit_Private_Child_Body,
                Parent => 1, Private_Child => True);
      Add_Check (Checks, 1, "child unit", LUS.Check_Child_Unit,
                 Parent => 1, Child => 2);
      Add_Check (Checks, 2, "child without parent", LUS.Check_Child_Unit,
                 Child => 2, Child_Parent_OK => False);
      Add_Check (Checks, 3, "private child body", LUS.Check_Private_Child_Body,
                 Parent => 1, Child => 3, Private_Child_Visible => False,
                 Private_Child_Spec_Present => False);
      Results := LUS.Build (Units, Stubs, Checks);
      Assert (LUS.Result_At (Results, 1).Status = LUS.Legality_Legal,
              "child unit is legal when parent library unit evidence is present");
      Assert (LUS.Result_At (Results, 2).Status = LUS.Legality_Child_Parent_Missing,
              "child unit without parent evidence is rejected");
      Assert (LUS.Result_At (Results, 3).Status = LUS.Legality_Multiple_Blockers,
              "private child body requires both visible context and private child spec");
      Assert (LUS.Result_At (Results, 3).Private_Child_Spec_Blockers = 1,
              "private child spec blocker recorded");
      Assert (LUS.Result_At (Results, 3).Private_Child_Visibility_Blockers = 1,
              "private child visibility blocker recorded");
   end Test_Child_And_Private_Child_Visibility;

   procedure Test_Nested_Separate_View_And_Fingerprint_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : LUS.Unit_Model;
      Stubs : LUS.Stub_Model;
      Checks : LUS.Check_Model;
      Results : LUS.Result_Model;
   begin
      Add_Unit (Units, 1, "Pkg", LUS.Unit_Package_Body,
                View => LUS.View_Limited);
      Add_Stub (Stubs, 1, "outer stub", LUS.Stub_Subprogram_Body,
                Parent => 1, Expected_Stub_FP => 42);
      Add_Check (Checks, 1, "nested separate", LUS.Check_Nested_Separate_Body,
                 Parent => 1, Nested_Stub => 1, Nested_Parent_OK => False,
                 Expected_Source_FP => 42, Expected_Closure_FP => 43);
      Results := LUS.Build (Units, Stubs, Checks);
      Assert (LUS.Result_At (Results, 1).Status = LUS.Legality_Multiple_Blockers,
              "nested separate parent mismatch, limited view, and stale fingerprints compose");
      Assert (LUS.Result_At (Results, 1).Nested_Separate_Parent_Blockers = 1,
              "nested separate parent blocker recorded");
      Assert (LUS.Result_At (Results, 1).Limited_View_Blockers = 1,
              "limited-view blocker recorded for parent evidence");
      Assert (LUS.Result_At (Results, 1).Source_Fingerprint_Blockers = 1,
              "source fingerprint blocker recorded");
      Assert (LUS.Result_At (Results, 1).Stub_Fingerprint_Blockers = 1,
              "stub fingerprint blocker recorded");
      Assert (LUS.Result_At (Results, 1).Closure_Fingerprint_Blockers = 1,
              "closure fingerprint blocker recorded");
   end Test_Nested_Separate_View_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Separate_Subunit_Requires_Matching_Stub'Access,
         "separate subunit requires matching body stub");
      Register_Routine
        (T, Test_Body_Stub_And_Duplicate_Subunit_Blockers'Access,
         "body stubs and duplicate subunits");
      Register_Routine
        (T, Test_Library_Unit_Completion_And_Body_Spec_Order'Access,
         "library unit completion and body/spec order");
      Register_Routine
        (T, Test_Child_And_Private_Child_Visibility'Access,
         "child and private child visibility");
      Register_Routine
        (T, Test_Nested_Separate_View_And_Fingerprint_Blockers'Access,
         "nested separate parent and stale evidence blockers");
   end Register_Tests;

end Test_Ada_Library_Unit_Subunit_Vertical_Slice_Legality;
