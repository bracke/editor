with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1307) mod 1_000_000_007;
   end Mix;

   function Numeric_Compatible (Actual, Expected : Type_Class) return Boolean is
   begin
      if Actual = Expected then
         return True;
      elsif Expected in Type_Integer | Type_Modular and then Actual = Type_Universal_Integer then
         return True;
      elsif Expected in Type_Real | Type_Fixed
        and then Actual in Type_Universal_Real | Type_Universal_Integer
      then
         return True;
      else
         return False;
      end if;
   end Numeric_Compatible;

   function Type_Compatible (Actual, Expected : Type_Class; Universal_OK : Boolean) return Boolean is
   begin
      if Expected = Type_Unknown or else Actual = Type_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Universal_OK then
         return Numeric_Compatible (Actual, Expected);
      else
         return False;
      end if;
   end Type_Compatible;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Object_Type_Blockers
        + R.Initializer_Blockers
        + R.Type_Blockers
        + R.Subtype_Blockers
        + R.Predicate_Blockers
        + R.Default_Blockers
        + R.Deferred_Completion_Blockers
        + R.Deferred_Type_Blockers
        + R.Aggregate_Missing_Blockers
        + R.Aggregate_Duplicate_Blockers
        + R.Aggregate_Type_Blockers
        + R.Limited_Default_Blockers
        + R.Controlled_Blockers
        + R.Accessibility_Blockers
        + R.Assignment_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; O : Object_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Object_Type_Blockers > 0 then
         return Legality_Missing_Object_Type;
      elsif R.Initializer_Blockers > 0 then
         return Legality_Missing_Initializer;
      elsif R.Type_Blockers > 0 then
         return Legality_Type_Mismatch;
      elsif R.Subtype_Blockers > 0 then
         return Legality_Subtype_Range_Blocked;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocked;
      elsif R.Default_Blockers > 0 then
         return Legality_Default_Expression_Blocked;
      elsif R.Deferred_Completion_Blockers > 0 then
         return Legality_Deferred_Constant_Missing_Completion;
      elsif R.Deferred_Type_Blockers > 0 then
         return Legality_Deferred_Constant_Type_Mismatch;
      elsif R.Aggregate_Missing_Blockers > 0 then
         return Legality_Aggregate_Component_Missing;
      elsif R.Aggregate_Duplicate_Blockers > 0 then
         return Legality_Aggregate_Component_Duplicate;
      elsif R.Aggregate_Type_Blockers > 0 then
         return Legality_Aggregate_Component_Type_Mismatch;
      elsif R.Limited_Default_Blockers > 0 then
         return Legality_Limited_Default_Required;
      elsif R.Controlled_Blockers > 0 then
         return Legality_Controlled_Finalization_Blocked;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocked;
      elsif R.Assignment_Blockers > 0 then
         return Legality_Definite_Assignment_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif O.Kind = Initialization_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   function Status_Code (Status : Legality_Status) return Natural is
   begin
      return Legality_Status'Pos (Status) + 1;
   end Status_Code;

   procedure Clear (Model : in out Initialization_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Object (Model : in out Initialization_Model; Info : Object_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Initialization_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
   end Add_Object;

   function Build (Objects : Initialization_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for O of Objects.Items loop
         declare
            R : Result_Info;
            Expected_Type : Type_Class := O.Expected_Type;
         begin
            if Expected_Type = Type_Unknown then
               Expected_Type := O.Object_Type;
            end if;

            R.Id := Result_Id (Next_Id);
            R.Object := O.Id;
            R.Node := O.Node;
            R.Kind := O.Kind;
            R.Resolved_Type := Expected_Type;
            R.Source_Fingerprint := O.Source_Fingerprint;
            R.AST_Fingerprint := O.AST_Fingerprint;

            if not O.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;

            if not O.Has_Object_Type then
               R.Object_Type_Blockers := R.Object_Type_Blockers + 1;
            end if;

            if O.Requires_Initializer and then not O.Has_Initializer then
               R.Initializer_Blockers := R.Initializer_Blockers + 1;
            end if;

            if O.Has_Initializer
              and then not Type_Compatible (O.Initializer_Type, Expected_Type, O.Universal_Compatible)
            then
               R.Type_Blockers := R.Type_Blockers + 1;
            end if;

            if not O.Subtype_Range_Legal then
               R.Subtype_Blockers := R.Subtype_Blockers + 1;
            end if;

            if not O.Predicate_Legal then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            elsif O.Runtime_Predicate_Check_Required then
               R.Runtime_Check_Required := True;
            end if;

            if O.Has_Default_Expression and then not O.Default_Expression_Legal then
               R.Default_Blockers := R.Default_Blockers + 1;
            end if;

            if O.Is_Deferred_Constant then
               if not O.Has_Deferred_Completion then
                  R.Deferred_Completion_Blockers := R.Deferred_Completion_Blockers + 1;
               elsif not O.Deferred_Completion_Type_Matches then
                  R.Deferred_Type_Blockers := R.Deferred_Type_Blockers + 1;
               end if;
            end if;

            if O.Kind in Initialization_Aggregate | Initialization_Array_Aggregate |
                         Initialization_Record_Aggregate
            then
               if not O.Aggregate_Complete then
                  R.Aggregate_Missing_Blockers := R.Aggregate_Missing_Blockers + 1;
               end if;
               if O.Aggregate_Has_Duplicate_Component then
                  R.Aggregate_Duplicate_Blockers := R.Aggregate_Duplicate_Blockers + 1;
               end if;
               if not O.Aggregate_Component_Types_Match then
                  R.Aggregate_Type_Blockers := R.Aggregate_Type_Blockers + 1;
               end if;
            end if;

            if O.Is_Limited_Type and then not O.Limited_Default_Available
              and then not O.Has_Initializer
            then
               R.Limited_Default_Blockers := R.Limited_Default_Blockers + 1;
            end if;

            if not O.Controlled_Finalization_Legal then
               R.Controlled_Blockers := R.Controlled_Blockers + 1;
            end if;

            if not O.Accessibility_Legal then
               R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
            end if;

            if not O.Definite_Assignment_Legal then
               R.Assignment_Blockers := R.Assignment_Blockers + 1;
            end if;

            if O.Expected_Source_Fingerprint /= 0
              and then O.Expected_Source_Fingerprint /= O.Source_Fingerprint
            then
               R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
            end if;

            if O.Expected_AST_Fingerprint /= 0
              and then O.Expected_AST_Fingerprint /= O.AST_Fingerprint
            then
               R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, O);
            R.Message := To_Unbounded_String ("object initialization/default legality");
            R.Detail := O.Source_Name;
            R.Fingerprint := Mix (Natural (R.Object), Status_Code (R.Status));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;

      return Results;
   end Build;

   function Object_Count (Model : Initialization_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Object_Count;

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
   begin
      return Result_Count (Model) - Legal_Count (Model)
        - Count_Status (Model, Legality_Not_Checked);
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Object /= No_Object;
   end Has_Result;

end Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality;
