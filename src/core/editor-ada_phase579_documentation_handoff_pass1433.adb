with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_Documentation_Handoff_Pass1433 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Handoff_Input; Row : Handoff_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Handoff_Status) return Handoff_Result_Class is
   begin
      case Status is
         when Status_Accepted =>
            return Class_Accepted;
         when Status_Rejected_Missing_Status
            | Status_Rejected_Missing_Guarantee
            | Status_Rejected_Missing_Approximation
            | Status_Rejected_Missing_Future_Work_Rule
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Speculative_Edge
            | Status_Rejected_Missing_Acceptance_Standard
            | Status_Rejected_Stale_Documentation_Evidence =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Has_Evidence (Row : Handoff_Row) return Boolean is
   begin
      return Row.Evidence_Present
        and then Row.Section /= Section_Unknown
        and then Length (Row.Title) > 0
        and then Length (Row.Text) > 0;
   end Has_Evidence;

   function Fingerprints_Fresh (Row : Handoff_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Documentation_Fingerprint = Row.Expected_Documentation_Fingerprint
        and then Row.Handoff_Fingerprint = Row.Expected_Handoff_Fingerprint;
   end Fingerprints_Fresh;

   function Evaluate (Row : Handoff_Row) return Handoff_Status is
   begin
      if not Has_Evidence (Row) then
         return Status_Indeterminate_Missing_Evidence;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Stale_Documentation_Evidence;
      elsif not Row.Final_Status_Documented then
         return Status_Rejected_Missing_Status;
      elsif not Row.Guarantees_Documented then
         return Status_Rejected_Missing_Guarantee;
      elsif not Row.Approximations_Documented then
         return Status_Rejected_Missing_Approximation;
      elsif not Row.Future_Work_Rule_Documented then
         return Status_Rejected_Missing_Future_Work_Rule;
      elsif not Row.Acceptance_Standard_Documented then
         return Status_Rejected_Missing_Acceptance_Standard;
      elsif Row.Reopens_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      elsif Row.Speculative_Edge_Allowed then
         return Status_Rejected_Speculative_Edge;
      else
         return Status_Accepted;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Handoff_Row; Status : Handoff_Status) return Natural is
   begin
      return Row.Id * 149
        + Handoff_Section'Pos (Row.Section) * 83
        + Handoff_Status'Pos (Status) * 53
        + Row.Source_Fingerprint
        + Row.Documentation_Fingerprint
        + Row.Handoff_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Handoff_Model; Item : Handoff_Entry) is
   begin
      case Item.Status is
         when Status_Accepted =>
            Model.Accepted_Count := Model.Accepted_Count + 1;
         when Status_Rejected_Missing_Status
            | Status_Rejected_Missing_Guarantee
            | Status_Rejected_Missing_Approximation
            | Status_Rejected_Missing_Future_Work_Rule
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Speculative_Edge
            | Status_Rejected_Missing_Acceptance_Standard
            | Status_Rejected_Stale_Documentation_Evidence =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Handoff_Input) return Handoff_Model is
      Model : Handoff_Model;
      Status : Handoff_Status;
      Item : Handoff_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Item.Id := Row.Id;
         Item.Section := Row.Section;
         Item.Status := Status;
         Item.Result_Class := Class_For_Status (Status);
         Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
         Model.Entries.Append (Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Handoff_Fingerprint :=
           Model.Handoff_Fingerprint + Item.Result_Fingerprint;
         Tally (Model, Item);
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Handoff_Model; Id : Natural) return Handoff_Entry is
   begin
      for Item of Model.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (Id => Id,
              Section => Section_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function Documentation_Handoff_Complete (Model : Handoff_Model) return Boolean is
   begin
      return Model.Total_Rows > 0
        and then Model.Accepted_Count = Model.Total_Rows
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Handoff_Fingerprint > 0;
   end Documentation_Handoff_Complete;

end Editor.Ada_Phase579_Documentation_Handoff_Pass1433;
