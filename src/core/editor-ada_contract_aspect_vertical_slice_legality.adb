with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Contract_Aspect_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1329) mod 1_000_000_007;
   end Mix;

   function Is_Callable (Kind : Subject_Kind) return Boolean is
   begin
      return Kind = Subject_Subprogram
        or else Kind = Subject_Function
        or else Kind = Subject_Procedure;
   end Is_Callable;

   function Is_Type_Target (Kind : Subject_Kind) return Boolean is
   begin
      return Kind = Subject_Type;
   end Is_Type_Target;

   function Is_Unit_Target (Kind : Subject_Kind) return Boolean is
   begin
      return Kind = Subject_Package
        or else Kind = Subject_Generic_Unit;
   end Is_Unit_Target;

   function Mode_Compatible (Required, Actual : Global_Mode) return Boolean is
   begin
      if Required = Global_Unspecified or else Actual = Global_Unspecified then
         return True;
      elsif Required = Actual then
         return True;
      elsif Required = Global_In and then Actual = Global_Proof_In then
         return True;
      elsif Required = Global_In_Out
        and then (Actual = Global_In or else Actual = Global_Out)
      then
         return False;
      else
         return False;
      end if;
   end Mode_Compatible;

   function Find_Subject (Model : Subject_Model; Id : Entity_Id) return Subject_Info is
   begin
      for S of Model.Items loop
         if S.Id = Id then
            return S;
         end if;
      end loop;
      return (others => <>);
   end Find_Subject;

   function Find_Type (Model : Type_Model; Id : Type_Id) return Type_Info is
   begin
      for T of Model.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   procedure Add_View_Blocker (View : View_Kind; R : in out Result_Info) is
   begin
      case View is
         when View_Private =>
            R.Private_View_Blockers := 1;
         when View_Limited =>
            R.Limited_View_Blockers := 1;
         when View_Incomplete =>
            R.Incomplete_View_Blockers := 1;
         when View_Generic_Formal =>
            R.Generic_Formal_View_Blockers := 1;
         when others =>
            null;
      end case;
   end Add_View_Blocker;

   procedure Add_Subject_Evidence_Blockers (S : Subject_Info; R : in out Result_Info) is
   begin
      if S.Id = No_Entity then
         return;
      end if;
      Add_View_Blocker (S.View, R);
      if S.Source_Fingerprint /= S.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if S.Type_Fingerprint /= S.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
      if S.Profile_Fingerprint /= S.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if S.State_Fingerprint /= S.Expected_State_Fingerprint then
         R.State_Fingerprint_Blockers := 1;
      end if;
      if S.Effect_Fingerprint /= S.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Subject_Evidence_Blockers;

   procedure Add_Type_Evidence_Blockers (T : Type_Info; R : in out Result_Info) is
   begin
      if T.Id = No_Type then
         return;
      end if;
      Add_View_Blocker (T.View, R);
      if T.Source_Fingerprint /= T.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if T.Type_Fingerprint /= T.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
   end Add_Type_Evidence_Blockers;

   procedure Add_Aspect_Fingerprint_Blockers (A : Aspect_Info; R : in out Result_Info) is
   begin
      if A.Source_Fingerprint /= A.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if A.AST_Fingerprint /= A.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if A.Type_Fingerprint /= A.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
      if A.Profile_Fingerprint /= A.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if A.State_Fingerprint /= A.Expected_State_Fingerprint then
         R.State_Fingerprint_Blockers := 1;
      end if;
      if A.Effect_Fingerprint /= A.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Aspect_Fingerprint_Blockers;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Aspect_Blockers
        + R.Missing_Target_Blockers
        + R.Missing_Expression_Type_Blockers
        + R.Missing_State_Blockers
        + R.Missing_Constituent_Blockers
        + R.Target_Mismatch_Blockers
        + R.Boolean_Expression_Blockers
        + R.Static_Expression_Blockers
        + R.Global_Mode_Blockers
        + R.Depends_Target_Blockers
        + R.Depends_Source_Blockers
        + R.Depends_Cycle_Blockers
        + R.Refinement_Abstract_State_Blockers
        + R.Refinement_Extra_Constituent_Blockers
        + R.Refinement_Mode_Blockers
        + R.Preelaborable_Init_Blockers
        + R.No_Return_Target_Blockers
        + R.No_Return_Fallthrough_Blockers
        + R.Convention_Profile_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.State_Fingerprint_Blockers
        + R.Effect_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count = 0 then
         if R.Runtime_Check_Count > 0 then
            return Legality_Legal_With_Runtime_Check;
         else
            return Legality_Legal;
         end if;
      elsif Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Aspect_Blockers > 0 then
         return Legality_Missing_Aspect;
      elsif R.Missing_Target_Blockers > 0 then
         return Legality_Missing_Target;
      elsif R.Missing_Expression_Type_Blockers > 0 then
         return Legality_Missing_Expression_Type;
      elsif R.Missing_State_Blockers > 0 then
         return Legality_Missing_State;
      elsif R.Missing_Constituent_Blockers > 0 then
         return Legality_Missing_Constituent;
      elsif R.Target_Mismatch_Blockers > 0 then
         return Legality_Aspect_Target_Mismatch;
      elsif R.Boolean_Expression_Blockers > 0 then
         return Legality_Boolean_Expression_Required;
      elsif R.Static_Expression_Blockers > 0 then
         return Legality_Static_Expression_Required;
      elsif R.Global_Mode_Blockers > 0 then
         return Legality_Global_Mode_Mismatch;
      elsif R.Depends_Target_Blockers > 0 then
         return Legality_Depends_Target_Missing;
      elsif R.Depends_Source_Blockers > 0 then
         return Legality_Depends_Source_Missing;
      elsif R.Depends_Cycle_Blockers > 0 then
         return Legality_Depends_Cycle;
      elsif R.Refinement_Abstract_State_Blockers > 0 then
         return Legality_Refinement_Without_Abstract_State;
      elsif R.Refinement_Extra_Constituent_Blockers > 0 then
         return Legality_Refinement_Extra_Constituent;
      elsif R.Refinement_Mode_Blockers > 0 then
         return Legality_Refinement_Mode_Mismatch;
      elsif R.Preelaborable_Init_Blockers > 0 then
         return Legality_Preelaborable_Initialization_Blocker;
      elsif R.No_Return_Target_Blockers > 0 then
         return Legality_No_Return_Target_Invalid;
      elsif R.No_Return_Fallthrough_Blockers > 0 then
         return Legality_No_Return_Fallthrough;
      elsif R.Convention_Profile_Blockers > 0 then
         return Legality_Convention_Profile_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Legality_Generic_Formal_View_Barrier;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif R.State_Fingerprint_Blockers > 0 then
         return Legality_State_Fingerprint_Mismatch;
      elsif R.Effect_Fingerprint_Blockers > 0 then
         return Legality_Effect_Fingerprint_Mismatch;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   procedure Clear (Model : in out Subject_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Aspect_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Subject (Model : in out Subject_Model; Info : Subject_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Subject_Kind'Pos (Info.Kind)));
   end Add_Subject;

   procedure Add_Type (Model : in out Type_Model; Info : Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Type_Kind'Pos (Info.Kind)));
   end Add_Type;

   procedure Add_Aspect (Model : in out Aspect_Model; Info : Aspect_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Aspect_Kind'Pos (Info.Kind)));
   end Add_Aspect;

   function Build
     (Subjects : Subject_Model;
      Types : Type_Model;
      Aspects : Aspect_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      for A of Aspects.Items loop
         declare
            Target : constant Subject_Info := Find_Subject (Subjects, A.Target);
            Expr_T : constant Type_Info := Find_Type (Types, A.Expression_Type);
            Target_T : constant Type_Info := Find_Type (Types, Target.Typ);
            State_Target : constant Subject_Info := Find_Subject (Subjects, A.State_Target);
            State_Source : constant Subject_Info := Find_Subject (Subjects, A.State_Source);
            Constituent : constant Subject_Info := Find_Subject (Subjects, A.Constituent);
            R : Result_Info;
         begin
            R.Id := Result_Id (Natural (A.Id));
            R.Aspect := A.Id;
            R.Kind := A.Kind;

            if A.Id = No_Aspect or else A.Kind = Aspect_Unknown then
               R.Missing_Aspect_Blockers := 1;
            end if;

            Add_Aspect_Fingerprint_Blockers (A, R);

            if A.Target = No_Entity or else Target.Id = No_Entity then
               R.Missing_Target_Blockers := 1;
            else
               Add_Subject_Evidence_Blockers (Target, R);
               Add_Type_Evidence_Blockers (Target_T, R);
            end if;

            case A.Kind is
               when Aspect_Pre | Aspect_Post =>
                  if not Is_Callable (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if A.Expression_Type = No_Type or else Expr_T.Id = No_Type then
                     R.Missing_Expression_Type_Blockers := 1;
                  else
                     Add_Type_Evidence_Blockers (Expr_T, R);
                     if not A.Boolean_Expression_OK
                       or else (not Expr_T.Is_Boolean and then Expr_T.Kind /= Type_Boolean)
                     then
                        R.Boolean_Expression_Blockers := 1;
                     end if;
                  end if;
                  if A.Runtime_Check_Required then
                     R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
                  end if;

               when Aspect_Type_Invariant
                  | Aspect_Static_Predicate
                  | Aspect_Dynamic_Predicate
                  | Aspect_Default_Initial_Condition =>
                  if not Is_Type_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if A.Expression_Type = No_Type or else Expr_T.Id = No_Type then
                     R.Missing_Expression_Type_Blockers := 1;
                  else
                     Add_Type_Evidence_Blockers (Expr_T, R);
                     if not A.Boolean_Expression_OK
                       or else (not Expr_T.Is_Boolean and then Expr_T.Kind /= Type_Boolean)
                     then
                        R.Boolean_Expression_Blockers := 1;
                     end if;
                  end if;
                  if A.Kind = Aspect_Static_Predicate and then not A.Is_Static_Expression then
                     R.Static_Expression_Blockers := 1;
                  end if;
                  if A.Kind = Aspect_Dynamic_Predicate
                    or else A.Runtime_Check_Required
                    or else Target_T.Predicate_Runtime_Check
                  then
                     R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
                  end if;
                  if A.Kind = Aspect_Default_Initial_Condition
                    and then (Target_T.Has_Controlled_Component
                              or else Target_T.Has_Task_Component
                              or else Target_T.Has_Protected_Component)
                    and then not A.Preelaborable_Init_OK
                  then
                     R.Preelaborable_Init_Blockers := 1;
                  end if;

               when Aspect_Initial_Condition =>
                  if not Is_Unit_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if A.Expression_Type = No_Type or else Expr_T.Id = No_Type then
                     R.Missing_Expression_Type_Blockers := 1;
                  else
                     Add_Type_Evidence_Blockers (Expr_T, R);
                     if not A.Boolean_Expression_OK
                       or else (not Expr_T.Is_Boolean and then Expr_T.Kind /= Type_Boolean)
                     then
                        R.Boolean_Expression_Blockers := 1;
                     end if;
                  end if;

               when Aspect_Global | Aspect_Refined_Global =>
                  if not Is_Callable (Target.Kind) and then not Is_Unit_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if not Mode_Compatible (A.Required_Global_Mode, A.Actual_Global_Mode)
                    or else (Target.Global_Mode /= Global_Unspecified
                             and then not Mode_Compatible (A.Required_Global_Mode, Target.Global_Mode))
                  then
                     R.Global_Mode_Blockers := 1;
                  end if;
                  if A.Kind = Aspect_Refined_Global
                    and then not (Target.Has_Abstract_State or else A.Refinement_Has_Abstract_State)
                  then
                     R.Refinement_Abstract_State_Blockers := 1;
                  end if;

               when Aspect_Depends | Aspect_Refined_Depends =>
                  if not Is_Callable (Target.Kind) and then not Is_Unit_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if not A.Depends_Target_Present or else State_Target.Id = No_Entity then
                     R.Depends_Target_Blockers := 1;
                  else
                     Add_Subject_Evidence_Blockers (State_Target, R);
                  end if;
                  if not A.Depends_Source_Present or else State_Source.Id = No_Entity then
                     R.Depends_Source_Blockers := 1;
                  else
                     Add_Subject_Evidence_Blockers (State_Source, R);
                  end if;
                  if A.Depends_Cycle then
                     R.Depends_Cycle_Blockers := 1;
                  end if;
                  if A.Kind = Aspect_Refined_Depends
                    and then not (Target.Has_Abstract_State or else A.Refinement_Has_Abstract_State)
                  then
                     R.Refinement_Abstract_State_Blockers := 1;
                  end if;

               when Aspect_Abstract_State =>
                  if not Is_Unit_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if A.State_Target = No_Entity or else State_Target.Id = No_Entity then
                     R.Missing_State_Blockers := 1;
                  else
                     Add_Subject_Evidence_Blockers (State_Target, R);
                  end if;

               when Aspect_Refined_State =>
                  if not Is_Unit_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if not (Target.Has_Abstract_State or else A.Refinement_Has_Abstract_State) then
                     R.Refinement_Abstract_State_Blockers := 1;
                  end if;
                  if A.Constituent = No_Entity or else Constituent.Id = No_Entity
                    or else not A.Constituent_Present
                  then
                     R.Missing_Constituent_Blockers := 1;
                  else
                     Add_Subject_Evidence_Blockers (Constituent, R);
                  end if;
                  if A.Extra_Constituent then
                     R.Refinement_Extra_Constituent_Blockers := 1;
                  end if;
                  if not A.Constituent_Mode_OK then
                     R.Refinement_Mode_Blockers := 1;
                  end if;

               when Aspect_Preelaborable_Initialization =>
                  if not Is_Type_Target (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if not A.Preelaborable_Init_OK
                    or else Target_T.Has_Controlled_Component
                    or else Target_T.Has_Task_Component
                    or else Target_T.Has_Protected_Component
                    or else Target_T.Has_Access_Component
                  then
                     R.Preelaborable_Init_Blockers := 1;
                  end if;

               when Aspect_No_Return =>
                  if not Is_Callable (Target.Kind) or else Target.Kind = Subject_Function then
                     R.No_Return_Target_Blockers := 1;
                  end if;
                  if not A.No_Return_Target_OK then
                     R.No_Return_Target_Blockers := 1;
                  end if;
                  if A.No_Return_Fallthrough or else Target.Callable_May_Return then
                     R.No_Return_Fallthrough_Blockers := 1;
                  end if;

               when Aspect_Inline =>
                  if not Is_Callable (Target.Kind) then
                     R.Target_Mismatch_Blockers := 1;
                  end if;

               when Aspect_Convention =>
                  if not Is_Callable (Target.Kind)
                    and then not Is_Type_Target (Target.Kind)
                    and then Target.Kind /= Subject_Object
                  then
                     R.Target_Mismatch_Blockers := 1;
                  end if;
                  if not A.Convention_Profile_OK or else not Target.Profile_Convention_OK then
                     R.Convention_Profile_Blockers := 1;
                  end if;

               when Aspect_Unknown =>
                  null;
            end case;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, R.Runtime_Check_Count);
            R.Message := To_Unbounded_String ("contract/aspect vertical slice");
            R.Detail := To_Unbounded_String (Legality_Status'Image (R.Status));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Subject_Count (Model : Subject_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Subject_Count;

   function Type_Count (Model : Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Type_Count;

   function Aspect_Count (Model : Aspect_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Aspect_Count;

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
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Legality_Legal
           or else R.Status = Legality_Legal_With_Runtime_Check
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status /= Legality_Legal
           and then R.Status /= Legality_Legal_With_Runtime_Check
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Contract_Aspect_Vertical_Slice_Legality;
