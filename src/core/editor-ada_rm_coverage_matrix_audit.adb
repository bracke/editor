package body Editor.Ada_RM_Coverage_Matrix_Audit is

   pragma Suppress (Overflow_Check);

   procedure Add_Coverage_Claim (Matrix : in out Coverage_Matrix; Claim : Coverage_Claim) is
   begin
      Matrix.Claims.Append (Claim);
   end Add_Coverage_Claim;

   procedure Add_Slice_Result (Matrix : in out Coverage_Matrix; Result : Slice_Result) is
   begin
      Matrix.Slices.Append (Result);
   end Add_Slice_Result;

   function Count (Results : Audit_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Audit_Model; Index : Positive) return Audit_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Audit_Model; Family : RM_Family) return Audit_Entry is
   begin
      for R of Results.Items loop
         if R.Family = Family then
            return R;
         end if;
      end loop;
      return (Family => Family,
              Slice => Slice_Unknown,
              Status => Status_Not_Checked,
              Level => Coverage_Unknown,
              Claim_Count => 0,
              Blocker_Count => 0,
              Entry_Fingerprint => 0);
   end Result_For;

   function RM_Coverage_Audit_Ready (Results : Audit_Model) return Boolean is
   begin
      return Results.Total_Families > 0
        and then Results.Covered_Count = Results.Total_Families
        and then Results.Partial_Count = 0
        and then Results.Blocked_Count = 0
        and then Results.Unclaimed_Slice_Count = 0;
   end RM_Coverage_Audit_Ready;

   function Real_Family_Count return Natural is
      Total : Natural := 0;
   begin
      for F in RM_Family loop
         if F /= Family_Unknown then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Real_Family_Count;

   procedure Add_Blocker
     (Result : in out Audit_Entry;
      Status : Audit_Status;
      Slice : Implementing_Slice) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status in Status_Not_Checked | Status_Covered | Status_Partial then
         Result.Status := Status;
         if Result.Slice = Slice_Unknown then
            Result.Slice := Slice;
         end if;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
         if Result.Slice = Slice_Unknown then
            Result.Slice := Slice;
         end if;
      end if;
   end Add_Blocker;

   function Has_Present_Slice
     (Matrix : Coverage_Matrix;
      Slice : Implementing_Slice) return Boolean is
   begin
      if Slice = Slice_Unknown then
         return False;
      end if;

      for S of Matrix.Slices loop
         if S.Slice = Slice and then S.Present then
            return S.Result_Fingerprint = S.Expected_Result_Fingerprint;
         end if;
      end loop;
      return False;
   end Has_Present_Slice;

   function Claim_Count_For
     (Matrix : Coverage_Matrix;
      Family : RM_Family;
      Slice : Implementing_Slice) return Natural is
      Total : Natural := 0;
   begin
      for C of Matrix.Claims loop
         if C.Family = Family and then C.Slice = Slice then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Claim_Count_For;

   function Has_Claim_For_Slice
     (Matrix : Coverage_Matrix;
      Slice : Implementing_Slice) return Boolean is
   begin
      for C of Matrix.Claims loop
         if C.Slice = Slice then
            return True;
         end if;
      end loop;
      return False;
   end Has_Claim_For_Slice;

   function Has_Conflicting_Level
     (Matrix : Coverage_Matrix;
      Family : RM_Family;
      Level : Coverage_Level) return Boolean is
   begin
      for C of Matrix.Claims loop
         if C.Family = Family then
            if (Level = Coverage_Covered and then C.Level in Coverage_None | Coverage_Blocked)
              or else (Level in Coverage_None | Coverage_Blocked and then C.Level = Coverage_Covered)
            then
               return True;
            end if;
         end if;
      end loop;
      return False;
   end Has_Conflicting_Level;

   procedure Check_Fingerprints
     (Claim : Coverage_Claim;
      Result : in out Audit_Entry) is
   begin
      if Claim.Source_Fingerprint /= Claim.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch, Claim.Slice);
      end if;
      if Claim.AST_Fingerprint /= Claim.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch, Claim.Slice);
      end if;
      if Claim.Type_Fingerprint /= Claim.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch, Claim.Slice);
      end if;
      if Claim.Profile_Fingerprint /= Claim.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch, Claim.Slice);
      end if;
      if Claim.Substitution_Fingerprint /= Claim.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch, Claim.Slice);
      end if;
      if Claim.Effect_Fingerprint /= Claim.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch, Claim.Slice);
      end if;
   end Check_Fingerprints;

   procedure Check_Claim
     (Matrix : Coverage_Matrix;
      Claim : Coverage_Claim;
      Result : in out Audit_Entry) is
   begin
      Result.Claim_Count := Result.Claim_Count + 1;
      Result.Entry_Fingerprint :=
        Result.Entry_Fingerprint
        + Claim.Id
        + RM_Family'Pos (Claim.Family)
        + Implementing_Slice'Pos (Claim.Slice)
        + Coverage_Level'Pos (Claim.Level)
        + Claim.Source_Fingerprint
        + Claim.AST_Fingerprint
        + Claim.Type_Fingerprint
        + Claim.Profile_Fingerprint
        + Claim.Substitution_Fingerprint
        + Claim.Effect_Fingerprint;

      if Claim.Level = Coverage_Covered then
         Result.Level := Coverage_Covered;
      elsif Result.Level /= Coverage_Covered and then Claim.Level = Coverage_Partial then
         Result.Level := Coverage_Partial;
      elsif Result.Level = Coverage_Unknown then
         Result.Level := Claim.Level;
      end if;

      if Claim.Level in Coverage_Covered | Coverage_Partial then
         if not Has_Present_Slice (Matrix, Claim.Slice) then
            Add_Blocker (Result, Status_Missing_Implementing_Slice, Claim.Slice);
         end if;
      end if;

      if Claim_Count_For (Matrix, Claim.Family, Claim.Slice) > 1 then
         Add_Blocker (Result, Status_Duplicate_Coverage_Claim, Claim.Slice);
      end if;

      if Claim.Conflicts_With_Existing_Claim
        or else Has_Conflicting_Level (Matrix, Claim.Family, Claim.Level)
      then
         Add_Blocker (Result, Status_Conflicting_Coverage_Claim, Claim.Slice);
      end if;

      if Claim.Level = Coverage_Covered and then not Claim.Source_Shaped_Test_Present then
         Add_Blocker (Result, Status_Missing_Source_Shaped_Test, Claim.Slice);
      end if;

      if Claim.Level in Coverage_Covered | Coverage_Partial
        and then not Claim.Semantic_Result_Consumed
      then
         Add_Blocker (Result, Status_Unconsumed_Semantic_Result, Claim.Slice);
      end if;

      if Claim.Level in Coverage_Covered | Coverage_Partial
        and then (not Claim.Concrete_Rule_Family_Evidence
                  or else Claim.Claims_Generic_Compiler_Grade)
      then
         Add_Blocker (Result, Status_Generic_Compiler_Grade_Claim, Claim.Slice);
      end if;

      Check_Fingerprints (Claim, Result);
   end Check_Claim;

   procedure Finalize_Family_Result (Result : in out Audit_Entry) is
   begin
      if Result.Claim_Count = 0 then
         Add_Blocker (Result, Status_Not_Covered, Slice_Unknown);
      elsif Result.Level in Coverage_None | Coverage_Blocked | Coverage_Unknown then
         Add_Blocker (Result, Status_Not_Covered, Result.Slice);
      elsif Result.Blocker_Count = 0 then
         case Result.Level is
            when Coverage_Covered =>
               Result.Status := Status_Covered;
            when Coverage_Partial =>
               Result.Status := Status_Partial;
            when others =>
               Result.Status := Status_Not_Covered;
         end case;
      end if;
   end Finalize_Family_Result;

   function Build (Matrix : Coverage_Matrix) return Audit_Model is
      Results : Audit_Model;
   begin
      Results.Total_Families := Real_Family_Count;

      for F in RM_Family loop
         if F /= Family_Unknown then
            declare
               R : Audit_Entry :=
                 (Family => F,
                  Slice => Slice_Unknown,
                  Status => Status_Not_Checked,
                  Level => Coverage_Unknown,
                  Claim_Count => 0,
                  Blocker_Count => 0,
                  Entry_Fingerprint => RM_Family'Pos (F) + 1_338_000);
            begin
               for C of Matrix.Claims loop
                  if C.Family = F then
                     if R.Slice = Slice_Unknown then
                        R.Slice := C.Slice;
                     end if;
                     Check_Claim (Matrix, C, R);
                  end if;
               end loop;

               Finalize_Family_Result (R);

               if R.Status = Status_Covered then
                  Results.Covered_Count := Results.Covered_Count + 1;
               elsif R.Status = Status_Partial then
                  Results.Partial_Count := Results.Partial_Count + 1;
               else
                  Results.Blocked_Count := Results.Blocked_Count + 1;
               end if;

               Results.Audit_Fingerprint :=
                 Results.Audit_Fingerprint + R.Entry_Fingerprint + R.Blocker_Count;
               Results.Items.Append (R);
            end;
         end if;
      end loop;

      for S of Matrix.Slices loop
         if S.Present and then S.Slice /= Slice_Unknown and then not Has_Claim_For_Slice (Matrix, S.Slice) then
            declare
               R : Audit_Entry :=
                 (Family => Family_Unknown,
                  Slice => S.Slice,
                  Status => Status_Slice_Unclaimed,
                  Level => Coverage_Unknown,
                  Claim_Count => 0,
                  Blocker_Count => 1,
                  Entry_Fingerprint =>
                    1_338_500
                    + Implementing_Slice'Pos (S.Slice)
                    + S.Result_Fingerprint
                    + S.Expected_Result_Fingerprint);
            begin
               Results.Unclaimed_Slice_Count := Results.Unclaimed_Slice_Count + 1;
               Results.Blocked_Count := Results.Blocked_Count + 1;
               Results.Audit_Fingerprint := Results.Audit_Fingerprint + R.Entry_Fingerprint;
               Results.Items.Append (R);
            end;
         end if;
      end loop;

      return Results;
   end Build;

end Editor.Ada_RM_Coverage_Matrix_Audit;
