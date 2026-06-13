with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446 is

   procedure Add_Row (Input : in out Closure_Input; Row : Closure_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Evidence_Status) return Evidence_Class is
   begin
      case Status is
         when Status_Accepted =>
            return Class_Accepted;
         when Status_Rejected_Missing_Test
            | Status_Rejected_Missing_Documentation
            | Status_Rejected_Unclassified_Legacy
            | Status_Rejected_Removed_Surface_Reference
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Speculative_Cleanup
            | Status_Rejected_Fingerprint_Mismatch =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Owner =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Has_Required_Text (Row : Closure_Row) return Boolean is
   begin
      return Length (Row.Name) > 0
        and then Length (Row.Canonical_Owner) > 0
        and then Length (Row.Reason) > 0
        and then Length (Row.Blocker_Family) > 0;
   end Has_Required_Text;

   function Fingerprints_Fresh (Row : Closure_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Document_Fingerprint = Row.Expected_Document_Fingerprint
        and then Row.Cleanup_Fingerprint = Row.Expected_Cleanup_Fingerprint;
   end Fingerprints_Fresh;

   function Evaluate (Row : Closure_Row) return Evidence_Status is
   begin
      if not Has_Required_Text (Row) then
         return Status_Indeterminate_Missing_Owner;
      elsif Row.Reopened_Remaining_Gap_Absent = False then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.Removed_Surface_References_Absent = False then
         return Status_Rejected_Removed_Surface_Reference;
      elsif Row.Speculative_Cleanup_Absent = False then
         return Status_Rejected_Speculative_Cleanup;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Fingerprint_Mismatch;
      elsif not Row.Has_Test or else not Row.Has_Core_Suite_Registration then
         return Status_Rejected_Missing_Test;
      elsif not Row.Has_Readme or else not Row.Has_Release_Document then
         return Status_Rejected_Missing_Documentation;
      elsif not Row.Inventory_Classified then
         return Status_Rejected_Unclassified_Legacy;
      end if;

      case Row.Item is
         when Item_API_Consolidation | Item_Closure =>
            if not Row.Has_Source or else not Row.Production_Surface_Canonical then
               return Status_Rejected_Unclassified_Legacy;
            end if;
         when others =>
            if not Row.Has_Source then
               return Status_Rejected_Unclassified_Legacy;
            end if;
      end case;

      return Status_Accepted;
   end Evaluate;

   function Result_Fingerprint
     (Row : Closure_Row; Status : Evidence_Status) return Natural is
   begin
      return Row.Id * 79
        + Cleanup_Item'Pos (Row.Item) * 83
        + Evidence_Status'Pos (Status) * 89
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Document_Fingerprint
        + Row.Cleanup_Fingerprint;
   end Result_Fingerprint;

   function Build (Input : Closure_Input) return Closure_Model is
      Model : Closure_Model;
      Status : Evidence_Status;
      Item_Result : Closure_Result;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Item_Result :=
           (Id => Row.Id,
            Status => Status,
            Result_Class => Class_For_Status (Status),
            Result_Fingerprint => Result_Fingerprint (Row, Status));
         Model.Results.Append (Item_Result);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Closure_Fingerprint :=
           Model.Closure_Fingerprint + Item_Result.Result_Fingerprint;

         case Item_Result.Result_Class is
            when Class_Accepted =>
               Model.Accepted_Count := Model.Accepted_Count + 1;
            when Class_Rejected =>
               Model.Rejected_Count := Model.Rejected_Count + 1;
            when Class_Indeterminate =>
               Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
            when Class_Unknown =>
               null;
         end case;
      end loop;

      return Model;
   end Build;

   function Result_For (Model : Closure_Model; Id : Natural) return Closure_Result is
   begin
      for Result of Model.Results loop
         if Result.Id = Id then
            return Result;
         end if;
      end loop;

      return
        (Id => Id,
         Status => Status_Not_Checked,
         Result_Class => Class_Unknown,
         Result_Fingerprint => 0);
   end Result_For;

   function Legacy_Cleanup_Closed (Model : Closure_Model) return Boolean is
   begin
      return Model.Total_Rows = 7
        and then Model.Accepted_Count = 7
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Closure_Fingerprint /= 0;
   end Legacy_Cleanup_Closed;

   function Ready_For_Next_Project_Phase (Model : Closure_Model) return Boolean is
   begin
      return Legacy_Cleanup_Closed (Model);
   end Ready_For_Next_Project_Phase;

end Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446;
