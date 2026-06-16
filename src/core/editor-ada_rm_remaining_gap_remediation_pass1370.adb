with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Pass1370 is

   pragma Suppress (Overflow_Check);
   use type Matrix.Coverage_Level;
   use type Remediation.Remediation_State;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Blocker
     (Result : in out Remediation_Entry;
      Status : Remediation_Status) is
   begin
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Expected_For_Status
     (Status : Remediation_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Remediated
            | Status_Legal_Parallel_Effect_Agreement =>
            return Precision.Class_Legal;
         when Status_Runtime_Tampering_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View_Only
            | Status_Indeterminate_Limited_View_Only
            | Status_Indeterminate_Missing_Iterator_Profile
            | Status_Indeterminate_Missing_Effect_Evidence
            | Status_Indeterminate_Missing_Reduction_Evidence
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Stale_Inventory_Evidence
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Iterator_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Reduction_Fingerprint_Mismatch
            | Status_Effect_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Not_Checked =>
            return Precision.Class_Unknown;
         when others =>
            return Precision.Class_Illegal;
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
      elsif Row.Limited_View_Only then
         Add_Blocker (Result, Status_Indeterminate_Limited_View_Only);
      elsif Row.Missing_Iterator_Profile then
         Add_Blocker (Result, Status_Indeterminate_Missing_Iterator_Profile);
      elsif Row.Missing_Effect_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Effect_Evidence);
      elsif Row.Missing_Reduction_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Reduction_Evidence);
      elsif Row.Missing_Cross_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      elsif Row.Stale_Inventory_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Stale_Inventory_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Fingerprints
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      elsif Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      elsif Row.Iterator_Fingerprint /= Row.Expected_Iterator_Fingerprint then
         Add_Blocker (Result, Status_Iterator_Fingerprint_Mismatch);
      elsif Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      elsif Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      elsif Row.Reduction_Fingerprint /= Row.Expected_Reduction_Fingerprint then
         Add_Blocker (Result, Status_Reduction_Fingerprint_Mismatch);
      elsif Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Parallel_Effect_Rule
     (Row : Remediation_Row;
      Result : in out Remediation_Entry) is
   begin
      if not Row.Iterator_Profile_Present then
         Add_Blocker (Result, Status_Indeterminate_Missing_Iterator_Profile);
      elsif not Row.Iterator_Element_Type_Agrees then
         Add_Blocker (Result, Status_Illegal_Iterator_Element_Type_Mismatch);
      elsif not Row.Reduction_Profile_Present then
         Add_Blocker (Result, Status_Indeterminate_Missing_Reduction_Evidence);
      elsif not Row.Reduction_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Reduction_Profile_Mismatch);
      elsif not Row.Reduction_Seed_Agrees then
         Add_Blocker (Result, Status_Illegal_Reduction_Seed_Mismatch);
      elsif not Row.Combiner_Result_Agrees then
         Add_Blocker (Result, Status_Illegal_Combiner_Result_Mismatch);
      elsif Row.Shared_State_Write_Without_Effect then
         Add_Blocker (Result, Status_Illegal_Parallel_Shared_State_Write);
      elsif Row.Static_Tampering then
         Add_Blocker (Result, Status_Illegal_Container_Tampering_Static);
      elsif not Row.Global_Depends_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Global_Depends_Evidence_Lost);
      elsif not Row.Volatile_Order_Preserved then
         Add_Blocker (Result, Status_Illegal_Volatile_Order_Lost);
      elsif not Row.Atomic_Order_Preserved then
         Add_Blocker (Result, Status_Illegal_Atomic_Order_Lost);
      elsif not Row.Synchronized_Interface_Effect_Agrees then
         Add_Blocker (Result, Status_Illegal_Synchronized_Interface_Effect_Mismatch);
      elsif not Row.Protected_Call_Effect_Preserved then
         Add_Blocker (Result, Status_Illegal_Protected_Call_Effect_Lost);
      elsif not Row.Dispatching_Effect_Join_Preserved then
         Add_Blocker (Result, Status_Illegal_Dispatching_Effect_Join_Lost);
      elsif not Row.Consumer_Surface_Agrees then
         Add_Blocker (Result, Status_Illegal_Consumer_Surface_Disagreement);
      elsif Row.Runtime_Tampering_Check then
         Add_Blocker (Result, Status_Runtime_Tampering_Check_Preserved);
      elsif Row.Expected = Precision.Class_Legal_With_Runtime_Check then
         Add_Blocker (Result, Status_Runtime_Tampering_Check_Preserved);
      elsif Row.Expected = Precision.Class_Legal then
         Add_Blocker (Result, Status_Legal_Parallel_Effect_Agreement);
      else
         Add_Blocker (Result, Status_Gap_Remediated);
      end if;
   end Check_Parallel_Effect_Rule;

   function Row_Fingerprint (Row : Remediation_Row) return Natural is
   begin
      return Row.Id
        + Natural (Remediated_Gap_Family'Pos (Row.Gap))
        + Natural (RM_Family'Pos (Row.Family))
        + Natural (Parallel_Item_Form'Pos (Row.Form))
        + Natural (Parallel_Effect_Form'Pos (Row.Effect))
        + Natural (Semantic_Consumer'Pos (Row.Consumer))
        + Natural (Precision_Classification'Pos (Row.Expected))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Iterator_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Reduction_Fingerprint
        + Row.Effect_Fingerprint
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
            Check_Parallel_Effect_Rule (Row, Item);
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

   function Result_For
     (Model : Remediation_Model;
      Id : Natural) return Remediation_Entry is
   begin
      for Item of Model.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (Id => Id,
              Gap => Remaining_Gap_Unknown,
              Status => Status_Not_Checked,
              Expected => Precision.Class_Unknown,
              Blocker_Count => 0,
              Result_Fingerprint => 0);
   end Result_For;

   function Gap_Remediated (Model : Remediation_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Remediated_Count > 0
        and then Model.Illegal_Count > 0
        and then Model.Runtime_Check_Count > 0
        and then Model.Indeterminate_Count > 0
        and then Model.Invalid_Count = 0;
   end Gap_Remediated;

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1370;
