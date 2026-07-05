package body Editor.Ada_Semantic_Regression_Corpus_Balance_Audit is

   pragma Suppress (Overflow_Check);
   use type Matrix.RM_Family;
   use type Matrix.Implementing_Slice;
   use type Remediation.Remediation_State;
   use type Precision.Precision_Classification;


   procedure Add_Corpus_Row
     (Input : in out Corpus_Input;
      Row : Corpus_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Corpus_Row;

   function Count (Results : Corpus_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Corpus_Model; Index : Positive) return Corpus_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Corpus_Model; Family : RM_Family) return Corpus_Entry is
   begin
      for R of Results.Items loop
         if R.Family = Family then
            return R;
         end if;
      end loop;

      return
        (Family => Family,
         Slice => Matrix.Slice_Unknown,
         State => Remediation.State_Unknown,
         Group => Group_Unknown,
         Status => Status_Not_Checked,
         Row_Count => 0,
         Blocker_Count => 0,
         Has_Legal => False,
         Has_Illegal => False,
         Has_Runtime_Check => False,
         Has_Indeterminate => False,
         Has_Consumer_Surfaced => False,
         Runtime_Check_Required => False,
         Indeterminate_Required => False,
         Entry_Fingerprint => 0);
   end Result_For;

   function Semantic_Regression_Corpus_Balanced (Results : Corpus_Model) return Boolean is
   begin
      return Count (Results) > 0
        and then Results.Invalid_Count = 0
        and then Results.Balanced_Count = Count (Results)
        and then Results.Legal_Scenario_Count > 0
        and then Results.Illegal_Scenario_Count > 0
        and then Results.Runtime_Check_Scenario_Count > 0
        and then Results.Indeterminate_Scenario_Count > 0
        and then Results.Consumer_Surfaced_Scenario_Count > 0;
   end Semantic_Regression_Corpus_Balanced;

   function Balanced_For_All_Covered_Families (Results : Corpus_Model) return Boolean is
   begin
      return Semantic_Regression_Corpus_Balanced (Results)
        and then Results.Total_Families = Count (Results);
   end Balanced_For_All_Covered_Families;

   procedure Add_Blocker
     (Result : in out Corpus_Entry;
      Status : Corpus_Status;
      Slice : Implementing_Slice) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status in Status_Not_Checked | Status_Balanced then
         Result.Status := Status;
         if Result.Slice = Matrix.Slice_Unknown then
            Result.Slice := Slice;
         end if;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
         if Result.Slice = Matrix.Slice_Unknown then
            Result.Slice := Slice;
         end if;
      end if;
   end Add_Blocker;

   procedure Check_Fingerprints
     (Row : Corpus_Row;
      Result : in out Corpus_Entry) is
   begin
      if Row.Evidence_Stale
        or else Row.Corpus_Fingerprint /= Row.Expected_Corpus_Fingerprint
      then
         Add_Blocker (Result, Status_Stale_Corpus_Fingerprint, Row.Slice);
      end if;

      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch, Row.Slice);
      end if;
      if Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch, Row.Slice);
      end if;
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch, Row.Slice);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch, Row.Slice);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch, Row.Slice);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch, Row.Slice);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch, Row.Slice);
      end if;
   end Check_Fingerprints;

   procedure Mark_Scenario
     (Row : Corpus_Row;
      Result : in out Corpus_Entry) is
   begin
      case Row.Scenario is
         when Scenario_Legal =>
            Result.Has_Legal := True;
         when Scenario_Illegal =>
            Result.Has_Illegal := True;
         when Scenario_Legal_With_Runtime_Check =>
            Result.Has_Runtime_Check := True;
         when Scenario_Indeterminate =>
            Result.Has_Indeterminate := True;
         when Scenario_Consumer_Surfaced =>
            Result.Has_Consumer_Surfaced := True;
         when Scenario_Unknown =>
            Add_Blocker (Result, Status_Indeterminate, Row.Slice);
      end case;

      if Row.Runtime_Check_Applicable then
         Result.Runtime_Check_Required := True;
      end if;
      if Row.Indeterminate_Applicable then
         Result.Indeterminate_Required := True;
      end if;
   end Mark_Scenario;

   procedure Check_Row
     (Row : Corpus_Row;
      Result : in out Corpus_Entry) is
   begin
      Result.Row_Count := Result.Row_Count + 1;

      if Result.Slice = Matrix.Slice_Unknown then
         Result.Slice := Row.Slice;
      end if;
      if Result.State = Remediation.State_Unknown then
         Result.State := Row.State;
      end if;
      if Result.Group = Group_Unknown then
         Result.Group := Row.Group;
      end if;

      Result.Entry_Fingerprint :=
        Result.Entry_Fingerprint
        + Row.Id
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Slice)
        + Remediation.Remediation_State'Pos (Row.State)
        + Corpus_Group'Pos (Row.Group)
        + Corpus_Scenario'Pos (Row.Scenario)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Precision.Precision_Classification'Pos (Row.Actual)
        + Row.Corpus_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      Mark_Scenario (Row, Result);

      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing, Row.Slice);
      end if;

      if not Row.Adds_Rule_Coverage then
         Add_Blocker (Result, Status_Duplicate_Noncoverage_Row, Row.Slice);
      end if;

      if Row.Scenario = Scenario_Consumer_Surfaced
        and then not Row.Semantic_Consumer_Reached
      then
         Add_Blocker (Result, Status_Semantic_Consumer_Not_Reached, Row.Slice);
      end if;

      if Row.Scenario = Scenario_Legal_With_Runtime_Check then
         if Row.Runtime_Check_Collapsed_To_Illegal
           or else Row.Actual = Precision.Class_Illegal
         then
            Add_Blocker (Result, Status_Runtime_Check_Collapsed_To_Illegal, Row.Slice);
         end if;

         if not Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost, Row.Slice);
         end if;
      end if;

      if Row.Scenario = Scenario_Indeterminate then
         if Row.Indeterminate_Collapsed_To_Legal
           or else Row.Actual = Precision.Class_Legal
         then
            Add_Blocker (Result, Status_Indeterminate_Collapsed_To_Legal, Row.Slice);
         end if;

         if Row.Indeterminate_Collapsed_To_Illegal
           or else Row.Actual = Precision.Class_Illegal
         then
            Add_Blocker (Result, Status_Indeterminate_Collapsed_To_Illegal, Row.Slice);
         end if;
      end if;

      if Row.Scenario = Scenario_Illegal
        and then not Row.Stable_Blocker_Family
      then
         Add_Blocker (Result, Status_Unstable_Blocker_Family, Row.Slice);
      end if;

      Check_Fingerprints (Row, Result);
   end Check_Row;

   procedure Finalize_Result (Result : in out Corpus_Entry) is
   begin
      if Result.Row_Count = 0 then
         Add_Blocker (Result, Status_Missing_Covered_Family, Matrix.Slice_Unknown);
      elsif Result.State = Remediation.State_Partial then
         Add_Blocker (Result, Status_Partial_Coverage_Treated_As_Balanced, Result.Slice);
      elsif Result.State = Remediation.State_Missing then
         Add_Blocker (Result, Status_Missing_Checker_Treated_As_Balanced, Result.Slice);
      elsif Result.State /= Remediation.State_Covered then
         Add_Blocker (Result, Status_Indeterminate, Result.Slice);
      elsif Result.Blocker_Count = 0 then
         if Result.Has_Legal and then not Result.Has_Illegal then
            Add_Blocker (Result, Status_Only_Positive_Tests, Result.Slice);
         elsif Result.Has_Illegal and then not Result.Has_Legal then
            Add_Blocker (Result, Status_Only_Negative_Tests, Result.Slice);
         elsif not Result.Has_Legal then
            Add_Blocker (Result, Status_Missing_Legal_Scenario, Result.Slice);
         elsif not Result.Has_Illegal then
            Add_Blocker (Result, Status_Missing_Illegal_Scenario, Result.Slice);
         elsif Result.Runtime_Check_Required and then not Result.Has_Runtime_Check then
            Add_Blocker (Result, Status_Missing_Runtime_Check_Scenario, Result.Slice);
         elsif Result.Indeterminate_Required and then not Result.Has_Indeterminate then
            Add_Blocker (Result, Status_Missing_Indeterminate_Scenario, Result.Slice);
         elsif not Result.Has_Consumer_Surfaced then
            Add_Blocker (Result, Status_Missing_Consumer_Surfaced_Scenario, Result.Slice);
         else
            Result.Status := Status_Balanced;
         end if;
      end if;
   end Finalize_Result;

   procedure Count_Result
     (Results : in out Corpus_Model;
      Result : Corpus_Entry) is
   begin
      if Result.Has_Legal then
         Results.Legal_Scenario_Count := Results.Legal_Scenario_Count + 1;
      end if;
      if Result.Has_Illegal then
         Results.Illegal_Scenario_Count := Results.Illegal_Scenario_Count + 1;
      end if;
      if Result.Has_Runtime_Check then
         Results.Runtime_Check_Scenario_Count := Results.Runtime_Check_Scenario_Count + 1;
      end if;
      if Result.Has_Indeterminate then
         Results.Indeterminate_Scenario_Count := Results.Indeterminate_Scenario_Count + 1;
      end if;
      if Result.Has_Consumer_Surfaced then
         Results.Consumer_Surfaced_Scenario_Count := Results.Consumer_Surfaced_Scenario_Count + 1;
      end if;

      case Result.Status is
         when Status_Balanced =>
            Results.Balanced_Count := Results.Balanced_Count + 1;
         when others =>
            Results.Invalid_Count := Results.Invalid_Count + 1;
      end case;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Result.Blocker_Count
        + Corpus_Status'Pos (Result.Status);
   end Count_Result;

   function Build (Input : Corpus_Input) return Corpus_Model is
      Results : Corpus_Model;
   begin
      for F in Matrix.RM_Family loop
         if F /= Matrix.Family_Unknown then
            declare
               R : Corpus_Entry :=
                 (Family => F,
                  Slice => Matrix.Slice_Unknown,
                  State => Remediation.State_Unknown,
                  Group => Group_Unknown,
                  Status => Status_Not_Checked,
                  Row_Count => 0,
                  Blocker_Count => 0,
                  Has_Legal => False,
                  Has_Illegal => False,
                  Has_Runtime_Check => False,
                  Has_Indeterminate => False,
                  Has_Consumer_Surfaced => False,
                  Runtime_Check_Required => False,
                  Indeterminate_Required => False,
                  Entry_Fingerprint => 1_342_000 + Matrix.RM_Family'Pos (F));
            begin
               for Row of Input.Rows loop
                  if Row.Family = F then
                     Check_Row (Row, R);
                  end if;
               end loop;

               if R.Row_Count > 0 then
                  Finalize_Result (R);
                  Results.Items.Append (R);
                  Results.Total_Families := Results.Total_Families + 1;
                  Count_Result (Results, R);
               end if;
            end;
         end if;
      end loop;

      return Results;
   end Build;

end Editor.Ada_Semantic_Regression_Corpus_Balance_Audit;
