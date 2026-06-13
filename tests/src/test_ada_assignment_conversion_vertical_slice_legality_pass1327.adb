with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality;

package body Test_Ada_Assignment_Conversion_Vertical_Slice_Legality_Pass1327 is

   package AC renames Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality;
   use type AC.Entity_Id;
   use type AC.Type_Id;
   use type AC.Check_Id;
   use type AC.Result_Id;
   use type AC.Type_Kind;
   use type AC.View_Kind;
   use type AC.Operation_Kind;
   use type AC.Legality_Status;
   use type AC.Entity_Info;
   use type AC.Type_Info;
   use type AC.Check_Info;
   use type AC.Result_Info;
   use type AC.Entity_Model;
   use type AC.Type_Model;
   use type AC.Check_Model;
   use type AC.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Assignment_Conversion_Vertical_Slice_Legality_Pass1327");
   end Name;

   procedure Add_Type
     (Model : in out AC.Type_Model;
      Id : Natural;
      Name : String;
      Kind : AC.Type_Kind;
      View : AC.View_Kind := AC.View_Full;
      Base : Natural := 0;
      Root : Natural := 0;
      Designated : Natural := 0;
      Tagged_Model : Boolean := False;
      Class_Wide : Boolean := False;
      Numeric : Boolean := False;
      Access_T : Boolean := False;
      Limited_T : Boolean := False;
      Private_T : Boolean := False;
      Conversion_OK : Boolean := True;
      Access_Profile_OK : Boolean := True;
      Source_FP : Natural := 132700;
      Type_FP : Natural := 232700;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      T : AC.Type_Info;
   begin
      T.Id := AC.Type_Id (Id);
      T.Name := To_Unbounded_String (Name);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (132700 + Id);
      T.Kind := Kind;
      T.View := View;
      T.Base_Type := AC.Type_Id (Base);
      T.Root_Type := AC.Type_Id (Root);
      T.Designated_Type := AC.Type_Id (Designated);
      T.Is_Tagged := Tagged_Model;
      T.Is_Class_Wide := Class_Wide;
      T.Is_Numeric := Numeric;
      T.Is_Access := Access_T;
      T.Is_Limited := Limited_T;
      T.Is_Private := Private_T;
      T.Conversion_Profile_Conformant := Conversion_OK;
      T.Access_Profile_Conformant := Access_Profile_OK;
      T.Source_Fingerprint := Source_FP + Id;
      T.Type_Fingerprint := Type_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      AC.Add_Type (Model, T);
   end Add_Type;

   procedure Add_Entity
     (Model : in out AC.Entity_Model;
      Id : Natural;
      Name : String;
      Typ : Natural;
      View : AC.View_Kind := AC.View_Full;
      Variable : Boolean := True;
      Limited_View : Boolean := False;
      Null_Excluding : Boolean := False;
      Accessibility : Natural := 0;
      Controlled_Finalized : Boolean := False;
      Source_FP : Natural := 332700;
      Type_FP : Natural := 432700;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      E : AC.Entity_Info;
   begin
      E.Id := AC.Entity_Id (Id);
      E.Name := To_Unbounded_String (Name);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (232700 + Id);
      E.Typ := AC.Type_Id (Typ);
      E.View := View;
      E.Is_Variable_View := Variable;
      E.Is_Limited_View := Limited_View;
      E.Null_Exclusion := Null_Excluding;
      E.Accessibility_Level := Accessibility;
      E.Controlled_Or_Finalized := Controlled_Finalized;
      E.Source_Fingerprint := Source_FP + Id;
      E.Type_Fingerprint := Type_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      AC.Add_Entity (Model, E);
   end Add_Entity;

   procedure Add_Check
     (Model : in out AC.Check_Model;
      Id : Natural;
      Name : String;
      Operation : AC.Operation_Kind;
      Target : Natural := 0;
      Source : Natural := 0;
      Target_Type : Natural;
      Source_Type : Natural;
      Expected_Type : Natural := 0;
      Explicit : Boolean := False;
      Source_Null : Boolean := False;
      Target_Null_Excluding : Boolean := False;
      Range_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Runtime_Range : Boolean := False;
      Runtime_Predicate : Boolean := False;
      Runtime_Accessibility : Boolean := False;
      Type_OK : Boolean := True;
      View_OK : Boolean := True;
      Class_Wide_OK : Boolean := True;
      Numeric_OK : Boolean := True;
      Access_OK : Boolean := True;
      Controlled_OK : Boolean := True;
      Source_FP : Natural := 532700;
      AST_FP : Natural := 632700;
      Type_FP : Natural := 732700;
      Substitution_FP : Natural := 832700;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0)
   is
      C : AC.Check_Info;
   begin
      C.Id := AC.Check_Id (Id);
      C.Name := To_Unbounded_String (Name);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (332700 + Id);
      C.Operation := Operation;
      C.Target := AC.Entity_Id (Target);
      C.Source := AC.Entity_Id (Source);
      C.Target_Type := AC.Type_Id (Target_Type);
      C.Source_Type := AC.Type_Id (Source_Type);
      C.Expected_Type := AC.Type_Id (Expected_Type);
      C.Explicit_Conversion := Explicit;
      C.Source_Is_Null := Source_Null;
      C.Target_Null_Excluding := Target_Null_Excluding;
      C.Static_Range_OK := Range_OK;
      C.Predicate_OK := Predicate_OK;
      C.Accessibility_OK := Accessibility_OK;
      C.Runtime_Range_Check_Required := Runtime_Range;
      C.Runtime_Predicate_Check_Required := Runtime_Predicate;
      C.Runtime_Accessibility_Check_Required := Runtime_Accessibility;
      C.Type_Compatibility_OK := Type_OK;
      C.View_Conversion_OK := View_OK;
      C.Class_Wide_Conversion_OK := Class_Wide_OK;
      C.Numeric_Conversion_OK := Numeric_OK;
      C.Access_Conversion_OK := Access_OK;
      C.Controlled_Finalization_OK := Controlled_OK;
      C.Source_Fingerprint := Source_FP + Id;
      C.AST_Fingerprint := AST_FP + Id;
      C.Type_Fingerprint := Type_FP + Id;
      C.Substitution_Fingerprint := Substitution_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      C.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      C.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0
         then Substitution_FP + Id
         else Expected_Substitution_FP);
      AC.Add_Check (Model, C);
   end Add_Check;

   procedure Test_Assignment_Legal_And_Runtime_Check

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : AC.Entity_Model;
      Types : AC.Type_Model;
      Checks : AC.Check_Model;
      Results : AC.Result_Model;
   begin
      Add_Type (Types, 1, "Natural", AC.Type_Integer, Numeric => True);
      Add_Entity (Entities, 1, "X", 1);
      Add_Entity (Entities, 2, "Y", 1);
      Add_Check (Checks, 1, "X := Y", AC.Operation_Assignment,
                 Target => 1, Source => 2, Target_Type => 1, Source_Type => 1,
                 Runtime_Range => True);
      Results := AC.Build (Entities, Types, Checks);
      Assert (AC.Result_Count (Results) = 1, "one assignment result expected");
      Assert (AC.Result_At (Results, 1).Status = AC.Legality_Legal_With_Runtime_Check,
              "assignment with dynamic range check remains legal");
      Assert (AC.Legal_Count (Results) = 1, "runtime-check result is legal");
   end Test_Assignment_Legal_And_Runtime_Check;

   procedure Test_Assignment_Target_And_Type_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : AC.Entity_Model;
      Types : AC.Type_Model;
      Checks : AC.Check_Model;
      Results : AC.Result_Model;
   begin
      Add_Type (Types, 1, "Integer", AC.Type_Integer, Numeric => True);
      Add_Type (Types, 2, "Boolean", AC.Type_Scalar);
      Add_Entity (Entities, 1, "C", 1, Variable => False);
      Add_Entity (Entities, 2, "Flag", 2);
      Add_Check (Checks, 1, "C := Flag", AC.Operation_Assignment,
                 Target => 1, Source => 2, Target_Type => 1, Source_Type => 2,
                 Type_OK => False);
      Results := AC.Build (Entities, Types, Checks);
      Assert (AC.Result_At (Results, 1).Status = AC.Legality_Multiple_Blockers,
              "constant target and type mismatch both preserved");
      Assert (AC.Error_Count (Results) = 1, "assignment blocker counted");
   end Test_Assignment_Target_And_Type_Blockers;

   procedure Test_Type_And_Qualified_Expression_Conversion

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : AC.Entity_Model;
      Types : AC.Type_Model;
      Checks : AC.Check_Model;
      Results : AC.Result_Model;
   begin
      Add_Type (Types, 1, "Root_Int", AC.Type_Integer, Root => 1, Numeric => True);
      Add_Type (Types, 2, "Derived_Int", AC.Type_Integer, Root => 1, Numeric => True);
      Add_Check (Checks, 1, "Derived_Int (X)", AC.Operation_Type_Conversion,
                 Target_Type => 2, Source_Type => 1, Explicit => True);
      Add_Check (Checks, 2, "Derived_Int'(X)", AC.Operation_Qualified_Expression,
                 Target_Type => 2, Source_Type => 1);
      Results := AC.Build (Entities, Types, Checks);
      Assert (AC.Result_Count (Results) = 2, "conversion and qualification checked");
      Assert (AC.Result_At (Results, 1).Status = AC.Legality_Legal,
              "explicit related type conversion accepted");
      Assert (AC.Result_At (Results, 2).Status = AC.Legality_Legal,
              "qualified expression accepted for same root family");
   end Test_Type_And_Qualified_Expression_Conversion;

   procedure Test_View_Classwide_Numeric_Access_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : AC.Entity_Model;
      Types : AC.Type_Model;
      Checks : AC.Check_Model;
      Results : AC.Result_Model;
   begin
      Add_Type (Types, 1, "Limited_Record", AC.Type_Record, Limited_T => True);
      Add_Type (Types, 2, "Other_Record", AC.Type_Record);
      Add_Type (Types, 3, "T'Class", AC.Type_Class_Wide, Class_Wide => True, Tagged_Model => True);
      Add_Type (Types, 4, "U", AC.Type_Tagged, Tagged_Model => True);
      Add_Type (Types, 5, "Integer", AC.Type_Integer, Numeric => True);
      Add_Type (Types, 6, "Rec", AC.Type_Record);
      Add_Type (Types, 7, "Access_Int", AC.Type_Access_Object, Access_T => True);
      Add_Type (Types, 8, "Bad_Access", AC.Type_Access_Object, Access_T => True,
                Access_Profile_OK => False);
      Add_Check (Checks, 1, "Limited_View (Obj)", AC.Operation_View_Conversion,
                 Target_Type => 1, Source_Type => 2, Explicit => True);
      Add_Check (Checks, 2, "T'Class (U_Obj)", AC.Operation_Class_Wide_Conversion,
                 Target_Type => 3, Source_Type => 4, Class_Wide_OK => False,
                 Explicit => True);
      Add_Check (Checks, 3, "Integer (R)", AC.Operation_Numeric_Conversion,
                 Target_Type => 5, Source_Type => 6, Explicit => True);
      Add_Check (Checks, 4, "Access_Int (Bad)", AC.Operation_Access_Conversion,
                 Target_Type => 7, Source_Type => 8, Explicit => True);
      Results := AC.Build (Entities, Types, Checks);
      Assert (AC.Count_Status (Results, AC.Legality_View_Conversion_Not_Allowed) = 1,
              "limited view conversion rejected");
      Assert (AC.Count_Status (Results, AC.Legality_Class_Wide_Conversion_Not_Allowed) = 1,
              "class-wide conversion blocker detected");
      Assert (AC.Count_Status (Results, AC.Legality_Numeric_Conversion_Not_Allowed) = 1,
              "numeric conversion requires numeric source and target");
      Assert (AC.Count_Status (Results, AC.Legality_Access_Conversion_Not_Allowed) = 1,
              "access conversion profile mismatch detected");
   end Test_View_Classwide_Numeric_Access_Blockers;

   procedure Test_Null_Accessibility_Range_Predicate_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : AC.Entity_Model;
      Types : AC.Type_Model;
      Checks : AC.Check_Model;
      Results : AC.Result_Model;
   begin
      Add_Type (Types, 1, "Access_T", AC.Type_Access_Object, Access_T => True);
      Add_Type (Types, 2, "Natural", AC.Type_Integer, Numeric => True);
      Add_Entity (Entities, 1, "A", 1);
      Add_Entity (Entities, 2, "Null_Value", 1);
      Add_Check (Checks, 1, "A := null", AC.Operation_Assignment,
                 Target => 1, Source => 2, Target_Type => 1, Source_Type => 1,
                 Source_Null => True, Target_Null_Excluding => True);
      Add_Check (Checks, 2, "A := Local'Access", AC.Operation_Access_Conversion,
                 Target_Type => 1, Source_Type => 1, Explicit => True,
                 Accessibility_OK => False);
      Add_Check (Checks, 3, "Natural (-1)", AC.Operation_Numeric_Conversion,
                 Target_Type => 2, Source_Type => 2, Explicit => True,
                 Range_OK => False);
      Add_Check (Checks, 4, "Subtype_With_Predicate (X)", AC.Operation_Type_Conversion,
                 Target_Type => 2, Source_Type => 2, Explicit => True,
                 Predicate_OK => False);
      Results := AC.Build (Entities, Types, Checks);
      Assert (AC.Count_Status (Results, AC.Legality_Null_Exclusion_Violation) = 1,
              "null exclusion violation detected");
      Assert (AC.Count_Status (Results, AC.Legality_Accessibility_Blocker) = 1,
              "static accessibility escape detected");
      Assert (AC.Count_Status (Results, AC.Legality_Range_Blocker) = 1,
              "range blocker detected");
      Assert (AC.Count_Status (Results, AC.Legality_Predicate_Blocker) = 1,
              "predicate blocker detected");
   end Test_Null_Accessibility_Range_Predicate_Blockers;

   procedure Test_View_Barriers_And_Stale_Fingerprints

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : AC.Entity_Model;
      Types : AC.Type_Model;
      Checks : AC.Check_Model;
      Results : AC.Result_Model;
   begin
      Add_Type (Types, 1, "Private_T", AC.Type_Private, View => AC.View_Private);
      Add_Type (Types, 2, "Integer", AC.Type_Integer, Numeric => True);
      Add_Check (Checks, 1, "Private_T (X)", AC.Operation_Type_Conversion,
                 Target_Type => 1, Source_Type => 2, Explicit => True);
      Add_Check (Checks, 2, "Integer (X stale)", AC.Operation_Type_Conversion,
                 Target_Type => 2, Source_Type => 2, Explicit => True,
                 Expected_AST_FP => 1);
      Results := AC.Build (Entities, Types, Checks);
      Assert (AC.Count_Status (Results, AC.Legality_Private_View_Barrier) = 1,
              "private view barrier retained");
      Assert (AC.Count_Status (Results, AC.Legality_AST_Fingerprint_Mismatch) = 1,
              "stale AST fingerprint rejected");
   end Test_View_Barriers_And_Stale_Fingerprints;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Assignment_Legal_And_Runtime_Check'Access,
         "assignment legality with runtime checks");
      Register_Routine
        (T, Test_Assignment_Target_And_Type_Blockers'Access,
         "assignment target and type blockers");
      Register_Routine
        (T, Test_Type_And_Qualified_Expression_Conversion'Access,
         "type conversions and qualified expressions");
      Register_Routine
        (T, Test_View_Classwide_Numeric_Access_Blockers'Access,
         "view class-wide numeric and access conversion blockers");
      Register_Routine
        (T, Test_Null_Accessibility_Range_Predicate_Blockers'Access,
         "null accessibility range and predicate blockers");
      Register_Routine
        (T, Test_View_Barriers_And_Stale_Fingerprints'Access,
         "view barriers and stale fingerprints");
   end Register_Tests;

end Test_Ada_Assignment_Conversion_Vertical_Slice_Legality_Pass1327;
