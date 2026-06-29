with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality;

package body Test_Ada_Enumeration_Representation_Vertical_Slice_Legality is

   package ER renames Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality;
   use type ER.Enum_Type_Id;
   use type ER.Literal_Id;
   use type ER.Clause_Id;
   use type ER.Result_Id;
   use type ER.Enum_View_Kind;
   use type ER.Enum_Status;
   use type ER.Enum_Type_Info;
   use type ER.Literal_Info;
   use type ER.Representation_Item_Info;
   use type ER.Result_Info;
   use type ER.Enum_Type_Model;
   use type ER.Literal_Model;
   use type ER.Clause_Model;
   use type ER.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Enumeration_Representation_Vertical_Slice_Legality");
   end Name;

   procedure Add_Type
     (Model : in out ER.Enum_Type_Model;
      Id : Natural;
      Name : String;
      Literal_Count : Natural;
      Size_Bits : Natural := 8;
      View : ER.Enum_View_Kind := ER.View_Full;
      Frozen : Boolean := False;
      Freeze_Order : Natural := 0;
      Stream_Attrs : Boolean := False;
      Stream_OK : Boolean := True;
      Existing_Rep : Boolean := False;
      Source_FP : Natural := 132300;
      Type_FP : Natural := 232300;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      T : ER.Enum_Type_Info;
   begin
      T.Id := ER.Enum_Type_Id (Id);
      T.Name := To_Unbounded_String (Name);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (132300 + Id);
      T.View := View;
      T.Literal_Count := Literal_Count;
      T.Size_Bits := Size_Bits;
      T.Frozen := Frozen;
      T.Freeze_Order := Freeze_Order;
      T.Has_Stream_Attributes := Stream_Attrs;
      T.Stream_Profile_Compatible := Stream_OK;
      T.Existing_Representation_Clause := Existing_Rep;
      T.Source_Fingerprint := Source_FP + Id;
      T.Type_Fingerprint := Type_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      ER.Add_Type (Model, T);
   end Add_Type;

   procedure Add_Literal
     (Model : in out ER.Literal_Model;
      Id : Natural;
      Enum_Type : Natural;
      Name : String;
      Order : Natural;
      Source_FP : Natural := 332300;
      Expected_Source_FP : Natural := 0)
   is
      L : ER.Literal_Info;
   begin
      L.Id := ER.Literal_Id (Id);
      L.Enum_Type := ER.Enum_Type_Id (Enum_Type);
      L.Name := To_Unbounded_String (Name);
      L.Declaration_Order := Order;
      L.Source_Fingerprint := Source_FP + Id;
      L.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      ER.Add_Literal (Model, L);
   end Add_Literal;

   procedure Add_Item
     (Model : in out ER.Clause_Model;
      Id : Natural;
      Enum_Type : Natural;
      Literal : Natural;
      Code : Integer;
      Code_Static : Boolean := True;
      Placement_Order : Natural := 1;
      Monotonic : Boolean := True;
      Rep_OK : Boolean := True;
      Source_FP : Natural := 432300;
      Type_FP : Natural := 532300;
      Clause_FP : Natural := 632300;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Clause_FP : Natural := 0)
   is
      I : ER.Representation_Item_Info;
   begin
      I.Id := ER.Clause_Id (Id);
      I.Enum_Type := ER.Enum_Type_Id (Enum_Type);
      I.Literal := ER.Literal_Id (Literal);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (232300 + Id);
      I.Code := Code;
      I.Code_Static := Code_Static;
      I.Placement_Order := Placement_Order;
      I.Requires_Monotonic_Order := Monotonic;
      I.Representation_Compatible := Rep_OK;
      I.Source_Fingerprint := Source_FP + Id;
      I.Type_Fingerprint := Type_FP + Id;
      I.Clause_Fingerprint := Clause_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      I.Expected_Clause_Fingerprint :=
        (if Expected_Clause_FP = 0 then Clause_FP + Id else Expected_Clause_FP);
      ER.Add_Item (Model, I);
   end Add_Item;

   procedure Accepts_Complete_Source_Shaped_Enumeration_Representation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : ER.Enum_Type_Model;
      Literals : ER.Literal_Model;
      Items : ER.Clause_Model;
      Results : ER.Result_Model;
   begin
      Add_Type (Types, 1, "Colour", 3, Size_Bits => 2);
      Add_Literal (Literals, 1, 1, "Red", 1);
      Add_Literal (Literals, 2, 1, "Green", 2);
      Add_Literal (Literals, 3, 1, "Blue", 3);
      Add_Item (Items, 1, 1, 1, 0);
      Add_Item (Items, 2, 1, 2, 1);
      Add_Item (Items, 3, 1, 3, 2);

      Results := ER.Build (Types, Literals, Items);
      Assert (ER.Result_Count (Results) = 3, "three enumeration literal clauses are analysed");
      Assert (ER.Legal_Count (Results) = 3, "complete static representation is legal");
      Assert (ER.Error_Count (Results) = 0, "legal enum rep has no blockers");
   end Accepts_Complete_Source_Shaped_Enumeration_Representation;

   procedure Rejects_Duplicate_Code_And_Missing_Literal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : ER.Enum_Type_Model;
      Literals : ER.Literal_Model;
      Items : ER.Clause_Model;
      Results : ER.Result_Model;
   begin
      Add_Type (Types, 1, "State", 2, Size_Bits => 2);
      Add_Literal (Literals, 1, 1, "Off", 1);
      Add_Literal (Literals, 2, 1, "On", 2);
      Add_Item (Items, 1, 1, 1, 0);
      Add_Item (Items, 2, 1, 2, 0);
      Add_Item (Items, 3, 1, 99, 1);

      Results := ER.Build (Types, Literals, Items);
      Assert (ER.Count_Status (Results, ER.Enum_Duplicate_Code) = 1,
              "duplicate literal representation codes are rejected");
      Assert (ER.Count_Status (Results, ER.Enum_Multiple_Blockers) = 1,
              "extra missing literal keeps precise multiple blocker evidence");
      Assert (ER.Result_At (Results, 3).Missing_Literal_Blockers = 1,
              "missing literal target is preserved");
      Assert (ER.Result_At (Results, 3).Extra_Literal_Blockers = 1,
              "extra clause beyond literal set is preserved");
   end Rejects_Duplicate_Code_And_Missing_Literal;

   procedure Rejects_Late_Nonstatic_And_Out_Of_Size_Codes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : ER.Enum_Type_Model;
      Literals : ER.Literal_Model;
      Items : ER.Clause_Model;
      Results : ER.Result_Model;
   begin
      Add_Type (Types, 1, "Tiny", 2, Size_Bits => 1, Frozen => True, Freeze_Order => 2);
      Add_Literal (Literals, 1, 1, "A", 1);
      Add_Literal (Literals, 2, 1, "B", 2);
      Add_Item (Items, 1, 1, 1, 0, Placement_Order => 1);
      Add_Item (Items, 2, 1, 2, 3, Code_Static => False, Placement_Order => 2);

      Results := ER.Build (Types, Literals, Items);
      Assert (ER.Count_Status (Results, ER.Enum_Multiple_Blockers) = 1,
              "late nonstatic out-of-size code preserves all blockers");
      Assert (ER.Result_At (Results, 2).Late_Freezing_Blockers = 1,
              "representation after freezing is rejected");
      Assert (ER.Result_At (Results, 2).Non_Static_Code_Blockers = 1,
              "nonstatic representation value is rejected");
      Assert (ER.Result_At (Results, 2).Code_Size_Blockers = 1,
              "representation value must fit enum object size");
   end Rejects_Late_Nonstatic_And_Out_Of_Size_Codes;

   procedure Rejects_View_Stream_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : ER.Enum_Type_Model;
      Literals : ER.Literal_Model;
      Items : ER.Clause_Model;
      Results : ER.Result_Model;
   begin
      Add_Type (Types, 1, "Hidden", 1, View => ER.View_Private,
                Stream_Attrs => True, Stream_OK => False,
                Expected_Source_FP => 999999);
      Add_Literal (Literals, 1, 1, "Only", 1);
      Add_Item (Items, 1, 1, 1, 0, Expected_Clause_FP => 999999);

      Results := ER.Build (Types, Literals, Items);
      Assert (ER.Count_Status (Results, ER.Enum_Multiple_Blockers) = 1,
              "private stream and stale evidence combine as multiple blockers");
      Assert (ER.Result_At (Results, 1).Private_View_Blockers = 1,
              "private-view representation target is blocked");
      Assert (ER.Result_At (Results, 1).Stream_Profile_Blockers = 1,
              "stream attribute profile conflict is preserved");
      Assert (ER.Result_At (Results, 1).Source_Fingerprint_Blockers = 1,
              "stale source evidence is rejected");
      Assert (ER.Result_At (Results, 1).Clause_Fingerprint_Blockers = 1,
              "stale clause evidence is rejected");
   end Rejects_View_Stream_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Complete_Source_Shaped_Enumeration_Representation'Access,
         "accepts complete source-shaped enumeration representation");
      Register_Routine
        (T, Rejects_Duplicate_Code_And_Missing_Literal'Access,
         "rejects duplicate codes and missing literal targets");
      Register_Routine
        (T, Rejects_Late_Nonstatic_And_Out_Of_Size_Codes'Access,
         "rejects late nonstatic and out-of-size representation values");
      Register_Routine
        (T, Rejects_View_Stream_And_Fingerprint_Blockers'Access,
         "rejects view stream and stale fingerprint blockers");
   end Register_Tests;

end Test_Ada_Enumeration_Representation_Vertical_Slice_Legality;
