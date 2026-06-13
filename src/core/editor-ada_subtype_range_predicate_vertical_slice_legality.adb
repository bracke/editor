with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1306) mod 1_000_000_007;
   end Mix;

   function Discrete_Type (T : Type_Class) return Boolean is
   begin
      return T in Type_Boolean | Type_Enumeration | Type_Integer |
                  Type_Modular | Type_Universal_Integer;
   end Discrete_Type;

   function Numeric_Compatible (Actual, Expected : Type_Class) return Boolean is
   begin
      if Actual = Expected then
         return True;
      elsif Expected = Type_Integer and then Actual = Type_Universal_Integer then
         return True;
      elsif Expected = Type_Modular and then Actual = Type_Universal_Integer then
         return True;
      elsif Expected = Type_Real and then Actual in Type_Universal_Real | Type_Universal_Integer then
         return True;
      elsif Expected = Type_Fixed and then Actual in Type_Universal_Real | Type_Universal_Integer then
         return True;
      else
         return False;
      end if;
   end Numeric_Compatible;

   function Type_Compatible (Actual, Expected : Type_Class) return Boolean is
   begin
      if Expected = Type_Unknown or else Actual = Type_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      else
         return Numeric_Compatible (Actual, Expected);
      end if;
   end Type_Compatible;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Base_Type_Blockers
        + R.Static_Value_Blockers
        + R.Range_Null_Blockers
        + R.Range_Base_Blockers
        + R.Modular_Blockers
        + R.Digits_Blockers
        + R.Delta_Blockers
        + R.Index_Blockers
        + R.Predicate_Type_Blockers
        + R.Static_Predicate_Blockers
        + R.Static_Predicate_Range_Blockers
        + R.Expected_Type_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; S : Subtype_Info) return Legality_Status is
   begin
      if R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Base_Type_Blockers > 0 then
         return Legality_Missing_Base_Type;
      elsif R.Static_Value_Blockers > 0 then
         return Legality_Missing_Static_Value;
      elsif R.Range_Null_Blockers > 0 then
         return Legality_Range_Null;
      elsif R.Range_Base_Blockers > 0 then
         return Legality_Range_Out_Of_Base;
      elsif R.Modular_Blockers > 0 then
         return Legality_Modular_Range_Invalid;
      elsif R.Digits_Blockers > 0 then
         return Legality_Digits_Invalid;
      elsif R.Delta_Blockers > 0 then
         return Legality_Delta_Invalid;
      elsif R.Index_Blockers > 0 then
         return Legality_Index_Not_Discrete;
      elsif R.Predicate_Type_Blockers > 0 then
         return Legality_Predicate_Not_Boolean;
      elsif R.Static_Predicate_Blockers > 0 then
         return Legality_Static_Predicate_Not_Static;
      elsif R.Static_Predicate_Range_Blockers > 0 then
         return Legality_Static_Predicate_Out_Of_Range;
      elsif R.Expected_Type_Blockers > 0 then
         return Legality_Expected_Type_Mismatch;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif Blocker_Count (R) > 1 then
         return Legality_Multiple_Blockers;
      elsif S.Kind = Constraint_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Check_Common (S : Subtype_Info; R : in out Result_Info) is
   begin
      if not S.Has_AST_Coverage or else not S.Has_Predicate_AST then
         R.AST_Blockers := R.AST_Blockers + 1;
      end if;

      if not S.Has_Base_Type or else S.Base_Type = Type_Unknown then
         R.Base_Type_Blockers := R.Base_Type_Blockers + 1;
      end if;

      if not Type_Compatible (S.Base_Type, S.Expected_Type) then
         R.Expected_Type_Blockers := R.Expected_Type_Blockers + 1;
      end if;

      if S.Expected_Source_Fingerprint /= 0
        and then S.Expected_Source_Fingerprint /= S.Source_Fingerprint
      then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;

      if S.Expected_AST_Fingerprint /= 0
        and then S.Expected_AST_Fingerprint /= S.AST_Fingerprint
      then
         R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
      end if;
   end Check_Common;

   procedure Check_Range (S : Subtype_Info; R : in out Result_Info) is
   begin
      if not S.Has_Static_Lower or else not S.Has_Static_Upper then
         R.Static_Value_Blockers := R.Static_Value_Blockers + 1;
         return;
      end if;

      if S.Low > S.High then
         R.Range_Null_Blockers := R.Range_Null_Blockers + 1;
      end if;

      if S.Low < S.Base_Low or else S.High > S.Base_High then
         R.Range_Base_Blockers := R.Range_Base_Blockers + 1;
      end if;
   end Check_Range;

   procedure Check_Predicate (S : Subtype_Info; R : in out Result_Info) is
   begin
      if S.Predicate_Type /= Type_Boolean or else not S.Predicate_Is_Boolean then
         R.Predicate_Type_Blockers := R.Predicate_Type_Blockers + 1;
      end if;

      if S.Kind = Constraint_Static_Predicate
        and then not S.Predicate_Is_Static
      then
         R.Static_Predicate_Blockers := R.Static_Predicate_Blockers + 1;
      end if;

      if S.Kind = Constraint_Static_Predicate
        and then not S.Predicate_Value_In_Range
      then
         R.Static_Predicate_Range_Blockers := R.Static_Predicate_Range_Blockers + 1;
      end if;

      if S.Kind = Constraint_Dynamic_Predicate
        or else S.Predicate_Needs_Runtime_Check
      then
         R.Runtime_Check_Required := True;
      end if;
   end Check_Predicate;

   function Build_Result (S : Subtype_Info; Id : Result_Id) return Result_Info is
      R : Result_Info;
   begin
      R.Id := Id;
      R.Subtype_Ref := S.Id;
      R.Node := S.Node;
      R.Kind := S.Kind;
      R.Resolved_Type := S.Base_Type;
      R.Source_Fingerprint := S.Source_Fingerprint;
      R.AST_Fingerprint := S.AST_Fingerprint;

      Check_Common (S, R);

      case S.Kind is
         when Constraint_Range =>
            if not Discrete_Type (S.Base_Type) and then S.Base_Type /= Type_Real and then S.Base_Type /= Type_Fixed then
               R.Base_Type_Blockers := R.Base_Type_Blockers + 1;
            end if;
            Check_Range (S, R);

         when Constraint_Modular_Range =>
            if S.Base_Type /= Type_Modular then
               R.Base_Type_Blockers := R.Base_Type_Blockers + 1;
            end if;
            if S.Modulus <= 0 or else S.Low < 0 or else S.High >= S.Modulus or else S.Low > S.High then
               R.Modular_Blockers := R.Modular_Blockers + 1;
            end if;

         when Constraint_Floating_Digits =>
            if S.Base_Type not in Type_Real | Type_Universal_Real then
               R.Base_Type_Blockers := R.Base_Type_Blockers + 1;
            end if;
            if S.Digits_Value = 0 then
               R.Digits_Blockers := R.Digits_Blockers + 1;
            end if;

         when Constraint_Fixed_Delta =>
            if S.Base_Type /= Type_Fixed then
               R.Base_Type_Blockers := R.Base_Type_Blockers + 1;
            end if;
            if S.Delta_Numerator = 0 or else S.Delta_Denominator = 0 then
               R.Delta_Blockers := R.Delta_Blockers + 1;
            end if;

         when Constraint_Index_Range =>
            if not S.Index_Discrete or else not Discrete_Type (S.Base_Type) then
               R.Index_Blockers := R.Index_Blockers + 1;
            end if;
            Check_Range (S, R);

         when Constraint_Predicate | Constraint_Static_Predicate | Constraint_Dynamic_Predicate =>
            if not S.Has_Static_Value and then S.Kind = Constraint_Static_Predicate then
               R.Static_Value_Blockers := R.Static_Value_Blockers + 1;
            end if;
            Check_Range (S, R);
            Check_Predicate (S, R);

         when Constraint_Unknown =>
            null;
      end case;

      if Blocker_Count (R) > 1 then
         R.Status := Legality_Multiple_Blockers;
      else
         R.Status := Status_For (R, S);
      end if;

      R.Message := To_Unbounded_String
        (case R.Status is
            when Legality_Legal => "subtype constraint is legal",
            when Legality_Legal_With_Runtime_Check => "subtype constraint is legal with runtime check",
            when Legality_Missing_AST_Coverage => "subtype constraint lacks parser-owned AST coverage",
            when Legality_Missing_Base_Type => "subtype constraint lacks base type evidence",
            when Legality_Missing_Static_Value => "subtype constraint lacks required static value",
            when Legality_Range_Null => "subtype range is null",
            when Legality_Range_Out_Of_Base => "subtype range is outside base range",
            when Legality_Modular_Range_Invalid => "modular subtype range is invalid",
            when Legality_Digits_Invalid => "floating digits constraint is invalid",
            when Legality_Delta_Invalid => "fixed delta constraint is invalid",
            when Legality_Index_Not_Discrete => "index subtype is not discrete",
            when Legality_Predicate_Not_Boolean => "predicate does not resolve to Boolean",
            when Legality_Static_Predicate_Not_Static => "static predicate is not static",
            when Legality_Static_Predicate_Out_Of_Range => "static predicate value is outside subtype range",
            when Legality_Dynamic_Predicate_Requires_Check => "dynamic predicate requires runtime check",
            when Legality_Expected_Type_Mismatch => "expected type does not match subtype base type",
            when Legality_Source_Fingerprint_Mismatch => "source fingerprint mismatch",
            when Legality_AST_Fingerprint_Mismatch => "AST fingerprint mismatch",
            when Legality_Multiple_Blockers => "multiple subtype legality blockers",
            when Legality_Indeterminate => "indeterminate subtype constraint",
            when Legality_Not_Checked => "subtype constraint was not checked");
      R.Detail := S.Source_Name;
      R.Fingerprint := Mix
        (Natural (R.Subtype_Ref), Mix (Natural (R.Status'Pos), Mix (R.Source_Fingerprint, R.AST_Fingerprint)));
      return R;
   end Build_Result;

   procedure Clear (Model : in out Subtype_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Subtype (Model : in out Subtype_Model; Info : Subtype_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Subtype;

   function Build (Subtypes : Subtype_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Result_Id := 1;
   begin
      for S of Subtypes.Items loop
         declare
            R : constant Result_Info := Build_Result (S, Next_Id);
         begin
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   function Subtype_Count (Model : Subtype_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Subtype_Count;

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
         if R.Status in Legality_Legal | Legality_Legal_With_Runtime_Check then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status not in Legality_Legal | Legality_Legal_With_Runtime_Check | Legality_Not_Checked then
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
      return Info.Id /= No_Result and then Info.Subtype_Ref /= No_Subtype;
   end Has_Result;

end Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality;
