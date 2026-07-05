with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1315) mod 1_000_000_007;
   end Mix;

   function Discrete_Compatible (Actual, Expected : Discrete_Class) return Boolean is
   begin
      if Expected = Discrete_Unknown or else Actual = Discrete_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Actual in Discrete_Integer | Discrete_Modular
        and then Expected in Discrete_Integer | Discrete_Modular
      then
         return True;
      elsif Actual in Discrete_Character | Discrete_Wide_Character
        and then Expected in Discrete_Character | Discrete_Wide_Character
      then
         return True;
      else
         return False;
      end if;
   end Discrete_Compatible;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Type_Blockers
        + R.Static_Blockers
        + R.Subject_Discrete_Blockers
        + R.Choice_Type_Blockers
        + R.Choice_Static_Blockers
        + R.Reversed_Range_Blockers
        + R.Out_Of_Base_Blockers
        + R.Missing_Choice_Blockers
        + R.Incomplete_Case_Blockers
        + R.Choice_Overlap_Blockers
        + R.Others_Order_Blockers
        + R.Duplicate_Others_Blockers
        + R.Null_Range_Blockers
        + R.Variant_Governor_Blockers
        + R.Aggregate_Choice_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Static_Fingerprint_Blockers;
   end Blocker_Count;

   function Is_Case_Like (Kind : Choice_Kind) return Boolean is
   begin
      return Kind in Choice_Case_Statement | Choice_Case_Expression |
                     Choice_Variant_Choice;
   end Is_Case_Like;

   function Is_Aggregate_Like (Kind : Choice_Kind) return Boolean is
   begin
      return Kind in Choice_Aggregate_Choice | Choice_Array_Index_Choice |
                     Choice_Record_Discriminant_Choice;
   end Is_Aggregate_Like;

   function Status_For (R : Result_Info; C : Choice_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Type_Blockers > 0 then
         return Legality_Missing_Type_Evidence;
      elsif R.Static_Blockers > 0 then
         return Legality_Choice_Not_Static;
      elsif R.Subject_Discrete_Blockers > 0 then
         return Legality_Subject_Not_Discrete;
      elsif R.Choice_Type_Blockers > 0 then
         return Legality_Choice_Type_Mismatch;
      elsif R.Choice_Static_Blockers > 0 then
         return Legality_Choice_Not_Static;
      elsif R.Reversed_Range_Blockers > 0 then
         return Legality_Range_Bounds_Reversed;
      elsif R.Out_Of_Base_Blockers > 0 then
         return Legality_Range_Out_Of_Base;
      elsif R.Missing_Choice_Blockers > 0 then
         return Legality_Case_Missing_Choice;
      elsif R.Incomplete_Case_Blockers > 0 then
         return Legality_Case_Incomplete;
      elsif R.Choice_Overlap_Blockers > 0 then
         return Legality_Case_Choice_Overlap;
      elsif R.Others_Order_Blockers > 0 then
         return Legality_Others_Not_Last;
      elsif R.Duplicate_Others_Blockers > 0 then
         return Legality_Duplicate_Others;
      elsif R.Null_Range_Blockers > 0 then
         return Legality_Null_Range_Static;
      elsif R.Variant_Governor_Blockers > 0 then
         return Legality_Variant_Governor_Mismatch;
      elsif R.Aggregate_Choice_Blockers > 0 then
         return Legality_Aggregate_Choice_Mismatch;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif R.Static_Fingerprint_Blockers > 0 then
         return Legality_Static_Fingerprint_Mismatch;
      elsif C.Kind = Choice_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_Runtime_Check;
      else
         return Legality_Legal_Static;
      end if;
   end Status_For;

   procedure Check_Common (C : Choice_Info; R : in out Result_Info) is
   begin
      if not C.Has_AST_Coverage then
         R.AST_Blockers := R.AST_Blockers + 1;
      end if;

      if not C.Has_Type_Evidence or else C.Subject_Type = Discrete_Unknown then
         R.Type_Blockers := R.Type_Blockers + 1;
      end if;

      if not C.Has_Static_Evidence then
         R.Static_Blockers := R.Static_Blockers + 1;
      end if;

      if not C.Subject_Is_Discrete or else C.Subject_Type = Discrete_Not_Discrete then
         R.Subject_Discrete_Blockers := R.Subject_Discrete_Blockers + 1;
      end if;

      if not C.Choice_Type_Compatible
        or else not Discrete_Compatible (C.Choice_Type, C.Expected_Type)
        or else not Discrete_Compatible (C.Choice_Type, C.Subject_Type)
      then
         R.Choice_Type_Blockers := R.Choice_Type_Blockers + 1;
      end if;

      if not C.Choice_Is_Static or else not C.Bounds_Are_Static then
         R.Choice_Static_Blockers := R.Choice_Static_Blockers + 1;
      end if;

      if C.Bounds_Reversed then
         if C.Null_Range_Allowed then
            R.Runtime_Check_Required := R.Runtime_Check_Required or else C.Runtime_Check_Allowed;
         else
            R.Reversed_Range_Blockers := R.Reversed_Range_Blockers + 1;
         end if;
      end if;

      if not C.Bounds_In_Base then
         R.Out_Of_Base_Blockers := R.Out_Of_Base_Blockers + 1;
      end if;

      if C.Expected_Source_Fingerprint /= 0
        and then C.Expected_Source_Fingerprint /= C.Source_Fingerprint
      then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;

      if C.Expected_AST_Fingerprint /= 0
        and then C.Expected_AST_Fingerprint /= C.AST_Fingerprint
      then
         R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
      end if;

      if C.Expected_Type_Fingerprint /= 0
        and then C.Expected_Type_Fingerprint /= C.Type_Fingerprint
      then
         R.Type_Fingerprint_Blockers := R.Type_Fingerprint_Blockers + 1;
      end if;

      if C.Expected_Static_Fingerprint /= 0
        and then C.Expected_Static_Fingerprint /= C.Static_Fingerprint
      then
         R.Static_Fingerprint_Blockers := R.Static_Fingerprint_Blockers + 1;
      end if;
   end Check_Common;

   procedure Check_Choice_Family (C : Choice_Info; R : in out Result_Info) is
   begin
      if Is_Case_Like (C.Kind) then
         if not C.Has_At_Least_One_Choice then
            R.Missing_Choice_Blockers := R.Missing_Choice_Blockers + 1;
         end if;

         if not C.Case_Coverage_Complete then
            R.Incomplete_Case_Blockers := R.Incomplete_Case_Blockers + 1;
         end if;

         if C.Choices_Overlap then
            R.Choice_Overlap_Blockers := R.Choice_Overlap_Blockers + 1;
         end if;

         if C.Others_Present and then not C.Others_Is_Last then
            R.Others_Order_Blockers := R.Others_Order_Blockers + 1;
         end if;

         if C.Duplicate_Others then
            R.Duplicate_Others_Blockers := R.Duplicate_Others_Blockers + 1;
         end if;

         if C.Kind = Choice_Variant_Choice and then not C.Variant_Governor_Compatible then
            R.Variant_Governor_Blockers := R.Variant_Governor_Blockers + 1;
         end if;
      elsif Is_Aggregate_Like (C.Kind) then
         if not C.Aggregate_Choice_Compatible then
            R.Aggregate_Choice_Blockers := R.Aggregate_Choice_Blockers + 1;
         end if;

         if C.Choices_Overlap then
            R.Choice_Overlap_Blockers := R.Choice_Overlap_Blockers + 1;
         end if;
      elsif C.Kind in Choice_Membership_Test | Choice_Not_In_Test then
         if C.Bounds_Reversed and then C.Null_Range_Allowed then
            R.Null_Range_Blockers := 0;
            R.Runtime_Check_Required := R.Runtime_Check_Required or else C.Runtime_Check_Allowed;
         end if;
      else
         null;
      end if;
   end Check_Choice_Family;

   function Build (Choices : Choice_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Choices.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Check := C.Id;
            R.Node := C.Node;
            R.Kind := C.Kind;
            R.Covered_Choice_Count := C.Covered_Choice_Count;
            R.Expected_Choice_Count := C.Expected_Choice_Count;

            Check_Common (C, R);
            Check_Choice_Family (C, R);

            R.Status := Status_For (R, C);
            R.Message := To_Unbounded_String
              ("Case 1315 membership/case-choice vertical-slice legality");
            R.Detail := C.Source_Name;
            R.Fingerprint := Mix
              (Natural (R.Id),
               Natural (C.Id) + Natural (Choice_Kind'Pos (C.Kind))
               + Natural (Discrete_Class'Pos (C.Subject_Type))
               + Natural (Discrete_Class'Pos (C.Choice_Type))
               + Natural (Legality_Status'Pos (R.Status))
               + Blocker_Count (R) + C.Covered_Choice_Count
               + C.Expected_Choice_Count + C.Source_Fingerprint
               + C.AST_Fingerprint + C.Type_Fingerprint
               + C.Static_Fingerprint);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Results.Items.Append (R);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   procedure Clear (Model : in out Choice_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Choice (Model : in out Choice_Model; Info : Choice_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Choice;

   function Choice_Count (Model : Choice_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Choice_Count;

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
      return Count_Status (Model, Legality_Legal_Static)
        + Count_Status (Model, Legality_Legal_Runtime_Check);
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
      return Info.Id /= No_Result and then Info.Check /= No_Check;
   end Has_Result;

end Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality;
