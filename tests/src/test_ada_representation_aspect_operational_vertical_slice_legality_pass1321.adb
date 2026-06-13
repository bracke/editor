with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality;

package body Test_Ada_Representation_Aspect_Operational_Vertical_Slice_Legality_Pass1321 is

   package RA renames Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality;
   use type RA.Target_Id;
   use type RA.Item_Id;
   use type RA.Result_Id;
   use type RA.Target_Kind;
   use type RA.View_Kind;
   use type RA.Item_Form;
   use type RA.Representation_Item_Kind;
   use type RA.Legality_Status;
   use type RA.Target_Info;
   use type RA.Item_Info;
   use type RA.Result_Info;
   use type RA.Target_Model;
   use type RA.Item_Model;
   use type RA.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Representation_Aspect_Operational_Vertical_Slice_Legality_Pass1321");
   end Name;

   procedure Add_Target
     (Model : in out RA.Target_Model;
      Id : Natural;
      Name : String;
      Kind : RA.Target_Kind := RA.Target_Type;
      View : RA.View_Kind := RA.View_Full;
      Frozen : Boolean := False;
      Freeze_Order : Natural := 0;
      Allows_Representation : Boolean := True;
      Allows_Operational : Boolean := True;
      Source_FP : Natural := 132100;
      Target_FP : Natural := 232100;
      Expected_Source_FP : Natural := 0;
      Expected_Target_FP : Natural := 0)
   is
      T : RA.Target_Info;
   begin
      T.Id := RA.Target_Id (Id);
      T.Name := To_Unbounded_String (Name);
      T.Kind := Kind;
      T.View := View;
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (132100 + Id);
      T.Frozen := Frozen;
      T.Freeze_Order := Freeze_Order;
      T.Allows_Representation := Allows_Representation;
      T.Allows_Operational := Allows_Operational;
      T.Source_Fingerprint := Source_FP + Id;
      T.Target_Fingerprint := Target_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_Target_Fingerprint :=
        (if Expected_Target_FP = 0 then Target_FP + Id else Expected_Target_FP);
      RA.Add_Target (Model, T);
   end Add_Target;

   procedure Add_Item
     (Model : in out RA.Item_Model;
      Id : Natural;
      Target : Natural;
      Kind : RA.Representation_Item_Kind;
      Name : String;
      Form : RA.Item_Form := RA.Form_Aspect;
      Expr : String := "1";
      Required_Kind : RA.Target_Kind := RA.Target_Unknown;
      Placement_Order : Natural := 1;
      Static_OK : Boolean := True;
      Positive_OK : Boolean := True;
      Address_OK : Boolean := True;
      Size_OK : Boolean := True;
      Alignment_OK : Boolean := True;
      Storage_OK : Boolean := True;
      Convention_OK : Boolean := True;
      Import_Export_OK : Boolean := True;
      External_Link_OK : Boolean := True;
      Stream_OK : Boolean := True;
      Volatile_Atomic_OK : Boolean := True;
      Operational_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Source_FP : Natural := 332100;
      Target_FP : Natural := 432100;
      Item_FP : Natural := 532100;
      Expected_Source_FP : Natural := 0;
      Expected_Target_FP : Natural := 0;
      Expected_Item_FP : Natural := 0)
   is
      I : RA.Item_Info;
   begin
      I.Id := RA.Item_Id (Id);
      I.Target := RA.Target_Id (Target);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (232100 + Id);
      I.Form := Form;
      I.Kind := Kind;
      I.Name := To_Unbounded_String (Name);
      I.Expression_Text := To_Unbounded_String (Expr);
      I.Required_Target_Kind := Required_Kind;
      I.Placement_Order := Placement_Order;
      I.Static_Expression := Static_OK;
      I.Positive_Value := Positive_OK;
      I.Address_Expression_Valid := Address_OK;
      I.Size_Expression_Valid := Size_OK;
      I.Alignment_Expression_Valid := Alignment_OK;
      I.Storage_Size_Expression_Valid := Storage_OK;
      I.Convention_Valid := Convention_OK;
      I.Import_Export_Profile_Valid := Import_Export_OK;
      I.External_Link_Name_Valid := External_Link_OK;
      I.Stream_Profile_Valid := Stream_OK;
      I.Volatile_Atomic_Compatible := Volatile_Atomic_OK;
      I.Operational_Attribute_Compatible := Operational_OK;
      I.Requires_Runtime_Check := Runtime_Check;
      I.Source_Fingerprint := Source_FP + Id;
      I.Target_Fingerprint := Target_FP + Id;
      I.Item_Fingerprint := Item_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_Target_Fingerprint :=
        (if Expected_Target_FP = 0 then Target_FP + Id else Expected_Target_FP);
      I.Expected_Item_Fingerprint :=
        (if Expected_Item_FP = 0 then Item_FP + Id else Expected_Item_FP);
      RA.Add_Item (Model, I);
   end Add_Item;

   procedure Accepts_Source_Shaped_Aspects_And_Attribute_Clauses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Targets : RA.Target_Model;
      Items : RA.Item_Model;
      Results : RA.Result_Model;
   begin
      Add_Target (Targets, 1, "T", Kind => RA.Target_Type);
      Add_Target (Targets, 2, "P", Kind => RA.Target_Subprogram);
      Add_Target (Targets, 3, "Obj", Kind => RA.Target_Object);

      Add_Item (Items, 1, 1, RA.Item_Size, "T'Size", Form => RA.Form_Attribute_Definition_Clause,
                Expr => "32", Required_Kind => RA.Target_Type);
      Add_Item (Items, 2, 2, RA.Item_Convention, "Convention => C", Form => RA.Form_Aspect,
                Expr => "C", Required_Kind => RA.Target_Subprogram);
      Add_Item (Items, 3, 3, RA.Item_Address, "Obj'Address", Form => RA.Form_Attribute_Definition_Clause,
                Expr => "System'To_Address (16#1000#)", Required_Kind => RA.Target_Object);
      Add_Item (Items, 4, 1, RA.Item_Volatile, "Volatile", Form => RA.Form_Aspect,
                Runtime_Check => True);

      Results := RA.Build (Targets, Items);
      Assert (RA.Result_Count (Results) = 4, "four representation/operational items expected");
      Assert (RA.Legal_Count (Results) = 4, "all source-shaped items should be legal");
      Assert (RA.Count_Status (Results, RA.Legality_Legal_Runtime_Check) = 1,
              "volatile evidence requiring runtime validation remains legal runtime-check evidence");
   end Accepts_Source_Shaped_Aspects_And_Attribute_Clauses;

   procedure Rejects_Late_Duplicate_And_Conflicting_Unified_Items
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Targets : RA.Target_Model;
      Items : RA.Item_Model;
      Results : RA.Result_Model;
   begin
      Add_Target (Targets, 1, "Frozen_Type", Frozen => True, Freeze_Order => 10);
      Add_Target (Targets, 2, "Unified_Type");
      Add_Target (Targets, 3, "Dup_Type");

      Add_Item (Items, 1, 1, RA.Item_Size, "for Frozen_Type'Size use 32",
                Form => RA.Form_Attribute_Definition_Clause, Placement_Order => 12);
      Add_Item (Items, 2, 2, RA.Item_Alignment, "Alignment => 4",
                Form => RA.Form_Aspect, Expr => "4");
      Add_Item (Items, 3, 2, RA.Item_Alignment, "for Unified_Type'Alignment use 8",
                Form => RA.Form_Attribute_Definition_Clause, Expr => "8");
      Add_Item (Items, 4, 3, RA.Item_Size, "Size => 32", Expr => "32");
      Add_Item (Items, 5, 3, RA.Item_Size, "Size => 32", Expr => "32");

      Results := RA.Build (Targets, Items);
      Assert (RA.Count_Status (Results, RA.Legality_Late_After_Freezing) = 1,
              "representation item after freezing must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Conflicting_Item) = 1,
              "aspect/attribute-definition spelling conflict must be unified and rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Duplicate_Item) = 1,
              "duplicate representation item must be rejected");
   end Rejects_Late_Duplicate_And_Conflicting_Unified_Items;

   procedure Rejects_Operational_Stream_Convention_And_View_Barriers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Targets : RA.Target_Model;
      Items : RA.Item_Model;
      Results : RA.Result_Model;
   begin
      Add_Target (Targets, 1, "P", Kind => RA.Target_Subprogram);
      Add_Target (Targets, 2, "Priv", View => RA.View_Private);
      Add_Target (Targets, 3, "Lim", View => RA.View_Limited);
      Add_Target (Targets, 4, "Formal", View => RA.View_Generic_Formal);

      Add_Item (Items, 1, 1, RA.Item_Convention, "Convention => Bad", Convention_OK => False);
      Add_Item (Items, 2, 1, RA.Item_Import, "Import => True", Import_Export_OK => False);
      Add_Item (Items, 3, 2, RA.Item_Read, "Priv'Read", Stream_OK => True);
      Add_Item (Items, 4, 3, RA.Item_Write, "Lim'Write", Stream_OK => True);
      Add_Item (Items, 5, 4, RA.Item_Size, "Formal'Size");

      Results := RA.Build (Targets, Items);
      Assert (RA.Count_Status (Results, RA.Legality_Invalid_Convention) = 1,
              "invalid convention must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Import_Export_Profile_Mismatch) = 1,
              "Import/Export profile mismatch must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Multiple_Blockers) >= 2,
              "private/limited stream view barriers should preserve combined blockers");
      Assert (RA.Count_Status (Results, RA.Legality_Generic_Formal_Barrier) = 1,
              "generic formal representation target must remain blocked");
   end Rejects_Operational_Stream_Convention_And_View_Barriers;

   procedure Rejects_Static_Value_And_Fingerprint_Mismatches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Targets : RA.Target_Model;
      Items : RA.Item_Model;
      Results : RA.Result_Model;
   begin
      Add_Target (Targets, 1, "T");
      Add_Target (Targets, 2, "Obj", Kind => RA.Target_Object);
      Add_Target (Targets, 3, "Arr", Kind => RA.Target_Type);
      Add_Target (Targets, 4, "Stale");

      Add_Item (Items, 1, 1, RA.Item_Size, "T'Size", Static_OK => False);
      Add_Item (Items, 2, 2, RA.Item_Address, "Obj'Address", Address_OK => False);
      Add_Item (Items, 3, 3, RA.Item_Alignment, "Alignment => 0", Positive_OK => False);
      Add_Item (Items, 4, 4, RA.Item_Storage_Size, "Storage_Size => -1", Storage_OK => False);
      Add_Item (Items, 5, 4, RA.Item_Atomic, "Atomic", Volatile_Atomic_OK => False,
                Expected_Source_FP => 99);

      Results := RA.Build (Targets, Items);
      Assert (RA.Count_Status (Results, RA.Legality_Invalid_Static_Expression) = 1,
              "non-static representation expression must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Invalid_Address) = 1,
              "invalid address expression must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Invalid_Alignment) = 1,
              "invalid alignment must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Invalid_Storage_Size) = 1,
              "invalid storage size must be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Multiple_Blockers) = 1,
              "volatile/atomic and stale source blockers must be preserved together");
   end Rejects_Static_Value_And_Fingerprint_Mismatches;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Accepts_Source_Shaped_Aspects_And_Attribute_Clauses'Access,
                        "accepts source-shaped aspects and attribute-definition clauses");
      Register_Routine (T, Rejects_Late_Duplicate_And_Conflicting_Unified_Items'Access,
                        "rejects late, duplicate, and conflicting unified representation items");
      Register_Routine (T, Rejects_Operational_Stream_Convention_And_View_Barriers'Access,
                        "rejects operational, stream, convention, and view barriers");
      Register_Routine (T, Rejects_Static_Value_And_Fingerprint_Mismatches'Access,
                        "rejects static/value and stale fingerprint mismatches");
   end Register_Tests;

end Test_Ada_Representation_Aspect_Operational_Vertical_Slice_Legality_Pass1321;
