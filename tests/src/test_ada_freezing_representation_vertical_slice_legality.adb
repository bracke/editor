with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Freezing_Representation_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Freezing_Representation_Vertical_Slice_Legality is

   package FRL renames Editor.Ada_Freezing_Representation_Vertical_Slice_Legality;
   use type FRL.Type_Id;
   use type FRL.Clause_Id;
   use type FRL.Result_Id;
   use type FRL.Type_View;
   use type FRL.Clause_Kind;
   use type FRL.Freezing_Status;
   use type FRL.Type_Info;
   use type FRL.Clause_Info;
   use type FRL.Result_Info;
   use type FRL.Type_Model;
   use type FRL.Clause_Model;
   use type FRL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Freezing_Representation_Vertical_Slice_Legality");
   end Name;

   procedure Add_Type
     (Types : in out FRL.Type_Model;
      Id    : Natural;
      Node  : Natural;
      Name  : String;
      View  : FRL.Type_View := FRL.View_Ordinary;
      Decl_Order : Natural := 1;
      Freeze_Order : Natural := 100;
      Full_View : Boolean := True;
      Generic_Formal : Boolean := False;
      Generic_Actual_Frozen : Boolean := False;
      Discriminants : Boolean := False;
      Variants : Boolean := False;
      Finalized : Boolean := False;
      Rep_FP : Natural := 400;
      Source_FP : Natural := 500)
   is
      T : FRL.Type_Info;
   begin
      T.Id := FRL.Type_Id (Id);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (Node);
      T.Name := To_Unbounded_String (Name);
      T.View := View;
      T.Declaration_Order := Decl_Order;
      T.Freezing_Order := Freeze_Order;
      T.Full_View_Available := Full_View;
      T.Generic_Formal := Generic_Formal;
      T.Generic_Actual_Frozen := Generic_Actual_Frozen;
      T.Has_Discriminants := Discriminants;
      T.Has_Variants := Variants;
      T.Has_Controlled_Or_Finalized_Component := Finalized;
      T.Representation_Fingerprint := (if Rep_FP = 0 then 0 else Rep_FP + Id);
      T.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      FRL.Add_Type (Types, T);
   end Add_Type;

   procedure Add_Clause
     (Clauses : in out FRL.Clause_Model;
      Id      : Natural;
      Target  : Natural;
      Node    : Natural;
      Kind    : FRL.Clause_Kind;
      Order   : Natural;
      Requires_Full_View : Boolean := False;
      Applies_To_Full_View : Boolean := False;
      Uses_Limited_View : Boolean := False;
      In_Generic_Template : Boolean := False;
      Inherited_Operational : Boolean := False;
      Overrides_Inherited_Operational : Boolean := False;
      Discriminant_Dependent : Boolean := False;
      Variant_Dependent : Boolean := False;
      Finalization_Sensitive : Boolean := False;
      Address_Size_Alignment_Sensitive : Boolean := False;
      Source_FP : Natural := 700;
      Clause_FP : Natural := 800)
   is
      C : FRL.Clause_Info;
   begin
      C.Id := FRL.Clause_Id (Id);
      C.Target := FRL.Type_Id (Target);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (Node);
      C.Kind := Kind;
      C.Clause_Order := Order;
      C.Requires_Full_View := Requires_Full_View;
      C.Applies_To_Full_View := Applies_To_Full_View;
      C.Uses_Limited_View := Uses_Limited_View;
      C.In_Generic_Template := In_Generic_Template;
      C.Inherited_Operational := Inherited_Operational;
      C.Overrides_Inherited_Operational := Overrides_Inherited_Operational;
      C.Discriminant_Dependent := Discriminant_Dependent;
      C.Variant_Dependent := Variant_Dependent;
      C.Finalization_Sensitive := Finalization_Sensitive;
      C.Address_Size_Alignment_Sensitive := Address_Size_Alignment_Sensitive;
      C.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      C.Clause_Fingerprint := (if Clause_FP = 0 then 0 else Clause_FP + Id);
      FRL.Add_Clause (Clauses, C);
   end Add_Clause;

   procedure Accepts_Clauses_Before_Freezing_And_Full_View_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : FRL.Type_Model;
      Clauses : FRL.Clause_Model;
   begin
      --  type R is record ... end record;
      --  for R use record ... end record;       -- before first freezing point
      Add_Type (Types, 1, 129901, "R", Freeze_Order => 50);
      Add_Clause (Clauses, 1, 1, 129911, FRL.Clause_Record_Representation,
                  Order => 20);

      --  private type P has a full view available before the representation
      --  clause targets that full view.
      Add_Type (Types, 2, 129902, "P", View => FRL.View_Private_Full,
                Freeze_Order => 70, Full_View => True);
      Add_Clause (Clauses, 2, 2, 129912, FRL.Clause_Size, Order => 30,
                  Requires_Full_View => True, Applies_To_Full_View => True);

      --  Generic formal representation is accepted while still pre-freeze.
      Add_Type (Types, 3, 129903, "Formal_T", View => FRL.View_Generic_Formal,
                Freeze_Order => 90, Generic_Formal => True);
      Add_Clause (Clauses, 3, 3, 129913, FRL.Clause_Alignment, Order => 40,
                  In_Generic_Template => True);

      --  Inherited operational attributes may be accepted when they do not
      --  simultaneously override conflicting inherited operational evidence.
      Add_Type (Types, 4, 129904, "Derived_T", Freeze_Order => 100);
      Add_Clause (Clauses, 4, 4, 129914, FRL.Clause_Operational_Attribute,
                  Order => 45, Inherited_Operational => True);

      declare
         Model : constant FRL.Result_Model := FRL.Build (Types, Clauses);
      begin
         Assert (FRL.Result_Count (Model) = 4,
                 "each representation clause should produce one freezing row");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Legal_Before_Point) = 1,
                 "ordinary representation clause before freezing should be legal");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Legal_Full_View) = 1,
                 "full-view representation clause should be accepted when full view is available");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Legal_Generic_Pre_Freeze) = 1,
                 "generic formal representation clause should be accepted before formal freezing");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Legal_Operational_Inheritance) = 1,
                 "non-conflicting inherited operational attribute should be accepted");
         Assert (FRL.Legal_Count (Model) = 4,
                 "all concrete pre-freeze representation clauses should be accepted");
      end;
   end Accepts_Clauses_Before_Freezing_And_Full_View_Targets;

   procedure Rejects_Late_Private_Generic_And_Layout_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : FRL.Type_Model;
      Clauses : FRL.Clause_Model;
   begin
      Add_Type (Types, 1, 129921, "Late_T", Freeze_Order => 30);
      Add_Clause (Clauses, 1, 1, 129931, FRL.Clause_Size, Order => 30);

      Add_Type (Types, 2, 129922, "Private_T", View => FRL.View_Private_Partial,
                Freeze_Order => 80, Full_View => False);
      Add_Clause (Clauses, 2, 2, 129932, FRL.Clause_Record_Representation,
                  Order => 20, Requires_Full_View => True);

      Add_Type (Types, 3, 129923, "Formal_T", View => FRL.View_Generic_Formal,
                Freeze_Order => 40, Generic_Formal => True,
                Generic_Actual_Frozen => True);
      Add_Clause (Clauses, 3, 3, 129933, FRL.Clause_Alignment, Order => 20,
                  In_Generic_Template => True);

      Add_Type (Types, 4, 129924, "Limited_T", View => FRL.View_Limited_Private,
                Freeze_Order => 90);
      Add_Clause (Clauses, 4, 4, 129934, FRL.Clause_Stream_Attribute,
                  Order => 10, Uses_Limited_View => True);

      Add_Type (Types, 5, 129925, "Disc_T", Freeze_Order => 100,
                Discriminants => True);
      Add_Clause (Clauses, 5, 5, 129935, FRL.Clause_Record_Representation,
                  Order => 10, Discriminant_Dependent => True);

      Add_Type (Types, 6, 129926, "Variant_T", Freeze_Order => 100,
                Variants => True);
      Add_Clause (Clauses, 6, 6, 129936, FRL.Clause_Record_Representation,
                  Order => 10, Variant_Dependent => True);

      Add_Type (Types, 7, 129927, "Controlled_T", Freeze_Order => 100,
                Finalized => True);
      Add_Clause (Clauses, 7, 7, 129937, FRL.Clause_Size,
                  Order => 10, Finalization_Sensitive => True);

      Add_Type (Types, 8, 129928, "Controlled_Address_T", Freeze_Order => 100,
                Finalized => True);
      Add_Clause (Clauses, 8, 8, 129938, FRL.Clause_At_Address,
                  Order => 10, Address_Size_Alignment_Sensitive => True);

      declare
         Model : constant FRL.Result_Model := FRL.Build (Types, Clauses);
      begin
         Assert (FRL.Count_Status (Model, FRL.Freezing_Late_Representation_Clause) = 1,
                 "representation clause at or after the freezing point should be rejected");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Private_View_Barrier) = 1,
                 "partial private view should block full-view representation clauses");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Generic_Formal_Barrier) = 1,
                 "generic formal representation clause should reject frozen actual/formal evidence");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Stream_Limited_View_Barrier) = 1,
                 "stream attribute should reject limited/private-view evidence");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Discriminant_Layout_Conflict) = 1,
                 "discriminant-dependent record layout conflict should be explicit");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Variant_Layout_Conflict) = 1,
                 "variant-dependent record layout conflict should be explicit");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Finalization_Layout_Conflict) = 1,
                 "controlled/finalized component layout conflict should be explicit");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Address_Size_Alignment_Conflict) = 1,
                 "address/size/alignment conflict should be explicit");
         Assert (FRL.Error_Count (Model) = 8,
                 "all concrete freezing/representation blockers should be counted");
      end;
   end Rejects_Late_Private_Generic_And_Layout_Blockers;

   procedure Reports_Fingerprint_Missing_Target_And_Deterministic_Empty_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Types : FRL.Type_Model;
      Clauses : FRL.Clause_Model;
   begin
      Add_Type (Types, 1, 129941, "Stale_T", Freeze_Order => 90,
                Source_FP => 0);
      Add_Clause (Clauses, 1, 1, 129951, FRL.Clause_Alignment, Order => 10);
      Add_Clause (Clauses, 2, 42, 129952, FRL.Clause_Size, Order => 10);

      declare
         Model : constant FRL.Result_Model := FRL.Build (Types, Clauses);
         Empty_Types : FRL.Type_Model;
         Empty_Clauses : FRL.Clause_Model;
         Empty_Model : constant FRL.Result_Model := FRL.Build (Empty_Types, Empty_Clauses);
      begin
         Assert (FRL.Count_Status (Model, FRL.Freezing_Source_Fingerprint_Mismatch) = 1,
                 "stale source/representation fingerprints should block representation legality");
         Assert (FRL.Count_Status (Model, FRL.Freezing_Missing_Target) = 1,
                 "missing representation target should be explicit");
         Assert (FRL.Result_Count (Empty_Model) = 0,
                 "empty freezing vertical-slice input should produce no rows");
         Assert (not FRL.Has_Result
                   (FRL.First_For_Node
                      (Empty_Model, Editor.Ada_Syntax_Tree.Node_Id (129999))),
                 "absent node lookup should return no result row");
      end;
   end Reports_Fingerprint_Missing_Target_And_Deterministic_Empty_Input;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Clauses_Before_Freezing_And_Full_View_Targets'Access,
         "Pass1299 accepts concrete pre-freeze representation clauses");
      Register_Routine
        (T, Rejects_Late_Private_Generic_And_Layout_Blockers'Access,
         "Pass1299 rejects concrete freezing/private/generic/layout blockers");
      Register_Routine
        (T, Reports_Fingerprint_Missing_Target_And_Deterministic_Empty_Input'Access,
         "Pass1299 reports stale/missing target blockers and deterministic empty input");
   end Register_Tests;

end Test_Ada_Freezing_Representation_Vertical_Slice_Legality;
