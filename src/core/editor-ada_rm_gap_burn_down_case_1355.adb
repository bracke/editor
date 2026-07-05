package body Editor.Ada_RM_Gap_Burn_Down_Case_1355 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


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
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Runtime_Accessibility_Check_Preserved
                     | Status_Runtime_Range_Predicate_Check_Preserved
                     | Status_Warning_Only_Policy_Preserved
                     | Status_Runtime_Check_Evidence_Lost
                     | Status_Warning_Policy_Evidence_Lost
                     | Status_Illegal_Missing_Required_Actual
                     | Status_Illegal_Extra_Actual
                     | Status_Illegal_Duplicate_Actual_Association
                     | Status_Illegal_Positional_Actual_After_Named
                     | Status_Illegal_Defaulted_Formal_Not_Available
                     | Status_Illegal_Association_Profile_Disagreement
                     | Status_Illegal_Out_Actual_Not_Variable
                     | Status_Illegal_In_Out_Actual_Not_Variable
                     | Status_Illegal_Constant_View_For_Writable_Formal
                     | Status_Illegal_Limited_View_For_Writable_Formal
                     | Status_Illegal_Out_Formal_Definite_Assignment_Missing
                     | Status_Illegal_Formal_Actual_Type_Mismatch
                     | Status_Illegal_Access_Parameter_Mismatch
                     | Status_Illegal_Anonymous_Access_Actual_Mismatch
                     | Status_Illegal_Null_Exclusion_Violation
                     | Status_Illegal_Static_Accessibility_Escape
                     | Status_Illegal_Callable_Profile_Disagreement
                     | Status_Illegal_Overload_Profile_Disagreement
                     | Status_Illegal_Writable_Actual_Alias
                     | Status_Illegal_Overlapping_Writable_Actuals
                     | Status_Illegal_Access_Value_Alias
                     | Status_Illegal_Volatile_Atomic_Ordering_Lost
                     | Status_Illegal_Protected_Shared_State_Effect_Lost
                     | Status_Illegal_Dispatching_Control_Evidence_Lost
                     | Status_Illegal_Generic_Substitution_Profile_Lost
                     | Status_Illegal_Renamed_Callable_Profile_Lost
                     | Status_Illegal_Access_To_Subprogram_Convention_Mismatch
                     | Status_Illegal_Contract_Evidence_Lost
                     | Status_Illegal_Global_Depends_Evidence_Lost
                     | Status_Illegal_Refined_Flow_Evidence_Lost
                     | Status_Illegal_Dispatching_Effect_Join_Lost
                     | Status_Illegal_Hard_Policy_Violation_Downgraded
                     | Status_Illegal_Diagnostics_Call_Disagreement
                     | Status_Illegal_Colouring_Call_Disagreement
                     | Status_Illegal_Outline_Profile_Disagreement
                     | Status_Illegal_Navigation_Target_Disagreement
                     | Status_Illegal_Hover_Effect_Disagreement
                     | Status_Illegal_Diagnostic_Bridge_Disagreement
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Call_Evidence
                     | Status_Indeterminate_Missing_Association_Evidence
                     | Status_Indeterminate_Missing_Profile_Evidence
                     | Status_Indeterminate_Missing_Overload_Evidence
                     | Status_Indeterminate_Missing_Substitution_Evidence
                     | Status_Indeterminate_Missing_Effect_Evidence
                     | Status_Indeterminate_Missing_Aliasing_Evidence
                     | Status_Indeterminate_Missing_Accessibility_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Runtime_Accessibility_Check_Preserved
            | Status_Runtime_Range_Predicate_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Warning_Only_Policy_Preserved
            | Status_Warning_Policy_Evidence_Lost =>
            return Precision.Class_Partial_Coverage;
         when Status_Illegal_Missing_Required_Actual
            | Status_Illegal_Extra_Actual
            | Status_Illegal_Duplicate_Actual_Association
            | Status_Illegal_Positional_Actual_After_Named
            | Status_Illegal_Defaulted_Formal_Not_Available
            | Status_Illegal_Association_Profile_Disagreement
            | Status_Illegal_Out_Actual_Not_Variable
            | Status_Illegal_In_Out_Actual_Not_Variable
            | Status_Illegal_Constant_View_For_Writable_Formal
            | Status_Illegal_Limited_View_For_Writable_Formal
            | Status_Illegal_Out_Formal_Definite_Assignment_Missing
            | Status_Illegal_Formal_Actual_Type_Mismatch
            | Status_Illegal_Access_Parameter_Mismatch
            | Status_Illegal_Anonymous_Access_Actual_Mismatch
            | Status_Illegal_Null_Exclusion_Violation
            | Status_Illegal_Static_Accessibility_Escape
            | Status_Illegal_Callable_Profile_Disagreement
            | Status_Illegal_Overload_Profile_Disagreement
            | Status_Illegal_Writable_Actual_Alias
            | Status_Illegal_Overlapping_Writable_Actuals
            | Status_Illegal_Access_Value_Alias
            | Status_Illegal_Volatile_Atomic_Ordering_Lost
            | Status_Illegal_Protected_Shared_State_Effect_Lost
            | Status_Illegal_Dispatching_Control_Evidence_Lost
            | Status_Illegal_Generic_Substitution_Profile_Lost
            | Status_Illegal_Renamed_Callable_Profile_Lost
            | Status_Illegal_Access_To_Subprogram_Convention_Mismatch
            | Status_Illegal_Contract_Evidence_Lost
            | Status_Illegal_Global_Depends_Evidence_Lost
            | Status_Illegal_Refined_Flow_Evidence_Lost
            | Status_Illegal_Dispatching_Effect_Join_Lost
            | Status_Illegal_Hard_Policy_Violation_Downgraded
            | Status_Illegal_Diagnostics_Call_Disagreement
            | Status_Illegal_Colouring_Call_Disagreement
            | Status_Illegal_Outline_Profile_Disagreement
            | Status_Illegal_Navigation_Target_Disagreement
            | Status_Illegal_Hover_Effect_Disagreement
            | Status_Illegal_Diagnostic_Bridge_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Call_Evidence
            | Status_Indeterminate_Missing_Association_Evidence
            | Status_Indeterminate_Missing_Profile_Evidence
            | Status_Indeterminate_Missing_Overload_Evidence
            | Status_Indeterminate_Missing_Substitution_Evidence
            | Status_Indeterminate_Missing_Effect_Evidence
            | Status_Indeterminate_Missing_Aliasing_Evidence
            | Status_Indeterminate_Missing_Accessibility_Evidence
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
      elsif Row.Missing_Call_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Call_Evidence);
      elsif Row.Missing_Association_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Association_Evidence);
      elsif Row.Missing_Profile_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Profile_Evidence);
      elsif Row.Missing_Overload_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Overload_Evidence);
      elsif Row.Missing_Substitution_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Substitution_Evidence);
      elsif Row.Missing_Effect_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Effect_Evidence);
      elsif Row.Missing_Aliasing_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Aliasing_Evidence);
      elsif Row.Missing_Accessibility_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Accessibility_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Call_Site_Rules
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Required_Actuals_Present then
         Add_Blocker (Result, Status_Illegal_Missing_Required_Actual);
      elsif Row.Extra_Actuals then
         Add_Blocker (Result, Status_Illegal_Extra_Actual);
      elsif Row.Duplicate_Actual_Association then
         Add_Blocker (Result, Status_Illegal_Duplicate_Actual_Association);
      elsif Row.Positional_Actual_After_Named then
         Add_Blocker (Result, Status_Illegal_Positional_Actual_After_Named);
      elsif not Row.Defaulted_Formals_Available then
         Add_Blocker (Result, Status_Illegal_Defaulted_Formal_Not_Available);
      elsif not Row.Association_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Association_Profile_Disagreement);
      elsif Row.Out_Formal and then not Row.Out_Actual_Is_Variable then
         Add_Blocker (Result, Status_Illegal_Out_Actual_Not_Variable);
      elsif Row.In_Out_Formal and then not Row.In_Out_Actual_Is_Variable then
         Add_Blocker (Result, Status_Illegal_In_Out_Actual_Not_Variable);
      elsif Row.Actual_Is_Constant_View and then (Row.Out_Formal or else Row.In_Out_Formal) then
         Add_Blocker (Result, Status_Illegal_Constant_View_For_Writable_Formal);
      elsif Row.Writable_Limited_View and then (Row.Out_Formal or else Row.In_Out_Formal) then
         Add_Blocker (Result, Status_Illegal_Limited_View_For_Writable_Formal);
      elsif Row.Out_Formal and then not Row.Out_Formal_Definite_Assignment_Present then
         Add_Blocker (Result, Status_Illegal_Out_Formal_Definite_Assignment_Missing);
      elsif not Row.Formal_Actual_Type_Agrees then
         Add_Blocker (Result, Status_Illegal_Formal_Actual_Type_Mismatch);
      elsif not Row.Access_Parameter_Agrees then
         Add_Blocker (Result, Status_Illegal_Access_Parameter_Mismatch);
      elsif not Row.Anonymous_Access_Actual_Agrees then
         Add_Blocker (Result, Status_Illegal_Anonymous_Access_Actual_Mismatch);
      elsif Row.Null_Exclusion_Violation then
         Add_Blocker (Result, Status_Illegal_Null_Exclusion_Violation);
      elsif Row.Static_Accessibility_Escape then
         Add_Blocker (Result, Status_Illegal_Static_Accessibility_Escape);
      elsif not Row.Callable_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Callable_Profile_Disagreement);
      elsif not Row.Overload_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Overload_Profile_Disagreement);
      elsif Row.Writable_Actual_Alias then
         Add_Blocker (Result, Status_Illegal_Writable_Actual_Alias);
      elsif Row.Overlapping_Writable_Actuals then
         Add_Blocker (Result, Status_Illegal_Overlapping_Writable_Actuals);
      elsif Row.Access_Value_Alias then
         Add_Blocker (Result, Status_Illegal_Access_Value_Alias);
      elsif not Row.Volatile_Atomic_Ordering_Preserved then
         Add_Blocker (Result, Status_Illegal_Volatile_Atomic_Ordering_Lost);
      elsif not Row.Protected_Shared_State_Effect_Preserved then
         Add_Blocker (Result, Status_Illegal_Protected_Shared_State_Effect_Lost);
      elsif not Row.Dispatching_Control_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Dispatching_Control_Evidence_Lost);
      elsif not Row.Generic_Substitution_Profile_Preserved then
         Add_Blocker (Result, Status_Illegal_Generic_Substitution_Profile_Lost);
      elsif not Row.Renamed_Callable_Profile_Preserved then
         Add_Blocker (Result, Status_Illegal_Renamed_Callable_Profile_Lost);
      elsif not Row.Access_To_Subprogram_Convention_Agrees then
         Add_Blocker (Result, Status_Illegal_Access_To_Subprogram_Convention_Mismatch);
      elsif not Row.Contract_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Contract_Evidence_Lost);
      elsif not Row.Global_Depends_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Global_Depends_Evidence_Lost);
      elsif not Row.Refined_Flow_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Refined_Flow_Evidence_Lost);
      elsif not Row.Dispatching_Effect_Join_Preserved then
         Add_Blocker (Result, Status_Illegal_Dispatching_Effect_Join_Lost);
      elsif Row.Hard_Policy_Violation_Downgraded then
         Add_Blocker (Result, Status_Illegal_Hard_Policy_Violation_Downgraded);
      elsif Row.Runtime_Accessibility_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Accessibility_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      elsif Row.Runtime_Range_Predicate_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Range_Predicate_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      elsif Row.Warning_Only_Policy then
         if Row.Warning_Policy_Evidence_Preserved then
            Add_Blocker (Result, Status_Warning_Only_Policy_Preserved);
         else
            Add_Blocker (Result, Status_Warning_Policy_Evidence_Lost);
         end if;
      end if;
   end Check_Call_Site_Rules;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Call_Agrees then
         Add_Blocker (Result, Status_Illegal_Diagnostics_Call_Disagreement);
      elsif not Row.Consumer_Actual_Agrees then
         Add_Blocker (Result, Status_Illegal_Colouring_Call_Disagreement);
      elsif not Row.Consumer_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Outline_Profile_Disagreement);
      elsif not Row.Consumer_Target_Agrees then
         Add_Blocker (Result, Status_Illegal_Navigation_Target_Disagreement);
      elsif not Row.Consumer_Effect_Agrees then
         Add_Blocker (Result, Status_Illegal_Hover_Effect_Disagreement);
      elsif not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Illegal_Diagnostic_Bridge_Disagreement);
      end if;
   end Check_Consumers;

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
      if Row.Call_Fingerprint /= Row.Expected_Call_Fingerprint then
         Add_Blocker (Result, Status_Call_Fingerprint_Mismatch);
      end if;
      if Row.Association_Fingerprint /= Row.Expected_Association_Fingerprint then
         Add_Blocker (Result, Status_Association_Fingerprint_Mismatch);
      end if;
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.Overload_Fingerprint /= Row.Expected_Overload_Fingerprint then
         Add_Blocker (Result, Status_Overload_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Alias_Fingerprint /= Row.Expected_Alias_Fingerprint then
         Add_Blocker (Result, Status_Alias_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Construct := Row.Construct;
      Result.Context := Row.Context;
      Result.Result_Fingerprint := Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Call_Fingerprint
        + Row.Association_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Overload_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Alias_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Id;

      Check_Audit_Gates (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Call_Site_Rules (Row, Result);
      Check_Consumers (Row, Result);
      Check_Fingerprints (Row, Result);

      if Result.Status = Status_Not_Checked then
         Result.Status := Status_Legal_Gap_Burned_Down;
      end if;

      if Row.Expected /= Precision.Class_Unknown
        and then Expected_For_Status (Result.Status) /= Row.Expected
      then
         Add_Blocker (Result, Status_Unexpected_Classification);
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
            when Precision.Class_Partial_Coverage =>
               Results.Warning_Count := Results.Warning_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
         end case;
      end loop;
      return Results;
   end Build;

   function Call_Actual_Parameter_Mode_Aliasing_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Call_Actual_Parameter_Mode_Aliasing then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Call_Actual_Parameter_Mode_Aliasing_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Case_1355;
