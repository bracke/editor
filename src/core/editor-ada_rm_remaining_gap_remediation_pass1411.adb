with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Pass1411 is

   pragma Suppress (Overflow_Check);
   use type Matrix.Coverage_Level;
   use type Remediation.Remediation_State;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Row (Input : in out Remediation_Input; Row : Remediation_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Expected_For_Status (Status : Remediation_Status)
      return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Remediated
            | Status_Task_Termination_Abort_Finalization_Resolved
            | Status_Warning_Only_Preserved =>
            return Precision.Class_Legal;
         when Status_Runtime_Abort_Finalization_Check_Preserved =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Abort_Finalization_Order
            | Status_Illegal_Termination_Dependent_Master
            | Status_Illegal_Asynchronous_Select_Finalization_Hazard
            | Status_Illegal_Controlled_Finalization_Double_Finalize
            | Status_Illegal_Protected_Finalization_Blocking =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Missing_Termination_Evidence
            | Status_Indeterminate_Missing_Finalization_Evidence
            | Status_Indeterminate_Stale_Lifecycle_Evidence
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
            | Status_Unstable_Blocker_Family
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Task_Fingerprint_Mismatch
            | Status_Master_Fingerprint_Mismatch
            | Status_Finalization_Fingerprint_Mismatch
            | Status_Effect_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Multiple_Blockers
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Not_Checked =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   function Fingerprints_Fresh (Row : Remediation_Row) return Remediation_Status is
   begin
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         return Status_Source_Fingerprint_Mismatch;
      elsif Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         return Status_AST_Fingerprint_Mismatch;
      elsif Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         return Status_Type_Fingerprint_Mismatch;
      elsif Row.Task_Fingerprint /= Row.Expected_Task_Fingerprint then
         return Status_Task_Fingerprint_Mismatch;
      elsif Row.Master_Fingerprint /= Row.Expected_Master_Fingerprint then
         return Status_Master_Fingerprint_Mismatch;
      elsif Row.Finalization_Fingerprint /= Row.Expected_Finalization_Fingerprint then
         return Status_Finalization_Fingerprint_Mismatch;
      elsif Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         return Status_Effect_Fingerprint_Mismatch;
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         return Status_Consumer_Fingerprint_Mismatch;
      else
         return Status_Not_Checked;
      end if;
   end Fingerprints_Fresh;

   function Gate_Status (Row : Remediation_Row) return Remediation_Status is
      FP_Status : constant Remediation_Status := Fingerprints_Fresh (Row);
   begin
      if not Row.Inventory_Row_From_Pass1366 then
         return Status_Missing_Pass1366_Inventory_Row;
      elsif not Row.Named_Concrete_Subrule
        or else Length (Row.Concrete_Subrule) = 0
      then
         return Status_Missing_Concrete_Subrule_Name;
      elsif not Row.Candidate_Owner_Named
        or else Length (Row.Candidate_Implementing_Package) = 0
        or else Length (Row.Candidate_Pass) = 0
      then
         return Status_Missing_Candidate_Owner;
      elsif not Row.New_Legality_Rule_Added then
         return Status_No_New_Legality_Rule;
      elsif not Row.Source_Shaped_Evidence then
         return Status_Source_Shaped_Evidence_Missing;
      elsif not Row.Coverage_Promoted_To_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered
      then
         return Status_Coverage_Not_Promoted;
      elsif Row.Target_Remediation /= Remediation.State_Covered then
         return Status_Remediation_State_Not_Covered;
      elsif not Row.Final_Gate_No_Longer_Reports_Gap then
         return Status_Final_Gate_Still_Reports_Gap;
      elsif not (Row.Legal_Test_Present
                 and Row.Illegal_Test_Present
                 and Row.Runtime_Check_Test_Present
                 and Row.Warning_Only_Test_Present
                 and Row.Indeterminate_Test_Present
                 and Row.Consumer_Surfaced_Test_Present)
      then
         return Status_Regression_Corpus_Not_Balanced;
      elsif not Row.Semantic_Result_Consumed then
         return Status_Semantic_Result_Unconsumed;
      elsif not Row.Consumer_Reached
        or else not Row.Consumer_Finalization_State_Agrees
      then
         return Status_Consumer_Not_Reached;
      elsif not Row.Stable_Blocker_Family or else Length (Row.Blocker_Family) = 0 then
         return Status_Unstable_Blocker_Family;
      elsif FP_Status /= Status_Not_Checked then
         return FP_Status;
      else
         return Status_Not_Checked;
      end if;
   end Gate_Status;

   function Evaluate (Row : Remediation_Row) return Remediation_Status is
      Status : constant Remediation_Status := Gate_Status (Row);
   begin
      if Status /= Status_Not_Checked then
         return Status;
      elsif Row.Stale_Lifecycle_Evidence then
         return Status_Indeterminate_Stale_Lifecycle_Evidence;
      elsif Row.Missing_Full_View then
         return Status_Indeterminate_Private_View;
      elsif Row.Missing_Termination_Evidence
        or else not Row.Complete_Task_Termination_Evidence
      then
         return Status_Indeterminate_Missing_Termination_Evidence;
      elsif Row.Missing_Finalization_Evidence
        or else not Row.Complete_Finalization_Evidence
      then
         return Status_Indeterminate_Missing_Finalization_Evidence;
      elsif Row.Abort_Finalization_Order_Hazard then
         return Status_Illegal_Abort_Finalization_Order;
      elsif Row.Termination_Dependent_Master_Hazard then
         return Status_Illegal_Termination_Dependent_Master;
      elsif Row.Async_Select_Finalization_Hazard then
         return Status_Illegal_Asynchronous_Select_Finalization_Hazard;
      elsif Row.Controlled_Finalization_Double_Finalize then
         return Status_Illegal_Controlled_Finalization_Double_Finalize;
      elsif Row.Protected_Finalization_Blocking then
         return Status_Illegal_Protected_Finalization_Blocking;
      elsif Row.Runtime_Abort_Finalization_Check_Preserved
        or else Row.Form = Form_Runtime_Abort_Finalization_Check_Preserved
      then
         return Status_Runtime_Abort_Finalization_Check_Preserved;
      elsif Row.Warning_Only_Preserved
        or else Row.Form = Form_Warning_Only_Preserved
      then
         return Status_Warning_Only_Preserved;
      elsif Row.Gap = Remaining_Task_Termination_Abort_Finalization_Edge then
         return Status_Task_Termination_Abort_Finalization_Resolved;
      else
         return Status_Indeterminate;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Remediation_Row; Status : Remediation_Status) return Natural is
   begin
      return Row.Id * 53
        + Remediation_Status'Pos (Status) * 23
        + Remediated_Gap_Family'Pos (Row.Gap) * 17
        + Task_Termination_Abort_Form'Pos (Row.Form) * 11
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Task_Fingerprint
        + Row.Master_Fingerprint
        + Row.Finalization_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;
   end Result_Fingerprint_For;

   function Build (Input : Remediation_Input) return Remediation_Model is
      Model : Remediation_Model;
   begin
      for Row of Input.Rows loop
         declare
            Status : constant Remediation_Status := Evaluate (Row);
            Feed_Item : Remediation_Entry;
         begin
            Feed_Item.Id := Row.Id;
            Feed_Item.Gap := Row.Gap;
            Feed_Item.Status := Status;
            Feed_Item.Expected := Expected_For_Status (Status);
            Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
            if Status in Status_Missing_Pass1366_Inventory_Row .. Status_Multiple_Blockers then
               Feed_Item.Blocker_Count := 1;
            end if;
            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Audit_Fingerprint := Model.Audit_Fingerprint + Feed_Item.Result_Fingerprint;

            case Feed_Item.Expected is
               when Precision.Class_Legal =>
                  if Status = Status_Warning_Only_Preserved then
                     Model.Warning_Count := Model.Warning_Count + 1;
                  else
                     Model.Remediated_Count := Model.Remediated_Count + 1;
                  end if;
               when Precision.Class_Illegal =>
                  Model.Illegal_Count := Model.Illegal_Count + 1;
               when Precision.Class_Legal_With_Runtime_Check =>
                  Model.Runtime_Check_Count := Model.Runtime_Check_Count + 1;
               when Precision.Class_Indeterminate =>
                  Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
               when others =>
                  Model.Invalid_Count := Model.Invalid_Count + 1;
            end case;
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Remediation_Model; Id : Natural)
      return Remediation_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
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
        and then Model.Runtime_Check_Count > 0
        and then Model.Warning_Count > 0
        and then Model.Illegal_Count > 0
        and then Model.Indeterminate_Count > 0
        and then Model.Invalid_Count = 0;
   end Gap_Remediated;

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1411;
