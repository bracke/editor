package body Editor.Ada_RM_Gap_Burn_Down_Case_1361 is

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
      return Status in Status_Legal_Result_Preserved
        | Status_Legal_Result_Invalidated
        | Status_Legal_Result_Recomputed
        | Status_Legal_Stable_Identity_Preserved
        | Status_Legal_Runtime_Check_Preserved;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Result_Preserved
            | Status_Legal_Result_Invalidated
            | Status_Legal_Result_Recomputed
            | Status_Legal_Stable_Identity_Preserved =>
            return Precision.Class_Legal;
         when Status_Legal_Runtime_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Stale_Semantic_Result_Reused
            | Status_Illegal_Needless_Entity_Identity_Churn
            | Status_Illegal_Diagnostic_From_Old_Request_Token
            | Status_Illegal_Stale_Outline_Or_Navigation_Row
            | Status_Illegal_Stale_Hover_Type_Profile
            | Status_Illegal_Stale_Cross_Unit_Result
            | Status_Illegal_Stale_Generic_Body_Replay
            | Status_Illegal_Stale_Representation_Freezing_Result
            | Status_Illegal_Stale_Recovery_Result
            | Status_Illegal_Consumer_Recomputed_Names_Types_Independently
            | Status_Illegal_File_Save_Reload_During_Analysis
            | Status_Illegal_Dirty_State_Mutation
            | Status_Illegal_Rendering_Side_Parsing
            | Status_Illegal_Command_Keybinding_Workspace_Render_Mutation
            | Status_Illegal_Unbounded_Recomputation
            | Status_Illegal_Result_Not_Invalidated_For_AST_Change
            | Status_Illegal_Result_Not_Invalidated_For_Declaration_Edit
            | Status_Illegal_Result_Not_Invalidated_For_Type_Edit
            | Status_Illegal_Result_Not_Invalidated_For_Generic_Formal_Edit
            | Status_Illegal_Result_Not_Invalidated_For_Context_Clause_Edit
            | Status_Illegal_Result_Not_Invalidated_For_Representation_Edit
            | Status_Illegal_Result_Not_Invalidated_For_Contract_Flow_Edit
            | Status_Illegal_Result_Not_Invalidated_For_Recovery_Shape_Edit
            | Status_Illegal_Diagnostics_Missing_Blocker_Family =>
            return Precision.Class_Illegal;
         when Status_Missing_Remediation_Evidence
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
            | Status_Recovery_Generation_Mismatch
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Unit_Fingerprint_Mismatch
            | Status_Substitution_Fingerprint_Mismatch
            | Status_Effect_Fingerprint_Mismatch
            | Status_Policy_Fingerprint_Mismatch
            | Status_Recovery_Fingerprint_Mismatch
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
      if Row.Recovery_Generation /= Row.Expected_Recovery_Generation then
         Add_Blocker (Result, Status_Recovery_Generation_Mismatch);
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
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

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
      if Row.Unbounded_Recomputation then
         Add_Blocker (Result, Status_Illegal_Unbounded_Recomputation);
      end if;
   end Check_Editor_Invariants;

   procedure Check_Stale_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Stale_Semantic_Result_Reused then
         Add_Blocker (Result, Status_Illegal_Stale_Semantic_Result_Reused);
      end if;
      if Row.Needless_Entity_Identity_Churn then
         Add_Blocker (Result, Status_Illegal_Needless_Entity_Identity_Churn);
      end if;
      if Row.Diagnostic_From_Old_Request_Token then
         Add_Blocker (Result, Status_Illegal_Diagnostic_From_Old_Request_Token);
      end if;
      if Row.Stale_Outline_Or_Navigation_Row then
         Add_Blocker (Result, Status_Illegal_Stale_Outline_Or_Navigation_Row);
      end if;
      if Row.Stale_Hover_Type_Profile then
         Add_Blocker (Result, Status_Illegal_Stale_Hover_Type_Profile);
      end if;
      if Row.Stale_Cross_Unit_Result then
         Add_Blocker (Result, Status_Illegal_Stale_Cross_Unit_Result);
      end if;
      if Row.Stale_Generic_Body_Replay then
         Add_Blocker (Result, Status_Illegal_Stale_Generic_Body_Replay);
      end if;
      if Row.Stale_Representation_Freezing_Result then
         Add_Blocker
           (Result, Status_Illegal_Stale_Representation_Freezing_Result);
      end if;
      if Row.Stale_Recovery_Result then
         Add_Blocker (Result, Status_Illegal_Stale_Recovery_Result);
      end if;
      if Row.Consumer_Recomputed_Names_Types_Independently then
         Add_Blocker
           (Result,
            Status_Illegal_Consumer_Recomputed_Names_Types_Independently);
      end if;
   end Check_Stale_Consumers;

   procedure Check_Dependency_Invalidation
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.AST_Changed and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result, Status_Illegal_Result_Not_Invalidated_For_AST_Change);
      end if;
      if Row.Declaration_Edited and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result,
            Status_Illegal_Result_Not_Invalidated_For_Declaration_Edit);
      end if;
      if Row.Type_Edited and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result, Status_Illegal_Result_Not_Invalidated_For_Type_Edit);
      end if;
      if Row.Generic_Formal_Edited and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result,
            Status_Illegal_Result_Not_Invalidated_For_Generic_Formal_Edit);
      end if;
      if Row.Context_Clause_Edited and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result,
            Status_Illegal_Result_Not_Invalidated_For_Context_Clause_Edit);
      end if;
      if Row.Representation_Edited and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result,
            Status_Illegal_Result_Not_Invalidated_For_Representation_Edit);
      end if;
      if Row.Contract_Flow_Edited and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result,
            Status_Illegal_Result_Not_Invalidated_For_Contract_Flow_Edit);
      end if;
      if Row.Recovery_Shape_Changed and then not Row.Result_Invalidated
        and then not Row.Result_Recomputed
      then
         Add_Blocker
           (Result,
            Status_Illegal_Result_Not_Invalidated_For_Recovery_Shape_Edit);
      end if;
   end Check_Dependency_Invalidation;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Change := Row.Change;
      Result.Result := Row.Result;
      Result.Result_Fingerprint :=
        Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Snapshot_Change_Kind'Pos (Row.Change))
        + Natural (Semantic_Result_Kind'Pos (Row.Result))
        + Row.Buffer_Identity
        + Row.Source_Revision
        + Row.Lifecycle_Generation
        + Row.Request_Token
        + Row.Recovery_Generation
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
      Check_Snapshot_Identity (Row, Result);
      Check_Fingerprints (Row, Result);
      Check_Editor_Invariants (Row, Result);
      Check_Stale_Consumers (Row, Result);
      Check_Dependency_Invalidation (Row, Result);

      if Result.Status = Status_Not_Checked then
         if Row.Runtime_Check_Context then
            if Row.Runtime_Check_Evidence_Preserved then
               Result.Status := Status_Legal_Runtime_Check_Preserved;
            else
               Result.Status := Status_Illegal_Stale_Semantic_Result_Reused;
            end if;
         elsif Row.Result_Recomputed then
            Result.Status := Status_Legal_Result_Recomputed;
         elsif Row.Result_Invalidated then
            Result.Status := Status_Legal_Result_Invalidated;
         elsif Row.Result_Preserved and then Row.Stable_Entity_Identity_Preserved then
            if Row.Unrelated_Edit or else Row.Underlying_Error_Unchanged then
               Result.Status := Status_Legal_Stable_Identity_Preserved;
            else
               Result.Status := Status_Legal_Result_Preserved;
            end if;
         else
            case Row.Expected is
               when Precision.Class_Legal =>
                  Result.Status := Status_Legal_Result_Preserved;
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
         if Item.Status = Status_Legal_Result_Invalidated then
            Results.Invalidated_Count := Results.Invalidated_Count + 1;
         elsif Item.Status = Status_Legal_Result_Recomputed then
            Results.Recomputed_Count := Results.Recomputed_Count + 1;
         elsif Item.Status = Status_Legal_Result_Preserved
           or else Item.Status = Status_Legal_Stable_Identity_Preserved
         then
            Results.Preserved_Count := Results.Preserved_Count + 1;
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

   function Incremental_Invalidation_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Incremental_Snapshot_Semantic_Invalidation then
            Saw_Target_Gap := True;
         end if;
         if Item.Blocker_Count /= 0 and then Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap
        and then Results.Preserved_Count > 0
        and then (Results.Invalidated_Count + Results.Recomputed_Count) > 0
        and then Results.Consumer_Count > 0;
   end Incremental_Invalidation_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Case_1361;
