package body Editor.Ada_RM_Gap_Burn_Down_Case_1353 is

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
                     | Status_Warning_Allocation_Restriction_Preserved
                     | Status_Runtime_Accessibility_Check_Preserved
                     | Status_Runtime_Constraint_Check_Preserved
                     | Status_Illegal_Allocator_Missing_Designated_Subtype
                     | Status_Illegal_Allocator_Designated_Subtype_Unavailable
                     | Status_Illegal_Limited_Type_Allocator
                     | Status_Illegal_Controlled_Finalized_Allocator_Hazard
                     | Status_Illegal_Null_Exclusion_Violation
                     | Status_Illegal_Storage_Pool_Missing
                     | Status_Illegal_Storage_Pool_Conflict
                     | Status_Illegal_Storage_Size_Not_Static
                     | Status_Illegal_Storage_Size_Incompatible
                     | Status_Illegal_Storage_Pool_Frozen
                     | Status_Illegal_Storage_Pool_Constraint
                     | Status_Illegal_Representation_Freezing_Disagreement
                     | Status_Illegal_Access_Conversion_Incompatible
                     | Status_Illegal_Static_Accessibility_Escape
                     | Status_Illegal_Access_Discriminant_Escape
                     | Status_Illegal_Anonymous_Access_Assignment_Escape
                     | Status_Illegal_Generic_Access_Substitution_Mismatch
                     | Status_Illegal_Unchecked_Conversion_Profile
                     | Status_Illegal_Unchecked_Deallocation_Incompatible_Access_Type
                     | Status_Illegal_Unchecked_Deallocation_Controlled_Finalized_Hazard
                     | Status_Illegal_Unknown_Restriction
                     | Status_Illegal_Restriction_No_Allocators_Violation
                     | Status_Illegal_Restriction_Warning_Treated_As_Hard_Error
                     | Status_Illegal_Local_Slice_Ignores_Allocation_Policy
                     | Status_Illegal_Generic_Replay_Access_Substitution_Lost
                     | Status_Illegal_Finalization_Evidence_Disagreement
                     | Status_Warning_Restriction_Evidence_Lost
                     | Status_Runtime_Check_Evidence_Lost
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Designated_Subtype_Evidence
                     | Status_Indeterminate_Missing_Storage_Pool_Evidence
                     | Status_Indeterminate_Missing_Lifetime_Evidence
                     | Status_Indeterminate_Missing_Unchecked_Profile_Evidence
                     | Status_Indeterminate_Missing_Size_View_Evidence
                     | Status_Indeterminate_Missing_Policy_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down
            | Status_Gap_Burned_Down
            | Status_Warning_Allocation_Restriction_Preserved =>
            return Precision.Class_Legal;
         when Status_Runtime_Accessibility_Check_Preserved
            | Status_Runtime_Constraint_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Allocator_Missing_Designated_Subtype
            | Status_Illegal_Allocator_Designated_Subtype_Unavailable
            | Status_Illegal_Limited_Type_Allocator
            | Status_Illegal_Controlled_Finalized_Allocator_Hazard
            | Status_Illegal_Null_Exclusion_Violation
            | Status_Illegal_Storage_Pool_Missing
            | Status_Illegal_Storage_Pool_Conflict
            | Status_Illegal_Storage_Size_Not_Static
            | Status_Illegal_Storage_Size_Incompatible
            | Status_Illegal_Storage_Pool_Frozen
            | Status_Illegal_Storage_Pool_Constraint
            | Status_Illegal_Representation_Freezing_Disagreement
            | Status_Illegal_Access_Conversion_Incompatible
            | Status_Illegal_Static_Accessibility_Escape
            | Status_Illegal_Access_Discriminant_Escape
            | Status_Illegal_Anonymous_Access_Assignment_Escape
            | Status_Illegal_Generic_Access_Substitution_Mismatch
            | Status_Illegal_Unchecked_Conversion_Profile
            | Status_Illegal_Unchecked_Deallocation_Incompatible_Access_Type
            | Status_Illegal_Unchecked_Deallocation_Controlled_Finalized_Hazard
            | Status_Illegal_Unknown_Restriction
            | Status_Illegal_Restriction_No_Allocators_Violation
            | Status_Illegal_Restriction_Warning_Treated_As_Hard_Error
            | Status_Illegal_Local_Slice_Ignores_Allocation_Policy
            | Status_Illegal_Generic_Replay_Access_Substitution_Lost
            | Status_Illegal_Finalization_Evidence_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Designated_Subtype_Evidence
            | Status_Indeterminate_Missing_Storage_Pool_Evidence
            | Status_Indeterminate_Missing_Lifetime_Evidence
            | Status_Indeterminate_Missing_Unchecked_Profile_Evidence
            | Status_Indeterminate_Missing_Size_View_Evidence
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
      if Row.Storage_Pool_Fingerprint /= Row.Expected_Storage_Pool_Fingerprint then
         Add_Blocker (Result, Status_Storage_Pool_Fingerprint_Mismatch);
      end if;
      if Row.Lifetime_Fingerprint /= Row.Expected_Lifetime_Fingerprint then
         Add_Blocker (Result, Status_Lifetime_Fingerprint_Mismatch);
      end if;
      if Row.Representation_Fingerprint /= Row.Expected_Representation_Fingerprint then
         Add_Blocker (Result, Status_Representation_Fingerprint_Mismatch);
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
      elsif Row.Missing_Designated_Subtype_Evidence then
         Add_Blocker (Result,
                      Status_Indeterminate_Missing_Designated_Subtype_Evidence);
      elsif Row.Missing_Storage_Pool_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Storage_Pool_Evidence);
      elsif Row.Missing_Lifetime_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Lifetime_Evidence);
      elsif Row.Missing_Unchecked_Profile_Evidence then
         Add_Blocker (Result,
                      Status_Indeterminate_Missing_Unchecked_Profile_Evidence);
      elsif Row.Missing_Size_View_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Size_View_Evidence);
      elsif Row.Missing_Policy_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Policy_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Allocator_Storage_Lifetime_Rules
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Designated_Subtype_Present then
         Add_Blocker (Result, Status_Illegal_Allocator_Missing_Designated_Subtype);
      elsif not Row.Designated_Subtype_Available then
         Add_Blocker
           (Result, Status_Illegal_Allocator_Designated_Subtype_Unavailable);
      elsif not Row.Limited_Type_Allocation_Allowed then
         Add_Blocker (Result, Status_Illegal_Limited_Type_Allocator);
      elsif not Row.Controlled_Finalized_Allocation_Safe then
         Add_Blocker
           (Result, Status_Illegal_Controlled_Finalized_Allocator_Hazard);
      elsif Row.Null_Exclusion_Violation then
         Add_Blocker (Result, Status_Illegal_Null_Exclusion_Violation);
      elsif not Row.Storage_Pool_Present then
         Add_Blocker (Result, Status_Illegal_Storage_Pool_Missing);
      elsif Row.Storage_Pool_Conflict then
         Add_Blocker (Result, Status_Illegal_Storage_Pool_Conflict);
      elsif not Row.Storage_Size_Static then
         Add_Blocker (Result, Status_Illegal_Storage_Size_Not_Static);
      elsif not Row.Storage_Size_Compatible then
         Add_Blocker (Result, Status_Illegal_Storage_Size_Incompatible);
      elsif Row.Storage_Pool_Frozen then
         Add_Blocker (Result, Status_Illegal_Storage_Pool_Frozen);
      elsif not Row.Pool_Specific_Constraints_OK then
         Add_Blocker (Result, Status_Illegal_Storage_Pool_Constraint);
      elsif not Row.Representation_Freezing_Agrees
        or else not Row.Allocator_Consumes_Representation
      then
         Add_Blocker (Result, Status_Illegal_Representation_Freezing_Disagreement);
      elsif not Row.Access_Conversion_Compatible then
         Add_Blocker (Result, Status_Illegal_Access_Conversion_Incompatible);
      elsif Row.Static_Accessibility_Escape then
         Add_Blocker (Result, Status_Illegal_Static_Accessibility_Escape);
      elsif Row.Access_Discriminant_Escape then
         Add_Blocker (Result, Status_Illegal_Access_Discriminant_Escape);
      elsif Row.Anonymous_Access_Assignment_Escape then
         Add_Blocker (Result, Status_Illegal_Anonymous_Access_Assignment_Escape);
      elsif not Row.Generic_Access_Substitution_Agrees then
         Add_Blocker (Result, Status_Illegal_Generic_Access_Substitution_Mismatch);
      elsif not Row.Unchecked_Conversion_Profile_OK then
         Add_Blocker (Result, Status_Illegal_Unchecked_Conversion_Profile);
      elsif not Row.Unchecked_Conversion_Size_View_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Size_View_Evidence);
      elsif not Row.Unchecked_Deallocation_Access_Type_OK then
         Add_Blocker
           (Result, Status_Illegal_Unchecked_Deallocation_Incompatible_Access_Type);
      elsif not Row.Unchecked_Deallocation_Finalization_Safe then
         Add_Blocker
           (Result,
            Status_Illegal_Unchecked_Deallocation_Controlled_Finalized_Hazard);
      elsif not Row.Restriction_Rule_Known then
         Add_Blocker (Result, Status_Illegal_Unknown_Restriction);
      elsif Row.No_Allocators_Restriction_Violation then
         Add_Blocker (Result, Status_Illegal_Restriction_No_Allocators_Violation);
      elsif Row.Restriction_Warning_Treated_As_Hard_Error then
         Add_Blocker
           (Result, Status_Illegal_Restriction_Warning_Treated_As_Hard_Error);
      elsif not Row.Access_Slice_Consumes_Policy then
         Add_Blocker (Result, Status_Illegal_Local_Slice_Ignores_Allocation_Policy);
      elsif not Row.Generic_Replay_Consumes_Access_Actual then
         Add_Blocker (Result,
                      Status_Illegal_Generic_Replay_Access_Substitution_Lost);
      elsif not Row.Finalization_Consumes_Allocation_Evidence then
         Add_Blocker (Result, Status_Illegal_Finalization_Evidence_Disagreement);
      elsif Row.Allocation_Restriction_Warning then
         if Row.Restriction_Warning_Preserved then
            Add_Blocker (Result, Status_Warning_Allocation_Restriction_Preserved);
         else
            Add_Blocker (Result, Status_Warning_Restriction_Evidence_Lost);
         end if;
      elsif Row.Runtime_Accessibility_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Accessibility_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      elsif Row.Runtime_Constraint_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Constraint_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
   end Check_Allocator_Storage_Lifetime_Rules;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Storage_Agrees then
         Add_Blocker (Result, Status_Consumer_Storage_Model_Disagreement);
      elsif not Row.Consumer_Lifetime_Agrees then
         Add_Blocker (Result, Status_Consumer_Lifetime_Model_Disagreement);
      elsif not Row.Consumer_Unchecked_Operation_Agrees then
         Add_Blocker
           (Result, Status_Consumer_Unchecked_Operation_Model_Disagreement);
      elsif not Row.Consumer_Policy_Agrees then
         Add_Blocker (Result, Status_Consumer_Policy_Model_Disagreement);
      elsif not Row.Consumer_Warning_State_Surface then
         Add_Blocker (Result, Status_Consumer_Warning_State_Hidden);
      elsif not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Consumer_Diagnostic_Bridge_Disagreement);
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
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Policy_Fingerprint
        + Row.Storage_Pool_Fingerprint
        + Row.Lifetime_Fingerprint
        + Row.Representation_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Id;

      Check_Audit_Gates (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Allocator_Storage_Lifetime_Rules (Row, Result);
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

         if Feed_Item.Status = Status_Warning_Allocation_Restriction_Preserved then
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

   function Allocator_Storage_Pool_Unchecked_Operations_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Feed_Item of Results.Entries loop
         if Feed_Item.Gap = Gap_Allocator_Storage_Pool_Unchecked_Operations then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Feed_Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Allocator_Storage_Pool_Unchecked_Operations_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Case_1353;
