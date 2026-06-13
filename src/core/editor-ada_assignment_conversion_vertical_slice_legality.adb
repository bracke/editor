with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1327) mod 1_000_000_007;
   end Mix;

   function Is_Numeric_Kind (Kind : Type_Kind) return Boolean is
   begin
      return Kind = Type_Integer
        or else Kind = Type_Real
        or else Kind = Type_Modular
        or else Kind = Type_Fixed;
   end Is_Numeric_Kind;

   function Is_Access_Kind (Kind : Type_Kind) return Boolean is
   begin
      return Kind = Type_Access_Object or else Kind = Type_Access_Subprogram;
   end Is_Access_Kind;

   function Same_Family (Left, Right : Type_Info) return Boolean is
   begin
      if Left.Id = No_Type or else Right.Id = No_Type then
         return False;
      elsif Left.Id = Right.Id then
         return True;
      elsif Left.Base_Type /= No_Type and then Left.Base_Type = Right.Base_Type then
         return True;
      elsif Left.Root_Type /= No_Type and then Left.Root_Type = Right.Root_Type then
         return True;
      elsif Left.Kind = Right.Kind then
         return True;
      elsif Is_Numeric_Kind (Left.Kind) and then Is_Numeric_Kind (Right.Kind) then
         return True;
      else
         return False;
      end if;
   end Same_Family;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Check_Blockers
        + R.Missing_Target_Blockers
        + R.Missing_Source_Blockers
        + R.Missing_Target_Type_Blockers
        + R.Missing_Source_Type_Blockers
        + R.Target_Variable_Blockers
        + R.Limited_Assignment_Blockers
        + R.Type_Mismatch_Blockers
        + R.Conversion_Blockers
        + R.View_Conversion_Blockers
        + R.Class_Wide_Conversion_Blockers
        + R.Numeric_Conversion_Blockers
        + R.Access_Conversion_Blockers
        + R.Null_Exclusion_Blockers
        + R.Accessibility_Blockers
        + R.Range_Blockers
        + R.Predicate_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Controlled_Finalization_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers;
   end Blocker_Count;

   procedure Add_View_Blocker (View : View_Kind; R : in out Result_Info) is
   begin
      case View is
         when View_Private => R.Private_View_Blockers := 1;
         when View_Limited => R.Limited_View_Blockers := 1;
         when View_Incomplete => R.Incomplete_View_Blockers := 1;
         when View_Generic_Formal => R.Generic_Formal_View_Blockers := 1;
         when others => null;
      end case;
   end Add_View_Blocker;

   function Status_For (R : Result_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Check_Blockers > 0 then
         return Legality_Missing_Check;
      elsif R.Missing_Target_Blockers > 0 then
         return Legality_Missing_Target;
      elsif R.Missing_Source_Blockers > 0 then
         return Legality_Missing_Source;
      elsif R.Missing_Target_Type_Blockers > 0 then
         return Legality_Missing_Target_Type;
      elsif R.Missing_Source_Type_Blockers > 0 then
         return Legality_Missing_Source_Type;
      elsif R.Target_Variable_Blockers > 0 then
         return Legality_Assignment_Target_Not_Variable;
      elsif R.Limited_Assignment_Blockers > 0 then
         return Legality_Assignment_To_Limited_View;
      elsif R.Type_Mismatch_Blockers > 0 then
         return Legality_Type_Mismatch;
      elsif R.Conversion_Blockers > 0 then
         return Legality_Conversion_Not_Allowed;
      elsif R.View_Conversion_Blockers > 0 then
         return Legality_View_Conversion_Not_Allowed;
      elsif R.Class_Wide_Conversion_Blockers > 0 then
         return Legality_Class_Wide_Conversion_Not_Allowed;
      elsif R.Numeric_Conversion_Blockers > 0 then
         return Legality_Numeric_Conversion_Not_Allowed;
      elsif R.Access_Conversion_Blockers > 0 then
         return Legality_Access_Conversion_Not_Allowed;
      elsif R.Null_Exclusion_Blockers > 0 then
         return Legality_Null_Exclusion_Violation;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocker;
      elsif R.Range_Blockers > 0 then
         return Legality_Range_Blocker;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocker;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Legality_Generic_Formal_View_Barrier;
      elsif R.Controlled_Finalization_Blockers > 0 then
         return Legality_Controlled_Finalization_Blocker;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif Blocks = 0 and then R.Runtime_Check_Count > 0 then
         return Legality_Legal_With_Runtime_Check;
      elsif Blocks = 0 then
         return Legality_Legal;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   function Find_Entity (Model : Entity_Model; Id : Entity_Id) return Entity_Info is
   begin
      for E of Model.Items loop
         if E.Id = Id then
            return E;
         end if;
      end loop;
      return (others => <>);
   end Find_Entity;

   function Find_Type (Model : Type_Model; Id : Type_Id) return Type_Info is
   begin
      for T of Model.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   procedure Clear (Model : in out Entity_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Check_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Entity;

   procedure Add_Type (Model : in out Type_Model; Info : Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Type;

   procedure Add_Check (Model : in out Check_Model; Info : Check_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Check;

   procedure Add_Fingerprint_Blockers (C : Check_Info; R : in out Result_Info) is
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if C.AST_Fingerprint /= C.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if C.Type_Fingerprint /= C.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         R.Substitution_Fingerprint_Blockers := 1;
      end if;
   end Add_Fingerprint_Blockers;

   procedure Add_Entity_Blockers (E : Entity_Info; R : in out Result_Info) is
   begin
      Add_View_Blocker (E.View, R);
      if E.Source_Fingerprint /= E.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if E.Type_Fingerprint /= E.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
      if E.Controlled_Or_Finalized then
         R.Controlled_Finalization_Blockers := 1;
      end if;
   end Add_Entity_Blockers;

   procedure Add_Type_Blockers (T : Type_Info; R : in out Result_Info) is
   begin
      Add_View_Blocker (T.View, R);
      if T.Source_Fingerprint /= T.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if T.Type_Fingerprint /= T.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
   end Add_Type_Blockers;

   function Build
     (Entities : Entity_Model;
      Types : Type_Model;
      Checks : Check_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      for C of Checks.Items loop
         declare
            Target : constant Entity_Info := Find_Entity (Entities, C.Target);
            Source : constant Entity_Info := Find_Entity (Entities, C.Source);
            Target_Type : constant Type_Info := Find_Type (Types, C.Target_Type);
            Source_Type : constant Type_Info := Find_Type (Types, C.Source_Type);
            R : Result_Info;
         begin
            R.Id := Result_Id (Natural (C.Id));
            R.Check := C.Id;
            R.Target := C.Target;
            R.Source := C.Source;
            R.Target_Type := C.Target_Type;
            R.Source_Type := C.Source_Type;
            R.Operation := C.Operation;

            if C.Id = No_Check then
               R.Missing_Check_Blockers := 1;
            end if;

            Add_Fingerprint_Blockers (C, R);

            if C.Operation = Operation_Assignment then
               if Target.Id = No_Entity then
                  R.Missing_Target_Blockers := 1;
               else
                  Add_Entity_Blockers (Target, R);
                  if not Target.Is_Variable_View then
                     R.Target_Variable_Blockers := 1;
                  end if;
                  if Target.Is_Limited_View then
                     R.Limited_Assignment_Blockers := 1;
                  end if;
               end if;
            end if;

            if Source.Id = No_Entity and then C.Operation = Operation_Assignment then
               R.Missing_Source_Blockers := 1;
            elsif Source.Id /= No_Entity then
               Add_Entity_Blockers (Source, R);
            end if;

            if Target_Type.Id = No_Type then
               R.Missing_Target_Type_Blockers := 1;
            else
               Add_Type_Blockers (Target_Type, R);
            end if;

            if Source_Type.Id = No_Type then
               R.Missing_Source_Type_Blockers := 1;
            else
               Add_Type_Blockers (Source_Type, R);
            end if;

            if Target_Type.Id /= No_Type and then Source_Type.Id /= No_Type then
               if C.Operation = Operation_Assignment
                 or else C.Operation = Operation_Qualified_Expression
               then
                  if not C.Type_Compatibility_OK
                    or else not Same_Family (Target_Type, Source_Type)
                  then
                     R.Type_Mismatch_Blockers := 1;
                  end if;
               elsif C.Operation = Operation_Type_Conversion then
                  if not C.Explicit_Conversion
                    or else not C.Type_Compatibility_OK
                    or else not Target_Type.Conversion_Profile_Conformant
                    or else not Source_Type.Conversion_Profile_Conformant
                  then
                     R.Conversion_Blockers := 1;
                  end if;
               elsif C.Operation = Operation_View_Conversion then
                  if not C.View_Conversion_OK or else Target_Type.Is_Limited then
                     R.View_Conversion_Blockers := 1;
                  end if;
               elsif C.Operation = Operation_Class_Wide_Conversion then
                  if not C.Class_Wide_Conversion_OK
                    or else not (Target_Type.Is_Class_Wide or else Source_Type.Is_Class_Wide)
                  then
                     R.Class_Wide_Conversion_Blockers := 1;
                  end if;
               elsif C.Operation = Operation_Numeric_Conversion then
                  if not C.Numeric_Conversion_OK
                    or else not (Target_Type.Is_Numeric or else Is_Numeric_Kind (Target_Type.Kind))
                    or else not (Source_Type.Is_Numeric or else Is_Numeric_Kind (Source_Type.Kind))
                  then
                     R.Numeric_Conversion_Blockers := 1;
                  end if;
               elsif C.Operation = Operation_Access_Conversion then
                  if not C.Access_Conversion_OK
                    or else not Target_Type.Access_Profile_Conformant
                    or else not Source_Type.Access_Profile_Conformant
                    or else not (Target_Type.Is_Access or else Is_Access_Kind (Target_Type.Kind))
                    or else not (Source_Type.Is_Access or else Is_Access_Kind (Source_Type.Kind))
                  then
                     R.Access_Conversion_Blockers := 1;
                  end if;
               else
                  R.Conversion_Blockers := 1;
               end if;
            end if;

            if C.Source_Is_Null and then C.Target_Null_Excluding then
               R.Null_Exclusion_Blockers := 1;
            end if;
            if not C.Accessibility_OK then
               R.Accessibility_Blockers := 1;
            end if;
            if not C.Static_Range_OK then
               R.Range_Blockers := 1;
            end if;
            if not C.Predicate_OK then
               R.Predicate_Blockers := 1;
            end if;
            if not C.Controlled_Finalization_OK then
               R.Controlled_Finalization_Blockers := 1;
            end if;
            if C.Runtime_Range_Check_Required then
               R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
            end if;
            if C.Runtime_Predicate_Check_Required then
               R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
            end if;
            if C.Runtime_Accessibility_Check_Required then
               R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
            end if;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, R.Runtime_Check_Count);
            R.Message := To_Unbounded_String ("assignment/conversion vertical slice");
            R.Detail := To_Unbounded_String (Legality_Status'Image (R.Status));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Entity_Count (Model : Entity_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Entity_Count;

   function Type_Count (Model : Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Type_Count;

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

end Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality;
