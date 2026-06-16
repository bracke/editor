with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 977) + 1302) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : Tasking_Status) return Boolean is
   begin
      return Status in Tasking_Legal_Protected_Action
        | Tasking_Legal_Queued_Entry
        | Tasking_Legal_Requeue_Or_Select
        | Tasking_Legal_Termination_Or_Finalization
        | Tasking_Legal_Shared_State_Access;
   end Is_Legal;

   function Is_Write (Mode : Access_Mode) return Boolean is
   begin
      return Mode in Access_Write | Access_Read_Write;
   end Is_Write;

   procedure Clear (Model : in out Entity_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Operation_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Event_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Entity_Kind'Pos (Info.Kind)
         + Info.Source_Fingerprint + Info.Effect_Fingerprint);
   end Add_Entity;

   procedure Add_Operation (Model : in out Operation_Model; Info : Operation_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Owner) + Operation_Kind'Pos (Info.Kind)
         + Access_Mode'Pos (Info.Access_Mode_Value) + Info.Source_Fingerprint + Info.Effect_Fingerprint);
   end Add_Operation;

   procedure Add_Event (Model : in out Event_Model; Info : Event_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Entity) + Natural (Info.Operation)
         + Event_Kind'Pos (Info.Kind) + Access_Mode'Pos (Info.Access_Mode_Value)
         + Info.Source_Fingerprint + Info.Event_Fingerprint);
   end Add_Event;

   function Find_Entity (Entities : Entity_Model; Id : Entity_Id) return Entity_Info is
   begin
      for E of Entities.Items loop
         if E.Id = Id then
            return E;
         end if;
      end loop;
      return (others => <>);
   end Find_Entity;

   function Find_Operation
     (Operations : Operation_Model;
      Id         : Operation_Id) return Operation_Info is
   begin
      for O of Operations.Items loop
         if O.Id = Id then
            return O;
         end if;
      end loop;
      return (others => <>);
   end Find_Operation;

   function Status_For (R : Result_Info; Ev : Event_Info; Ent : Entity_Info;
                        Op : Operation_Info) return Tasking_Status is
   begin
      if R.Missing_Entity_Blockers > 0 then
         return Tasking_Missing_Entity;
      elsif R.Missing_Operation_Blockers > 0 then
         return Tasking_Missing_Operation;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Tasking_Source_Fingerprint_Mismatch;
      elsif R.Effect_Fingerprint_Blockers > 0 then
         return Tasking_Effect_Fingerprint_Mismatch;
      elsif R.Reentrancy_Blockers > 0 then
         return Tasking_Protected_Reentrancy;
      elsif R.Callback_Reentrancy_Blockers > 0 then
         return Tasking_Callback_Reentrancy;
      elsif R.Barrier_Blockers > 0 then
         return Tasking_Barrier_Side_Effect;
      elsif R.Entry_Family_Blockers > 0 then
         return Tasking_Entry_Family_Index_Error;
      elsif R.Queue_Blockers > 0 then
         return Tasking_Entry_Queue_Discipline_Error;
      elsif R.Requeue_Blockers > 0 then
         return Tasking_Requeue_Target_Error;
      elsif R.Select_Path_Blockers > 0 then
         return Tasking_Select_Path_Error;
      elsif R.Accept_Body_Blockers > 0 then
         return Tasking_Accept_Body_Effect_Error;
      elsif R.Terminate_Blockers > 0 then
         return Tasking_Terminate_Dependency_Error;
      elsif R.Abort_Finalization_Blockers > 0 then
         return Tasking_Abort_Deferred_Finalization_Error;
      elsif R.Abortable_Finalization_Blockers > 0 then
         return Tasking_Abortable_Select_Finalization_Error;
      elsif R.Shared_Access_Blockers > 0 then
         return Tasking_Unprotected_Shared_Access;
      elsif R.Mode_Blockers > 0 then
         return Tasking_Mode_Mismatch;
      elsif R.Abstract_State_Blockers > 0 then
         return Tasking_Abstract_State_Blocker;
      elsif Ev.Kind in Event_Entry_Family_Call then
         return Tasking_Legal_Queued_Entry;
      elsif Ev.Kind in Event_Requeue | Event_Selective_Accept | Event_Accept_Body then
         return Tasking_Legal_Requeue_Or_Select;
      elsif Ev.Kind in Event_Task_Termination | Event_Terminate_Alternative
        | Event_Abort | Event_Abortable_Select | Event_Finalization
      then
         return Tasking_Legal_Termination_Or_Finalization;
      elsif Ev.Kind = Event_Shared_State_Access or else Ent.Requires_Protected_Access then
         return Tasking_Legal_Shared_State_Access;
      end if;

      pragma Unreferenced (Op);
      return Tasking_Legal_Protected_Action;
   end Status_For;

   procedure Add_Message (R : in out Result_Info) is
   begin
      case R.Status is
         when Tasking_Legal_Protected_Action =>
            R.Message := To_Unbounded_String ("protected action is tasking-legal");
         when Tasking_Legal_Queued_Entry =>
            R.Message := To_Unbounded_String ("entry-family queue semantics are legal");
         when Tasking_Legal_Requeue_Or_Select =>
            R.Message := To_Unbounded_String ("requeue/select path is legal");
         when Tasking_Legal_Termination_Or_Finalization =>
            R.Message := To_Unbounded_String ("termination/finalization ordering is legal");
         when Tasking_Legal_Shared_State_Access =>
            R.Message := To_Unbounded_String ("shared-state access is protected by tasking rules");
         when Tasking_Missing_Entity =>
            R.Message := To_Unbounded_String ("tasking event has no resolved task/protected entity");
         when Tasking_Missing_Operation =>
            R.Message := To_Unbounded_String ("tasking event has no resolved operation");
         when Tasking_Protected_Reentrancy =>
            R.Message := To_Unbounded_String ("protected action may reenter its protected object");
         when Tasking_Callback_Reentrancy =>
            R.Message := To_Unbounded_String ("callback may reenter protected action");
         when Tasking_Barrier_Side_Effect =>
            R.Message := To_Unbounded_String ("protected entry barrier has side effects");
         when Tasking_Entry_Family_Index_Error =>
            R.Message := To_Unbounded_String ("entry-family index is not statically in range");
         when Tasking_Entry_Queue_Discipline_Error =>
            R.Message := To_Unbounded_String ("entry queue discipline is not known");
         when Tasking_Requeue_Target_Error =>
            R.Message := To_Unbounded_String ("requeue target is not compatible");
         when Tasking_Select_Path_Error =>
            R.Message := To_Unbounded_String ("select path lacks required else/terminate coverage");
         when Tasking_Accept_Body_Effect_Error =>
            R.Message := To_Unbounded_String ("accept body effects are not known");
         when Tasking_Terminate_Dependency_Error =>
            R.Message := To_Unbounded_String ("terminate alternative dependency is unsafe");
         when Tasking_Abort_Deferred_Finalization_Error =>
            R.Message := To_Unbounded_String ("abort violates deferred finalization ordering");
         when Tasking_Abortable_Select_Finalization_Error =>
            R.Message := To_Unbounded_String ("abortable select violates finalization safety");
         when Tasking_Unprotected_Shared_Access =>
            R.Message := To_Unbounded_String ("shared object access is not protected");
         when Tasking_Mode_Mismatch =>
            R.Message := To_Unbounded_String ("tasking access mode does not match shared-state mode");
         when Tasking_Abstract_State_Blocker =>
            R.Message := To_Unbounded_String ("abstract-state evidence is missing for tasking effect");
         when Tasking_Source_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("tasking source fingerprint mismatch");
         when Tasking_Effect_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("tasking effect fingerprint mismatch");
         when Tasking_Multiple_Blockers =>
            R.Message := To_Unbounded_String ("multiple tasking/protected blockers");
         when Tasking_Indeterminate | Tasking_Not_Checked =>
            R.Message := To_Unbounded_String ("tasking/protected legality is indeterminate");
      end case;
   end Add_Message;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Entity_Blockers + R.Missing_Operation_Blockers
        + R.Reentrancy_Blockers + R.Callback_Reentrancy_Blockers
        + R.Barrier_Blockers + R.Entry_Family_Blockers + R.Queue_Blockers
        + R.Requeue_Blockers + R.Select_Path_Blockers + R.Accept_Body_Blockers
        + R.Terminate_Blockers + R.Abort_Finalization_Blockers
        + R.Abortable_Finalization_Blockers + R.Shared_Access_Blockers
        + R.Mode_Blockers + R.Abstract_State_Blockers
        + R.Source_Fingerprint_Blockers + R.Effect_Fingerprint_Blockers;
   end Blocker_Count;

   function Build
     (Entities   : Entity_Model;
      Operations : Operation_Model;
      Events     : Event_Model) return Result_Model
   is
      Result : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Ev of Events.Items loop
         declare
            Ent : constant Entity_Info := Find_Entity (Entities, Ev.Entity);
            Op  : constant Operation_Info := Find_Operation (Operations, Ev.Operation);
            Target_Ent : constant Entity_Info := Find_Entity (Entities, Ev.Target_Entity);
            Target_Op  : constant Operation_Info := Find_Operation (Operations, Ev.Target_Operation);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Event := Ev.Id;
            R.Entity := Ev.Entity;
            R.Operation := Ev.Operation;
            R.Node := Ev.Node;

            if Ent.Id = No_Entity then
               R.Missing_Entity_Blockers := R.Missing_Entity_Blockers + 1;
            else
               R.Source_Fingerprint := Ent.Source_Fingerprint;
               R.Effect_Fingerprint := Ent.Effect_Fingerprint;
            end if;

            if Op.Id = No_Operation then
               R.Missing_Operation_Blockers := R.Missing_Operation_Blockers + 1;
            end if;

            if R.Missing_Entity_Blockers = 0 and then R.Missing_Operation_Blockers = 0 then
               if Ent.Source_Fingerprint = 0 or else Op.Source_Fingerprint = 0
                 or else Ev.Source_Fingerprint = 0
                 or else (Ev.Expected_Source_Fingerprint /= 0
                          and then Ev.Expected_Source_Fingerprint /= Ent.Source_Fingerprint)
               then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;

               if Ent.Effect_Fingerprint = 0 or else Op.Effect_Fingerprint = 0
                 or else (Ev.Expected_Effect_Fingerprint /= 0
                          and then Ev.Expected_Effect_Fingerprint /= Ent.Effect_Fingerprint)
               then
                  R.Effect_Fingerprint_Blockers := R.Effect_Fingerprint_Blockers + 1;
               end if;

               if Ev.Inside_Protected_Action and then Ent.Is_Protected
                 and then (Ev.Through_Indirect_Call or else Op.May_Indirectly_Call_Owner)
                 and then not Ent.Allows_Reentrant_Read
               then
                  R.Reentrancy_Blockers := R.Reentrancy_Blockers + 1;
               end if;

               if (Ev.Through_Callback or else Op.May_Call_Back_Into_Owner)
                 and then Ent.Is_Protected
               then
                  R.Callback_Reentrancy_Blockers := R.Callback_Reentrancy_Blockers + 1;
               end if;

               if Op.Is_Barrier and then Op.Barrier_Has_Side_Effects then
                  R.Barrier_Blockers := R.Barrier_Blockers + 1;
               end if;

               if Ev.Uses_Entry_Family
                 and then (not Op.Entry_Family_Index_Static
                           or else not Op.Entry_Family_Index_In_Range)
               then
                  R.Entry_Family_Blockers := R.Entry_Family_Blockers + 1;
               end if;

               if Ev.Kind in Event_Entry_Family_Call | Event_Requeue | Event_Selective_Accept
                 and then not Op.Queue_Policy_Known
               then
                  R.Queue_Blockers := R.Queue_Blockers + 1;
               end if;

               if Ev.Kind = Event_Requeue
                 and then (not Ev.Has_Requeue_Target
                           or else not Op.Requeue_Target_Compatible
                           or else (Ev.Target_Operation /= No_Operation
                                    and then Target_Op.Id = No_Operation)
                           or else (Ev.Target_Entity /= No_Entity
                                    and then Target_Ent.Id = No_Entity))
               then
                  R.Requeue_Blockers := R.Requeue_Blockers + 1;
               end if;

               if Ev.Kind = Event_Selective_Accept
                 and then (not Ev.Has_Select_Else_Or_Terminate_Path
                           or else not Op.Select_Path_Covered)
               then
                  R.Select_Path_Blockers := R.Select_Path_Blockers + 1;
               end if;

               if Ev.Kind = Event_Accept_Body and then not Op.Accept_Body_Effects_Known then
                  R.Accept_Body_Blockers := R.Accept_Body_Blockers + 1;
               end if;

               if Ev.Kind in Event_Terminate_Alternative | Event_Task_Termination
                 and then not Ent.Has_Terminate_Alternative
               then
                  R.Terminate_Blockers := R.Terminate_Blockers + 1;
               end if;

               if Ev.Kind = Event_Abort
                 and then (Ent.Has_Finalization and then not Ev.Abort_Deferred_Finalization_Safe)
               then
                  R.Abort_Finalization_Blockers := R.Abort_Finalization_Blockers + 1;
               end if;

               if Ev.Kind = Event_Abortable_Select
                 and then (Ent.Has_Finalization and then not Ev.Abortable_Select_Finalization_Safe)
               then
                  R.Abortable_Finalization_Blockers := R.Abortable_Finalization_Blockers + 1;
               end if;

               if Ev.Kind = Event_Shared_State_Access
                 and then (Ent.Requires_Protected_Access and then not Ev.Shared_Access_Is_Protected)
               then
                  R.Shared_Access_Blockers := R.Shared_Access_Blockers + 1;
               end if;

               if Ev.Kind = Event_Shared_State_Access
                 and then Is_Write (Ev.Access_Mode_Value)
                 and then Op.Access_Mode_Value = Access_Read
               then
                  R.Mode_Blockers := R.Mode_Blockers + 1;
               end if;

               if (Ent.Is_Abstract_State or else Ent.Is_Volatile or else Ent.Is_Atomic)
                 and then not Ev.Abstract_State_Evidence_Present
               then
                  R.Abstract_State_Blockers := R.Abstract_State_Blockers + 1;
               end if;
            end if;

            if Blocker_Count (R) > 1 then
               R.Status := Tasking_Multiple_Blockers;
            elsif Ev.Kind = Event_Unknown then
               R.Status := Tasking_Indeterminate;
            else
               R.Status := Status_For (R, Ev, Ent, Op);
            end if;

            Add_Message (R);
            R.Detail := To_Unbounded_String ("tasking vertical slice event" & Natural'Image (Natural (Ev.Id)));
            R.Fingerprint := Mix
              (Natural (R.Id) + Natural (R.Event) + Natural (R.Entity)
               + Natural (R.Operation) + Tasking_Status'Pos (R.Status),
               R.Source_Fingerprint + R.Effect_Fingerprint + Ev.Event_Fingerprint
               + Blocker_Count (R));

            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            Result.Items.Append (R);
         end;
      end loop;
      return Result;
   end Build;

   function Entity_Count (Model : Entity_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Entity_Count;

   function Operation_Count (Model : Operation_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Operation_Count;

   function Event_Count (Model : Event_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Event_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Tasking_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if Is_Legal (R.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Result_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result;
   end Has_Result;

end Editor.Ada_Tasking_Protected_Vertical_Slice_Legality;
