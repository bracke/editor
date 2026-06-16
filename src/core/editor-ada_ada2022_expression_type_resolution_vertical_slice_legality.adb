with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 997) + 1305) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : Resolution_Status) return Boolean is
   begin
      return Status in Resolution_Legal | Resolution_Legal_With_Runtime_Check;
   end Is_Legal;

   function Numeric_Compatible (Actual, Expected : Type_Class) return Boolean is
   begin
      if Actual = Expected then
         return True;
      elsif Expected = Type_Integer
        and then Actual in Type_Universal_Integer
      then
         return True;
      elsif Expected = Type_Real
        and then Actual in Type_Universal_Real | Type_Universal_Integer
      then
         return True;
      elsif Expected = Type_Universal_Real
        and then Actual = Type_Universal_Integer
      then
         return True;
      else
         return False;
      end if;
   end Numeric_Compatible;

   function Type_Compatible (Actual, Expected : Type_Class) return Boolean is
   begin
      if Expected = Type_Unknown or else Actual = Type_Unknown then
         return False;
      elsif Actual = Expected then
         return True;
      elsif Numeric_Compatible (Actual, Expected) then
         return True;
      elsif Expected = Type_Tagged and then Actual = Type_Record then
         return True;
      else
         return False;
      end if;
   end Type_Compatible;

   function Composite_Type (T : Type_Class) return Boolean is
   begin
      return T in Type_Array | Type_Record | Type_Tagged | Type_Container;
   end Composite_Type;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Expected_Type_Blockers
        + R.Operand_Type_Blockers
        + R.Predicate_Blockers
        + R.Reduction_Profile_Blockers
        + R.Reduction_Seed_Blockers
        + R.Delta_Base_Blockers
        + R.Delta_Component_Blockers
        + R.Container_Element_Blockers
        + R.Declare_Result_Blockers
        + R.Target_Name_Blockers
        + R.Indexing_Blockers
        + R.Parallel_State_Blockers
        + R.Expected_Result_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; E : Expression_Info) return Resolution_Status is
   begin
      if R.AST_Blockers > 0 then
         return Resolution_Missing_AST_Coverage;
      elsif R.Expected_Type_Blockers > 0 then
         return Resolution_Missing_Expected_Type;
      elsif R.Operand_Type_Blockers > 0 then
         return Resolution_Missing_Operand_Type;
      elsif R.Predicate_Blockers > 0 then
         return Resolution_Predicate_Not_Boolean;
      elsif R.Reduction_Profile_Blockers > 0 then
         return Resolution_Reduction_Profile_Mismatch;
      elsif R.Reduction_Seed_Blockers > 0 then
         return Resolution_Reduction_Seed_Mismatch;
      elsif R.Delta_Base_Blockers > 0 then
         return Resolution_Delta_Base_Not_Composite;
      elsif R.Delta_Component_Blockers > 0 then
         return Resolution_Delta_Component_Mismatch;
      elsif R.Container_Element_Blockers > 0 then
         return Resolution_Container_Element_Mismatch;
      elsif R.Declare_Result_Blockers > 0 then
         return Resolution_Declare_Result_Mismatch;
      elsif R.Target_Name_Blockers > 0 then
         return Resolution_Target_Name_Outside_Update;
      elsif R.Indexing_Blockers > 0 then
         return Resolution_Generalized_Indexing_Mismatch;
      elsif R.Parallel_State_Blockers > 0 then
         return Resolution_Parallel_Loop_Shared_State_Blocker;
      elsif R.Expected_Result_Blockers > 0 then
         return Resolution_Expected_Type_Mismatch;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Resolution_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Resolution_AST_Fingerprint_Mismatch;
      elsif E.Needs_Runtime_Accessibility_Check then
         return Resolution_Legal_With_Runtime_Check;
      else
         return Resolution_Legal;
      end if;
   end Status_For;

   procedure Add_Message (R : in out Result_Info) is
   begin
      case R.Status is
         when Resolution_Legal =>
            R.Message := To_Unbounded_String ("Ada 2022 expression type resolution is legal");
         when Resolution_Legal_With_Runtime_Check =>
            R.Message := To_Unbounded_String ("Ada 2022 expression type resolution is legal with required runtime check");
         when Resolution_Missing_AST_Coverage =>
            R.Message := To_Unbounded_String ("expression lacks complete parser/AST coverage");
         when Resolution_Missing_Expected_Type =>
            R.Message := To_Unbounded_String ("expression lacks expected type context");
         when Resolution_Missing_Operand_Type =>
            R.Message := To_Unbounded_String ("expression operand type is missing");
         when Resolution_Predicate_Not_Boolean =>
            R.Message := To_Unbounded_String ("quantified expression predicate does not resolve to Boolean");
         when Resolution_Reduction_Profile_Mismatch =>
            R.Message := To_Unbounded_String ("reduction combiner profile is not compatible with accumulator and element types");
         when Resolution_Reduction_Seed_Mismatch =>
            R.Message := To_Unbounded_String ("reduction initial value is not compatible with accumulator type");
         when Resolution_Delta_Base_Not_Composite =>
            R.Message := To_Unbounded_String ("delta aggregate base is not a composite type");
         when Resolution_Delta_Component_Mismatch =>
            R.Message := To_Unbounded_String ("delta aggregate component update is not compatible with the component type");
         when Resolution_Container_Element_Mismatch =>
            R.Message := To_Unbounded_String ("container aggregate element is not compatible with the container element type");
         when Resolution_Declare_Result_Mismatch =>
            R.Message := To_Unbounded_String ("declare expression result is not compatible with expected type");
         when Resolution_Target_Name_Outside_Update =>
            R.Message := To_Unbounded_String ("target-name @ appears outside an update context");
         when Resolution_Generalized_Indexing_Mismatch =>
            R.Message := To_Unbounded_String ("generalized indexing profile or result type is incompatible");
         when Resolution_Parallel_Loop_Shared_State_Blocker =>
            R.Message := To_Unbounded_String ("parallel loop has unsafe shared-state effects");
         when Resolution_Expected_Type_Mismatch =>
            R.Message := To_Unbounded_String ("resolved expression type is incompatible with expected type");
         when Resolution_Source_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("stale source fingerprint for expression type resolution");
         when Resolution_AST_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("stale AST fingerprint for expression type resolution");
         when Resolution_Multiple_Blockers =>
            R.Message := To_Unbounded_String ("multiple expression type-resolution blockers");
         when Resolution_Indeterminate | Resolution_Not_Checked =>
            R.Message := To_Unbounded_String ("expression type resolution is indeterminate");
      end case;
   end Add_Message;

   procedure Clear (Model : in out Expression_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Expression (Model : in out Expression_Model; Info : Expression_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Expression_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
   end Add_Expression;

   procedure Resolve_Kind (E : Expression_Info; R : in out Result_Info) is
   begin
      case E.Kind is
         when Expression_Quantified =>
            R.Resolved_Type := Type_Boolean;
            if E.Primary_Type /= Type_Iterator and then E.Primary_Type /= Type_Array
              and then E.Primary_Type /= Type_Container
            then
               R.Operand_Type_Blockers := R.Operand_Type_Blockers + 1;
            end if;
            if not E.Predicate_Result_Is_Boolean then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            end if;

         when Expression_Reduction =>
            R.Resolved_Type := E.Accumulator_Type;
            if not E.Reducer_Profile_Compatible then
               R.Reduction_Profile_Blockers := R.Reduction_Profile_Blockers + 1;
            end if;
            if not E.Reduction_Seed_Compatible
              or else not Type_Compatible (E.Secondary_Type, E.Accumulator_Type)
            then
               R.Reduction_Seed_Blockers := R.Reduction_Seed_Blockers + 1;
            end if;

         when Expression_Delta_Aggregate =>
            R.Resolved_Type := E.Primary_Type;
            if not Composite_Type (E.Primary_Type) then
               R.Delta_Base_Blockers := R.Delta_Base_Blockers + 1;
            end if;
            if not E.Delta_Component_Exists
              or else not E.Delta_Component_Compatible
            then
               R.Delta_Component_Blockers := R.Delta_Component_Blockers + 1;
            end if;

         when Expression_Container_Aggregate =>
            R.Resolved_Type := E.Expected_Type;
            if E.Expected_Type /= Type_Container then
               R.Expected_Result_Blockers := R.Expected_Result_Blockers + 1;
            end if;
            if not E.Container_Element_Compatible then
               R.Container_Element_Blockers := R.Container_Element_Blockers + 1;
            end if;

         when Expression_Declare =>
            R.Resolved_Type := E.Result_Type;
            if not E.Declare_Declarations_Elaborable
              or else not Type_Compatible (E.Result_Type, E.Expected_Type)
            then
               R.Declare_Result_Blockers := R.Declare_Result_Blockers + 1;
            end if;

         when Expression_Target_Name_Update =>
            R.Resolved_Type := E.Primary_Type;
            if not E.Target_Name_In_Update_Context then
               R.Target_Name_Blockers := R.Target_Name_Blockers + 1;
            end if;

         when Expression_Generalized_Indexing =>
            R.Resolved_Type := E.Result_Type;
            if not E.Generalized_Indexing_Profile_Compatible
              or else not Type_Compatible (E.Result_Type, E.Expected_Type)
            then
               R.Indexing_Blockers := R.Indexing_Blockers + 1;
            end if;

         when Expression_Parallel_Loop =>
            R.Resolved_Type := Type_Void;
            if not E.Parallel_Shared_State_Safe then
               R.Parallel_State_Blockers := R.Parallel_State_Blockers + 1;
            end if;

         when Expression_Unknown =>
            R.Resolved_Type := Type_Unknown;
      end case;
   end Resolve_Kind;

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
            R.Source_Fingerprint := E.Source_Fingerprint;
            R.AST_Fingerprint := E.AST_Fingerprint;

            if E.Id = No_Expression or else not E.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;
            if not E.Has_Expected_Type then
               R.Expected_Type_Blockers := R.Expected_Type_Blockers + 1;
            end if;
            if not E.Has_Primary_Operand_Type
              or else (E.Kind in Expression_Reduction | Expression_Generalized_Indexing
                       and then not E.Has_Secondary_Operand_Type)
            then
               R.Operand_Type_Blockers := R.Operand_Type_Blockers + 1;
            end if;

            Resolve_Kind (E, R);

            if E.Has_Result_Type
              and then E.Kind not in Expression_Parallel_Loop
              and then E.Expected_Type /= Type_Unknown
              and then R.Resolved_Type /= Type_Unknown
              and then not Type_Compatible (R.Resolved_Type, E.Expected_Type)
              and then E.Kind not in Expression_Quantified | Expression_Container_Aggregate
            then
               R.Expected_Result_Blockers := R.Expected_Result_Blockers + 1;
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

            R.Status := Status_For (R, E);
            if Blocker_Count (R) > 1 then
               R.Status := Resolution_Multiple_Blockers;
            elsif E.Kind = Expression_Unknown and then Blocker_Count (R) = 0 then
               R.Status := Resolution_Indeterminate;
            end if;

            Add_Message (R);
            R.Detail := To_Unbounded_String
              ("Ada 2022 expression type-resolution vertical slice for "
               & To_String (E.Source_Name));
            R.Fingerprint := Mix (Natural (Resolution_Status'Pos (R.Status)), Natural (E.Id));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Type_Class'Pos (R.Resolved_Type)));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

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

   function Count_Status (Model : Result_Model; Status : Resolution_Status) return Natural is
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
         if Is_Legal (R.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if not Is_Legal (R.Status)
           and then R.Status /= Resolution_Not_Checked
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
      return Info.Id /= No_Result and then Info.Status /= Resolution_Not_Checked;
   end Has_Result;

end Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality;
