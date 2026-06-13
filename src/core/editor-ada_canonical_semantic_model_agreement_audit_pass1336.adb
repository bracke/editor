package body Editor.Ada_Canonical_Semantic_Model_Agreement_Audit_Pass1336 is

   procedure Add_Binding (Model : in out Canonical_Model; Binding : Canonical_Binding) is
   begin
      Model.Bindings.Append (Binding);
   end Add_Binding;

   procedure Add_Check (Model : in out Check_Model; Check : Scenario_Check) is
   begin
      Model.Items.Append (Check);
   end Add_Check;

   function Count (Results : Result_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Result_Model; Index : Positive) return Agreement_Result is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Canonical_Model_Agrees (Results : Result_Model) return Boolean is
   begin
      return Results.Blocked_Count = 0 and then Results.Ready_Count = Count (Results);
   end Canonical_Model_Agrees;

   procedure Add_Blocker
     (Result : in out Agreement_Result;
      Status : Agreement_Status;
      Slice : Slice_Family;
      Dimension : Agreement_Dimension) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status = Agreement_Ready then
         Result.Status := Status;
         Result.Blocking_Slice := Slice;
         Result.Dimension := Dimension;
      elsif Result.Status /= Status then
         Result.Status := Agreement_Multiple_Blockers;
         if Result.Blocking_Slice = Slice_Unknown then
            Result.Blocking_Slice := Slice;
         end if;
         if Result.Dimension = Dimension_Unknown then
            Result.Dimension := Dimension;
         end if;
      end if;
   end Add_Blocker;

   function Requires (Check : Scenario_Check; Dimension : Agreement_Dimension) return Boolean is
   begin
      case Dimension is
         when Dimension_Entity =>
            return Check.Requires_Entity;
         when Dimension_Type =>
            return Check.Requires_Type;
         when Dimension_View =>
            return Check.Requires_View;
         when Dimension_Profile =>
            return Check.Requires_Profile;
         when Dimension_Generic_Substitution =>
            return Check.Requires_Generic_Substitution;
         when Dimension_Unit =>
            return Check.Requires_Unit;
         when Dimension_Representation_Freezing =>
            return Check.Requires_Representation_Freezing;
         when Dimension_Flow_Effect =>
            return Check.Requires_Flow_Effect;
         when Dimension_Overload_Set =>
            return Check.Requires_Overload_Set;
         when Dimension_Runtime_Check =>
            return Check.Requires_Runtime_Check;
         when Dimension_Unknown =>
            return False;
      end case;
   end Requires;

   function Has_Required_Binding
     (Model : Canonical_Model;
      Scenario_Id : Natural;
      Dimension : Agreement_Dimension) return Boolean
   is
   begin
      for B of Model.Bindings loop
         if B.Scenario_Id = Scenario_Id and then B.Dimension = Dimension then
            return True;
         end if;
      end loop;
      return False;
   end Has_Required_Binding;

   procedure Check_Common_Evidence
     (Binding : Canonical_Binding;
      Result : in out Agreement_Result) is
   begin
      if not Binding.Source_Shaped then
         Add_Blocker
           (Result, Agreement_Scenario_Not_Source_Shaped,
            Binding.Slice, Binding.Dimension);
      end if;
      if not Binding.Has_Source_Evidence then
         Add_Blocker
           (Result, Agreement_Missing_Source_Evidence,
            Binding.Slice, Binding.Dimension);
      end if;
      if not Binding.Has_AST_Evidence then
         Add_Blocker
           (Result, Agreement_Missing_AST_Evidence,
            Binding.Slice, Binding.Dimension);
      end if;
      if not Binding.Consumed_By_Semantic_Path then
         Add_Blocker
           (Result, Agreement_Unconsumed_By_Semantic_Path,
            Binding.Slice, Binding.Dimension);
      end if;
      if Binding.Source_Fingerprint /= Binding.Expected_Source_Fingerprint then
         Add_Blocker
           (Result, Agreement_Source_Fingerprint_Mismatch,
            Binding.Slice, Binding.Dimension);
      end if;
      if Binding.AST_Fingerprint /= Binding.Expected_AST_Fingerprint then
         Add_Blocker
           (Result, Agreement_AST_Fingerprint_Mismatch,
            Binding.Slice, Binding.Dimension);
      end if;
      if Binding.Model_Fingerprint /= Binding.Expected_Model_Fingerprint then
         Add_Blocker
           (Result, Agreement_Model_Fingerprint_Mismatch,
            Binding.Slice, Binding.Dimension);
      end if;
   end Check_Common_Evidence;

   procedure Check_Dimension
     (Binding : Canonical_Binding;
      Result : in out Agreement_Result) is
   begin
      Check_Common_Evidence (Binding, Result);

      if Binding.Canonical_Id = 0 then
         Add_Blocker
           (Result, Agreement_Missing_Canonical_Identity,
            Binding.Slice, Binding.Dimension);
      elsif Binding.Canonical_Id /= Binding.Slice_Local_Id then
         Add_Blocker
           (Result, Agreement_Slice_Local_Identity_Mismatch,
            Binding.Slice, Binding.Dimension);
      end if;

      case Binding.Dimension is
         when Dimension_View =>
            if Binding.Canonical_View /= Binding.Slice_View then
               Add_Blocker
                 (Result, Agreement_View_Class_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Profile =>
            if Binding.Canonical_Profile_Id /= Binding.Slice_Profile_Id then
               Add_Blocker
                 (Result, Agreement_Profile_Model_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Generic_Substitution =>
            if Binding.Canonical_Substitution_Id /= Binding.Slice_Substitution_Id then
               Add_Blocker
                 (Result, Agreement_Generic_Substitution_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Unit =>
            if Binding.Canonical_Unit_Id /= Binding.Slice_Unit_Id then
               Add_Blocker
                 (Result, Agreement_Unit_Completion_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Representation_Freezing =>
            if Binding.Canonical_Representation_Id /= Binding.Slice_Representation_Id then
               Add_Blocker
                 (Result, Agreement_Representation_Freezing_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Flow_Effect =>
            if Binding.Canonical_Flow_Effect_Id /= Binding.Slice_Flow_Effect_Id then
               Add_Blocker
                 (Result, Agreement_Flow_Effect_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Overload_Set =>
            if Binding.Canonical_Overload_Set_Id /= Binding.Slice_Overload_Set_Id then
               Add_Blocker
                 (Result, Agreement_Overload_Set_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when Dimension_Runtime_Check =>
            if Binding.Canonical_Runtime_Check_Id /= Binding.Slice_Runtime_Check_Id then
               Add_Blocker
                 (Result, Agreement_Runtime_Check_Mismatch,
                  Binding.Slice, Binding.Dimension);
            end if;
         when others =>
            null;
      end case;
   end Check_Dimension;

   procedure Check_Missing_Dimensions
     (Model : Canonical_Model;
      Check : Scenario_Check;
      Result : in out Agreement_Result) is
   begin
      for D in Agreement_Dimension loop
         if D /= Dimension_Unknown
           and then Requires (Check, D)
           and then not Has_Required_Binding (Model, Check.Id, D)
         then
            Add_Blocker (Result, Agreement_Missing_Binding, Slice_Unknown, D);
         end if;
      end loop;
   end Check_Missing_Dimensions;

   function Build (Model : Canonical_Model; Checks : Check_Model) return Result_Model is
      Results : Result_Model;
   begin
      for C of Checks.Items loop
         declare
            R : Agreement_Result;
         begin
            R.Id := C.Id;
            R.Kind := C.Kind;
            R.Name := C.Name;
            R.Node := C.Node;
            R.Status := Agreement_Ready;
            R.Blocking_Slice := Slice_Unknown;
            R.Dimension := Dimension_Unknown;
            R.Agreement_Fingerprint := C.Id + Scenario_Kind'Pos (C.Kind) + 1;

            if not C.Source_Shaped then
               Add_Blocker
                 (R, Agreement_Scenario_Not_Source_Shaped,
                  Slice_Unknown, Dimension_Unknown);
            end if;

            Check_Missing_Dimensions (Model, C, R);

            for B of Model.Bindings loop
               if B.Scenario_Id = C.Id and then Requires (C, B.Dimension) then
                  Check_Dimension (B, R);
                  R.Agreement_Fingerprint :=
                    R.Agreement_Fingerprint
                    + B.Canonical_Id
                    + B.Slice_Local_Id
                    + Agreement_Dimension'Pos (B.Dimension)
                    + Slice_Family'Pos (B.Slice);
               end if;
            end loop;

            if R.Blocker_Count = 0 then
               Results.Ready_Count := Results.Ready_Count + 1;
            else
               Results.Blocked_Count := Results.Blocked_Count + 1;
            end if;

            Results.Result_Fingerprint :=
              Results.Result_Fingerprint + R.Agreement_Fingerprint + R.Blocker_Count;
            Results.Items.Append (R);
         end;
      end loop;
      return Results;
   end Build;

end Editor.Ada_Canonical_Semantic_Model_Agreement_Audit_Pass1336;
