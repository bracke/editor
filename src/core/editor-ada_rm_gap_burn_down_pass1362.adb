package body Editor.Ada_RM_Gap_Burn_Down_Pass1362 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Blocker
     (Result : in out Burn_Down_Entry;
      Status : Burn_Down_Status) is
   begin
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      else
         Result.Status := Status_Multiple_Blockers;
      end if;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Legal_Work_Completed_Within_Budget
        | Status_Legal_Work_Cancelled_By_Newer_Request
        | Status_Legal_Work_Superseded_And_Rejected
        | Status_Legal_Deterministic_Order_Preserved
        | Status_Legal_Partial_Result_Preserved
        | Status_Legal_Runtime_Check_Preserved
        | Status_Indeterminate_Budget_Exceeded;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Work_Completed_Within_Budget
            | Status_Legal_Work_Cancelled_By_Newer_Request
            | Status_Legal_Work_Superseded_And_Rejected
            | Status_Legal_Deterministic_Order_Preserved
            | Status_Legal_Partial_Result_Preserved =>
            return Precision.Class_Legal;
         when Status_Legal_Runtime_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Work_Budget_Exceeded_As_Legal
            | Status_Illegal_Work_Budget_Exceeded_As_Illegal
            | Status_Illegal_Unbounded_Generic_Replay
            | Status_Illegal_Unbounded_Overload_Exploration
            | Status_Illegal_Unbounded_Cross_Unit_Closure
            | Status_Illegal_Diagnostic_Emitted_After_Cancellation
            | Status_Illegal_Stale_Partial_Result_Reused
            | Status_Illegal_Cancelled_Result_Consumed
            | Status_Illegal_Superseded_Result_Consumed
            | Status_Illegal_Nondeterministic_Work_Order
            | Status_Illegal_Nondeterministic_Blocker_Order
            | Status_Illegal_Nondeterministic_Diagnostic_Order
            | Status_Illegal_Nondeterministic_Outline_Order
            | Status_Illegal_Hash_Or_Timing_Dependent_Order
            | Status_Illegal_Consumer_Bypassed_Cancellation_State
            | Status_Illegal_Consumer_Bypassed_Budget_State
            | Status_Illegal_Diagnostics_Missing_Blocker_Family
            | Status_Illegal_File_Save_Reload_During_Analysis
            | Status_Illegal_Dirty_State_Mutation
            | Status_Illegal_Rendering_Side_Parsing
            | Status_Illegal_Command_Keybinding_Workspace_Render_Mutation =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Budget_Exceeded
            | Status_Missing_Remediation_Evidence
            | Status_Missing_Matrix_Coverage
            | Status_Missing_Implementing_Package
            | Status_No_New_Legality_Rule
            | Status_Coverage_Not_Updated_To_Covered
            | Status_Regression_Corpus_Not_Balanced
            | Status_Semantic_Result_Unconsumed
            | Status_Consumer_Not_Reached
            | Status_Source_Shaped_Evidence_Missing
            | Status_Unstable_Blocker_Family
            | Status_Buffer_Identity_Mismatch
            | Status_Source_Revision_Mismatch
            | Status_Lifecycle_Generation_Mismatch
            | Status_Request_Token_Mismatch
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Unit_Fingerprint_Mismatch
            | Status_Substitution_Fingerprint_Mismatch
            | Status_Effect_Fingerprint_Mismatch
            | Status_Policy_Fingerprint_Mismatch
            | Status_Recovery_Fingerprint_Mismatch
            | Status_Schedule_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Multiple_Blockers
            | Status_Unexpected_Classification
            | Status_Not_Checked
            | Status_Gap_Burned_Down =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Check_Audit_Gates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
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
      if not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
      if not Row.Diagnostics_Blocker_Family_Present then
         Add_Blocker (Result, Status_Illegal_Diagnostics_Missing_Blocker_Family);
      end if;
   end Check_Audit_Gates;

   procedure Check_Snapshot_Identity
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Buffer_Identity /= Row.Expected_Buffer_Identity then
         Add_Blocker (Result, Status_Buffer_Identity_Mismatch);
      end if;
      if Row.Source_Revision /= Row.Expected_Source_Revision then
         Add_Blocker (Result, Status_Source_Revision_Mismatch);
      end if;
      if Row.Lifecycle_Generation /= Row.Expected_Lifecycle_Generation then
         Add_Blocker (Result, Status_Lifecycle_Generation_Mismatch);
      end if;
      if Row.Request_Token /= Row.Expected_Request_Token then
         Add_Blocker (Result, Status_Request_Token_Mismatch);
      end if;
   end Check_Snapshot_Identity;

   procedure Check_Fingerprints
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
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
      if Row.Schedule_Fingerprint /= Row.Expected_Schedule_Fingerprint then
         Add_Blocker (Result, Status_Schedule_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Budgets
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Per_Buffer_Budget /= 0
        and then Row.Steps_Consumed > Row.Per_Buffer_Budget
        and then not Row.Budget_Exhausted
      then
         Add_Blocker (Result, Status_Illegal_Work_Budget_Exceeded_As_Legal);
      end if;

      if Row.Request_Budget /= 0
        and then Row.Steps_Consumed > Row.Request_Budget
        and then not Row.Budget_Exhausted
      then
         Add_Blocker (Result, Status_Illegal_Work_Budget_Exceeded_As_Legal);
      end if;

      if Row.Slice_Budget /= 0
        and then Row.Slice_Steps_Consumed > Row.Slice_Budget
        and then not Row.Budget_Exhausted
      then
         Add_Blocker (Result, Status_Illegal_Work_Budget_Exceeded_As_Legal);
      end if;

      if Row.Candidate_Limit /= 0
        and then Row.Candidate_Count > Row.Candidate_Limit
        and then not Row.Budget_Exhausted
      then
         Add_Blocker (Result, Status_Illegal_Unbounded_Overload_Exploration);
      end if;

      if Row.Replay_Depth_Limit /= 0
        and then Row.Replay_Depth > Row.Replay_Depth_Limit
        and then not Row.Budget_Exhausted
      then
         Add_Blocker (Result, Status_Illegal_Unbounded_Generic_Replay);
      end if;

      if Row.Cross_Unit_Depth_Limit /= 0
        and then Row.Cross_Unit_Depth > Row.Cross_Unit_Depth_Limit
        and then not Row.Budget_Exhausted
      then
         Add_Blocker (Result, Status_Illegal_Unbounded_Cross_Unit_Closure);
      end if;

      if Row.Budget_Exhaustion_Treated_As_Legal then
         Add_Blocker (Result, Status_Illegal_Work_Budget_Exceeded_As_Legal);
      end if;
      if Row.Budget_Exhaustion_Treated_As_Illegal then
         Add_Blocker (Result, Status_Illegal_Work_Budget_Exceeded_As_Illegal);
      end if;
      if Row.Unbounded_Generic_Replay then
         Add_Blocker (Result, Status_Illegal_Unbounded_Generic_Replay);
      end if;
      if Row.Unbounded_Overload_Exploration then
         Add_Blocker (Result, Status_Illegal_Unbounded_Overload_Exploration);
      end if;
      if Row.Unbounded_Cross_Unit_Closure then
         Add_Blocker (Result, Status_Illegal_Unbounded_Cross_Unit_Closure);
      end if;
   end Check_Budgets;

   procedure Check_Cancellation
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Work_Cancelled and then Row.Diagnostic_Emitted then
         Add_Blocker (Result, Status_Illegal_Diagnostic_Emitted_After_Cancellation);
      end if;
      if Row.Work_Cancelled and then Row.Cancelled_Result_Consumed then
         Add_Blocker (Result, Status_Illegal_Cancelled_Result_Consumed);
      end if;
      if Row.Work_Superseded and then Row.Superseded_Result_Consumed then
         Add_Blocker (Result, Status_Illegal_Superseded_Result_Consumed);
      end if;
      if Row.Stale_Partial_Result_Reused then
         Add_Blocker (Result, Status_Illegal_Stale_Partial_Result_Reused);
      end if;
      if Row.Consumer_Bypassed_Cancellation_State then
         Add_Blocker (Result, Status_Illegal_Consumer_Bypassed_Cancellation_State);
      end if;
      if Row.Consumer_Bypassed_Budget_State then
         Add_Blocker (Result, Status_Illegal_Consumer_Bypassed_Budget_State);
      end if;
   end Check_Cancellation;

   procedure Check_Determinism
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Deterministic_Work_Order then
         Add_Blocker (Result, Status_Illegal_Nondeterministic_Work_Order);
      end if;
      if not Row.Deterministic_Blocker_Order then
         Add_Blocker (Result, Status_Illegal_Nondeterministic_Blocker_Order);
      end if;
      if not Row.Deterministic_Diagnostic_Order then
         Add_Blocker (Result, Status_Illegal_Nondeterministic_Diagnostic_Order);
      end if;
      if not Row.Deterministic_Outline_Order then
         Add_Blocker (Result, Status_Illegal_Nondeterministic_Outline_Order);
      end if;
      if Row.Hash_Or_Timing_Dependent_Order then
         Add_Blocker (Result, Status_Illegal_Hash_Or_Timing_Dependent_Order);
      end if;
   end Check_Determinism;

   procedure Check_Editor_Invariants
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.File_Save_Reload_During_Analysis then
         Add_Blocker (Result, Status_Illegal_File_Save_Reload_During_Analysis);
      end if;
      if Row.Dirty_State_Mutation then
         Add_Blocker (Result, Status_Illegal_Dirty_State_Mutation);
      end if;
      if Row.Rendering_Side_Parsing then
         Add_Blocker (Result, Status_Illegal_Rendering_Side_Parsing);
      end if;
      if Row.Command_Keybinding_Workspace_Render_Mutation then
         Add_Blocker
           (Result,
            Status_Illegal_Command_Keybinding_Workspace_Render_Mutation);
      end if;
   end Check_Editor_Invariants;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Work := Row.Work;
      Result.Phase := Row.Phase;
      Result.Result_Fingerprint :=
        Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Work_Unit_Kind'Pos (Row.Work))
        + Natural (Schedule_Phase'Pos (Row.Phase))
        + Row.Buffer_Identity
        + Row.Source_Revision
        + Row.Lifecycle_Generation
        + Row.Request_Token
        + Row.Steps_Consumed
        + Row.Slice_Steps_Consumed
        + Row.Candidate_Count
        + Row.Replay_Depth
        + Row.Cross_Unit_Depth
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Unit_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Policy_Fingerprint
        + Row.Recovery_Fingerprint
        + Row.Schedule_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Audit_Gates (Row, Result);
      Check_Snapshot_Identity (Row, Result);
      Check_Fingerprints (Row, Result);
      Check_Budgets (Row, Result);
      Check_Cancellation (Row, Result);
      Check_Determinism (Row, Result);
      Check_Editor_Invariants (Row, Result);

      if Result.Status = Status_Not_Checked then
         if Row.Budget_Exhausted then
            if Row.Budget_Exhaustion_Classified_Indeterminate
              and then Row.Partial_Evidence_Preserved_On_Budget_Exhaustion
            then
               Result.Status := Status_Indeterminate_Budget_Exceeded;
            elsif not Row.Budget_Exhaustion_Classified_Indeterminate then
               Result.Status := Status_Illegal_Work_Budget_Exceeded_As_Legal;
            else
               Result.Status := Status_Illegal_Stale_Partial_Result_Reused;
            end if;
         elsif Row.Runtime_Check_Context then
            if Row.Runtime_Check_Evidence_Preserved then
               Result.Status := Status_Legal_Runtime_Check_Preserved;
            else
               Result.Status := Status_Illegal_Stale_Partial_Result_Reused;
            end if;
         elsif Row.Work_Cancelled then
            Result.Status := Status_Legal_Work_Cancelled_By_Newer_Request;
         elsif Row.Work_Superseded then
            if Row.Result_Rejected_By_Consumer then
               Result.Status := Status_Legal_Work_Superseded_And_Rejected;
            else
               Result.Status := Status_Illegal_Superseded_Result_Consumed;
            end if;
         elsif Row.Partial_Result_Available then
            if Row.Partial_Result_Preserved then
               Result.Status := Status_Legal_Partial_Result_Preserved;
            else
               Result.Status := Status_Illegal_Stale_Partial_Result_Reused;
            end if;
         elsif Row.Work_Completed then
            Result.Status := Status_Legal_Work_Completed_Within_Budget;
         elsif Row.Deterministic_Work_Order
           and then Row.Deterministic_Blocker_Order
           and then Row.Deterministic_Diagnostic_Order
           and then Row.Deterministic_Outline_Order
         then
            Result.Status := Status_Legal_Deterministic_Order_Preserved;
         else
            case Row.Expected is
               when Precision.Class_Legal =>
                  Result.Status := Status_Legal_Work_Completed_Within_Budget;
               when Precision.Class_Legal_With_Runtime_Check =>
                  Result.Status := Status_Legal_Runtime_Check_Preserved;
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

         if Item.Consumer /= Consumers.Consumer_Unknown then
            Results.Consumer_Count := Results.Consumer_Count + 1;
         end if;
         if Item.Status = Status_Legal_Work_Completed_Within_Budget then
            Results.Completed_Count := Results.Completed_Count + 1;
         elsif Item.Status = Status_Legal_Work_Cancelled_By_Newer_Request then
            Results.Cancelled_Count := Results.Cancelled_Count + 1;
         elsif Item.Status = Status_Legal_Work_Superseded_And_Rejected then
            Results.Superseded_Count := Results.Superseded_Count + 1;
         elsif Item.Status = Status_Indeterminate_Budget_Exceeded then
            Results.Budget_Exceeded_Count := Results.Budget_Exceeded_Count + 1;
         elsif Item.Status = Status_Legal_Deterministic_Order_Preserved then
            Results.Deterministic_Count := Results.Deterministic_Count + 1;
         end if;

         Classification := Expected_For_Status (Item.Status);
         case Classification is
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Legal_With_Runtime_Check =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
            when others =>
               null;
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

   function Bounded_Work_Scheduling_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Bounded_Semantic_Work_Cancellation_Scheduling then
            Saw_Target_Gap := True;
         end if;
         if Item.Blocker_Count /= 0 and then Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap
        and then Results.Completed_Count > 0
        and then Results.Cancelled_Count > 0
        and then Results.Budget_Exceeded_Count > 0
        and then Results.Deterministic_Count > 0
        and then Results.Consumer_Count > 0;
   end Bounded_Work_Scheduling_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1362;
