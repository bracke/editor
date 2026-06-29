with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Vertical_Slice_Legality;

package body Test_Ada_Tasking_Protected_Vertical_Slice_Legality is

   package TP renames Editor.Ada_Tasking_Protected_Vertical_Slice_Legality;
   use type TP.Entity_Id;
   use type TP.Operation_Id;
   use type TP.Event_Id;
   use type TP.Result_Id;
   use type TP.Entity_Kind;
   use type TP.Operation_Kind;
   use type TP.Access_Mode;
   use type TP.Event_Kind;
   use type TP.Tasking_Status;
   use type TP.Entity_Info;
   use type TP.Operation_Info;
   use type TP.Event_Info;
   use type TP.Result_Info;
   use type TP.Entity_Model;
   use type TP.Operation_Model;
   use type TP.Event_Model;
   use type TP.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Protected_Vertical_Slice_Legality");
   end Name;

   procedure Add_Entity
     (Entities : in out TP.Entity_Model;
      Id       : Natural;
      Kind     : TP.Entity_Kind;
      Name     : String;
      Protected_Entity : Boolean := False;
      Task_Entity : Boolean := False;
      Abstract_State : Boolean := False;
      Volatile_State : Boolean := False;
      Atomic_State : Boolean := False;
      Independent_Components : Boolean := False;
      Requires_Protected_Access : Boolean := False;
      Allows_Reentrant_Read : Boolean := False;
      Allows_Requeue : Boolean := True;
      Has_Terminate : Boolean := True;
      Has_Finalization : Boolean := False;
      Source_FP : Natural := 130200;
      Effect_FP : Natural := 230200)
   is
      E : TP.Entity_Info;
   begin
      E.Id := TP.Entity_Id (Id);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (130200 + Id);
      E.Kind := Kind;
      E.Name := To_Unbounded_String (Name);
      E.Is_Protected := Protected_Entity;
      E.Is_Task := Task_Entity;
      E.Is_Abstract_State := Abstract_State;
      E.Is_Volatile := Volatile_State;
      E.Is_Atomic := Atomic_State;
      E.Has_Independent_Components := Independent_Components;
      E.Requires_Protected_Access := Requires_Protected_Access;
      E.Allows_Reentrant_Read := Allows_Reentrant_Read;
      E.Allows_Requeue := Allows_Requeue;
      E.Has_Terminate_Alternative := Has_Terminate;
      E.Has_Finalization := Has_Finalization;
      E.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      E.Effect_Fingerprint := (if Effect_FP = 0 then 0 else Effect_FP + Id);
      TP.Add_Entity (Entities, E);
   end Add_Entity;

   procedure Add_Operation
     (Operations : in out TP.Operation_Model;
      Id         : Natural;
      Owner      : Natural;
      Kind       : TP.Operation_Kind;
      Name       : String;
      Access_Mode_Param : TP.Access_Mode := TP.Access_None;
      Barrier    : Boolean := False;
      Barrier_Side_Effects : Boolean := False;
      Callback_Owner : Boolean := False;
      Indirect_Owner : Boolean := False;
      Index_Static : Boolean := True;
      Index_In_Range : Boolean := True;
      Queue_Known : Boolean := True;
      Requeue_Compatible : Boolean := True;
      Select_Covered : Boolean := True;
      Accept_Effects_Known : Boolean := True;
      Source_FP : Natural := 130200;
      Effect_FP : Natural := 230200)
   is
      O : TP.Operation_Info;
   begin
      O.Id := TP.Operation_Id (Id);
      O.Owner := TP.Entity_Id (Owner);
      O.Node := Editor.Ada_Syntax_Tree.Node_Id (130400 + Id);
      O.Kind := Kind;
      O.Name := To_Unbounded_String (Name);
      O.Access_Mode_Value := Access_Mode_Param;
      O.Is_Barrier := Barrier;
      O.Barrier_Has_Side_Effects := Barrier_Side_Effects;
      O.May_Call_Back_Into_Owner := Callback_Owner;
      O.May_Indirectly_Call_Owner := Indirect_Owner;
      O.Entry_Family_Index_Static := Index_Static;
      O.Entry_Family_Index_In_Range := Index_In_Range;
      O.Queue_Policy_Known := Queue_Known;
      O.Requeue_Target_Compatible := Requeue_Compatible;
      O.Select_Path_Covered := Select_Covered;
      O.Accept_Body_Effects_Known := Accept_Effects_Known;
      O.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Owner);
      O.Effect_Fingerprint := (if Effect_FP = 0 then 0 else Effect_FP + Owner);
      TP.Add_Operation (Operations, O);
   end Add_Operation;

   procedure Add_Event
     (Events : in out TP.Event_Model;
      Id     : Natural;
      Entity : Natural;
      Operation : Natural;
      Kind   : TP.Event_Kind;
      Access_Mode_Param : TP.Access_Mode := TP.Access_None;
      Target_Entity : Natural := 0;
      Target_Operation : Natural := 0;
      Inside_Protected : Boolean := False;
      Callback : Boolean := False;
      Indirect : Boolean := False;
      Entry_Family : Boolean := False;
      Requeue_Target : Boolean := False;
      Select_Covered : Boolean := True;
      Abort_Safe : Boolean := True;
      Abortable_Safe : Boolean := True;
      Protected_Shared : Boolean := True;
      Abstract_State_Evidence : Boolean := True;
      Source_FP : Natural := 130200;
      Effect_FP : Natural := 230200;
      Event_FP : Natural := 330200)
   is
      Ev : TP.Event_Info;
   begin
      Ev.Id := TP.Event_Id (Id);
      Ev.Entity := TP.Entity_Id (Entity);
      Ev.Operation := TP.Operation_Id (Operation);
      Ev.Target_Entity := TP.Entity_Id (Target_Entity);
      Ev.Target_Operation := TP.Operation_Id (Target_Operation);
      Ev.Node := Editor.Ada_Syntax_Tree.Node_Id (130600 + Id);
      Ev.Kind := Kind;
      Ev.Access_Mode_Value := Access_Mode_Param;
      Ev.Inside_Protected_Action := Inside_Protected;
      Ev.Through_Callback := Callback;
      Ev.Through_Indirect_Call := Indirect;
      Ev.Uses_Entry_Family := Entry_Family;
      Ev.Has_Requeue_Target := Requeue_Target;
      Ev.Has_Select_Else_Or_Terminate_Path := Select_Covered;
      Ev.Abort_Deferred_Finalization_Safe := Abort_Safe;
      Ev.Abortable_Select_Finalization_Safe := Abortable_Safe;
      Ev.Shared_Access_Is_Protected := Protected_Shared;
      Ev.Abstract_State_Evidence_Present := Abstract_State_Evidence;
      Ev.Expected_Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Entity);
      Ev.Expected_Effect_Fingerprint := (if Effect_FP = 0 then 0 else Effect_FP + Entity);
      Ev.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Entity);
      Ev.Event_Fingerprint := (if Event_FP = 0 then 0 else Event_FP + Id);
      TP.Add_Event (Events, Ev);
   end Add_Event;

   procedure Accepts_Protected_Entry_Requeue_Finalization_And_Shared_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Entities : TP.Entity_Model;
      Operations : TP.Operation_Model;
      Events : TP.Event_Model;
   begin
      Add_Entity (Entities, 1, TP.Entity_Protected_Object, "PO", Protected_Entity => True);
      Add_Operation (Operations, 1, 1, TP.Operation_Protected_Procedure, "Update", TP.Access_Read_Write);
      Add_Event (Events, 1, 1, 1, TP.Event_Protected_Action, TP.Access_Read_Write,
                 Inside_Protected => True);

      Add_Entity (Entities, 2, TP.Entity_Entry_Family, "Workers", Task_Entity => True);
      Add_Operation (Operations, 2, 2, TP.Operation_Task_Entry, "Start", TP.Access_None,
                     Queue_Known => True, Index_Static => True, Index_In_Range => True);
      Add_Event (Events, 2, 2, 2, TP.Event_Entry_Family_Call,
                 Entry_Family => True);

      Add_Entity (Entities, 3, TP.Entity_Task_Object, "Server", Task_Entity => True,
                  Has_Terminate => True, Has_Finalization => True);
      Add_Operation (Operations, 3, 3, TP.Operation_Select_Alternative, "Select_Path",
                     Select_Covered => True);
      Add_Event (Events, 3, 3, 3, TP.Event_Selective_Accept,
                 Select_Covered => True);
      Add_Event (Events, 4, 3, 3, TP.Event_Finalization);

      Add_Entity (Entities, 4, TP.Entity_Shared_Object, "Shared", Protected_Entity => True,
                  Requires_Protected_Access => True, Abstract_State => True);
      Add_Operation (Operations, 4, 4, TP.Operation_Protected_Procedure, "Write_Shared",
                     TP.Access_Read_Write);
      Add_Event (Events, 5, 4, 4, TP.Event_Shared_State_Access, TP.Access_Write,
                 Protected_Shared => True, Abstract_State_Evidence => True);

      declare
         Model : constant TP.Result_Model := TP.Build (Entities, Operations, Events);
      begin
         Assert (TP.Result_Count (Model) = 5,
                 "each source-shaped tasking event should produce one result");
         Assert (TP.Count_Status (Model, TP.Tasking_Legal_Protected_Action) = 1,
                 "plain protected action should be accepted");
         Assert (TP.Count_Status (Model, TP.Tasking_Legal_Queued_Entry) = 1,
                 "entry-family call with known queue and range should be accepted");
         Assert (TP.Count_Status (Model, TP.Tasking_Legal_Requeue_Or_Select) = 1,
                 "covered select path should be accepted");
         Assert (TP.Count_Status (Model, TP.Tasking_Legal_Termination_Or_Finalization) = 1,
                 "safe finalization event should be accepted");
         Assert (TP.Count_Status (Model, TP.Tasking_Legal_Shared_State_Access) = 1,
                 "protected shared-state write with abstract-state evidence should be accepted");
         Assert (TP.Legal_Count (Model) = 5,
                 "all accepted tasking/protected scenarios should be legal");
      end;
   end Accepts_Protected_Entry_Requeue_Finalization_And_Shared_State;

   procedure Rejects_Reentrancy_Barriers_Queues_Abort_And_Shared_State_Gaps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Entities : TP.Entity_Model;
      Operations : TP.Operation_Model;
      Events : TP.Event_Model;
   begin
      Add_Entity (Entities, 1, TP.Entity_Protected_Object, "PO", Protected_Entity => True);
      Add_Operation (Operations, 1, 1, TP.Operation_Protected_Procedure, "Reenter",
                     TP.Access_Read_Write, Indirect_Owner => True);
      Add_Event (Events, 1, 1, 1, TP.Event_Indirect_Protected_Call,
                 Inside_Protected => True, Indirect => True);

      Add_Entity (Entities, 2, TP.Entity_Protected_Object, "Barrier_PO", Protected_Entity => True);
      Add_Operation (Operations, 2, 2, TP.Operation_Protected_Entry, "E",
                     Barrier => True, Barrier_Side_Effects => True);
      Add_Event (Events, 2, 2, 2, TP.Event_Protected_Action);

      Add_Entity (Entities, 3, TP.Entity_Entry_Family, "Family", Task_Entity => True);
      Add_Operation (Operations, 3, 3, TP.Operation_Task_Entry, "Indexed",
                     Index_Static => True, Index_In_Range => False);
      Add_Event (Events, 3, 3, 3, TP.Event_Entry_Family_Call,
                 Entry_Family => True);

      Add_Entity (Entities, 4, TP.Entity_Task_Object, "Finalized_Task", Task_Entity => True,
                  Has_Finalization => True);
      Add_Operation (Operations, 4, 4, TP.Operation_Finalizer, "Finalize");
      Add_Event (Events, 4, 4, 4, TP.Event_Abort, Abort_Safe => False);

      Add_Entity (Entities, 5, TP.Entity_Shared_Object, "Shared", Requires_Protected_Access => True,
                  Abstract_State => True);
      Add_Operation (Operations, 5, 5, TP.Operation_Protected_Procedure, "Write_Shared",
                     TP.Access_Read_Write);
      Add_Event (Events, 5, 5, 5, TP.Event_Shared_State_Access, TP.Access_Write,
                 Protected_Shared => False);

      declare
         Model : constant TP.Result_Model := TP.Build (Entities, Operations, Events);
      begin
         Assert (TP.Result_Count (Model) = 5,
                 "each illegal tasking scenario should be represented");
         Assert (TP.Count_Status (Model, TP.Tasking_Protected_Reentrancy) = 1,
                 "indirect protected self-call should be rejected");
         Assert (TP.Count_Status (Model, TP.Tasking_Barrier_Side_Effect) = 1,
                 "barrier side effects should be rejected");
         Assert (TP.Count_Status (Model, TP.Tasking_Entry_Family_Index_Error) = 1,
                 "entry-family index range error should be rejected");
         Assert (TP.Count_Status (Model, TP.Tasking_Abort_Deferred_Finalization_Error) = 1,
                 "unsafe abort with deferred finalization should be rejected");
         Assert (TP.Count_Status (Model, TP.Tasking_Unprotected_Shared_Access) = 1,
                 "unprotected shared-state write should be rejected");
         Assert (TP.Error_Count (Model) = 5,
                 "all blocker scenarios should be counted as errors");
      end;
   end Rejects_Reentrancy_Barriers_Queues_Abort_And_Shared_State_Gaps;

   procedure Preserves_Fingerprint_Mode_And_Abstract_State_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Entities : TP.Entity_Model;
      Operations : TP.Operation_Model;
      Events : TP.Event_Model;
   begin
      Add_Entity (Entities, 1, TP.Entity_Shared_Object, "Volatile_State",
                  Requires_Protected_Access => True, Volatile_State => True);
      Add_Operation (Operations, 1, 1, TP.Operation_Protected_Function, "Read_Only",
                     TP.Access_Read);
      Add_Event (Events, 1, 1, 1, TP.Event_Shared_State_Access, TP.Access_Write,
                 Protected_Shared => True);

      Add_Entity (Entities, 2, TP.Entity_Abstract_State, "State", Abstract_State => True);
      Add_Operation (Operations, 2, 2, TP.Operation_Protected_Procedure, "Touch",
                     TP.Access_Read_Write);
      Add_Event (Events, 2, 2, 2, TP.Event_Shared_State_Access, TP.Access_Read_Write,
                 Protected_Shared => True, Abstract_State_Evidence => False);

      Add_Entity (Entities, 3, TP.Entity_Protected_Object, "Stale", Protected_Entity => True,
                  Source_FP => 0);
      Add_Operation (Operations, 3, 3, TP.Operation_Protected_Procedure, "Update",
                     TP.Access_Read_Write);
      Add_Event (Events, 3, 3, 3, TP.Event_Protected_Action, TP.Access_Read_Write,
                 Source_FP => 130200);

      declare
         Model : constant TP.Result_Model := TP.Build (Entities, Operations, Events);
      begin
         Assert (TP.Count_Status (Model, TP.Tasking_Mode_Mismatch) = 1,
                 "write through read-only protected function should be a mode blocker");
         Assert (TP.Count_Status (Model, TP.Tasking_Abstract_State_Blocker) = 1,
                 "volatile/abstract state access requires abstract-state evidence");
         Assert (TP.Count_Status (Model, TP.Tasking_Source_Fingerprint_Mismatch) = 1,
                 "stale source fingerprints should be rejected");
      end;
   end Preserves_Fingerprint_Mode_And_Abstract_State_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepts_Protected_Entry_Requeue_Finalization_And_Shared_State'Access,
         "accept protected, queued, select, finalization, and shared-state tasking cases");
      Register_Routine
        (T,
         Rejects_Reentrancy_Barriers_Queues_Abort_And_Shared_State_Gaps'Access,
         "reject concrete tasking/protected RM blockers");
      Register_Routine
        (T,
         Preserves_Fingerprint_Mode_And_Abstract_State_Blockers'Access,
         "preserve fingerprint, mode, and abstract-state tasking blockers");
   end Register_Tests;

end Test_Ada_Tasking_Protected_Vertical_Slice_Legality;
