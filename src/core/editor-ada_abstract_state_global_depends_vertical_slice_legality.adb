with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 997) + 1303) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : State_Status) return Boolean is
   begin
      return Status in State_Legal_Global
        | State_Legal_Depends
        | State_Legal_Refined_State
        | State_Legal_Constituent
        | State_Legal_Shared_Effect;
   end Is_Legal;

   function Is_Write (Mode : Flow_Mode) return Boolean is
   begin
      return Mode in Mode_Out | Mode_In_Out;
   end Is_Write;

   function Mode_Compatible (Actual, Allowed : Flow_Mode) return Boolean is
   begin
      if Actual = Mode_None or else Allowed = Mode_None then
         return True;
      elsif Actual = Allowed then
         return True;
      elsif Actual = Mode_In and then Allowed in Mode_In_Out | Mode_Proof_In then
         return True;
      elsif Actual = Mode_Out and then Allowed = Mode_In_Out then
         return True;
      elsif Actual = Mode_Proof_In and then Allowed in Mode_In | Mode_In_Out | Mode_Proof_In then
         return True;
      else
         return False;
      end if;
   end Mode_Compatible;

   function Find_State (Model : State_Model; Id : State_Id) return State_Info is
   begin
      for S of Model.Items loop
         if S.Id = Id then
            return S;
         end if;
      end loop;
      return (others => <>);
   end Find_State;

   function Find_Operation
     (Model : Operation_Model; Id : Operation_Id) return Operation_Info
   is
   begin
      for O of Model.Items loop
         if O.Id = Id then
            return O;
         end if;
      end loop;
      return (others => <>);
   end Find_Operation;

   function Duplicate_Name_Count (Model : State_Model; Info : State_Info) return Natural is
      Count : Natural := 0;
   begin
      if Info.Id = No_State then
         return 0;
      end if;

      for S of Model.Items loop
         if To_String (S.Name) = To_String (Info.Name)
           and then S.Is_Abstract = Info.Is_Abstract
           and then S.Id /= Info.Id
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Duplicate_Name_Count;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_State_Blockers
        + R.Missing_Operation_Blockers
        + R.Duplicate_State_Blockers
        + R.Mode_Blockers
        + R.Refined_State_Blockers
        + R.Constituent_Blockers
        + R.Visibility_Blockers
        + R.Depends_Blockers
        + R.Volatile_Blockers
        + R.Atomic_Blockers
        + R.Shared_Blockers
        + R.Source_Fingerprint_Blockers
        + R.State_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For
     (R : Result_Info;
      U : Use_Info;
      Target : State_Info;
      Source : State_Info) return State_Status
   is
      pragma Unreferenced (Target, Source);
   begin
      if R.Missing_State_Blockers > 0 then
         return State_Missing_State;
      elsif R.Missing_Operation_Blockers > 0 then
         return State_Missing_Operation;
      elsif R.Duplicate_State_Blockers > 0 then
         return State_Duplicate_Abstract_State;
      elsif R.Mode_Blockers > 0 then
         return State_Mode_Mismatch;
      elsif R.Refined_State_Blockers > 0 then
         return State_Missing_Refined_State_Aspect;
      elsif R.Constituent_Blockers > 0 then
         if U.Extra_Constituent then
            return State_Extra_Constituent;
         elsif not U.Constituent_Present then
            return State_Missing_Constituent;
         else
            return State_Constituent_Mode_Mismatch;
         end if;
      elsif R.Visibility_Blockers > 0 then
         return State_Invisible_Constituent;
      elsif R.Depends_Blockers > 0 then
         if U.Depends_Cycle then
            return State_Depends_Cycle;
         elsif Source.Id = No_State then
            return State_Depends_Missing_Source;
         else
            return State_Depends_Missing_Target;
         end if;
      elsif R.Volatile_Blockers > 0 then
         return State_Volatile_Ordering_Error;
      elsif R.Atomic_Blockers > 0 then
         return State_Atomic_Mixed_Access_Error;
      elsif R.Shared_Blockers > 0 then
         return State_Unprotected_Shared_Access;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return State_Source_Fingerprint_Mismatch;
      elsif R.State_Fingerprint_Blockers > 0 then
         return State_State_Fingerprint_Mismatch;
      elsif U.Kind = Use_Global then
         return State_Legal_Global;
      elsif U.Kind = Use_Depends_Edge then
         return State_Legal_Depends;
      elsif U.Kind = Use_Refined_State_Mapping then
         return State_Legal_Refined_State;
      elsif U.Kind = Use_Constituent_Declaration then
         return State_Legal_Constituent;
      elsif U.Kind in Use_Call_Effect | Use_Shared_State_Effect then
         return State_Legal_Shared_Effect;
      else
         return State_Indeterminate;
      end if;
   end Status_For;

   procedure Add_Message (R : in out Result_Info) is
   begin
      case R.Status is
         when State_Legal_Global =>
            R.Message := To_Unbounded_String ("Global aspect state usage is legal");
         when State_Legal_Depends =>
            R.Message := To_Unbounded_String ("Depends edge is legal");
         when State_Legal_Refined_State =>
            R.Message := To_Unbounded_String ("Refined_State mapping is legal");
         when State_Legal_Constituent =>
            R.Message := To_Unbounded_String ("state constituent declaration is legal");
         when State_Legal_Shared_Effect =>
            R.Message := To_Unbounded_String ("shared-state effect is legal");
         when State_Missing_State =>
            R.Message := To_Unbounded_String ("abstract/refined-state target is missing");
         when State_Missing_Operation =>
            R.Message := To_Unbounded_String ("Global/Depends operation is missing");
         when State_Duplicate_Abstract_State =>
            R.Message := To_Unbounded_String ("duplicate abstract state declaration");
         when State_Mode_Mismatch =>
            R.Message := To_Unbounded_String ("Global/Depends mode is incompatible with state contract");
         when State_Missing_Refined_State_Aspect =>
            R.Message := To_Unbounded_String ("required Refined_State aspect is missing");
         when State_Missing_Constituent =>
            R.Message := To_Unbounded_String ("required refined-state constituent is missing");
         when State_Extra_Constituent =>
            R.Message := To_Unbounded_String ("unexpected refined-state constituent");
         when State_Constituent_Mode_Mismatch =>
            R.Message := To_Unbounded_String ("refined-state constituent mode mismatch");
         when State_Invisible_Constituent =>
            R.Message := To_Unbounded_String ("state constituent is not visible at this point");
         when State_Depends_Missing_Source =>
            R.Message := To_Unbounded_String ("Depends source state is missing");
         when State_Depends_Missing_Target =>
            R.Message := To_Unbounded_String ("Depends target state is missing");
         when State_Depends_Cycle =>
            R.Message := To_Unbounded_String ("Depends relation introduces a state cycle");
         when State_Volatile_Ordering_Error =>
            R.Message := To_Unbounded_String ("volatile state read/write ordering is not proven");
         when State_Atomic_Mixed_Access_Error =>
            R.Message := To_Unbounded_String ("atomic and non-atomic state access are mixed");
         when State_Unprotected_Shared_Access =>
            R.Message := To_Unbounded_String ("shared state requires protected access");
         when State_Source_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("stale source fingerprint for state contract");
         when State_State_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("stale state fingerprint for state contract");
         when State_Multiple_Blockers =>
            R.Message := To_Unbounded_String ("multiple abstract/refined-state blockers");
         when State_Indeterminate | State_Not_Checked =>
            R.Message := To_Unbounded_String ("abstract/refined-state legality is indeterminate");
      end case;
   end Add_Message;

   procedure Clear (Model : in out State_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Operation_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Use_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_State (Model : in out State_Model; Info : State_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + State_Kind'Pos (Info.Kind) + Info.Source_Fingerprint + Info.State_Fingerprint);
   end Add_State;

   procedure Add_Operation (Model : in out Operation_Model; Info : Operation_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Flow_Mode'Pos (Info.Global_Mode) + Info.Source_Fingerprint + Info.Contract_Fingerprint);
   end Add_Operation;

   procedure Add_Use (Model : in out Use_Model; Info : Use_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Use_Kind'Pos (Info.Kind) + Info.Source_Fingerprint + Info.Use_Fingerprint);
   end Add_Use;

   function Build
     (States     : State_Model;
      Operations : Operation_Model;
      Uses       : Use_Model) return Result_Model
   is
      Result : Result_Model;
      Next_Id : Natural := 1;
   begin
      for U of Uses.Items loop
         declare
            Target : constant State_Info := Find_State (States, U.Target_State);
            Source : constant State_Info := Find_State (States, U.Source_State);
            Parent : constant State_Info := Find_State (States, U.Parent_State);
            Op     : constant Operation_Info := Find_Operation (Operations, U.Operation);
            R      : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Use_Ref := U.Id;
            R.Operation := U.Operation;
            R.Target_State := U.Target_State;
            R.Source_State := U.Source_State;
            R.Node := U.Node;

            if Op.Id = No_Operation then
               R.Missing_Operation_Blockers := R.Missing_Operation_Blockers + 1;
            end if;

            if Target.Id = No_State then
               R.Missing_State_Blockers := R.Missing_State_Blockers + 1;
            else
               R.Source_Fingerprint := Target.Source_Fingerprint;
               R.State_Fingerprint := Target.State_Fingerprint;
               if Duplicate_Name_Count (States, Target) > 0 then
                  R.Duplicate_State_Blockers := R.Duplicate_State_Blockers + 1;
               end if;
            end if;

            if U.Kind = Use_Depends_Edge then
               if Source.Id = No_State then
                  R.Depends_Blockers := R.Depends_Blockers + 1;
               elsif Target.Id = No_State then
                  R.Depends_Blockers := R.Depends_Blockers + 1;
               end if;
            end if;

            if R.Missing_State_Blockers = 0 and then R.Missing_Operation_Blockers = 0 then
               if Target.Source_Fingerprint = 0 or else Op.Source_Fingerprint = 0
                 or else U.Source_Fingerprint = 0
                 or else (U.Expected_Source_Fingerprint /= 0
                          and then U.Expected_Source_Fingerprint /= Target.Source_Fingerprint)
               then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;

               if Target.State_Fingerprint = 0
                 or else (U.Expected_State_Fingerprint /= 0
                          and then U.Expected_State_Fingerprint /= Target.State_Fingerprint)
               then
                  R.State_Fingerprint_Blockers := R.State_Fingerprint_Blockers + 1;
               end if;

               if not Mode_Compatible (U.Mode, Target.Allowed_Mode) then
                  R.Mode_Blockers := R.Mode_Blockers + 1;
               end if;

               if U.Kind = Use_Global and then not Op.Has_Global_Aspect then
                  R.Refined_State_Blockers := R.Refined_State_Blockers + 1;
               end if;

               if U.Kind = Use_Depends_Edge then
                  if not Op.Has_Depends_Aspect then
                     R.Depends_Blockers := R.Depends_Blockers + 1;
                  end if;
                  if not U.Depends_Source_Visible or else (Source.Id /= No_State and then not Source.Visible) then
                     R.Visibility_Blockers := R.Visibility_Blockers + 1;
                  end if;
                  if not U.Depends_Target_Visible or else not Target.Visible then
                     R.Visibility_Blockers := R.Visibility_Blockers + 1;
                  end if;
                  if U.Depends_Cycle then
                     R.Depends_Blockers := R.Depends_Blockers + 1;
                  end if;
               end if;

               if U.Kind in Use_Refined_State_Mapping | Use_Constituent_Declaration then
                  if not Op.Has_Refined_State_Aspect or else not U.Has_Refined_State_Aspect then
                     R.Refined_State_Blockers := R.Refined_State_Blockers + 1;
                  end if;
                  if not U.Constituent_Present or else U.Extra_Constituent
                    or else not U.Constituent_Mode_Matches
                  then
                     R.Constituent_Blockers := R.Constituent_Blockers + 1;
                  end if;
                  if not Target.Visible or else (Parent.Id /= No_State and then not Parent.Visible) then
                     R.Visibility_Blockers := R.Visibility_Blockers + 1;
                  end if;
               end if;

               if (Target.Is_Volatile or else Target.Kind = State_Volatile)
                 and then Is_Write (U.Mode)
                 and then not U.Volatile_Order_Known
               then
                  R.Volatile_Blockers := R.Volatile_Blockers + 1;
               end if;

               if (Target.Is_Atomic or else Target.Kind = State_Atomic)
                 and then not U.Atomic_Access_Consistent
               then
                  R.Atomic_Blockers := R.Atomic_Blockers + 1;
               end if;

               if (Target.Is_Shared or else Target.Kind = State_Shared or else Target.Requires_Protected_Access)
                 and then Is_Write (U.Mode)
                 and then not U.Shared_Access_Protected
               then
                  R.Shared_Blockers := R.Shared_Blockers + 1;
               end if;
            end if;

            if Blocker_Count (R) > 1 then
               R.Status := State_Multiple_Blockers;
            elsif U.Kind = Use_Unknown then
               R.Status := State_Indeterminate;
            else
               R.Status := Status_For (R, U, Target, Source);
            end if;

            Add_Message (R);
            R.Detail := To_Unbounded_String
              ("abstract/refined-state vertical slice use" & Natural'Image (Natural (U.Id)));
            R.Fingerprint := Mix
              (Natural (R.Id) + Natural (R.Use_Ref) + Natural (R.Operation)
               + Natural (R.Target_State) + Natural (R.Source_State)
               + State_Status'Pos (R.Status),
               R.Source_Fingerprint + R.State_Fingerprint + U.Use_Fingerprint
               + Blocker_Count (R));
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            Result.Items.Append (R);
         end;
      end loop;
      return Result;
   end Build;

   function State_Count (Model : State_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end State_Count;

   function Operation_Count (Model : Operation_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Operation_Count;

   function Use_Count (Model : Use_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Use_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : State_Status) return Natural is
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

end Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality;
