package body Editor.Ada_Semantic_Integration_Audit_Pass1335 is

   pragma Suppress (Overflow_Check);

   procedure Add_Slice (Model : in out Slice_Model; Slice : Slice_Info) is
   begin
      Model.Items.Append (Slice);
   end Add_Slice;

   procedure Add_Check (Model : in out Check_Model; Check : Scenario_Check) is
   begin
      Model.Items.Append (Check);
   end Add_Check;

   function Count (Results : Result_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Result_Model; Index : Positive) return Audit_Result is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Integration_Ready (Results : Result_Model) return Boolean is
   begin
      return Results.Blocked_Count = 0 and then Results.Ready_Count = Count (Results);
   end Integration_Ready;

   function Find_Slice
     (Slices : Slice_Model;
      Family : Slice_Family;
      Found : out Boolean) return Slice_Info
   is
      Empty : Slice_Info;
   begin
      for S of Slices.Items loop
         if S.Family = Family then
            Found := True;
            return S;
         end if;
      end loop;
      Found := False;
      return Empty;
   end Find_Slice;

   procedure Add_Blocker
     (Status : in out Audit_Status;
      Count : in out Natural;
      Candidate : Audit_Status;
      Slice : Slice_Family;
      Blocking_Slice : in out Slice_Family) is
   begin
      if Candidate /= Audit_Ready then
         Count := Count + 1;
         if Status = Audit_Ready then
            Status := Candidate;
            Blocking_Slice := Slice;
         elsif Status /= Candidate then
            Status := Audit_Multiple_Blockers;
            if Blocking_Slice = Slice_Unknown then
               Blocking_Slice := Slice;
            end if;
         end if;
      end if;
   end Add_Blocker;

   procedure Check_Fingerprint
     (Actual : Natural;
      Expected : Natural;
      Candidate : Audit_Status;
      Status : in out Audit_Status;
      Count : in out Natural;
      Slice : Slice_Family;
      Blocking_Slice : in out Slice_Family) is
   begin
      if Actual /= Expected then
         Add_Blocker (Status, Count, Candidate, Slice, Blocking_Slice);
      end if;
   end Check_Fingerprint;

   function Requires_Family (Check : Scenario_Check; Family : Slice_Family) return Boolean is
   begin
      case Family is
         when Slice_Aggregate =>
            return Check.Requires_Aggregate;
         when Slice_Assignment_Conversion =>
            return Check.Requires_Assignment_Conversion;
         when Slice_Iterator_Loop_Parallel =>
            return Check.Requires_Iterator_Loop_Parallel;
         when Slice_Contract_Aspect =>
            return Check.Requires_Contract_Aspect;
         when Slice_Context_Clause_With_Use =>
            return Check.Requires_Context_Clause_With_Use;
         when Slice_Library_Unit_Subunit =>
            return Check.Requires_Library_Unit_Subunit;
         when Slice_Interface_Synchronized =>
            return Check.Requires_Interface_Synchronized;
         when Slice_Interfacing_Import_Export =>
            return Check.Requires_Interfacing_Import_Export;
         when Slice_Flow_Refinement =>
            return Check.Requires_Flow_Refinement;
         when Slice_Callable_Profile =>
            return Check.Requires_Callable_Profile;
         when Slice_Unknown =>
            return False;
      end case;
   end Requires_Family;

   procedure Check_Slice
     (Slices : Slice_Model;
      Check : Scenario_Check;
      Family : Slice_Family;
      Status : in out Audit_Status;
      Count : in out Natural;
      Blocking_Slice : in out Slice_Family;
      Evidence_Fingerprint : in out Natural) is
      Found : Boolean := False;
      S : constant Slice_Info := Find_Slice (Slices, Family, Found);
   begin
      if not Requires_Family (Check, Family) then
         return;
      end if;

      if (not Found) or else (not S.Present) then
         Add_Blocker (Status, Count, Audit_Missing_Slice, Family, Blocking_Slice);
         return;
      end if;

      Evidence_Fingerprint :=
        Evidence_Fingerprint
        + S.Source_Fingerprint
        + S.AST_Fingerprint
        + S.Type_Fingerprint
        + S.Profile_Fingerprint
        + S.Substitution_Fingerprint
        + S.Effect_Fingerprint
        + Slice_Family'Pos (Family) + 1;

      if Check.Source_Shaped and then not S.Source_Shaped then
         Add_Blocker (Status, Count, Audit_Scenario_Not_Source_Shaped, Family, Blocking_Slice);
      end if;

      if Check.Requires_Source_Evidence and then not S.Has_Source_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Source_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_AST_Evidence and then not S.Has_AST_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_AST_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Type_Evidence and then not S.Has_Type_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Type_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Profile_Evidence and then not S.Has_Profile_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Profile_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_View_Evidence and then not S.Has_View_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_View_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Overload_Evidence and then not S.Has_Overload_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Overload_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Freezing_Evidence and then not S.Has_Freezing_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Freezing_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Generic_Substitution_Evidence
        and then not S.Has_Generic_Substitution_Evidence
      then
         Add_Blocker
           (Status, Count, Audit_Missing_Generic_Substitution_Evidence,
            Family, Blocking_Slice);
      end if;
      if Check.Requires_Cross_Unit_Evidence and then not S.Has_Cross_Unit_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Cross_Unit_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Flow_Effect_Evidence and then not S.Has_Flow_Effect_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Flow_Effect_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Representation_Evidence and then not S.Has_Representation_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Representation_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Runtime_Check_Evidence and then not S.Has_Runtime_Check_Evidence then
         Add_Blocker (Status, Count, Audit_Missing_Runtime_Check_Evidence, Family, Blocking_Slice);
      end if;
      if Check.Requires_Consumer and then not S.Consumed_By_Semantic_Path then
         Add_Blocker (Status, Count, Audit_Unconsumed_Semantic_Result, Family, Blocking_Slice);
      end if;
      if Check.Requires_Canonical_Agreement and then not S.Agrees_With_Canonical_Model then
         Add_Blocker (Status, Count, Audit_Slice_Model_Disagreement, Family, Blocking_Slice);
      end if;

      Check_Fingerprint
        (S.Source_Fingerprint, S.Expected_Source_Fingerprint,
         Audit_Source_Fingerprint_Mismatch, Status, Count, Family, Blocking_Slice);
      Check_Fingerprint
        (S.AST_Fingerprint, S.Expected_AST_Fingerprint,
         Audit_AST_Fingerprint_Mismatch, Status, Count, Family, Blocking_Slice);
      Check_Fingerprint
        (S.Type_Fingerprint, S.Expected_Type_Fingerprint,
         Audit_Type_Fingerprint_Mismatch, Status, Count, Family, Blocking_Slice);
      Check_Fingerprint
        (S.Profile_Fingerprint, S.Expected_Profile_Fingerprint,
         Audit_Profile_Fingerprint_Mismatch, Status, Count, Family, Blocking_Slice);
      Check_Fingerprint
        (S.Substitution_Fingerprint, S.Expected_Substitution_Fingerprint,
         Audit_Substitution_Fingerprint_Mismatch, Status, Count, Family, Blocking_Slice);
      Check_Fingerprint
        (S.Effect_Fingerprint, S.Expected_Effect_Fingerprint,
         Audit_Effect_Fingerprint_Mismatch, Status, Count, Family, Blocking_Slice);
   end Check_Slice;

   function Build (Slices : Slice_Model; Checks : Check_Model) return Result_Model is
      Results : Result_Model;
   begin
      for C of Checks.Items loop
         declare
            R : Audit_Result;
         begin
            R.Id := C.Id;
            R.Kind := C.Kind;
            R.Name := C.Name;
            R.Node := C.Node;
            R.Status := Audit_Ready;
            R.Blocking_Slice := Slice_Unknown;
            R.Blocker_Count := 0;
            R.Evidence_Fingerprint := C.Id + Scenario_Kind'Pos (C.Kind) + 1;

            if not C.Source_Shaped then
               Add_Blocker
                 (R.Status, R.Blocker_Count, Audit_Scenario_Not_Source_Shaped,
                  Slice_Unknown, R.Blocking_Slice);
            end if;

            Check_Slice (Slices, C, Slice_Aggregate,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Assignment_Conversion,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Iterator_Loop_Parallel,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Contract_Aspect,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Context_Clause_With_Use,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Library_Unit_Subunit,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Interface_Synchronized,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Interfacing_Import_Export,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Flow_Refinement,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);
            Check_Slice (Slices, C, Slice_Callable_Profile,
                         R.Status, R.Blocker_Count, R.Blocking_Slice,
                         R.Evidence_Fingerprint);

            if R.Status = Audit_Ready then
               Results.Ready_Count := Results.Ready_Count + 1;
            else
               Results.Blocked_Count := Results.Blocked_Count + 1;
            end if;

            Results.Result_Fingerprint :=
              Results.Result_Fingerprint
              + R.Evidence_Fingerprint
              + R.Blocker_Count
              + Audit_Status'Pos (R.Status) + 1;
            Results.Items.Append (R);
         end;
      end loop;

      return Results;
   end Build;

end Editor.Ada_Semantic_Integration_Audit_Pass1335;
