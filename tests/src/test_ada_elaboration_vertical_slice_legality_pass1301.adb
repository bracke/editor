with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Elaboration_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Vertical_Slice_Legality_Pass1301 is

   package EL renames Editor.Ada_Elaboration_Vertical_Slice_Legality;
   use type EL.Unit_Id;
   use type EL.Edge_Id;
   use type EL.Call_Id;
   use type EL.Result_Id;
   use type EL.Unit_Kind;
   use type EL.Dependency_Kind;
   use type EL.Call_Kind;
   use type EL.Elaboration_Status;
   use type EL.Unit_Info;
   use type EL.Dependency_Info;
   use type EL.Call_Info;
   use type EL.Result_Info;
   use type EL.Unit_Model;
   use type EL.Dependency_Model;
   use type EL.Call_Model;
   use type EL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Elaboration_Vertical_Slice_Legality_Pass1301");
   end Name;

   procedure Add_Unit
     (Units : in out EL.Unit_Model;
      Id    : Natural;
      Kind  : EL.Unit_Kind;
      Name  : String;
      Has_Body : Boolean := True;
      Body_Before_Use : Boolean := True;
      Preelaborated : Boolean := False;
      Pure : Boolean := False;
      Elaborate : Boolean := False;
      Elaborate_All : Boolean := False;
      Generic_Unit : Boolean := False;
      Generic_Body : Boolean := True;
      Limited_View : Boolean := False;
      Private_View : Boolean := False;
      Separate_Body : Boolean := False;
      Separate_Linked : Boolean := True;
      Source_FP : Natural := 130100;
      Dep_FP : Natural := 230100)
   is
      U : EL.Unit_Info;
   begin
      U.Id := EL.Unit_Id (Id);
      U.Body_Id := (if Kind in EL.Unit_Package_Spec | EL.Unit_Subprogram_Spec | EL.Unit_Generic_Spec
                    then EL.Unit_Id (Id + 100) else EL.No_Unit);
      U.Spec_Id := (if Kind in EL.Unit_Package_Body | EL.Unit_Subprogram_Body | EL.Unit_Generic_Body
                    and then Id > 100
                    then EL.Unit_Id (Id - 100) else EL.No_Unit);
      U.Node := Editor.Ada_Syntax_Tree.Node_Id (130100 + Id);
      U.Kind := Kind;
      U.Name := To_Unbounded_String (Name);
      U.Has_Body := Has_Body;
      U.Body_Elaborated_Before_Use := Body_Before_Use;
      U.Is_Preelaborated := Preelaborated;
      U.Is_Pure := Pure;
      U.Has_Elaborate := Elaborate;
      U.Has_Elaborate_All := Elaborate_All;
      U.Is_Generic := Generic_Unit;
      U.Generic_Body_Available := Generic_Body;
      U.Is_Limited_View := Limited_View;
      U.Is_Private_View := Private_View;
      U.Is_Separate_Body := Separate_Body;
      U.Separate_Linked := Separate_Linked;
      U.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      U.Dependency_Fingerprint := (if Dep_FP = 0 then 0 else Dep_FP + Id);
      EL.Add_Unit (Units, U);
   end Add_Unit;

   procedure Add_Dep
     (Deps : in out EL.Dependency_Model;
      Id   : Natural;
      From_Unit : Natural;
      To_Unit   : Natural;
      Kind : EL.Dependency_Kind;
      Transitive : Boolean := False;
      Cyclic : Boolean := False;
      Limited_View : Boolean := False;
      Private_View : Boolean := False;
      Source_FP : Natural := 130100;
      Dep_FP : Natural := 230100)
   is
      D : EL.Dependency_Info;
   begin
      D.Id := EL.Edge_Id (Id);
      D.From_Unit := EL.Unit_Id (From_Unit);
      D.To_Unit := EL.Unit_Id (To_Unit);
      D.Node := Editor.Ada_Syntax_Tree.Node_Id (130300 + Id);
      D.Kind := Kind;
      D.Is_Transitive := Transitive;
      D.Is_Cyclic := Cyclic;
      D.Is_Limited_View := Limited_View;
      D.Is_Private_View := Private_View;
      D.Source_Fingerprint := Source_FP + From_Unit;
      D.Dependency_Fingerprint := Dep_FP + To_Unit;
      EL.Add_Dependency (Deps, D);
   end Add_Dep;

   procedure Add_Call
     (Calls : in out EL.Call_Model;
      Id    : Natural;
      Caller : Natural;
      Callee : Natural;
      Kind : EL.Call_Kind;
      Needs_Body : Boolean := True;
      Needs_Elaborate_All : Boolean := False;
      In_Preelaborated : Boolean := False;
      In_Pure : Boolean := False;
      Generic_Instance : Boolean := False;
      Separate_Body : Boolean := False;
      Caller_FP : Natural := 130100;
      Callee_FP : Natural := 130100;
      Dep_FP : Natural := 230100;
      Call_FP : Natural := 330100)
   is
      C : EL.Call_Info;
   begin
      C.Id := EL.Call_Id (Id);
      C.Caller := EL.Unit_Id (Caller);
      C.Callee := EL.Unit_Id (Callee);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (130500 + Id);
      C.Kind := Kind;
      C.Requires_Body_Before_Call := Needs_Body;
      C.Requires_Elaborate_All := Needs_Elaborate_All;
      C.Occurs_In_Preelaborated_Unit := In_Preelaborated;
      C.Occurs_In_Pure_Unit := In_Pure;
      C.Through_Generic_Instance := Generic_Instance;
      C.Through_Separate_Body := Separate_Body;
      C.Expected_Caller_Fingerprint := (if Caller_FP = 0 then 0 else Caller_FP + Caller);
      C.Expected_Callee_Fingerprint := (if Callee_FP = 0 then 0 else Callee_FP + Callee);
      C.Expected_Dependency_Fingerprint := (if Dep_FP = 0 then 0 else Dep_FP + Callee);
      C.Source_Fingerprint := (if Caller_FP = 0 then 0 else Caller_FP + Caller);
      C.Call_Fingerprint := (if Call_FP = 0 then 0 else Call_FP + Id);
      EL.Add_Call (Calls, C);
   end Add_Call;

   procedure Accepts_Body_Elaborated_And_Pragma_Protected_Calls
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Units : EL.Unit_Model;
      Deps  : EL.Dependency_Model;
      Calls : EL.Call_Model;
   begin
      Add_Unit (Units, 1, EL.Unit_Package_Body, "Client");
      Add_Unit (Units, 2, EL.Unit_Package_Body, "Service", Body_Before_Use => True);
      Add_Call (Calls, 1, 1, 2, EL.Call_Package_Body_Elaboration);

      Add_Unit (Units, 3, EL.Unit_Package_Body, "Elab_Client", Elaborate => True);
      Add_Unit (Units, 4, EL.Unit_Package_Body, "Elab_Service", Body_Before_Use => False,
                Elaborate => True);
      Add_Dep (Deps, 1, 3, 4, EL.Dependency_Elaborate);
      Add_Call (Calls, 2, 3, 4, EL.Call_Default_Expression);

      Add_Unit (Units, 5, EL.Unit_Package_Body, "All_Client");
      Add_Unit (Units, 6, EL.Unit_Package_Body, "All_Service", Body_Before_Use => False,
                Elaborate_All => True);
      Add_Dep (Deps, 2, 5, 6, EL.Dependency_Elaborate_All, Transitive => True);
      Add_Call (Calls, 3, 5, 6, EL.Call_Object_Initialization,
                Needs_Elaborate_All => True);

      Add_Unit (Units, 7, EL.Unit_Package_Body, "Pure_Client", Pure => True);
      Add_Unit (Units, 8, EL.Unit_Package_Body, "Pure_Service", Pure => True);
      Add_Call (Calls, 4, 7, 8, EL.Call_Library_Level, In_Pure => True,
                Needs_Body => False);

      declare
         Model : constant EL.Result_Model := EL.Build (Units, Deps, Calls);
      begin
         Assert (EL.Result_Count (Model) = 4,
                 "each source-shaped elaboration call should produce one row");
         Assert (EL.Count_Status (Model, EL.Elaboration_Legal_Body_Elaborated) = 1,
                 "body-elaborated calls should be accepted");
         Assert (EL.Count_Status (Model, EL.Elaboration_Legal_Elaborate_Pragma) = 1,
                 "pragma Elaborate dependency should accept call-before-body evidence");
         Assert (EL.Count_Status (Model, EL.Elaboration_Legal_Elaborate_All_Pragma) = 1,
                 "pragma Elaborate_All should accept transitive elaboration requirement");
         Assert (EL.Count_Status (Model, EL.Elaboration_Legal_Pure_Call) = 1,
                 "Pure unit may call pure/preelaborable evidence only");
         Assert (EL.Legal_Count (Model) = 4,
                 "all protected elaboration scenarios should be legal");
      end;
   end Accepts_Body_Elaborated_And_Pragma_Protected_Calls;

   procedure Rejects_Cycles_Body_Gaps_Preelaborate_And_View_Barriers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Units : EL.Unit_Model;
      Deps  : EL.Dependency_Model;
      Calls : EL.Call_Model;
   begin
      Add_Unit (Units, 1, EL.Unit_Package_Body, "Client");
      Add_Unit (Units, 2, EL.Unit_Package_Spec, "Missing_Body", Has_Body => False);
      Add_Call (Calls, 1, 1, 2, EL.Call_Library_Level);

      Add_Unit (Units, 3, EL.Unit_Package_Body, "Early_Client");
      Add_Unit (Units, 4, EL.Unit_Package_Body, "Late_Service", Body_Before_Use => False);
      Add_Call (Calls, 2, 3, 4, EL.Call_Object_Initialization);

      Add_Unit (Units, 5, EL.Unit_Package_Body, "Cycle_A");
      Add_Unit (Units, 6, EL.Unit_Package_Body, "Cycle_B");
      Add_Dep (Deps, 1, 5, 6, EL.Dependency_With, Cyclic => True);
      Add_Call (Calls, 3, 5, 6, EL.Call_Library_Level);

      Add_Unit (Units, 7, EL.Unit_Package_Body, "Pre_Client", Preelaborated => True);
      Add_Unit (Units, 8, EL.Unit_Package_Body, "Normal_Service");
      Add_Call (Calls, 4, 7, 8, EL.Call_Default_Expression,
                In_Preelaborated => True, Needs_Body => False);

      Add_Unit (Units, 9, EL.Unit_Package_Body, "Limited_Client");
      Add_Unit (Units, 10, EL.Unit_Package_Body, "Limited_Service", Limited_View => True);
      Add_Dep (Deps, 2, 9, 10, EL.Dependency_Limited_With, Limited_View => True);
      Add_Call (Calls, 5, 9, 10, EL.Call_Library_Level);

      declare
         Model : constant EL.Result_Model := EL.Build (Units, Deps, Calls);
      begin
         Assert (EL.Result_Count (Model) = 5,
                 "all illegal elaboration scenarios should be represented");
         Assert (EL.Count_Status (Model, EL.Elaboration_Missing_Body) = 1,
                 "call requiring body should reject missing body");
         Assert (EL.Count_Status (Model, EL.Elaboration_Call_Before_Body) = 1,
                 "call-before-body without pragma should be rejected");
         Assert (EL.Count_Status (Model, EL.Elaboration_Cycle) = 1,
                 "elaboration dependency cycle should be rejected");
         Assert (EL.Count_Status (Model, EL.Elaboration_Preelaborate_Violation) = 1,
                 "preelaborated unit should reject non-preelaborable call");
         Assert (EL.Count_Status (Model, EL.Elaboration_Limited_View_Barrier) = 1,
                 "limited-view call should remain blocked");
         Assert (EL.Error_Count (Model) = 5,
                 "all blocker scenarios should be errors");
      end;
   end Rejects_Cycles_Body_Gaps_Preelaborate_And_View_Barriers;

   procedure Rejects_Generic_Separate_Elaborate_All_And_Fingerprint_Gaps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Units : EL.Unit_Model;
      Deps  : EL.Dependency_Model;
      Calls : EL.Call_Model;
   begin
      Add_Unit (Units, 1, EL.Unit_Package_Body, "Client");
      Add_Unit (Units, 2, EL.Unit_Generic_Body, "Generic_Service",
                Generic_Unit => True, Generic_Body => False);
      Add_Call (Calls, 1, 1, 2, EL.Call_Generic_Instance,
                Generic_Instance => True);

      Add_Unit (Units, 3, EL.Unit_Package_Body, "Separate_Client");
      Add_Unit (Units, 4, EL.Unit_Separate_Body, "Separate_Service",
                Separate_Body => True, Separate_Linked => False);
      Add_Call (Calls, 2, 3, 4, EL.Call_Package_Body_Elaboration,
                Separate_Body => True);

      Add_Unit (Units, 5, EL.Unit_Package_Body, "All_Client");
      Add_Unit (Units, 6, EL.Unit_Package_Body, "All_Service");
      Add_Call (Calls, 3, 5, 6, EL.Call_Task_Activation,
                Needs_Elaborate_All => True);

      Add_Unit (Units, 7, EL.Unit_Package_Body, "Stale_Client", Source_FP => 0);
      Add_Unit (Units, 8, EL.Unit_Package_Body, "Stale_Service");
      Add_Call (Calls, 4, 7, 8, EL.Call_Library_Level, Caller_FP => 0);

      declare
         Model : constant EL.Result_Model := EL.Build (Units, Deps, Calls);
      begin
         Assert (EL.Count_Status (Model, EL.Elaboration_Generic_Body_Unavailable) = 1,
                 "generic body replay should require body availability");
         Assert (EL.Count_Status (Model, EL.Elaboration_Separate_Body_Unlinked) = 1,
                 "separate body calls should require stub/body linkage");
         Assert (EL.Count_Status (Model, EL.Elaboration_Elaborate_All_Violation) = 1,
                 "Elaborate_All requirement should require transitive evidence");
         Assert (EL.Count_Status (Model, EL.Elaboration_Source_Fingerprint_Mismatch) = 1,
                 "stale source fingerprints should reject elaboration evidence");
         Assert (EL.Error_Count (Model) = 4,
                 "all generic/separate/fingerprint blockers should be errors");
      end;
   end Rejects_Generic_Separate_Elaborate_All_And_Fingerprint_Gaps;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Body_Elaborated_And_Pragma_Protected_Calls'Access,
         "accept body-elaborated and pragma-protected elaboration calls");
      Register_Routine
        (T, Rejects_Cycles_Body_Gaps_Preelaborate_And_View_Barriers'Access,
         "reject cycles, body gaps, preelaborate violations, and view barriers");
      Register_Routine
        (T, Rejects_Generic_Separate_Elaborate_All_And_Fingerprint_Gaps'Access,
         "reject generic body, separate body, Elaborate_All, and stale fingerprint gaps");
   end Register_Tests;

end Test_Ada_Elaboration_Vertical_Slice_Legality_Pass1301;
