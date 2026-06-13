with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1324) mod 1_000_000_007;
   end Mix;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Access_Type_Blockers
        + R.Missing_Designated_Type_Blockers
        + R.Missing_Profile_Blockers
        + R.Kind_Mismatch_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_Blockers
        + R.Null_Exclusion_Blockers
        + R.Accessibility_Blockers
        + R.Profile_Conformance_Blockers
        + R.Convention_Blockers
        + R.Storage_Pool_Missing_Blockers
        + R.Storage_Pool_Conflict_Blockers
        + R.Storage_Size_Non_Static_Blockers
        + R.Storage_Size_Conflict_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.Pool_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info) return Access_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Access_Multiple_Blockers;
      elsif R.Missing_Access_Type_Blockers > 0 then
         return Access_Missing_Access_Type;
      elsif R.Missing_Designated_Type_Blockers > 0 then
         return Access_Missing_Designated_Type;
      elsif R.Missing_Profile_Blockers > 0 then
         return Access_Missing_Profile;
      elsif R.Kind_Mismatch_Blockers > 0 then
         return Access_Kind_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Access_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Access_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Access_Incomplete_View_Barrier;
      elsif R.Generic_Formal_Blockers > 0 then
         return Access_Generic_Formal_Barrier;
      elsif R.Null_Exclusion_Blockers > 0 then
         return Access_Null_Exclusion_Violation;
      elsif R.Accessibility_Blockers > 0 then
         return Access_Accessibility_Escape;
      elsif R.Profile_Conformance_Blockers > 0 then
         return Access_Profile_Conformance_Mismatch;
      elsif R.Convention_Blockers > 0 then
         return Access_Convention_Mismatch;
      elsif R.Storage_Pool_Missing_Blockers > 0 then
         return Access_Storage_Pool_Missing;
      elsif R.Storage_Pool_Conflict_Blockers > 0 then
         return Access_Storage_Pool_Conflict;
      elsif R.Storage_Size_Non_Static_Blockers > 0 then
         return Access_Storage_Size_Non_Static;
      elsif R.Storage_Size_Conflict_Blockers > 0 then
         return Access_Storage_Size_Conflict;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Access_Source_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Access_Type_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Access_Profile_Fingerprint_Mismatch;
      elsif R.Pool_Fingerprint_Blockers > 0 then
         return Access_Pool_Fingerprint_Mismatch;
      elsif Blocks = 0 and then R.Runtime_Accessibility_Checks > 0 then
         return Access_Legal_Runtime_Accessibility_Check;
      elsif Blocks = 0 then
         return Access_Legal;
      else
         return Access_Indeterminate;
      end if;
   end Status_For;

   function Find_Access_Type
     (Model : Access_Type_Model; Id : Access_Type_Id) return Access_Type_Info is
   begin
      for T of Model.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Access_Type;

   function Find_Designated_Type
     (Model : Designated_Type_Model; Id : Designated_Type_Id) return Designated_Type_Info is
   begin
      for D of Model.Items loop
         if D.Id = Id then
            return D;
         end if;
      end loop;
      return (others => <>);
   end Find_Designated_Type;

   function Find_Profile (Model : Profile_Model; Id : Profile_Id) return Profile_Info is
   begin
      for P of Model.Items loop
         if P.Id = Id then
            return P;
         end if;
      end loop;
      return (others => <>);
   end Find_Profile;

   procedure Clear (Model : in out Access_Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Designated_Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Profile_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Use_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Access_Type (Model : in out Access_Type_Model; Info : Access_Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Access_Type;

   procedure Add_Designated_Type (Model : in out Designated_Type_Model; Info : Designated_Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Designated_Type;

   procedure Add_Profile (Model : in out Profile_Model; Info : Profile_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Profile_Fingerprint);
   end Add_Profile;

   procedure Add_Use (Model : in out Use_Model; Info : Access_Use_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Use;

   function Build
     (Access_Types : Access_Type_Model;
      Designated_Types : Designated_Type_Model;
      Profiles : Profile_Model;
      Uses : Use_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      for U of Uses.Items loop
         declare
            Access_Info : constant Access_Type_Info := Find_Access_Type (Access_Types, U.Access_Type);
            D  : constant Designated_Type_Info :=
              Find_Designated_Type
                (Designated_Types,
                 (if U.Designated /= No_Designated_Type then U.Designated else Access_Info.Designated));
            P  : constant Profile_Info :=
              Find_Profile
                (Profiles,
                 (if U.Profile /= No_Profile then U.Profile else Access_Info.Profile));
            R : Result_Info;
         begin
            R.Id := U.Id;
            R.Access_Type := U.Access_Type;
            R.Designated := (if U.Designated /= No_Designated_Type then U.Designated else Access_Info.Designated);
            R.Profile := (if U.Profile /= No_Profile then U.Profile else Access_Info.Profile);

            if Access_Info.Id = No_Access_Type then
               R.Missing_Access_Type_Blockers := 1;
            else
               if Access_Info.Kind /= U.Expected_Kind then
                  R.Kind_Mismatch_Blockers := 1;
               end if;
               if Access_Info.Source_Fingerprint /= Access_Info.Expected_Source_Fingerprint
                 or else U.Source_Fingerprint /= U.Expected_Source_Fingerprint
               then
                  R.Source_Fingerprint_Blockers := 1;
               end if;
               if Access_Info.Type_Fingerprint /= Access_Info.Expected_Type_Fingerprint
                 or else U.Type_Fingerprint /= U.Expected_Type_Fingerprint
               then
                  R.Type_Fingerprint_Blockers := 1;
               end if;
               if Access_Info.Pool_Fingerprint /= Access_Info.Expected_Pool_Fingerprint
                 or else U.Pool_Fingerprint /= U.Expected_Pool_Fingerprint
               then
                  R.Pool_Fingerprint_Blockers := 1;
               end if;
            end if;

            if U.Expected_Kind = Access_Object then
               if D.Id = No_Designated_Type then
                  R.Missing_Designated_Type_Blockers := 1;
               else
                  case D.View is
                     when View_Private => R.Private_View_Blockers := 1;
                     when View_Limited => R.Limited_View_Blockers := 1;
                     when View_Incomplete => R.Incomplete_View_Blockers := 1;
                     when View_Generic_Formal => R.Generic_Formal_Blockers := 1;
                     when others => null;
                  end case;
                  if D.Is_Limited then
                     R.Limited_View_Blockers := 1;
                  end if;
                  if D.Is_Incomplete then
                     R.Incomplete_View_Blockers := 1;
                  end if;
                  if D.Source_Fingerprint /= D.Expected_Source_Fingerprint
                    or else D.Type_Fingerprint /= D.Expected_Type_Fingerprint
                  then
                     R.Type_Fingerprint_Blockers := 1;
                  end if;
               end if;
            end if;

            if U.Expected_Kind = Access_Subprogram then
               if P.Id = No_Profile then
                  R.Missing_Profile_Blockers := 1;
               else
                  if U.Requires_Profile_Conformance
                    and then (not P.Parameter_Modes_Compatible
                              or else not P.Type_Profile_Compatible
                              or else not P.Null_Exclusions_Compatible)
                  then
                     R.Profile_Conformance_Blockers := 1;
                  end if;
                  if not U.Convention_Compatible then
                     R.Convention_Blockers := 1;
                  end if;
                  if P.Source_Fingerprint /= P.Expected_Source_Fingerprint
                    or else P.Profile_Fingerprint /= P.Expected_Profile_Fingerprint
                    or else U.Profile_Fingerprint /= U.Expected_Profile_Fingerprint
                  then
                     R.Profile_Fingerprint_Blockers := 1;
                  end if;
               end if;
            end if;

            if (Access_Info.Null_Exclusion or else U.Null_Exclusion_Required) and then U.May_Be_Null then
               R.Null_Exclusion_Blockers := 1;
            end if;

            if U.Source_Master_Depth > U.Target_Master_Depth then
               if U.Runtime_Accessibility_Check_Allowed then
                  R.Runtime_Accessibility_Checks := 1;
               else
                  R.Accessibility_Blockers := 1;
               end if;
            end if;

            if U.Requires_Storage_Pool and then Access_Info.Storage_Pool = No_Pool and then U.Pool = No_Pool then
               R.Storage_Pool_Missing_Blockers := 1;
            elsif U.Pool /= No_Pool and then Access_Info.Storage_Pool /= No_Pool and then U.Pool /= Access_Info.Storage_Pool then
               R.Storage_Pool_Conflict_Blockers := 1;
            end if;

            if U.Requires_Static_Storage_Size
              and then (not Access_Info.Storage_Size_Static or else not U.Storage_Size_Static)
            then
               R.Storage_Size_Non_Static_Blockers := 1;
            end if;
            if not Access_Info.Storage_Size_Compatible or else not U.Storage_Size_Compatible then
               R.Storage_Size_Conflict_Blockers := 1;
            end if;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (R.Id), Natural (Access_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Message := To_Unbounded_String ("access type/access-to-subprogram legality");
            R.Detail := To_Unbounded_String (Access_Status'Image (R.Status));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Access_Type_Count (Model : Access_Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Access_Type_Count;

   function Designated_Type_Count (Model : Designated_Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Designated_Type_Count;

   function Profile_Count (Model : Profile_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Profile_Count;

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

   function Count_Status (Model : Result_Model; Status : Access_Status) return Natural is
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
         if R.Status = Access_Legal or else R.Status = Access_Legal_Runtime_Accessibility_Check then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status /= Access_Legal and then R.Status /= Access_Legal_Runtime_Accessibility_Check then
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
      return Info.Id /= No_Result and then Info.Status /= Access_Not_Checked;
   end Has_Result;

end Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality;
