package body Editor.Ada_RM_Gap_Burn_Down_Case_1348 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


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

   function Tasking_Protected_Parallel_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if not RM_Gap_Burn_Down_Ready (Results) then
         return False;
      end if;

      for R of Results.Items loop
         if R.Gap = Gap_Tasking_Protected_Parallel_Shared_State
           and then R.Promoted_State = Remediation.State_Covered
           and then R.Matrix_Level_After = Matrix.Coverage_Covered
         then
            Saw_Target_Gap := True;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Tasking_Protected_Parallel_Gap_Closed;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Illegal_Protected_Reentrant_Call
                     | Status_Illegal_Protected_Access_Mode_Mismatch
                     | Status_Illegal_Protected_Barrier_Side_Effect
                     | Status_Illegal_Protected_Shared_State_Write_Without_Effect
                     | Status_Illegal_Entry_Family_Index_Range
                     | Status_Illegal_Entry_Queue_Discipline
                     | Status_Illegal_Missing_Accept_Body_Effect_Evidence
                     | Status_Illegal_Requeue_Target_Mismatch
                     | Status_Illegal_Select_Path_Not_Covered
                     | Status_Illegal_Terminate_Alternative_Unsafe
                     | Status_Illegal_Abort_Finalization_Order
                     | Status_Illegal_Abortable_Select_Finalization_Unsafe
                     | Status_Illegal_Task_Termination_Finalization_Blocker
                     | Status_Illegal_Controlled_Finalization_Evidence_Missing
                     | Status_Illegal_Parallel_Shared_State_Write
                     | Status_Illegal_Iterator_Tampering
                     | Status_Illegal_Reduction_Profile_Mismatch
                     | Status_Illegal_Reduction_Seed_Mismatch
                     | Status_Illegal_Global_Depends_Evidence_Lost
                     | Status_Illegal_Refined_Flow_Evidence_Lost
                     | Status_Illegal_Volatile_Ordering_Lost
                     | Status_Illegal_Atomic_Ordering_Lost
                     | Status_Illegal_Dispatching_Effect_Join_Missing
                     | Status_Illegal_Synchronized_Interface_Effect_Disagreement
                     | Status_Runtime_Tampering_Check_Preserved
                     | Status_Runtime_Bounds_Check_Preserved
                     | Status_Runtime_Accessibility_Check_Preserved
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Effect_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down | Status_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Illegal_Protected_Reentrant_Call
            | Status_Illegal_Protected_Access_Mode_Mismatch
            | Status_Illegal_Protected_Barrier_Side_Effect
            | Status_Illegal_Protected_Shared_State_Write_Without_Effect
            | Status_Illegal_Entry_Family_Index_Range
            | Status_Illegal_Entry_Queue_Discipline
            | Status_Illegal_Missing_Accept_Body_Effect_Evidence
            | Status_Illegal_Requeue_Target_Mismatch
            | Status_Illegal_Select_Path_Not_Covered
            | Status_Illegal_Terminate_Alternative_Unsafe
            | Status_Illegal_Abort_Finalization_Order
            | Status_Illegal_Abortable_Select_Finalization_Unsafe
            | Status_Illegal_Task_Termination_Finalization_Blocker
            | Status_Illegal_Controlled_Finalization_Evidence_Missing
            | Status_Illegal_Parallel_Shared_State_Write
            | Status_Illegal_Iterator_Tampering
            | Status_Illegal_Reduction_Profile_Mismatch
            | Status_Illegal_Reduction_Seed_Mismatch
            | Status_Illegal_Global_Depends_Evidence_Lost
            | Status_Illegal_Refined_Flow_Evidence_Lost
            | Status_Illegal_Volatile_Ordering_Lost
            | Status_Illegal_Atomic_Ordering_Lost
            | Status_Illegal_Dispatching_Effect_Join_Missing
            | Status_Illegal_Synchronized_Interface_Effect_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Runtime_Tampering_Check_Preserved
            | Status_Runtime_Bounds_Check_Preserved
            | Status_Runtime_Accessibility_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Effect_Evidence
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
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Flow_Fingerprint /= Row.Expected_Flow_Fingerprint then
         Add_Blocker (Result, Status_Flow_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Rule_Status (Row : Burn_Down_Row) return Burn_Down_Status is
   begin
      if Row.Private_View_Barrier then
         return Status_Indeterminate_Private_View;
      elsif Row.Limited_View_Barrier then
         return Status_Indeterminate_Limited_View;
      elsif Row.Incomplete_View_Barrier then
         return Status_Indeterminate_Incomplete_View;
      elsif Row.Generic_Formal_View_Barrier then
         return Status_Indeterminate_Generic_Formal_View;
      elsif Row.Missing_Cross_Unit_Evidence then
         return Status_Indeterminate_Missing_Cross_Unit_Evidence;
      elsif Row.Missing_Effect_Evidence then
         return Status_Indeterminate_Missing_Effect_Evidence;
      elsif not Row.Protected_Action_Reentrancy_Safe then
         return Status_Illegal_Protected_Reentrant_Call;
      elsif not Row.Protected_Access_Mode_Compatible then
         return Status_Illegal_Protected_Access_Mode_Mismatch;
      elsif not Row.Protected_Barrier_Pure then
         return Status_Illegal_Protected_Barrier_Side_Effect;
      elsif not Row.Protected_Shared_State_Write_Has_Effect then
         return Status_Illegal_Protected_Shared_State_Write_Without_Effect;
      elsif not Row.Entry_Family_Index_In_Range then
         return Status_Illegal_Entry_Family_Index_Range;
      elsif not Row.Entry_Queue_Discipline_Compatible then
         return Status_Illegal_Entry_Queue_Discipline;
      elsif not Row.Accept_Body_Effect_Evidence_Present then
         return Status_Illegal_Missing_Accept_Body_Effect_Evidence;
      elsif not Row.Requeue_Target_Compatible then
         return Status_Illegal_Requeue_Target_Mismatch;
      elsif not Row.Select_Path_Covered then
         return Status_Illegal_Select_Path_Not_Covered;
      elsif not Row.Terminate_Alternative_Dependency_Safe then
         return Status_Illegal_Terminate_Alternative_Unsafe;
      elsif not Row.Abort_Finalization_Order_Safe then
         return Status_Illegal_Abort_Finalization_Order;
      elsif not Row.Abortable_Select_Finalization_Safe then
         return Status_Illegal_Abortable_Select_Finalization_Unsafe;
      elsif not Row.Task_Termination_Finalization_Safe then
         return Status_Illegal_Task_Termination_Finalization_Blocker;
      elsif not Row.Controlled_Finalization_Evidence_Present then
         return Status_Illegal_Controlled_Finalization_Evidence_Missing;
      elsif not Row.Parallel_Shared_State_Effects_Valid then
         return Status_Illegal_Parallel_Shared_State_Write;
      elsif not Row.Iterator_Tampering_Static_Safe then
         if Row.Iterator_Tampering_Runtime_Check then
            if Row.Runtime_Check_Evidence_Preserved then
               return Status_Runtime_Tampering_Check_Preserved;
            else
               return Status_Runtime_Check_Evidence_Lost;
            end if;
         else
            return Status_Illegal_Iterator_Tampering;
         end if;
      elsif not Row.Reduction_Profile_Compatible then
         return Status_Illegal_Reduction_Profile_Mismatch;
      elsif not Row.Reduction_Seed_Compatible then
         return Status_Illegal_Reduction_Seed_Mismatch;
      elsif not Row.Global_Depends_Evidence_Preserved then
         return Status_Illegal_Global_Depends_Evidence_Lost;
      elsif not Row.Refined_Flow_Evidence_Preserved then
         return Status_Illegal_Refined_Flow_Evidence_Lost;
      elsif not Row.Volatile_Ordering_Preserved then
         return Status_Illegal_Volatile_Ordering_Lost;
      elsif not Row.Atomic_Ordering_Preserved then
         return Status_Illegal_Atomic_Ordering_Lost;
      elsif not Row.Dispatching_Effect_Join_Present then
         return Status_Illegal_Dispatching_Effect_Join_Missing;
      elsif not Row.Synchronized_Interface_Effects_Agree then
         return Status_Illegal_Synchronized_Interface_Effect_Disagreement;
      elsif Row.Runtime_Bounds_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Bounds_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Runtime_Accessibility_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Accessibility_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
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
        1_348_000
        + Row.Id
        + Burn_Down_Gap'Pos (Row.Gap)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Owner)
        + Remediation.Remediation_State'Pos (Row.Previous_State)
        + Remediation.Remediation_State'Pos (Row.Target_State)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_Before)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_After)
        + Tasking_Construct_Kind'Pos (Row.Construct)
        + Tasking_Context_Kind'Pos (Row.Context)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Flow_Fingerprint
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
      if not Row.Consumer_Tasking_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Tasking_Model_Disagreement);
      end if;
      if not Row.Consumer_Protected_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Protected_Model_Disagreement);
      end if;
      if not Row.Consumer_Flow_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Flow_Model_Disagreement);
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

end Editor.Ada_RM_Gap_Burn_Down_Case_1348;
