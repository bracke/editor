with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Inventory_Input; Row : Inventory_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Inventory_Status)
      return Inventory_Result_Class is
   begin
      case Status is
         when Status_Classified_Production
            | Status_Classified_Regression_Evidence
            | Status_Classified_Quarantine
            | Status_Classified_Removal_Candidate =>
            return Class_Accepted;
         when Status_Rejected_Unowned_Active_Legacy
            | Status_Rejected_Removed_Code_Reference
            | Status_Rejected_Production_Alias_Leak
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Owner
            | Status_Indeterminate_Unclassified_Surface =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Fingerprints_Fresh (Row : Inventory_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Inventory_Fingerprint = Row.Expected_Inventory_Fingerprint;
   end Fingerprints_Fresh;

   function Missing_Owner (Row : Inventory_Row) return Boolean is
   begin
      return Length (Row.Package_Name) = 0
        or else Length (Row.Surface_Path) = 0
        or else Length (Row.Canonical_Owner) = 0
        or else Length (Row.Cleanup_Action) = 0
        or else Length (Row.Blocker_Family) = 0;
   end Missing_Owner;

   function Legacy_Family (Family : Scaffold_Family) return Boolean is
   begin
      return Family in Family_Diagnostic_Recovery_Legacy
        | Family_Diagnostic_Command_Legacy
        | Family_Diagnostic_Render_Legacy
        | Family_Repair_Gated_Legacy
        | Family_Remediation_Worklist_Legacy
        | Family_Stabilized_Closure_Legacy;
   end Legacy_Family;

   function Evaluate (Row : Inventory_Row) return Inventory_Status is
   begin
      if Missing_Owner (Row) then
         return Status_Indeterminate_Missing_Owner;
      elsif Row.Classification = Classification_Unknown
        or else Row.Family = Family_Unknown
      then
         return Status_Indeterminate_Unclassified_Surface;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.References_Removed_Code then
         return Status_Rejected_Removed_Code_Reference;
      elsif Row.Adds_Command_Alias then
         return Status_Rejected_Production_Alias_Leak;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      elsif Legacy_Family (Row.Family)
        and then Row.Production_Facing
        and then Row.Classification /= Classification_Remove
        and then Row.Classification /= Classification_Quarantine
      then
         return Status_Rejected_Unowned_Active_Legacy;
      else
         case Row.Classification is
            when Classification_Production =>
               return Status_Classified_Production;
            when Classification_Regression_Evidence =>
               return Status_Classified_Regression_Evidence;
            when Classification_Quarantine =>
               return Status_Classified_Quarantine;
            when Classification_Remove =>
               return Status_Classified_Removal_Candidate;
            when Classification_Unknown =>
               return Status_Indeterminate_Unclassified_Surface;
         end case;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Inventory_Row; Status : Inventory_Status) return Natural is
   begin
      return Row.Id * 101
        + Scaffold_Family'Pos (Row.Family) * 67
        + Scaffold_Classification'Pos (Row.Classification) * 43
        + Inventory_Status'Pos (Status) * 29
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Inventory_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Inventory_Model; Feed_Item : Inventory_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Classified_Production =>
            Model.Production_Count := Model.Production_Count + 1;
         when Status_Classified_Regression_Evidence =>
            Model.Regression_Evidence_Count :=
              Model.Regression_Evidence_Count + 1;
         when Status_Classified_Quarantine =>
            Model.Quarantine_Count := Model.Quarantine_Count + 1;
         when Status_Classified_Removal_Candidate =>
            Model.Removal_Candidate_Count :=
              Model.Removal_Candidate_Count + 1;
         when Status_Rejected_Unowned_Active_Legacy
            | Status_Rejected_Removed_Code_Reference
            | Status_Rejected_Production_Alias_Leak
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Owner
            | Status_Indeterminate_Unclassified_Surface =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Inventory_Input) return Inventory_Model is
      Model : Inventory_Model;
   begin
      for Row of Input.Rows loop
         declare
            Status : constant Inventory_Status := Evaluate (Row);
            Feed_Item : constant Inventory_Entry :=
              (Id => Row.Id,
               Family => Row.Family,
               Classification => Row.Classification,
               Status => Status,
               Result_Class => Class_For_Status (Status),
               Result_Fingerprint => Result_Fingerprint_For (Row, Status));
         begin
            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Inventory_Audit_Fingerprint :=
              Model.Inventory_Audit_Fingerprint + Feed_Item.Result_Fingerprint;
            Tally (Model, Feed_Item);
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Inventory_Model; Id : Natural)
      return Inventory_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (Id => Id,
              Family => Family_Unknown,
              Classification => Classification_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Inventory_Complete (Model : Inventory_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Production_Count > 0
        and then Model.Regression_Evidence_Count > 0
        and then Model.Quarantine_Count > 0
        and then Model.Removal_Candidate_Count > 0
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0;
   end Inventory_Complete;

   function Ready_For_Removal_Passes (Model : Inventory_Model) return Boolean is
   begin
      return Inventory_Complete (Model)
        and then Model.Removal_Candidate_Count >= 4
        and then Model.Quarantine_Count >= 2;
   end Ready_For_Removal_Passes;

end Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440;
