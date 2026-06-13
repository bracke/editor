with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Object_Initialization_Default_Vertical_Slice_Legality_Pass1307 is

   package OI renames Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality;
   use type OI.Object_Id;
   use type OI.Result_Id;
   use type OI.Initialization_Kind;
   use type OI.Type_Class;
   use type OI.Legality_Status;
   use type OI.Object_Info;
   use type OI.Result_Info;
   use type OI.Initialization_Model;
   use type OI.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Object_Initialization_Default_Vertical_Slice_Legality_Pass1307");
   end Name;

   procedure Add_Obj
     (Model : in out OI.Initialization_Model;
      Id    : Natural;
      Kind  : OI.Initialization_Kind;
      Text  : String;
      Object_Type : OI.Type_Class := OI.Type_Integer;
      Init_Type   : OI.Type_Class := OI.Type_Integer;
      Expected    : OI.Type_Class := OI.Type_Integer;
      AST : Boolean := True;
      Has_Object_Type : Boolean := True;
      Requires_Init : Boolean := False;
      Has_Init : Boolean := True;
      Has_Default : Boolean := True;
      Default_Legal : Boolean := True;
      Universal_OK : Boolean := True;
      Subtype_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Deferred : Boolean := False;
      Has_Completion : Boolean := True;
      Completion_Type_Matches : Boolean := True;
      Aggregate_Complete : Boolean := True;
      Aggregate_Duplicate : Boolean := False;
      Aggregate_Types_Match : Boolean := True;
      Limited_Type : Boolean := False;
      Limited_Default : Boolean := True;
      Controlled_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Assignment_OK : Boolean := True;
      Source_FP : Natural := 130700;
      AST_FP : Natural := 230700;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0)
   is
      O : OI.Object_Info;
   begin
      O.Id := OI.Object_Id (Id);
      O.Node := Editor.Ada_Syntax_Tree.Node_Id (130700 + Id);
      O.Kind := Kind;
      O.Source_Name := To_Unbounded_String (Text);
      O.Object_Type := Object_Type;
      O.Initializer_Type := Init_Type;
      O.Expected_Type := Expected;
      O.Has_AST_Coverage := AST;
      O.Has_Object_Type := Has_Object_Type;
      O.Requires_Initializer := Requires_Init;
      O.Has_Initializer := Has_Init;
      O.Has_Default_Expression := Has_Default;
      O.Default_Expression_Legal := Default_Legal;
      O.Universal_Compatible := Universal_OK;
      O.Subtype_Range_Legal := Subtype_OK;
      O.Predicate_Legal := Predicate_OK;
      O.Runtime_Predicate_Check_Required := Runtime_Check;
      O.Is_Deferred_Constant := Deferred;
      O.Has_Deferred_Completion := Has_Completion;
      O.Deferred_Completion_Type_Matches := Completion_Type_Matches;
      O.Aggregate_Complete := Aggregate_Complete;
      O.Aggregate_Has_Duplicate_Component := Aggregate_Duplicate;
      O.Aggregate_Component_Types_Match := Aggregate_Types_Match;
      O.Is_Limited_Type := Limited_Type;
      O.Limited_Default_Available := Limited_Default;
      O.Controlled_Finalization_Legal := Controlled_OK;
      O.Accessibility_Legal := Accessibility_OK;
      O.Definite_Assignment_Legal := Assignment_OK;
      O.Source_Fingerprint := Source_FP + Id;
      O.AST_Fingerprint := AST_FP + Id;
      O.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      O.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      OI.Add_Object (Model, O);
   end Add_Obj;

   procedure Accepts_Concrete_Object_Initialization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Objects : OI.Initialization_Model;
      Results : OI.Result_Model;
   begin
      Add_Obj (Objects, 1, OI.Initialization_Object_Declaration,
               "X : Integer := 1");
      Add_Obj (Objects, 2, OI.Initialization_Default_Expression,
               "X : Integer := Default_Value",
               Has_Default => True, Default_Legal => True);
      Add_Obj (Objects, 3, OI.Initialization_Deferred_Constant,
               "C : constant Integer; C : constant Integer := 1",
               Deferred => True, Has_Completion => True,
               Completion_Type_Matches => True);
      Add_Obj (Objects, 4, OI.Initialization_Record_Aggregate,
               "R : Rec := (A => 1, B => 2)",
               Object_Type => OI.Type_Record, Init_Type => OI.Type_Record,
               Expected => OI.Type_Record);
      Add_Obj (Objects, 5, OI.Initialization_Object_Declaration,
               "Y : Integer range 1 .. 10 := Runtime_Checked_Value",
               Runtime_Check => True);

      Results := OI.Build (Objects);

      Assert (OI.Result_Count (Results) = 5, "expected five initialization rows");
      Assert (OI.Count_Status (Results, OI.Legality_Legal) = 4,
              "complete initialization rows should be legal");
      Assert (OI.Count_Status (Results, OI.Legality_Legal_With_Runtime_Check) = 1,
              "runtime predicate check should be preserved as legal with check");
      Assert (OI.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Concrete_Object_Initialization;

   procedure Rejects_Default_Aggregate_Deferred_And_Type_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Objects : OI.Initialization_Model;
      Results : OI.Result_Model;
   begin
      Add_Obj (Objects, 1, OI.Initialization_Object_Declaration,
               "X : Integer",
               Requires_Init => True, Has_Init => False);
      Add_Obj (Objects, 2, OI.Initialization_Default_Expression,
               "X : Integer := Boolean_Default",
               Init_Type => OI.Type_Boolean);
      Add_Obj (Objects, 3, OI.Initialization_Default_Expression,
               "X : Integer := Illegal_Default",
               Default_Legal => False);
      Add_Obj (Objects, 4, OI.Initialization_Deferred_Constant,
               "C : constant Integer",
               Deferred => True, Has_Completion => False);
      Add_Obj (Objects, 5, OI.Initialization_Record_Aggregate,
               "R : Rec := (A => 1)",
               Object_Type => OI.Type_Record, Init_Type => OI.Type_Record,
               Expected => OI.Type_Record, Aggregate_Complete => False);
      Add_Obj (Objects, 6, OI.Initialization_Record_Aggregate,
               "R : Rec := (A => 1, A => 2, B => 3)",
               Object_Type => OI.Type_Record, Init_Type => OI.Type_Record,
               Expected => OI.Type_Record, Aggregate_Duplicate => True);
      Add_Obj (Objects, 7, OI.Initialization_Record_Aggregate,
               "R : Rec := (A => True, B => 3)",
               Object_Type => OI.Type_Record, Init_Type => OI.Type_Record,
               Expected => OI.Type_Record, Aggregate_Types_Match => False);

      Results := OI.Build (Objects);

      Assert (OI.Error_Count (Results) = 7, "all invalid initialization rows should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Missing_Initializer) = 1,
              "required initializer absence should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Type_Mismatch) = 1,
              "initializer type mismatch should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Default_Expression_Blocked) = 1,
              "illegal default expression should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Deferred_Constant_Missing_Completion) = 1,
              "deferred constant without completion should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Aggregate_Component_Missing) = 1,
              "missing aggregate component should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Aggregate_Component_Duplicate) = 1,
              "duplicate aggregate component should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Aggregate_Component_Type_Mismatch) = 1,
              "aggregate component type mismatch should reject");
   end Rejects_Default_Aggregate_Deferred_And_Type_Errors;

   procedure Rejects_Lifetime_Finalization_Assignment_And_Range_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Objects : OI.Initialization_Model;
      Results : OI.Result_Model;
   begin
      Add_Obj (Objects, 1, OI.Initialization_Object_Declaration,
               "L : Limited_Type",
               Object_Type => OI.Type_Limited, Init_Type => OI.Type_Limited,
               Expected => OI.Type_Limited, Limited_Type => True,
               Has_Init => False, Limited_Default => False);
      Add_Obj (Objects, 2, OI.Initialization_Controlled_Object,
               "C : Controlled_Type := Make_Controlled",
               Object_Type => OI.Type_Controlled, Init_Type => OI.Type_Controlled,
               Expected => OI.Type_Controlled, Controlled_OK => False);
      Add_Obj (Objects, 3, OI.Initialization_Access_Object,
               "A : access Integer := Local'Access",
               Object_Type => OI.Type_Access, Init_Type => OI.Type_Access,
               Expected => OI.Type_Access, Accessibility_OK => False);
      Add_Obj (Objects, 4, OI.Initialization_Out_Parameter,
               "out parameter leaves component unassigned",
               Assignment_OK => False);
      Add_Obj (Objects, 5, OI.Initialization_Object_Declaration,
               "X : Small := 99",
               Subtype_OK => False);
      Add_Obj (Objects, 6, OI.Initialization_Object_Declaration,
               "X : Predicated := 3",
               Predicate_OK => False);

      Results := OI.Build (Objects);

      Assert (OI.Count_Status (Results, OI.Legality_Limited_Default_Required) = 1,
              "limited object without available default should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Controlled_Finalization_Blocked) = 1,
              "controlled/finalized initialization blocker should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Accessibility_Blocked) = 1,
              "accessibility blocker should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Definite_Assignment_Blocked) = 1,
              "definite-assignment blocker should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Subtype_Range_Blocked) = 1,
              "subtype range blocker should reject");
      Assert (OI.Count_Status (Results, OI.Legality_Predicate_Blocked) = 1,
              "predicate blocker should reject");
   end Rejects_Lifetime_Finalization_Assignment_And_Range_Blockers;

   procedure Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Objects : OI.Initialization_Model;
      Results : OI.Result_Model;
   begin
      Add_Obj (Objects, 1, OI.Initialization_Object_Declaration,
               "Missing AST initialization",
               AST => False);
      Add_Obj (Objects, 2, OI.Initialization_Object_Declaration,
               "Missing object type",
               Has_Object_Type => False);
      Add_Obj (Objects, 3, OI.Initialization_Object_Declaration,
               "Stale source fingerprint",
               Expected_Source_FP => 99_999);
      Add_Obj (Objects, 4, OI.Initialization_Object_Declaration,
               "Stale AST fingerprint",
               Expected_AST_FP => 88_888);
      Add_Obj (Objects, 5, OI.Initialization_Object_Declaration,
               "Many blockers",
               Requires_Init => True, Has_Init => False,
               Expected_AST_FP => 77_777);
      Add_Obj (Objects, 6, OI.Initialization_Unknown,
               "unknown initialization shape",
               Object_Type => OI.Type_Unknown, Init_Type => OI.Type_Unknown,
               Expected => OI.Type_Unknown);

      Results := OI.Build (Objects);

      Assert (OI.Count_Status (Results, OI.Legality_Missing_AST_Coverage) = 1,
              "missing AST coverage should be classified");
      Assert (OI.Count_Status (Results, OI.Legality_Missing_Object_Type) = 1,
              "missing object type should be classified");
      Assert (OI.Count_Status (Results, OI.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be classified");
      Assert (OI.Count_Status (Results, OI.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be classified");
      Assert (OI.Count_Status (Results, OI.Legality_Multiple_Blockers) = 1,
              "multiple blockers should be preserved");
      Assert (OI.Count_Status (Results, OI.Legality_Indeterminate) = 1,
              "unknown initialization shape should stay indeterminate");
      Assert (OI.Has_Result (OI.Result_At (Results, 1)), "first result should be present");
   end Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Concrete_Object_Initialization'Access,
         "accepts concrete object initialization");
      Register_Routine
        (T, Rejects_Default_Aggregate_Deferred_And_Type_Errors'Access,
         "rejects default, aggregate, deferred, and type errors");
      Register_Routine
        (T, Rejects_Lifetime_Finalization_Assignment_And_Range_Blockers'Access,
         "rejects lifetime, finalization, assignment, and range blockers");
      Register_Routine
        (T, Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers'Access,
         "preserves AST, fingerprint, multiple, and indeterminate blockers");
   end Register_Tests;

end Test_Ada_Object_Initialization_Default_Vertical_Slice_Legality_Pass1307;
