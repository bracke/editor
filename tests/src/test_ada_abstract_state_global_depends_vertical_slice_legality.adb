with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality;

package body Test_Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality is

   package AS renames Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality;
   use type AS.State_Id;
   use type AS.Operation_Id;
   use type AS.Use_Id;
   use type AS.Result_Id;
   use type AS.State_Kind;
   use type AS.Flow_Mode;
   use type AS.Use_Kind;
   use type AS.State_Status;
   use type AS.State_Info;
   use type AS.Operation_Info;
   use type AS.Use_Info;
   use type AS.Result_Info;
   use type AS.State_Model;
   use type AS.Operation_Model;
   use type AS.Use_Model;
   use type AS.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality");
   end Name;

   procedure Add_State
     (States : in out AS.State_Model;
      Id     : Natural;
      Kind   : AS.State_Kind;
      Name   : String;
      Parent : Natural := 0;
      Allowed : AS.Flow_Mode := AS.Mode_In_Out;
      Visible : Boolean := True;
      Abstract_State : Boolean := False;
      Constituent : Boolean := False;
      Volatile_State : Boolean := False;
      Atomic_State : Boolean := False;
      Shared_State : Boolean := False;
      Protected_Access : Boolean := False;
      Source_FP : Natural := 130300;
      State_FP : Natural := 230300)
   is
      S : AS.State_Info;
   begin
      S.Id := AS.State_Id (Id);
      S.Parent := AS.State_Id (Parent);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (130300 + Id);
      S.Kind := Kind;
      S.Name := To_Unbounded_String (Name);
      S.Allowed_Mode := Allowed;
      S.Visible := Visible;
      S.Is_Abstract := Abstract_State;
      S.Is_Constituent := Constituent;
      S.Is_Volatile := Volatile_State;
      S.Is_Atomic := Atomic_State;
      S.Is_Shared := Shared_State;
      S.Requires_Protected_Access := Protected_Access;
      S.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      S.State_Fingerprint := (if State_FP = 0 then 0 else State_FP + Id);
      AS.Add_State (States, S);
   end Add_State;

   procedure Add_Operation
     (Operations : in out AS.Operation_Model;
      Id         : Natural;
      Name       : String;
      Global_Mode : AS.Flow_Mode := AS.Mode_In_Out;
      Depends_Mode : AS.Flow_Mode := AS.Mode_In_Out;
      Has_Global : Boolean := True;
      Has_Depends : Boolean := True;
      Has_Refined : Boolean := True;
      Source_FP : Natural := 130300;
      Contract_FP : Natural := 330300)
   is
      O : AS.Operation_Info;
   begin
      O.Id := AS.Operation_Id (Id);
      O.Node := Editor.Ada_Syntax_Tree.Node_Id (130500 + Id);
      O.Name := To_Unbounded_String (Name);
      O.Global_Mode := Global_Mode;
      O.Depends_Mode := Depends_Mode;
      O.Has_Global_Aspect := Has_Global;
      O.Has_Depends_Aspect := Has_Depends;
      O.Has_Refined_State_Aspect := Has_Refined;
      O.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      O.Contract_Fingerprint := (if Contract_FP = 0 then 0 else Contract_FP + Id);
      AS.Add_Operation (Operations, O);
   end Add_Operation;

   procedure Add_Use
     (Uses : in out AS.Use_Model;
      Id   : Natural;
      Operation : Natural;
      Target : Natural;
      Kind : AS.Use_Kind;
      Mode : AS.Flow_Mode := AS.Mode_In;
      Source : Natural := 0;
      Parent : Natural := 0;
      Has_Refined : Boolean := True;
      Constituent_Present : Boolean := True;
      Extra_Constituent : Boolean := False;
      Constituent_Mode : Boolean := True;
      Source_Visible : Boolean := True;
      Target_Visible : Boolean := True;
      Cycle : Boolean := False;
      Volatile_Order : Boolean := True;
      Atomic_Consistent : Boolean := True;
      Protected_Shared : Boolean := True;
      Source_FP : Natural := 130300;
      State_FP : Natural := 230300;
      Use_FP : Natural := 430300)
   is
      U : AS.Use_Info;
   begin
      U.Id := AS.Use_Id (Id);
      U.Operation := AS.Operation_Id (Operation);
      U.Target_State := AS.State_Id (Target);
      U.Source_State := AS.State_Id (Source);
      U.Parent_State := AS.State_Id (Parent);
      U.Node := Editor.Ada_Syntax_Tree.Node_Id (130700 + Id);
      U.Kind := Kind;
      U.Mode := Mode;
      U.Has_Refined_State_Aspect := Has_Refined;
      U.Constituent_Present := Constituent_Present;
      U.Extra_Constituent := Extra_Constituent;
      U.Constituent_Mode_Matches := Constituent_Mode;
      U.Depends_Source_Visible := Source_Visible;
      U.Depends_Target_Visible := Target_Visible;
      U.Depends_Cycle := Cycle;
      U.Volatile_Order_Known := Volatile_Order;
      U.Atomic_Access_Consistent := Atomic_Consistent;
      U.Shared_Access_Protected := Protected_Shared;
      U.Expected_Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Target);
      U.Expected_State_Fingerprint := (if State_FP = 0 then 0 else State_FP + Target);
      U.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Target);
      U.Use_Fingerprint := (if Use_FP = 0 then 0 else Use_FP + Id);
      AS.Add_Use (Uses, U);
   end Add_Use;

   procedure Accepts_Global_Depends_Refined_State_And_Shared_Effects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      States : AS.State_Model;
      Operations : AS.Operation_Model;
      Uses : AS.Use_Model;
   begin
      Add_State (States, 1, AS.State_Abstract, "Visible_State",
                 Abstract_State => True, Allowed => AS.Mode_In_Out);
      Add_State (States, 2, AS.State_Constituent, "Concrete_Cache",
                 Parent => 1, Constituent => True, Allowed => AS.Mode_In_Out);
      Add_State (States, 3, AS.State_Volatile, "Volatile_Flag",
                 Volatile_State => True, Allowed => AS.Mode_In_Out);
      Add_State (States, 4, AS.State_Shared, "Shared_Buffer",
                 Shared_State => True, Protected_Access => True, Allowed => AS.Mode_In_Out);
      Add_Operation (Operations, 1, "Update", AS.Mode_In_Out, AS.Mode_In_Out);

      Add_Use (Uses, 1, 1, 1, AS.Use_Global, AS.Mode_In_Out);
      Add_Use (Uses, 2, 1, 1, AS.Use_Depends_Edge, AS.Mode_In,
               Source => 2);
      Add_Use (Uses, 3, 1, 2, AS.Use_Refined_State_Mapping, AS.Mode_In_Out,
               Parent => 1, Constituent_Present => True, Constituent_Mode => True);
      Add_Use (Uses, 4, 1, 3, AS.Use_Call_Effect, AS.Mode_Out,
               Volatile_Order => True);
      Add_Use (Uses, 5, 1, 4, AS.Use_Shared_State_Effect, AS.Mode_Out,
               Protected_Shared => True);

      declare
         Model : constant AS.Result_Model := AS.Build (States, Operations, Uses);
      begin
         Assert (AS.Result_Count (Model) = 5,
                 "each source-shaped abstract-state use should produce one result");
         Assert (AS.Count_Status (Model, AS.State_Legal_Global) = 1,
                 "visible Global state usage should be accepted");
         Assert (AS.Count_Status (Model, AS.State_Legal_Depends) = 1,
                 "visible Depends source/target should be accepted");
         Assert (AS.Count_Status (Model, AS.State_Legal_Refined_State) = 1,
                 "Refined_State mapping with constituent should be accepted");
         Assert (AS.Count_Status (Model, AS.State_Legal_Shared_Effect) = 2,
                 "volatile and protected shared effects should be accepted");
         Assert (AS.Legal_Count (Model) = 5,
                 "accepted state/flow scenarios should all be legal");
      end;
   end Accepts_Global_Depends_Refined_State_And_Shared_Effects;

   procedure Rejects_Mode_Constituent_Depends_Volatile_Atomic_And_Shared_Gaps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      States : AS.State_Model;
      Operations : AS.Operation_Model;
      Uses : AS.Use_Model;
   begin
      Add_State (States, 1, AS.State_Abstract, "Read_Only_State",
                 Abstract_State => True, Allowed => AS.Mode_In);
      Add_State (States, 2, AS.State_Constituent, "Missing_Constituent",
                 Parent => 1, Constituent => True);
      Add_State (States, 3, AS.State_Volatile, "Volatile_State",
                 Volatile_State => True);
      Add_State (States, 4, AS.State_Atomic, "Atomic_State",
                 Atomic_State => True);
      Add_State (States, 5, AS.State_Shared, "Shared_State",
                 Shared_State => True, Protected_Access => True);
      Add_Operation (Operations, 1, "Bad_Update", AS.Mode_In_Out, AS.Mode_In_Out);

      Add_Use (Uses, 1, 1, 1, AS.Use_Global, AS.Mode_Out);
      Add_Use (Uses, 2, 1, 2, AS.Use_Refined_State_Mapping, AS.Mode_In_Out,
               Parent => 1, Has_Refined => True, Constituent_Present => False);
      Add_Use (Uses, 3, 1, 1, AS.Use_Depends_Edge, AS.Mode_In,
               Source => 99);
      Add_Use (Uses, 4, 1, 3, AS.Use_Call_Effect, AS.Mode_Out,
               Volatile_Order => False);
      Add_Use (Uses, 5, 1, 4, AS.Use_Call_Effect, AS.Mode_In_Out,
               Atomic_Consistent => False);
      Add_Use (Uses, 6, 1, 5, AS.Use_Shared_State_Effect, AS.Mode_Out,
               Protected_Shared => False);

      declare
         Model : constant AS.Result_Model := AS.Build (States, Operations, Uses);
      begin
         Assert (AS.Count_Status (Model, AS.State_Mode_Mismatch) = 1,
                 "writing a read-only abstract state should be a mode blocker");
         Assert (AS.Count_Status (Model, AS.State_Missing_Constituent) = 1,
                 "missing refined-state constituent should be rejected");
         Assert (AS.Count_Status (Model, AS.State_Depends_Missing_Source) = 1,
                 "missing Depends source state should be rejected");
         Assert (AS.Count_Status (Model, AS.State_Volatile_Ordering_Error) = 1,
                 "volatile write without ordering evidence should be rejected");
         Assert (AS.Count_Status (Model, AS.State_Atomic_Mixed_Access_Error) = 1,
                 "mixed atomic/non-atomic state access should be rejected");
         Assert (AS.Count_Status (Model, AS.State_Unprotected_Shared_Access) = 1,
                 "unprotected shared-state write should be rejected");
         Assert (AS.Error_Count (Model) = 6,
                 "all concrete abstract-state blocker scenarios should be errors");
      end;
   end Rejects_Mode_Constituent_Depends_Volatile_Atomic_And_Shared_Gaps;

   procedure Preserves_Duplicate_Fingerprint_Visibility_And_Cycle_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      States : AS.State_Model;
      Operations : AS.Operation_Model;
      Uses : AS.Use_Model;
   begin
      Add_State (States, 1, AS.State_Abstract, "Dup_State", Abstract_State => True);
      Add_State (States, 2, AS.State_Abstract, "Dup_State", Abstract_State => True);
      Add_State (States, 3, AS.State_Abstract, "Hidden_Target", Visible => False,
                 Abstract_State => True);
      Add_State (States, 4, AS.State_Abstract, "Stale_State", Abstract_State => True,
                 Source_FP => 0);
      Add_State (States, 5, AS.State_Abstract, "Cycle_Target", Abstract_State => True);
      Add_State (States, 6, AS.State_Abstract, "Cycle_Source", Abstract_State => True);
      Add_Operation (Operations, 1, "Check", AS.Mode_In_Out, AS.Mode_In_Out);

      Add_Use (Uses, 1, 1, 1, AS.Use_Global, AS.Mode_In);
      Add_Use (Uses, 2, 1, 3, AS.Use_Depends_Edge, AS.Mode_In,
               Source => 6, Target_Visible => False);
      Add_Use (Uses, 3, 1, 5, AS.Use_Depends_Edge, AS.Mode_In,
               Source => 6, Cycle => True);
      Add_Use (Uses, 4, 1, 4, AS.Use_Global, AS.Mode_In,
               Source_FP => 130300);

      declare
         Model : constant AS.Result_Model := AS.Build (States, Operations, Uses);
      begin
         Assert (AS.Count_Status (Model, AS.State_Duplicate_Abstract_State) = 1,
                 "duplicate abstract states should be rejected deterministically");
         Assert (AS.Count_Status (Model, AS.State_Invisible_Constituent) = 1,
                 "invisible Depends target should preserve a visibility blocker");
         Assert (AS.Count_Status (Model, AS.State_Depends_Cycle) = 1,
                 "Depends cycles should be rejected");
         Assert (AS.Count_Status (Model, AS.State_Source_Fingerprint_Mismatch) = 1,
                 "stale source fingerprint should be rejected");
      end;
   end Preserves_Duplicate_Fingerprint_Visibility_And_Cycle_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepts_Global_Depends_Refined_State_And_Shared_Effects'Access,
         "accept concrete Global, Depends, Refined_State, volatile, and shared-state uses");
      Register_Routine
        (T,
         Rejects_Mode_Constituent_Depends_Volatile_Atomic_And_Shared_Gaps'Access,
         "reject concrete abstract/refined-state and Global/Depends blockers");
      Register_Routine
        (T,
         Preserves_Duplicate_Fingerprint_Visibility_And_Cycle_Blockers'Access,
         "preserve duplicate, fingerprint, visibility, and Depends-cycle blockers");
   end Register_Tests;

end Test_Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality;
