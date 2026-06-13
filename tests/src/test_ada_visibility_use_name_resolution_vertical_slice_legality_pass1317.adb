with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality;

package body Test_Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality_Pass1317 is

   package VN renames Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality;
   use type VN.Lookup_Id;
   use type VN.Result_Id;
   use type VN.Lookup_Kind;
   use type VN.Declaration_Kind;
   use type VN.Region_Kind;
   use type VN.View_Kind;
   use type VN.Visibility_Source;
   use type VN.Legality_Status;
   use type VN.Lookup_Info;
   use type VN.Result_Info;
   use type VN.Lookup_Model;
   use type VN.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality_Pass1317");
   end Name;

   procedure Add_Lookup
     (Model : in out VN.Lookup_Model;
      Id    : Natural;
      Kind  : VN.Lookup_Kind;
      Text  : String;
      Candidate : VN.Declaration_Kind := VN.Decl_Object;
      Expected  : VN.Declaration_Kind := VN.Decl_Unknown;
      Source    : VN.Visibility_Source := VN.Visibility_Direct;
      View      : VN.View_Kind := VN.View_Full;
      AST       : Boolean := True;
      Symbols   : Boolean := True;
      Visible   : Boolean := True;
      Direct    : Boolean := True;
      Use_Visible : Boolean := True;
      Use_Type_Visible : Boolean := True;
      Hidden    : Boolean := False;
      Homograph : Boolean := False;
      Multiple_Use : Boolean := False;
      Ambiguity_Allowed : Boolean := False;
      Prefix_Visible : Boolean := True;
      Selector_Visible : Boolean := True;
      With_Present : Boolean := True;
      Private_Child_Visible : Boolean := True;
      Limited_OK : Boolean := True;
      Private_OK : Boolean := True;
      Incomplete_OK : Boolean := True;
      Generic_Formal_OK : Boolean := True;
      Renaming_OK : Boolean := True;
      Kind_OK : Boolean := True;
      Overload_OK : Boolean := True;
      Source_FP : Natural := 131700;
      Symbol_FP : Natural := 231700;
      Visibility_FP : Natural := 331700;
      View_FP : Natural := 431700;
      Expected_Source_FP : Natural := 0;
      Expected_Symbol_FP : Natural := 0;
      Expected_Visibility_FP : Natural := 0;
      Expected_View_FP : Natural := 0)
   is
      I : VN.Lookup_Info;
   begin
      I.Id := VN.Lookup_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131700 + Id);
      I.Kind := Kind;
      I.Name := To_Unbounded_String (Text);
      I.Region := VN.Region_Package_Body;
      I.Candidate_Kind := Candidate;
      I.Expected_Kind := Expected;
      I.Source := Source;
      I.View := View;
      I.Has_AST_Coverage := AST;
      I.Has_Symbol_Evidence := Symbols;
      I.Has_Visible_Declaration := Visible;
      I.Directly_Visible := Direct;
      I.Use_Clause_Visible := Use_Visible;
      I.Use_Type_Operator_Visible := Use_Type_Visible;
      I.Hidden_By_Inner_Declaration := Hidden;
      I.Homograph_Conflict := Homograph;
      I.Multiple_Use_Candidates := Multiple_Use;
      I.Ambiguity_Allowed_By_Overload := Ambiguity_Allowed;
      I.Selected_Prefix_Visible := Prefix_Visible;
      I.Selected_Selector_Visible := Selector_Visible;
      I.With_Clause_Present := With_Present;
      I.Private_Child_Visible := Private_Child_Visible;
      I.Limited_View_Allows_Use := Limited_OK;
      I.Private_View_Allows_Use := Private_OK;
      I.Incomplete_View_Allows_Use := Incomplete_OK;
      I.Generic_Formal_View_Allows_Use := Generic_Formal_OK;
      I.Renaming_Target_Visible := Renaming_OK;
      I.Declaration_Kind_Compatible := Kind_OK;
      I.Overload_Context_OK := Overload_OK;
      I.Source_Fingerprint := Source_FP + Id;
      I.Symbol_Fingerprint := Symbol_FP + Id;
      I.Visibility_Fingerprint := Visibility_FP + Id;
      I.View_Fingerprint := View_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_Symbol_Fingerprint :=
        (if Expected_Symbol_FP = 0 then Symbol_FP + Id else Expected_Symbol_FP);
      I.Expected_Visibility_Fingerprint :=
        (if Expected_Visibility_FP = 0 then Visibility_FP + Id else Expected_Visibility_FP);
      I.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then View_FP + Id else Expected_View_FP);
      VN.Add_Lookup (Model, I);
   end Add_Lookup;

   procedure Accepts_Source_Shaped_Direct_Use_Selected_And_Operator_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : VN.Lookup_Model;
      Results : VN.Result_Model;
   begin
      Add_Lookup (Model, 1, VN.Lookup_Simple_Name, "Counter",
                  Candidate => VN.Decl_Object, Expected => VN.Decl_Object,
                  Source => VN.Visibility_Direct);
      Add_Lookup (Model, 2, VN.Lookup_Use_Visible_Declaration, "Put_Line",
                  Candidate => VN.Decl_Subprogram, Expected => VN.Decl_Subprogram,
                  Source => VN.Visibility_Use_Package);
      Add_Lookup (Model, 3, VN.Lookup_Use_Visible_Operator, '"' & "+" & '"',
                  Candidate => VN.Decl_Operator, Expected => VN.Decl_Operator,
                  Source => VN.Visibility_Use_Type, Use_Type_Visible => True,
                  Multiple_Use => True, Ambiguity_Allowed => True);
      Add_Lookup (Model, 4, VN.Lookup_Selected_Name, "Pkg.Visible",
                  Candidate => VN.Decl_Object, Prefix_Visible => True,
                  Selector_Visible => True, Source => VN.Visibility_Selected);
      Add_Lookup (Model, 5, VN.Lookup_Private_Child_Unit_Name, "Parent.Private_Child",
                  Candidate => VN.Decl_Private_Child_Unit, With_Present => True,
                  Private_Child_Visible => True, Source => VN.Visibility_With);

      Results := VN.Build (Model);

      Assert (VN.Result_Count (Results) = 5, "all source-shaped lookups should produce rows");
      Assert (VN.Legal_Count (Results) = 5, "direct/use/selected/operator visibility should resolve");
      Assert (VN.Count_Status (Results, VN.Legality_Legal_Ambiguous_Overload_Set) = 1,
              "ambiguous use-visible operator set should remain legal for overload filtering");
      Assert (VN.Error_Count (Results) = 0, "accepted visibility rows should not emit blockers");
      Assert (VN.Fingerprint (Results) /= 0, "visibility result fingerprint should be stable");
   end Accepts_Source_Shaped_Direct_Use_Selected_And_Operator_Visibility;

   procedure Rejects_Hiding_Homographs_Use_And_Selected_Visibility_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : VN.Lookup_Model;
      Results : VN.Result_Model;
   begin
      Add_Lookup (Model, 1, VN.Lookup_Simple_Name, "Hidden_By_Block",
                  Hidden => True);
      Add_Lookup (Model, 2, VN.Lookup_Simple_Name, "Homograph",
                  Homograph => True);
      Add_Lookup (Model, 3, VN.Lookup_Use_Visible_Declaration, "Use_Missing.F",
                  Source => VN.Visibility_Use_Package, Use_Visible => False);
      Add_Lookup (Model, 4, VN.Lookup_Use_Visible_Operator, '"' & "*" & '"',
                  Candidate => VN.Decl_Operator, Source => VN.Visibility_Use_Type,
                  Use_Type_Visible => False);
      Add_Lookup (Model, 5, VN.Lookup_Selected_Name, "Invisible_Pkg.X",
                  Prefix_Visible => False);
      Add_Lookup (Model, 6, VN.Lookup_Selected_Name, "Pkg.Hidden_X",
                  Selector_Visible => False);

      Results := VN.Build (Model);

      Assert (VN.Error_Count (Results) = 6, "visibility blockers should be rejected");
      Assert (VN.Count_Status (Results, VN.Legality_Hidden_By_Inner_Declaration) = 1,
              "inner declaration hiding should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Homograph_Conflict) = 1,
              "non-overloadable homograph conflicts should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Use_Clause_Not_Visible) = 1,
              "use-clause visibility failure should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Use_Type_Operator_Not_Visible) = 1,
              "use type operator visibility failure should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Selected_Prefix_Not_Visible) = 1,
              "selected-name prefix visibility failure should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Selected_Selector_Not_Visible) = 1,
              "selected-name selector visibility failure should be explicit");
   end Rejects_Hiding_Homographs_Use_And_Selected_Visibility_Blockers;

   procedure Rejects_Child_Private_View_Renaming_Kind_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : VN.Lookup_Model;
      Results : VN.Result_Model;
   begin
      Add_Lookup (Model, 1, VN.Lookup_Child_Unit_Name, "Parent.Child",
                  Candidate => VN.Decl_Child_Unit, With_Present => False);
      Add_Lookup (Model, 2, VN.Lookup_Private_Child_Unit_Name, "Parent.Private_Child",
                  Candidate => VN.Decl_Private_Child_Unit,
                  Private_Child_Visible => False);
      Add_Lookup (Model, 3, VN.Lookup_Selected_Name, "Limited_View.T",
                  View => VN.View_Limited, Limited_OK => False);
      Add_Lookup (Model, 4, VN.Lookup_Selected_Name, "Private_View.Hidden",
                  View => VN.View_Private, Private_OK => False);
      Add_Lookup (Model, 5, VN.Lookup_Renamed_Entity, "Alias_Target",
                  Candidate => VN.Decl_Renaming, Renaming_OK => False);
      Add_Lookup (Model, 6, VN.Lookup_Simple_Name, "Wrong_Kind",
                  Candidate => VN.Decl_Package, Expected => VN.Decl_Object);
      Add_Lookup (Model, 7, VN.Lookup_Simple_Name, "Stale_Symbol",
                  Expected_Symbol_FP => 1);

      Results := VN.Build (Model);

      Assert (VN.Error_Count (Results) = 7, "child/view/renaming/kind/fingerprint blockers should reject");
      Assert (VN.Count_Status (Results, VN.Legality_With_Clause_Missing) = 1,
              "missing with clause should block child visibility");
      Assert (VN.Count_Status (Results, VN.Legality_Private_Child_Not_Visible) = 1,
              "private child visibility should be guarded");
      Assert (VN.Count_Status (Results, VN.Legality_Limited_View_Barrier) = 1,
              "limited-view barrier should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Private_View_Barrier) = 1,
              "private-view barrier should be explicit");
      Assert (VN.Count_Status (Results, VN.Legality_Renaming_Target_Not_Visible) = 1,
              "renaming target visibility should be checked");
      Assert (VN.Count_Status (Results, VN.Legality_Wrong_Declaration_Kind) = 1,
              "wrong declaration kind should block lookup");
      Assert (VN.Count_Status (Results, VN.Legality_Symbol_Fingerprint_Mismatch) = 1,
              "stale symbol fingerprints should reject lookup evidence");
   end Rejects_Child_Private_View_Renaming_Kind_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Direct_Use_Selected_And_Operator_Visibility'Access,
         "accepts direct/use/selected/operator visibility");
      Register_Routine
        (T, Rejects_Hiding_Homographs_Use_And_Selected_Visibility_Blockers'Access,
         "rejects hiding homograph use and selected visibility blockers");
      Register_Routine
        (T, Rejects_Child_Private_View_Renaming_Kind_And_Fingerprint_Blockers'Access,
         "rejects child private view renaming kind and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality_Pass1317;
