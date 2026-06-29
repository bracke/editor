with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Selected_Name_Attribute_Vertical_Slice_Legality is

   package SA renames Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality;
   use type SA.Check_Id;
   use type SA.Result_Id;
   use type SA.Reference_Kind;
   use type SA.Entity_Kind;
   use type SA.View_Kind;
   use type SA.Attribute_Class;
   use type SA.Legality_Status;
   use type SA.Reference_Info;
   use type SA.Result_Info;
   use type SA.Reference_Model;
   use type SA.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Selected_Name_Attribute_Vertical_Slice_Legality");
   end Name;

   procedure Add_Check
     (Model : in out SA.Reference_Model;
      Id    : Natural;
      Kind  : SA.Reference_Kind;
      Text  : String;
      Prefix : SA.Entity_Kind := SA.Entity_Object;
      Selected : SA.Entity_Kind := SA.Entity_Component;
      Expected : SA.Entity_Kind := SA.Entity_Unknown;
      View : SA.View_Kind := SA.View_Full;
      Attribute : SA.Attribute_Class := SA.Attribute_None;
      AST : Boolean := True;
      Resolution : Boolean := True;
      Prefix_Visible : Boolean := True;
      Selected_Visible : Boolean := True;
      Composite : Boolean := True;
      Selector_Exists : Boolean := True;
      Ambiguous : Boolean := False;
      Kind_OK : Boolean := True;
      Private_OK : Boolean := True;
      Limited_OK : Boolean := True;
      Incomplete_OK : Boolean := True;
      Generic_Formal_OK : Boolean := True;
      Attribute_Defined : Boolean := True;
      Attribute_Prefix_OK : Boolean := True;
      Attribute_Result_OK : Boolean := True;
      Static_Required : Boolean := False;
      Static_OK : Boolean := True;
      Is_Access : Boolean := True;
      May_Be_Null : Boolean := False;
      Null_Check_OK : Boolean := True;
      Index_Profile_OK : Boolean := True;
      Index_Count_OK : Boolean := True;
      Component_Type_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Representation_OK : Boolean := True;
      Overload_OK : Boolean := True;
      Source_FP : Natural := 131600;
      AST_FP : Natural := 231600;
      Resolution_FP : Natural := 331600;
      View_FP : Natural := 431600;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Resolution_FP : Natural := 0;
      Expected_View_FP : Natural := 0)
   is
      I : SA.Reference_Info;
   begin
      I.Id := SA.Check_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131600 + Id);
      I.Kind := Kind;
      I.Source_Name := To_Unbounded_String (Text);
      I.Prefix_Entity := Prefix;
      I.Selected_Entity := Selected;
      I.Expected_Entity := Expected;
      I.Prefix_View := View;
      I.Attribute := Attribute;
      I.Has_AST_Coverage := AST;
      I.Has_Resolution_Evidence := Resolution;
      I.Prefix_Visible := Prefix_Visible;
      I.Selected_Visible := Selected_Visible;
      I.Prefix_Is_Composite := Composite;
      I.Selector_Exists := Selector_Exists;
      I.Selector_Ambiguous := Ambiguous;
      I.Entity_Kind_Compatible := Kind_OK;
      I.Private_View_Allows_Selection := Private_OK;
      I.Limited_View_Allows_Selection := Limited_OK;
      I.Incomplete_View_Allows_Selection := Incomplete_OK;
      I.Generic_Formal_View_Allows_Selection := Generic_Formal_OK;
      I.Attribute_Defined := Attribute_Defined;
      I.Attribute_Prefix_Allowed := Attribute_Prefix_OK;
      I.Attribute_Result_Type_Compatible := Attribute_Result_OK;
      I.Attribute_Static_Required := Static_Required;
      I.Attribute_Is_Static := Static_OK;
      I.Prefix_Is_Access := Is_Access;
      I.Access_Value_May_Be_Null := May_Be_Null;
      I.Null_Check_Allowed := Null_Check_OK;
      I.Index_Profile_Compatible := Index_Profile_OK;
      I.Index_Count_Compatible := Index_Count_OK;
      I.Component_Type_Compatible := Component_Type_OK;
      I.Accessibility_OK := Accessibility_OK;
      I.Representation_OK := Representation_OK;
      I.Overload_OK := Overload_OK;
      I.Source_Fingerprint := Source_FP + Id;
      I.AST_Fingerprint := AST_FP + Id;
      I.Resolution_Fingerprint := Resolution_FP + Id;
      I.View_Fingerprint := View_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      I.Expected_Resolution_Fingerprint :=
        (if Expected_Resolution_FP = 0 then Resolution_FP + Id else Expected_Resolution_FP);
      I.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then View_FP + Id else Expected_View_FP);
      SA.Add_Reference (Model, I);
   end Add_Check;

   procedure Accepts_Source_Shaped_Selected_Names_Attributes_And_References
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : SA.Reference_Model;
      Results : SA.Result_Model;
   begin
      Add_Check (Model, 1, SA.Reference_Selected_Name,
                 "Pkg.Visible_Component", Prefix => SA.Entity_Package,
                 Selected => SA.Entity_Object, Expected => SA.Entity_Object);
      Add_Check (Model, 2, SA.Reference_Record_Component,
                 "R.Field", Prefix => SA.Entity_Object,
                 Selected => SA.Entity_Component, Expected => SA.Entity_Component);
      Add_Check (Model, 3, SA.Reference_First_Last_Range_Attribute,
                 "Index_Type'First", Prefix => SA.Entity_Type,
                 Selected => SA.Entity_Attribute, Attribute => SA.Attribute_Scalar_Static,
                 Static_Required => True, Static_OK => True);
      Add_Check (Model, 4, SA.Reference_Array_Component,
                 "A (I)", Prefix => SA.Entity_Object,
                 Selected => SA.Entity_Component, Index_Profile_OK => True,
                 Index_Count_OK => True);
      Add_Check (Model, 5, SA.Reference_Generalized_Indexing,
                 "Container (Cursor)", Prefix => SA.Entity_Object,
                 Selected => SA.Entity_Subprogram, Index_Profile_OK => True,
                 Index_Count_OK => True);
      Add_Check (Model, 6, SA.Reference_Explicit_Dereference,
                 "Ptr.all", Prefix => SA.Entity_Access_Value,
                 Selected => SA.Entity_Object, Is_Access => True);

      Results := SA.Build (Model);

      Assert (SA.Result_Count (Results) = 6, "all source-shaped references should produce rows");
      Assert (SA.Legal_Count (Results) = 6, "well-formed references should be legal");
      Assert (SA.Error_Count (Results) = 0, "accepted references should not emit blockers");
      Assert (SA.Fingerprint (Results) /= 0, "result fingerprint should be stable and nonzero");
   end Accepts_Source_Shaped_Selected_Names_Attributes_And_References;

   procedure Rejects_Selection_Visibility_And_View_Barriers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : SA.Reference_Model;
      Results : SA.Result_Model;
   begin
      Add_Check (Model, 1, SA.Reference_Selected_Name,
                 "Hidden_Pkg.X", Prefix_Visible => False);
      Add_Check (Model, 2, SA.Reference_Selected_Name,
                 "Pkg.Hidden", Selected_Visible => False);
      Add_Check (Model, 3, SA.Reference_Record_Component,
                 "Not_Record.Field", Composite => False);
      Add_Check (Model, 4, SA.Reference_Record_Component,
                 "R.No_Such_Field", Selector_Exists => False);
      Add_Check (Model, 5, SA.Reference_Selected_Name,
                 "Ambiguous.Selector", Ambiguous => True);
      Add_Check (Model, 6, SA.Reference_Record_Component,
                 "Private_View.Hidden", View => SA.View_Private,
                 Private_OK => False);
      Add_Check (Model, 7, SA.Reference_Record_Component,
                 "Limited_View.Field", View => SA.View_Limited,
                 Limited_OK => False);
      Add_Check (Model, 8, SA.Reference_Record_Component,
                 "Incomplete_View.Field", View => SA.View_Incomplete,
                 Incomplete_OK => False);

      Results := SA.Build (Model);

      Assert (SA.Count_Status (Results, SA.Legality_Prefix_Not_Visible) = 1,
              "invisible prefixes should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Selected_Entity_Not_Visible) = 1,
              "invisible selected entities should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Prefix_Not_Composite) = 1,
              "component selection requires a composite prefix");
      Assert (SA.Count_Status (Results, SA.Legality_No_Such_Selector) = 1,
              "missing selectors should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Ambiguous_Selector) = 1,
              "ambiguous selectors should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Private_View_Barrier) = 1,
              "private-view selection barrier should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Limited_View_Barrier) = 1,
              "limited-view selection barrier should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Incomplete_View_Barrier) = 1,
              "incomplete-view selection barrier should be preserved");
   end Rejects_Selection_Visibility_And_View_Barriers;

   procedure Rejects_Attribute_Dereference_Indexing_And_Consumer_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : SA.Reference_Model;
      Results : SA.Result_Model;
   begin
      Add_Check (Model, 1, SA.Reference_Attribute,
                 "Obj'Unknown_Attribute", Attribute => SA.Attribute_Unknown,
                 Attribute_Defined => False);
      Add_Check (Model, 2, SA.Reference_Size_Attribute,
                 "Subp'Size", Prefix => SA.Entity_Subprogram,
                 Attribute => SA.Attribute_Size_Alignment,
                 Attribute_Prefix_OK => False);
      Add_Check (Model, 3, SA.Reference_First_Last_Range_Attribute,
                 "Obj'First used as Boolean", Attribute => SA.Attribute_Array_Bounds,
                 Attribute_Result_OK => False);
      Add_Check (Model, 4, SA.Reference_First_Last_Range_Attribute,
                 "Non_Static_Index'First in static context",
                 Attribute => SA.Attribute_Array_Bounds,
                 Static_Required => True, Static_OK => False);
      Add_Check (Model, 5, SA.Reference_Explicit_Dereference,
                 "Not_Access.all", Is_Access => False);
      Add_Check (Model, 6, SA.Reference_Array_Component,
                 "A (I, J)", Index_Count_OK => False);
      Add_Check (Model, 7, SA.Reference_Generalized_Indexing,
                 "Container (Bad_Cursor)", Index_Profile_OK => False);
      Add_Check (Model, 8, SA.Reference_Record_Component,
                 "R.Field_Wrong_Type", Component_Type_OK => False);
      Add_Check (Model, 9, SA.Reference_Access_Attribute,
                 "Local'Access escapes", Attribute => SA.Attribute_Access,
                 Accessibility_OK => False);
      Add_Check (Model, 10, SA.Reference_Address_Attribute,
                 "Obj'Address blocked by representation", Attribute => SA.Attribute_Address,
                 Representation_OK => False);
      Add_Check (Model, 11, SA.Reference_Callable_Entity,
                 "Pkg.F selected overload blocked", Selected => SA.Entity_Subprogram,
                 Overload_OK => False);
      Add_Check (Model, 12, SA.Reference_Implicit_Dereference,
                 "Maybe_Null.Component", Prefix => SA.Entity_Access_Value,
                 Is_Access => True, May_Be_Null => True, Null_Check_OK => True);

      Results := SA.Build (Model);

      Assert (SA.Count_Status (Results, SA.Legality_Attribute_Not_Defined) = 1,
              "undefined attributes should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Attribute_Prefix_Not_Allowed) = 1,
              "attributes must accept their prefix kind");
      Assert (SA.Count_Status (Results, SA.Legality_Attribute_Result_Type_Mismatch) = 1,
              "attribute result type mismatch should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Attribute_Not_Static) = 1,
              "nonstatic attribute in static context should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Dereference_Non_Access) = 1,
              "dereference requires an access prefix");
      Assert (SA.Count_Status (Results, SA.Legality_Index_Count_Mismatch) = 1,
              "index dimension mismatch should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Index_Profile_Mismatch) = 1,
              "generalized indexing profile mismatch should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Component_Type_Mismatch) = 1,
              "component type mismatch should be rejected");
      Assert (SA.Count_Status (Results, SA.Legality_Accessibility_Blocker) = 1,
              "accessibility blockers should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Representation_Blocker) = 1,
              "representation blockers should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Overload_Blocker) = 1,
              "overload blockers should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Legal_Runtime_Check) = 1,
              "null implicit dereference should remain legal with runtime check");
   end Rejects_Attribute_Dereference_Indexing_And_Consumer_Blockers;

   procedure Preserves_Evidence_Fingerprint_And_Multiple_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : SA.Reference_Model;
      Results : SA.Result_Model;
   begin
      Add_Check (Model, 1, SA.Reference_Selected_Name,
                 "token-only selected name", AST => False);
      Add_Check (Model, 2, SA.Reference_Selected_Name,
                 "selection without resolution evidence", Resolution => False);
      Add_Check (Model, 3, SA.Reference_Selected_Name,
                 "wrong entity kind", Selected => SA.Entity_Exception,
                 Expected => SA.Entity_Object, Kind_OK => False);
      Add_Check (Model, 4, SA.Reference_Record_Component,
                 "generic formal full view unavailable", View => SA.View_Generic_Formal,
                 Generic_Formal_OK => False);
      Add_Check (Model, 5, SA.Reference_Selected_Name,
                 "stale source fingerprint", Expected_Source_FP => 999999);
      Add_Check (Model, 6, SA.Reference_Selected_Name,
                 "stale ast fingerprint", Expected_AST_FP => 999999);
      Add_Check (Model, 7, SA.Reference_Selected_Name,
                 "stale resolution fingerprint", Expected_Resolution_FP => 999999);
      Add_Check (Model, 8, SA.Reference_Selected_Name,
                 "stale view fingerprint", Expected_View_FP => 999999);
      Add_Check (Model, 9, SA.Reference_Record_Component,
                 "private view and missing selector", View => SA.View_Private,
                 Private_OK => False, Selector_Exists => False);

      Results := SA.Build (Model);

      Assert (SA.Count_Status (Results, SA.Legality_Missing_AST_Coverage) = 1,
              "AST coverage blocker should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Missing_Resolution_Evidence) = 1,
              "resolution evidence blocker should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Wrong_Entity_Kind) = 1,
              "entity-kind blocker should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Generic_Formal_View_Barrier) = 1,
              "generic formal view barrier should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Resolution_Fingerprint_Mismatch) = 1,
              "resolution fingerprint mismatch should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_View_Fingerprint_Mismatch) = 1,
              "view fingerprint mismatch should be preserved");
      Assert (SA.Count_Status (Results, SA.Legality_Multiple_Blockers) = 1,
              "multiple selected-name blockers should remain grouped");
   end Preserves_Evidence_Fingerprint_And_Multiple_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Selected_Names_Attributes_And_References'Access,
         "accepts source-shaped selected names, attributes, and references");
      Register_Routine
        (T, Rejects_Selection_Visibility_And_View_Barriers'Access,
         "rejects selection visibility and view barriers");
      Register_Routine
        (T, Rejects_Attribute_Dereference_Indexing_And_Consumer_Blockers'Access,
         "rejects attribute, dereference, indexing, and consumer blockers");
      Register_Routine
        (T, Preserves_Evidence_Fingerprint_And_Multiple_Blockers'Access,
         "preserves evidence, fingerprint, and multiple blockers");
   end Register_Tests;

end Test_Ada_Selected_Name_Attribute_Vertical_Slice_Legality;
