with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340 is

   procedure Add_Consumer_Row
     (Input : in out Consumer_Input;
      Row : Consumer_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Consumer_Row;

   function Count (Results : Consumer_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Consumer_Model; Index : Positive) return Consumer_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Consumer_Model; Consumer : Semantic_Consumer) return Consumer_Entry is
   begin
      for R of Results.Items loop
         if R.Consumer = Consumer then
            return R;
         end if;
      end loop;

      return
        (Consumer => Consumer,
         Family => Matrix.Family_Unknown,
         Slice => Matrix.Slice_Unknown,
         State => Remediation.State_Unknown,
         Status => Status_Not_Checked,
         Blocker_Count => 0,
         Entry_Fingerprint => 0);
   end Result_For;

   function Semantic_Consumer_Enforcement_Ready (Results : Consumer_Model) return Boolean is
   begin
      return Results.Total_Consumers > 0
        and then Results.Invalid_Count = 0
        and then Results.Blocked_Count = 0
        and then Results.Missing_Consumer_Count = 0
        and then Count (Results) >= Results.Total_Consumers;
   end Semantic_Consumer_Enforcement_Ready;

   function All_Completed_Results_Surfaceable (Results : Consumer_Model) return Boolean is
   begin
      return Semantic_Consumer_Enforcement_Ready (Results)
        and then Results.Ready_Count >= Results.Total_Consumers;
   end All_Completed_Results_Surfaceable;

   function Real_Consumer_Count return Natural is
      Total : Natural := 0;
   begin
      for C in Semantic_Consumer loop
         if C /= Consumer_Unknown then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Real_Consumer_Count;

   function Row_Count_For_Consumer
     (Input : Consumer_Input;
      Consumer : Semantic_Consumer) return Natural is
      Total : Natural := 0;
   begin
      for Row of Input.Rows loop
         if Row.Consumer = Consumer then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Row_Count_For_Consumer;

   procedure Add_Blocker
     (Result : in out Consumer_Entry;
      Status : Consumer_Status) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status in Status_Not_Checked | Status_Ready then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

   function Consumer_Requires_Blocker_Family (Row : Consumer_Row) return Boolean is
   begin
      return Row.Consumer = Consumer_Diagnostics
        or else Row.State in Remediation.State_Partial | Remediation.State_Blocked | Remediation.State_Missing;
   end Consumer_Requires_Blocker_Family;

   procedure Check_Fingerprints
     (Row : Consumer_Row;
      Result : in out Consumer_Entry) is
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

   procedure Check_Common_Consumer_Rules
     (Input : Consumer_Input;
      Row : Consumer_Row;
      Result : in out Consumer_Entry) is
   begin
      if Row_Count_For_Consumer (Input, Row.Consumer) > 1 then
         Add_Blocker (Result, Status_Duplicate_Consumer_Row);
      end if;

      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Missing_Source_Shaped_Evidence);
      end if;

      if not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Unconsumed_Semantic_Result);
      end if;

      if not Row.Canonical_Model_Used then
         Add_Blocker (Result, Status_Noncanonical_Consumer_Model);
      end if;

      if not Row.Stable_Source_Span then
         Add_Blocker (Result, Status_Unstable_Source_Span);
      end if;

      if Consumer_Requires_Blocker_Family (Row)
        and then not Row.Semantic_Blocker_Family_Present
      then
         Add_Blocker (Result, Status_Diagnostics_Missing_Blocker_Family);
      end if;

      if Consumer_Requires_Blocker_Family (Row)
        and then not Row.Stable_Blocker_Family
      then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;

      if Row.Consumer_Reinterprets_Names_Or_Types then
         Add_Blocker (Result, Status_Independent_Name_Type_Resolution);
      end if;

      if Row.State = Remediation.State_Covered
        and then not Row.Consumer_Can_Surface_Result
      then
         Add_Blocker (Result, Status_Covered_Result_Not_Surfaceable);
      end if;

      if Row.State in Remediation.State_Partial | Remediation.State_Blocked
        and then not Row.Partial_Or_Blocked_Represented
      then
         Add_Blocker (Result, Status_Partial_Or_Blocked_Result_Hidden);
      end if;

      if not Row.Runtime_Check_Evidence_Preserved then
         Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
      end if;
   end Check_Common_Consumer_Rules;

   procedure Check_Consumer_Specific_Rules
     (Row : Consumer_Row;
      Result : in out Consumer_Entry) is
   begin
      case Row.Consumer is
         when Consumer_Diagnostics =>
            null;

         when Consumer_Semantic_Colouring =>
            if not Row.Uses_Canonical_Entity_Identity
              or else not Row.Uses_Canonical_Type_Identity
              or else not Row.Uses_Canonical_View_Identity
            then
               Add_Blocker (Result, Status_Noncanonical_Type_View_Profile);
            end if;

         when Consumer_Outline_Model =>
            if not Row.Uses_Canonical_Declaration_Identity
              or else not Row.Uses_Canonical_Completion_Identity
            then
               Add_Blocker (Result, Status_Noncanonical_Declaration_Or_Completion);
            end if;

         when Consumer_Semantic_Navigation =>
            if not Row.Uses_Canonical_Entity_Identity
              or else not Row.Uses_Canonical_Renaming_Identity
            then
               Add_Blocker (Result, Status_Navigation_Entity_Model_Mismatch);
            end if;

            if not Row.Uses_Generic_Substitution_Identity then
               Add_Blocker (Result, Status_Noncanonical_Generic_Substitution);
            end if;

            if not Row.Uses_Cross_Unit_Evidence then
               Add_Blocker (Result, Status_Missing_Cross_Unit_Evidence);
            end if;

         when Consumer_Hover_Details =>
            if not Row.Hover_Detail_From_Canonical_Evidence then
               Add_Blocker (Result, Status_Hover_Uses_Slice_Local_Evidence);
            end if;

            if not Row.Uses_Canonical_Type_Identity
              or else not Row.Uses_Canonical_View_Identity
              or else not Row.Uses_Canonical_Profile_Identity
            then
               Add_Blocker (Result, Status_Noncanonical_Type_View_Profile);
            end if;

         when Consumer_Build_Diagnostic_Bridge =>
            if not Row.Build_Diagnostics_Distinct_From_Internal then
               Add_Blocker (Result, Status_Build_Diagnostic_Bridge_Conflates_External);
            end if;

            if not Row.Build_Diagnostic_Shares_Source_Span then
               Add_Blocker (Result, Status_Unstable_Source_Span);
            end if;

         when Consumer_Unknown =>
            Add_Blocker (Result, Status_Indeterminate);
      end case;
   end Check_Consumer_Specific_Rules;

   procedure Check_Row
     (Input : Consumer_Input;
      Row : Consumer_Row;
      Result : in out Consumer_Entry) is
   begin
      Result.Entry_Fingerprint :=
        Result.Entry_Fingerprint
        + Row.Id
        + Semantic_Consumer'Pos (Row.Consumer)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Slice)
        + Remediation.Remediation_State'Pos (Row.State)
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Common_Consumer_Rules (Input, Row, Result);
      Check_Consumer_Specific_Rules (Row, Result);
      Check_Fingerprints (Row, Result);
   end Check_Row;

   procedure Count_Result
     (Results : in out Consumer_Model;
      Result : Consumer_Entry) is
   begin
      case Result.Status is
         when Status_Ready =>
            Results.Ready_Count := Results.Ready_Count + 1;
         when Status_Missing_Consumer_Row =>
            Results.Missing_Consumer_Count := Results.Missing_Consumer_Count + 1;
            Results.Invalid_Count := Results.Invalid_Count + 1;
         when Status_Not_Checked =>
            Results.Invalid_Count := Results.Invalid_Count + 1;
         when others =>
            Results.Blocked_Count := Results.Blocked_Count + 1;
            Results.Invalid_Count := Results.Invalid_Count + 1;
      end case;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Result.Blocker_Count
        + Consumer_Status'Pos (Result.Status);
   end Count_Result;

   function Missing_Consumer_Entry (Consumer : Semantic_Consumer) return Consumer_Entry is
   begin
      return
        (Consumer => Consumer,
         Family => Matrix.Family_Diagnostics_Consumer_Readiness,
         Slice => Matrix.Slice_Unknown,
         State => Remediation.State_Unknown,
         Status => Status_Missing_Consumer_Row,
         Blocker_Count => 1,
         Entry_Fingerprint => 1_340_900 + Semantic_Consumer'Pos (Consumer));
   end Missing_Consumer_Entry;

   function Build (Input : Consumer_Input) return Consumer_Model is
      Results : Consumer_Model;
   begin
      Results.Total_Consumers := Real_Consumer_Count;

      for Row of Input.Rows loop
         declare
            Result : Consumer_Entry :=
              (Consumer => Row.Consumer,
               Family => Row.Family,
               Slice => Row.Slice,
               State => Row.State,
               Status => Status_Ready,
               Blocker_Count => 0,
               Entry_Fingerprint => 1_340_000 + Row.Id);
         begin
            Check_Row (Input, Row, Result);
            Count_Result (Results, Result);
            Results.Items.Append (Result);
         end;
      end loop;

      for Consumer in Semantic_Consumer loop
         if Consumer /= Consumer_Unknown
           and then Row_Count_For_Consumer (Input, Consumer) = 0
         then
            declare
               Result : constant Consumer_Entry := Missing_Consumer_Entry (Consumer);
            begin
               Count_Result (Results, Result);
               Results.Items.Append (Result);
            end;
         end if;
      end loop;

      return Results;
   end Build;

end Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
