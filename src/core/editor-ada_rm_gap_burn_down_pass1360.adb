package body Editor.Ada_RM_Gap_Burn_Down_Pass1360 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in
        Status_Gap_Burned_Down
        | Status_Legal_Complete_Source_Closure
        | Status_Runtime_Check_Evidence_Preserved
        | Status_Illegal_Complete_Evidence_Violation
        | Status_Illegal_Hard_Diagnostic_From_Incomplete_Source
        | Status_Illegal_Partial_Declaration_Treated_Complete
        | Status_Illegal_Partial_Body_Treated_Complete
        | Status_Illegal_Stale_Recovery_Result_Reused
        | Status_Illegal_Incomplete_Call_Diagnosed_Wrong_Overload
        | Status_Illegal_Incomplete_Aggregate_Diagnosed_Missing_Component
        | Status_Illegal_Partial_View_Treated_Definitive
        | Status_Illegal_Consumer_Hides_Indeterminate
        | Status_Illegal_Consumer_Independent_Name_Type_Resolution
        | Status_Illegal_Outline_Unstable_Partial_Symbol
        | Status_Illegal_Navigation_Invented_Target
        | Status_Illegal_Hover_Invented_Type
        | Status_Illegal_Colouring_Reinterprets_Name
        | Status_Illegal_Diagnostics_Missing_Blocker_Family
        | Status_Illegal_Diagnostic_Bridge_Conflates_Recovered_Source
        | Status_Indeterminate_Missing_Token
        | Status_Indeterminate_Degraded_Construct
        | Status_Indeterminate_Token_Only_Construct
        | Status_Indeterminate_Missing_Source_Span
        | Status_Indeterminate_Partial_Declaration
        | Status_Indeterminate_Partial_Body
        | Status_Indeterminate_Partial_Aggregate
        | Status_Indeterminate_Partial_Call
        | Status_Indeterminate_Partial_Expression
        | Status_Indeterminate_Partial_Context_Clause
        | Status_Indeterminate_Partial_Generic_Instantiation
        | Status_Indeterminate_Partial_Subunit_Stub
        | Status_Indeterminate_Private_View
        | Status_Indeterminate_Limited_View
        | Status_Indeterminate_Incomplete_View
        | Status_Indeterminate_Generic_Formal_View
        | Status_Indeterminate_Missing_Full_View
        | Status_Indeterminate_Missing_AST_Evidence
        | Status_Indeterminate_Missing_Type_Evidence
        | Status_Indeterminate_Missing_Profile_Evidence
        | Status_Indeterminate_Missing_Unit_Evidence
        | Status_Indeterminate_Missing_Substitution_Evidence
        | Status_Indeterminate_Missing_Effect_Evidence
        | Status_Indeterminate_Missing_Policy_Evidence
        | Status_Indeterminate_Missing_Consumer_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Complete_Source_Closure =>
            return Precision.Class_Legal;
         when Status_Runtime_Check_Evidence_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Complete_Evidence_Violation
            | Status_Illegal_Hard_Diagnostic_From_Incomplete_Source
            | Status_Illegal_Partial_Declaration_Treated_Complete
            | Status_Illegal_Partial_Body_Treated_Complete
            | Status_Illegal_Stale_Recovery_Result_Reused
            | Status_Illegal_Incomplete_Call_Diagnosed_Wrong_Overload
            | Status_Illegal_Incomplete_Aggregate_Diagnosed_Missing_Component
            | Status_Illegal_Partial_View_Treated_Definitive
            | Status_Illegal_Consumer_Hides_Indeterminate
            | Status_Illegal_Consumer_Independent_Name_Type_Resolution
            | Status_Illegal_Outline_Unstable_Partial_Symbol
            | Status_Illegal_Navigation_Invented_Target
            | Status_Illegal_Hover_Invented_Type
            | Status_Illegal_Colouring_Reinterprets_Name
            | Status_Illegal_Diagnostics_Missing_Blocker_Family
            | Status_Illegal_Diagnostic_Bridge_Conflates_Recovered_Source =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Missing_Token
            | Status_Indeterminate_Degraded_Construct
            | Status_Indeterminate_Token_Only_Construct
            | Status_Indeterminate_Missing_Source_Span
            | Status_Indeterminate_Partial_Declaration
            | Status_Indeterminate_Partial_Body
            | Status_Indeterminate_Partial_Aggregate
            | Status_Indeterminate_Partial_Call
            | Status_Indeterminate_Partial_Expression
            | Status_Indeterminate_Partial_Context_Clause
            | Status_Indeterminate_Partial_Generic_Instantiation
            | Status_Indeterminate_Partial_Subunit_Stub
            | Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_AST_Evidence
            | Status_Indeterminate_Missing_Type_Evidence
            | Status_Indeterminate_Missing_Profile_Evidence
            | Status_Indeterminate_Missing_Unit_Evidence
            | Status_Indeterminate_Missing_Substitution_Evidence
            | Status_Indeterminate_Missing_Effect_Evidence
            | Status_Indeterminate_Missing_Policy_Evidence
            | Status_Indeterminate_Missing_Consumer_Evidence
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when others =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Add_Blocker
     (Result : in out Burn_Down_Entry;
      Status : Burn_Down_Status) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

   procedure Check_Audit_Gates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Remediation_Entry_Present then
         Add_Blocker (Result, Status_Missing_Remediation_Evidence);
      end if;
      if not Row.Matrix_Coverage_Present then
         Add_Blocker (Result, Status_Missing_Matrix_Coverage);
      end if;
      if not Row.Implementing_Package_Present then
         Add_Blocker (Result, Status_Missing_Implementing_Package);
      end if;
      if not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      end if;
      if not Row.Coverage_Entry_Updated_To_Covered then
         Add_Blocker (Result, Status_Coverage_Not_Updated_To_Covered);
      end if;
      if not Row.Balanced_Regression_Evidence then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      end if;
      if not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      end if;
      if not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      end if;
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      end if;
      if not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Audit_Gates;

   procedure Check_Fingerprints
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Evidence_Stale then
         Add_Blocker (Result, Status_Stale_Recovery_Fingerprint);
      end if;
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
      if Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Add_Blocker (Result, Status_Unit_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Policy_Fingerprint /= Row.Expected_Policy_Fingerprint then
         Add_Blocker (Result, Status_Policy_Fingerprint_Mismatch);
      end if;
      if Row.Recovery_Fingerprint /= Row.Expected_Recovery_Fingerprint then
         Add_Blocker (Result, Status_Recovery_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Precision_Misuse
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Complete_Evidence_Violation then
         Add_Blocker (Result, Status_Illegal_Complete_Evidence_Violation);
      end if;
      if Row.Hard_Diagnostic_From_Incomplete_Evidence then
         Add_Blocker
           (Result, Status_Illegal_Hard_Diagnostic_From_Incomplete_Source);
      end if;
      if Row.Partial_Declaration_Treated_Complete then
         Add_Blocker
           (Result, Status_Illegal_Partial_Declaration_Treated_Complete);
      end if;
      if Row.Partial_Body_Treated_Complete then
         Add_Blocker (Result, Status_Illegal_Partial_Body_Treated_Complete);
      end if;
      if Row.Stale_Recovery_Result_Reused then
         Add_Blocker (Result, Status_Illegal_Stale_Recovery_Result_Reused);
      end if;
      if Row.Incomplete_Call_Diagnosed_Wrong_Overload then
         Add_Blocker
           (Result, Status_Illegal_Incomplete_Call_Diagnosed_Wrong_Overload);
      end if;
      if Row.Incomplete_Aggregate_Diagnosed_Missing_Component then
         Add_Blocker
           (Result,
            Status_Illegal_Incomplete_Aggregate_Diagnosed_Missing_Component);
      end if;
      if Row.Partial_View_Treated_Definitive then
         Add_Blocker (Result, Status_Illegal_Partial_View_Treated_Definitive);
      end if;
      if Row.Consumer_Hides_Indeterminate then
         Add_Blocker (Result, Status_Illegal_Consumer_Hides_Indeterminate);
      end if;
      if Row.Consumer_Independent_Name_Type_Resolution then
         Add_Blocker
           (Result,
            Status_Illegal_Consumer_Independent_Name_Type_Resolution);
      end if;
      if Row.Outline_Unstable_Partial_Symbol then
         Add_Blocker (Result, Status_Illegal_Outline_Unstable_Partial_Symbol);
      end if;
      if Row.Navigation_Invented_Target then
         Add_Blocker (Result, Status_Illegal_Navigation_Invented_Target);
      end if;
      if Row.Hover_Invented_Type then
         Add_Blocker (Result, Status_Illegal_Hover_Invented_Type);
      end if;
      if Row.Colouring_Reinterprets_Name then
         Add_Blocker (Result, Status_Illegal_Colouring_Reinterprets_Name);
      end if;
      if not Row.Diagnostics_Blocker_Family_Present then
         Add_Blocker (Result, Status_Illegal_Diagnostics_Missing_Blocker_Family);
      end if;
      if Row.Bridge_Conflates_Recovered_Source then
         Add_Blocker
           (Result,
            Status_Illegal_Diagnostic_Bridge_Conflates_Recovered_Source);
      end if;
   end Check_Precision_Misuse;

   procedure Check_Recovery_Indeterminates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Missing_Token then
         Add_Blocker (Result, Status_Indeterminate_Missing_Token);
      end if;
      if Row.Degraded_Construct then
         Add_Blocker (Result, Status_Indeterminate_Degraded_Construct);
      end if;
      if Row.Token_Only_Construct then
         Add_Blocker (Result, Status_Indeterminate_Token_Only_Construct);
      end if;
      if Row.Missing_Source_Span then
         Add_Blocker (Result, Status_Indeterminate_Missing_Source_Span);
      end if;
      if Row.Partial_Declaration then
         Add_Blocker (Result, Status_Indeterminate_Partial_Declaration);
      end if;
      if Row.Partial_Body then
         Add_Blocker (Result, Status_Indeterminate_Partial_Body);
      end if;
      if Row.Partial_Aggregate then
         Add_Blocker (Result, Status_Indeterminate_Partial_Aggregate);
      end if;
      if Row.Partial_Call then
         Add_Blocker (Result, Status_Indeterminate_Partial_Call);
      end if;
      if Row.Partial_Expression then
         Add_Blocker (Result, Status_Indeterminate_Partial_Expression);
      end if;
      if Row.Partial_Context_Clause then
         Add_Blocker (Result, Status_Indeterminate_Partial_Context_Clause);
      end if;
      if Row.Partial_Generic_Instantiation then
         Add_Blocker
           (Result, Status_Indeterminate_Partial_Generic_Instantiation);
      end if;
      if Row.Partial_Subunit_Stub then
         Add_Blocker (Result, Status_Indeterminate_Partial_Subunit_Stub);
      end if;
      if Row.Private_View then
         Add_Blocker (Result, Status_Indeterminate_Private_View);
      end if;
      if Row.Limited_View then
         Add_Blocker (Result, Status_Indeterminate_Limited_View);
      end if;
      if Row.Incomplete_View then
         Add_Blocker (Result, Status_Indeterminate_Incomplete_View);
      end if;
      if Row.Generic_Formal_View then
         Add_Blocker (Result, Status_Indeterminate_Generic_Formal_View);
      end if;
      if Row.Missing_Full_View then
         Add_Blocker (Result, Status_Indeterminate_Missing_Full_View);
      end if;
      if Row.Missing_AST_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_AST_Evidence);
      end if;
      if Row.Missing_Type_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Type_Evidence);
      end if;
      if Row.Missing_Profile_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Profile_Evidence);
      end if;
      if Row.Missing_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Unit_Evidence);
      end if;
      if Row.Missing_Substitution_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Substitution_Evidence);
      end if;
      if Row.Missing_Effect_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Effect_Evidence);
      end if;
      if Row.Missing_Policy_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Policy_Evidence);
      end if;
      if Row.Missing_Consumer_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Consumer_Evidence);
      end if;
   end Check_Recovery_Indeterminates;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Source_Kind := Row.Source_Kind;
      Result.Context := Row.Context;
      Result.Result_Fingerprint :=
        Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Recovered_Source_Kind'Pos (Row.Source_Kind))
        + Natural (Recovery_Context_Kind'Pos (Row.Context))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Unit_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Policy_Fingerprint
        + Row.Recovery_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Audit_Gates (Row, Result);
      Check_Fingerprints (Row, Result);
      Check_Precision_Misuse (Row, Result);
      Check_Recovery_Indeterminates (Row, Result);

      if Result.Status = Status_Not_Checked then
         if Row.Runtime_Check_Context then
            if Row.Runtime_Check_Evidence_Preserved then
               Result.Status := Status_Runtime_Check_Evidence_Preserved;
            else
               Result.Status := Status_Runtime_Check_Evidence_Lost;
            end if;
         elsif not Row.Complete_Source_Closure_Agrees then
            Result.Status := Status_Illegal_Complete_Evidence_Violation;
         else
            case Row.Expected is
               when Precision.Class_Legal =>
                  Result.Status := Status_Legal_Complete_Source_Closure;
               when Precision.Class_Legal_With_Runtime_Check =>
                  Result.Status := Status_Runtime_Check_Evidence_Lost;
               when Precision.Class_Illegal =>
                  Result.Status := Status_Unexpected_Classification;
               when Precision.Class_Indeterminate =>
                  Result.Status := Status_Indeterminate;
               when others =>
                  Result.Status := Status_Unexpected_Classification;
            end case;
         end if;
      end if;

      return Result;
   end Evaluate;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
      Item : Burn_Down_Entry;
      Classification : Precision_Classification;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := Evaluate (Row);
         Results.Entries.Append (Item);
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint
           + Natural (Burn_Down_Status'Pos (Item.Status))
           + Item.Blocker_Count;

         if Item.Source_Kind /= Source_Complete_Source then
            Results.Recovery_Row_Count := Results.Recovery_Row_Count + 1;
         end if;
         if Item.Consumer /= Consumers.Consumer_Unknown then
            Results.Consumer_Count := Results.Consumer_Count + 1;
         end if;

         Classification := Expected_For_Status (Item.Status);
         case Classification is
            when Precision.Class_Legal =>
               Results.Legal_Count := Results.Legal_Count + 1;
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Legal_With_Runtime_Check =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
         end case;
      end loop;
      return Results;
   end Build;

   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry is
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Partial_Source_Recovery_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Partial_Source_Recovery_Semantic_Closure then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap
        and then Results.Recovery_Row_Count > 0
        and then Results.Consumer_Count > 0
        and then Results.Indeterminate_Count > 0;
   end Partial_Source_Recovery_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1360;
