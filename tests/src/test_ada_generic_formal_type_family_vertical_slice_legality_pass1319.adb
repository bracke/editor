with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality;

package body Test_Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality_Pass1319 is

   package GF renames Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality;
   use type GF.Instance_Id;
   use type GF.Formal_Id;
   use type GF.Actual_Id;
   use type GF.Result_Id;
   use type GF.Formal_Type_Family;
   use type GF.Actual_Type_Family;
   use type GF.Formal_Mode;
   use type GF.View_Kind;
   use type GF.Legality_Status;
   use type GF.Formal_Info;
   use type GF.Actual_Info;
   use type GF.Result_Info;
   use type GF.Formal_Model;
   use type GF.Actual_Model;
   use type GF.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality_Pass1319");
   end Name;

   procedure Add_Formal
     (Model : in out GF.Formal_Model;
      Id    : Natural;
      Family : GF.Formal_Type_Family;
      Name  : String;
      Mode  : GF.Formal_Mode := GF.Mode_None;
      Requires_Limited : Boolean := False;
      Requires_Tagged  : Boolean := False;
      Requires_Definite : Boolean := False;
      Allows_Private : Boolean := True;
      Allows_Limited : Boolean := True;
      Has_Discriminants : Boolean := False;
      Disc : String := "";
      Index_Profile : String := "";
      Component : String := "";
      Designated : String := "";
      Profile : String := "";
      Interface_Name : String := "";
      Ancestor : String := "";
      Package_Contract : String := "";
      Subprogram_Profile : String := "";
      Has_Default : Boolean := False;
      Source_FP : Natural := 131900;
      Subst_FP : Natural := 231900;
      Expected_Source_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0)
   is
      F : GF.Formal_Info;
   begin
      F.Id := GF.Formal_Id (Id);
      F.Instance := 1;
      F.Node := Editor.Ada_Syntax_Tree.Node_Id (131900 + Id);
      F.Name := To_Unbounded_String (Name);
      F.Family := Family;
      F.Mode := Mode;
      F.Requires_Limited := Requires_Limited;
      F.Requires_Tagged := Requires_Tagged;
      F.Requires_Definite := Requires_Definite;
      F.Allows_Private_View := Allows_Private;
      F.Allows_Limited_View := Allows_Limited;
      F.Has_Discriminants := Has_Discriminants;
      F.Discriminant_Profile := To_Unbounded_String (Disc);
      F.Array_Index_Profile := To_Unbounded_String (Index_Profile);
      F.Array_Component_Type := To_Unbounded_String (Component);
      F.Access_Designated_Type := To_Unbounded_String (Designated);
      F.Access_Profile := To_Unbounded_String (Profile);
      F.Interface_Name := To_Unbounded_String (Interface_Name);
      F.Ancestor_Type := To_Unbounded_String (Ancestor);
      F.Package_Contract := To_Unbounded_String (Package_Contract);
      F.Subprogram_Profile := To_Unbounded_String (Subprogram_Profile);
      F.Has_Default := Has_Default;
      F.Source_Fingerprint := Source_FP + Id;
      F.Substitution_Fingerprint := Subst_FP + Id;
      F.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      F.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      GF.Add_Formal (Model, F);
   end Add_Formal;

   procedure Add_Actual
     (Model : in out GF.Actual_Model;
      Id    : Natural;
      Formal : Natural;
      Family : GF.Actual_Type_Family;
      Name  : String;
      Mode  : GF.Formal_Mode := GF.Mode_None;
      View  : GF.View_Kind := GF.View_Full;
      Is_Limited : Boolean := False;
      Is_Tagged  : Boolean := False;
      Is_Definite : Boolean := True;
      Has_Discriminants : Boolean := False;
      Disc : String := "";
      Index_Profile : String := "";
      Component : String := "";
      Designated : String := "";
      Profile : String := "";
      Interface_Name : String := "";
      Ancestor : String := "";
      Package_Contract : String := "";
      Subprogram_Profile : String := "";
      Body_Replay : Boolean := True;
      Nested : Boolean := False;
      Cycle  : Boolean := False;
      Source_FP : Natural := 331900;
      Subst_FP : Natural := 431900;
      Expected_Source_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0)
   is
      A : GF.Actual_Info;
   begin
      A.Id := GF.Actual_Id (Id);
      A.Instance := 1;
      A.Formal := GF.Formal_Id (Formal);
      A.Node := Editor.Ada_Syntax_Tree.Node_Id (231900 + Id);
      A.Name := To_Unbounded_String (Name);
      A.Family := Family;
      A.Mode := Mode;
      A.View := View;
      A.Is_Limited := Is_Limited;
      A.Is_Tagged := Is_Tagged;
      A.Is_Definite := Is_Definite;
      A.Has_Discriminants := Has_Discriminants;
      A.Discriminant_Profile := To_Unbounded_String (Disc);
      A.Array_Index_Profile := To_Unbounded_String (Index_Profile);
      A.Array_Component_Type := To_Unbounded_String (Component);
      A.Access_Designated_Type := To_Unbounded_String (Designated);
      A.Access_Profile := To_Unbounded_String (Profile);
      A.Interface_Name := To_Unbounded_String (Interface_Name);
      A.Ancestor_Type := To_Unbounded_String (Ancestor);
      A.Package_Contract := To_Unbounded_String (Package_Contract);
      A.Subprogram_Profile := To_Unbounded_String (Subprogram_Profile);
      A.Body_Replay_Available := Body_Replay;
      A.Nested_Instance := Nested;
      A.Nested_Cycle := Cycle;
      A.Source_Fingerprint := Source_FP + Id;
      A.Substitution_Fingerprint := Subst_FP + Id;
      A.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      A.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      GF.Add_Actual (Model, A);
   end Add_Actual;

   procedure Accepts_Source_Shaped_Formal_Type_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Formals : GF.Formal_Model;
      Actuals : GF.Actual_Model;
      Results : GF.Result_Model;
   begin
      Add_Formal (Formals, 1, GF.Family_Discrete, "type Index is (<>)");
      Add_Actual (Actuals, 1, 1, GF.Actual_Enumeration, "Color");

      Add_Formal (Formals, 2, GF.Family_Array, "type Vec is array (Index) of Element",
                  Index_Profile => "Index", Component => "Element");
      Add_Actual (Actuals, 2, 2, GF.Actual_Array, "Int_Vec",
                  Index_Profile => "Index", Component => "Element");

      Add_Formal (Formals, 3, GF.Family_Access_Subprogram, "with procedure P",
                  Profile => "procedure(Integer)", Subprogram_Profile => "procedure(Integer)");
      Add_Actual (Actuals, 3, 3, GF.Actual_Access_Subprogram, "P'Access",
                  Profile => "procedure(Integer)", Subprogram_Profile => "procedure(Integer)");

      Add_Formal (Formals, 4, GF.Family_Derived, "type T is new Root with private",
                  Requires_Tagged => True, Ancestor => "Root");
      Add_Actual (Actuals, 4, 4, GF.Actual_Derived, "Child",
                  Is_Tagged => True, Ancestor => "Root");

      Results := GF.Build (Formals, Actuals);
      Assert (GF.Result_Count (Results) = 4, "expected four formal/actual results");
      Assert (GF.Legal_Count (Results) = 4, "all source-shaped generic formals should match");
      Assert (GF.Count_Status (Results, GF.Legality_Legal_Exact) >= 3,
              "exact family/profile matches should be accepted");
   end Accepts_Source_Shaped_Formal_Type_Families;

   procedure Rejects_Generic_Formal_Mismatches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Formals : GF.Formal_Model;
      Actuals : GF.Actual_Model;
      Results : GF.Result_Model;
   begin
      Add_Formal (Formals, 1, GF.Family_Modular, "type M is mod <>");
      Add_Actual (Actuals, 1, 1, GF.Actual_Signed_Integer, "Integer");

      Add_Formal (Formals, 2, GF.Family_Tagged_Private, "type T is tagged private",
                  Requires_Tagged => True);
      Add_Actual (Actuals, 2, 2, GF.Actual_Private, "Untagged_Private");

      Add_Formal (Formals, 3, GF.Family_Array, "type A is array (...) of Element",
                  Index_Profile => "Positive", Component => "Element");
      Add_Actual (Actuals, 3, 3, GF.Actual_Array, "Wrong_Array",
                  Index_Profile => "Natural", Component => "Other_Element");

      Add_Formal (Formals, 4, GF.Family_Access_Object, "type Ref is access T",
                  Designated => "T");
      Add_Actual (Actuals, 4, 4, GF.Actual_Access_Object, "Access_U",
                  Designated => "U");

      Results := GF.Build (Formals, Actuals);
      Assert (GF.Error_Count (Results) = 4, "four formal mismatch rows expected");
      Assert (GF.Count_Status (Results, GF.Legality_Formal_Actual_Family_Mismatch) = 1,
              "modular formal must reject signed integer actual");
      Assert (GF.Count_Status (Results, GF.Legality_Taggedness_Mismatch) = 1,
              "tagged private formal must reject untagged actual");
      Assert (GF.Count_Status (Results, GF.Legality_Multiple_Blockers) >= 1,
              "array mismatch should preserve multiple index/component blockers");
      Assert (GF.Count_Status (Results, GF.Legality_Access_Designated_Type_Mismatch) = 1,
              "access designated type mismatch must be reported");
   end Rejects_Generic_Formal_Mismatches;

   procedure Handles_Defaults_Views_Nested_And_Stale_Substitution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Formals : GF.Formal_Model;
      Actuals : GF.Actual_Model;
      Results : GF.Result_Model;
   begin
      Add_Formal (Formals, 1, GF.Family_Private, "type Optional is private",
                  Has_Default => True);

      Add_Formal (Formals, 2, GF.Family_Private, "type Visible is private",
                  Allows_Private => False);
      Add_Actual (Actuals, 2, 2, GF.Actual_Private, "Hidden",
                  View => GF.View_Private);

      Add_Formal (Formals, 3, GF.Family_Private, "type Limited_View is private",
                  Allows_Limited => False);
      Add_Actual (Actuals, 3, 3, GF.Actual_Private, "Limited_View",
                  View => GF.View_Limited);

      Add_Formal (Formals, 4, GF.Family_Private, "type Nested is private");
      Add_Actual (Actuals, 4, 4, GF.Actual_Private, "Nested_Instance_Type",
                  Nested => True);

      Add_Formal (Formals, 5, GF.Family_Private, "type Stale is private",
                  Expected_Subst_FP => 99);
      Add_Actual (Actuals, 5, 5, GF.Actual_Private, "Stale_Type");

      Add_Actual (Actuals, 99, 99, GF.Actual_Private, "Extra_Actual");

      Results := GF.Build (Formals, Actuals);
      Assert (GF.Count_Status (Results, GF.Legality_Legal_Defaulted_Formal) = 1,
              "defaulted formal should be accepted without actual");
      Assert (GF.Count_Status (Results, GF.Legality_Private_View_Barrier) = 1,
              "private-view barrier should be preserved");
      Assert (GF.Count_Status (Results, GF.Legality_Limited_View_Barrier) = 1,
              "limited-view barrier should be preserved");
      Assert (GF.Count_Status (Results, GF.Legality_Legal_Nested_Substitution) = 1,
              "nested substitution should be accepted when fresh and acyclic");
      Assert (GF.Count_Status (Results, GF.Legality_Substitution_Fingerprint_Mismatch) = 1,
              "stale substitution evidence must be rejected");
      Assert (GF.Count_Status (Results, GF.Legality_Extra_Actual) = 1,
              "extra actual without matching formal must be rejected");
   end Handles_Defaults_Views_Nested_And_Stale_Substitution;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Accepts_Source_Shaped_Formal_Type_Families'Access,
                        "accepts source-shaped generic formal type family matches");
      Register_Routine (T, Rejects_Generic_Formal_Mismatches'Access,
                        "rejects formal type family, taggedness, array, and access mismatches");
      Register_Routine (T, Handles_Defaults_Views_Nested_And_Stale_Substitution'Access,
                        "handles defaults, view barriers, nested instances, stale substitution, and extra actuals");
   end Register_Tests;

end Test_Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality_Pass1319;
