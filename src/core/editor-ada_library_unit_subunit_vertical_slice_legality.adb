package body Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1331) mod 1_000_000_007;
   end Mix;

   function Find_Unit (Model : Unit_Model; Id : Unit_Id) return Unit_Info is
   begin
      for U of Model.Items loop
         if U.Id = Id then
            return U;
         end if;
      end loop;
      return (others => <>);
   end Find_Unit;

   function Find_Stub (Model : Stub_Model; Id : Stub_Id) return Stub_Info is
   begin
      for S of Model.Items loop
         if S.Id = Id then
            return S;
         end if;
      end loop;
      return (others => <>);
   end Find_Stub;

   function Stub_Matches_Unit (Kind : Stub_Kind; Body_Kind : Unit_Kind) return Boolean is
   begin
      case Kind is
         when Stub_Package_Body =>
            return Body_Kind = Unit_Package_Body
              or else Body_Kind = Unit_Generic_Package_Body
              or else Body_Kind = Unit_Child_Body
              or else Body_Kind = Unit_Private_Child_Body
              or else Body_Kind = Unit_Subunit;
         when Stub_Subprogram_Body =>
            return Body_Kind = Unit_Subprogram_Body
              or else Body_Kind = Unit_Generic_Subprogram_Body
              or else Body_Kind = Unit_Subunit;
         when Stub_Task_Body =>
            return Body_Kind = Unit_Task_Body or else Body_Kind = Unit_Subunit;
         when Stub_Protected_Body =>
            return Body_Kind = Unit_Protected_Body or else Body_Kind = Unit_Subunit;
         when Stub_Unknown =>
            return False;
      end case;
   end Stub_Matches_Unit;

   function Spec_Body_Compatible (Spec_Kind, Body_Kind : Unit_Kind) return Boolean is
   begin
      return (Spec_Kind = Unit_Package_Spec and then Body_Kind = Unit_Package_Body)
        or else (Spec_Kind = Unit_Subprogram_Spec and then Body_Kind = Unit_Subprogram_Body)
        or else (Spec_Kind = Unit_Generic_Package_Spec and then Body_Kind = Unit_Generic_Package_Body)
        or else (Spec_Kind = Unit_Generic_Subprogram_Spec and then Body_Kind = Unit_Generic_Subprogram_Body)
        or else (Spec_Kind = Unit_Child_Spec and then Body_Kind = Unit_Child_Body)
        or else (Spec_Kind = Unit_Private_Child_Spec and then Body_Kind = Unit_Private_Child_Body);
   end Spec_Body_Compatible;

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
      if U.Body_Fingerprint /= U.Expected_Body_Fingerprint then
         R.Body_Fingerprint_Blockers := 1;
      end if;
      if U.Closure_Fingerprint /= U.Expected_Closure_Fingerprint then
         R.Closure_Fingerprint_Blockers := 1;
      end if;
   end Add_Unit_Evidence_Blockers;

   procedure Add_Stub_Evidence_Blockers (S : Stub_Info; R : in out Result_Info) is
   begin
      if S.Id = No_Stub then
         return;
      end if;
      if S.Source_Fingerprint /= S.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if S.Stub_Fingerprint /= S.Expected_Stub_Fingerprint then
         R.Stub_Fingerprint_Blockers := 1;
      end if;
      if S.Closure_Fingerprint /= S.Expected_Closure_Fingerprint then
         R.Closure_Fingerprint_Blockers := 1;
      end if;
   end Add_Stub_Evidence_Blockers;

   procedure Add_Check_Fingerprint_Blockers (C : Check_Info; R : in out Result_Info) is
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if C.Unit_Fingerprint /= C.Expected_Unit_Fingerprint then
         R.Unit_Fingerprint_Blockers := 1;
      end if;
      if C.Body_Fingerprint /= C.Expected_Body_Fingerprint then
         R.Body_Fingerprint_Blockers := 1;
      end if;
      if C.Stub_Fingerprint /= C.Expected_Stub_Fingerprint then
         R.Stub_Fingerprint_Blockers := 1;
      end if;
      if C.Closure_Fingerprint /= C.Expected_Closure_Fingerprint then
         R.Closure_Fingerprint_Blockers := 1;
      end if;
   end Add_Check_Fingerprint_Blockers;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Check_Blockers
        + R.Missing_Parent_Unit_Blockers
        + R.Missing_Child_Unit_Blockers
        + R.Missing_Spec_Blockers
        + R.Missing_Body_Blockers
        + R.Missing_Stub_Blockers
        + R.Unit_Kind_Blockers
        + R.Stub_Kind_Blockers
        + R.Parent_Name_Blockers
        + R.Parent_Library_Blockers
        + R.Body_Before_Spec_Blockers
        + R.Duplicate_Body_Blockers
        + R.Duplicate_Subunit_Blockers
        + R.Body_Stub_Separate_Blockers
        + R.Separate_Without_Stub_Blockers
        + R.Nested_Separate_Parent_Blockers
        + R.Library_Unit_Incomplete_Blockers
        + R.Child_Parent_Blockers
        + R.Private_Child_Spec_Blockers
        + R.Private_Child_Visibility_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Unit_Fingerprint_Blockers
        + R.Body_Fingerprint_Blockers
        + R.Stub_Fingerprint_Blockers
        + R.Closure_Fingerprint_Blockers;
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
      elsif R.Missing_Parent_Unit_Blockers > 0 then
         return Legality_Missing_Parent_Unit;
      elsif R.Missing_Child_Unit_Blockers > 0 then
         return Legality_Missing_Child_Unit;
      elsif R.Missing_Spec_Blockers > 0 then
         return Legality_Missing_Spec;
      elsif R.Missing_Body_Blockers > 0 then
         return Legality_Missing_Body;
      elsif R.Missing_Stub_Blockers > 0 then
         return Legality_Missing_Stub;
      elsif R.Unit_Kind_Blockers > 0 then
         return Legality_Unit_Kind_Mismatch;
      elsif R.Stub_Kind_Blockers > 0 then
         return Legality_Stub_Kind_Mismatch;
      elsif R.Parent_Name_Blockers > 0 then
         return Legality_Parent_Name_Mismatch;
      elsif R.Parent_Library_Blockers > 0 then
         return Legality_Parent_Not_Library_Unit;
      elsif R.Body_Before_Spec_Blockers > 0 then
         return Legality_Body_Before_Spec;
      elsif R.Duplicate_Body_Blockers > 0 then
         return Legality_Duplicate_Body;
      elsif R.Duplicate_Subunit_Blockers > 0 then
         return Legality_Duplicate_Subunit;
      elsif R.Body_Stub_Separate_Blockers > 0 then
         return Legality_Body_Stub_Requires_Separate;
      elsif R.Separate_Without_Stub_Blockers > 0 then
         return Legality_Separate_Without_Stub;
      elsif R.Nested_Separate_Parent_Blockers > 0 then
         return Legality_Nested_Separate_Parent_Mismatch;
      elsif R.Library_Unit_Incomplete_Blockers > 0 then
         return Legality_Library_Unit_Incomplete;
      elsif R.Child_Parent_Blockers > 0 then
         return Legality_Child_Parent_Missing;
      elsif R.Private_Child_Spec_Blockers > 0 then
         return Legality_Private_Child_Spec_Missing;
      elsif R.Private_Child_Visibility_Blockers > 0 then
         return Legality_Private_Child_Body_Not_Visible;
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
      elsif R.Unit_Fingerprint_Blockers > 0 then
         return Legality_Unit_Fingerprint_Mismatch;
      elsif R.Body_Fingerprint_Blockers > 0 then
         return Legality_Body_Fingerprint_Mismatch;
      elsif R.Stub_Fingerprint_Blockers > 0 then
         return Legality_Stub_Fingerprint_Mismatch;
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

   procedure Clear (Model : in out Stub_Model) is
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

   procedure Add_Unit (Model : in out Unit_Model; Item : Unit_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Unit_Kind'Pos (Item.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Unit_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Body_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Closure_Fingerprint);
   end Add_Unit;

   procedure Add_Stub (Model : in out Stub_Model; Item : Stub_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Stub_Kind'Pos (Item.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Stub_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Closure_Fingerprint);
   end Add_Stub;

   procedure Add_Check (Model : in out Check_Model; Item : Check_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Check_Kind'Pos (Item.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Unit_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Body_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Stub_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Closure_Fingerprint);
   end Add_Check;

   function Build
     (Units : Unit_Model;
      Stubs : Stub_Model;
      Checks : Check_Model) return Result_Model
   is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Checks.Items loop
         declare
            R : Result_Info;
            U : constant Unit_Info := Find_Unit (Units, C.Unit);
            Parent : constant Unit_Info := Find_Unit (Units, C.Parent_Unit);
            Child : constant Unit_Info := Find_Unit (Units, C.Child_Unit);
            Spec_U : constant Unit_Info := Find_Unit (Units, C.Spec_Unit);
            Body_U : constant Unit_Info := Find_Unit (Units, C.Body_Unit);
            S : constant Stub_Info := Find_Stub (Stubs, C.Stub);
            Nested_S : constant Stub_Info := Find_Stub (Stubs, C.Nested_Parent_Stub);
         begin
            R.Id := Result_Id (Next_Id);
            R.Check := C.Id;
            R.Source_Node := C.Node;
            R.Fingerprint := Mix (Mix (Natural (C.Id), Check_Kind'Pos (C.Kind)), Checks.Result_Fingerprint);

            if C.Id = No_Check or else C.Kind = Check_Unknown then
               R.Missing_Check_Blockers := 1;
            end if;

            if C.Unit /= No_Unit then
               if U.Id = No_Unit then
                  R.Missing_Body_Blockers := 1;
               else
                  Add_Unit_Evidence_Blockers (U, R);
                  if C.Expected_Unit_Kind /= Unit_Unknown
                    and then U.Kind /= C.Expected_Unit_Kind
                  then
                     R.Unit_Kind_Blockers := 1;
                  end if;
               end if;
            end if;

            if C.Parent_Unit /= No_Unit then
               if Parent.Id = No_Unit then
                  R.Missing_Parent_Unit_Blockers := 1;
               else
                  Add_Unit_Evidence_Blockers (Parent, R);
                  if not Parent.Is_Library_Unit
                    and then (C.Kind = Check_Child_Unit
                              or else C.Kind = Check_Library_Unit_Completion)
                  then
                     R.Parent_Library_Blockers := 1;
                  end if;
               end if;
            end if;

            if C.Child_Unit /= No_Unit then
               if Child.Id = No_Unit then
                  R.Missing_Child_Unit_Blockers := 1;
               else
                  Add_Unit_Evidence_Blockers (Child, R);
               end if;
            end if;

            if C.Spec_Unit /= No_Unit then
               if Spec_U.Id = No_Unit then
                  R.Missing_Spec_Blockers := 1;
               else
                  Add_Unit_Evidence_Blockers (Spec_U, R);
               end if;
            end if;

            if C.Body_Unit /= No_Unit then
               if Body_U.Id = No_Unit then
                  R.Missing_Body_Blockers := 1;
               else
                  Add_Unit_Evidence_Blockers (Body_U, R);
               end if;
            end if;

            if C.Stub /= No_Stub then
               if S.Id = No_Stub then
                  R.Missing_Stub_Blockers := 1;
               else
                  Add_Stub_Evidence_Blockers (S, R);
               end if;
            end if;

            if C.Nested_Parent_Stub /= No_Stub then
               if Nested_S.Id = No_Stub then
                  R.Missing_Stub_Blockers := 1;
               else
                  Add_Stub_Evidence_Blockers (Nested_S, R);
               end if;
            end if;

            if not C.Parent_Name_Matches
              or else (U.Id /= No_Unit and then not U.Parent_Name_Matches)
              or else (S.Id /= No_Stub and then not S.Parent_Name_Matches)
            then
               R.Parent_Name_Blockers := 1;
            end if;

            if C.Kind = Check_Body_Stub then
               if S.Id = No_Stub then
                  R.Missing_Stub_Blockers := 1;
               elsif C.Expected_Stub_Kind /= Stub_Unknown
                 and then S.Kind /= C.Expected_Stub_Kind
               then
                  R.Stub_Kind_Blockers := 1;
               end if;

               if C.Requires_Separate_Body
                 and then not C.Separate_Body_Present
               then
                  R.Body_Stub_Separate_Blockers := 1;
               end if;
            end if;

            if C.Kind = Check_Separate_Subunit then
               if S.Id = No_Stub then
                  R.Separate_Without_Stub_Blockers := 1;
               else
                  if U.Id /= No_Unit and then not Stub_Matches_Unit (S.Kind, U.Kind) then
                     R.Stub_Kind_Blockers := 1;
                  end if;
                  if not S.Separate_Present or else not C.Separate_Body_Present then
                     R.Body_Stub_Separate_Blockers := 1;
                  end if;
               end if;
            end if;

            if C.Kind = Check_Nested_Separate_Body
              and then not C.Nested_Separate_Parent_Matches
            then
               R.Nested_Separate_Parent_Blockers := 1;
            end if;

            if C.Kind = Check_Library_Unit_Completion then
               if Spec_U.Id = No_Unit then
                  R.Missing_Spec_Blockers := 1;
               end if;
               if Body_U.Id = No_Unit and then Spec_U.Has_Required_Body then
                  R.Missing_Body_Blockers := 1;
               end if;
               if Spec_U.Id /= No_Unit and then Body_U.Id /= No_Unit
                 and then not Spec_Body_Compatible (Spec_U.Kind, Body_U.Kind)
               then
                  R.Unit_Kind_Blockers := 1;
               end if;
               if not C.Library_Unit_Complete
                 or else (Spec_U.Id /= No_Unit
                          and then Spec_U.Has_Required_Body
                          and then not Spec_U.Body_Present)
               then
                  R.Library_Unit_Incomplete_Blockers := 1;
               end if;
            end if;

            if C.Kind = Check_Child_Unit then
               if Parent.Id = No_Unit or else not C.Child_Parent_Present then
                  R.Child_Parent_Blockers := 1;
               elsif Child.Id /= No_Unit and then Child.Parent /= Parent.Id then
                  R.Child_Parent_Blockers := 1;
               end if;
            end if;

            if C.Kind = Check_Private_Child_Body then
               if not C.Private_Child_Spec_Present then
                  R.Private_Child_Spec_Blockers := 1;
               end if;
               if not C.Private_Child_Visible then
                  R.Private_Child_Visibility_Blockers := 1;
               end if;
            end if;

            if not C.Body_After_Spec
              or else (Spec_U.Id /= No_Unit and then not Spec_U.Body_After_Spec)
            then
               R.Body_Before_Spec_Blockers := 1;
            end if;

            if C.Duplicate_Body
              or else (Spec_U.Id /= No_Unit and then Spec_U.Duplicate_Body)
              or else (Body_U.Id /= No_Unit and then Body_U.Duplicate_Body)
            then
               R.Duplicate_Body_Blockers := 1;
            end if;

            if C.Duplicate_Subunit
              or else (S.Id /= No_Stub and then S.Duplicate_Subunit)
            then
               R.Duplicate_Subunit_Blockers := 1;
            end if;

            Add_Check_Fingerprint_Blockers (C, R);
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

end Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality;
