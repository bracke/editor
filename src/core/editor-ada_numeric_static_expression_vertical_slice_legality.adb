with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1314) mod 1_000_000_007;
   end Mix;

   function Numeric_Compatible (Actual, Expected : Numeric_Class) return Boolean is
   begin
      if Expected = Numeric_Unknown or else Actual = Numeric_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Expected = Numeric_Integer and then Actual = Numeric_Universal_Integer then
         return True;
      elsif Expected = Numeric_Modular and then Actual = Numeric_Universal_Integer then
         return True;
      elsif Expected = Numeric_Real and then Actual in Numeric_Universal_Real | Numeric_Universal_Integer then
         return True;
      elsif Expected = Numeric_Fixed and then Actual in Numeric_Universal_Real | Numeric_Universal_Integer then
         return True;
      elsif Expected = Numeric_Duration and then Actual in Numeric_Universal_Real | Numeric_Universal_Integer then
         return True;
      else
         return False;
      end if;
   end Numeric_Compatible;

   function Static_Operator_Allowed (Op : Operator_Kind) return Boolean is
   begin
      return Op in Operator_None | Operator_Add | Operator_Subtract |
                   Operator_Multiply | Operator_Divide | Operator_Mod |
                   Operator_Rem | Operator_Exponent | Operator_Abs |
                   Operator_Unary_Minus;
   end Static_Operator_Allowed;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Type_Blockers
        + R.Static_Blockers
        + R.Named_Number_Blockers
        + R.Constant_Blockers
        + R.Operand_Static_Blockers
        + R.Operator_Static_Blockers
        + R.Universal_Ambiguity_Blockers
        + R.Universal_Resolution_Blockers
        + R.Expected_Type_Blockers
        + R.Range_Blockers
        + R.Modular_Blockers
        + R.Divide_By_Zero_Blockers
        + R.Exponent_Blockers
        + R.Fixed_Delta_Blockers
        + R.Attribute_Blockers
        + R.Qualification_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; E : Expression_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Type_Blockers > 0 then
         return Legality_Missing_Type_Evidence;
      elsif R.Static_Blockers > 0 then
         return Legality_Not_Static;
      elsif R.Named_Number_Blockers > 0 then
         return Legality_Named_Number_Not_Static;
      elsif R.Constant_Blockers > 0 then
         return Legality_Static_Constant_Not_Static;
      elsif R.Operand_Static_Blockers > 0 then
         return Legality_Operand_Not_Static;
      elsif R.Operator_Static_Blockers > 0 then
         return Legality_Operator_Not_Static;
      elsif R.Universal_Ambiguity_Blockers > 0 then
         return Legality_Universal_Numeric_Ambiguous;
      elsif R.Universal_Resolution_Blockers > 0 then
         return Legality_Universal_Numeric_Not_Resolved;
      elsif R.Expected_Type_Blockers > 0 then
         return Legality_Expected_Type_Mismatch;
      elsif R.Range_Blockers > 0 then
         return Legality_Range_Out_Of_Base;
      elsif R.Modular_Blockers > 0 then
         return Legality_Modular_Out_Of_Modulus;
      elsif R.Divide_By_Zero_Blockers > 0 then
         return Legality_Divide_By_Zero_Static;
      elsif R.Exponent_Blockers > 0 then
         return Legality_Exponent_Not_Natural;
      elsif R.Fixed_Delta_Blockers > 0 then
         return Legality_Fixed_Delta_Mismatch;
      elsif R.Attribute_Blockers > 0 then
         return Legality_Attribute_Not_Static;
      elsif R.Qualification_Blockers > 0 then
         return Legality_Qualification_Mismatch;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif E.Kind = Expr_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_Nonstatic_Runtime_Check;
      else
         return Legality_Legal_Static;
      end if;
   end Status_For;

   procedure Check_Common (E : Expression_Info; R : in out Result_Info) is
   begin
      if not E.Has_AST_Coverage then
         R.AST_Blockers := R.AST_Blockers + 1;
      end if;

      if not E.Has_Type_Evidence or else E.Actual_Type = Numeric_Unknown then
         R.Type_Blockers := R.Type_Blockers + 1;
      end if;

      if E.Requires_Static_Context and then not E.Expression_Is_Static then
         R.Static_Blockers := R.Static_Blockers + 1;
      end if;

      if E.Universal_Ambiguous then
         R.Universal_Ambiguity_Blockers := R.Universal_Ambiguity_Blockers + 1;
      end if;

      if not E.Universal_Resolved then
         R.Universal_Resolution_Blockers := R.Universal_Resolution_Blockers + 1;
      end if;

      if not Numeric_Compatible (E.Actual_Type, E.Expected_Type) then
         R.Expected_Type_Blockers := R.Expected_Type_Blockers + 1;
      end if;

      if E.Expected_Source_Fingerprint /= 0
        and then E.Expected_Source_Fingerprint /= E.Source_Fingerprint
      then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;

      if E.Expected_AST_Fingerprint /= 0
        and then E.Expected_AST_Fingerprint /= E.AST_Fingerprint
      then
         R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
      end if;

      if E.Expected_Type_Fingerprint /= 0
        and then E.Expected_Type_Fingerprint /= E.Type_Fingerprint
      then
         R.Type_Fingerprint_Blockers := R.Type_Fingerprint_Blockers + 1;
      end if;

      R.Runtime_Check_Required := E.Runtime_Check_Required or else E.Range_Check_Required;
   end Check_Common;

   procedure Check_Kind (E : Expression_Info; R : in out Result_Info) is
   begin
      case E.Kind is
         when Expr_Named_Number =>
            if not E.Named_Number_Is_Static then
               R.Named_Number_Blockers := R.Named_Number_Blockers + 1;
            end if;

         when Expr_Static_Constant =>
            if not E.Static_Constant_Is_Static then
               R.Constant_Blockers := R.Constant_Blockers + 1;
            end if;

         when Expr_Unary_Operator | Expr_Binary_Operator =>
            if not E.Left_Operand_Static
              or else (E.Kind = Expr_Binary_Operator and then not E.Right_Operand_Static)
            then
               R.Operand_Static_Blockers := R.Operand_Static_Blockers + 1;
            end if;

            if not E.Operator_Static_Allowed
              or else not Static_Operator_Allowed (E.Operator)
            then
               R.Operator_Static_Blockers := R.Operator_Static_Blockers + 1;
            end if;

            if E.Operator = Operator_Divide and then E.Divisor_Is_Zero then
               R.Divide_By_Zero_Blockers := R.Divide_By_Zero_Blockers + 1;
            end if;

            if E.Operator = Operator_Exponent and then not E.Exponent_Is_Natural then
               R.Exponent_Blockers := R.Exponent_Blockers + 1;
            end if;

         when Expr_Qualified_Expression =>
            if not E.Qualified_Type_Compatible then
               R.Qualification_Blockers := R.Qualification_Blockers + 1;
            end if;

         when Expr_Static_Attribute =>
            if not E.Attribute_Static then
               R.Attribute_Blockers := R.Attribute_Blockers + 1;
            end if;

         when Expr_Range_Bound =>
            if not E.Range_In_Base then
               R.Range_Blockers := R.Range_Blockers + 1;
            end if;

         when Expr_Modular_Expression =>
            if not E.Modular_In_Modulus then
               R.Modular_Blockers := R.Modular_Blockers + 1;
            end if;

         when Expr_Fixed_Point_Expression =>
            if not E.Fixed_Delta_Compatible then
               R.Fixed_Delta_Blockers := R.Fixed_Delta_Blockers + 1;
            end if;

         when Expr_Integer_Literal | Expr_Real_Literal | Expr_Unknown =>
            null;
      end case;
   end Check_Kind;

   function Build (Expressions : Expression_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for E of Expressions.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Expression := E.Id;
            R.Node := E.Node;
            R.Kind := E.Kind;
            R.Operator := E.Operator;
            R.Resolved_Type := (if E.Resolved_Type = Numeric_Unknown then E.Actual_Type else E.Resolved_Type);
            R.Static_Integer_Value := E.Static_Integer_Value;

            Check_Common (E, R);
            Check_Kind (E, R);

            R.Status := Status_For (R, E);
            R.Message := To_Unbounded_String
              ("Pass1314 numeric/static expression vertical-slice legality");
            R.Detail := E.Source_Name;
            R.Fingerprint := Mix
              (Natural (R.Id),
               Natural (E.Id) + Natural (Expression_Kind'Pos (E.Kind))
               + Natural (Operator_Kind'Pos (E.Operator))
               + Natural (Legality_Status'Pos (R.Status))
               + Blocker_Count (R)
               + E.Source_Fingerprint + E.AST_Fingerprint + E.Type_Fingerprint);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Results.Items.Append (R);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   procedure Clear (Model : in out Expression_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Expression (Model : in out Expression_Model; Info : Expression_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Expression;

   function Expression_Count (Model : Expression_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Expression_Count;

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
        + Count_Status (Model, Legality_Legal_Nonstatic_Runtime_Check);
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
      return Info.Id /= No_Result and then Info.Expression /= No_Expression;
   end Has_Result;

end Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality;
