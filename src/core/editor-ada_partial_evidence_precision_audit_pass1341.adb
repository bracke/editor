package body Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341 is

   pragma Suppress (Overflow_Check);

   procedure Add_Precision_Row
     (Input : in out Precision_Input;
      Row : Precision_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Precision_Row;

   function Count (Results : Precision_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Precision_Model; Index : Positive) return Precision_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Precision_Model; Area : Precision_Area) return Precision_Entry is
   begin
      for R of Results.Items loop
         if R.Area = Area then
            return R;
         end if;
      end loop;

      return
        (Area => Area,
         Family => Matrix.Family_Unknown,
         Slice => Matrix.Slice_Unknown,
         Consumer => Consumers.Consumer_Unknown,
         Expected => Class_Unknown,
         Actual => Class_Unknown,
         Status => Status_Not_Checked,
         Blocker_Count => 0,
         Entry_Fingerprint => 0);
   end Result_For;

   function Partial_Evidence_Precision_Ready (Results : Precision_Model) return Boolean is
   begin
      return Count (Results) > 0
        and then Results.Invalid_Count = 0
        and then Results.Ready_Count = Count (Results);
   end Partial_Evidence_Precision_Ready;

   function False_Positive_False_Negative_Hardened (Results : Precision_Model) return Boolean is
   begin
      return Partial_Evidence_Precision_Ready (Results)
        and then Results.Legal_Count > 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Indeterminate_Count > 0
        and then Results.Partial_Coverage_Count > 0
        and then Results.Missing_Checker_Count > 0;
   end False_Positive_False_Negative_Hardened;

   procedure Add_Blocker
     (Result : in out Precision_Entry;
      Status : Precision_Status) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status in Status_Not_Checked | Status_Ready then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

   function Evidence_Complete (Row : Precision_Row) return Boolean is
   begin
      return Row.Source_Shaped_Evidence
        and then Row.Required_Source_AST_Evidence_Complete
        and then Row.Required_Type_Profile_Evidence_Complete
        and then Row.Required_View_Cross_Unit_Evidence_Complete
        and then Row.Required_Flow_Effect_Evidence_Complete
        and then Row.Required_Representation_Freezing_Evidence_Complete
        and then not Row.Evidence_Stale
        and then Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.AST_Fingerprint = Row.Expected_AST_Fingerprint
        and then Row.Type_Fingerprint = Row.Expected_Type_Fingerprint
        and then Row.Profile_Fingerprint = Row.Expected_Profile_Fingerprint
        and then Row.Substitution_Fingerprint = Row.Expected_Substitution_Fingerprint
        and then Row.Effect_Fingerprint = Row.Expected_Effect_Fingerprint
        and then Row.Consumer_Fingerprint = Row.Expected_Consumer_Fingerprint;
   end Evidence_Complete;

   function Classification_Is_Authoritative (Class : Precision_Classification) return Boolean is
   begin
      return Class in Class_Legal | Class_Illegal | Class_Legal_With_Runtime_Check;
   end Classification_Is_Authoritative;

   function Classification_Is_Blocker_State (Class : Precision_Classification) return Boolean is
   begin
      return Class in Class_Indeterminate | Class_Partial_Coverage | Class_Missing_Checker;
   end Classification_Is_Blocker_State;

   procedure Check_Fingerprints
     (Row : Precision_Row;
      Result : in out Precision_Entry) is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      end if;
      if Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      end if;
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Incomplete_Evidence
     (Row : Precision_Row;
      Result : in out Precision_Entry) is
      Treats_Incomplete_As_Authoritative : constant Boolean :=
        Row.Hard_Diagnostic_Emitted
        or else Classification_Is_Authoritative (Row.Actual)
        or else not Row.Consumer_Represents_Blocker_State;
   begin
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Missing_Source_Shaped_Evidence);
      end if;

      if Treats_Incomplete_As_Authoritative then
         if not Row.Required_Source_AST_Evidence_Complete then
            Add_Blocker (Result, Status_Source_AST_Evidence_Incomplete);
         end if;
         if not Row.Required_Type_Profile_Evidence_Complete then
            Add_Blocker (Result, Status_Type_Profile_Evidence_Incomplete);
         end if;
         if not Row.Required_View_Cross_Unit_Evidence_Complete then
            Add_Blocker (Result, Status_View_Cross_Unit_Evidence_Incomplete);
         end if;
         if not Row.Required_Flow_Effect_Evidence_Complete then
            Add_Blocker (Result, Status_Flow_Effect_Evidence_Incomplete);
         end if;
         if not Row.Required_Representation_Freezing_Evidence_Complete then
            Add_Blocker (Result, Status_Representation_Freezing_Evidence_Incomplete);
         end if;
      end if;
   end Check_Incomplete_Evidence;

   procedure Check_Precision_Rules
     (Row : Precision_Row;
      Result : in out Precision_Entry) is
      Complete : constant Boolean := Evidence_Complete (Row);
   begin
      if Row.Evidence_Stale and then Row.Authoritative_Result_Used then
         Add_Blocker (Result, Status_Stale_Evidence_Treated_As_Authoritative);
      end if;

      if Row.Hard_Diagnostic_Emitted
        and then not Row.Semantic_Blocker_Family_Present
      then
         Add_Blocker (Result, Status_Diagnostic_Missing_Blocker_Family);
      end if;

      if Row.Hard_Diagnostic_Emitted
        and then (not Complete)
        and then Row.Expected /= Class_Illegal
      then
         Add_Blocker (Result, Status_Hard_Diagnostic_From_Incomplete_Evidence);
      end if;

      case Row.Expected is
         when Class_Legal =>
            if Row.Actual = Class_Illegal or else Row.Hard_Diagnostic_Emitted then
               Add_Blocker (Result, Status_Legal_Case_Diagnosed);
            end if;

         when Class_Illegal =>
            if Complete and then Row.Actual /= Class_Illegal then
               Add_Blocker (Result, Status_Complete_Evidence_Violation_Not_Diagnosed);
            end if;

         when Class_Legal_With_Runtime_Check =>
            if Row.Actual = Class_Illegal or else Row.Hard_Diagnostic_Emitted then
               Add_Blocker (Result, Status_Runtime_Check_Marked_Illegal);
            end if;
            if not Row.Runtime_Check_Evidence_Preserved then
               Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
            end if;

         when Class_Indeterminate =>
            if Row.Actual = Class_Legal then
               Add_Blocker (Result, Status_Indeterminate_Treated_As_Legal);
            elsif Row.Actual = Class_Illegal or else Row.Hard_Diagnostic_Emitted then
               Add_Blocker (Result, Status_Indeterminate_Treated_As_Illegal);
            end if;

         when Class_Partial_Coverage =>
            if Row.Actual in Class_Legal | Class_Illegal | Class_Legal_With_Runtime_Check then
               Add_Blocker (Result, Status_Partial_Coverage_Treated_As_Complete);
            end if;
            if not Row.Partial_Coverage_Represented then
               Add_Blocker (Result, Status_Consumer_Hides_Blocker_State);
            end if;

         when Class_Missing_Checker =>
            if Row.Actual in Class_Legal | Class_Illegal | Class_Legal_With_Runtime_Check then
               Add_Blocker (Result, Status_Missing_Checker_Treated_As_Complete);
            end if;
            if not Row.Missing_Checker_Represented then
               Add_Blocker (Result, Status_Consumer_Hides_Blocker_State);
            end if;

         when Class_Unknown =>
            Add_Blocker (Result, Status_Indeterminate);
      end case;

      if Classification_Is_Blocker_State (Row.Actual)
        and then not Row.Consumer_Represents_Blocker_State
      then
         Add_Blocker (Result, Status_Consumer_Hides_Blocker_State);
      end if;

      if (not Complete)
        and then Classification_Is_Authoritative (Row.Actual)
        and then Row.Expected not in Class_Legal | Class_Illegal | Class_Legal_With_Runtime_Check
      then
         Add_Blocker (Result, Status_Hard_Diagnostic_From_Incomplete_Evidence);
      end if;
   end Check_Precision_Rules;

   procedure Check_Row
     (Row : Precision_Row;
      Result : in out Precision_Entry) is
   begin
      Result.Entry_Fingerprint :=
        Result.Entry_Fingerprint
        + Row.Id
        + Precision_Area'Pos (Row.Area)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Slice)
        + Remediation.Remediation_State'Pos (Row.State)
        + Consumers.Semantic_Consumer'Pos (Row.Consumer)
        + Precision_Classification'Pos (Row.Expected)
        + Precision_Classification'Pos (Row.Actual)
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Incomplete_Evidence (Row, Result);
      Check_Precision_Rules (Row, Result);
      Check_Fingerprints (Row, Result);
   end Check_Row;

   procedure Count_Result
     (Results : in out Precision_Model;
      Row : Precision_Row;
      Result : Precision_Entry) is
   begin
      if Result.Status = Status_Ready then
         Results.Ready_Count := Results.Ready_Count + 1;
      else
         Results.Invalid_Count := Results.Invalid_Count + 1;
      end if;

      case Row.Actual is
         when Class_Legal =>
            Results.Legal_Count := Results.Legal_Count + 1;
         when Class_Illegal =>
            Results.Illegal_Count := Results.Illegal_Count + 1;
         when Class_Legal_With_Runtime_Check =>
            Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
         when Class_Indeterminate =>
            Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
         when Class_Partial_Coverage =>
            Results.Partial_Coverage_Count := Results.Partial_Coverage_Count + 1;
         when Class_Missing_Checker =>
            Results.Missing_Checker_Count := Results.Missing_Checker_Count + 1;
         when Class_Unknown =>
            null;
      end case;

      if Row.Hard_Diagnostic_Emitted then
         Results.Hard_Diagnostic_Count := Results.Hard_Diagnostic_Count + 1;
      end if;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Result.Blocker_Count
        + Precision_Status'Pos (Result.Status);
   end Count_Result;

   function Build (Input : Precision_Input) return Precision_Model is
      Results : Precision_Model;
   begin
      for Row of Input.Rows loop
         declare
            Result : Precision_Entry :=
              (Area => Row.Area,
               Family => Row.Family,
               Slice => Row.Slice,
               Consumer => Row.Consumer,
               Expected => Row.Expected,
               Actual => Row.Actual,
               Status => Status_Ready,
               Blocker_Count => 0,
               Entry_Fingerprint => 1_341_000 + Row.Id);
         begin
            Check_Row (Row, Result);
            Count_Result (Results, Row, Result);
            Results.Items.Append (Result);
         end;
      end loop;

      return Results;
   end Build;

end Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
