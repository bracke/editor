with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Project_Scale_Closure_Pass1436 is

   procedure Add_Row (Input : in out Closure_Input; Row : Closure_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status
     (Status : Closure_Status) return Closure_Result_Class is
   begin
      case Status is
         when Status_Accepted =>
            return Class_Accepted;
         when Status_Rejected_Missing_Project_Item
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Speculative_New_Work
            | Status_Rejected_Unregistered_Test
            | Status_Rejected_Missing_Documentation
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Stale_Evidence =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Has_Evidence (Row : Closure_Row) return Boolean is
   begin
      return Row.Evidence_Present
        and then Row.Area /= Area_Unknown
        and then Length (Row.Name) > 0;
   end Has_Evidence;

   function Fingerprints_Fresh (Row : Closure_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Test_Fingerprint = Row.Expected_Test_Fingerprint
        and then Row.Documentation_Fingerprint = Row.Expected_Documentation_Fingerprint
        and then Row.Closure_Fingerprint = Row.Expected_Closure_Fingerprint;
   end Fingerprints_Fresh;

   function Evaluate (Row : Closure_Row) return Closure_Status is
   begin
      if not Has_Evidence (Row) then
         return Status_Indeterminate_Missing_Evidence;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Stale_Evidence;
      elsif not Row.Project_Item_Complete then
         return Status_Rejected_Missing_Project_Item;
      elsif not Row.Test_Registered then
         return Status_Rejected_Unregistered_Test;
      elsif not Row.Documentation_Present then
         return Status_Rejected_Missing_Documentation;
      elsif not Row.Consumer_Agreement then
         return Status_Rejected_Consumer_Disagreement;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.Proposes_Speculative_Work and then not Row.Has_Real_Failing_Evidence then
         return Status_Rejected_Speculative_New_Work;
      else
         return Status_Accepted;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Closure_Row; Status : Closure_Status) return Natural is
   begin
      return Row.Id * 173
        + Closure_Area'Pos (Row.Area) * 101
        + Closure_Status'Pos (Status) * 67
        + Row.Source_Fingerprint
        + Row.Test_Fingerprint
        + Row.Documentation_Fingerprint
        + Row.Closure_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Closure_Model; Item : Closure_Entry) is
   begin
      case Item.Status is
         when Status_Accepted =>
            Model.Accepted_Count := Model.Accepted_Count + 1;
         when Status_Rejected_Missing_Project_Item
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Speculative_New_Work
            | Status_Rejected_Unregistered_Test
            | Status_Rejected_Missing_Documentation
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Stale_Evidence =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Closure_Input) return Closure_Model is
      Model : Closure_Model;
      Status : Closure_Status;
      Item : Closure_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Item.Id := Row.Id;
         Item.Area := Row.Area;
         Item.Status := Status;
         Item.Result_Class := Class_For_Status (Status);
         Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
         Model.Entries.Append (Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Closure_Fingerprint :=
           Model.Closure_Fingerprint + Item.Result_Fingerprint;
         Tally (Model, Item);
      end loop;
      return Model;
   end Build;

   function Result_For
     (Model : Closure_Model; Id : Natural) return Closure_Entry is
   begin
      for Item of Model.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (Id => Id,
              Area => Area_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Phase579_Project_Scale_Closed (Model : Closure_Model) return Boolean is
   begin
      return Model.Total_Rows = 7
        and then Model.Accepted_Count = Model.Total_Rows
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Closure_Fingerprint > 0;
   end Phase579_Project_Scale_Closed;

end Editor.Ada_Phase579_Project_Scale_Closure_Pass1436;
