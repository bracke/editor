package body Editor.Ada_Flow_Refinement_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1334) mod 1_000_000_007;
   end Mix;

   function Find_Entity (Model : Entity_Model; Id : Entity_Id) return Entity_Info is
   begin
      for E of Model.Items loop
         if E.Id = Id then
            return E;
         end if;
      end loop;
      return (others => <>);
   end Find_Entity;

   function Find_State (Model : State_Model; Id : State_Id) return State_Info is
   begin
      for S of Model.Items loop
         if S.Id = Id then
            return S;
         end if;
      end loop;
      return (others => <>);
   end Find_State;

   function Find_Flow (Model : Flow_Model; Id : Flow_Id) return Flow_Info is
   begin
      for F of Model.Items loop
         if F.Id = Id then
            return F;
         end if;
      end loop;
      return (others => <>);
   end Find_Flow;

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

   procedure Add_Entity_Evidence_Blockers (E : Entity_Info; R : in out Result_Info) is
   begin
      if E.Id = No_Entity then
         return;
      end if;

      Add_View_Blocker (E.View, R);

      if E.Source_Fingerprint /= E.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if E.AST_Fingerprint /= E.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if E.State_Fingerprint /= E.Expected_State_Fingerprint then
         R.State_Fingerprint_Blockers := 1;
      end if;
      if E.Flow_Fingerprint /= E.Expected_Flow_Fingerprint then
         R.Flow_Fingerprint_Blockers := 1;
      end if;
      if E.Profile_Fingerprint /= E.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if E.Substitution_Fingerprint /= E.Expected_Substitution_Fingerprint then
         R.Substitution_Fingerprint_Blockers := 1;
      end if;
      if E.Effect_Fingerprint /= E.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Entity_Evidence_Blockers;

   procedure Add_State_Evidence_Blockers (S : State_Info; R : in out Result_Info) is
   begin
      if S.Id = No_State then
         return;
      end if;

      Add_View_Blocker (S.View, R);

      if S.Source_Fingerprint /= S.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if S.AST_Fingerprint /= S.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if S.State_Fingerprint /= S.Expected_State_Fingerprint then
         R.State_Fingerprint_Blockers := 1;
      end if;
      if S.Flow_Fingerprint /= S.Expected_Flow_Fingerprint then
         R.Flow_Fingerprint_Blockers := 1;
      end if;
   end Add_State_Evidence_Blockers;

   procedure Add_Flow_Evidence_Blockers (F : Flow_Info; R : in out Result_Info) is
   begin
      if F.Id = No_Flow then
         return;
      end if;

      if F.Source_Fingerprint /= F.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if F.AST_Fingerprint /= F.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if F.Flow_Fingerprint /= F.Expected_Flow_Fingerprint then
         R.Flow_Fingerprint_Blockers := 1;
      end if;
      if F.Effect_Fingerprint /= F.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Flow_Evidence_Blockers;

   procedure Add_Check_Fingerprint_Blockers (C : Check_Info; R : in out Result_Info) is
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if C.AST_Fingerprint /= C.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if C.State_Fingerprint /= C.Expected_State_Fingerprint then
         R.State_Fingerprint_Blockers := 1;
      end if;
      if C.Flow_Fingerprint /= C.Expected_Flow_Fingerprint then
         R.Flow_Fingerprint_Blockers := 1;
      end if;
      if C.Profile_Fingerprint /= C.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         R.Substitution_Fingerprint_Blockers := 1;
      end if;
      if C.Effect_Fingerprint /= C.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Check_Fingerprint_Blockers;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Check_Blockers
        + R.Missing_Entity_Blockers
        + R.Missing_State_Blockers
        + R.Missing_Flow_Blockers
        + R.Entity_Kind_Blockers
        + R.Refined_Global_Missing_Blockers
        + R.Global_Mode_Blockers
        + R.Refined_Depends_Missing_Blockers
        + R.Depends_Source_Blockers
        + R.Depends_Target_Blockers
        + R.Depends_Cycle_Blockers
        + R.Constituent_Missing_Blockers
        + R.Constituent_Extra_Blockers
        + R.Constituent_Mode_Blockers
        + R.Initialization_Missing_Blockers
        + R.Initialization_Order_Blockers
        + R.Data_Dependency_Blockers
        + R.Dispatching_Effect_Join_Blockers
        + R.Generic_Substitution_Blockers
        + R.Volatile_Ordering_Blockers
        + R.Atomic_Ordering_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.State_Fingerprint_Blockers
        + R.Flow_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers
        + R.Effect_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info) return Legality_Status is
      C : constant Natural := Blocker_Count (R);
   begin
      if C = 0 then
         return Legality_Legal;
      elsif C > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Check_Blockers > 0 then
         return Legality_Missing_Check;
      elsif R.Missing_Entity_Blockers > 0 then
         return Legality_Missing_Entity;
      elsif R.Missing_State_Blockers > 0 then
         return Legality_Missing_State;
      elsif R.Missing_Flow_Blockers > 0 then
         return Legality_Missing_Flow;
      elsif R.Entity_Kind_Blockers > 0 then
         return Legality_Entity_Kind_Mismatch;
      elsif R.Refined_Global_Missing_Blockers > 0 then
         return Legality_Refined_Global_Missing;
      elsif R.Global_Mode_Blockers > 0 then
         return Legality_Global_Mode_Mismatch;
      elsif R.Refined_Depends_Missing_Blockers > 0 then
         return Legality_Refined_Depends_Missing;
      elsif R.Depends_Source_Blockers > 0 then
         return Legality_Depends_Source_Missing;
      elsif R.Depends_Target_Blockers > 0 then
         return Legality_Depends_Target_Missing;
      elsif R.Depends_Cycle_Blockers > 0 then
         return Legality_Depends_Cycle;
      elsif R.Constituent_Missing_Blockers > 0 then
         return Legality_Constituent_Missing;
      elsif R.Constituent_Extra_Blockers > 0 then
         return Legality_Constituent_Extra;
      elsif R.Constituent_Mode_Blockers > 0 then
         return Legality_Constituent_Mode_Mismatch;
      elsif R.Initialization_Missing_Blockers > 0 then
         return Legality_Initialization_Missing;
      elsif R.Initialization_Order_Blockers > 0 then
         return Legality_Initialization_Order_Mismatch;
      elsif R.Data_Dependency_Blockers > 0 then
         return Legality_Data_Dependency_Mismatch;
      elsif R.Dispatching_Effect_Join_Blockers > 0 then
         return Legality_Dispatching_Effect_Join_Mismatch;
      elsif R.Generic_Substitution_Blockers > 0 then
         return Legality_Generic_Substitution_Mismatch;
      elsif R.Volatile_Ordering_Blockers > 0 then
         return Legality_Volatile_Ordering_Mismatch;
      elsif R.Atomic_Ordering_Blockers > 0 then
         return Legality_Atomic_Ordering_Mismatch;
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
      elsif R.State_Fingerprint_Blockers > 0 then
         return Legality_State_Fingerprint_Mismatch;
      elsif R.Flow_Fingerprint_Blockers > 0 then
         return Legality_Flow_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif R.Effect_Fingerprint_Blockers > 0 then
         return Legality_Effect_Fingerprint_Mismatch;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   procedure Clear (Model : in out Entity_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out State_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Flow_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Check_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Result_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Entity (Model : in out Entity_Model; Item : Entity_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Entity_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Effect_Fingerprint);
   end Add_Entity;

   procedure Add_State (Model : in out State_Model; Item : State_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Flow_Mode'Pos (Item.Mode)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.State_Fingerprint);
   end Add_State;

   procedure Add_Flow (Model : in out Flow_Model; Item : Flow_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Flow_Mode'Pos (Item.Mode)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Flow_Fingerprint);
   end Add_Flow;

   procedure Add_Check (Model : in out Check_Model; Item : Check_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Check_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
   end Add_Check;

   procedure Add_Result (Model : in out Result_Model; Item : Result_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Legality_Status'Pos (Item.Status)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_Result;

   function Build
     (Entities : Entity_Model;
      States : State_Model;
      Flows : Flow_Model;
      Checks : Check_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      if Checks.Items.Is_Empty then
         declare
            R : Result_Info;
         begin
            R.Id := 1;
            R.Missing_Check_Blockers := 1;
            R.Status := Status_For (R);
            R.Fingerprint := Mix (1334, Natural (Legality_Status'Pos (R.Status)));
            Add_Result (Results, R);
         end;
      end if;

      for C of Checks.Items loop
         declare
            E : constant Entity_Info := Find_Entity (Entities, C.Operation);
            S : constant State_Info := Find_State (States, C.State);
            F : constant Flow_Info := Find_Flow (Flows, C.Flow);
            R : Result_Info;
         begin
            R.Id := Result_Id (Natural (C.Id));
            R.Check := C.Id;
            R.Source_Node := C.Node;

            Add_Check_Fingerprint_Blockers (C, R);
            Add_Entity_Evidence_Blockers (E, R);
            Add_State_Evidence_Blockers (S, R);
            Add_Flow_Evidence_Blockers (F, R);

            if E.Id = No_Entity then
               R.Missing_Entity_Blockers := 1;
            end if;
            if C.State /= No_State and then S.Id = No_State then
               R.Missing_State_Blockers := 1;
            end if;
            if C.Flow /= No_Flow and then F.Id = No_Flow then
               R.Missing_Flow_Blockers := 1;
            end if;

            if E.Id /= No_Entity
              and then C.Expected_Entity_Kind /= Entity_Unknown
              and then E.Kind /= C.Expected_Entity_Kind
            then
               R.Entity_Kind_Blockers := 1;
            end if;

            case C.Kind is
               when Check_Refined_Global =>
                  if E.Id /= No_Entity then
                     if C.Requires_Refined_Global and then not E.Has_Refined_Global then
                        R.Refined_Global_Missing_Blockers := 1;
                     end if;
                     if not E.Refined_Global_Mode_OK then
                        R.Global_Mode_Blockers := 1;
                     end if;
                     if C.Expected_Mode /= Mode_Unknown and then S.Id /= No_State
                       and then S.Mode /= C.Expected_Mode
                     then
                        R.Global_Mode_Blockers := 1;
                     end if;
                  end if;

               when Check_Refined_Depends =>
                  if E.Id /= No_Entity then
                     if C.Requires_Refined_Depends and then not E.Has_Refined_Depends then
                        R.Refined_Depends_Missing_Blockers := 1;
                     end if;
                     if not E.Refined_Depends_OK then
                        R.Data_Dependency_Blockers := 1;
                     end if;
                  end if;
                  if F.Id /= No_Flow then
                     if C.Requires_Depends_Source and then not F.Source_Present then
                        R.Depends_Source_Blockers := 1;
                     end if;
                     if C.Requires_Depends_Target and then not F.Target_Present then
                        R.Depends_Target_Blockers := 1;
                     end if;
                     if C.Reject_Depends_Cycle and then F.Has_Cycle then
                        R.Depends_Cycle_Blockers := 1;
                     end if;
                     if not F.Data_Dependency_OK then
                        R.Data_Dependency_Blockers := 1;
                     end if;
                  end if;

               when Check_Abstract_State_Constituent_Flow =>
                  if S.Id /= No_State then
                     if C.Requires_Abstract_State and then not S.Has_Abstract_State then
                        R.Constituent_Missing_Blockers := 1;
                     end if;
                     if C.Requires_Constituent and then not S.Has_Constituent then
                        R.Constituent_Missing_Blockers := 1;
                     end if;
                     if C.Reject_Extra_Constituent and then S.Constituent_Extra then
                        R.Constituent_Extra_Blockers := 1;
                     end if;
                     if not S.Constituent_Mode_OK then
                        R.Constituent_Mode_Blockers := 1;
                     end if;
                  end if;

               when Check_Initialization_Flow =>
                  if S.Id /= No_State then
                     if C.Requires_Initialization and then not S.Initialized then
                        R.Initialization_Missing_Blockers := 1;
                     end if;
                     if not S.Initialization_Order_OK then
                        R.Initialization_Order_Blockers := 1;
                     end if;
                  end if;
                  if F.Id /= No_Flow and then not F.Initialization_OK then
                     R.Initialization_Order_Blockers := 1;
                  end if;

               when Check_Data_Dependency =>
                  if F.Id /= No_Flow then
                     if C.Requires_Depends_Source and then not F.Source_Present then
                        R.Depends_Source_Blockers := 1;
                     end if;
                     if C.Requires_Depends_Target and then not F.Target_Present then
                        R.Depends_Target_Blockers := 1;
                     end if;
                     if not F.Data_Dependency_OK then
                        R.Data_Dependency_Blockers := 1;
                     end if;
                     if C.Reject_Depends_Cycle and then F.Has_Cycle then
                        R.Depends_Cycle_Blockers := 1;
                     end if;
                  end if;

               when Check_Dispatching_Effect_Join =>
                  if E.Id /= No_Entity then
                     if E.Kind /= Entity_Dispatching_Operation then
                        R.Entity_Kind_Blockers := 1;
                     end if;
                     if C.Requires_Dispatching_Join and then not E.Dispatching_Effect_Join_OK then
                        R.Dispatching_Effect_Join_Blockers := 1;
                     end if;
                  end if;

               when Check_Generic_Substitution_Flow =>
                  if E.Id /= No_Entity then
                     if E.Kind /= Entity_Generic_Instance then
                        R.Entity_Kind_Blockers := 1;
                     end if;
                     if C.Requires_Generic_Substitution and then not E.Generic_Substitution_OK then
                        R.Generic_Substitution_Blockers := 1;
                     end if;
                  end if;

               when Check_Volatile_Atomic_Ordering =>
                  if E.Id /= No_Entity then
                     if C.Requires_Volatile_Ordering and then not E.Volatile_Ordering_OK then
                        R.Volatile_Ordering_Blockers := 1;
                     end if;
                     if C.Requires_Atomic_Ordering and then not E.Atomic_Ordering_OK then
                        R.Atomic_Ordering_Blockers := 1;
                     end if;
                  end if;
                  if F.Id /= No_Flow then
                     if C.Requires_Volatile_Ordering and then not F.Volatile_Ordering_OK then
                        R.Volatile_Ordering_Blockers := 1;
                     end if;
                     if C.Requires_Atomic_Ordering and then not F.Atomic_Ordering_OK then
                        R.Atomic_Ordering_Blockers := 1;
                     end if;
                  end if;

               when Check_Unknown =>
                  R.Missing_Check_Blockers := 1;
            end case;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (C.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, C.Source_Fingerprint);
            Add_Result (Results, R);
         end;
      end loop;

      return Results;
   end Build;

   function Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index - 1);
   end Result_At;

end Editor.Ada_Flow_Refinement_Vertical_Slice_Legality;
