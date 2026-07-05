package body Editor.Ada_RM_Gap_Burn_Down_Case_1363 is

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
      return Status in Status_Legal_Open_Buffer_Snapshot_Precedence
        | Status_Legal_Project_Index_Closure
        | Status_Legal_Cross_Buffer_Invalidation
        | Status_Legal_Stable_Unrelated_Edit_Preserved
        | Status_Legal_Missing_File_Blocked;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Open_Buffer_Snapshot_Precedence
            | Status_Legal_Project_Index_Closure
            | Status_Legal_Cross_Buffer_Invalidation
            | Status_Legal_Stable_Unrelated_Edit_Preserved =>
            return Precision.Class_Legal;
         when Status_Illegal_Disk_Text_Used_For_Open_Buffer
            | Status_Illegal_Scratch_Buffer_Became_Library_Unit
            | Status_Illegal_Missing_File_Treated_As_Empty_Unit
            | Status_Illegal_Duplicate_Library_Unit_Accepted
            | Status_Illegal_Private_Child_Visibility_Leak
            | Status_Illegal_Context_Lookup_Bypassed_Index
            | Status_Illegal_Consumer_Resolved_Cross_Unit_Independently
            | Status_Illegal_Dependent_Spec_Not_Invalidated
            | Status_Illegal_Body_Availability_Not_Invalidated
            | Status_Illegal_Private_View_Not_Invalidated
            | Status_Illegal_Generic_Instances_Not_Invalidated
            | Status_Illegal_File_Identity_Not_Invalidated
            | Status_Illegal_Stale_Project_Index_Row_Used
            | Status_Illegal_Stale_Cross_Unit_Closure_Used
            | Status_Illegal_Stale_Consumer_Feed_Used
            | Status_Illegal_Spec_Body_Pairing_Stale_Reused
            | Status_Illegal_Open_Buffer_Identity_Churn
            | Status_Illegal_Diagnostics_Missing_Blocker_Family
            | Status_Illegal_File_Save_Reload_During_Analysis
            | Status_Illegal_Dirty_State_Mutation
            | Status_Illegal_Rendering_Side_Parsing
            | Status_Illegal_Command_Keybinding_Workspace_Render_Mutation =>
            return Precision.Class_Illegal;
         when Status_Legal_Missing_File_Blocked
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
            | Status_Project_Index_Row_Missing
            | Status_Unit_Name_Mismatch
            | Status_Spec_Body_Pairing_Missing
            | Status_Child_Index_Missing
            | Status_Separate_Subunit_Index_Missing
            | Status_Missing_File_Blocker_Missing
            | Status_Open_Buffer_Precedence_Missing
            | Status_Dirty_Buffer_Snapshot_Missing
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Buffer_Fingerprint_Mismatch
            | Status_Project_Fingerprint_Mismatch
            | Status_Index_Fingerprint_Mismatch
            | Status_Unit_Fingerprint_Mismatch
            | Status_View_Fingerprint_Mismatch
            | Status_Closure_Fingerprint_Mismatch
            | Status_Substitution_Fingerprint_Mismatch
            | Status_Effect_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Indeterminate_Stale_Project_Evidence
            | Status_Indeterminate_Missing_Project_Source
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Not_Checked
            | Status_Gap_Burned_Down
            | Status_Unexpected_Classification
            | Status_Multiple_Blockers =>
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

   procedure Check_Source_Ownership
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Source in Source_Open_Buffer | Source_Dirty_Open_Buffer
        and then not Row.Open_Buffer_Precedence
      then
         Add_Blocker (Result, Status_Open_Buffer_Precedence_Missing);
      end if;

      if Row.Source = Source_Dirty_Open_Buffer
        and then not Row.Dirty_Buffer_Uses_Snapshot
      then
         Add_Blocker (Result, Status_Dirty_Buffer_Snapshot_Missing);
      end if;

      if Row.Disk_Text_Used_For_Open_Buffer then
         Add_Blocker (Result, Status_Illegal_Disk_Text_Used_For_Open_Buffer);
      end if;

      if Row.Scratch_Became_Library_Unit then
         Add_Blocker (Result, Status_Illegal_Scratch_Buffer_Became_Library_Unit);
      end if;

      if Row.Missing_File_Treated_As_Empty_Unit then
         Add_Blocker (Result, Status_Illegal_Missing_File_Treated_As_Empty_Unit);
      end if;

      if Row.Source in Source_Missing_File | Source_Deleted_File
        and then not Row.Missing_File_Blocker_Preserved
      then
         Add_Blocker (Result, Status_Missing_File_Blocker_Missing);
      end if;
   end Check_Source_Ownership;

   procedure Check_Project_Index
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Project_Index_Row_Present then
         Add_Blocker (Result, Status_Project_Index_Row_Missing);
      end if;
      if not Row.Unit_Name_Matches_Source then
         Add_Blocker (Result, Status_Unit_Name_Mismatch);
      end if;
      if Row.Duplicate_Library_Unit and then not Row.Duplicate_Unit_Rejected then
         Add_Blocker (Result, Status_Illegal_Duplicate_Library_Unit_Accepted);
      end if;
      if Row.Role in Role_Package_Body | Role_Subprogram_Body | Role_Generic_Body
        and then not Row.Spec_Body_Paired
      then
         Add_Blocker (Result, Status_Spec_Body_Pairing_Missing);
      end if;
      if Row.Spec_Body_Pairing_Stale then
         Add_Blocker (Result, Status_Illegal_Spec_Body_Pairing_Stale_Reused);
      end if;
      if Row.Role in Role_Child_Unit | Role_Private_Child
        and then not Row.Child_Index_Present
      then
         Add_Blocker (Result, Status_Child_Index_Missing);
      end if;
      if Row.Private_Child_Visibility_Leaked then
         Add_Blocker (Result, Status_Illegal_Private_Child_Visibility_Leak);
      end if;
      if Row.Role = Role_Separate_Subunit
        and then not Row.Separate_Subunit_Indexed
      then
         Add_Blocker (Result, Status_Separate_Subunit_Index_Missing);
      end if;
      if not Row.Context_Lookup_Uses_Index then
         Add_Blocker (Result, Status_Illegal_Context_Lookup_Bypassed_Index);
      end if;
      if Row.Consumer_Resolved_Independently then
         Add_Blocker
           (Result,
            Status_Illegal_Consumer_Resolved_Cross_Unit_Independently);
      end if;
   end Check_Project_Index;

   procedure Check_Invalidation
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      case Row.Invalidation is
         when Invalidation_Spec_Edit =>
            if not Row.Dependent_Spec_Invalidated then
               Add_Blocker (Result, Status_Illegal_Dependent_Spec_Not_Invalidated);
            end if;
         when Invalidation_Body_Edit =>
            if not Row.Body_Availability_Invalidated then
               Add_Blocker
                 (Result, Status_Illegal_Body_Availability_Not_Invalidated);
            end if;
         when Invalidation_Private_Part_Edit =>
            if not Row.Private_View_Invalidated then
               Add_Blocker (Result, Status_Illegal_Private_View_Not_Invalidated);
            end if;
         when Invalidation_Generic_Spec_Edit =>
            if not Row.Generic_Instances_Invalidated then
               Add_Blocker
                 (Result, Status_Illegal_Generic_Instances_Not_Invalidated);
            end if;
         when Invalidation_Context_Clause_Edit
            | Invalidation_File_Delete_Or_Rename =>
            if not Row.File_Identity_Invalidated then
               Add_Blocker (Result, Status_Illegal_File_Identity_Not_Invalidated);
            end if;
         when Invalidation_Unrelated_Edit =>
            if not Row.Stable_Entity_Identity_Preserved then
               Add_Blocker (Result, Status_Illegal_Open_Buffer_Identity_Churn);
            end if;
         when others =>
            null;
      end case;

      if Row.Stale_Project_Index_Row_Used then
         Add_Blocker (Result, Status_Illegal_Stale_Project_Index_Row_Used);
      end if;
      if Row.Cross_Unit_Closure_Stale then
         Add_Blocker (Result, Status_Illegal_Stale_Cross_Unit_Closure_Used);
      end if;
      if Row.Consumer_Feed_Stale then
         Add_Blocker (Result, Status_Illegal_Stale_Consumer_Feed_Used);
      end if;
   end Check_Invalidation;

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
      if Row.Buffer_Fingerprint /= Row.Expected_Buffer_Fingerprint then
         Add_Blocker (Result, Status_Buffer_Fingerprint_Mismatch);
      end if;
      if Row.Project_Fingerprint /= Row.Expected_Project_Fingerprint then
         Add_Blocker (Result, Status_Project_Fingerprint_Mismatch);
      end if;
      if Row.Index_Fingerprint /= Row.Expected_Index_Fingerprint then
         Add_Blocker (Result, Status_Index_Fingerprint_Mismatch);
      end if;
      if Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Add_Blocker (Result, Status_Unit_Fingerprint_Mismatch);
      end if;
      if Row.View_Fingerprint /= Row.Expected_View_Fingerprint then
         Add_Blocker (Result, Status_View_Fingerprint_Mismatch);
      end if;
      if Row.Closure_Fingerprint /= Row.Expected_Closure_Fingerprint then
         Add_Blocker (Result, Status_Closure_Fingerprint_Mismatch);
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
      Result.Source := Row.Source;
      Result.Role := Row.Role;
      Result.Invalidation := Row.Invalidation;
      Result.Result_Fingerprint :=
        Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Source_Origin'Pos (Row.Source))
        + Natural (Unit_Role'Pos (Row.Role))
        + Natural (Invalidation_Kind'Pos (Row.Invalidation))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Buffer_Fingerprint
        + Row.Project_Fingerprint
        + Row.Index_Fingerprint
        + Row.Unit_Fingerprint
        + Row.View_Fingerprint
        + Row.Closure_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Audit_Gates (Row, Result);
      Check_Source_Ownership (Row, Result);
      Check_Project_Index (Row, Result);
      Check_Invalidation (Row, Result);
      Check_Fingerprints (Row, Result);
      Check_Editor_Invariants (Row, Result);

      if Result.Status = Status_Not_Checked then
         if Row.Source in Source_Missing_File | Source_Deleted_File then
            if Row.Missing_File_Blocker_Preserved then
               Result.Status := Status_Legal_Missing_File_Blocked;
            else
               Result.Status := Status_Indeterminate_Missing_Project_Source;
            end if;
         elsif Row.Source in Source_Open_Buffer | Source_Dirty_Open_Buffer then
            Result.Status := Status_Legal_Open_Buffer_Snapshot_Precedence;
         elsif Row.Invalidation = Invalidation_Unrelated_Edit then
            Result.Status := Status_Legal_Stable_Unrelated_Edit_Preserved;
         elsif Row.Invalidation /= Invalidation_None
           and then Row.Invalidation /= Invalidation_Unknown
         then
            Result.Status := Status_Legal_Cross_Buffer_Invalidation;
         elsif Row.Stale_Project_Index_Row_Used
           or else Row.Cross_Unit_Closure_Stale
           or else Row.Consumer_Feed_Stale
         then
            Result.Status := Status_Indeterminate_Stale_Project_Evidence;
         else
            case Row.Expected is
               when Precision.Class_Legal =>
                  Result.Status := Status_Legal_Project_Index_Closure;
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

         case Item.Status is
            when Status_Legal_Open_Buffer_Snapshot_Precedence =>
               Results.Open_Buffer_Precedence_Count :=
                 Results.Open_Buffer_Precedence_Count + 1;
            when Status_Legal_Project_Index_Closure =>
               Results.Project_Index_Count := Results.Project_Index_Count + 1;
            when Status_Legal_Cross_Buffer_Invalidation =>
               Results.Invalidation_Count := Results.Invalidation_Count + 1;
            when Status_Legal_Missing_File_Blocked =>
               Results.Missing_File_Blocker_Count :=
                 Results.Missing_File_Blocker_Count + 1;
            when Status_Legal_Stable_Unrelated_Edit_Preserved =>
               Results.Stable_Preservation_Count :=
                 Results.Stable_Preservation_Count + 1;
            when others =>
               null;
         end case;

         Classification := Expected_For_Status (Item.Status);
         case Classification is
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
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

   function Project_Index_Multi_Buffer_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Project_Semantic_Index_Multi_Buffer_Closure then
            Saw_Target_Gap := True;
         end if;
         if Item.Blocker_Count /= 0 and then Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap
        and then Results.Open_Buffer_Precedence_Count > 0
        and then Results.Project_Index_Count > 0
        and then Results.Invalidation_Count > 0
        and then Results.Missing_File_Blocker_Count > 0
        and then Results.Stable_Preservation_Count > 0
        and then Results.Consumer_Count > 0;
   end Project_Index_Multi_Buffer_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Case_1363;
