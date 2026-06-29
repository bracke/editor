with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Flow_Refinement_Vertical_Slice_Legality;

package body Test_Ada_Flow_Refinement_Vertical_Slice_Legality is

   package FRL renames Editor.Ada_Flow_Refinement_Vertical_Slice_Legality;
   use type FRL.Entity_Id;
   use type FRL.State_Id;
   use type FRL.Flow_Id;
   use type FRL.Check_Id;
   use type FRL.Result_Id;
   use type FRL.Entity_Kind;
   use type FRL.Flow_Mode;
   use type FRL.Check_Kind;
   use type FRL.View_Kind;
   use type FRL.Legality_Status;
   use type FRL.Entity_Info;
   use type FRL.Entity_Model;
   use type FRL.State_Info;
   use type FRL.State_Model;
   use type FRL.Flow_Info;
   use type FRL.Flow_Model;
   use type FRL.Check_Info;
   use type FRL.Check_Model;
   use type FRL.Result_Info;
   use type FRL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Flow_Refinement_Vertical_Slice_Legality");
   end Name;

   procedure Add_Entity
     (Model : in out FRL.Entity_Model;
      Id : Natural;
      Name : String;
      Kind : FRL.Entity_Kind;
      View : FRL.View_Kind := FRL.View_Full;
      Refined_Global : Boolean := True;
      Refined_Depends : Boolean := True;
      Global_Mode_OK : Boolean := True;
      Depends_OK : Boolean := True;
      Dispatching_Join_OK : Boolean := True;
      Generic_Substitution_OK : Boolean := True;
      Volatile_OK : Boolean := True;
      Atomic_OK : Boolean := True;
      Source_FP : Natural := 1_334_000;
      AST_FP : Natural := 2_334_000;
      State_FP : Natural := 3_334_000;
      Flow_FP : Natural := 4_334_000;
      Profile_FP : Natural := 5_334_000;
      Substitution_FP : Natural := 6_334_000;
      Effect_FP : Natural := 7_334_000;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_State_FP : Natural := 0;
      Expected_Flow_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      E : FRL.Entity_Info;
   begin
      E.Id := FRL.Entity_Id (Id);
      E.Name := To_Unbounded_String (Name);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (133400 + Id);
      E.Kind := Kind;
      E.View := View;
      E.Has_Refined_Global := Refined_Global;
      E.Has_Refined_Depends := Refined_Depends;
      E.Refined_Global_Mode_OK := Global_Mode_OK;
      E.Refined_Depends_OK := Depends_OK;
      E.Dispatching_Effect_Join_OK := Dispatching_Join_OK;
      E.Generic_Substitution_OK := Generic_Substitution_OK;
      E.Volatile_Ordering_OK := Volatile_OK;
      E.Atomic_Ordering_OK := Atomic_OK;
      E.Source_Fingerprint := Source_FP + Id;
      E.AST_Fingerprint := AST_FP + Id;
      E.State_Fingerprint := State_FP + Id;
      E.Flow_Fingerprint := Flow_FP + Id;
      E.Profile_Fingerprint := Profile_FP + Id;
      E.Substitution_Fingerprint := Substitution_FP + Id;
      E.Effect_Fingerprint := Effect_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      E.Expected_State_Fingerprint :=
        (if Expected_State_FP = 0 then State_FP + Id else Expected_State_FP);
      E.Expected_Flow_Fingerprint :=
        (if Expected_Flow_FP = 0 then Flow_FP + Id else Expected_Flow_FP);
      E.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      E.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Substitution_FP + Id else Expected_Substitution_FP);
      E.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      FRL.Add_Entity (Model, E);
   end Add_Entity;

   procedure Add_State
     (Model : in out FRL.State_Model;
      Id : Natural;
      Name : String;
      Owner : Natural;
      View : FRL.View_Kind := FRL.View_Full;
      Mode : FRL.Flow_Mode := FRL.Mode_In_Out;
      Abstract_State : Boolean := True;
      Constituent : Boolean := True;
      Extra : Boolean := False;
      Constituent_Mode_OK : Boolean := True;
      Initialized : Boolean := True;
      Initialization_Order_OK : Boolean := True;
      Source_FP : Natural := 8_334_000;
      AST_FP : Natural := 9_334_000;
      State_FP : Natural := 10_334_000;
      Flow_FP : Natural := 11_334_000;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_State_FP : Natural := 0;
      Expected_Flow_FP : Natural := 0)
   is
      S : FRL.State_Info;
   begin
      S.Id := FRL.State_Id (Id);
      S.Name := To_Unbounded_String (Name);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (233400 + Id);
      S.Owner := FRL.Entity_Id (Owner);
      S.View := View;
      S.Mode := Mode;
      S.Has_Abstract_State := Abstract_State;
      S.Has_Constituent := Constituent;
      S.Constituent_Extra := Extra;
      S.Constituent_Mode_OK := Constituent_Mode_OK;
      S.Initialized := Initialized;
      S.Initialization_Order_OK := Initialization_Order_OK;
      S.Source_Fingerprint := Source_FP + Id;
      S.AST_Fingerprint := AST_FP + Id;
      S.State_Fingerprint := State_FP + Id;
      S.Flow_Fingerprint := Flow_FP + Id;
      S.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      S.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      S.Expected_State_Fingerprint :=
        (if Expected_State_FP = 0 then State_FP + Id else Expected_State_FP);
      S.Expected_Flow_Fingerprint :=
        (if Expected_Flow_FP = 0 then Flow_FP + Id else Expected_Flow_FP);
      FRL.Add_State (Model, S);
   end Add_State;

   procedure Add_Flow
     (Model : in out FRL.Flow_Model;
      Id : Natural;
      Name : String;
      Source : Natural;
      Target : Natural;
      Mode : FRL.Flow_Mode := FRL.Mode_In_Out;
      Source_Present : Boolean := True;
      Target_Present : Boolean := True;
      Cycle : Boolean := False;
      Dependency_OK : Boolean := True;
      Initialization_OK : Boolean := True;
      Volatile_OK : Boolean := True;
      Atomic_OK : Boolean := True;
      Source_FP : Natural := 12_334_000;
      AST_FP : Natural := 13_334_000;
      Flow_FP : Natural := 14_334_000;
      Effect_FP : Natural := 15_334_000;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Flow_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      F : FRL.Flow_Info;
   begin
      F.Id := FRL.Flow_Id (Id);
      F.Name := To_Unbounded_String (Name);
      F.Node := Editor.Ada_Syntax_Tree.Node_Id (333400 + Id);
      F.Source := FRL.State_Id (Source);
      F.Target := FRL.State_Id (Target);
      F.Mode := Mode;
      F.Source_Present := Source_Present;
      F.Target_Present := Target_Present;
      F.Has_Cycle := Cycle;
      F.Data_Dependency_OK := Dependency_OK;
      F.Initialization_OK := Initialization_OK;
      F.Volatile_Ordering_OK := Volatile_OK;
      F.Atomic_Ordering_OK := Atomic_OK;
      F.Source_Fingerprint := Source_FP + Id;
      F.AST_Fingerprint := AST_FP + Id;
      F.Flow_Fingerprint := Flow_FP + Id;
      F.Effect_Fingerprint := Effect_FP + Id;
      F.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      F.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      F.Expected_Flow_Fingerprint :=
        (if Expected_Flow_FP = 0 then Flow_FP + Id else Expected_Flow_FP);
      F.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      FRL.Add_Flow (Model, F);
   end Add_Flow;

   procedure Add_Check
     (Model : in out FRL.Check_Model;
      Id : Natural;
      Name : String;
      Kind : FRL.Check_Kind;
      Operation : Natural := 0;
      State : Natural := 0;
      Flow : Natural := 0;
      Expected_Kind : FRL.Entity_Kind := FRL.Entity_Unknown;
      Expected_Mode : FRL.Flow_Mode := FRL.Mode_Unknown;
      Requires_Global : Boolean := False;
      Requires_Depends : Boolean := False;
      Requires_Source : Boolean := False;
      Requires_Target : Boolean := False;
      Reject_Cycle : Boolean := True;
      Requires_Abstract_State : Boolean := False;
      Requires_Constituent : Boolean := False;
      Reject_Extra : Boolean := True;
      Requires_Initialization : Boolean := False;
      Requires_Dispatching_Join : Boolean := False;
      Requires_Generic_Substitution : Boolean := False;
      Requires_Volatile : Boolean := False;
      Requires_Atomic : Boolean := False;
      Source_FP : Natural := 16_334_000;
      AST_FP : Natural := 17_334_000;
      State_FP : Natural := 18_334_000;
      Flow_FP : Natural := 19_334_000;
      Profile_FP : Natural := 20_334_000;
      Substitution_FP : Natural := 21_334_000;
      Effect_FP : Natural := 22_334_000;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_State_FP : Natural := 0;
      Expected_Flow_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      C : FRL.Check_Info;
   begin
      C.Id := FRL.Check_Id (Id);
      C.Name := To_Unbounded_String (Name);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (433400 + Id);
      C.Kind := Kind;
      C.Operation := FRL.Entity_Id (Operation);
      C.State := FRL.State_Id (State);
      C.Flow := FRL.Flow_Id (Flow);
      C.Expected_Entity_Kind := Expected_Kind;
      C.Expected_Mode := Expected_Mode;
      C.Requires_Refined_Global := Requires_Global;
      C.Requires_Refined_Depends := Requires_Depends;
      C.Requires_Depends_Source := Requires_Source;
      C.Requires_Depends_Target := Requires_Target;
      C.Reject_Depends_Cycle := Reject_Cycle;
      C.Requires_Abstract_State := Requires_Abstract_State;
      C.Requires_Constituent := Requires_Constituent;
      C.Reject_Extra_Constituent := Reject_Extra;
      C.Requires_Initialization := Requires_Initialization;
      C.Requires_Dispatching_Join := Requires_Dispatching_Join;
      C.Requires_Generic_Substitution := Requires_Generic_Substitution;
      C.Requires_Volatile_Ordering := Requires_Volatile;
      C.Requires_Atomic_Ordering := Requires_Atomic;
      C.Source_Fingerprint := Source_FP + Id;
      C.AST_Fingerprint := AST_FP + Id;
      C.State_Fingerprint := State_FP + Id;
      C.Flow_Fingerprint := Flow_FP + Id;
      C.Profile_Fingerprint := Profile_FP + Id;
      C.Substitution_Fingerprint := Substitution_FP + Id;
      C.Effect_Fingerprint := Effect_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      C.Expected_State_Fingerprint :=
        (if Expected_State_FP = 0 then State_FP + Id else Expected_State_FP);
      C.Expected_Flow_Fingerprint :=
        (if Expected_Flow_FP = 0 then Flow_FP + Id else Expected_Flow_FP);
      C.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      C.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Substitution_FP + Id else Expected_Substitution_FP);
      C.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      FRL.Add_Check (Model, C);
   end Add_Check;

   procedure Expect_Status
     (Results : FRL.Result_Model;
      Index : Positive;
      Status : FRL.Legality_Status) is
   begin
      Assert
        (FRL.Result_At (Results, Index).Status = Status,
         "unexpected flow refinement legality status");
   end Expect_Status;

   procedure Test_Refined_Global_And_Depends

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : FRL.Entity_Model;
      States : FRL.State_Model;
      Flows : FRL.Flow_Model;
      Checks : FRL.Check_Model;
      Results : FRL.Result_Model;
   begin
      Add_Entity (Entities, 1, "Update", FRL.Entity_Subprogram,
                  Refined_Global => True, Refined_Depends => True);
      Add_Entity (Entities, 2, "Missing_Global", FRL.Entity_Subprogram,
                  Refined_Global => False, Refined_Depends => True);
      Add_Entity (Entities, 3, "Mode_Mismatch", FRL.Entity_Subprogram,
                  Global_Mode_OK => False);
      Add_State (States, 1, "State", Owner => 1, Mode => FRL.Mode_In_Out);
      Add_Flow (Flows, 1, "In_To_Out", Source => 1, Target => 1);
      Add_Flow (Flows, 2, "Missing_Source", Source => 0, Target => 1,
                Source_Present => False);
      Add_Flow (Flows, 3, "Cycle", Source => 1, Target => 1,
                Cycle => True);

      Add_Check (Checks, 1, "refined global accepted",
                 FRL.Check_Refined_Global, Operation => 1, State => 1,
                 Requires_Global => True, Expected_Mode => FRL.Mode_In_Out);
      Add_Check (Checks, 2, "missing refined global",
                 FRL.Check_Refined_Global, Operation => 2, State => 1,
                 Requires_Global => True);
      Add_Check (Checks, 3, "global mode mismatch",
                 FRL.Check_Refined_Global, Operation => 3, State => 1,
                 Requires_Global => True);
      Add_Check (Checks, 4, "depends missing source",
                 FRL.Check_Refined_Depends, Operation => 1, Flow => 2,
                 Requires_Depends => True, Requires_Source => True,
                 Requires_Target => True);
      Add_Check (Checks, 5, "depends cycle",
                 FRL.Check_Refined_Depends, Operation => 1, Flow => 3,
                 Requires_Depends => True, Requires_Source => True,
                 Requires_Target => True);

      Results := FRL.Build (Entities, States, Flows, Checks);
      Assert (FRL.Count (Results) = 5, "expected five flow refinement checks");
      Expect_Status (Results, 1, FRL.Legality_Legal);
      Expect_Status (Results, 2, FRL.Legality_Refined_Global_Missing);
      Expect_Status (Results, 3, FRL.Legality_Global_Mode_Mismatch);
      Expect_Status (Results, 4, FRL.Legality_Depends_Source_Missing);
      Expect_Status (Results, 5, FRL.Legality_Depends_Cycle);
   end Test_Refined_Global_And_Depends;

   procedure Test_Constituent_Initialization_And_Data_Flow

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : FRL.Entity_Model;
      States : FRL.State_Model;
      Flows : FRL.Flow_Model;
      Checks : FRL.Check_Model;
      Results : FRL.Result_Model;
   begin
      Add_Entity (Entities, 1, "Op", FRL.Entity_Subprogram);
      Add_State (States, 1, "Visible_Part", Owner => 1,
                 Abstract_State => True, Constituent => True);
      Add_State (States, 2, "Missing_Constituent", Owner => 1,
                 Abstract_State => True, Constituent => False);
      Add_State (States, 3, "Extra_Constituent", Owner => 1,
                 Extra => True);
      Add_State (States, 4, "Uninitialized", Owner => 1,
                 Initialized => False);
      Add_State (States, 5, "Wrong_Order", Owner => 1,
                 Initialization_Order_OK => False);
      Add_Flow (Flows, 1, "Bad_Dependency", Source => 1, Target => 2,
                Dependency_OK => False);

      Add_Check (Checks, 1, "constituent accepted",
                 FRL.Check_Abstract_State_Constituent_Flow,
                 Operation => 1, State => 1,
                 Requires_Abstract_State => True, Requires_Constituent => True);
      Add_Check (Checks, 2, "missing constituent",
                 FRL.Check_Abstract_State_Constituent_Flow,
                 Operation => 1, State => 2,
                 Requires_Abstract_State => True, Requires_Constituent => True);
      Add_Check (Checks, 3, "extra constituent",
                 FRL.Check_Abstract_State_Constituent_Flow,
                 Operation => 1, State => 3,
                 Requires_Abstract_State => True, Requires_Constituent => True,
                 Reject_Extra => True);
      Add_Check (Checks, 4, "missing initialization",
                 FRL.Check_Initialization_Flow,
                 Operation => 1, State => 4,
                 Requires_Initialization => True);
      Add_Check (Checks, 5, "initialization order mismatch",
                 FRL.Check_Initialization_Flow,
                 Operation => 1, State => 5,
                 Requires_Initialization => True);
      Add_Check (Checks, 6, "bad data dependency",
                 FRL.Check_Data_Dependency,
                 Operation => 1, Flow => 1,
                 Requires_Source => True, Requires_Target => True);

      Results := FRL.Build (Entities, States, Flows, Checks);
      Expect_Status (Results, 1, FRL.Legality_Legal);
      Expect_Status (Results, 2, FRL.Legality_Constituent_Missing);
      Expect_Status (Results, 3, FRL.Legality_Constituent_Extra);
      Expect_Status (Results, 4, FRL.Legality_Initialization_Missing);
      Expect_Status (Results, 5, FRL.Legality_Initialization_Order_Mismatch);
      Expect_Status (Results, 6, FRL.Legality_Data_Dependency_Mismatch);
   end Test_Constituent_Initialization_And_Data_Flow;

   procedure Test_Dispatching_Generic_And_Ordering

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : FRL.Entity_Model;
      States : FRL.State_Model;
      Flows : FRL.Flow_Model;
      Checks : FRL.Check_Model;
      Results : FRL.Result_Model;
   begin
      Add_Entity (Entities, 1, "Dispatch", FRL.Entity_Dispatching_Operation,
                  Dispatching_Join_OK => True);
      Add_Entity (Entities, 2, "Bad_Dispatch", FRL.Entity_Dispatching_Operation,
                  Dispatching_Join_OK => False);
      Add_Entity (Entities, 3, "Instance", FRL.Entity_Generic_Instance,
                  Generic_Substitution_OK => False);
      Add_Entity (Entities, 4, "Atomic_Update", FRL.Entity_Subprogram,
                  Volatile_OK => False, Atomic_OK => True);
      Add_Flow (Flows, 1, "Atomic_Flow", Source => 0, Target => 0,
                Volatile_OK => True, Atomic_OK => False);

      Add_Check (Checks, 1, "dispatching join accepted",
                 FRL.Check_Dispatching_Effect_Join, Operation => 1,
                 Requires_Dispatching_Join => True);
      Add_Check (Checks, 2, "dispatching join mismatch",
                 FRL.Check_Dispatching_Effect_Join, Operation => 2,
                 Requires_Dispatching_Join => True);
      Add_Check (Checks, 3, "generic substitution mismatch",
                 FRL.Check_Generic_Substitution_Flow, Operation => 3,
                 Requires_Generic_Substitution => True);
      Add_Check (Checks, 4, "volatile ordering mismatch",
                 FRL.Check_Volatile_Atomic_Ordering, Operation => 4,
                 Requires_Volatile => True);
      Add_Check (Checks, 5, "atomic ordering mismatch",
                 FRL.Check_Volatile_Atomic_Ordering, Operation => 4,
                 Flow => 1, Requires_Atomic => True);

      Results := FRL.Build (Entities, States, Flows, Checks);
      Expect_Status (Results, 1, FRL.Legality_Legal);
      Expect_Status (Results, 2, FRL.Legality_Dispatching_Effect_Join_Mismatch);
      Expect_Status (Results, 3, FRL.Legality_Generic_Substitution_Mismatch);
      Expect_Status (Results, 4, FRL.Legality_Volatile_Ordering_Mismatch);
      Expect_Status (Results, 5, FRL.Legality_Atomic_Ordering_Mismatch);
   end Test_Dispatching_Generic_And_Ordering;

   procedure Test_Views_Missing_Evidence_And_Freshness

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : FRL.Entity_Model;
      States : FRL.State_Model;
      Flows : FRL.Flow_Model;
      Checks : FRL.Check_Model;
      Results : FRL.Result_Model;
   begin
      Add_Entity (Entities, 1, "Private_Op", FRL.Entity_Subprogram,
                  View => FRL.View_Private);
      Add_Entity (Entities, 2, "Stale_Op", FRL.Entity_Subprogram,
                  Expected_Effect_FP => 42);
      Add_Entity (Entities, 3, "Full_Op", FRL.Entity_Subprogram);
      Add_State (States, 1, "S", Owner => 1);

      Add_Check (Checks, 1, "private view barrier",
                 FRL.Check_Refined_Global, Operation => 1, State => 1,
                 Requires_Global => True);
      Add_Check (Checks, 2, "stale effect fingerprint",
                 FRL.Check_Refined_Global, Operation => 2,
                 Requires_Global => True);
      Add_Check (Checks, 3, "missing operation",
                 FRL.Check_Refined_Global, Operation => 99,
                 Requires_Global => True);
      Add_Check (Checks, 4, "missing state",
                 FRL.Check_Abstract_State_Constituent_Flow,
                 Operation => 3, State => 99,
                 Requires_Constituent => True);
      Add_Check (Checks, 5, "unknown check",
                 FRL.Check_Unknown, Operation => 3);

      Results := FRL.Build (Entities, States, Flows, Checks);
      Expect_Status (Results, 1, FRL.Legality_Private_View_Barrier);
      Expect_Status (Results, 2, FRL.Legality_Effect_Fingerprint_Mismatch);
      Expect_Status (Results, 3, FRL.Legality_Missing_Entity);
      Expect_Status (Results, 4, FRL.Legality_Missing_State);
      Expect_Status (Results, 5, FRL.Legality_Missing_Check);
   end Test_Views_Missing_Evidence_And_Freshness;

   procedure Test_Empty_Check_Model_Reports_Missing_Check

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : FRL.Entity_Model;
      States : FRL.State_Model;
      Flows : FRL.Flow_Model;
      Checks : FRL.Check_Model;
      Results : FRL.Result_Model;
   begin
      Results := FRL.Build (Entities, States, Flows, Checks);
      Assert (FRL.Count (Results) = 1, "empty flow check model should report one blocker");
      Expect_Status (Results, 1, FRL.Legality_Missing_Check);
   end Test_Empty_Check_Model_Reports_Missing_Check;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Refined_Global_And_Depends'Access,
         "refined global and refined depends legality");
      Register_Routine
        (T, Test_Constituent_Initialization_And_Data_Flow'Access,
         "constituent initialization and data flow legality");
      Register_Routine
        (T, Test_Dispatching_Generic_And_Ordering'Access,
         "dispatching generic substitution and ordering legality");
      Register_Routine
        (T, Test_Views_Missing_Evidence_And_Freshness'Access,
         "views missing evidence and stale fingerprints");
      Register_Routine
        (T, Test_Empty_Check_Model_Reports_Missing_Check'Access,
         "empty check model reports missing check");
   end Register_Tests;

end Test_Ada_Flow_Refinement_Vertical_Slice_Legality;
