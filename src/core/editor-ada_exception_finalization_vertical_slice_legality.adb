with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Exception_Finalization_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1310) mod 1_000_000_007;
   end Mix;

   function Is_Raise (Kind : Event_Kind) return Boolean is
   begin
      return Kind in Event_Raise_Statement | Event_Raise_Expression;
   end Is_Raise;

   function Is_Handler (Kind : Event_Kind) return Boolean is
   begin
      return Kind in Event_Exception_Handler | Event_Handled_Sequence;
   end Is_Handler;

   function Is_Finalization (Kind : Event_Kind) return Boolean is
   begin
      return Kind in Event_Controlled_Object_Finalization
        | Event_Limited_Controlled_Finalization
        | Event_Task_Termination_Finalization
        | Event_Abort_Finalization
        | Event_Abortable_Select_Finalization;
   end Is_Finalization;

   function Exception_Kind_Compatible (Info : Event_Info) return Boolean is
   begin
      if Info.Expected_Exception_Kind = Entity_Unknown
        or else Info.Actual_Exception_Kind = Entity_Unknown
      then
         return True;
      elsif Info.Actual_Exception_Kind = Info.Expected_Exception_Kind then
         return True;
      elsif Info.Expected_Exception_Kind = Entity_Exception
        and then Info.Actual_Exception_Kind = Entity_Renamed_Exception
      then
         return True;
      else
         return False;
      end if;
   end Exception_Kind_Compatible;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Context_Blockers
        + R.Exception_Missing_Blockers
        + R.Exception_Visibility_Blockers
        + R.Exception_Kind_Blockers
        + R.Handler_Missing_Blockers
        + R.Handler_Duplicate_Blockers
        + R.Handler_Unreachable_Blockers
        + R.Reraise_Blockers
        + R.Propagation_Blockers
        + R.Finalization_Missing_Blockers
        + R.Finalization_Order_Blockers
        + R.Adjust_Finalize_Blockers
        + R.Limited_Finalization_Blockers
        + R.Abort_Finalization_Blockers
        + R.Task_Termination_Blockers
        + R.Accessibility_Blockers
        + R.Renaming_Blockers
        + R.Shared_State_Blockers
        + R.Representation_Blockers
        + R.Predicate_Blockers
        + R.Elaboration_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Effect_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; Info : Event_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Context_Blockers > 0 then
         return Legality_Missing_Context;
      elsif R.Exception_Missing_Blockers > 0 then
         return Legality_Exception_Missing;
      elsif R.Exception_Visibility_Blockers > 0 then
         return Legality_Exception_Not_Visible;
      elsif R.Exception_Kind_Blockers > 0 then
         return Legality_Exception_Kind_Mismatch;
      elsif R.Handler_Missing_Blockers > 0 then
         return Legality_Handler_Choice_Missing;
      elsif R.Handler_Duplicate_Blockers > 0 then
         return Legality_Handler_Choice_Duplicate;
      elsif R.Handler_Unreachable_Blockers > 0 then
         return Legality_Handler_Choice_Unreachable;
      elsif R.Reraise_Blockers > 0 then
         return Legality_Reraise_Outside_Handler;
      elsif R.Propagation_Blockers > 0 then
         return Legality_Propagation_Unhandled;
      elsif R.Finalization_Missing_Blockers > 0 then
         return Legality_Finalization_Missing;
      elsif R.Finalization_Order_Blockers > 0 then
         return Legality_Finalization_Order_Mismatch;
      elsif R.Adjust_Finalize_Blockers > 0 then
         return Legality_Controlled_Adjust_Finalize_Mismatch;
      elsif R.Limited_Finalization_Blockers > 0 then
         return Legality_Limited_Finalization_Blocked;
      elsif R.Abort_Finalization_Blockers > 0 then
         return Legality_Abort_Finalization_Unsafe;
      elsif R.Task_Termination_Blockers > 0 then
         return Legality_Task_Termination_Finalization_Blocked;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocked;
      elsif R.Renaming_Blockers > 0 then
         return Legality_Renaming_Blocked;
      elsif R.Shared_State_Blockers > 0 then
         return Legality_Shared_State_Blocked;
      elsif R.Representation_Blockers > 0 then
         return Legality_Representation_Blocked;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocked;
      elsif R.Elaboration_Blockers > 0 then
         return Legality_Elaboration_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Effect_Fingerprint_Blockers > 0 then
         return Legality_Effect_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif Info.Kind = Event_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Clear (Model : in out Event_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Event (Model : in out Event_Model; Info : Event_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Event_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Effect_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Event;

   function Build (Events : Event_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Info of Events.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Event := Info.Id;
            R.Node := Info.Node;
            R.Kind := Info.Kind;
            R.Propagation := Info.Propagation;
            R.Runtime_Check_Required := Info.Runtime_Check_Required;
            R.Source_Fingerprint := Info.Source_Fingerprint;
            R.AST_Fingerprint := Info.AST_Fingerprint;
            R.Effect_Fingerprint := Info.Effect_Fingerprint;
            R.Substitution_Fingerprint := Info.Substitution_Fingerprint;

            if not Info.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;
            if not Info.Has_Context then
               R.Context_Blockers := R.Context_Blockers + 1;
            end if;
            if Is_Raise (Info.Kind) or else Info.Kind = Event_Exception_Renaming then
               if not Info.Has_Exception_Entity then
                  R.Exception_Missing_Blockers := R.Exception_Missing_Blockers + 1;
               elsif not Info.Exception_Visible then
                  R.Exception_Visibility_Blockers := R.Exception_Visibility_Blockers + 1;
               elsif not Exception_Kind_Compatible (Info) then
                  R.Exception_Kind_Blockers := R.Exception_Kind_Blockers + 1;
               elsif Info.Exception_Type /= Type_Exception then
                  R.Exception_Kind_Blockers := R.Exception_Kind_Blockers + 1;
               end if;
            end if;
            if Is_Handler (Info.Kind) then
               if not Info.Handler_Choice_Present then
                  R.Handler_Missing_Blockers := R.Handler_Missing_Blockers + 1;
               end if;
               if Info.Handler_Choice_Duplicate then
                  R.Handler_Duplicate_Blockers := R.Handler_Duplicate_Blockers + 1;
               end if;
               if not Info.Handler_Choice_Reachable then
                  R.Handler_Unreachable_Blockers := R.Handler_Unreachable_Blockers + 1;
               end if;
            end if;
            if Info.Propagation = Propagation_Reraises and then not Info.In_Exception_Handler then
               R.Reraise_Blockers := R.Reraise_Blockers + 1;
            end if;
            if Info.Requires_Local_Handler
              and then Info.Propagation in Propagation_Propagates | Propagation_Unknown
            then
               R.Propagation_Blockers := R.Propagation_Blockers + 1;
            end if;
            if Is_Finalization (Info.Kind) then
               if not Info.Has_Finalization_Procedure then
                  R.Finalization_Missing_Blockers := R.Finalization_Missing_Blockers + 1;
               end if;
               if not Info.Finalization_Order_Legal then
                  R.Finalization_Order_Blockers := R.Finalization_Order_Blockers + 1;
               end if;
               if not Info.Adjust_Finalize_Profile_Matches then
                  R.Adjust_Finalize_Blockers := R.Adjust_Finalize_Blockers + 1;
               end if;
            end if;
            if Info.Kind = Event_Limited_Controlled_Finalization
              and then not Info.Limited_Finalization_Legal
            then
               R.Limited_Finalization_Blockers := R.Limited_Finalization_Blockers + 1;
            end if;
            if Info.Kind in Event_Abort_Finalization | Event_Abortable_Select_Finalization
              and then not Info.Abort_Finalization_Safe
            then
               R.Abort_Finalization_Blockers := R.Abort_Finalization_Blockers + 1;
            end if;
            if Info.Kind = Event_Task_Termination_Finalization
              and then not Info.Task_Termination_Finalization_Legal
            then
               R.Task_Termination_Blockers := R.Task_Termination_Blockers + 1;
            end if;
            if not Info.Accessibility_Legal then
               R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
            end if;
            if not Info.Renaming_Legal then
               R.Renaming_Blockers := R.Renaming_Blockers + 1;
            end if;
            if not Info.Shared_State_Legal then
               R.Shared_State_Blockers := R.Shared_State_Blockers + 1;
            end if;
            if not Info.Representation_Legal then
               R.Representation_Blockers := R.Representation_Blockers + 1;
            end if;
            if not Info.Predicate_Legal then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            end if;
            if not Info.Elaboration_Legal then
               R.Elaboration_Blockers := R.Elaboration_Blockers + 1;
            end if;
            if Info.Expected_Source_Fingerprint /= 0
              and then Info.Expected_Source_Fingerprint /= Info.Source_Fingerprint
            then
               R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_AST_Fingerprint /= 0
              and then Info.Expected_AST_Fingerprint /= Info.AST_Fingerprint
            then
               R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_Effect_Fingerprint /= 0
              and then Info.Expected_Effect_Fingerprint /= Info.Effect_Fingerprint
            then
               R.Effect_Fingerprint_Blockers := R.Effect_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_Substitution_Fingerprint /= 0
              and then Info.Expected_Substitution_Fingerprint /= Info.Substitution_Fingerprint
            then
               R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, Info);
            R.Message := To_Unbounded_String (Legality_Status'Image (R.Status));
            R.Detail := Info.Source_Name;
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Event_Kind'Pos (R.Kind)));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Effect_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Substitution_Fingerprint);

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

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

   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural is
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
   begin
      return Count_Status (Model, Legality_Legal)
        + Count_Status (Model, Legality_Legal_With_Runtime_Check);
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
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Exception_Finalization_Vertical_Slice_Legality;
