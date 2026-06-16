package body Editor.Ada_RM_Gap_Burn_Down_Pass1352 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At
     (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry is
   begin
      if Index > Count (Results) then
         return (others => <>);
      end if;
      return Results.Entries.Element (Natural (Index - 1));
   end Result_At;

   function Result_For
     (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry is
   begin
      for Feed_Item of Results.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Warning_Restriction_Preserved
                     | Status_Runtime_Assertion_Check_Preserved
                     | Status_Runtime_Suppressed_Check_Preserved
                     | Status_Illegal_Configuration_Pragma_Placement
                     | Status_Illegal_Configuration_Pragma_Target
                     | Status_Illegal_Duplicate_Configuration_Pragma
                     | Status_Illegal_Conflicting_Configuration_Pragma
                     | Status_Illegal_Unknown_Restriction
                     | Status_Illegal_Hard_Restriction_Violation
                     | Status_Illegal_Restriction_Warning_Treated_As_Hard_Error
                     | Status_Illegal_Categorization_Conflict
                     | Status_Illegal_Dependency_Category
                     | Status_Illegal_Body_Spec_Category_Disagreement
                     | Status_Illegal_Pure_Restriction_Violation
                     | Status_Illegal_Preelaborate_Restriction_Violation
                     | Status_Illegal_Remote_Types_Category_Violation
                     | Status_Illegal_Shared_Passive_Category_Violation
                     | Status_Illegal_Remote_Call_Interface_Category_Violation
                     | Status_Illegal_Suppress_Unsuppress_Placement
                     | Status_Illegal_Assert_Expression_Not_Boolean
                     | Status_Illegal_Unknown_Assertion_Policy
                     | Status_Illegal_Pack_Target
                     | Status_Illegal_Inline_No_Inline_Target
                     | Status_Illegal_Import_Export_Convention_Disagreement
                     | Status_Illegal_No_Return_Flow_Disagreement
                     | Status_Illegal_Volatile_Atomic_Independent_Disagreement
                     | Status_Illegal_Task_Restriction_Not_Consumed
                     | Status_Illegal_Access_Allocation_Restriction_Not_Consumed
                     | Status_Illegal_Exception_Finalization_Restriction_Not_Consumed
                     | Status_Illegal_Local_Slice_Ignores_Configuration_Policy
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Configuration_Evidence
                     | Status_Indeterminate_Missing_Categorization_Evidence
                     | Status_Indeterminate_Missing_Restriction_Evidence
                     | Status_Indeterminate_Missing_Policy_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down
            | Status_Gap_Burned_Down
            | Status_Warning_Restriction_Preserved =>
            return Precision.Class_Legal;
         when Status_Illegal_Configuration_Pragma_Placement
            | Status_Illegal_Configuration_Pragma_Target
            | Status_Illegal_Duplicate_Configuration_Pragma
            | Status_Illegal_Conflicting_Configuration_Pragma
            | Status_Illegal_Unknown_Restriction
            | Status_Illegal_Hard_Restriction_Violation
            | Status_Illegal_Restriction_Warning_Treated_As_Hard_Error
            | Status_Illegal_Categorization_Conflict
            | Status_Illegal_Dependency_Category
            | Status_Illegal_Body_Spec_Category_Disagreement
            | Status_Illegal_Pure_Restriction_Violation
            | Status_Illegal_Preelaborate_Restriction_Violation
            | Status_Illegal_Remote_Types_Category_Violation
            | Status_Illegal_Shared_Passive_Category_Violation
            | Status_Illegal_Remote_Call_Interface_Category_Violation
            | Status_Illegal_Suppress_Unsuppress_Placement
            | Status_Illegal_Assert_Expression_Not_Boolean
            | Status_Illegal_Unknown_Assertion_Policy
            | Status_Illegal_Pack_Target
            | Status_Illegal_Inline_No_Inline_Target
            | Status_Illegal_Import_Export_Convention_Disagreement
            | Status_Illegal_No_Return_Flow_Disagreement
            | Status_Illegal_Volatile_Atomic_Independent_Disagreement
            | Status_Illegal_Task_Restriction_Not_Consumed
            | Status_Illegal_Access_Allocation_Restriction_Not_Consumed
            | Status_Illegal_Exception_Finalization_Restriction_Not_Consumed
            | Status_Illegal_Local_Slice_Ignores_Configuration_Policy =>
            return Precision.Class_Illegal;
         when Status_Runtime_Assertion_Check_Preserved
            | Status_Runtime_Suppressed_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Configuration_Evidence
            | Status_Indeterminate_Missing_Categorization_Evidence
            | Status_Indeterminate_Missing_Restriction_Evidence
            | Status_Indeterminate_Missing_Policy_Evidence
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

   procedure Check_Fingerprints
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Evidence_Stale
        or else Row.Burn_Down_Fingerprint /= Row.Expected_Burn_Down_Fingerprint
      then
         Add_Blocker (Result, Status_Stale_Burn_Down_Fingerprint);
      end if;
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      end if;
      if Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      end if;
      if Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Add_Blocker (Result, Status_Unit_Fingerprint_Mismatch);
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
      if Row.Policy_Fingerprint /= Row.Expected_Policy_Fingerprint then
         Add_Blocker (Result, Status_Policy_Fingerprint_Mismatch);
      end if;
      if Row.Category_Fingerprint /= Row.Expected_Category_Fingerprint then
         Add_Blocker (Result, Status_Category_Fingerprint_Mismatch);
      end if;
      if Row.Restriction_Fingerprint /= Row.Expected_Restriction_Fingerprint then
         Add_Blocker (Result, Status_Restriction_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Audit_Gates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      elsif not Row.Remediation_Entry_Present then
         Add_Blocker (Result, Status_Missing_Remediation_Evidence);
      elsif not Row.Matrix_Coverage_Present then
         Add_Blocker (Result, Status_Missing_Matrix_Coverage);
      elsif not Row.Implementing_Package_Present then
         Add_Blocker (Result, Status_Missing_Implementing_Package);
      elsif not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      elsif not Row.Coverage_Entry_Updated_To_Covered then
         Add_Blocker (Result, Status_Coverage_Not_Updated_To_Covered);
      elsif not Row.Balanced_Regression_Evidence then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      elsif not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      elsif not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      elsif not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Audit_Gates;

   procedure Check_Indeterminate_Evidence
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Private_View then
         Add_Blocker (Result, Status_Indeterminate_Private_View);
      elsif Row.Limited_View then
         Add_Blocker (Result, Status_Indeterminate_Limited_View);
      elsif Row.Incomplete_View then
         Add_Blocker (Result, Status_Indeterminate_Incomplete_View);
      elsif Row.Generic_Formal_View then
         Add_Blocker (Result, Status_Indeterminate_Generic_Formal_View);
      elsif Row.Missing_Full_View then
         Add_Blocker (Result, Status_Indeterminate_Missing_Full_View);
      elsif Row.Missing_Cross_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      elsif Row.Missing_Configuration_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Configuration_Evidence);
      elsif Row.Missing_Categorization_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Categorization_Evidence);
      elsif Row.Missing_Restriction_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Restriction_Evidence);
      elsif Row.Missing_Policy_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Policy_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Pragma_Policy_Rules
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Configuration_Placement_OK then
         Add_Blocker (Result, Status_Illegal_Configuration_Pragma_Placement);
      elsif not Row.Configuration_Target_OK then
         Add_Blocker (Result, Status_Illegal_Configuration_Pragma_Target);
      elsif Row.Duplicate_Configuration_Pragma then
         Add_Blocker (Result, Status_Illegal_Duplicate_Configuration_Pragma);
      elsif Row.Conflicting_Configuration_Pragma then
         Add_Blocker (Result, Status_Illegal_Conflicting_Configuration_Pragma);
      elsif not Row.Restriction_Rule_Known then
         Add_Blocker (Result, Status_Illegal_Unknown_Restriction);
      elsif Row.Restriction_Warning_Treated_As_Hard_Error then
         Add_Blocker
           (Result, Status_Illegal_Restriction_Warning_Treated_As_Hard_Error);
      elsif Row.Hard_Restriction_Violation then
         Add_Blocker (Result, Status_Illegal_Hard_Restriction_Violation);
      elsif Row.Categorization_Conflict then
         Add_Blocker (Result, Status_Illegal_Categorization_Conflict);
      elsif not Row.Dependency_Category_Legal then
         Add_Blocker (Result, Status_Illegal_Dependency_Category);
      elsif not Row.Body_Spec_Category_Agrees then
         Add_Blocker (Result, Status_Illegal_Body_Spec_Category_Disagreement);
      elsif not Row.Pure_Restrictions_Hold then
         Add_Blocker (Result, Status_Illegal_Pure_Restriction_Violation);
      elsif not Row.Preelaborate_Restrictions_Hold then
         Add_Blocker (Result, Status_Illegal_Preelaborate_Restriction_Violation);
      elsif not Row.Remote_Types_Category_Legal then
         Add_Blocker (Result, Status_Illegal_Remote_Types_Category_Violation);
      elsif not Row.Shared_Passive_Category_Legal then
         Add_Blocker (Result, Status_Illegal_Shared_Passive_Category_Violation);
      elsif not Row.Remote_Call_Interface_Category_Legal then
         Add_Blocker
           (Result, Status_Illegal_Remote_Call_Interface_Category_Violation);
      elsif not Row.Suppress_Unsuppress_Placement_OK then
         Add_Blocker (Result, Status_Illegal_Suppress_Unsuppress_Placement);
      elsif not Row.Assert_Expression_Boolean then
         Add_Blocker (Result, Status_Illegal_Assert_Expression_Not_Boolean);
      elsif not Row.Assertion_Policy_Known then
         Add_Blocker (Result, Status_Illegal_Unknown_Assertion_Policy);
      elsif not Row.Pack_Target_OK then
         Add_Blocker (Result, Status_Illegal_Pack_Target);
      elsif not Row.Inline_No_Inline_Target_OK then
         Add_Blocker (Result, Status_Illegal_Inline_No_Inline_Target);
      elsif not Row.Import_Export_Convention_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Import_Export_Convention_Disagreement);
      elsif not Row.No_Return_Flow_Agrees then
         Add_Blocker (Result, Status_Illegal_No_Return_Flow_Disagreement);
      elsif not Row.Volatile_Atomic_Independent_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Volatile_Atomic_Independent_Disagreement);
      elsif not Row.Tasking_Consumes_Restrictions then
         Add_Blocker (Result, Status_Illegal_Task_Restriction_Not_Consumed);
      elsif not Row.Access_Allocation_Consumes_Restrictions then
         Add_Blocker
           (Result, Status_Illegal_Access_Allocation_Restriction_Not_Consumed);
      elsif not Row.Exception_Finalization_Consumes_Restrictions then
         Add_Blocker
           (Result,
            Status_Illegal_Exception_Finalization_Restriction_Not_Consumed);
      elsif not Row.Elaboration_Consumes_Categorization
        or else not Row.Local_Slices_Consume_Configuration_Policy
      then
         Add_Blocker
           (Result, Status_Illegal_Local_Slice_Ignores_Configuration_Policy);
      end if;
   end Check_Pragma_Policy_Rules;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Configuration_Agrees then
         Add_Blocker (Result, Status_Consumer_Configuration_Model_Disagreement);
      elsif not Row.Consumer_Restriction_Agrees then
         Add_Blocker (Result, Status_Consumer_Restriction_Model_Disagreement);
      elsif not Row.Consumer_Categorization_Agrees then
         Add_Blocker
           (Result, Status_Consumer_Categorization_Model_Disagreement);
      elsif not Row.Consumer_Assertion_Agrees then
         Add_Blocker (Result, Status_Consumer_Assertion_Model_Disagreement);
      elsif not Row.Consumer_Warning_State_Surface then
         Add_Blocker (Result, Status_Consumer_Warning_State_Hidden);
      elsif not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Consumer_Diagnostic_Bridge_Disagreement);
      end if;
   end Check_Consumers;

   procedure Add_Success_Or_Runtime_Status
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Result.Status /= Status_Not_Checked then
         return;
      end if;

      if Row.Restriction_Warning_Violation then
         if Row.Restriction_Warning_Preserved then
            Add_Blocker (Result, Status_Warning_Restriction_Preserved);
         else
            Add_Blocker (Result, Status_Warning_Restriction_Evidence_Lost);
         end if;
      elsif Row.Assertion_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Assertion_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      elsif Row.Suppressed_Check_Runtime then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Suppressed_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      else
         Add_Blocker (Result, Status_Legal_Gap_Burned_Down);
      end if;
   end Add_Success_Or_Runtime_Status;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry :=
        (Id => Row.Id,
         Gap => Row.Gap,
         Family => Row.Family,
         Owner => Row.Owner,
         Consumer => Row.Consumer,
         Expected => Row.Expected,
         Construct => Row.Construct,
         Context => Row.Context,
         Status => Status_Not_Checked,
         Blocker_Count => 0,
         Result_Fingerprint => Row.Burn_Down_Fingerprint
           + Row.Source_Fingerprint
           + Row.AST_Fingerprint
           + Row.Unit_Fingerprint
           + Row.Policy_Fingerprint
           + Row.Category_Fingerprint
           + Row.Restriction_Fingerprint
           + Row.Consumer_Fingerprint);
      Actual_Expected : Precision_Classification;
   begin
      Check_Audit_Gates (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Pragma_Policy_Rules (Row, Result);
      Check_Consumers (Row, Result);
      Check_Fingerprints (Row, Result);
      Add_Success_Or_Runtime_Status (Row, Result);

      Actual_Expected := Expected_For_Status (Result.Status);
      if Row.Expected /= Precision.Class_Unknown
        and then Actual_Expected /= Precision.Class_Unknown
        and then Row.Expected /= Actual_Expected
      then
         Add_Blocker (Result, Status_Unexpected_Classification);
      end if;

      return Result;
   end Evaluate;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
      Feed_Item : Burn_Down_Entry;
      Classification : Precision_Classification;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Feed_Item := Evaluate (Row);
         Results.Entries.Append (Feed_Item);
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Feed_Item.Result_Fingerprint
           + Natural (Burn_Down_Status'Pos (Feed_Item.Status))
           + Feed_Item.Blocker_Count;

         if Feed_Item.Consumer /= Consumers.Consumer_Unknown then
            Results.Consumer_Count := Results.Consumer_Count + 1;
         end if;

         if Feed_Item.Status = Status_Warning_Restriction_Preserved then
            Results.Warning_Count := Results.Warning_Count + 1;
         end if;

         Classification := Expected_For_Status (Feed_Item.Status);
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

   function Pragma_Configuration_Categorization_Restrictions_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Feed_Item of Results.Entries loop
         if Feed_Item.Gap = Gap_Pragma_Configuration_Categorization_Restrictions then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Feed_Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Pragma_Configuration_Categorization_Restrictions_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1352;
