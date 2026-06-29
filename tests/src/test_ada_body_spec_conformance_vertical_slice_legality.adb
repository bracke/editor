with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality;

package body Test_Ada_Body_Spec_Conformance_Vertical_Slice_Legality is

   package BC renames Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality;
   use type BC.Completion_Id;
   use type BC.Result_Id;
   use type BC.Completion_Kind;
   use type BC.Unit_Kind;
   use type BC.Profile_Conformance_Kind;
   use type BC.Completion_Placement;
   use type BC.View_Kind;
   use type BC.Legality_Status;
   use type BC.Completion_Info;
   use type BC.Result_Info;
   use type BC.Completion_Model;
   use type BC.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Body_Spec_Conformance_Vertical_Slice_Legality");
   end Name;

   procedure Add_Completion
     (Model : in out BC.Completion_Model;
      Id    : Natural;
      Kind  : BC.Completion_Kind;
      Text  : String;
      Spec  : BC.Unit_Kind;
      Body_Info  : BC.Unit_Kind;
      Placement : BC.Completion_Placement := BC.Placement_Package_Body;
      View  : BC.View_Kind := BC.View_Full;
      Profile : BC.Profile_Conformance_Kind := BC.Profile_Fully_Conformant;
      AST : Boolean := True;
      Has_Spec : Boolean := True;
      Has_Body : Boolean := True;
      Body_Required : Boolean := True;
      Duplicate_Body : Boolean := False;
      Kind_OK : Boolean := True;
      Region_OK : Boolean := True;
      Generic_Formals_OK : Boolean := True;
      Generic_Body_OK : Boolean := True;
      Stub_OK : Boolean := True;
      Parent_OK : Boolean := True;
      Full_View_OK : Boolean := True;
      Deferred_OK : Boolean := True;
      Incomplete_OK : Boolean := True;
      Visibility_OK : Boolean := True;
      Limited_OK : Boolean := True;
      Private_OK : Boolean := True;
      Elaboration_OK : Boolean := True;
      Overload_OK : Boolean := True;
      Representation_OK : Boolean := True;
      Source_FP : Natural := 131800;
      Spec_FP : Natural := 231800;
      Body_FP : Natural := 331800;
      Profile_FP : Natural := 431800;
      Expected_Source_FP : Natural := 0;
      Expected_Spec_FP : Natural := 0;
      Expected_Body_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0)
   is
      I : BC.Completion_Info;
   begin
      I.Id := BC.Completion_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131800 + Id);
      I.Kind := Kind;
      I.Spec_Unit := Spec;
      I.Body_Unit := Body_Info;
      I.Name := To_Unbounded_String (Text);
      I.Placement := Placement;
      I.View := View;
      I.Profile := Profile;
      I.Has_AST_Coverage := AST;
      I.Has_Spec := Has_Spec;
      I.Has_Body := Has_Body;
      I.Body_Required := Body_Required;
      I.Duplicate_Body := Duplicate_Body;
      I.Completion_Kind_Matches := Kind_OK;
      I.Region_Matches := Region_OK;
      I.Generic_Formals_Conform := Generic_Formals_OK;
      I.Generic_Body_Available := Generic_Body_OK;
      I.Separate_Stub_Present := Stub_OK;
      I.Separate_Parent_Matches := Parent_OK;
      I.Private_Full_View_Present := Full_View_OK;
      I.Deferred_Constant_Matches := Deferred_OK;
      I.Incomplete_Type_Completed := Incomplete_OK;
      I.Visibility_OK := Visibility_OK;
      I.Limited_View_Allows_Completion := Limited_OK;
      I.Private_View_Allows_Completion := Private_OK;
      I.Elaboration_OK := Elaboration_OK;
      I.Overload_Profile_OK := Overload_OK;
      I.Representation_OK := Representation_OK;
      I.Source_Fingerprint := Source_FP + Id;
      I.Spec_Fingerprint := Spec_FP + Id;
      I.Body_Fingerprint := Body_FP + Id;
      I.Profile_Fingerprint := Profile_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_Spec_Fingerprint :=
        (if Expected_Spec_FP = 0 then Spec_FP + Id else Expected_Spec_FP);
      I.Expected_Body_Fingerprint :=
        (if Expected_Body_FP = 0 then Body_FP + Id else Expected_Body_FP);
      I.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      BC.Add_Completion (Model, I);
   end Add_Completion;

   procedure Accepts_Source_Shaped_Bodies_Stubs_And_Completions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : BC.Completion_Model;
      Results : BC.Result_Model;
   begin
      Add_Completion (Model, 1, BC.Completion_Subprogram_Body, "procedure P is",
                      BC.Unit_Subprogram, BC.Unit_Subprogram);
      Add_Completion (Model, 2, BC.Completion_Package_Body, "package body Pkg is",
                      BC.Unit_Package, BC.Unit_Package);
      Add_Completion (Model, 3, BC.Completion_Separate_Body, "separate (Parent) procedure Child is",
                      BC.Unit_Subprogram, BC.Unit_Separate,
                      Placement => BC.Placement_Subunit);
      Add_Completion (Model, 4, BC.Completion_Private_Type_Full_View, "type T is record ...",
                      BC.Unit_Private_Type, BC.Unit_Private_Type,
                      Placement => BC.Placement_Private_Part,
                      Profile => BC.Profile_Not_Applicable);
      Add_Completion (Model, 5, BC.Completion_Deferred_Constant, "C : constant T := ...",
                      BC.Unit_Constant, BC.Unit_Constant,
                      Profile => BC.Profile_Not_Applicable);
      Add_Completion (Model, 6, BC.Completion_Incomplete_Type, "type Node is record ...",
                      BC.Unit_Type, BC.Unit_Type,
                      Profile => BC.Profile_Not_Applicable);

      Results := BC.Build (Model);

      Assert (BC.Result_Count (Results) = 6, "all source-shaped completions should produce rows");
      Assert (BC.Legal_Count (Results) = 6, "body/spec completions should conform");
      Assert (BC.Error_Count (Results) = 0, "accepted completions should not emit blockers");
      Assert (BC.Fingerprint (Results) /= 0, "completion result fingerprint should be stable");
   end Accepts_Source_Shaped_Bodies_Stubs_And_Completions;

   procedure Rejects_Profile_Kind_Region_And_Duplicate_Body_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : BC.Completion_Model;
      Results : BC.Result_Model;
   begin
      Add_Completion (Model, 1, BC.Completion_Subprogram_Body, "P mode mismatch",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Profile => BC.Profile_Mode_Mismatch);
      Add_Completion (Model, 2, BC.Completion_Subprogram_Body, "P type mismatch",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Profile => BC.Profile_Type_Mismatch);
      Add_Completion (Model, 3, BC.Completion_Subprogram_Body, "P default mismatch",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Profile => BC.Profile_Default_Mismatch);
      Add_Completion (Model, 4, BC.Completion_Subprogram_Body, "P null exclusion mismatch",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Profile => BC.Profile_Null_Exclusion_Mismatch);
      Add_Completion (Model, 5, BC.Completion_Subprogram_Body, "P convention mismatch",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Profile => BC.Profile_Convention_Mismatch);
      Add_Completion (Model, 6, BC.Completion_Subprogram_Body, "P result mismatch",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Profile => BC.Profile_Result_Mismatch);
      Add_Completion (Model, 7, BC.Completion_Package_Body, "wrong body kind",
                      BC.Unit_Package, BC.Unit_Subprogram);
      Add_Completion (Model, 8, BC.Completion_Subprogram_Body, "wrong region",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Placement => BC.Placement_Wrong_Region);
      Add_Completion (Model, 9, BC.Completion_Subprogram_Body, "duplicate body",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Duplicate_Body => True);

      Results := BC.Build (Model);

      Assert (BC.Error_Count (Results) = 9, "profile/kind/region/duplicate blockers should reject");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Mode_Mismatch) = 1, "mode conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Type_Mismatch) = 1, "type conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Default_Mismatch) = 1, "default conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Null_Exclusion_Mismatch) = 1, "null exclusion conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Convention_Mismatch) = 1, "convention conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Result_Mismatch) = 1, "result conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Wrong_Completion_Kind) = 1, "wrong completion kind should reject");
      Assert (BC.Count_Status (Results, BC.Legality_Wrong_Region) = 1, "wrong completion region should reject");
      Assert (BC.Count_Status (Results, BC.Legality_Duplicate_Body) = 1, "duplicate body should reject");
   end Rejects_Profile_Kind_Region_And_Duplicate_Body_Blockers;

   procedure Rejects_Generic_Separate_View_Cross_Consumer_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : BC.Completion_Model;
      Results : BC.Result_Model;
   begin
      Add_Completion (Model, 1, BC.Completion_Generic_Package_Body, "generic package body G",
                      BC.Unit_Generic_Package, BC.Unit_Package,
                      Generic_Formals_OK => False);
      Add_Completion (Model, 2, BC.Completion_Generic_Subprogram_Body, "generic procedure body GP",
                      BC.Unit_Generic_Subprogram, BC.Unit_Subprogram,
                      Generic_Body_OK => False);
      Add_Completion (Model, 3, BC.Completion_Separate_Body, "separate body without stub",
                      BC.Unit_Subprogram, BC.Unit_Separate,
                      Placement => BC.Placement_Subunit,
                      Stub_OK => False);
      Add_Completion (Model, 4, BC.Completion_Separate_Body, "separate body parent mismatch",
                      BC.Unit_Subprogram, BC.Unit_Separate,
                      Placement => BC.Placement_Subunit,
                      Parent_OK => False);
      Add_Completion (Model, 5, BC.Completion_Private_Type_Full_View, "private type missing full view",
                      BC.Unit_Private_Type, BC.Unit_Private_Type,
                      Profile => BC.Profile_Not_Applicable,
                      Full_View_OK => False);
      Add_Completion (Model, 6, BC.Completion_Incomplete_Type, "incomplete type not completed",
                      BC.Unit_Type, BC.Unit_Type,
                      Profile => BC.Profile_Not_Applicable,
                      Incomplete_OK => False);
      Add_Completion (Model, 7, BC.Completion_Subprogram_Body, "limited view completion",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      View => BC.View_Limited, Limited_OK => False);
      Add_Completion (Model, 8, BC.Completion_Subprogram_Body, "private view completion",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      View => BC.View_Private, Private_OK => False);
      Add_Completion (Model, 9, BC.Completion_Subprogram_Body, "elaboration blocked",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Elaboration_OK => False);
      Add_Completion (Model, 10, BC.Completion_Subprogram_Body, "stale profile",
                      BC.Unit_Subprogram, BC.Unit_Subprogram,
                      Expected_Profile_FP => 1);

      Results := BC.Build (Model);

      Assert (BC.Error_Count (Results) = 10, "generic/separate/view/consumer/fingerprint blockers should reject");
      Assert (BC.Count_Status (Results, BC.Legality_Generic_Formal_Mismatch) = 1, "generic formal conformance should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Generic_Body_Missing) = 1, "generic body availability should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Separate_Stub_Missing) = 1, "separate bodies need stubs");
      Assert (BC.Count_Status (Results, BC.Legality_Separate_Parent_Mismatch) = 1, "separate parent matching should be checked");
      Assert (BC.Count_Status (Results, BC.Legality_Private_Full_View_Missing) = 1, "private types need full views");
      Assert (BC.Count_Status (Results, BC.Legality_Incomplete_Type_Not_Completed) = 1, "incomplete types need completion");
      Assert (BC.Count_Status (Results, BC.Legality_Limited_View_Barrier) = 1, "limited-view completion barrier should reject");
      Assert (BC.Count_Status (Results, BC.Legality_Private_View_Barrier) = 1, "private-view completion barrier should reject");
      Assert (BC.Count_Status (Results, BC.Legality_Elaboration_Blocker) = 1, "elaboration blockers should remain visible");
      Assert (BC.Count_Status (Results, BC.Legality_Profile_Fingerprint_Mismatch) = 1, "stale profile fingerprints should reject");
   end Rejects_Generic_Separate_View_Cross_Consumer_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Bodies_Stubs_And_Completions'Access,
         "accepts source-shaped bodies stubs and completions");
      Register_Routine
        (T, Rejects_Profile_Kind_Region_And_Duplicate_Body_Blockers'Access,
         "rejects profile kind region and duplicate body blockers");
      Register_Routine
        (T, Rejects_Generic_Separate_View_Cross_Consumer_And_Fingerprint_Blockers'Access,
         "rejects generic separate view cross-consumer and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Body_Spec_Conformance_Vertical_Slice_Legality;
