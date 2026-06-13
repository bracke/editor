package body Editor.Ada_RM_Gap_Burn_Down_Pass1351 is

   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Burn_Down_Row;

   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry is
   begin
      for R of Results.Items loop
         if R.Id = Id then
            return R;
         end if;
      end loop;

      return
        (Id => Id,
         Gap => Gap_Unknown,
         Family => Matrix.Family_Unknown,
         Owner => Matrix.Slice_Unknown,
         Previous_State => Remediation.State_Unknown,
         Promoted_State => Remediation.State_Unknown,
         Matrix_Level_After => Matrix.Coverage_Unknown,
         Consumer => Consumers.Consumer_Unknown,
         Classification => Precision.Class_Unknown,
         Status => Status_Not_Checked,
         Blocker_Count => 0,
         Entry_Fingerprint => 0);
   end Result_For;

   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean is
   begin
      return Count (Results) > 0
        and then Results.Invalid_Count = 0
        and then Results.Burned_Down_Count = Count (Results)
        and then Results.Legal_Count > 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Indeterminate_Count > 0;
   end RM_Gap_Burn_Down_Ready;

   function Control_Exception_Initialization_Finalization_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if not RM_Gap_Burn_Down_Ready (Results) then
         return False;
      end if;

      for R of Results.Items loop
         if R.Gap = Gap_Control_Exception_Initialization_Finalization
           and then R.Promoted_State = Remediation.State_Covered
           and then R.Matrix_Level_After = Matrix.Coverage_Covered
         then
            Saw_Target_Gap := True;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Control_Exception_Initialization_Finalization_Gap_Closed;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Illegal_Function_Path_Missing_Return
                     | Status_Illegal_Return_Expression_Type_Mismatch
                     | Status_Illegal_Return_Accessibility_Escape
                     | Status_Illegal_No_Return_Has_Normal_Return
                     | Status_Illegal_Unreachable_Statement
                     | Status_Illegal_Exit_Target_Missing
                     | Status_Illegal_Exit_Target_Not_Loop
                     | Status_Illegal_Goto_Target_Missing
                     | Status_Illegal_Goto_Into_Deeper_Scope
                     | Status_Illegal_Goto_Into_Protected_Action
                     | Status_Illegal_Required_Initializer_Missing
                     | Status_Illegal_Default_Expression
                     | Status_Illegal_Deferred_Constant_Completion_Mismatch
                     | Status_Illegal_Out_Parameter_Not_Assigned
                     | Status_Illegal_Aggregate_Initialization_Disagreement
                     | Status_Illegal_Subtype_Predicate_Initialization_Disagreement
                     | Status_Illegal_Raise_Exception_Missing
                     | Status_Illegal_Raise_Exception_Not_Visible
                     | Status_Illegal_Raise_Target_Not_Exception
                     | Status_Illegal_Handler_Choice_Missing
                     | Status_Illegal_Duplicate_Handler_Choice
                     | Status_Illegal_Unreachable_Handler
                     | Status_Illegal_Reraise_Outside_Handler
                     | Status_Illegal_Local_Handler_Propagation_Disagreement
                     | Status_Illegal_Controlled_Initialize_Profile_Mismatch
                     | Status_Illegal_Controlled_Adjust_Profile_Mismatch
                     | Status_Illegal_Controlled_Finalize_Profile_Mismatch
                     | Status_Illegal_Finalization_Order_Disagreement
                     | Status_Illegal_Limited_Controlled_Blocker
                     | Status_Illegal_Controlled_Component_Initialization_Disagreement
                     | Status_Illegal_Exception_Finalization_Hazard
                     | Status_Illegal_Abort_Finalization_Disagreement
                     | Status_Illegal_Task_Finalization_Disagreement
                     | Status_Runtime_Constraint_Check_Preserved
                     | Status_Runtime_Predicate_Check_Preserved
                     | Status_Runtime_Accessibility_Check_Preserved
                     | Status_Runtime_Finalization_Path_Preserved
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Control_Flow_Evidence
                     | Status_Indeterminate_Missing_Definite_Assignment_Evidence
                     | Status_Indeterminate_Missing_Exception_Evidence
                     | Status_Indeterminate_Missing_Finalization_Evidence
                     | Status_Indeterminate_Missing_Lifetime_Effect_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down | Status_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Illegal_Function_Path_Missing_Return
            | Status_Illegal_Return_Expression_Type_Mismatch
            | Status_Illegal_Return_Accessibility_Escape
            | Status_Illegal_No_Return_Has_Normal_Return
            | Status_Illegal_Unreachable_Statement
            | Status_Illegal_Exit_Target_Missing
            | Status_Illegal_Exit_Target_Not_Loop
            | Status_Illegal_Goto_Target_Missing
            | Status_Illegal_Goto_Into_Deeper_Scope
            | Status_Illegal_Goto_Into_Protected_Action
            | Status_Illegal_Required_Initializer_Missing
            | Status_Illegal_Default_Expression
            | Status_Illegal_Deferred_Constant_Completion_Mismatch
            | Status_Illegal_Out_Parameter_Not_Assigned
            | Status_Illegal_Aggregate_Initialization_Disagreement
            | Status_Illegal_Subtype_Predicate_Initialization_Disagreement
            | Status_Illegal_Raise_Exception_Missing
            | Status_Illegal_Raise_Exception_Not_Visible
            | Status_Illegal_Raise_Target_Not_Exception
            | Status_Illegal_Handler_Choice_Missing
            | Status_Illegal_Duplicate_Handler_Choice
            | Status_Illegal_Unreachable_Handler
            | Status_Illegal_Reraise_Outside_Handler
            | Status_Illegal_Local_Handler_Propagation_Disagreement
            | Status_Illegal_Controlled_Initialize_Profile_Mismatch
            | Status_Illegal_Controlled_Adjust_Profile_Mismatch
            | Status_Illegal_Controlled_Finalize_Profile_Mismatch
            | Status_Illegal_Finalization_Order_Disagreement
            | Status_Illegal_Limited_Controlled_Blocker
            | Status_Illegal_Controlled_Component_Initialization_Disagreement
            | Status_Illegal_Exception_Finalization_Hazard
            | Status_Illegal_Abort_Finalization_Disagreement
            | Status_Illegal_Task_Finalization_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Runtime_Constraint_Check_Preserved
            | Status_Runtime_Predicate_Check_Preserved
            | Status_Runtime_Accessibility_Check_Preserved
            | Status_Runtime_Finalization_Path_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Control_Flow_Evidence
            | Status_Indeterminate_Missing_Definite_Assignment_Evidence
            | Status_Indeterminate_Missing_Exception_Evidence
            | Status_Indeterminate_Missing_Finalization_Evidence
            | Status_Indeterminate_Missing_Lifetime_Effect_Evidence
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
      if Result.Status = Status_Not_Checked
        or else Is_Valid_Status (Result.Status)
      then
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
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Flow_Fingerprint /= Row.Expected_Flow_Fingerprint then
         Add_Blocker (Result, Status_Flow_Fingerprint_Mismatch);
      end if;
      if Row.Initialization_Fingerprint /= Row.Expected_Initialization_Fingerprint then
         Add_Blocker (Result, Status_Initialization_Fingerprint_Mismatch);
      end if;
      if Row.Exception_Fingerprint /= Row.Expected_Exception_Fingerprint then
         Add_Blocker (Result, Status_Exception_Fingerprint_Mismatch);
      end if;
      if Row.Finalization_Fingerprint /= Row.Expected_Finalization_Fingerprint then
         Add_Blocker (Result, Status_Finalization_Fingerprint_Mismatch);
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

   function Runtime_Status (Row : Burn_Down_Row) return Burn_Down_Status is
   begin
      if not Row.Runtime_Check_Evidence_Preserved then
         return Status_Runtime_Check_Evidence_Lost;
      elsif Row.Runtime_Constraint_Check then
         return Status_Runtime_Constraint_Check_Preserved;
      elsif Row.Runtime_Predicate_Check then
         return Status_Runtime_Predicate_Check_Preserved;
      elsif Row.Runtime_Accessibility_Check then
         return Status_Runtime_Accessibility_Check_Preserved;
      elsif Row.Runtime_Finalization_Path then
         return Status_Runtime_Finalization_Path_Preserved;
      else
         return Status_Not_Checked;
      end if;
   end Runtime_Status;

   function Rule_Status (Row : Burn_Down_Row) return Burn_Down_Status is
      Runtime : constant Burn_Down_Status := Runtime_Status (Row);
   begin
      if Row.Private_View_Barrier then
         return Status_Indeterminate_Private_View;
      elsif Row.Limited_View_Barrier then
         return Status_Indeterminate_Limited_View;
      elsif Row.Incomplete_View_Barrier then
         return Status_Indeterminate_Incomplete_View;
      elsif Row.Generic_Formal_View_Barrier then
         return Status_Indeterminate_Generic_Formal_View;
      elsif Row.Missing_Full_View_Evidence then
         return Status_Indeterminate_Missing_Full_View;
      elsif Row.Missing_Cross_Unit_Evidence then
         return Status_Indeterminate_Missing_Cross_Unit_Evidence;
      elsif Row.Missing_Control_Flow_Evidence then
         return Status_Indeterminate_Missing_Control_Flow_Evidence;
      elsif Row.Missing_Definite_Assignment_Evidence then
         return Status_Indeterminate_Missing_Definite_Assignment_Evidence;
      elsif Row.Missing_Exception_Evidence then
         return Status_Indeterminate_Missing_Exception_Evidence;
      elsif Row.Missing_Finalization_Evidence then
         return Status_Indeterminate_Missing_Finalization_Evidence;
      elsif Row.Missing_Lifetime_Effect_Evidence then
         return Status_Indeterminate_Missing_Lifetime_Effect_Evidence;
      elsif not Row.Function_Path_Returns then
         return Status_Illegal_Function_Path_Missing_Return;
      elsif not Row.Return_Expression_Type_Compatible then
         return Status_Illegal_Return_Expression_Type_Mismatch;
      elsif not Row.Return_Accessibility_OK then
         return Status_Illegal_Return_Accessibility_Escape;
      elsif Row.No_Return_Has_Normal_Return then
         return Status_Illegal_No_Return_Has_Normal_Return;
      elsif Row.Unreachable_Statement_Present then
         return Status_Illegal_Unreachable_Statement;
      elsif not Row.Exit_Target_Present then
         return Status_Illegal_Exit_Target_Missing;
      elsif not Row.Exit_Target_Is_Loop then
         return Status_Illegal_Exit_Target_Not_Loop;
      elsif not Row.Goto_Target_Present then
         return Status_Illegal_Goto_Target_Missing;
      elsif Row.Goto_Into_Deeper_Scope then
         return Status_Illegal_Goto_Into_Deeper_Scope;
      elsif Row.Goto_Into_Protected_Action then
         return Status_Illegal_Goto_Into_Protected_Action;
      elsif not Row.Required_Initializer_Present then
         return Status_Illegal_Required_Initializer_Missing;
      elsif not Row.Default_Expression_Legal then
         return Status_Illegal_Default_Expression;
      elsif not Row.Deferred_Constant_Completion_Matches then
         return Status_Illegal_Deferred_Constant_Completion_Mismatch;
      elsif not Row.Out_Parameter_Definitely_Assigned then
         return Status_Illegal_Out_Parameter_Not_Assigned;
      elsif not Row.Aggregate_Initialization_Consumes then
         return Status_Illegal_Aggregate_Initialization_Disagreement;
      elsif not Row.Subtype_Predicate_Initialization_Consumes then
         return Status_Illegal_Subtype_Predicate_Initialization_Disagreement;
      elsif not Row.Exception_Name_Present then
         return Status_Illegal_Raise_Exception_Missing;
      elsif not Row.Exception_Name_Visible then
         return Status_Illegal_Raise_Exception_Not_Visible;
      elsif not Row.Raise_Target_Is_Exception then
         return Status_Illegal_Raise_Target_Not_Exception;
      elsif not Row.Handler_Choice_Present then
         return Status_Illegal_Handler_Choice_Missing;
      elsif Row.Duplicate_Handler_Choice then
         return Status_Illegal_Duplicate_Handler_Choice;
      elsif Row.Unreachable_Handler_Present then
         return Status_Illegal_Unreachable_Handler;
      elsif not Row.Reraise_Inside_Handler then
         return Status_Illegal_Reraise_Outside_Handler;
      elsif not Row.Local_Handler_Propagation_Agrees then
         return Status_Illegal_Local_Handler_Propagation_Disagreement;
      elsif not Row.Controlled_Initialize_Profile_Compatible then
         return Status_Illegal_Controlled_Initialize_Profile_Mismatch;
      elsif not Row.Controlled_Adjust_Profile_Compatible then
         return Status_Illegal_Controlled_Adjust_Profile_Mismatch;
      elsif not Row.Controlled_Finalize_Profile_Compatible then
         return Status_Illegal_Controlled_Finalize_Profile_Mismatch;
      elsif not Row.Finalization_Order_Agrees then
         return Status_Illegal_Finalization_Order_Disagreement;
      elsif Row.Limited_Controlled_Blocker then
         return Status_Illegal_Limited_Controlled_Blocker;
      elsif not Row.Controlled_Component_Initialization_Consumes then
         return Status_Illegal_Controlled_Component_Initialization_Disagreement;
      elsif Row.Exception_Finalization_Hazard then
         return Status_Illegal_Exception_Finalization_Hazard;
      elsif not Row.Abort_Finalization_Agrees then
         return Status_Illegal_Abort_Finalization_Disagreement;
      elsif not Row.Task_Finalization_Agrees then
         return Status_Illegal_Task_Finalization_Disagreement;
      elsif Runtime /= Status_Not_Checked then
         return Runtime;
      else
         return Status_Legal_Gap_Burned_Down;
      end if;
   end Rule_Status;

   procedure Check_Row
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
      Status : constant Burn_Down_Status := Rule_Status (Row);
      Classification : constant Precision_Classification := Expected_For_Status (Status);
   begin
      Result.Status := Status;
      Result.Classification := Classification;
      Result.Promoted_State := Row.Target_State;
      Result.Entry_Fingerprint :=
        1_351_000
        + Row.Id
        + Burn_Down_Gap'Pos (Row.Gap)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Owner)
        + Remediation.Remediation_State'Pos (Row.Previous_State)
        + Remediation.Remediation_State'Pos (Row.Target_State)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_Before)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_After)
        + Flow_Construct_Kind'Pos (Row.Construct)
        + Flow_Context_Kind'Pos (Row.Context)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Flow_Fingerprint
        + Row.Initialization_Fingerprint
        + Row.Exception_Fingerprint
        + Row.Finalization_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      end if;
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
      if Row.Target_State /= Remediation.State_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered
        or else not Row.Coverage_Entry_Updated_To_Covered
      then
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
      if not Row.Consumer_Control_Flow_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Control_Flow_Model_Disagreement);
      end if;
      if not Row.Consumer_Initialization_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Initialization_Model_Disagreement);
      end if;
      if not Row.Consumer_Exception_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Exception_Model_Disagreement);
      end if;
      if not Row.Consumer_Finalization_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Finalization_Model_Disagreement);
      end if;
      if not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Consumer_Diagnostic_Bridge_Disagreement);
      end if;
      if not Row.Stable_Blocker_Family
        and then Classification = Precision.Class_Illegal
      then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
      if Status = Status_Runtime_Check_Evidence_Lost then
         Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
      end if;
      if Row.Expected /= Precision.Class_Unknown
        and then Row.Expected /= Classification
      then
         Add_Blocker (Result, Status_Unexpected_Classification);
      end if;

      Check_Fingerprints (Row, Result);
   end Check_Row;

   procedure Count_Result
     (Results : in out Burn_Down_Model;
      Result : Burn_Down_Entry) is
   begin
      if Is_Valid_Status (Result.Status) then
         Results.Burned_Down_Count := Results.Burned_Down_Count + 1;
      else
         Results.Invalid_Count := Results.Invalid_Count + 1;
      end if;

      case Result.Classification is
         when Precision.Class_Legal =>
            Results.Legal_Count := Results.Legal_Count + 1;
         when Precision.Class_Illegal =>
            Results.Illegal_Count := Results.Illegal_Count + 1;
         when Precision.Class_Legal_With_Runtime_Check =>
            Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
         when Precision.Class_Indeterminate =>
            Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
         when others =>
            null;
      end case;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Burn_Down_Status'Pos (Result.Status)
        + Precision.Precision_Classification'Pos (Result.Classification)
        + Result.Blocker_Count;
   end Count_Result;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
   begin
      for Row of Input.Rows loop
         declare
            R : Burn_Down_Entry :=
              (Id => Row.Id,
               Gap => Row.Gap,
               Family => Row.Family,
               Owner => Row.Owner,
               Previous_State => Row.Previous_State,
               Promoted_State => Remediation.State_Unknown,
               Matrix_Level_After => Row.Matrix_Level_After,
               Consumer => Row.Consumer,
               Classification => Precision.Class_Unknown,
               Status => Status_Not_Checked,
               Blocker_Count => 0,
               Entry_Fingerprint => 0);
         begin
            Check_Row (Row, R);
            Results.Items.Append (R);
            Count_Result (Results, R);
         end;
      end loop;

      return Results;
   end Build;

end Editor.Ada_RM_Gap_Burn_Down_Pass1351;
