with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Remaining_Gap_Remediation_Case_1428 is

   pragma Suppress (Overflow_Check);
   use type Matrix.Coverage_Level;
   use type Remediation.Remediation_State;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   Frozen_Remaining_Edge_Count : constant Natural := 9;

   procedure Add_Row (Input : in out Closure_Input; Row : Closure_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Expected_For_Status (Status : Closure_Status)
      return Precision_Classification is
   begin
      case Status is
         when Status_Inventory_Closed | Status_Edge_Closed =>
            return Precision.Class_Legal;
         when Status_Edge_Reopened
            | Status_Missing_Implementation_Package
            | Status_Missing_AUnit_Test
            | Status_Missing_Readme
            | Status_Missing_Suite_Registration
            | Status_New_Edge_After_Freeze
            | Status_Source_Shaped_Evidence_Missing
            | Status_Unstable_Blocker_Family
            | Status_Inventory_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Not_Checked =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   function Evaluate (Row : Closure_Row) return Closure_Status is
   begin
      if not Row.Edge_Closed then
         return Status_Edge_Reopened;
      elsif not Row.Implementation_Package_Present
        or else Length (Row.Candidate_Implementing_Package) = 0
      then
         return Status_Missing_Implementation_Package;
      elsif not Row.AUnit_Test_Present
        or else Length (Row.Candidate_Test_Package) = 0
      then
         return Status_Missing_AUnit_Test;
      elsif not Row.Readme_Present or else Length (Row.Candidate_Readme) = 0 then
         return Status_Missing_Readme;
      elsif not Row.Suite_Registration_Present then
         return Status_Missing_Suite_Registration;
      elsif not Row.No_New_Edge_After_Freeze then
         return Status_New_Edge_After_Freeze;
      elsif not Row.Source_Shaped_Evidence
        or else Length (Row.Concrete_Subrule) = 0
      then
         return Status_Source_Shaped_Evidence_Missing;
      elsif not Row.Stable_Blocker_Family or else Length (Row.Blocker_Family) = 0 then
         return Status_Unstable_Blocker_Family;
      elsif Row.Inventory_Fingerprint /= Row.Expected_Inventory_Fingerprint then
         return Status_Inventory_Fingerprint_Mismatch;
      elsif Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint
        or else not Row.Consumer_Result_Agrees
      then
         return Status_Consumer_Fingerprint_Mismatch;
      elsif Row.Gap = Remaining_Gap_Unknown then
         return Status_Indeterminate;
      elsif Row.Gap = Remaining_Inventory_Closed then
         return Status_Inventory_Closed;
      else
         return Status_Edge_Closed;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Closure_Row; Status : Closure_Status) return Natural is
   begin
      return Row.Id * 97
        + Row.Pass_Number * 41
        + Remediated_Gap_Family'Pos (Row.Gap) * 23
        + Closure_Status'Pos (Status) * 17
        + Row.Inventory_Fingerprint
        + Row.Consumer_Fingerprint;
   end Result_Fingerprint_For;

   function Build (Input : Closure_Input) return Closure_Model is
      Model : Closure_Model;
   begin
      for Row of Input.Rows loop
         declare
            Status : constant Closure_Status := Evaluate (Row);
            Feed_Item : Closure_Entry;
         begin
            Feed_Item.Id := Row.Id;
            Feed_Item.Gap := Row.Gap;
            Feed_Item.Status := Status;
            Feed_Item.Expected := Expected_For_Status (Status);
            Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Audit_Fingerprint := Model.Audit_Fingerprint + Feed_Item.Result_Fingerprint;

            case Status is
               when Status_Edge_Closed =>
                  Model.Closed_Count := Model.Closed_Count + 1;
               when Status_Edge_Reopened =>
                  Model.Reopened_Count := Model.Reopened_Count + 1;
               when Status_Inventory_Closed =>
                  null;
               when others =>
                  Model.Invalid_Count := Model.Invalid_Count + 1;
            end case;
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Closure_Model; Id : Natural)
      return Closure_Entry is
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
              Result_Fingerprint => 0);
   end Result_For;

   function Final_Closure_Achieved (Model : Closure_Model) return Boolean is
   begin
      return Model.Total_Rows = Frozen_Remaining_Edge_Count + 1
        and then Model.Closed_Count = Frozen_Remaining_Edge_Count
        and then Model.Reopened_Count = 0
        and then Model.Invalid_Count = 0;
   end Final_Closure_Achieved;

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1428;
