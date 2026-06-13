with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Legacy_Code_Removal_Pass1438 is

   procedure Add_Row (Input : in out Removal_Input; Row : Removal_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Removal_Status)
      return Removal_Result_Class is
   begin
      case Status is
         when Status_Removed_From_Source_Tree
            | Status_Removed_From_Test_Tree
            | Status_Removed_From_Core_Suite
            | Status_Documented_Removal =>
            return Class_Accepted;
         when Status_Rejected_Active_Source_File
            | Status_Rejected_Active_Test_File
            | Status_Rejected_Core_Suite_Reference
            | Status_Rejected_Replacement_Not_Canonical
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Removal_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Fingerprints_Fresh (Row : Removal_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Suite_Fingerprint = Row.Expected_Suite_Fingerprint
        and then Row.Removal_Fingerprint = Row.Expected_Removal_Fingerprint;
   end Fingerprints_Fresh;

   function Missing_Removal_Evidence (Row : Removal_Row) return Boolean is
   begin
      return Length (Row.Legacy_Path) = 0
        or else Length (Row.Legacy_Package) = 0
        or else Length (Row.Replacement_Owner) = 0
        or else Length (Row.Removal_Reason) = 0
        or else Length (Row.Blocker_Family) = 0;
   end Missing_Removal_Evidence;

   function Evaluate (Row : Removal_Row) return Removal_Status is
   begin
      if Missing_Removal_Evidence (Row) then
         return Status_Indeterminate_Missing_Removal_Evidence;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      elsif not Row.Replacement_Is_Canonical then
         return Status_Rejected_Replacement_Not_Canonical;
      elsif Row.Core_Suite_Reference_Present then
         return Status_Rejected_Core_Suite_Reference;
      elsif Row.Surface in Surface_Source_Spec | Surface_Source_Body then
         if Row.Source_File_Present then
            return Status_Rejected_Active_Source_File;
         else
            return Status_Removed_From_Source_Tree;
         end if;
      elsif Row.Surface in Surface_AUnit_Spec | Surface_AUnit_Body then
         if Row.Test_File_Present then
            return Status_Rejected_Active_Test_File;
         else
            return Status_Removed_From_Test_Tree;
         end if;
      elsif Row.Surface = Surface_Core_Suite_Registration then
         return Status_Removed_From_Core_Suite;
      elsif Row.Surface = Surface_Release_Document then
         if Row.Removal_Document_Present then
            return Status_Documented_Removal;
         else
            return Status_Indeterminate_Missing_Removal_Evidence;
         end if;
      else
         return Status_Indeterminate_Missing_Removal_Evidence;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Removal_Row; Status : Removal_Status) return Natural is
   begin
      return Row.Id * 97
        + Legacy_Surface'Pos (Row.Surface) * 53
        + Removal_Status'Pos (Status) * 31
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Suite_Fingerprint
        + Row.Removal_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Removal_Model; Feed_Item : Removal_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Removed_From_Source_Tree =>
            Model.Removed_Source_Count := Model.Removed_Source_Count + 1;
         when Status_Removed_From_Test_Tree =>
            Model.Removed_Test_Count := Model.Removed_Test_Count + 1;
         when Status_Removed_From_Core_Suite =>
            Model.Removed_Suite_Count := Model.Removed_Suite_Count + 1;
         when Status_Documented_Removal =>
            Model.Documented_Count := Model.Documented_Count + 1;
         when Status_Rejected_Active_Source_File
            | Status_Rejected_Active_Test_File
            | Status_Rejected_Core_Suite_Reference
            | Status_Rejected_Replacement_Not_Canonical
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Fingerprint_Mismatch =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Removal_Evidence =>
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
            Feed_Item : constant Removal_Entry :=
              (Id => Row.Id,
               Surface => Row.Surface,
               Status => Status,
               Result_Class => Class_For_Status (Status),
               Result_Fingerprint => Result_Fingerprint_For (Row, Status));
         begin
            Model.Entries.Append (Feed_Item);
            Model.Total_Rows := Model.Total_Rows + 1;
            Model.Removal_Audit_Fingerprint :=
              Model.Removal_Audit_Fingerprint + Feed_Item.Result_Fingerprint;
            Tally (Model, Feed_Item);
         end;
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Removal_Model; Id : Natural) return Removal_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (Id => Id,
              Surface => Surface_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Legacy_Code_Removal_Achieved (Model : Removal_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Removed_Source_Count >= 2
        and then Model.Removed_Test_Count >= 2
        and then Model.Removed_Suite_Count >= 1
        and then Model.Documented_Count >= 1
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0;
   end Legacy_Code_Removal_Achieved;

end Editor.Ada_Phase579_Legacy_Code_Removal_Pass1438;
