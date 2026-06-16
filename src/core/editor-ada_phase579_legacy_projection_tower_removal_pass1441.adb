with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Removal_Input; Row : Removal_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Removal_Status)
      return Removal_Result_Class is
   begin
      case Status is
         when Status_Removed_From_Active_Source
            | Status_Removed_From_Active_Test
            | Status_Removed_From_Source_And_Test
            | Status_Kept_As_Historical_Documentation =>
            return Class_Accepted;
         when Status_Rejected_Active_Source_Remains
            | Status_Rejected_Active_Test_Remains
            | Status_Rejected_Core_Suite_Reference_Remains
            | Status_Rejected_Dangling_Dependent_Source
            | Status_Rejected_Noncanonical_Replacement
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Unowned_Surface =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Missing_Owner (Row : Removal_Row) return Boolean is
   begin
      return Length (Row.Package_Name) = 0
        or else Length (Row.Canonical_Owner) = 0
        or else Length (Row.Replacement_Surface) = 0
        or else Length (Row.Blocker_Family) = 0;
   end Missing_Owner;

   function Fingerprints_Fresh (Row : Removal_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Removal_Fingerprint = Row.Expected_Removal_Fingerprint;
   end Fingerprints_Fresh;

   function Evaluate (Row : Removal_Row) return Removal_Status is
   begin
      if Missing_Owner (Row) or else Row.Family = Family_Unknown then
         return Status_Indeterminate_Unowned_Surface;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.Noncanonical_Replacement then
         return Status_Rejected_Noncanonical_Replacement;
      elsif Row.Core_Suite_Reference_Remains then
         return Status_Rejected_Core_Suite_Reference_Remains;
      elsif Row.Dangling_Dependent_Source then
         return Status_Rejected_Dangling_Dependent_Source;
      elsif Row.Active_Source_Remains then
         return Status_Rejected_Active_Source_Remains;
      elsif Row.Active_Test_Remains then
         return Status_Rejected_Active_Test_Remains;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      elsif Row.Historical_Documentation_Only then
         return Status_Kept_As_Historical_Documentation;
      elsif Length (Row.Source_Path) > 0 and then Length (Row.Test_Path) > 0 then
         return Status_Removed_From_Source_And_Test;
      elsif Length (Row.Source_Path) > 0 then
         return Status_Removed_From_Active_Source;
      elsif Length (Row.Test_Path) > 0 then
         return Status_Removed_From_Active_Test;
      else
         return Status_Indeterminate_Unowned_Surface;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Removal_Row; Status : Removal_Status) return Natural is
   begin
      return Row.Id * 109
        + Removed_Surface_Family'Pos (Row.Family) * 71
        + Removal_Status'Pos (Status) * 37
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Removal_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Removal_Model; Feed_Item : Removal_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Removed_From_Active_Source =>
            Model.Removed_Source_Count := Model.Removed_Source_Count + 1;
         when Status_Removed_From_Active_Test =>
            Model.Removed_Test_Count := Model.Removed_Test_Count + 1;
         when Status_Removed_From_Source_And_Test =>
            Model.Removed_Source_Count := Model.Removed_Source_Count + 1;
            Model.Removed_Test_Count := Model.Removed_Test_Count + 1;
         when Status_Kept_As_Historical_Documentation =>
            Model.Historical_Documentation_Count :=
              Model.Historical_Documentation_Count + 1;
         when Status_Rejected_Active_Source_Remains
            | Status_Rejected_Active_Test_Remains
            | Status_Rejected_Core_Suite_Reference_Remains
            | Status_Rejected_Dangling_Dependent_Source
            | Status_Rejected_Noncanonical_Replacement
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Unowned_Surface =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Removal_Input) return Removal_Model is
      Model : Removal_Model;
   begin
      for Row of Input.Rows loop
         declare
            Status : constant Removal_Status := Evaluate (Row);
            Feed_Item : Removal_Entry;
         begin
            Feed_Item.Id := Row.Id;
            Feed_Item.Family := Row.Family;
            Feed_Item.Status := Status;
            Feed_Item.Result_Class := Class_For_Status (Status);
            Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Removal_Audit_Fingerprint :=
              Model.Removal_Audit_Fingerprint + Feed_Item.Result_Fingerprint;
            Tally (Model, Feed_Item);
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Removal_Model; Id : Natural)
      return Removal_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Removal_Batch_Clean (Model : Removal_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Removed_Source_Count >= 18
        and then Model.Removed_Test_Count >= 18
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Removal_Audit_Fingerprint /= 0;
   end Removal_Batch_Clean;

end Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441;
