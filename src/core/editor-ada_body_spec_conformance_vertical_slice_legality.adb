with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1318) mod 1_000_000_007;
   end Mix;

   function Unit_Kind_Matches (Spec, Body_Info : Unit_Kind; Kind : Completion_Kind) return Boolean is
   begin
      if Spec = Unit_Unknown or else Body_Info = Unit_Unknown then
         return True;
      elsif Spec = Body_Info then
         return True;
      elsif Kind = Completion_Generic_Package_Body
        and then Spec = Unit_Generic_Package and then Body_Info = Unit_Package
      then
         return True;
      elsif Kind = Completion_Generic_Subprogram_Body
        and then Spec = Unit_Generic_Subprogram and then Body_Info = Unit_Subprogram
      then
         return True;
      elsif Kind = Completion_Separate_Body
        and then Body_Info = Unit_Separate
      then
         return True;
      else
         return False;
      end if;
   end Unit_Kind_Matches;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Missing_Spec_Blockers
        + R.Missing_Body_Blockers
        + R.Duplicate_Body_Blockers
        + R.Kind_Blockers
        + R.Region_Blockers
        + R.Mode_Blockers
        + R.Type_Blockers
        + R.Default_Blockers
        + R.Null_Exclusion_Blockers
        + R.Convention_Blockers
        + R.Result_Blockers
        + R.Generic_Formal_Blockers
        + R.Generic_Body_Blockers
        + R.Stub_Blockers
        + R.Separate_Parent_Blockers
        + R.Private_Full_View_Blockers
        + R.Deferred_Constant_Blockers
        + R.Incomplete_Type_Blockers
        + R.Visibility_Blockers
        + R.Limited_View_Blockers
        + R.Private_View_Blockers
        + R.Elaboration_Blockers
        + R.Overload_Blockers
        + R.Representation_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Spec_Fingerprint_Blockers
        + R.Body_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; C : Completion_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Missing_Spec_Blockers > 0 then
         return Legality_Missing_Spec;
      elsif R.Missing_Body_Blockers > 0 then
         return Legality_Missing_Body;
      elsif R.Duplicate_Body_Blockers > 0 then
         return Legality_Duplicate_Body;
      elsif R.Kind_Blockers > 0 then
         return Legality_Wrong_Completion_Kind;
      elsif R.Region_Blockers > 0 then
         return Legality_Wrong_Region;
      elsif R.Mode_Blockers > 0 then
         return Legality_Profile_Mode_Mismatch;
      elsif R.Type_Blockers > 0 then
         return Legality_Profile_Type_Mismatch;
      elsif R.Default_Blockers > 0 then
         return Legality_Profile_Default_Mismatch;
      elsif R.Null_Exclusion_Blockers > 0 then
         return Legality_Profile_Null_Exclusion_Mismatch;
      elsif R.Convention_Blockers > 0 then
         return Legality_Profile_Convention_Mismatch;
      elsif R.Result_Blockers > 0 then
         return Legality_Profile_Result_Mismatch;
      elsif R.Generic_Formal_Blockers > 0 then
         return Legality_Generic_Formal_Mismatch;
      elsif R.Generic_Body_Blockers > 0 then
         return Legality_Generic_Body_Missing;
      elsif R.Stub_Blockers > 0 then
         return Legality_Separate_Stub_Missing;
      elsif R.Separate_Parent_Blockers > 0 then
         return Legality_Separate_Parent_Mismatch;
      elsif R.Private_Full_View_Blockers > 0 then
         return Legality_Private_Full_View_Missing;
      elsif R.Deferred_Constant_Blockers > 0 then
         return Legality_Deferred_Constant_Mismatch;
      elsif R.Incomplete_Type_Blockers > 0 then
         return Legality_Incomplete_Type_Not_Completed;
      elsif R.Visibility_Blockers > 0 then
         return Legality_Visibility_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Elaboration_Blockers > 0 then
         return Legality_Elaboration_Blocker;
      elsif R.Overload_Blockers > 0 then
         return Legality_Overload_Blocker;
      elsif R.Representation_Blockers > 0 then
         return Legality_Representation_Blocker;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.Spec_Fingerprint_Blockers > 0 then
         return Legality_Spec_Fingerprint_Mismatch;
      elsif R.Body_Fingerprint_Blockers > 0 then
         return Legality_Body_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif C.Kind = Completion_Unknown then
         return Legality_Indeterminate;
      elsif not C.Body_Required and then not C.Has_Body then
         return Legality_Legal_Optional_Body;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Check_Profile (C : Completion_Info; R : in out Result_Info) is
   begin
      case C.Profile is
         when Profile_Fully_Conformant | Profile_Not_Applicable =>
            null;
         when Profile_Mode_Mismatch =>
            R.Mode_Blockers := R.Mode_Blockers + 1;
         when Profile_Type_Mismatch =>
            R.Type_Blockers := R.Type_Blockers + 1;
         when Profile_Default_Mismatch =>
            R.Default_Blockers := R.Default_Blockers + 1;
         when Profile_Null_Exclusion_Mismatch =>
            R.Null_Exclusion_Blockers := R.Null_Exclusion_Blockers + 1;
         when Profile_Convention_Mismatch =>
            R.Convention_Blockers := R.Convention_Blockers + 1;
         when Profile_Result_Mismatch =>
            R.Result_Blockers := R.Result_Blockers + 1;
         when Profile_Unknown =>
            null;
      end case;
   end Check_Profile;

   procedure Check_Completion (C : Completion_Info; R : in out Result_Info) is
   begin
      if not C.Has_AST_Coverage then
         R.AST_Blockers := R.AST_Blockers + 1;
      end if;

      if not C.Has_Spec then
         R.Missing_Spec_Blockers := R.Missing_Spec_Blockers + 1;
      end if;

      if C.Body_Required and then not C.Has_Body then
         R.Missing_Body_Blockers := R.Missing_Body_Blockers + 1;
      end if;

      if C.Duplicate_Body then
         R.Duplicate_Body_Blockers := R.Duplicate_Body_Blockers + 1;
      end if;

      if not C.Completion_Kind_Matches
        or else not Unit_Kind_Matches (C.Spec_Unit, C.Body_Unit, C.Kind)
      then
         R.Kind_Blockers := R.Kind_Blockers + 1;
      end if;

      if not C.Region_Matches or else C.Placement = Placement_Wrong_Region then
         R.Region_Blockers := R.Region_Blockers + 1;
      end if;

      Check_Profile (C, R);

      if not C.Generic_Formals_Conform then
         R.Generic_Formal_Blockers := R.Generic_Formal_Blockers + 1;
      end if;

      if C.Kind in Completion_Generic_Package_Body | Completion_Generic_Subprogram_Body
        and then not C.Generic_Body_Available
      then
         R.Generic_Body_Blockers := R.Generic_Body_Blockers + 1;
      end if;

      if C.Kind = Completion_Separate_Body and then not C.Separate_Stub_Present then
         R.Stub_Blockers := R.Stub_Blockers + 1;
      end if;

      if C.Kind = Completion_Separate_Body and then not C.Separate_Parent_Matches then
         R.Separate_Parent_Blockers := R.Separate_Parent_Blockers + 1;
      end if;

      if C.Kind = Completion_Private_Type_Full_View and then not C.Private_Full_View_Present then
         R.Private_Full_View_Blockers := R.Private_Full_View_Blockers + 1;
      end if;

      if C.Kind = Completion_Deferred_Constant and then not C.Deferred_Constant_Matches then
         R.Deferred_Constant_Blockers := R.Deferred_Constant_Blockers + 1;
      end if;

      if C.Kind = Completion_Incomplete_Type and then not C.Incomplete_Type_Completed then
         R.Incomplete_Type_Blockers := R.Incomplete_Type_Blockers + 1;
      end if;

      if not C.Visibility_OK then
         R.Visibility_Blockers := R.Visibility_Blockers + 1;
      end if;

      if C.View = View_Limited and then not C.Limited_View_Allows_Completion then
         R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
      end if;

      if C.View = View_Private and then not C.Private_View_Allows_Completion then
         R.Private_View_Blockers := R.Private_View_Blockers + 1;
      end if;

      if not C.Elaboration_OK then
         R.Elaboration_Blockers := R.Elaboration_Blockers + 1;
      end if;

      if not C.Overload_Profile_OK then
         R.Overload_Blockers := R.Overload_Blockers + 1;
      end if;

      if not C.Representation_OK then
         R.Representation_Blockers := R.Representation_Blockers + 1;
      end if;

      if C.Expected_Source_Fingerprint /= 0
        and then C.Expected_Source_Fingerprint /= C.Source_Fingerprint
      then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;

      if C.Expected_Spec_Fingerprint /= 0
        and then C.Expected_Spec_Fingerprint /= C.Spec_Fingerprint
      then
         R.Spec_Fingerprint_Blockers := R.Spec_Fingerprint_Blockers + 1;
      end if;

      if C.Expected_Body_Fingerprint /= 0
        and then C.Expected_Body_Fingerprint /= C.Body_Fingerprint
      then
         R.Body_Fingerprint_Blockers := R.Body_Fingerprint_Blockers + 1;
      end if;

      if C.Expected_Profile_Fingerprint /= 0
        and then C.Expected_Profile_Fingerprint /= C.Profile_Fingerprint
      then
         R.Profile_Fingerprint_Blockers := R.Profile_Fingerprint_Blockers + 1;
      end if;
   end Check_Completion;

   function Build (Completions : Completion_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Completions.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Completion := C.Id;
            R.Node := C.Node;
            R.Kind := C.Kind;
            Check_Completion (C, R);
            R.Status := Status_For (R, C);
            R.Message := To_Unbounded_String (Legality_Status'Image (R.Status));
            R.Detail := C.Name;
            R.Fingerprint := Mix
              (Natural (Legality_Status'Pos (R.Status)) + Natural (Completion_Kind'Pos (C.Kind)),
               C.Source_Fingerprint + C.Spec_Fingerprint + C.Body_Fingerprint + C.Profile_Fingerprint + Blocker_Count (R));
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Results.Items.Append (R);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   procedure Clear (Model : in out Completion_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Completion (Model : in out Completion_Model; Info : Completion_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Completion;

   function Completion_Count (Model : Completion_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Completion_Count;

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
         if R.Status in Legality_Legal | Legality_Legal_Optional_Body then
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
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality;
