package body Editor.Ada_RM_Gap_Burn_Down_Pass1354 is

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
                     | Status_Runtime_Default_Initialization_Check_Preserved
                     | Status_Runtime_Check_Evidence_Lost
                     | Status_Illegal_Declarative_Region_Missing
                     | Status_Illegal_Scope_Parent_Mismatch
                     | Status_Illegal_Duplicate_Nonoverloadable_Declaration
                     | Status_Illegal_Overloadable_Homograph_Collapsed_As_Duplicate
                     | Status_Illegal_Direct_Hiding_Conflict_Mismatch
                     | Status_Illegal_Use_Visible_Conflict_Mismatch
                     | Status_Illegal_Private_Full_View_Disagreement
                     | Status_Illegal_Incomplete_Type_Used_As_Complete
                     | Status_Illegal_Deferred_Constant_Missing_Completion
                     | Status_Illegal_Deferred_Constant_Completion_Mismatch
                     | Status_Illegal_Body_Spec_Kind_Mismatch
                     | Status_Illegal_Body_Spec_Profile_Mismatch
                     | Status_Illegal_Task_Protected_Body_Missing
                     | Status_Illegal_Generic_Body_Missing
                     | Status_Illegal_Duplicate_Completion
                     | Status_Illegal_Missing_Completion
                     | Status_Illegal_Renaming_Target_Missing
                     | Status_Illegal_Renaming_Target_Not_Visible
                     | Status_Illegal_Renaming_Kind_Mismatch
                     | Status_Illegal_Renaming_Type_Profile_Mode_Mismatch
                     | Status_Illegal_Renaming_View_Lost
                     | Status_Illegal_Alias_Cycle
                     | Status_Illegal_Alias_Depth_Overflow
                     | Status_Illegal_Name_Resolution_Entity_Disagreement
                     | Status_Illegal_Aggregate_Completion_View_Disagreement
                     | Status_Illegal_Assignment_Completion_View_Disagreement
                     | Status_Illegal_Generic_Substitution_Entity_Lost
                     | Status_Illegal_Outline_Completion_Disagreement
                     | Status_Illegal_Navigation_Alias_Disagreement
                     | Status_Illegal_Hover_View_Disagreement
                     | Status_Illegal_Diagnostic_Bridge_Disagreement
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Declaration_Evidence
                     | Status_Indeterminate_Missing_Scope_Evidence
                     | Status_Indeterminate_Missing_Completion_Evidence
                     | Status_Indeterminate_Missing_Alias_Evidence
                     | Status_Indeterminate_Missing_Profile_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Runtime_Default_Initialization_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Declarative_Region_Missing
            | Status_Illegal_Scope_Parent_Mismatch
            | Status_Illegal_Duplicate_Nonoverloadable_Declaration
            | Status_Illegal_Overloadable_Homograph_Collapsed_As_Duplicate
            | Status_Illegal_Direct_Hiding_Conflict_Mismatch
            | Status_Illegal_Use_Visible_Conflict_Mismatch
            | Status_Illegal_Private_Full_View_Disagreement
            | Status_Illegal_Incomplete_Type_Used_As_Complete
            | Status_Illegal_Deferred_Constant_Missing_Completion
            | Status_Illegal_Deferred_Constant_Completion_Mismatch
            | Status_Illegal_Body_Spec_Kind_Mismatch
            | Status_Illegal_Body_Spec_Profile_Mismatch
            | Status_Illegal_Task_Protected_Body_Missing
            | Status_Illegal_Generic_Body_Missing
            | Status_Illegal_Duplicate_Completion
            | Status_Illegal_Missing_Completion
            | Status_Illegal_Renaming_Target_Missing
            | Status_Illegal_Renaming_Target_Not_Visible
            | Status_Illegal_Renaming_Kind_Mismatch
            | Status_Illegal_Renaming_Type_Profile_Mode_Mismatch
            | Status_Illegal_Renaming_View_Lost
            | Status_Illegal_Alias_Cycle
            | Status_Illegal_Alias_Depth_Overflow
            | Status_Illegal_Name_Resolution_Entity_Disagreement
            | Status_Illegal_Aggregate_Completion_View_Disagreement
            | Status_Illegal_Assignment_Completion_View_Disagreement
            | Status_Illegal_Generic_Substitution_Entity_Lost
            | Status_Illegal_Outline_Completion_Disagreement
            | Status_Illegal_Navigation_Alias_Disagreement
            | Status_Illegal_Hover_View_Disagreement
            | Status_Illegal_Diagnostic_Bridge_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Declaration_Evidence
            | Status_Indeterminate_Missing_Scope_Evidence
            | Status_Indeterminate_Missing_Completion_Evidence
            | Status_Indeterminate_Missing_Alias_Evidence
            | Status_Indeterminate_Missing_Profile_Evidence
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
      if Row.Declaration_Fingerprint /= Row.Expected_Declaration_Fingerprint then
         Add_Blocker (Result, Status_Declaration_Fingerprint_Mismatch);
      end if;
      if Row.Scope_Fingerprint /= Row.Expected_Scope_Fingerprint then
         Add_Blocker (Result, Status_Scope_Fingerprint_Mismatch);
      end if;
      if Row.Completion_Fingerprint /= Row.Expected_Completion_Fingerprint then
         Add_Blocker (Result, Status_Completion_Fingerprint_Mismatch);
      end if;
      if Row.Alias_Fingerprint /= Row.Expected_Alias_Fingerprint then
         Add_Blocker (Result, Status_Alias_Fingerprint_Mismatch);
      end if;
      if Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Add_Blocker (Result, Status_Unit_Fingerprint_Mismatch);
      end if;
      if Row.View_Fingerprint /= Row.Expected_View_Fingerprint then
         Add_Blocker (Result, Status_View_Fingerprint_Mismatch);
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
      elsif Row.Missing_Declaration_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Declaration_Evidence);
      elsif Row.Missing_Scope_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Scope_Evidence);
      elsif Row.Missing_Completion_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Completion_Evidence);
      elsif Row.Missing_Alias_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Alias_Evidence);
      elsif Row.Missing_Profile_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Profile_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Declaration_Lifecycle_Rules
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Declarative_Region_Present then
         Add_Blocker (Result, Status_Illegal_Declarative_Region_Missing);
      elsif not Row.Scope_Parent_Agrees then
         Add_Blocker (Result, Status_Illegal_Scope_Parent_Mismatch);
      elsif Row.Duplicate_Nonoverloadable_Declaration then
         Add_Blocker (Result,
                      Status_Illegal_Duplicate_Nonoverloadable_Declaration);
      elsif not Row.Overloadable_Homographs_Agree then
         Add_Blocker
           (Result, Status_Illegal_Overloadable_Homograph_Collapsed_As_Duplicate);
      elsif not Row.Hiding_Vs_Conflict_Agrees then
         Add_Blocker (Result, Status_Illegal_Direct_Hiding_Conflict_Mismatch);
      elsif not Row.Use_Visible_Conflict_Agrees then
         Add_Blocker (Result, Status_Illegal_Use_Visible_Conflict_Mismatch);
      elsif not Row.Private_Full_View_Agrees then
         Add_Blocker (Result, Status_Illegal_Private_Full_View_Disagreement);
      elsif Row.Incomplete_Type_Used_As_Complete
        or else not Row.Incomplete_Type_Completed_Before_Use
      then
         Add_Blocker (Result, Status_Illegal_Incomplete_Type_Used_As_Complete);
      elsif not Row.Deferred_Constant_Completion_Present then
         Add_Blocker (Result,
                      Status_Illegal_Deferred_Constant_Missing_Completion);
      elsif not Row.Deferred_Constant_Completion_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Deferred_Constant_Completion_Mismatch);
      elsif not Row.Body_Spec_Kind_Agrees then
         Add_Blocker (Result, Status_Illegal_Body_Spec_Kind_Mismatch);
      elsif not Row.Body_Spec_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Body_Spec_Profile_Mismatch);
      elsif not Row.Task_Protected_Body_Completion_Present then
         Add_Blocker (Result, Status_Illegal_Task_Protected_Body_Missing);
      elsif not Row.Generic_Body_Completion_Present then
         Add_Blocker (Result, Status_Illegal_Generic_Body_Missing);
      elsif Row.Duplicate_Completion then
         Add_Blocker (Result, Status_Illegal_Duplicate_Completion);
      elsif Row.Missing_Completion then
         Add_Blocker (Result, Status_Illegal_Missing_Completion);
      elsif not Row.Renaming_Target_Present then
         Add_Blocker (Result, Status_Illegal_Renaming_Target_Missing);
      elsif not Row.Renaming_Target_Visible then
         Add_Blocker (Result, Status_Illegal_Renaming_Target_Not_Visible);
      elsif not Row.Renaming_Kind_Agrees then
         Add_Blocker (Result, Status_Illegal_Renaming_Kind_Mismatch);
      elsif not Row.Renaming_Type_Profile_Mode_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Renaming_Type_Profile_Mode_Mismatch);
      elsif not Row.Renaming_View_Preserved then
         Add_Blocker (Result, Status_Illegal_Renaming_View_Lost);
      elsif Row.Alias_Cycle then
         Add_Blocker (Result, Status_Illegal_Alias_Cycle);
      elsif Row.Alias_Depth_Overflow then
         Add_Blocker (Result, Status_Illegal_Alias_Depth_Overflow);
      elsif not Row.Name_Resolution_Consumes_Entity then
         Add_Blocker
           (Result, Status_Illegal_Name_Resolution_Entity_Disagreement);
      elsif not Row.Aggregate_Consumes_Completion_View then
         Add_Blocker
           (Result, Status_Illegal_Aggregate_Completion_View_Disagreement);
      elsif not Row.Assignment_Consumes_Completion_View then
         Add_Blocker
           (Result, Status_Illegal_Assignment_Completion_View_Disagreement);
      elsif not Row.Generic_Substitution_Preserves_Entity then
         Add_Blocker (Result, Status_Illegal_Generic_Substitution_Entity_Lost);
      elsif Row.Runtime_Default_Initialization_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker
              (Result, Status_Runtime_Default_Initialization_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
   end Check_Declaration_Lifecycle_Rules;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Declaration_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Name_Resolution_Entity_Disagreement);
      elsif not Row.Consumer_Completion_Agrees then
         Add_Blocker (Result, Status_Illegal_Outline_Completion_Disagreement);
      elsif not Row.Consumer_Alias_Agrees then
         Add_Blocker (Result, Status_Illegal_Navigation_Alias_Disagreement);
      elsif not Row.Consumer_View_Agrees then
         Add_Blocker (Result, Status_Illegal_Hover_View_Disagreement);
      elsif not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Illegal_Diagnostic_Bridge_Disagreement);
      end if;
   end Check_Consumers;

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
        + Row.Declaration_Fingerprint
        + Row.Scope_Fingerprint
        + Row.Completion_Fingerprint
        + Row.Alias_Fingerprint
        + Row.Unit_Fingerprint
        + Row.View_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Id;

      Check_Audit_Gates (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Declaration_Lifecycle_Rules (Row, Result);
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

   function Declaration_Scope_Completion_Alias_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Feed_Item of Results.Entries loop
         if Feed_Item.Gap = Gap_Declaration_Region_Scope_Completion_Alias then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Feed_Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Declaration_Scope_Completion_Alias_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1354;
