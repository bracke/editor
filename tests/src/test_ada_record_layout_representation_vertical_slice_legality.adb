with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality;

package body Test_Ada_Record_Layout_Representation_Vertical_Slice_Legality is

   package RL renames Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality;
   use type RL.Record_Id;
   use type RL.Component_Id;
   use type RL.Clause_Id;
   use type RL.Result_Id;
   use type RL.Record_View_Kind;
   use type RL.Component_Kind;
   use type RL.Storage_Order_Kind;
   use type RL.Layout_Status;
   use type RL.Record_Info;
   use type RL.Component_Info;
   use type RL.Component_Clause_Info;
   use type RL.Result_Info;
   use type RL.Record_Model;
   use type RL.Component_Model;
   use type RL.Clause_Model;
   use type RL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Record_Layout_Representation_Vertical_Slice_Legality");
   end Name;

   procedure Add_Record
     (Model : in out RL.Record_Model;
      Id : Natural;
      Name : String;
      View : RL.Record_View_Kind := RL.View_Full;
      Frozen : Boolean := False;
      Freeze_Order : Natural := 0;
      Size_Bits : Natural := 128;
      Alignment_Bits : Natural := 8;
      Storage : RL.Storage_Order_Kind := RL.Storage_Default;
      Has_Discriminants : Boolean := False;
      Has_Variants : Boolean := False;
      Has_Controlled : Boolean := False;
      Has_Finalized : Boolean := False;
      Source_FP : Natural := 132200;
      Record_FP : Natural := 232200;
      Expected_Source_FP : Natural := 0;
      Expected_Record_FP : Natural := 0)
   is
      R : RL.Record_Info;
   begin
      R.Id := RL.Record_Id (Id);
      R.Name := To_Unbounded_String (Name);
      R.Node := Editor.Ada_Syntax_Tree.Node_Id (132200 + Id);
      R.View := View;
      R.Frozen := Frozen;
      R.Freeze_Order := Freeze_Order;
      R.Size_Bits := Size_Bits;
      R.Alignment_Bits := Alignment_Bits;
      R.Storage_Order := Storage;
      R.Has_Discriminants := Has_Discriminants;
      R.Has_Variants := Has_Variants;
      R.Has_Controlled_Components := Has_Controlled;
      R.Has_Finalized_Components := Has_Finalized;
      R.Source_Fingerprint := Source_FP + Id;
      R.Record_Fingerprint := Record_FP + Id;
      R.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      R.Expected_Record_Fingerprint :=
        (if Expected_Record_FP = 0 then Record_FP + Id else Expected_Record_FP);
      RL.Add_Record (Model, R);
   end Add_Record;

   procedure Add_Component
     (Model : in out RL.Component_Model;
      Id : Natural;
      Record_Ref : Natural;
      Name : String;
      Kind : RL.Component_Kind := RL.Component_Data;
      Size_Bits : Natural := 8;
      Alignment_Bits : Natural := 8;
      Requires_Discriminant : Boolean := False;
      Active_In_All_Variants : Boolean := True;
      Controlled_Or_Finalized : Boolean := False;
      Source_FP : Natural := 332200;
      Expected_Source_FP : Natural := 0)
   is
      C : RL.Component_Info;
   begin
      C.Id := RL.Component_Id (Id);
      C.Record_Ref := RL.Record_Id (Record_Ref);
      C.Name := To_Unbounded_String (Name);
      C.Kind := Kind;
      C.Size_Bits := Size_Bits;
      C.Alignment_Bits := Alignment_Bits;
      C.Requires_Discriminant_Value := Requires_Discriminant;
      C.Active_In_All_Variants := Active_In_All_Variants;
      C.Controlled_Or_Finalized := Controlled_Or_Finalized;
      C.Source_Fingerprint := Source_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      RL.Add_Component (Model, C);
   end Add_Component;

   procedure Add_Clause
     (Model : in out RL.Clause_Model;
      Id : Natural;
      Record_Ref : Natural;
      Component : Natural;
      Position : Natural;
      First : Natural;
      Last : Natural;
      Placement_Order : Natural := 1;
      Position_Static : Boolean := True;
      Range_Static : Boolean := True;
      Range_Valid : Boolean := True;
      Position_Valid : Boolean := True;
      Alignment_OK : Boolean := True;
      Storage_OK : Boolean := True;
      Discriminant_OK : Boolean := True;
      Variant_OK : Boolean := True;
      Controlled_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Source_FP : Natural := 432200;
      Record_FP : Natural := 532200;
      Clause_FP : Natural := 632200;
      Expected_Source_FP : Natural := 0;
      Expected_Record_FP : Natural := 0;
      Expected_Clause_FP : Natural := 0)
   is
      C : RL.Component_Clause_Info;
   begin
      C.Id := RL.Clause_Id (Id);
      C.Record_Ref := RL.Record_Id (Record_Ref);
      C.Component := RL.Component_Id (Component);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (232200 + Id);
      C.Position_Bits := Position;
      C.First_Bit := First;
      C.Last_Bit := Last;
      C.Placement_Order := Placement_Order;
      C.Position_Static := Position_Static;
      C.Range_Static := Range_Static;
      C.Range_Valid := Range_Valid;
      C.Position_Valid := Position_Valid;
      C.Alignment_Compatible := Alignment_OK;
      C.Storage_Order_Compatible := Storage_OK;
      C.Discriminant_Dependency_Compatible := Discriminant_OK;
      C.Variant_Coverage_Compatible := Variant_OK;
      C.Controlled_Finalized_Compatible := Controlled_OK;
      C.Requires_Runtime_Check := Runtime_Check;
      C.Source_Fingerprint := Source_FP + Id;
      C.Record_Fingerprint := Record_FP + Id;
      C.Clause_Fingerprint := Clause_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_Record_Fingerprint :=
        (if Expected_Record_FP = 0 then Record_FP + Id else Expected_Record_FP);
      C.Expected_Clause_Fingerprint :=
        (if Expected_Clause_FP = 0 then Clause_FP + Id else Expected_Clause_FP);
      RL.Add_Clause (Model, C);
   end Add_Clause;

   procedure Accepts_Source_Shaped_Record_Component_Clauses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Records : RL.Record_Model;
      Components : RL.Component_Model;
      Clauses : RL.Clause_Model;
      Results : RL.Result_Model;
   begin
      Add_Record (Records, 1, "Packet", Size_Bits => 64, Alignment_Bits => 8);
      Add_Component (Components, 1, 1, "Tag", Size_Bits => 8);
      Add_Component (Components, 2, 1, "Length", Size_Bits => 16);
      Add_Clause (Clauses, 1, 1, 1, 0, 0, 7);
      Add_Clause (Clauses, 2, 1, 2, 8, 0, 15);

      Results := RL.Build (Records, Components, Clauses);
      Assert (RL.Result_Count (Results) = 2, "two record clauses are analysed");
      Assert (RL.Legal_Count (Results) = 2, "non-overlapping static layout is legal");
      Assert (RL.Error_Count (Results) = 0, "legal layout has no blockers");
   end Accepts_Source_Shaped_Record_Component_Clauses;

   procedure Rejects_Late_And_Overlapping_Layout_Clauses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Records : RL.Record_Model;
      Components : RL.Component_Model;
      Clauses : RL.Clause_Model;
      Results : RL.Result_Model;
   begin
      Add_Record (Records, 1, "Frozen_Record", Frozen => True, Freeze_Order => 2, Size_Bits => 64);
      Add_Component (Components, 1, 1, "A", Size_Bits => 16);
      Add_Component (Components, 2, 1, "B", Size_Bits => 16);
      Add_Clause (Clauses, 1, 1, 1, 0, 0, 15, Placement_Order => 1);
      Add_Clause (Clauses, 2, 1, 2, 8, 0, 15, Placement_Order => 2);

      Results := RL.Build (Records, Components, Clauses);
      Assert (RL.Count_Status (Results, RL.Layout_Multiple_Blockers) = 1,
              "late overlapping component clause preserves multiple blockers");
      Assert (RL.Result_At (Results, 2).Late_Freezing_Blockers = 1,
              "late clause is rejected after freezing");
      Assert (RL.Result_At (Results, 2).Overlap_Blockers = 1,
              "overlapping component clauses are rejected");
   end Rejects_Late_And_Overlapping_Layout_Clauses;

   procedure Rejects_Discriminant_Variant_And_Controlled_Conflicts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Records : RL.Record_Model;
      Components : RL.Component_Model;
      Clauses : RL.Clause_Model;
      Results : RL.Result_Model;
   begin
      Add_Record (Records, 1, "Plain", Has_Discriminants => False, Has_Variants => False,
                  Has_Controlled => False, Has_Finalized => False);
      Add_Component (Components, 1, 1, "D_Field", Requires_Discriminant => True);
      Add_Component (Components, 2, 1, "Variant_Field", Active_In_All_Variants => False);
      Add_Component (Components, 3, 1, "Ctl", Controlled_Or_Finalized => True);
      Add_Clause (Clauses, 1, 1, 1, 0, 0, 7);
      Add_Clause (Clauses, 2, 1, 2, 8, 0, 7);
      Add_Clause (Clauses, 3, 1, 3, 16, 0, 7);

      Results := RL.Build (Records, Components, Clauses);
      Assert (RL.Count_Status (Results, RL.Layout_Discriminant_Dependency_Conflict) = 1,
              "discriminant-dependent component requires discriminants");
      Assert (RL.Count_Status (Results, RL.Layout_Variant_Coverage_Conflict) = 1,
              "variant-only component requires variant-aware layout evidence");
      Assert (RL.Count_Status (Results, RL.Layout_Controlled_Finalized_Conflict) = 1,
              "controlled/finalized component layout requires matching record evidence");
   end Rejects_Discriminant_Variant_And_Controlled_Conflicts;

   procedure Rejects_View_Barriers_And_Stale_Fingerprints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Records : RL.Record_Model;
      Components : RL.Component_Model;
      Clauses : RL.Clause_Model;
      Results : RL.Result_Model;
   begin
      Add_Record (Records, 1, "Private_Record", View => RL.View_Private);
      Add_Record (Records, 2, "Stale_Record", Expected_Record_FP => 123);
      Add_Component (Components, 1, 1, "A");
      Add_Component (Components, 2, 2, "B");
      Add_Clause (Clauses, 1, 1, 1, 0, 0, 7);
      Add_Clause (Clauses, 2, 2, 2, 0, 0, 7, Expected_Clause_FP => 456);

      Results := RL.Build (Records, Components, Clauses);
      Assert (RL.Count_Status (Results, RL.Layout_Private_View_Barrier) = 1,
              "private view blocks record representation layout");
      Assert (RL.Count_Status (Results, RL.Layout_Multiple_Blockers) = 1,
              "record and clause fingerprint mismatch are both preserved");
      Assert (RL.Result_At (Results, 2).Record_Fingerprint_Blockers = 1,
              "record fingerprint mismatch is tracked");
      Assert (RL.Result_At (Results, 2).Clause_Fingerprint_Blockers = 1,
              "clause fingerprint mismatch is tracked");
   end Rejects_View_Barriers_And_Stale_Fingerprints;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Record_Component_Clauses'Access,
         "accepts source-shaped record representation clauses");
      Register_Routine
        (T, Rejects_Late_And_Overlapping_Layout_Clauses'Access,
         "rejects late and overlapping layout clauses");
      Register_Routine
        (T, Rejects_Discriminant_Variant_And_Controlled_Conflicts'Access,
         "rejects discriminant, variant and controlled layout conflicts");
      Register_Routine
        (T, Rejects_View_Barriers_And_Stale_Fingerprints'Access,
         "rejects view barriers and stale fingerprints");
   end Register_Tests;

end Test_Ada_Record_Layout_Representation_Vertical_Slice_Legality;
