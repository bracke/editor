with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1330) mod 1_000_000_007;
   end Mix;

   function Is_Body (Kind : Unit_Kind) return Boolean is
   begin
      return Kind = Unit_Package_Body or else Kind = Unit_Subprogram_Body;
   end Is_Body;

   function Is_Generic_Unit (Kind : Unit_Kind) return Boolean is
   begin
      return Kind = Unit_Generic_Package or else Kind = Unit_Generic_Subprogram;
   end Is_Generic_Unit;

   function Is_Package_Unit (Kind : Unit_Kind) return Boolean is
   begin
      return Kind = Unit_Package_Spec
        or else Kind = Unit_Package_Body
        or else Kind = Unit_Generic_Package
        or else Kind = Unit_Child_Package
        or else Kind = Unit_Private_Child_Package;
   end Is_Package_Unit;

   function Is_Type_Target (Kind : Type_Kind) return Boolean is
   begin
      return Kind /= Type_Unknown;
   end Is_Type_Target;

   function Find_Unit (Model : Unit_Model; Id : Unit_Id) return Unit_Info is
   begin
      for U of Model.Items loop
         if U.Id = Id then
            return U;
         end if;
      end loop;
      return (others => <>);
   end Find_Unit;

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

   procedure Add_Unit_Evidence_Blockers (U : Unit_Info; R : in out Result_Info) is
   begin
      if U.Id = No_Unit then
         return;
      end if;
      Add_View_Blocker (U.View, R);
      if U.Source_Fingerprint /= U.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if U.Unit_Fingerprint /= U.Expected_Unit_Fingerprint then
         R.Unit_Fingerprint_Blockers := 1;
      end if;
      if U.View_Fingerprint /= U.Expected_View_Fingerprint then
         R.View_Fingerprint_Blockers := 1;
      end if;
      if U.Closure_Fingerprint /= U.Expected_Closure_Fingerprint then
         R.Closure_Fingerprint_Blockers := 1;
      end if;
   end Add_Unit_Evidence_Blockers;

   procedure Add_Type_Evidence_Blockers (T : Type_Info; R : in out Result_Info) is
   begin
      if T.Id = No_Type then
         return;
      end if;
      Add_View_Blocker (T.View, R);
      if T.Source_Fingerprint /= T.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if T.View_Fingerprint /= T.Expected_View_Fingerprint then
         R.View_Fingerprint_Blockers := 1;
      end if;
   end Add_Type_Evidence_Blockers;

   procedure Add_Clause_Fingerprint_Blockers
     (C : Clause_Info; R : in out Result_Info) is
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if C.Unit_Fingerprint /= C.Expected_Unit_Fingerprint then
         R.Unit_Fingerprint_Blockers := 1;
      end if;
      if C.View_Fingerprint /= C.Expected_View_Fingerprint then
         R.View_Fingerprint_Blockers := 1;
      end if;
      if C.Closure_Fingerprint /= C.Expected_Closure_Fingerprint then
         R.Closure_Fingerprint_Blockers := 1;
      end if;
   end Add_Clause_Fingerprint_Blockers;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Clause_Blockers
        + R.Missing_Context_Unit_Blockers
        + R.Missing_Target_Unit_Blockers
        + R.Unit_Name_Mismatch_Blockers
        + R.Duplicate_With_Blockers
        + R.Duplicate_Use_Blockers
        + R.Nonlimited_With_Cycle_Blockers
        + R.Private_With_Blockers
        + R.Private_Child_Blockers
        + R.Limited_View_Blockers
        + R.Private_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Use_Target_Package_Blockers
        + R.Use_Type_Target_Blockers
        + R.Use_Without_With_Blockers
        + R.Body_Context_Blockers
        + R.Generic_Context_Blockers
        + R.Ambiguous_Use_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Unit_Fingerprint_Blockers
        + R.View_Fingerprint_Blockers
        + R.Closure_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info) return Legality_Status is
      C : constant Natural := Blocker_Count (R);
   begin
      if C = 0 then
         if R.Runtime_Check_Count > 0 then
            return Legality_Legal_With_Limited_View;
         else
            return Legality_Legal;
         end if;
      elsif C > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Clause_Blockers > 0 then
         return Legality_Missing_Clause;
      elsif R.Missing_Context_Unit_Blockers > 0 then
         return Legality_Missing_Context_Unit;
      elsif R.Missing_Target_Unit_Blockers > 0 then
         return Legality_Missing_Target_Unit;
      elsif R.Unit_Name_Mismatch_Blockers > 0 then
         return Legality_Unit_Name_Mismatch;
      elsif R.Duplicate_With_Blockers > 0 then
         return Legality_Duplicate_With;
      elsif R.Duplicate_Use_Blockers > 0 then
         return Legality_Duplicate_Use;
      elsif R.Nonlimited_With_Cycle_Blockers > 0 then
         return Legality_Nonlimited_With_Cycle;
      elsif R.Private_With_Blockers > 0 then
         return Legality_Private_With_Not_Allowed;
      elsif R.Private_Child_Blockers > 0 then
         return Legality_Private_Child_Not_Visible;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Legality_Generic_Formal_View_Barrier;
      elsif R.Use_Target_Package_Blockers > 0 then
         return Legality_Use_Target_Not_Package;
      elsif R.Use_Type_Target_Blockers > 0 then
         return Legality_Use_Type_Target_Not_Type;
      elsif R.Use_Without_With_Blockers > 0 then
         return Legality_Use_Clause_Without_With;
      elsif R.Body_Context_Blockers > 0 then
         return Legality_Body_Context_Not_Propagated;
      elsif R.Generic_Context_Blockers > 0 then
         return Legality_Generic_Context_Missing;
      elsif R.Ambiguous_Use_Blockers > 0 then
         return Legality_Ambiguous_Use_Homograph;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.Unit_Fingerprint_Blockers > 0 then
         return Legality_Unit_Fingerprint_Mismatch;
      elsif R.View_Fingerprint_Blockers > 0 then
         return Legality_View_Fingerprint_Mismatch;
      elsif R.Closure_Fingerprint_Blockers > 0 then
         return Legality_Closure_Fingerprint_Mismatch;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   procedure Clear (Model : in out Unit_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Clause_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Result_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Unit (Model : in out Unit_Model; Item : Unit_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Unit_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.View_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Closure_Fingerprint);
   end Add_Unit;

   procedure Add_Type (Model : in out Type_Model; Item : Type_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.View_Fingerprint);
   end Add_Type;

   procedure Add_Clause (Model : in out Clause_Model; Item : Clause_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Clause_Kind'Pos (Item.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Unit_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.View_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Closure_Fingerprint);
   end Add_Clause;

   function Build
     (Units : Unit_Model;
      Types : Type_Model;
      Clauses : Clause_Model) return Result_Model
   is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Clauses.Items loop
         declare
            R : Result_Info;
            Context : constant Unit_Info := Find_Unit (Units, C.Context_Unit);
            Target_Unit : constant Unit_Info := Find_Unit (Units, C.Target_Unit);
            Target_Type : constant Type_Info := Find_Type (Types, C.Target_Type);
         begin
            R.Id := Result_Id (Next_Id);
            R.Clause := C.Id;
            R.Source_Node := C.Node;
            R.Fingerprint := Mix (Mix (Natural (C.Id), Clause_Kind'Pos (C.Kind)), Clauses.Result_Fingerprint);

            if C.Id = No_Clause or else C.Kind = Clause_Unknown then
               R.Missing_Clause_Blockers := 1;
            end if;

            if Context.Id = No_Unit then
               R.Missing_Context_Unit_Blockers := 1;
            else
               Add_Unit_Evidence_Blockers (Context, R);
            end if;

            if C.Kind = Clause_Use_Type then
               if Target_Type.Id = No_Type then
                  R.Use_Type_Target_Blockers := 1;
               else
                  Add_Type_Evidence_Blockers (Target_Type, R);
                  if not Is_Type_Target (Target_Type.Kind) then
                     R.Use_Type_Target_Blockers := 1;
                  end if;
               end if;
            elsif C.Kind /= Clause_Unknown then
               if Target_Unit.Id = No_Unit then
                  R.Missing_Target_Unit_Blockers := 1;
               else
                  Add_Unit_Evidence_Blockers (Target_Unit, R);
               end if;
            end if;

            if not C.Target_Name_Matches then
               R.Unit_Name_Mismatch_Blockers := 1;
            end if;

            if C.Duplicate_With then
               R.Duplicate_With_Blockers := 1;
            end if;
            if C.Duplicate_Use then
               R.Duplicate_Use_Blockers := 1;
            end if;

            if C.Dependency_Cycle then
               if C.Kind = Clause_Limited_With then
                  R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
               else
                  R.Nonlimited_With_Cycle_Blockers := 1;
               end if;
            end if;

            if C.Kind = Clause_Private_With and then not C.Private_With_Allowed then
               R.Private_With_Blockers := 1;
            end if;

            if Target_Unit.Is_Private_Child and then not C.Private_Child_Visible then
               R.Private_Child_Blockers := 1;
            end if;

            if C.Consumer_Requires_Full_View
              and then (C.Kind = Clause_Limited_With or else Target_Unit.View = View_Limited)
            then
               R.Limited_View_Blockers := 1;
            end if;

            if C.Kind = Clause_Use_Package then
               if not C.Use_Has_With then
                  R.Use_Without_With_Blockers := 1;
               end if;
               if Target_Unit.Id /= No_Unit
                 and then (not Is_Package_Unit (Target_Unit.Kind)
                           or else not C.Use_Target_Is_Package)
               then
                  R.Use_Target_Package_Blockers := 1;
               end if;
            elsif C.Kind = Clause_Use_Type then
               if not C.Use_Has_With then
                  R.Use_Without_With_Blockers := 1;
               end if;
               if not C.Use_Type_Target_Is_Type then
                  R.Use_Type_Target_Blockers := 1;
               end if;
            end if;

            if Context.Id /= No_Unit and then Is_Body (Context.Kind) then
               if not Context.Context_Propagated_To_Body
                 or else not C.Body_Context_Propagated
               then
                  R.Body_Context_Blockers := 1;
               end if;
            end if;

            if (Context.Id /= No_Unit and then Is_Generic_Unit (Context.Kind))
              or else Context.Is_Generic
            then
               if not Context.Generic_Contract_Context_Present
                 or else not C.Generic_Context_Present
               then
                  R.Generic_Context_Blockers := 1;
               end if;
            end if;

            if C.Ambiguous_Use_Homograph then
               R.Ambiguous_Use_Blockers := 1;
            end if;

            Add_Clause_Fingerprint_Blockers (C, R);
            R.Status := Status_For (R);
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Legality_Status'Pos (R.Status));
            Next_Id := Next_Id + 1;
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
      return Model.Items.Element (Index - 1);
   end Result_At;

end Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality;
