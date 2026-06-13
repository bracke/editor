with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Pass1368 is

   procedure Add_Blocker
     (Result : in out Remediation_Entry;
      Status : Remediation_Status) is
   begin
      Result.Status := Status;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Expected_For_Status
     (Status : Remediation_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Remediated
            | Status_Legal_Substituted_Aggregate =>
            return Precision.Class_Legal;
         when Status_Runtime_Predicate_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Missing_Discriminant
            | Status_Illegal_Inactive_Variant_Component
            | Status_Illegal_Static_Predicate_Failure
            | Status_Illegal_Full_View_Not_Used_For_Replay
            | Status_Illegal_Aggregate_Consumer_Disagreement
            | Status_Illegal_Generic_Substitution_Lost
            | Status_Illegal_Body_Replay_Uses_Formal_Placeholder
            | Status_Illegal_Discriminant_Compatibility_Lost
            | Status_Illegal_Default_Component_Evidence_Lost
            | Status_Illegal_Variant_Governor_Evidence_Lost
            | Status_Illegal_Predicate_Evidence_Lost
            | Status_Illegal_Consumer_Surface_Disagreement
            | Status_Missing_Pass1366_Inventory_Row
            | Status_Missing_Concrete_Subrule_Name
            | Status_Missing_Candidate_Owner
            | Status_No_New_Legality_Rule
            | Status_Source_Shaped_Evidence_Missing
            | Status_Coverage_Not_Promoted
            | Status_Remediation_State_Not_Covered
            | Status_Final_Gate_Still_Reports_Gap
            | Status_Regression_Corpus_Not_Balanced
            | Status_Semantic_Result_Unconsumed
            | Status_Consumer_Not_Reached
            | Status_Unstable_Blocker_Family =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View_Only
            | Status_Indeterminate_Missing_Substitution_Evidence
            | Status_Indeterminate_Missing_Full_View_Evidence
            | Status_Indeterminate_Missing_Aggregate_Shape
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Stale_Inventory_Evidence
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Aggregate_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Substitution_Fingerprint_Mismatch
            | Status_View_Fingerprint_Mismatch
            | Status_Predicate_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when others =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Check_Remediation_Gates
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if not Row.Inventory_Row_From_Pass1366 then
         Add_Blocker (Result, Status_Missing_Pass1366_Inventory_Row);
      elsif not Row.Named_Concrete_Subrule
        or else Length (Row.Concrete_Subrule) = 0
      then
         Add_Blocker (Result, Status_Missing_Concrete_Subrule_Name);
      elsif not Row.Candidate_Owner_Named
        or else Length (Row.Candidate_Implementing_Package) = 0
      then
         Add_Blocker (Result, Status_Missing_Candidate_Owner);
      elsif not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      elsif not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      elsif not Row.Coverage_Promoted_To_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered
      then
         Add_Blocker (Result, Status_Coverage_Not_Promoted);
      elsif Row.Target_Remediation /= Remediation.State_Covered then
         Add_Blocker (Result, Status_Remediation_State_Not_Covered);
      elsif not Row.Final_Gate_No_Longer_Reports_Gap then
         Add_Blocker (Result, Status_Final_Gate_Still_Reports_Gap);
      elsif not (Row.Legal_Test_Present
                 and Row.Illegal_Test_Present
                 and Row.Runtime_Check_Test_Present
                 and Row.Indeterminate_Test_Present
                 and Row.Consumer_Surfaced_Test_Present)
      then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      elsif not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      elsif not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      elsif not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Remediation_Gates;

   procedure Check_Indeterminate_Evidence
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if Row.Private_View_Only then
         Add_Blocker (Result, Status_Indeterminate_Private_View_Only);
      elsif Row.Missing_Substitution_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Substitution_Evidence);
      elsif Row.Missing_Full_View_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Full_View_Evidence);
      elsif Row.Missing_Aggregate_Shape then
         Add_Blocker (Result, Status_Indeterminate_Missing_Aggregate_Shape);
      elsif Row.Missing_Cross_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      elsif Row.Stale_Inventory_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Stale_Inventory_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Generic_Aggregate_Rule
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if not Row.Substitution_Evidence_Present then
         Add_Blocker (Result, Status_Illegal_Generic_Substitution_Lost);
      elsif not Row.Body_Replay_Uses_Substituted_Actuals then
         Add_Blocker
           (Result, Status_Illegal_Body_Replay_Uses_Formal_Placeholder);
      elsif not Row.Full_View_Used_For_Replay then
         Add_Blocker (Result, Status_Illegal_Full_View_Not_Used_For_Replay);
      elsif not Row.Aggregate_Shape_Complete then
         Add_Blocker (Result, Status_Indeterminate_Missing_Aggregate_Shape);
      elsif not Row.Required_Discriminants_Present then
         Add_Blocker (Result, Status_Illegal_Missing_Discriminant);
      elsif not Row.Discriminant_Compatibility_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Discriminant_Compatibility_Lost);
      elsif not Row.Default_Component_Evidence_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Default_Component_Evidence_Lost);
      elsif not Row.Variant_Governor_Evidence_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Variant_Governor_Evidence_Lost);
      elsif Row.Inactive_Variant_Component then
         Add_Blocker (Result, Status_Illegal_Inactive_Variant_Component);
      elsif Row.Static_Predicate_Failure then
         Add_Blocker (Result, Status_Illegal_Static_Predicate_Failure);
      elsif not Row.Predicate_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Predicate_Evidence_Lost);
      elsif not Row.Aggregate_Consumer_Agrees then
         Add_Blocker (Result, Status_Illegal_Aggregate_Consumer_Disagreement);
      elsif not Row.Consumer_Surface_Agrees then
         Add_Blocker (Result, Status_Illegal_Consumer_Surface_Disagreement);
      elsif Row.Runtime_Predicate_Check then
         Add_Blocker (Result, Status_Runtime_Predicate_Check_Preserved);
      elsif Row.Expected = Precision.Class_Legal_With_Runtime_Check then
         Add_Blocker (Result, Status_Runtime_Predicate_Check_Preserved);
      elsif Row.Expected = Precision.Class_Legal then
         Add_Blocker (Result, Status_Legal_Substituted_Aggregate);
      else
         Add_Blocker (Result, Status_Gap_Remediated);
      end if;
   end Check_Generic_Aggregate_Rule;

   procedure Check_Fingerprints
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      elsif Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      elsif Row.Aggregate_Fingerprint /= Row.Expected_Aggregate_Fingerprint then
         Add_Blocker (Result, Status_Aggregate_Fingerprint_Mismatch);
      elsif Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      elsif Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      elsif Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      elsif Row.View_Fingerprint /= Row.Expected_View_Fingerprint then
         Add_Blocker (Result, Status_View_Fingerprint_Mismatch);
      elsif Row.Predicate_Fingerprint /= Row.Expected_Predicate_Fingerprint then
         Add_Blocker (Result, Status_Predicate_Fingerprint_Mismatch);
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Row_Fingerprint (Row : Remediation_Row) return Natural is
   begin
      return Row.Id
        + Natural (Remediated_Gap_Family'Pos (Row.Gap))
        + Natural (RM_Family'Pos (Row.Family))
        + Natural (Generic_Aggregate_Form'Pos (Row.Form))
        + Natural (Aggregate_Actual_Form'Pos (Row.Actual))
        + Natural (Semantic_Consumer'Pos (Row.Consumer))
        + Natural (Precision_Classification'Pos (Row.Expected))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Aggregate_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.View_Fingerprint
        + Row.Predicate_Fingerprint
        + Row.Consumer_Fingerprint;
   end Row_Fingerprint;

   procedure Add_Row (Input : in out Remediation_Input; Row : Remediation_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Build (Input : Remediation_Input) return Remediation_Model is
      Results : Remediation_Model;
      Item : Remediation_Entry;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := (Id => Row.Id,
                  Gap => Row.Gap,
                  Status => Status_Not_Checked,
                  Expected => Precision.Class_Unknown,
                  Blocker_Count => 0,
                  Result_Fingerprint => 0);

         Check_Remediation_Gates (Row, Item);
         if Item.Status = Status_Not_Checked then
            Check_Indeterminate_Evidence (Row, Item);
         end if;
         if Item.Status = Status_Not_Checked then
            Check_Fingerprints (Row, Item);
         end if;
         if Item.Status = Status_Not_Checked then
            Check_Generic_Aggregate_Rule (Row, Item);
         end if;

         if Item.Status = Status_Not_Checked then
            Item.Status := Status_Gap_Remediated;
         end if;

         Item.Expected := Expected_For_Status (Item.Status);
         Item.Result_Fingerprint := Row_Fingerprint (Row)
           + Natural (Remediation_Status'Pos (Item.Status))
           + Item.Blocker_Count;
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint;

         case Item.Expected is
            when Precision.Class_Legal =>
               Results.Remediated_Count := Results.Remediated_Count + 1;
            when Precision.Class_Legal_With_Runtime_Check =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Invalid_Count := Results.Invalid_Count + 1;
         end case;

         Results.Entries.Append (Item);
      end loop;
      return Results;
   end Build;

   function Count (Results : Remediation_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At (Results : Remediation_Model; Index : Positive)
     return Remediation_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Remediation_Model; Id : Natural)
     return Remediation_Entry is
      Empty : Remediation_Entry;
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return Empty;
   end Result_For;

   function Gap_Remediated (Results : Remediation_Model) return Boolean is
   begin
      return Results.Total_Rows > 0
        and then Results.Invalid_Count = 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Indeterminate_Count > 0
        and then Results.Remediated_Count > 0;
   end Gap_Remediated;

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1368;
