with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1325) mod 1_000_000_007;
   end Mix;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Callable_Blockers
        + R.Missing_Declared_Profile_Blockers
        + R.Missing_Expected_Profile_Blockers
        + R.Kind_Blockers
        + R.Arity_Blockers
        + R.Mode_Blockers
        + R.Type_Blockers
        + R.Default_Blockers
        + R.Null_Exclusion_Blockers
        + R.Convention_Blockers
        + R.Result_Type_Blockers
        + R.Access_Profile_Blockers
        + R.Overriding_Blockers
        + R.Renaming_Blockers
        + R.Generic_Formal_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info) return Profile_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Profile_Multiple_Blockers;
      elsif R.Missing_Callable_Blockers > 0 then
         return Profile_Missing_Callable;
      elsif R.Missing_Declared_Profile_Blockers > 0 then
         return Profile_Missing_Declared_Profile;
      elsif R.Missing_Expected_Profile_Blockers > 0 then
         return Profile_Missing_Expected_Profile;
      elsif R.Kind_Blockers > 0 then
         return Profile_Kind_Mismatch;
      elsif R.Arity_Blockers > 0 then
         return Profile_Arity_Mismatch;
      elsif R.Mode_Blockers > 0 then
         return Profile_Mode_Conformance_Mismatch;
      elsif R.Type_Blockers > 0 then
         return Profile_Type_Conformance_Mismatch;
      elsif R.Default_Blockers > 0 then
         return Profile_Default_Expression_Mismatch;
      elsif R.Null_Exclusion_Blockers > 0 then
         return Profile_Null_Exclusion_Mismatch;
      elsif R.Convention_Blockers > 0 then
         return Profile_Convention_Mismatch;
      elsif R.Result_Type_Blockers > 0 then
         return Profile_Result_Type_Mismatch;
      elsif R.Access_Profile_Blockers > 0 then
         return Profile_Access_Profile_Mismatch;
      elsif R.Overriding_Blockers > 0 then
         return Profile_Overriding_Profile_Mismatch;
      elsif R.Renaming_Blockers > 0 then
         return Profile_Renaming_Profile_Mismatch;
      elsif R.Generic_Formal_Blockers > 0 then
         return Profile_Generic_Formal_Profile_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Profile_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Profile_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Profile_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Profile_Generic_Formal_View_Barrier;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Profile_Source_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Profile_Profile_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Profile_Type_Fingerprint_Mismatch;
      elsif Blocks = 0 and then R.Defaulted_Formal_Count > 0 then
         return Profile_Legal_Defaulted_Formals;
      elsif Blocks = 0 then
         return Profile_Legal;
      else
         return Profile_Indeterminate;
      end if;
   end Status_For;

   function Find_Callable (Model : Callable_Model; Id : Callable_Id) return Callable_Info is
   begin
      for C of Model.Items loop
         if C.Id = Id then
            return C;
         end if;
      end loop;
      return (others => <>);
   end Find_Callable;

   function Find_Profile (Model : Profile_Model; Id : Profile_Id) return Profile_Info is
   begin
      for P of Model.Items loop
         if P.Id = Id then
            return P;
         end if;
      end loop;
      return (others => <>);
   end Find_Profile;

   procedure Clear (Model : in out Callable_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Profile_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Check_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Callable (Model : in out Callable_Model; Info : Callable_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Callable;

   procedure Add_Profile (Model : in out Profile_Model; Info : Profile_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Profile_Fingerprint);
   end Add_Profile;

   procedure Add_Check (Model : in out Check_Model; Info : Check_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Check;

   function Build
     (Callables : Callable_Model;
      Profiles : Profile_Model;
      Checks : Check_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      for Ch of Checks.Items loop
         declare
            C : constant Callable_Info := Find_Callable (Callables, Ch.Callable);
            Declared_Id : constant Profile_Id :=
              (if Ch.Declared_Profile /= No_Profile then Ch.Declared_Profile else C.Declared_Profile);
            Declared : constant Profile_Info := Find_Profile (Profiles, Declared_Id);
            Expected : constant Profile_Info := Find_Profile (Profiles, Ch.Expected_Profile);
            R : Result_Info;
         begin
            R.Id := Ch.Id;
            R.Callable := Ch.Callable;
            R.Declared_Profile := Declared_Id;
            R.Expected_Profile := Ch.Expected_Profile;

            if C.Id = No_Callable then
               R.Missing_Callable_Blockers := 1;
            else
               if C.Kind /= Ch.Expected_Kind then
                  R.Kind_Blockers := 1;
               end if;
               if C.Source_Fingerprint /= C.Expected_Source_Fingerprint
                 or else Ch.Source_Fingerprint /= Ch.Expected_Source_Fingerprint
               then
                  R.Source_Fingerprint_Blockers := 1;
               end if;
            end if;

            if Declared.Id = No_Profile then
               R.Missing_Declared_Profile_Blockers := 1;
            else
               case Declared.View is
                  when View_Private => R.Private_View_Blockers := 1;
                  when View_Limited => R.Limited_View_Blockers := 1;
                  when View_Incomplete => R.Incomplete_View_Blockers := 1;
                  when View_Generic_Formal => R.Generic_Formal_View_Blockers := 1;
                  when others => null;
               end case;

               if Declared.Source_Fingerprint /= Declared.Expected_Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := 1;
               end if;
               if Declared.Profile_Fingerprint /= Declared.Expected_Profile_Fingerprint
                 or else Ch.Profile_Fingerprint /= Ch.Expected_Profile_Fingerprint
               then
                  R.Profile_Fingerprint_Blockers := 1;
               end if;
               if Declared.Type_Fingerprint /= Declared.Expected_Type_Fingerprint
                 or else Ch.Type_Fingerprint /= Ch.Expected_Type_Fingerprint
               then
                  R.Type_Fingerprint_Blockers := 1;
               end if;
            end if;

            if Expected.Id = No_Profile then
               R.Missing_Expected_Profile_Blockers := 1;
            else
               case Expected.View is
                  when View_Private => R.Private_View_Blockers := 1;
                  when View_Limited => R.Limited_View_Blockers := 1;
                  when View_Incomplete => R.Incomplete_View_Blockers := 1;
                  when View_Generic_Formal => R.Generic_Formal_View_Blockers := 1;
                  when others => null;
               end case;

               if Expected.Source_Fingerprint /= Expected.Expected_Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := 1;
               end if;
               if Expected.Profile_Fingerprint /= Expected.Expected_Profile_Fingerprint then
                  R.Profile_Fingerprint_Blockers := 1;
               end if;
               if Expected.Type_Fingerprint /= Expected.Expected_Type_Fingerprint then
                  R.Type_Fingerprint_Blockers := 1;
               end if;
            end if;

            if Declared.Id /= No_Profile and then Expected.Id /= No_Profile then
               if Declared.Kind /= Expected.Kind or else Declared.Kind /= Ch.Expected_Kind then
                  R.Kind_Blockers := 1;
               end if;

               if Ch.Actual_Count < Declared.Required_Formal_Count
                 or else Ch.Actual_Count > Declared.Formal_Count
               then
                  R.Arity_Blockers := 1;
               elsif Ch.Actual_Count < Declared.Formal_Count then
                  if Ch.Allow_Defaulted_Formals then
                     R.Defaulted_Formal_Count := Declared.Formal_Count - Ch.Actual_Count;
                  else
                     R.Arity_Blockers := 1;
                  end if;
               end if;

               if Declared.Formal_Count /= Expected.Formal_Count
                 or else Declared.Required_Formal_Count /= Expected.Required_Formal_Count
               then
                  R.Arity_Blockers := 1;
               end if;

               if Ch.Require_Mode_Conformance
                 and then (not Declared.Modes_Conformant or else not Expected.Modes_Conformant)
               then
                  R.Mode_Blockers := 1;
               end if;
               if Ch.Require_Type_Conformance
                 and then (not Declared.Types_Conformant or else not Expected.Types_Conformant)
               then
                  R.Type_Blockers := 1;
               end if;
               if Ch.Require_Default_Conformance
                 and then (not Declared.Default_Expressions_Conformant
                           or else not Expected.Default_Expressions_Conformant)
               then
                  R.Default_Blockers := 1;
               end if;
               if Ch.Require_Null_Exclusion_Conformance
                 and then (not Declared.Null_Exclusions_Conformant
                           or else not Expected.Null_Exclusions_Conformant)
               then
                  R.Null_Exclusion_Blockers := 1;
               end if;
               if Ch.Require_Result_Conformance then
                  if Declared.Result_Type /= Expected.Result_Type
                    or else not Declared.Result_Type_Conformant
                    or else not Expected.Result_Type_Conformant
                  then
                     R.Result_Type_Blockers := 1;
                  end if;
               end if;

               if Length (Ch.Expected_Convention) > 0
                 and then (To_String (Declared.Convention) /= To_String (Ch.Expected_Convention)
                           or else To_String (Expected.Convention) /= To_String (Ch.Expected_Convention))
               then
                  R.Convention_Blockers := 1;
               end if;

               if Ch.Require_Access_Profile_Conformance
                 and then (not Declared.Access_Profile_Conformant
                           or else not Expected.Access_Profile_Conformant)
               then
                  R.Access_Profile_Blockers := 1;
               end if;
               if Ch.Require_Overriding_Conformance
                 and then (not Declared.Overriding_Profile_Conformant
                           or else not Expected.Overriding_Profile_Conformant)
               then
                  R.Overriding_Blockers := 1;
               end if;
               if Ch.Require_Renaming_Conformance
                 and then (not Declared.Renaming_Profile_Conformant
                           or else not Expected.Renaming_Profile_Conformant)
               then
                  R.Renaming_Blockers := 1;
               end if;
               if Ch.Require_Generic_Formal_Conformance
                 and then (not Declared.Generic_Formal_Profile_Conformant
                           or else not Expected.Generic_Formal_Profile_Conformant)
               then
                  R.Generic_Formal_Blockers := 1;
               end if;
            end if;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (R.Id), Natural (Profile_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Message := To_Unbounded_String ("callable profile conformance legality");
            R.Detail := To_Unbounded_String (Profile_Status'Image (R.Status));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Callable_Count (Model : Callable_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Callable_Count;

   function Profile_Count (Model : Profile_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Profile_Count;

   function Check_Count (Model : Check_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Check_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Profile_Status) return Natural is
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
         if R.Status = Profile_Legal or else R.Status = Profile_Legal_Defaulted_Formals then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status /= Profile_Legal and then R.Status /= Profile_Legal_Defaulted_Formals then
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
      return Info.Id /= No_Result and then Info.Status /= Profile_Not_Checked;
   end Has_Result;

end Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality;
