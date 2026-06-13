package body Editor.Ada_RM_Gap_Burn_Down_Pass1356 is

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
                     | Status_Runtime_Finalization_Check_Preserved
                     | Status_Runtime_Check_Evidence_Lost
                     | Status_Illegal_Static_Accessibility_Escape
                     | Status_Illegal_Access_Value_Escapes_Master
                     | Status_Illegal_Return_Access_Escapes_Master
                     | Status_Illegal_Assignment_To_Longer_Lived_Access_Object
                     | Status_Illegal_Access_Discriminant_Escapes_Master
                     | Status_Illegal_Anonymous_Access_Escape
                     | Status_Illegal_Return_Object_Master_Lost
                     | Status_Illegal_Limited_Return_Object_Lifetime_Lost
                     | Status_Illegal_Controlled_Return_Object_Owner_Lost
                     | Status_Illegal_Returned_Aggregate_Component_Escapes
                     | Status_Illegal_Allocator_Lifetime_Evidence_Lost
                     | Status_Illegal_Unchecked_Deallocation_Lifetime_Lost
                     | Status_Illegal_Generic_Substitution_Lifetime_Changed
                     | Status_Illegal_Task_Lifetime_Treated_As_Block
                     | Status_Illegal_Protected_Lifetime_Treated_As_Block
                     | Status_Illegal_Finalization_Owner_Lost
                     | Status_Illegal_Normal_Return_Finalization_Lost
                     | Status_Illegal_Exception_Propagation_Finalization_Lost
                     | Status_Illegal_Task_Abort_Finalization_Lost
                     | Status_Illegal_Aggregate_Assignment_Lifetime_Disagreement
                     | Status_Illegal_Call_Actual_Lifetime_Disagreement
                     | Status_Illegal_Control_Flow_Finalization_Disagreement
                     | Status_Illegal_Accessibility_Slice_Disagreement
                     | Status_Illegal_Diagnostics_Lifetime_Disagreement
                     | Status_Illegal_Colouring_Lifetime_Disagreement
                     | Status_Illegal_Outline_Declaration_Lifetime_Disagreement
                     | Status_Illegal_Navigation_Target_Lifetime_Disagreement
                     | Status_Illegal_Hover_Lifetime_Disagreement
                     | Status_Illegal_Diagnostic_Bridge_Lifetime_Disagreement
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Master_Evidence
                     | Status_Indeterminate_Missing_Lifetime_Evidence
                     | Status_Indeterminate_Missing_Accessibility_Evidence
                     | Status_Indeterminate_Missing_Return_Object_Evidence
                     | Status_Indeterminate_Missing_Finalization_Evidence
                     | Status_Indeterminate_Missing_Allocator_Evidence
                     | Status_Indeterminate_Missing_Generic_Substitution_Evidence
                     | Status_Indeterminate_Missing_Call_Evidence
                     | Status_Indeterminate_Missing_Effect_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Runtime_Accessibility_Check_Preserved
            | Status_Runtime_Finalization_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Static_Accessibility_Escape
            | Status_Illegal_Access_Value_Escapes_Master
            | Status_Illegal_Return_Access_Escapes_Master
            | Status_Illegal_Assignment_To_Longer_Lived_Access_Object
            | Status_Illegal_Access_Discriminant_Escapes_Master
            | Status_Illegal_Anonymous_Access_Escape
            | Status_Illegal_Return_Object_Master_Lost
            | Status_Illegal_Limited_Return_Object_Lifetime_Lost
            | Status_Illegal_Controlled_Return_Object_Owner_Lost
            | Status_Illegal_Returned_Aggregate_Component_Escapes
            | Status_Illegal_Allocator_Lifetime_Evidence_Lost
            | Status_Illegal_Unchecked_Deallocation_Lifetime_Lost
            | Status_Illegal_Generic_Substitution_Lifetime_Changed
            | Status_Illegal_Task_Lifetime_Treated_As_Block
            | Status_Illegal_Protected_Lifetime_Treated_As_Block
            | Status_Illegal_Finalization_Owner_Lost
            | Status_Illegal_Normal_Return_Finalization_Lost
            | Status_Illegal_Exception_Propagation_Finalization_Lost
            | Status_Illegal_Task_Abort_Finalization_Lost
            | Status_Illegal_Aggregate_Assignment_Lifetime_Disagreement
            | Status_Illegal_Call_Actual_Lifetime_Disagreement
            | Status_Illegal_Control_Flow_Finalization_Disagreement
            | Status_Illegal_Accessibility_Slice_Disagreement
            | Status_Illegal_Diagnostics_Lifetime_Disagreement
            | Status_Illegal_Colouring_Lifetime_Disagreement
            | Status_Illegal_Outline_Declaration_Lifetime_Disagreement
            | Status_Illegal_Navigation_Target_Lifetime_Disagreement
            | Status_Illegal_Hover_Lifetime_Disagreement
            | Status_Illegal_Diagnostic_Bridge_Lifetime_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Master_Evidence
            | Status_Indeterminate_Missing_Lifetime_Evidence
            | Status_Indeterminate_Missing_Accessibility_Evidence
            | Status_Indeterminate_Missing_Return_Object_Evidence
            | Status_Indeterminate_Missing_Finalization_Evidence
            | Status_Indeterminate_Missing_Allocator_Evidence
            | Status_Indeterminate_Missing_Generic_Substitution_Evidence
            | Status_Indeterminate_Missing_Call_Evidence
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
      elsif Row.Missing_Master_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Master_Evidence);
      elsif Row.Missing_Lifetime_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Lifetime_Evidence);
      elsif Row.Missing_Accessibility_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Accessibility_Evidence);
      elsif Row.Missing_Return_Object_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Return_Object_Evidence);
      elsif Row.Missing_Finalization_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Finalization_Evidence);
      elsif Row.Missing_Allocator_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Allocator_Evidence);
      elsif Row.Missing_Generic_Substitution_Evidence then
         Add_Blocker
           (Result, Status_Indeterminate_Missing_Generic_Substitution_Evidence);
      elsif Row.Missing_Call_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Call_Evidence);
      elsif Row.Missing_Effect_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Effect_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Lifetime_Rules
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Same_Canonical_Master then
         Add_Blocker (Result, Status_Illegal_Accessibility_Slice_Disagreement);
      elsif Row.Static_Accessibility_Escape then
         Add_Blocker (Result, Status_Illegal_Static_Accessibility_Escape);
      elsif Row.Access_Value_Escapes_Master then
         Add_Blocker (Result, Status_Illegal_Access_Value_Escapes_Master);
      elsif Row.Return_Access_Escapes_Master then
         Add_Blocker (Result, Status_Illegal_Return_Access_Escapes_Master);
      elsif Row.Assignment_To_Longer_Lived_Access_Object then
         Add_Blocker
           (Result, Status_Illegal_Assignment_To_Longer_Lived_Access_Object);
      elsif Row.Access_Discriminant_Escapes_Master then
         Add_Blocker (Result, Status_Illegal_Access_Discriminant_Escapes_Master);
      elsif Row.Anonymous_Access_Escapes_Master then
         Add_Blocker (Result, Status_Illegal_Anonymous_Access_Escape);
      elsif not Row.Return_Object_Master_Preserved then
         Add_Blocker (Result, Status_Illegal_Return_Object_Master_Lost);
      elsif not Row.Limited_Return_Object_Lifetime_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Limited_Return_Object_Lifetime_Lost);
      elsif not Row.Controlled_Return_Object_Owner_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Controlled_Return_Object_Owner_Lost);
      elsif not Row.Returned_Aggregate_Components_Safe then
         Add_Blocker
           (Result, Status_Illegal_Returned_Aggregate_Component_Escapes);
      elsif not Row.Allocator_Lifetime_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Allocator_Lifetime_Evidence_Lost);
      elsif not Row.Unchecked_Deallocation_Lifetime_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Unchecked_Deallocation_Lifetime_Lost);
      elsif not Row.Generic_Substitution_Lifetime_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Generic_Substitution_Lifetime_Changed);
      elsif not Row.Task_Lifetime_Is_Task_Master then
         Add_Blocker (Result, Status_Illegal_Task_Lifetime_Treated_As_Block);
      elsif not Row.Protected_Lifetime_Is_Protected_Master then
         Add_Blocker (Result, Status_Illegal_Protected_Lifetime_Treated_As_Block);
      elsif not Row.Finalization_Owner_Preserved then
         Add_Blocker (Result, Status_Illegal_Finalization_Owner_Lost);
      elsif not Row.Normal_Return_Finalization_Preserved then
         Add_Blocker (Result, Status_Illegal_Normal_Return_Finalization_Lost);
      elsif not Row.Exception_Propagation_Finalization_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Exception_Propagation_Finalization_Lost);
      elsif not Row.Task_Abort_Finalization_Preserved then
         Add_Blocker (Result, Status_Illegal_Task_Abort_Finalization_Lost);
      elsif not Row.Aggregate_Assignment_Lifetime_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Aggregate_Assignment_Lifetime_Disagreement);
      elsif not Row.Call_Actual_Lifetime_Agrees then
         Add_Blocker (Result, Status_Illegal_Call_Actual_Lifetime_Disagreement);
      elsif not Row.Control_Flow_Finalization_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Control_Flow_Finalization_Disagreement);
      elsif not Row.Accessibility_Slice_Agrees then
         Add_Blocker (Result, Status_Illegal_Accessibility_Slice_Disagreement);
      elsif Row.Runtime_Accessibility_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Accessibility_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      elsif Row.Runtime_Finalization_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Finalization_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
   end Check_Lifetime_Rules;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Lifetime_Agrees then
         Add_Blocker (Result, Status_Illegal_Diagnostics_Lifetime_Disagreement);
      elsif not Row.Consumer_Colouring_Agrees then
         Add_Blocker (Result, Status_Illegal_Colouring_Lifetime_Disagreement);
      elsif not Row.Consumer_Declaration_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Outline_Declaration_Lifetime_Disagreement);
      elsif not Row.Consumer_Target_Agrees then
         Add_Blocker (Result, Status_Illegal_Navigation_Target_Lifetime_Disagreement);
      elsif not Row.Consumer_Detail_Agrees then
         Add_Blocker (Result, Status_Illegal_Hover_Lifetime_Disagreement);
      elsif not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Illegal_Diagnostic_Bridge_Lifetime_Disagreement);
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
      if Row.Master_Fingerprint /= Row.Expected_Master_Fingerprint then
         Add_Blocker (Result, Status_Master_Fingerprint_Mismatch);
      end if;
      if Row.Lifetime_Fingerprint /= Row.Expected_Lifetime_Fingerprint then
         Add_Blocker (Result, Status_Lifetime_Fingerprint_Mismatch);
      end if;
      if Row.Accessibility_Fingerprint /= Row.Expected_Accessibility_Fingerprint then
         Add_Blocker (Result, Status_Accessibility_Fingerprint_Mismatch);
      end if;
      if Row.Return_Object_Fingerprint /= Row.Expected_Return_Object_Fingerprint then
         Add_Blocker (Result, Status_Return_Object_Fingerprint_Mismatch);
      end if;
      if Row.Allocation_Fingerprint /= Row.Expected_Allocation_Fingerprint then
         Add_Blocker (Result, Status_Allocation_Fingerprint_Mismatch);
      end if;
      if Row.Finalization_Fingerprint /= Row.Expected_Finalization_Fingerprint then
         Add_Blocker (Result, Status_Finalization_Fingerprint_Mismatch);
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
        + Row.Master_Fingerprint
        + Row.Lifetime_Fingerprint
        + Row.Accessibility_Fingerprint
        + Row.Return_Object_Fingerprint
        + Row.Allocation_Fingerprint
        + Row.Finalization_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Id;

      Check_Audit_Gates (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Lifetime_Rules (Row, Result);
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
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
         end case;
      end loop;
      return Results;
   end Build;

   function Master_Lifetime_Accessibility_Closure_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Master_Lifetime_Accessibility_Closure then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Master_Lifetime_Accessibility_Closure_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1356;
